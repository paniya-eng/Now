import 'app_state.dart';
import 'jalali.dart';
import 'strings.dart';

String fmtHM(DateTime t) {
  final mm = t.minute.toString().padLeft(2, '0');
  if (app.h24) return nd('${t.hour.toString().padLeft(2, '0')}:$mm');
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return nd('$h:$mm');
}

String ampm(DateTime t) => app.h24 ? '' : (t.hour < 12 ? tr('am') : tr('pm'));

String fmtTime(DateTime t) {
  final a = ampm(t);
  return a.isEmpty ? fmtHM(t) : '${fmtHM(t)} $a';
}

String jFull(Jalali j) => Tr.fa
    ? '${j.weekdayName} ${nd(j.day)} ${j.monthName} ${nd(j.year)}'
    : '${j.weekdayName}, ${j.day} ${j.monthName} ${j.year}';

String gFull(DateTime g) => '${nd(g.day)} ${Tr.gMonth(g.month)} ${nd(g.year)}';

String jShort(Jalali j) => '${nd(j.day)} ${j.monthName}';

String repeatUnit(int type, int n) {
  const fa = ['ساعت', 'روز', 'هفته', 'ماه', 'سال', 'دقیقه'];
  const en = ['hour', 'day', 'week', 'month', 'year', 'minute'];
  final i = type - 1;
  return Tr.fa ? fa[i] : (n == 1 ? en[i] : '${en[i]}s');
}

String repeatText(int type, int n) {
  if (type == 0) return tr('rep_none');
  if (Tr.fa) return n == 1 ? 'هر ${repeatUnit(type, 1)}' : 'هر ${nd(n)} ${repeatUnit(type, n)}';
  return n == 1 ? 'Every ${repeatUnit(type, 1)}' : 'Every $n ${repeatUnit(type, n)}';
}

String leadLabel(int minutes) {
  if (minutes < 1440) {
    final h = minutes ~/ 60;
    return Tr.fa ? '${nd(h)} ساعت' : '$h h';
  }
  if (minutes == 10080) return Tr.fa ? '۱ هفته' : '1 week';
  if (minutes == 43200) return Tr.fa ? '۱ ماه' : '1 month';
  final d = minutes ~/ 1440;
  return Tr.fa ? '${nd(d)} روز' : '$d day${d == 1 ? '' : 's'}';
}
