import 'package:flutter/material.dart';
import 'app_state.dart';
import 'archive_page.dart';
import 'category_page.dart';
import 'data.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.remindersOn(appNow());
        return Stack(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              const _TopRow(),
              const SizedBox(height: 12),
              _TodayOccasions(),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Text(tr('reminders'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(
                  tooltip: tr('categories'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CategoriesPage())),
                  icon: const AppIcon('tags'),
                ),
                IconButton(
                  tooltip: tr('archive'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ArchivePage())),
                  icon: const AppIcon('archive'),
                ),
              ]),
              if (app.activeCats.isNotEmpty) _CatStrip(),
              const SizedBox(height: 4),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Center(child: Text(tr('no_reminders_today'), style: TextStyle(color: context.sub))),
                      )
                    : Column(children: [for (final r in list) ReminderTile(r)]),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(padding: const EdgeInsets.all(16), child: NewReminderButton()),
          ),
        ]);
      },
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow();
  @override
  Widget build(BuildContext context) {
    return LiveTime(builder: (context, now) {
      final j = Jalali.fromDateTime(now);
      final holiday = isHoliday(j);
      return IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 5,
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: j.monthName, style: TextStyle(color: context.sub)),
                    const TextSpan(text: '  '),
                    TextSpan(text: j.weekdayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                Text(nd(j.day),
                    style: TextStyle(
                      fontSize: 64,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: holiday ? Colors.red.shade400 : context.accent,
                    )),
                Text(nd(j.year), style: TextStyle(color: context.sub)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Ltr(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(fmtHM(now), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    Column(children: [
                      if (app.showSeconds)
                        Text(nd(now.second.toString().padLeft(2, '0')), style: TextStyle(fontSize: 15, color: context.accent, fontWeight: FontWeight.bold)),
                      if (ampm(now).isNotEmpty) Text(ampm(now), style: TextStyle(fontSize: 12, color: context.sub)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(gFull(now), style: TextStyle(fontSize: 13, color: context.sub)),
              ]),
            ),
          ),
        ]),
      );
    });
  }
}

class _TodayOccasions extends StatelessWidget {
  _TodayOccasions();
  @override
  Widget build(BuildContext context) {
    final list = occasionsOn(Jalali.now());
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: list.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                const AppIcon('flag-triangle-right', size: 20, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(child: Text(tr('no_occasion'), style: TextStyle(color: context.sub))),
              ]),
            )
          : Column(children: [for (final o in list) OccasionRow(o)]),
    );
  }
}

class _CatStrip extends StatelessWidget {
  _CatStrip();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final c in app.activeCats)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ActionChip(
                avatar: Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(c.color), shape: BoxShape.circle)),
                label: Text('${c.name}  ${nd(app.countActive(c.id))}'),
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CategoryDetailPage(c.id))),
              ),
            ),
        ]),
      ),
    );
  }
}
