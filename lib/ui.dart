import 'dart:async';
import 'dart:io' show File, Platform, Process;
import 'dart:math' as math;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'app_state.dart';
import 'data.dart';
import 'fmt.dart';
import 'icons.dart';
import 'jalali.dart';
import 'reminder_form.dart';
import 'strings.dart';

extension Ctx on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get card => isDark ? const Color(0xFF22242F) : Colors.white;
  Color get bg => isDark ? const Color(0xFF101116) : const Color(0xFFEDEEF3);
  Color get sub => isDark ? Colors.white60 : Colors.black54;
  Color get accent => Color(app.accentValue);
  Color get onAccent => accent.computeLuminance() > 0.6 ? Colors.black : Colors.white;
  Color get ink => isDark ? Colors.white : const Color(0xFF14151C);
}

// ---------- آیکون ----------
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 24, this.color, this.stroke = 2});
  final String name;
  final double size;
  final Color? color;
  final double stroke;
  static final _cache = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    final hex = '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final svg = _cache.putIfAbsent(
      '$name$hex$stroke',
      () => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$hex" '
          'stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">${kIcons[name]}</svg>',
    );
    return SvgPicture.string(svg, width: size, height: size);
  }
}

// ---------- ابزارهای ساده ----------
class Ltr extends StatelessWidget {
  const Ltr({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr, child: child);
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(color: context.card, borderRadius: BorderRadius.circular(24)),
        child: child,
      );
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// هر ثانیه زمان را تازه می‌کند
class LiveTime extends StatefulWidget {
  const LiveTime({super.key, required this.builder});
  final Widget Function(BuildContext, DateTime) builder;
  @override
  State<LiveTime> createState() => _LiveTimeState();
}

class _LiveTimeState extends State<LiveTime> {
  Timer? _t;
  DateTime _now = appNow();
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = appNow());
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

class OptionChips<T> extends StatelessWidget {
  const OptionChips({super.key, required this.options, required this.value, required this.onSelected});
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o.$2),
              selected: o.$1 == value,
              showCheckmark: false,
              selectedColor: context.accent,
              labelStyle: TextStyle(color: o.$1 == value ? Colors.white : null),
              onSelected: (_) => onSelected(o.$1),
            ),
        ],
      );
}

// ---------- تقویم ماهانه ----------
class MonthHeader extends StatelessWidget {
  const MonthHeader({super.key, required this.year, required this.month, required this.onPrev, required this.onNext});
  final int year, month;
  final VoidCallback onPrev, onNext;
  @override
  Widget build(BuildContext context) {
    final prevIcon = Tr.fa ? 'chevron-right' : 'chevron-left';
    final nextIcon = Tr.fa ? 'chevron-left' : 'chevron-right';
    return Row(children: [
      IconButton(onPressed: onPrev, icon: AppIcon(prevIcon)),
      Expanded(
        child: Text('${Tr.jMonth(month)} ${nd(year)}',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      ),
      IconButton(onPressed: onNext, icon: AppIcon(nextIcon)),
    ]);
  }
}

class WeekHeader extends StatelessWidget {
  const WeekHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Text(Tr.weekdayShort(i),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: i == 6 ? Colors.red.shade400 : context.sub)),
          ),
      ]);
}

