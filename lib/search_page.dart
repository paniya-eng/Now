import 'package:flutter/material.dart';
import 'app_state.dart';
import 'category_page.dart';
import 'data.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'ui.dart';

String _norm(String s) {
  var r = s.toLowerCase().replaceAll('ي', 'ی').replaceAll('ك', 'ک').replaceAll('\u200c', ' ');
  r = r.replaceAll(RegExp('[\u064B-\u065F]'), '');
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  for (var i = 0; i < 10; i++) {
    r = r.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return r.trim();
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _c = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Column(children: [
          PageTitle(tr('search')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _c,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: tr('search_hint'),
                filled: true,
                fillColor: context.card,
                prefixIcon: const Padding(padding: EdgeInsets.all(12), child: AppIcon('search', size: 20)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(child: _results(context)),
        ]);
      },
    );
  }

  Widget _results(BuildContext context) {
    final q = _norm(_q);
    if (q.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppIcon('search', size: 52, color: context.sub),
            const SizedBox(height: 10),
            Text(tr('search_empty'), textAlign: TextAlign.center, style: TextStyle(color: context.sub)),
          ]),
        ),
      );
    }

    final rem = app.reminders.where((r) => !r.done && _norm(r.title).contains(q)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final arc = app.archived.where((r) => _norm(r.title).contains(q)).toList();
    final cats = app.activeCats.where((c) => _norm(c.name).contains(q)).toList();
    final mine = app.userOcc.where((o) => _norm(o.title).contains(q)).toList();
    final year = Jalali.now().year;
    final built = <_Hit>[];
    for (final o in kSolar) {
      if (_norm(o.fa).contains(q) || _norm(o.en).contains(q)) {
        built.add(_Hit(Tr.fa ? o.fa : o.en, jShort(Jalali(year, o.m, o.d)), Jalali(year, o.m, o.d), o.holiday));
      }
    }
    for (final o in kGlobal) {
      if (_norm(o.fa).contains(q) || _norm(o.en).contains(q)) {
        final g = DateTime(DateTime.now().year, o.m, o.d);
        built.add(_Hit(Tr.fa ? o.fa : o.en, gFull(g), Jalali.fromDateTime(g), false));
      }
    }

    if (rem.isEmpty && arc.isEmpty && mine.isEmpty && built.isEmpty && cats.isEmpty) {
      return Center(child: Text(tr('no_results'), style: TextStyle(color: context.sub)));
    }

    Widget section(String title, List<Widget> items) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: Text(title, style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
            ),
            AppCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), child: Column(children: items)),
          ]),
        );

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      if (cats.isNotEmpty)
        section(tr('sec_categories'), [
          for (final c in cats)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CategoryDetailPage(c.id))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Container(width: 14, height: 14, decoration: BoxDecoration(color: Color(c.color), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                  Text('${nd(app.countActive(c.id))} ${tr('cat_active')}', style: TextStyle(fontSize: 13, color: context.sub)),
                ]),
              ),
            ),
        ]),
      if (rem.isNotEmpty) section(tr('sec_reminders'), [for (final r in rem.take(30)) ReminderTile(r, showDate: true)]),
      if (arc.isNotEmpty) section(tr('sec_archived'), [for (final r in arc.take(30)) ReminderTile(r, showDate: true)]),
      if (mine.isNotEmpty)
        section(tr('sec_my_occ'), [
          for (final o in mine.take(30))
            _hitTile(context, _Hit(o.title, jShort(Jalali(o.y, o.m, o.d)), Jalali(o.y, o.m, o.d), false)),
        ]),
      if (built.isNotEmpty) section(tr('sec_builtin'), [for (final h in built.take(30)) _hitTile(context, h)]),
    ]);
  }

  Widget _hitTile(BuildContext context, _Hit h) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => app.openCalendarOn(h.date),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            AppIcon('flag-triangle-right', size: 20, color: h.holiday ? Colors.red.shade400 : Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(h.sub, style: TextStyle(fontSize: 13, color: context.sub)),
              ]),
            ),
          ]),
        ),
      );
}

class _Hit {
  _Hit(this.title, this.sub, this.date, this.holiday);
  final String title, sub;
  final Jalali date;
  final bool holiday;
}
