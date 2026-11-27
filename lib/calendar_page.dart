import 'package:flutter/material.dart';
import 'app_state.dart';
import 'data.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'reminder_form.dart';
import 'strings.dart';
import 'ui.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late int _y, _m;
  late Jalali _sel;

  @override
  void initState() {
    super.initState();
    final f = app.calendarFocus ?? Jalali.now();
    app.calendarFocus = null;
    _y = f.year;
    _m = f.month;
    _sel = f;
  }

  void _shift(int d) => setState(() {
        _m += d;
        if (_m > 12) { _m = 1; _y++; }
        if (_m < 1) { _m = 12; _y--; }
      });

  void _today() {
    final t = Jalali.now();
    setState(() { _y = t.year; _m = t.month; _sel = t; });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final len = Jalali.monthLengthOf(_y, _m);
        final remDays = <int>{};
        for (final r in app.reminders) {
          if (r.done) continue;
          final j = Jalali.fromDateTime(r.time);
          if (j.year == _y && j.month == _m) remDays.add(j.day);
        }
        final occDays = <int>{};
        final holDays = <int>{};
        for (var d = 1; d <= len; d++) {
          final l = occasionsOn(Jalali(_y, _m, d));
          if (l.isNotEmpty) occDays.add(d);
          if (l.any((o) => o.holiday)) holDays.add(d);
        }
        final selOcc = occasionsOn(_sel);
        final selRem = app.remindersOn(_sel.toDateTime());

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            PageTitle(tr('calendar'), trailing: TextButton(onPressed: _today, child: Text(tr('today')))),
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(children: [
                MonthHeader(year: _y, month: _m, onPrev: () => _shift(-1), onNext: () => _shift(1)),
                WeekHeader(),
                const SizedBox(height: 4),
                MonthGrid(
                  year: _y,
                  month: _m,
                  selected: _sel,
                  onTap: (j) => setState(() => _sel = j),
                  reminderDays: remDays,
                  occasionDays: occDays,
                  holidayDays: holDays,
                ),
              ]),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jFull(_sel), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(gFull(_sel.toDateTime()), style: TextStyle(color: context.sub)),
                const Divider(height: 20),
                CollapsibleSection(
                  title: tr('occasions'),
                  count: selOcc.length,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (selOcc.isEmpty)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(tr('no_occasion_day'), style: TextStyle(color: context.sub)))
                    else
                      for (final o in selOcc) OccasionRow(o),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => addOccasionDialog(context, _sel),
                        icon: const AppIcon('flag', size: 18),
                        label: Text(tr('add_occasion')),
                      ),
                    ),
                  ]),
                ),
                const Divider(height: 8),
                CollapsibleSection(
                  title: tr('reminders'),
                  count: selRem.length,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (selRem.isEmpty)
                      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(tr('no_reminders_day'), style: TextStyle(color: context.sub)))
                    else
                      for (final r in selRem) ReminderTile(r),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => editReminder(context, null, date: _sel),
                        icon: const AppIcon('calendar-plus', size: 18),
                        label: Text(tr('add_reminder')),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
