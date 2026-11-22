import 'package:flutter/foundation.dart';

/// نسخهٔ سبک: Tray و ویجت ویندوز موقتاً غیرفعال است (کد کامل در windows_desktop/ نگه‌داری شده).
class Desktop {
  Desktop._();
  static final Desktop instance = Desktop._();

  static bool get supported => false;
  final ValueNotifier<bool> widgetMode = ValueNotifier<bool>(false);

  Future<void> init() async {}
  Future<void> showMain() async {}
  Future<void> enterWidget() async {}
  Future<void> exitWidget() async {}
  Future<void> applyStartup() async {}
  Future<void> quit() async {}
}
