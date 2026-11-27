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
        final r = app.byId(e.key);
        app.clearSnooze(e.key);
        if (r != null && !r.done) {
          _fire(r, 0, false);
          return;
        }
      }
    }

    for (final r in app.reminders.toList()) {
      if (r.done) continue;
      final ms = r.time.millisecondsSinceEpoch;
      if (!now.isBefore(r.time)) {
        final snoozed = app.snoozedUntil.containsKey(r.id);
        if ((app.alerted[r.id] ?? 0) < ms && !snoozed) {
          app.markAlerted(r.id, ms);
          // یادآوری‌های خیلی قدیمی فقط علامت می‌خورند و هشدار داده نمی‌شوند
          if (now.difference(r.time) <= const Duration(hours: 24)) {
            app.markAlerted('${r.id}@', nowMs); // زمان واقعی زنگ خوردن
            app.addLog(r.id, 'fired');
            _fire(r, 0, false);
            return;
          } else {
            app.markAlerted('${r.id}!', ms);
          }
        } else if (app.followUpMin > 0 && !snoozed) {
          // یادآوری پیگیری: چند دقیقه بعد از زنگ اول، اگر هنوز انجام نشده
          final firedAt = app.alerted['${r.id}@'] ?? 0;
          if (firedAt >= ms && (app.alerted['${r.id}!'] ?? 0) < ms && nowMs >= firedAt + app.followUpMin * 60000) {
            app.markAlerted('${r.id}!', ms);
            if (nowMs - firedAt <= const Duration(hours: 24).inMilliseconds) {
              app.addLog(r.id, 'followup');
              _fire(r, 0, true);
              return;
            }
          }
        }
      } else {
        for (final m in app.leads) {
          final at = r.time.subtract(Duration(minutes: m));
          final key = '${r.id}#$m';
          if (!now.isBefore(at) && (app.alerted[key] ?? 0) < ms) {
            app.markAlerted(key, ms);
            if (now.difference(at) <= const Duration(minutes: 10)) {
              _fire(r, m, false);
              return;
            }
          }
        }
      }
    }
  }

  Future<void> _fire(Reminder r, int lead, bool followUp) async {
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
      builder: (_) => _AlarmDialog(r, lead, followUp),
    );
    silence?.cancel();
    AlarmSound.stop();
    if (res == 'done') {
      app.complete(r.id);
    } else if (res == 'snooze') {
      app.markAlerted('${r.id}!', r.time.millisecondsSinceEpoch); // پیگیری لغو
      app.addLog(r.id, 'snooze');
      app.snoozeReminder(r.id);
    }
    _showing = false;
  }
}

class _AlarmDialog extends StatefulWidget {
  const _AlarmDialog(this.r, this.lead, this.followUp);
  final Reminder r;
  final int lead;
  final bool followUp;
  @override
  State<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<_AlarmDialog> {
  final TextEditingController _report = TextEditingController();

  @override
  void dispose() {
    _report.dispose();
    super.dispose();
  }

  void _saveReport() {
    final t = _report.text.trim();
    if (t.isNotEmpty) {
      app.addLog(widget.r.id, 'report', t);
      _report.clear();
    }
  }

  void _close(String result) {
    _saveReport(); // گزارش نوشته‌شده اما ذخیره‌نشده هم ثبت می‌شود
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final lead = widget.lead;
    final cat = app.catById(r.catId);
    final head = lead > 0
        ? (Tr.fa ? 'تا ${leadLabel(lead)} دیگر' : 'In ${leadLabel(lead)}')
        : '${jShort(Jalali.fromDateTime(r.time))} • ${fmtTime(r.time)}';
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: AppIcon('bell', size: 52, color: context.accent)),
            if (widget.followUp)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: context.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text(tr('followup_title'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.ink)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(head, textAlign: TextAlign.center, style: TextStyle(color: context.sub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(r.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (r.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.note, textAlign: TextAlign.center, style: TextStyle(color: context.sub)),
            ],
            if (cat != null) Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: CatChip(cat))),
            if (r.image != null) Padding(padding: const EdgeInsets.only(top: 12), child: Center(child: ImageThumb(r.image!, size: 100))),
            if (widget.followUp) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _report,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: tr('report_hint'),
                  filled: true,
                  fillColor: context.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: context.accent, foregroundColor: context.onAccent, minimumSize: const Size.fromHeight(48)),
              onPressed: () => _close('done'),
              child: Text(tr('mark_done'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (lead == 0) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: () => _close('snooze'),
                child: Text('${tr('snooze_word')} ${nd(app.snooze)} ${tr('min_unit')}'),
              ),
            ],
            const SizedBox(height: 4),
            TextButton(onPressed: () => _close('close'), child: Text(tr('dismiss'))),
          ]),
        ),
      ),
    );
  }
}
