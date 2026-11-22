import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app_state.dart';
import 'desktop.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'ui.dart';

/// ویجت دسکتاپ ویندوز: کارت تاریخ شمسی (چپ) + ساعت (راست)، مثل ویجت اندروید
class DesktopWidget extends StatelessWidget {
  const DesktopWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Scaffold(
      backgroundColor: const Color(0xFF1B1D29),
      body: DragToMoveArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: LiveTime(builder: (context, now) {
            final j = Jalali.fromDateTime(now);
            final holiday = isHoliday(j);
            return Row(children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${j.weekdayName}  ${j.monthName}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    Text(nd(j.day),
                        style: TextStyle(fontSize: 54, height: 1.05, fontWeight: FontWeight.bold, color: holiday ? Colors.red.shade400 : accent)),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: Stack(children: [
                  Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Ltr(child: Text(fmtHM(now), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w500))),
                      Text(gFull(now), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ]),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton(
                      tooltip: tr('widget_back'),
                      onPressed: () => Desktop.instance.exitWidget(),
                      icon: const Icon(Icons.open_in_full, size: 16, color: Colors.white54),
                    ),
                  ),
                ]),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