class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.selected,
    required this.onTap,
    this.reminderDays = const {},
    this.occasionDays = const {},
    this.holidayDays = const {},
  });
  final int year, month;
  final Jalali selected;
  final ValueChanged<Jalali> onTap;
  final Set<int> reminderDays, occasionDays, holidayDays;

  @override
  Widget build(BuildContext context) {
    final today = Jalali.now();
    final offset = Jalali(year, month, 1).weekdayIndex;
    final len = Jalali.monthLengthOf(year, month);
    final rows = ((offset + len) / 7).ceil();
    final accent = context.accent;

    Widget cell(int d) {
      final j = Jalali(year, month, d);
      final isToday = j.isSameDay(today);
      final isSel = j.isSameDay(selected);
      final red = (offset + d - 1) % 7 == 6 || holidayDays.contains(d);
      final dotColor = isToday ? Colors.white : accent;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(j),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? accent : (isSel ? accent.withValues(alpha: 0.16) : null),
              border: (isSel && !isToday) ? Border.all(color: accent, width: 1.6) : null,
            ),
            child: Stack(alignment: Alignment.center, children: [
              Text(nd(d),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    color: isToday ? Colors.white : (red ? Colors.red.shade400 : context.ink),
                  )),
              Positioned(
                bottom: 3,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (reminderDays.contains(d)) _dot(dotColor),
                  if (occasionDays.contains(d)) _dot(isToday ? Colors.white70 : Colors.orange),
                ]),
              ),
            ]),
          ),
        ),
      );
    }

    return Column(children: [
      for (var r = 0; r < rows; r++)
        Row(children: [
          for (var c = 0; c < 7; c++)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: () {
                  final d = r * 7 + c - offset + 1;
                  return (d < 1 || d > len) ? const SizedBox() : cell(d);
                }(),
              ),
            ),
        ]),
    ]);
  }

  Widget _dot(Color c) => Container(
        width: 4,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ---------- انتخاب‌گرها ----------
Future<Jalali?> pickDate(BuildContext context, Jalali init) {
  var y = init.year, mo = init.month;
  var sel = init;
  return showDialog<Jalali>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, upd) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              MonthHeader(
                year: y,
                month: mo,
                onPrev: () => upd(() {
                  mo--;
                  if (mo < 1) { mo = 12; y--; }
                }),
                onNext: () => upd(() {
                  mo++;
                  if (mo > 12) { mo = 1; y++; }
                }),
              ),
              const WeekHeader(),
              const SizedBox(height: 4),
              MonthGrid(year: y, month: mo, selected: sel, onTap: (j) => upd(() => sel = j)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ctx.accent),
                  onPressed: () => Navigator.pop(ctx, sel),
                  child: Text(tr('ok')),
                ),
              ]),
            ]),
          ),
        ),
      ),
    ),
  );
}

/// انتخاب عدد: دکمه‌های ▲▼ (با نگه‌داشتن کلیک تکرار می‌شوند)، چرخ ماوس و کشیدن عمودی
class NumberSpinner extends StatefulWidget {
  const NumberSpinner({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.label,
    this.wrap = true,
    this.pad = 2,
  });
  final int min, max, value, pad;
  final bool wrap;
  final String? label;
  final ValueChanged<int> onChanged;
  @override
  State<NumberSpinner> createState() => _NumberSpinnerState();
}

class _NumberSpinnerState extends State<NumberSpinner> {
  late int _v = widget.value;
  Timer? _t;
  double _acc = 0;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _step(int d) {
    final range = widget.max - widget.min + 1;
    var n = _v + d;
    if (widget.wrap) {
      n = (n - widget.min) % range + widget.min;
    } else {
      n = math.max(widget.min, math.min(widget.max, n));
    }
    if (n == _v) return;
    setState(() => _v = n);
    widget.onChanged(n);
  }

  void _hold(int d) {
    _step(d);
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 380), () {
      _t = Timer.periodic(const Duration(milliseconds: 70), (_) => _step(d));
    });
  }

  void _release() {
    _t?.cancel();
    _t = null;
  }

  Widget _btn(BuildContext context, String icon, int d) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _hold(d),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: Container(
          width: 72,
          height: 42,
          alignment: Alignment.center,
          child: AppIcon(icon, size: 26, color: context.accent),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) _step(e.scrollDelta.dy > 0 ? -1 : 1);
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (widget.label != null) Text(widget.label!, style: TextStyle(color: context.sub, fontSize: 12)),
        _btn(context, 'chevron-up', 1),
        GestureDetector(
          onVerticalDragUpdate: (d) {
            _acc += d.delta.dy;
            if (_acc <= -14) {
              _step(1);
              _acc = 0;
            } else if (_acc >= 14) {
              _step(-1);
              _acc = 0;
            }
          },
          onVerticalDragEnd: (_) => _acc = 0,
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Text(nd(_v.toString().padLeft(widget.pad, '0')), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ),
        ),
        _btn(context, 'chevron-down', -1),
      ]),
    );
  }
}

Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay init) {
  var h = init.hour, m = init.minute;
  return showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('select_time'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Ltr(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                NumberSpinner(min: 0, max: 23, value: h, onChanged: (v) => h = v),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text(':', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold))),
                NumberSpinner(min: 0, max: 59, value: m, onChanged: (v) => m = v),
              ]),
            ),
            const SizedBox(height: 6),
            Text(tr('hold_hint'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: ctx.sub)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ctx.accent),
                onPressed: () => Navigator.pop(ctx, TimeOfDay(hour: h, minute: m)),
                child: Text(tr('ok')),
              ),
            ]),
          ]),
        ),
      ),
    ),
  );
}

// ---------- یادآوری ----------
class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.checked, required this.onTap});
  final bool checked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? context.accent : Colors.transparent,
              border: Border.all(color: checked ? context.accent : context.sub, width: 2),
            ),
            child: checked ? const Center(child: AppIcon('check', size: 15, color: Colors.white, stroke: 3.2)) : null,
          ),
        ),
      );
}

