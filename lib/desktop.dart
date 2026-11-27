import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';

/// ویندوز: پنجره (کوچک شدن با ×، بازگرداندن هنگام زنگ، حالت ویجت) و اجرا با روشن شدن ویندوز.
/// کد بومی مربوطه با ci/patch_windows.py به پروژهٔ ویندوز اضافه می‌شود.
class Desktop {
  Desktop._();
  static final Desktop instance = Desktop._();
  static const MethodChannel _ch = MethodChannel('now/window');

  static bool get supported => Platform.isWindows;
  final ValueNotifier<bool> widgetMode = ValueNotifier<bool>(false);

  Future<void> _call(String method, [Object? args]) async {
    if (!supported) return;
    try {
      await _ch.invokeMethod<void>(method, args);
    } catch (_) {}
  }

  Future<void> init(List<String> args) async {
    if (!supported) return;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'widgetClosed') widgetMode.value = false;
      return null;
    });
    await applyCloseMode();
    if (args.contains('--background')) await _call('minimize');
  }

  /// true: دکمهٔ × پنجره را کوچک می‌کند (برنامه برای زنگ زنده می‌ماند)
  Future<void> applyCloseMode() => _call('closeMode', app.closeToTray);

  Future<void> showMain() async {
    if (widgetMode.value) await exitWidget();
    await _call('restore');
  }

  Future<void> enterWidget() async {
    widgetMode.value = true;
    await _call('widget', true);
  }

  Future<void> exitWidget() async {
    widgetMode.value = false;
    await _call('widget', false);
  }

  Future<void> quit() async => exit(0);

  /// اجرا با روشن شدن ویندوز (ثبت در Registry کاربر)
  Future<void> applyStartup() async {
    if (!supported) return;
    const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
    try {
      if (app.autoStart) {
        await Process.run('reg', ['add', key, '/v', 'Now', '/t', 'REG_SZ', '/d', '"${Platform.resolvedExecutable}" --background', '/f']);
      } else {
        await Process.run('reg', ['delete', key, '/v', 'Now', '/f']);
      }
    } catch (_) {}
  }
}
