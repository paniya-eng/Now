import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'app_state.dart';
import 'data.dart';
import 'fmt.dart';
import 'strings.dart';

/// اعلان‌های واقعی اندروید: حتی وقتی برنامه بسته یا گوشی قفل است زنگ می‌خورند
class Notifier {
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  static Timer? _debounce;
  static String _lastSig = '';
  static const _widgetChannel = MethodChannel('now/widget');

  static bool get supported => Platform.isAndroid;

  static Future<void> init() async {
    if (!supported) return;
    try {
      await _fln.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
      final a = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await a?.requestNotificationsPermission();
      await a?.requestExactAlarmsPermission();
      app.addListener(_schedule);
      _schedule();
    } catch (_) {}
  }

  static void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), _doSchedule);
  }

  static int _base(Reminder r) => (r.id.hashCode & 0x3fffff) * 16;

  static String _sound() => app.soundId.startsWith('custom:') ? 'bell' : app.soundId;

  static Future<void> _doSchedule() async {
    try {
      // ویجت اندروید هم با تغییر تنظیمات تازه شود
      try {
        await _widgetChannel.invokeMethod('refresh');
      } catch (_) {}

      final active = app.reminders.where((r) => !r.done).toList();
      final sig = [
        for (final r in active) '${r.id}@${r.time.millisecondsSinceEpoch}:${r.title}',
        'L${app.leads.toList()..sort()}', _sound(), 'S${app.silentAfter}', 'O${app.clockOffsetMin}', Tr.lang,
      ].join('|');
      if (sig == _lastSig) return;
      _lastSig = sig;

      await _fln.cancelAll();
      final off = Duration(minutes: app.clockOffsetMin);
      final nowReal = DateTime.now();
      final leads = app.leads.toList()..sort();
      for (final r in active) {
        final real = r.time.subtract(off);
        final base = _base(r);
        final body = r.note.isNotEmpty ? r.note : fmtTime(r.time);
        if (real.isAfter(nowReal)) await _one(base, r.title, body, real);
        var i = 0;
        for (final m in leads) {
          i++;
          if (i > 12) break;
          final at = real.subtract(Duration(minutes: m));
          if (at.isAfter(nowReal)) {
            await _one(base + i, r.title, Tr.fa ? 'تا ${leadLabel(m)} دیگر' : 'In ${leadLabel(m)}', at);
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> _one(int id, String title, String body, DateTime when) async {
    final sound = _sound();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'now_alarm_$sound',
        Tr.fa ? 'هشدار یادآوری' : 'Reminder alarms',
        channelDescription: 'Reminder alarms',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(sound),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT: تکرار صدا تا بسته شدن
        timeoutAfter: app.silentAfter > 0 ? app.silentAfter * 60000 : null,
      ),
    );
    final at = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, when.millisecondsSinceEpoch);
    try {
      await _fln.zonedSchedule(
        id, title, body, at, details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _fln.zonedSchedule(
          id, title, body, at, details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  /// وقتی هشدار داخل برنامه نمایش داده شد، اعلان مربوطه را بردار تا دوبار زنگ نزند
  static Future<void> dismiss(Reminder r) async {
    if (!supported) return;
    try {
      final base = _base(r);
      for (var i = 0; i <= 12; i++) {
        await _fln.cancel(base + i);
      }
    } catch (_) {}
  }
}