class CatChip extends StatelessWidget {
  const CatChip(this.cat, {super.key});
  final ReminderCategory cat;
  @override
  Widget build(BuildContext context) {
    final c = cat.deleted ? Colors.grey : Color(cat.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            cat.deleted ? '${cat.name} · ${tr('cat_deleted')}' : cat.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cat.deleted ? context.sub : context.ink),
          ),
        ),
      ]),
    );
  }
}

class ImageThumb extends StatelessWidget {
  const ImageThumb(this.name, {super.key, this.size = 48});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => showImageViewer(context, name),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(app.imagePath(name)),
            width: size,
            height: size,
            fit: BoxFit.cover,
            cacheWidth: 240,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              color: Colors.black12,
              child: const Center(child: AppIcon('image', size: 20, color: Colors.grey)),
            ),
          ),
        ),
      );
}

Future<void> shareImage(String name) async {
  final path = app.imagePath(name);
  try {
    await Share.shareXFiles([XFile(path)]);
  } catch (_) {
    // اگر اشتراک‌گذاری در این سیستم پشتیبانی نشد، فایل را در پوشه‌اش نشان بده
    try {
      if (Platform.isWindows) await Process.run('explorer.exe', ['/select,', path]);
    } catch (_) {}
  }
}

void showImageViewer(BuildContext context, String name) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(children: [
        InteractiveViewer(child: Center(child: Image.file(File(app.imagePath(name))))),
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(onPressed: () => Navigator.pop(ctx), icon: const AppIcon('x', color: Colors.white)),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filled(
            tooltip: tr('share'),
            style: IconButton.styleFrom(backgroundColor: Colors.white24),
            onPressed: () => shareImage(name),
            icon: const AppIcon('share-2', color: Colors.white, size: 22),
          ),
        ),
      ]),
    ),
  );
}

class ReminderTile extends StatelessWidget {
  const ReminderTile(this.r, {super.key, this.showDate = false, this.showCat = true});
  final Reminder r;
  final bool showDate, showCat;

  void _toggle(BuildContext context) {
    if (r.done) {
      app.restore(r.id);
      return;
    }
    final undo = app.complete(r.id);
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(
      content: Text(tr('done_moved')),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(label: tr('undo'), onPressed: undo),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cat = showCat ? app.catById(r.catId) : null;
    final when = showDate ? '${jShort(Jalali.fromDateTime(r.time))} • ${fmtTime(r.time)}' : fmtTime(r.time);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => editReminder(context, r),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CheckCircle(checked: r.done, onTap: () => _toggle(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: r.done ? TextDecoration.lineThrough : null,
                  )),
              if (r.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(r.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.sub)),
                ),
              const SizedBox(height: 3),
              Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(when, style: TextStyle(fontSize: 13, color: context.sub)),
                if (r.repeatType > 0)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    AppIcon('repeat', size: 13, color: context.sub),
                    const SizedBox(width: 3),
                    Text(repeatText(r.repeatType, r.repeatN), style: TextStyle(fontSize: 12, color: context.sub)),
                  ]),
                if (cat != null) CatChip(cat),
              ]),
            ]),
          ),
          if (r.image != null) ...[const SizedBox(width: 8), ImageThumb(r.image!)],
        ]),
      ),
    );
  }
}

class NewReminderButton extends StatelessWidget {
  const NewReminderButton({super.key, this.date});
  final Jalali? date;
  @override
  Widget build(BuildContext context) => Material(
        color: context.accent,
        elevation: 6,
        shadowColor: context.accent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => editReminder(context, null, date: date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const AppIcon('circle-plus', color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(tr('new_reminder'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
          ),
        ),
      );
}

// ---------- مناسبت کاربر ----------
Future<void> addOccasionDialog(BuildContext context, Jalali date) {
  return showDialog<void>(context: context, builder: (_) => _OccasionForm(date: date));
}

class _OccasionForm extends StatefulWidget {
  const _OccasionForm({required this.date});
  final Jalali date;
  @override
  State<_OccasionForm> createState() => _OccasionFormState();
}

class _OccasionFormState extends State<_OccasionForm> {
  final _c = TextEditingController();
  bool _yearly = true;
  bool _err = false;
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr('add_occasion'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(jFull(widget.date), style: TextStyle(color: context.sub)),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                autofocus: true,
                decoration: InputDecoration(hintText: tr('occasion_title'), errorText: _err ? tr('empty_title') : null),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _yearly,
                title: Text(tr('repeat_yearly')),
                onChanged: (v) => setState(() => _yearly = v),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: context.accent),
                  onPressed: () {
                    final t = _c.text.trim();
                    if (t.isEmpty) {
                      setState(() => _err = true);
                      return;
                    }
                    app.addOccasion(t, widget.date, _yearly);
                    Navigator.pop(context);
                  },
                  child: Text(tr('save')),
                ),
              ]),
            ]),
          ),
        ),
      );
}

