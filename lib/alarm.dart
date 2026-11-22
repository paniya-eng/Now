import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'data.dart';
import 'desktop.dart';
import 'notifier.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'ui.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// پخش صدای زنگ (صدای آماده یا فایل دلخواه کاربر)
class AlarmSound {
  static final AudioPlayer _p = AudioPlayer();

  static Source _source(String id) {
    if (id.startsWith('custom:')) return DeviceFileSource(app.soundPath(id.substring(7)));
    return AssetSource('sounds/$id.wav');
  }

  static Future<void> play({bool loop = true, String? id}) async {
    try {
      await _p.stop();
      await _p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _p.play(_source(id ?? app.soundId));
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _p.stop();
    } catch (_) {}
  }
}

/// هر ثانیه یادآوری‌ها را بررسی می‌کند و در زمان موعد هشدار می‌دهد (وقتی برنامه باز یا در پس‌زمینه زنده است)
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();
  Timer? _t;
  bool _showing = false;

  void start() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_showing || navKey.currentContext == null) return;
    final now = appNow();
    final nowMs = now.millisecondsSinceEpoch;

    for (final e in app.snoozedUntil.entries.toList()) {
      if (nowMs >= e.value) {
        Reminder? r;
        for (final x in app.reminders) {
          if (x.id == e.key) r = x;
        }
        app.clearSnooze(e.key);
        if (r != null && !r.done) {
          _fire(r, 0);
          return;
        }
      }
    }

    for (final r in app.reminders.toList()) {
      if (r.done) continue;
      final ms = r.time.millisecondsSinceEpoch;
      if (!now.isBefore(r.time)) {
        if ((app.alerted[r.id] ?? 0) < ms && !app.snoozedUntil.containsKey(r.id)) {
          app.markAlerted(r.id, ms);
          // یادآوری‌های خیلی قدیمی فقط علامت می‌خورند و هشدار داده نمی‌شوند
          if (now.difference(r.time) <= const Duration(hours: 24)) {
            _fire(r, 0);
            return;
          }
        }
      } else {
        for (final m in app.leads) {
          final at = r.time.subtract(Duration(minutes: m));
          final key = '${r.id}#$m';
          if (!now.isBefore(at) && (app.alerted[key] ?? 0) < ms) {
            app.markAlerted(key, ms);
            if (now.difference(at) <= const Duration(minutes: 10)) {
              _fire(r, m);
              return;
            }
          }
        }
      }
    }
  }

  Future<void> _fire(Reminder r, int lead) async {
    if (navKey.currentContext == null) return;
    _showing = true;
    Notifier.dismiss(r);
    if (Desktop.supported) await Desktop.instance.showMain();
    final ctx = navKey.currentContext;
    if (ctx == null) {
      _showing = false;
      return;
    }
    AlarmSound.play(loop: true);
    Timer? silence;
    if (app.silentAfter > 0) {
      silence = Timer(Duration(minutes: app.silentAfter), AlarmSound.stop);
    }
    final res = await showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _AlarmDialog(r, lead),
    );
    silence?.cancel();
    AlarmSound.stop();
    if (res == 'done') {
      app.complete(r.id);
    } else if (res == 'snooze') {
      app.snoozeReminder(r.id);
    }
    _showing = false;
  }
}

class _AlarmDialog extends StatelessWidget {
  const _AlarmDialog(this.r, this.lead);
  final Reminder r;
  final int lead;

  @override
  Widget build(BuildContext context) {
    final cat = app.catById(r.catId);
    final head = lead > 0
        ? (Tr.fa ? 'تا ${leadLabel(lead)} دیگر' : 'In ${leadLabel(lead)}')
        : '${jShort(Jalali.fromDateTime(r.time))} • ${fmtTime(r.time)}';
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: AppIcon('bell', size: 56, color: context.accent)),
            const SizedBox(height: 10),
            Text(head, textAlign: TextAlign.center, style: TextStyle(color: context.sub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(r.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (r.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.note, textAlign: TextAlign.center, style: TextStyle(color: context.sub)),
            ],
            if (cat != null) Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: CatChip(cat))),
            if (r.image != null) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: ImageThumb(r.image!, size: 110))),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.accent, minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(context, 'done'),
              child: Text(tr('mark_done'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (lead == 0) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: () => Navigator.pop(context, 'snooze'),
                child: Text('${tr('snooze_word')} ${nd(app.snooze)} ${tr('min_unit')}'),
              ),
            ],
            const SizedBox(height: 4),
            TextButton(onPressed: () => Navigator.pop(context, 'close'), child: Text(tr('dismiss'))),
          ]),
        ),
      ),
    );
  }
}
