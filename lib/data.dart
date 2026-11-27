import 'dart:ui' show Color;

const kAccents = <Color>[
  Color(0xFF2F6BFF), Color(0xFFFF7A1A), Color(0xFFE8362B),
  Color(0xFF12A594), Color(0xFF8B5CF6), Color(0xFFEC4899),
];

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.time,
    this.done = false,
    this.note = '',
    this.catId,
    this.image,
    this.repeatType = 0,
    this.repeatN = 1,
    this.updatedAt = 0,
    this.deleted = false,
    List<Map<String, dynamic>>? log,
  }) : log = log ?? [];
  final String id;
  String title;
  DateTime time;
  bool done;
  String note;
  String? catId;
  String? image;
  int repeatType; // 0 ندارد، 1 ساعت، 2 روز، 3 هفته، 4 ماه (شمسی)، 5 سال (شمسی)، 6 دقیقه
  int repeatN;
  int updatedAt;
  bool deleted;

  /// گردش کار: {t: زمان (ms)، k: نوع، x: متن گزارش}
  final List<Map<String, dynamic>> log;

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 't': time.millisecondsSinceEpoch, 'done': done,
        'note': note, 'cat': catId, 'img': image, 'rt': repeatType, 'rn': repeatN,
        'u': updatedAt, 'del': deleted, 'log': log,
      };
  factory Reminder.fromJson(Map<String, dynamic> m) => Reminder(
        id: m['id'] as String,
        title: m['title'] as String,
        time: DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
        done: (m['done'] as bool?) ?? false,
        note: (m['note'] as String?) ?? '',
        catId: m['cat'] as String?,
        image: m['img'] as String?,
        repeatType: (m['rt'] as int?) ?? 0,
        repeatN: (m['rn'] as int?) ?? 1,
        updatedAt: (m['u'] as int?) ?? 0,
        deleted: (m['del'] as bool?) ?? false,
        log: ((m['log'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
}

class ReminderCategory {
  ReminderCategory({required this.id, required this.name, required this.color, this.deleted = false, this.updatedAt = 0});
  final String id;
  String name;
  int color;
  bool deleted;
  int updatedAt;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color, 'deleted': deleted, 'u': updatedAt};
  factory ReminderCategory.fromJson(Map<String, dynamic> m) => ReminderCategory(
        id: m['id'] as String,
        name: m['name'] as String,
        color: m['color'] as int,
        deleted: (m['deleted'] as bool?) ?? false,
        updatedAt: (m['u'] as int?) ?? 0,
      );
}

const kCatColors = <int>[
  0xFF2F6BFF, 0xFFFF7A1A, 0xFFE8362B, 0xFF12A594, 0xFF8B5CF6, 0xFFEC4899,
  0xFFF5B301, 0xFF16A34A, 0xFF0EA5E9, 0xFF78716C, 0xFF111827, 0xFF84CC16,
];

class UserOccasion {
  UserOccasion({required this.id, required this.title, required this.y, required this.m, required this.d, this.yearly = true, this.updatedAt = 0, this.deleted = false});
  final String id;
  final String title;
  final int y, m, d;
  final bool yearly;
  int updatedAt;
  bool deleted;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'y': y, 'm': m, 'd': d, 'yearly': yearly, 'u': updatedAt, 'del': deleted};
  factory UserOccasion.fromJson(Map<String, dynamic> j) => UserOccasion(
        id: j['id'] as String,
        title: j['title'] as String,
        y: j['y'] as int,
        m: j['m'] as int,
        d: j['d'] as int,
        yearly: (j['yearly'] as bool?) ?? true,
        updatedAt: (j['u'] as int?) ?? 0,
        deleted: (j['del'] as bool?) ?? false,
      );
}

class Occ {
  const Occ(this.m, this.d, this.fa, this.en, [this.holiday = false]);
  final int m, d;
  final String fa, en;
  final bool holiday;
}

class OccItem {
  OccItem(this.title, this.holiday, {this.userId});
  final String title;
  final bool holiday;
  final String? userId;
}

// مناسبت‌های ثابت شمسی (مناسبت‌های قمری مثل عید فطر در مرحلهٔ بعد اضافه می‌شود)
const kSolar = <Occ>[
  Occ(1, 1, 'عید نوروز', 'Nowruz', true),
  Occ(1, 2, 'عید نوروز', 'Nowruz', true),
  Occ(1, 3, 'عید نوروز', 'Nowruz', true),
  Occ(1, 4, 'عید نوروز', 'Nowruz', true),
  Occ(1, 12, 'روز جمهوری اسلامی ایران', 'Islamic Republic Day', true),
  Occ(1, 13, 'سیزده‌به‌در (روز طبیعت)', 'Nature Day (Sizdah Bedar)', true),
  Occ(2, 1, 'روز بزرگداشت عطار نیشابوری', 'Attar of Nishapur Day'),
  Occ(2, 12, 'روز معلم', "Teacher's Day"),
  Occ(2, 25, 'روز بزرگداشت فردوسی', 'Ferdowsi Day'),
  Occ(2, 26, 'روز ملی ارتباطات و روابط عمومی', 'National Communications Day'),
  Occ(3, 3, 'آزادسازی خرمشهر', 'Liberation of Khorramshahr'),
  Occ(3, 14, 'رحلت امام خمینی', 'Demise of Imam Khomeini', true),
  Occ(3, 15, 'قیام ۱۵ خرداد', 'Uprising of 15 Khordad', true),
  Occ(4, 7, 'روز قوهٔ قضاییه', 'Judiciary Day'),
  Occ(5, 14, 'سالروز صدور فرمان مشروطیت', 'Constitutional Revolution Anniversary'),
  Occ(6, 1, 'روز پزشک (زادروز ابوعلی سینا)', 'Physician Day (Avicenna)'),
  Occ(6, 8, 'روز مبارزه با تروریسم', 'Anti-Terrorism Day'),
  Occ(6, 17, 'قیام ۱۷ شهریور', 'Uprising of 17 Shahrivar'),
  Occ(6, 31, 'آغاز هفتهٔ دفاع مقدس', 'Start of Sacred Defense Week'),
  Occ(7, 1, 'آغاز سال تحصیلی', 'Start of School Year'),
  Occ(7, 7, 'روز آتش‌نشانی و ایمنی', 'Firefighters Day'),
  Occ(7, 8, 'روز بزرگداشت مولوی', 'Rumi Day'),
  Occ(7, 14, 'روز دامپزشکی', 'Veterinary Day'),
  Occ(7, 20, 'روز بزرگداشت حافظ', 'Hafez Day'),
  Occ(8, 13, 'روز دانش‌آموز', 'Student Day'),
  Occ(8, 24, 'روز کتاب و کتابخوانی', 'Book and Reading Day'),
  Occ(9, 5, 'روز بسیج مستضعفین', 'Basij Day'),
  Occ(9, 7, 'روز نیروی دریایی', 'Navy Day'),
  Occ(9, 16, 'روز دانشجو', 'University Student Day'),
  Occ(9, 30, 'شب یلدا', 'Yalda Night'),
  Occ(10, 9, 'روز بصیرت', 'Basirat Day'),
  Occ(11, 12, 'بازگشت امام خمینی (آغاز دهه فجر)', 'Start of Fajr Decade'),
  Occ(11, 22, 'پیروزی انقلاب اسلامی', 'Victory of the Islamic Revolution', true),
  Occ(12, 15, 'روز درختکاری', 'Arbor Day'),
  Occ(12, 29, 'روز ملی شدن صنعت نفت', 'Oil Nationalization Day', true),
];

// مناسبت‌های جهانی (تاریخ میلادی ثابت) - منبع: فهرست رسمی سازمان ملل، یونسکو و WHO (un.org/en/observances/list-days-weeks)
const kGlobal = <Occ>[
  Occ(1, 1, 'آغاز سال میلادی', "New Year's Day"),
  Occ(1, 4, 'روز جهانی بریل', 'World Braille Day'),
  Occ(1, 24, 'روز جهانی آموزش', 'International Day of Education'),
  Occ(2, 2, 'روز جهانی تالاب‌ها', 'World Wetlands Day'),
  Occ(2, 11, 'روز جهانی زنان و دختران در علم', 'Women and Girls in Science Day'),
  Occ(2, 13, 'روز جهانی رادیو', 'World Radio Day'),
  Occ(2, 20, 'روز جهانی عدالت اجتماعی', 'World Day of Social Justice'),
  Occ(2, 21, 'روز جهانی زبان مادری', 'International Mother Language Day'),
  Occ(3, 3, 'روز جهانی حیات‌وحش', 'World Wildlife Day'),
  Occ(3, 8, 'روز جهانی زن', "International Women's Day"),
  Occ(3, 14, 'روز جهانی ریاضیات', 'International Day of Mathematics'),
  Occ(3, 20, 'روز جهانی شادی', 'International Day of Happiness'),
  Occ(3, 21, 'روز جهانی نوروز', 'International Day of Nowruz'),
  Occ(3, 21, 'روز جهانی شعر', 'World Poetry Day'),
  Occ(3, 21, 'روز جهانی جنگل', 'International Day of Forests'),
  Occ(3, 21, 'روز جهانی سندرم داون', 'World Down Syndrome Day'),
  Occ(3, 22, 'روز جهانی آب', 'World Water Day'),
  Occ(3, 23, 'روز جهانی هواشناسی', 'World Meteorological Day'),
  Occ(3, 24, 'روز جهانی مبارزه با سل', 'World Tuberculosis Day'),
  Occ(3, 30, 'روز جهانی بدون زباله', 'International Day of Zero Waste'),
  Occ(4, 2, 'روز جهانی آگاهی از اوتیسم', 'World Autism Awareness Day'),
  Occ(4, 7, 'روز جهانی بهداشت', 'World Health Day'),
  Occ(4, 12, 'روز جهانی پرواز فضایی انسان', 'International Day of Human Space Flight'),
  Occ(4, 15, 'روز جهانی هنر', 'World Art Day'),
  Occ(4, 22, 'روز جهانی زمین', 'International Mother Earth Day'),
  Occ(4, 23, 'روز جهانی کتاب و حق مؤلف', 'World Book and Copyright Day'),
  Occ(4, 26, 'روز جهانی مالکیت فکری', 'World Intellectual Property Day'),
  Occ(4, 28, 'روز جهانی ایمنی و بهداشت کار', 'World Day for Safety and Health at Work'),
  Occ(4, 30, 'روز جهانی جاز', 'International Jazz Day'),
  Occ(5, 1, 'روز جهانی کارگر', "International Workers' Day"),
  Occ(5, 3, 'روز جهانی آزادی مطبوعات', 'World Press Freedom Day'),
  Occ(5, 15, 'روز جهانی خانواده', 'International Day of Families'),
  Occ(5, 17, 'روز جهانی ارتباطات و جامعهٔ اطلاعاتی', 'World Telecommunication and Information Society Day'),
  Occ(5, 20, 'روز جهانی زنبور عسل', 'World Bee Day'),
  Occ(5, 21, 'روز جهانی چای', 'International Tea Day'),
  Occ(5, 22, 'روز جهانی تنوع زیستی', 'International Day for Biological Diversity'),
  Occ(5, 31, 'روز جهانی بدون دخانیات', 'World No-Tobacco Day'),
  Occ(6, 1, 'روز جهانی والدین', 'Global Day of Parents'),
  Occ(6, 3, 'روز جهانی دوچرخه', 'World Bicycle Day'),
  Occ(6, 5, 'روز جهانی محیط زیست', 'World Environment Day'),
  Occ(6, 7, 'روز جهانی ایمنی غذا', 'World Food Safety Day'),
  Occ(6, 8, 'روز جهانی اقیانوس‌ها', 'World Oceans Day'),
  Occ(6, 12, 'روز جهانی مبارزه با کار کودکان', 'World Day Against Child Labour'),
  Occ(6, 14, 'روز جهانی اهدای خون', 'World Blood Donor Day'),
  Occ(6, 17, 'روز جهانی مبارزه با بیابان‌زایی و خشکسالی', 'World Day to Combat Desertification and Drought'),
  Occ(6, 20, 'روز جهانی پناهندگان', 'World Refugee Day'),
  Occ(6, 21, 'روز جهانی یوگا', 'International Day of Yoga'),
  Occ(6, 26, 'روز جهانی مبارزه با مواد مخدر', 'International Day against Drug Abuse'),
  Occ(6, 30, 'روز جهانی سیارک', 'International Asteroid Day'),
  Occ(7, 11, 'روز جهانی جمعیت', 'World Population Day'),
  Occ(7, 15, 'روز جهانی مهارت‌های جوانان', 'World Youth Skills Day'),
  Occ(7, 18, 'روز جهانی نلسون ماندلا', 'Nelson Mandela International Day'),
  Occ(7, 20, 'روز جهانی شطرنج', 'World Chess Day'),
  Occ(7, 28, 'روز جهانی هپاتیت', 'World Hepatitis Day'),
  Occ(7, 30, 'روز جهانی دوستی', 'International Day of Friendship'),
  Occ(8, 9, 'روز جهانی مردمان بومی', "International Day of the World's Indigenous Peoples"),
  Occ(8, 12, 'روز جهانی جوانان', 'International Youth Day'),
  Occ(8, 19, 'روز جهانی کمک‌های بشردوستانه', 'World Humanitarian Day'),
  Occ(9, 8, 'روز جهانی سوادآموزی', 'International Literacy Day'),
  Occ(9, 15, 'روز جهانی دموکراسی', 'International Day of Democracy'),
  Occ(9, 16, 'روز جهانی حفاظت از لایهٔ ازن', 'International Day for the Preservation of the Ozone Layer'),
  Occ(9, 21, 'روز جهانی صلح', 'International Day of Peace'),
  Occ(9, 23, 'روز جهانی زبان اشاره', 'International Day of Sign Languages'),
  Occ(9, 27, 'روز جهانی گردشگری', 'World Tourism Day'),
  Occ(9, 29, 'روز جهانی آگاهی از اتلاف غذا', 'International Day of Awareness of Food Loss and Waste'),
  Occ(9, 30, 'روز جهانی ترجمه', 'International Translation Day'),
  Occ(10, 1, 'روز جهانی سالمندان', 'International Day of Older Persons'),
  Occ(10, 2, 'روز جهانی عدم خشونت', 'International Day of Non-Violence'),
  Occ(10, 5, 'روز جهانی معلم', "World Teachers' Day"),
  Occ(10, 6, 'روز جهانی زیستگاه', 'World Habitat Day'),
  Occ(10, 9, 'روز جهانی پست', 'World Post Day'),
  Occ(10, 10, 'روز جهانی سلامت روان', 'World Mental Health Day'),
  Occ(10, 11, 'روز جهانی دختر', 'International Day of the Girl Child'),
  Occ(10, 13, 'روز جهانی کاهش خطر بلایای طبیعی', 'International Day for Disaster Risk Reduction'),
  Occ(10, 15, 'روز جهانی زنان روستایی', 'International Day of Rural Women'),
  Occ(10, 16, 'روز جهانی غذا', 'World Food Day'),
  Occ(10, 17, 'روز جهانی ریشه‌کنی فقر', 'International Day for the Eradication of Poverty'),
  Occ(10, 24, 'روز سازمان ملل متحد', 'United Nations Day'),
  Occ(10, 31, 'روز جهانی شهرها', 'World Cities Day'),
  Occ(11, 10, 'روز جهانی علم برای صلح و توسعه', 'World Science Day for Peace and Development'),
  Occ(11, 14, 'روز جهانی دیابت', 'World Diabetes Day'),
  Occ(11, 16, 'روز جهانی مدارا', 'International Day for Tolerance'),
  Occ(11, 17, 'روز جهانی یادبود قربانیان تصادفات جاده‌ای', 'World Day of Remembrance for Road Traffic Victims'),
  Occ(11, 20, 'روز جهانی کودک', "World Children's Day"),
  Occ(11, 21, 'روز جهانی فلسفه', 'World Philosophy Day'),
  Occ(11, 21, 'روز جهانی تلویزیون', 'World Television Day'),
  Occ(11, 25, 'روز جهانی مبارزه با خشونت علیه زنان', 'International Day for the Elimination of Violence against Women'),
  Occ(12, 1, 'روز جهانی ایدز', 'World AIDS Day'),
  Occ(12, 3, 'روز جهانی افراد دارای معلولیت', 'International Day of Persons with Disabilities'),
  Occ(12, 5, 'روز جهانی داوطلبان', 'International Volunteer Day'),
  Occ(12, 5, 'روز جهانی خاک', 'World Soil Day'),
  Occ(12, 9, 'روز جهانی مبارزه با فساد', 'International Anti-Corruption Day'),
  Occ(12, 10, 'روز جهانی حقوق بشر', 'Human Rights Day'),
  Occ(12, 11, 'روز جهانی کوهستان', 'International Mountain Day'),
  Occ(12, 18, 'روز جهانی مهاجران', 'International Migrants Day'),
  Occ(12, 20, 'روز جهانی همبستگی انسانی', 'International Human Solidarity Day'),
  Occ(12, 25, 'کریسمس', 'Christmas Day'),
];

// ---------- ساعت جهانی ----------
class City {
  const City(this.id, this.fa, this.en, this.std, [this.dst = 0]);
  final String id, fa, en;
  final int std; // اختلاف استاندارد با UTC به دقیقه
  final int dst; // 0 بدون ساعت تابستانی، 1 اروپا، 2 آمریکا/کانادا

  Duration offsetAt(DateTime utc) {
    var m = std;
    final y = utc.year;
    if (dst == 1) {
      final s = _lastSun(y, 3).add(const Duration(hours: 1));
      final e = _lastSun(y, 10).add(const Duration(hours: 1));
      if (!utc.isBefore(s) && utc.isBefore(e)) m += 60;
    } else if (dst == 2) {
      final s = _nthSun(y, 3, 2).add(Duration(minutes: 120 - std));
      final e = _nthSun(y, 11, 1).add(Duration(minutes: 120 - (std + 60)));
      if (!utc.isBefore(s) && utc.isBefore(e)) m += 60;
    }
    return Duration(minutes: m);
  }
}

DateTime _lastSun(int y, int m) {
  final d = DateTime.utc(y, m + 1, 0);
  return d.subtract(Duration(days: d.weekday % 7));
}

DateTime _nthSun(int y, int m, int n) {
  final f = DateTime.utc(y, m, 1);
  final first = f.add(Duration(days: (7 - f.weekday) % 7));
  return first.add(Duration(days: 7 * (n - 1)));
}

String gmtLabel(Duration off) {
  final m = off.inMinutes;
  final sign = m < 0 ? '-' : '+';
  final a = m.abs();
  final h = a ~/ 60;
  final mm = a % 60;
  return 'GMT$sign$h${mm == 0 ? '' : ':${mm.toString().padLeft(2, '0')}'}';
}

const kCities = <City>[
  City('tehran', 'تهران', 'Tehran', 210),
  City('istanbul', 'استانبول', 'Istanbul', 180),
  City('dubai', 'دبی', 'Dubai', 240),
  City('doha', 'دوحه', 'Doha', 180),
  City('riyadh', 'ریاض', 'Riyadh', 180),
  City('baghdad', 'بغداد', 'Baghdad', 180),
  City('baku', 'باکو', 'Baku', 240),
  City('kabul', 'کابل', 'Kabul', 270),
  City('karachi', 'کراچی', 'Karachi', 300),
  City('tashkent', 'تاشکند', 'Tashkent', 300),
  City('delhi', 'دهلی', 'Delhi', 330),
  City('dhaka', 'داکا', 'Dhaka', 360),
  City('bangkok', 'بانکوک', 'Bangkok', 420),
  City('jakarta', 'جاکارتا', 'Jakarta', 420),
  City('beijing', 'پکن', 'Beijing', 480),
  City('singapore', 'سنگاپور', 'Singapore', 480),
  City('hongkong', 'هنگ‌کنگ', 'Hong Kong', 480),
  City('tokyo', 'توکیو', 'Tokyo', 540),
  City('seoul', 'سئول', 'Seoul', 540),
  City('moscow', 'مسکو', 'Moscow', 180),
  City('london', 'لندن', 'London', 0, 1),
  City('paris', 'پاریس', 'Paris', 60, 1),
  City('berlin', 'برلین', 'Berlin', 60, 1),
  City('rome', 'رم', 'Rome', 60, 1),
  City('madrid', 'مادرید', 'Madrid', 60, 1),
  City('amsterdam', 'آمستردام', 'Amsterdam', 60, 1),
  City('johannesburg', 'ژوهانسبورگ', 'Johannesburg', 120),
  City('nairobi', 'نایروبی', 'Nairobi', 180),
  City('lagos', 'لاگوس', 'Lagos', 60),
  City('saopaulo', 'سائوپائولو', 'Sao Paulo', -180),
  City('mexico', 'مکزیکوسیتی', 'Mexico City', -360),
  City('newyork', 'نیویورک', 'New York', -300, 2),
  City('toronto', 'تورنتو', 'Toronto', -300, 2),
  City('chicago', 'شیکاگو', 'Chicago', -360, 2),
  City('losangeles', 'لس‌آنجلس', 'Los Angeles', -480, 2),
];

City cityById(String id) => kCities.firstWhere((c) => c.id == id, orElse: () => kCities.first);
