// تبدیل تاریخ میلادی و شمسی (الگوریتم ۳۳ ساله) - تست‌شده برای سال‌های ۱۳۰۰ تا ۱۵۰۰
import 'strings.dart';

class Jalali {
  final int year;
  final int month;
  final int day;
  const Jalali(this.year, this.month, this.day);

  factory Jalali.now() => Jalali.fromDateTime(DateTime.now());

  factory Jalali.fromDateTime(DateTime d) {
    const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    int gy = d.year;
    final int gm = d.month;
    final int gd = d.day;
    int jy;
    if (gy > 1600) {
      jy = 979;
      gy -= 1600;
    } else {
      jy = 0;
      gy -= 621;
    }
    final int gy2 = gm > 2 ? gy + 1 : gy;
    int days = 365 * gy +
        (gy2 + 3) ~/ 4 -
        (gy2 + 99) ~/ 100 +
        (gy2 + 399) ~/ 400 -
        80 +
        gd +
        gdm[gm - 1];
    jy += 33 * (days ~/ 12053);
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int jm, jd;
    if (days < 186) {
      jm = 1 + days ~/ 31;
      jd = 1 + days % 31;
    } else {
      jm = 7 + (days - 186) ~/ 30;
      jd = 1 + (days - 186) % 30;
    }
    return Jalali(jy, jm, jd);
  }

  DateTime toDateTime() {
    final int jy2 = year + 1595;
    int days = -355668 +
        365 * jy2 +
        (jy2 ~/ 33) * 8 +
        ((jy2 % 33) + 3) ~/ 4 +
        day +
        (month < 7 ? (month - 1) * 31 : (month - 7) * 30 + 186);
    int gy = 400 * (days ~/ 146097);
    days %= 146097;
    if (days > 36524) {
      days--;
      gy += 100 * (days ~/ 36524);
      days %= 36524;
      if (days >= 365) days++;
    }
    gy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      gy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }
    int gd = days + 1;
    final bool leap = (gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0;
    final sal = [0, 31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int gm = 0;
    while (gm < 13 && gd > sal[gm]) {
      gd -= sal[gm];
      gm++;
    }
    return DateTime(gy, gm, gd);
  }

  static int monthLengthOf(int year, int month) {
    if (month <= 6) return 31;
    if (month <= 11) return 30;
    final back = Jalali.fromDateTime(Jalali(year, 12, 30).toDateTime());
    return (back.month == 12 && back.day == 30) ? 30 : 29;
  }

  /// ۰ = شنبه ... ۶ = جمعه
  int get weekdayIndex => (toDateTime().weekday + 1) % 7;

  String get monthName => Tr.jMonth(month);
  String get weekdayName => Tr.weekday(weekdayIndex);

  bool isSameDay(Jalali o) =>
      o.year == year && o.month == month && o.day == day;
}

