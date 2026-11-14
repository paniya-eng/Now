import 'package:flutter/material.dart';
import 'app_state.dart';
import 'data.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'stopwatch_page.dart';
import 'strings.dart';
import 'timer_page.dart';
import 'ui.dart';

class ClockPage extends StatelessWidget {
  const ClockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            PageTitle(tr('clock')),
            LiveTime(builder: (context, now) {
              final j = Jalali.fromDateTime(now);
              return AppCard(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                child: Column(children: [
                  Ltr(
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(fmtHM(now), style: const TextStyle(fontSize: 68, fontWeight: FontWeight.w500, height: 1.1)),
                      const SizedBox(width: 6),
                      Column(children: [
                        Text(nd(now.second.toString().padLeft(2, '0')), style: TextStyle(fontSize: 26, color: context.accent, fontWeight: FontWeight.bold)),
                        if (ampm(now).isNotEmpty) Text(ampm(now), style: TextStyle(fontSize: 13, color: context.sub)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text(jFull(j), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(gFull(now), style: TextStyle(color: context.sub)),
                ]),
              );
            }),
            const SizedBox(height: 12),
            _WorldClocks(),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _BigButton(icon: 'hourglass', label: tr('timer'), page: const TimerPage())),
              const SizedBox(width: 12),
              Expanded(child: _BigButton(icon: 'timer', label: tr('stopwatch'), page: const StopwatchPage())),
            ]),
          ],
        );
      },
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.icon, required this.label, required this.page});
  final String icon, label;
  final Widget page;
  @override
  Widget build(BuildContext context) => Material(
        color: context.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Column(children: [
              AppIcon(icon, size: 34, color: context.accent, stroke: 1.8),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
}

class _WorldClocks extends StatelessWidget {
  _WorldClocks();

  String _dayLabel(DateTime city, DateTime local) {
    final a = DateTime(city.year, city.month, city.day);
    final b = DateTime(local.year, local.month, local.day);
    final diff = a.difference(b).inDays;
    if (diff == 0) return tr('today');
    return diff > 0 ? tr('tomorrow') : tr('yesterday');
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: LiveTime(builder: (context, now) {
        final utc = now.toUtc();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('world_clock'), style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          for (final id in app.cities)
            Builder(builder: (context) {
              final c = cityById(id);
              final off = c.offsetAt(utc);
              final t = utc.add(off);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Tr.fa ? c.fa : c.en, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${_dayLabel(t, now)} • ${gmtLabel(off)}', style: TextStyle(fontSize: 12, color: context.sub)),
                    ]),
                  ),
                  Ltr(child: Text(fmtTime(t), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500))),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => app.removeCity(id),
                    icon: AppIcon('x', size: 18, color: context.sub),
                  ),
                ]),
              );
            }),
          if (app.cities.length < 3)
            TextButton.icon(
              onPressed: () => _pickCity(context),
              icon: const AppIcon('plus', size: 18),
              label: Text(tr('add_city')),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 6),
              child: Text(tr('max_cities'), style: TextStyle(fontSize: 12, color: context.sub)),
            ),
        ]);
      }),
    );
  }

  Future<void> _pickCity(BuildContext context) async {
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 340,
          height: 460,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(tr('choose_city'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(children: [
                for (final c in kCities)
                  if (!app.cities.contains(c.id))
                    ListTile(
                      title: Text(Tr.fa ? c.fa : c.en),
                      subtitle: Text(gmtLabel(Duration(minutes: c.std))),
                      onTap: () => Navigator.pop(ctx, c.id),
                    ),
              ]),
            ),
          ]),
        ),
      ),
    );
    if (id != null) app.addCity(id);
  }
}
