import 'package:flutter/material.dart';
import 'app_state.dart';
import 'data.dart';
import 'reminder_form.dart';
import 'strings.dart';
import 'ui.dart';

/// ساخت یا ویرایش دسته؛ شناسهٔ دستهٔ ذخیره‌شده را برمی‌گرداند
Future<String?> showCategoryDialog(BuildContext context, {ReminderCategory? edit}) =>
    showDialog<String>(context: context, builder: (_) => _CategoryForm(edit: edit));

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.edit});
  final ReminderCategory? edit;
  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late final TextEditingController _c = TextEditingController(text: widget.edit?.name ?? '');
  late int _color = widget.edit?.color ?? kCatColors[0];
  bool _err = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.edit == null ? tr('new_category') : tr('edit_category'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              autofocus: true,
              decoration: InputDecoration(hintText: tr('cat_name'), errorText: _err ? tr('empty_title') : null),
            ),
            const SizedBox(height: 14),
            Text(tr('cat_color'), style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final c in kCatColors)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: _color == c ? Border.all(color: context.ink, width: 3) : null,
                    ),
                    child: _color == c ? const Center(child: AppIcon('check', size: 16, color: Colors.white, stroke: 3)) : null,
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.accent),
                onPressed: () {
                  final name = _c.text.trim();
                  if (name.isEmpty) {
                    setState(() => _err = true);
                    return;
                  }
                  String id;
                  if (widget.edit == null) {
                    id = app.addCategory(name, _color);
                  } else {
                    id = widget.edit!.id;
                    app.updateCategory(id, name, _color);
                  }
                  Navigator.pop(context, id);
                },
                child: Text(tr('save')),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

String _counts(String id) => '${nd(app.countActive(id))} ${tr('cat_active')} • ${nd(app.countArchived(id))} ${tr('cat_archived')}';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final cats = app.activeCats;
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('categories')),
            backgroundColor: Colors.transparent,
            actions: [IconButton(onPressed: () => showCategoryDialog(context), icon: const AppIcon('plus'))],
          ),
          body: cats.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AppIcon('tags', size: 56, color: context.sub),
                    const SizedBox(height: 10),
                    Text(tr('no_categories'), style: TextStyle(color: context.sub)),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: context.accent),
                      onPressed: () => showCategoryDialog(context),
                      icon: const AppIcon('plus', color: Colors.white, size: 18),
                      label: Text(tr('new_category')),
                    ),
                  ]),
                )
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final c in cats)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: context.card,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => CategoryDetailPage(c.id))),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Container(width: 16, height: 16, decoration: BoxDecoration(color: Color(c.color), shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  Text(_counts(c.id), style: TextStyle(fontSize: 13, color: context.sub)),
                                ]),
                              ),
                              AppIcon(Tr.fa ? 'chevron-left' : 'chevron-right', color: context.sub),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
        );
      },
    );
  }
}

class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage(this.catId, {super.key});
  final String catId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final c = app.catById(catId);
        if (c == null || c.deleted) {
          return Scaffold(appBar: AppBar(backgroundColor: Colors.transparent), body: Center(child: Text(tr('no_categories'))));
        }
        final act = app.reminders.where((r) => !r.done && r.catId == catId).toList()..sort((a, b) => a.time.compareTo(b.time));
        final arc = app.reminders.where((r) => r.done && r.catId == catId).toList()..sort((a, b) => b.time.compareTo(a.time));
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(c.color), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
            ]),
            actions: [
              IconButton(onPressed: () => showCategoryDialog(context, edit: c), icon: const AppIcon('pencil')),
              IconButton(
                icon: AppIcon('trash-2', color: Colors.red.shade400),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: Text(tr('confirm_delete_cat')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('delete'))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    app.deleteCategory(catId);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            AppCard(
              child: Row(children: [
                Expanded(child: Text(_counts(catId), style: const TextStyle(fontWeight: FontWeight.w600))),
                TextButton.icon(
                  onPressed: () => editReminder(context, null, catId: catId),
                  icon: const AppIcon('plus', size: 18),
                  label: Text(tr('add_in_category')),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            if (act.isNotEmpty)
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(children: [for (final r in act) ReminderTile(r, showDate: true, showCat: false)]),
              ),
            if (arc.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
                child: Text(tr('archive'), style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(children: [for (final r in arc) ReminderTile(r, showDate: true, showCat: false)]),
              ),
            ],
          ]),
        );
      },
    );
  }
}