class OccasionRow extends StatelessWidget {
  const OccasionRow(this.o, {super.key});
  final OccItem o;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          AppIcon('flag-triangle-right', size: 20, color: o.holiday ? Colors.red.shade400 : Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(o.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          if (o.holiday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(tr('holiday'), style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.bold)),
            ),
          if (o.userId != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => app.removeOccasion(o.userId!),
              icon: AppIcon('x', size: 18, color: context.sub),
            ),
        ]),
      );
}


// ---------- بخش جمع‌شونده با فلش پویا ----------
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.count,
    this.initiallyExpanded = true,
    this.icon,
    this.bold = false,
  });
  final String title;
  final Widget child;
  final int? count;
  final bool initiallyExpanded;
  final String? icon;
  final bool bold;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            if (widget.icon != null) ...[AppIcon(widget.icon!, size: 20, color: context.accent), const SizedBox(width: 10)],
            Expanded(
              child: Text(widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: widget.bold ? 17 : 14,
                    color: widget.bold ? context.ink : context.sub,
                  )),
            ),
            if (widget.count != null)
              Container(
                margin: const EdgeInsetsDirectional.only(end: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: context.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Text(nd(widget.count!), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.ink)),
              ),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AppIcon('chevron-down', size: 22, color: context.sub),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: _open ? widget.child : const SizedBox(width: double.infinity),
      ),
    ]);
  }
}

// ---------- انتخاب رنگ (طیف کامل + کد Hex) ----------
double _unit(double v) => v < 0 ? 0.0 : (v > 1 ? 1.0 : v);

Future<int?> showColorPicker(BuildContext context, int initial) =>
    showDialog<int>(context: context, builder: (_) => _ColorPickerDialog(initial: initial));

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final int initial;
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv = HSVColor.fromColor(Color(widget.initial));
  late final TextEditingController _hex = TextEditingController(text: _toHex(Color(widget.initial)));

  static String _toHex(Color c) => (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _set(HSVColor h) {
    setState(() {
      _hsv = h;
      _hex.text = _toHex(h.toColor());
    });
  }

  @override
  Widget build(BuildContext context) {
    const h = 200.0;
    final pure = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    final cur = _hsv.toColor();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tr('pick_color'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: h,
              child: LayoutBuilder(builder: (context, cons) {
                final w = cons.maxWidth;
                void upd(Offset p) => _set(_hsv.withSaturation(_unit(p.dx / w)).withValue(1 - _unit(p.dy / h)));
                return GestureDetector(
                  onPanDown: (d) => upd(d.localPosition),
                  onPanUpdate: (d) => upd(d.localPosition),
                  child: Stack(children: [
                    Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [Colors.white, pure]))),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black]),
                      ),
                    ),
                    Positioned(
                      left: _hsv.saturation * w - 11,
                      top: (1 - _hsv.value) * h - 11,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: cur, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
                      ),
                    ),
                  ]),
                );
              }),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 22,
              child: LayoutBuilder(builder: (context, cons) {
                final w = cons.maxWidth;
                void upd(Offset p) => _set(_hsv.withHue(_unit(p.dx / w) * 359.9));
                return GestureDetector(
                  onPanDown: (d) => upd(d.localPosition),
                  onPanUpdate: (d) => upd(d.localPosition),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: LinearGradient(colors: [for (var i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0 % 360, 1, 1).toColor()]),
                      ),
                    ),
                    Positioned(
                      left: (_hsv.hue / 360) * w - 11,
                      top: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: pure, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)]),
                      ),
                    ),
                  ]),
                );
              }),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: cur, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              const Text('#', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Expanded(
                child: Ltr(
                  child: TextField(
                    controller: _hex,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(counterText: '', hintText: 'F54927'),
                    onChanged: (v) {
                      if (v.length == 6 && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(v)) {
                        setState(() => _hsv = HSVColor.fromColor(Color(int.parse('FF$v', radix: 16))));
                      }
                    },
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: cur, foregroundColor: cur.computeLuminance() > 0.6 ? Colors.black : Colors.white),
                onPressed: () => Navigator.pop(context, cur.toARGB32()),
                child: Text(tr('ok')),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
