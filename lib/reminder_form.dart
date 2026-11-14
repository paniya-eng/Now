import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_state.dart';
import 'category_page.dart';
import 'data.dart';
import 'fmt.dart';
import 'jalali.dart';
import 'strings.dart';
import 'ui.dart';

Future<void> editReminder(BuildContext context, Reminder? r, {Jalali? date, String? catId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: context.card,
    builder: (_) => _ReminderForm(edit: r, date: date, catId: catId),
  );
}

class _ReminderForm extends StatefulWidget {
  const _ReminderForm({this.edit, this.date, this.catId});
  final Reminder? edit;
  final Jalali? date;
  final String? catId;
  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  late final TextEditingController _c;
  late final TextEditingController _n;
  late Jalali _d;
  late TimeOfDay _t;
  int _rt = 0, _rn = 1;
  String? _cat;
  String? _img;
  String? _newImg;
  bool _saved = false;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _c = TextEditingController(text: e?.title ?? '');
    _n = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _d = Jalali.fromDateTime(e.time);
      _t = TimeOfDay(hour: e.time.hour, minute: e.time.minute);
      _rt = e.repeatType;
      _rn = e.repeatN;
      _cat = e.catId;
      _img = e.image;
    } else {
      _d = widget.date ?? Jalali.now();
      final n = DateTime.now().add(const Duration(hours: 1));
      _t = TimeOfDay(hour: n.hour, minute: 0);
      _cat = widget.catId;
    }
  }

  @override
  void dispose() {
    if (!_saved && _newImg != null) app.deleteImageFile(_newImg!);
    _c.dispose();
    _n.dispose();
    super.dispose();
  }

  void _save() {
    final title = _c.text.trim();
    if (title.isEmpty) {
      setState(() => _err = true);
      return;
    }
    final g = _d.toDateTime();
    final time = DateTime(g.year, g.month, g.day, _t.hour, _t.minute);
    final note = _n.text.trim();
    final e = widget.edit;
    if (e == null) {
      app.addReminder(title: title, time: time, note: note, catId: _cat, image: _img, repeatType: _rt, repeatN: _rn);
    } else {
      final old = e.image;
      app.updateReminder(e.id, title: title, time: time, note: note, catId: _cat, image: _img, repeatType: _rt, repeatN: _rn);
      if (old != null && old != _img) app.gcImage(old);
    }
    _saved = true;
    Navigator.pop(context);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (x == null) return;
      final name = await app.saveImage(x);
      if (name == null) return;
      if (_newImg != null) app.deleteImageFile(_newImg!);
      if (mounted) {
        setState(() {
          _img = name;
          _newImg = name;
        });
      }
    } catch (_) {}
  }

  void _removeImage() {
    if (_newImg != null) {
      app.deleteImageFile(_newImg!);
      _newImg = null;
    }
    setState(() => _img = null);
  }

  Future<void> _pickRepeat() async {
    final res = await showDialog<(int, int)>(context: context, builder: (_) => _RepeatDialog(type: _rt, n: _rn));
    if (res != null) {
      setState(() {
        _rt = res.$1;
        _rn = res.$2;
      });
    }
  }

  Future<void> _newCategory() async {
    final id = await showCategoryDialog(context);
    if (id != null) setState(() => _cat = id);
  }

  InputDecoration _dec(String hint, {String? error}) => InputDecoration(
        hintText: hint,
        errorText: error,
        filled: true,
        fillColor: context.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(s, style: TextStyle(color: context.sub, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    final edit = widget.edit;
    final dt = DateTime(2000, 1, 1, _t.hour, _t.minute);
    final cats = app.activeCats;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(edit == null ? tr('new_reminder') : tr('edit_reminder'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(
            controller: _c,
            autofocus: edit == null,
            textInputAction: TextInputAction.next,
            decoration: _dec(tr('title_hint'), error: _err ? tr('empty_title') : null),
            onChanged: (_) {
              if (_err) setState(() => _err = false);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _n,
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            decoration: _dec(tr('note_hint')),
          ),
          const SizedBox(height: 10),
          _FieldRow(
            icon: 'calendar-days',
            label: tr('date'),
            value: jFull(_d),
            onTap: () async {
              final j = await pickDate(context, _d);
              if (j != null) setState(() => _d = j);
            },
          ),
          const SizedBox(height: 8),
          _FieldRow(
            icon: 'clock',
            label: tr('time'),
            value: fmtTime(dt),
            onTap: () async {
              final t = await pickTime(context, _t);
              if (t != null) setState(() => _t = t);
            },
          ),
          const SizedBox(height: 8),
          _FieldRow(icon: 'repeat', label: tr('repeat'), value: repeatText(_rt, _rn), onTap: _pickRepeat),
          _label(tr('category')),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _catChip(null, tr('no_category'), Colors.grey),
            for (final c in cats) _catChip(c.id, c.name, Color(c.color)),
            ActionChip(
              avatar: AppIcon('plus', size: 16, color: context.accent),
              label: Text(tr('new_category')),
              onPressed: _newCategory,
            ),
          ]),
          _label(tr('image')),
          if (_img == null)
            Row(children: [
              if (Platform.isAndroid) ...[
                Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: AppIcon('camera', size: 18, color: context.accent), label: Text(tr('take_photo')))),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: AppIcon('image', size: 18, color: context.accent),
                  label: Text(Platform.isAndroid ? tr('from_gallery') : tr('from_file')),
                ),
              ),
            ])
          else
            Row(children: [
              ImageThumb(_img!, size: 96),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(spacing: 8, children: [
                  OutlinedButton(onPressed: () => _pick(ImageSource.gallery), child: Text(tr('replace'))),
                  OutlinedButton(onPressed: _removeImage, child: Text(tr('remove'))),
                ]),
              ),
            ]),
          const SizedBox(height: 18),
          Row(children: [
            if (edit != null)
              IconButton(
                onPressed: () {
                  app.deleteReminder(edit.id);
                  _saved = true;
                  Navigator.pop(context);
                },
                icon: AppIcon('trash-2', color: Colors.red.shade400),
              ),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.accent, minimumSize: const Size.fromHeight(50)),
                onPressed: _save,
                child: Text(tr('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _catChip(String? id, String name, Color color) {
    final sel = _cat == id;
    return ChoiceChip(
      avatar: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      label: Text(name),
      selected: sel,
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.25),
      onSelected: (_) => setState(() => _cat = id),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.icon, required this.label, required this.value, required this.onTap});
  final String icon, label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            AppIcon(icon, size: 20, color: context.accent),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: context.sub)),
            const Spacer(),
            Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ),
      );
}

class _RepeatDialog extends StatefulWidget {
  const _RepeatDialog({required this.type, required this.n});
  final int type, n;
  @override
  State<_RepeatDialog> createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<_RepeatDialog> {
  late int _t = widget.type;
  late int _n = widget.n;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr('repeat'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            OptionChips<int>(
              options: [(0, tr('rep_none')), for (var i = 1; i <= 5; i++) (i, repeatText(i, 1))],
              value: _t,
              onSelected: (v) => setState(() => _t = v),
            ),
            if (_t > 0) ...[
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(tr('every'), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Ltr(child: NumberSpinner(min: 1, max: 99, value: _n, wrap: false, pad: 1, onChanged: (v) => setState(() => _n = v))),
                const SizedBox(width: 12),
                Text(repeatUnit(_t, _n), style: const TextStyle(fontSize: 18)),
              ]),
            ],
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: context.accent),
                onPressed: () => Navigator.pop(context, (_t, _t == 0 ? 1 : _n)),
                child: Text(tr('ok')),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
