import 'package:flutter/material.dart';
import 'desktop.dart';
import 'home_page.dart' show HeaderCards;
import 'strings.dart';
import 'ui.dart';

/// ویجت دسکتاپ ویندوز: همان دو کارت تاریخ و ساعت صفحهٔ اصلی در یک پنجرهٔ کوچک همیشه‌روی‌صفحه
class DesktopWidget extends StatelessWidget {
  const DesktopWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(children: [
        const Padding(padding: EdgeInsets.all(8), child: Center(child: HeaderCards())),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: tr('widget_back'),
            onPressed: () => Desktop.instance.exitWidget(),
            icon: Icon(Icons.open_in_full, size: 14, color: context.sub),
          ),
        ),
      ]),
    );
  }
}
