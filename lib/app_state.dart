import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'jalali.dart';
import 'strings.dart';

const kVersion = '0.5.3';

final AppState app = AppState();

int nowMs() => DateTime.now().millisecondsSinceEpoch;

/// ساعت برنامه = ساعت دستگاه + مقدار جابه‌جایی که کاربر تنظیم کرده
DateTime appNow() => DateTime.now().add(Duration(minutes: app.clockOffsetMin));

class AppState extends ChangeNotifier {
  SharedPreferences? _p;

  String lang = 'fa';
  bool h24 = true;
  bool showSeconds = true;
  bool systemFont = false;
  int fontSize = 1; // 0 کوچک، 1 متوسط، 2 بزرگ
  int accent = 0;
  int themeMode = 0; // 0 خودکار، 1 روشن، 2 تاریک
  int silentAfter = 5; // دقیقه؛ ۰ یعنی هرگز
  int snooze = 10;
  int clockOffsetMin = 0; // جابه‌جایی ساعت برنامه (دقیقه)
  Set<int> leads = {}; // یادآوری زودتر از موعد (دقیقه)
  List<String> cities = ['london', 'newyork', 'dubai'];
  List<Reminder> _rem = []; // همهٔ یادآوری‌ها، شامل حذف‌شده‌ها (برای همگام‌سازی)
  List<UserOccasion> _occ = [];
  List<ReminderCategory> categories = []; // شامل دسته‌های حذف‌شده
  String imageDir = '';
  String soundDir = '';
  String soundId = 'bell';
  List<String> customSounds = [];
  Map<String, int> alerted = {};
  Map<String, int> snoozedUntil = {};

  // همگام‌سازی
  String syncUrl = '';
  String syncKey = '';
  bool syncAuto = true;
  int lastSyncMs = 0;

  // ویندوز
  bool closeToTray = true;
  bool autoStart = false;

  VoidCallback? onDataChanged;

  int tab = 0;
  Jalali? calendarFocus;

  List<Reminder> get reminders => _rem.where((r) => !r.deleted).toList();
  List<UserOccasion> get userOcc => _occ.where((o) => !o.deleted).toList();
  bool get syncConfigured => syncUrl.trim().isNotEmpty && syncKey.trim().length >= 8;

  Future<void> load() async {
    try {
      _p = await SharedPreferences.getInstance();
      final raw = _p!.getString('data');
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        lang = (m['lang'] as String?) ?? lang;
        h24 = (m['h24'] as bool?) ?? h24;
        showSeconds = (m['sec'] as bool?) ?? showSeconds;
        systemFont = (m['sysfont'] as bool?) ?? systemFont;
        fontSize = (m['fsize'] as int?) ?? fontSize;
        accent = (m['accent'] as int?) ?? accent;
        themeMode = (m['theme'] as int?) ?? themeMode;
        silentAfter = (m['silent'] as int?) ?? silentAfter;
        snooze = (m['snooze'] as int?) ?? snooze;
        clockOffsetMin = (m['offset'] as int?) ?? 0;
        leads = ((m['leads'] as List?) ?? []).map((e) => e as int).toSet();
        cities = ((m['cities'] as List?) ?? cities).map((e) => e as String).toList();
        _rem = ((m['reminders'] as List?) ?? [])
            .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _occ = ((m['occ'] as List?) ?? [])
            .map((e) => UserOccasion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        soundId = (m['sound'] as String?) ?? soundId;
        customSounds = ((m['csounds'] as List?) ?? []).map((e) => e as String).toList();
        alerted = ((m['alerted'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as int));
        snoozedUntil = ((m['snz'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as int));
        categories = ((m['cats'] as List?) ?? [])
            .map((e) => ReminderCategory.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        syncUrl = (m['syncUrl'] as String?) ?? '';
        syncKey = (m['syncKey'] as String?) ?? '';
        syncAuto = (m['syncAuto'] as bool?) ?? true;
        lastSyncMs = (m['lastSync'] as int?) ?? 0;
        closeToTray = (m['tray'] as bool?) ?? true;
        autoStart = (m['startup'] as bool?) ?? false;
      }
    } catch (_) {}
    try {
      final d = await getApplicationDocumentsDirectory();
      imageDir = '${d.path}${Platform.pathSeparator}now_images';
      await Directory(imageDir).create(recursive: true);
      soundDir = '${d.path}${Platform.pathSeparator}now_sounds';
      await Directory(soundDir).create(recursive: true);
    } catch (_) {}
    Tr.lang = lang;
    Jalali.clock = appNow;
  }

  void _commit({bool fromSync = false}) {
    alerted.removeWhere((k, _) => !_rem.any((r) => r.id == k.split('#').first));
    snoozedUntil.removeWhere((k, _) => !_rem.any((r) => r.id == k));
    _p?.setString(
      'data',
      jsonEncode({
        'lang': lang, 'h24': h24, 'sec': showSeconds, 'sysfont': systemFont,
        'fsize': fontSize, 'accent': accent, 'theme': themeMode,
        'silent': silentAfter, 'snooze': snooze, 'offset': clockOffsetMin,
        'leads': leads.toList(), 'cities': cities,
        'reminders': _rem.map((r) => r.toJson()).toList(),
        'occ': _occ.map((o) => o.toJson()).toList(),
        'cats': categories.map((c) => c.toJson()).toList(),
        'sound': soundId, 'csounds': customSounds, 'alerted': alerted, 'snz': snoozedUntil,
        'syncUrl': syncUrl, 'syncKey': syncKey, 'syncAuto': syncAuto, 'lastSync': lastSyncMs,
        'tray': closeToTray, 'startup': autoStart,
      }),
    );
    notifyListeners();
    if (!fromSync) onDataChanged?.call();
  }

  // ----- تنظیمات -----
  void setLang(String l) { lang = l; Tr.lang = l; _commit(); }
  void setH24(bool v) { h24 = v; _commit(); }
  void setShowSeconds(bool v) { showSeconds = v; _commit(); }
  void setSystemFont(bool v) { systemFont = v; _commit(); }
  void setFontSize(int v) { fontSize = v; _commit(); }
  void setAccent(int v) { accent = v; _commit(); }
  void setThemeMode(int v) { themeMode = v; _commit(); }
  void setSilentAfter(int v) { silentAfter = v; _commit(); }
  void setSnooze(int v) { snooze = v; _commit(); }
  void setClockOffset(int minutes) { clockOffsetMin = minutes; _commit(); }
  void setCloseToTray(bool v) { closeToTray = v; _commit(); }
  void setAutoStart(bool v) { autoStart = v; _commit(); }
  void setSyncConfig(String url, String key, bool auto) {
    syncUrl = url.trim();
    syncKey = key.trim();
    syncAuto = auto;
    _commit();
  }

  void markSynced() {
    lastSyncMs = nowMs();
    _commit(fromSync: true);
  }

  void toggleLead(int minutes) {
    leads = leads.contains(minutes) ? (Set<int>.of(leads)..remove(minutes)) : (Set<int>.of(leads)..add(minutes));
    _commit();
  }

  // ----- صدای زنگ و هشدار -----
  String soundPath(String name) => '$soundDir${Platform.pathSeparator}$name';
  void setSound(String id) { soundId = id; _commit(); }

  Future<String?> addCustomSoundFile(String srcPath, String originalName) async {
    try {
      final clean = originalName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final name = '${DateTime.now().millisecondsSinceEpoch}_$clean';
      await File(srcPath).copy(soundPath(name));
      customSounds = [...customSounds, name];
      _commit();
      return name;
    } catch (_) {
      return null;
    }
  }

  void removeCustomSound(String name) {
    customSounds = customSounds.where((e) => e != name).toList();
    try {
      final f = File(soundPath(name));
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    if (soundId == 'custom:$name') soundId = 'bell';
    _commit();
  }

  void markAlerted(String key, int ms) { alerted[key] = ms; _commit(fromSync: true); }
  void clearSnooze(String id) { snoozedUntil.remove(id); _commit(fromSync: true); }
  void snoozeReminder(String id) {
    snoozedUntil[id] = appNow().add(Duration(minutes: snooze)).millisecondsSinceEpoch;
    _commit(fromSync: true);
  }

  // ----- ناوبری -----
  void setTab(int i) { tab = i; notifyListeners(); }
  void openCalendarOn(Jalali j) { calendarFocus = j; tab = 1; notifyListeners(); }

  // ----- شهرها -----
  void addCity(String id) {
    if (cities.length < 3 && !cities.contains(id)) {
      cities = [...cities, id];
      _commit();
    }
  }

  void removeCity(String id) {
    cities = cities.where((c) => c != id).toList();
    _commit();
  }

  // ----- دسته‌بندی‌ها -----
  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  ReminderCategory? catById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<ReminderCategory> get activeCats => categories.where((c) => !c.deleted).toList();
  int countActive(String catId) => reminders.where((r) => !r.done && r.catId == catId).length;
  int countArchived(String catId) => reminders.where((r) => r.done && r.catId == catId).length;

  String addCategory(String name, int color) {
    final c = ReminderCategory(id: newId(), name: name, color: color, updatedAt: nowMs());
    categories = [...categories, c];
    _commit();
    return c.id;
  }

  void updateCategory(String id, String name, int color) {
    final c = catById(id);
    if (c != null) {
      c.name = name;
      c.color = color;
      c.updatedAt = nowMs();
    }
    _commit();
  }

  void deleteCategory(String id) {
    final c = catById(id);
    if (c != null) {
      c.deleted = true;
      c.updatedAt = nowMs();
    }
    for (final r in _rem) {
      if (r.catId == id && !r.done) {
        r.catId = null;
        r.updatedAt = nowMs();
      }
    }
    _commit();
  }

  // ----- تصاویر -----
  String imagePath(String name) => '$imageDir${Platform.pathSeparator}$name';

  Future<String?> saveImage(XFile f) async {
    try {
      final name = 'img_${newId()}.jpg';
      await f.saveTo(imagePath(name));
      return name;
    } catch (_) {
      return null;
    }
  }

  void deleteImageFile(String name) {
    try {
      final f = File(imagePath(name));
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  /// فایل تصویر فقط وقتی پاک می‌شود که هیچ یادآوری‌ای از آن استفاده نکند
  void gcImage(String? name) {
    if (name == null) return;
    if (_rem.any((r) => !r.deleted && r.image == name)) return;
    deleteImageFile(name);
  }

  // ----- یادآوری‌ها -----
  List<Reminder> remindersOn(DateTime day) {
    final l = reminders.where((r) => !r.done && sameDay(r.time, day)).toList();
    l.sort((a, b) => a.time.compareTo(b.time));
    return l;
  }

  List<Reminder> get archived {
    final l = reminders.where((r) => r.done).toList();
    l.sort((a, b) => b.time.compareTo(a.time));
    return l;
  }

  void addReminder({
    required String title,
    required DateTime time,
    String note = '',
    String? catId,
    String? image,
    int repeatType = 0,
    int repeatN = 1,
  }) {
    _rem = [
      ..._rem,
      Reminder(
        id: newId(), title: title, time: time, note: note, catId: catId, image: image,
        repeatType: repeatType, repeatN: repeatN, updatedAt: nowMs(),
      ),
    ];
    _commit();
  }

  void updateReminder(
    String id, {
    required String title,
    required DateTime time,
    String note = '',
    String? catId,
    String? image,
    int repeatType = 0,
    int repeatN = 1,
  }) {
    for (final r in _rem) {
      if (r.id == id) {
        r.title = title;
        r.time = time;
        r.note = note;
        r.catId = catId;
        r.image = image;
        r.repeatType = repeatType;
        r.repeatN = repeatN;
        r.updatedAt = nowMs();
      }
    }
    _commit();
  }

  /// انجام‌شد: یادآوری بایگانی می‌شود. اگر تکرارشونده باشد، نوبت بعدی‌اش ساخته می‌شود.
  /// تابعی برمی‌گرداند که کار را برمی‌گرداند (Undo).
  VoidCallback complete(String id) {
    Reminder? r;
    for (final e in _rem) {
      if (e.id == id && !e.deleted) r = e;
    }
    if (r == null) return () {};
    final rem = r;
    if (rem.repeatType == 0) {
      rem.done = true;
      rem.updatedAt = nowMs();
      _commit();
      return () => restore(id);
    }
    final oldTime = rem.time;
    final copy = Reminder(
      id: newId(), title: rem.title, time: oldTime, done: true,
      note: rem.note, catId: rem.catId, image: rem.image, updatedAt: nowMs(),
    );
    rem.time = nextOccurrence(rem, appNow());
    rem.updatedAt = nowMs();
    _rem = [..._rem, copy];
    _commit();
    return () {
      copy.deleted = true;
      copy.updatedAt = nowMs();
      rem.time = oldTime;
      rem.updatedAt = nowMs();
      _commit();
    };
  }

  void restore(String id) {
    for (final r in _rem) {
      if (r.id == id) {
        r.done = false;
        final c = catById(r.catId);
        if (c != null && c.deleted) r.catId = null;
        r.updatedAt = nowMs();
      }
    }
    _commit();
  }

  void deleteReminder(String id) {
    String? img;
    for (final r in _rem) {
      if (r.id == id) {
        img = r.image;
        r.deleted = true;
        r.updatedAt = nowMs();
      }
    }
    gcImage(img);
    _commit();
  }

  void clearArchive() {
    final imgs = <String?>{};
    for (final r in _rem) {
      if (r.done && !r.deleted) {
        imgs.add(r.image);
        r.deleted = true;
        r.updatedAt = nowMs();
      }
    }
    for (final i in imgs) {
      gcImage(i);
    }
    _commit();
  }

  // ----- مناسبت‌های کاربر -----
  void addOccasion(String title, Jalali j, bool yearly) {
    _occ = [..._occ, UserOccasion(id: newId(), title: title, y: j.year, m: j.month, d: j.day, yearly: yearly, updatedAt: nowMs())];
    _commit();
  }

  void removeOccasion(String id) {
    for (final o in _occ) {
      if (o.id == id) {
        o.deleted = true;
        o.updatedAt = nowMs();
      }
    }
    _commit();
  }

  // ----- همگام‌سازی -----
  Map<String, dynamic> exportSyncState() => {
        'reminders': _rem.map((r) => r.toJson()).toList(),
        'cats': categories.map((c) => c.toJson()).toList(),
        'occ': _occ.map((o) => o.toJson()).toList(),
      };

  void importSyncState(Map<String, dynamic> s) {
    _rem = ((s['reminders'] as List?) ?? [])
        .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    categories = ((s['cats'] as List?) ?? [])
        .map((e) => ReminderCategory.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _occ = ((s['occ'] as List?) ?? [])
        .map((e) => UserOccasion.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _commit(fromSync: true);
  }

  /// نام تصاویری که یادآوری‌های زندهٔ فعلی به آن‌ها اشاره می‌کنند
  Set<String> get usedImages => _rem.where((r) => !r.deleted && r.image != null).map((r) => r.image!).toSet();
}

// ---------- تکرار ----------
DateTime nextOccurrence(Reminder r, DateTime after) {
  var t = r.time;
  for (var i = 0; i < 200000; i++) {
    t = _step(t, r.repeatType, r.repeatN);
    if (t.isAfter(after)) break;
  }
  return t;
}

DateTime _step(DateTime t, int type, int n) {
  switch (type) {
    case 6:
      return t.add(Duration(minutes: n));
    case 1:
      return t.add(Duration(hours: n));
    case 2:
      return DateTime(t.year, t.month, t.day + n, t.hour, t.minute);
    case 3:
      return DateTime(t.year, t.month, t.day + 7 * n, t.hour, t.minute);
    case 4:
      {
        final j = Jalali.fromDateTime(t);
        final idx = j.year * 12 + (j.month - 1) + n;
        final y = idx ~/ 12;
        final m = idx % 12 + 1;
        final d = math.min(j.day, Jalali.monthLengthOf(y, m));
        final g = Jalali(y, m, d).toDateTime();
        return DateTime(g.year, g.month, g.day, t.hour, t.minute);
      }
    case 5:
      {
        final j = Jalali.fromDateTime(t);
        final y = j.year + n;
        final d = math.min(j.day, Jalali.monthLengthOf(y, j.month));
        final g = Jalali(y, j.month, d).toDateTime();
        return DateTime(g.year, g.month, g.day, t.hour, t.minute);
      }
    default:
      return t;
  }
}

/// همهٔ مناسبت‌های یک روز شمسی (ثابت شمسی + جهانی + مناسبت‌های کاربر)
List<OccItem> occasionsOn(Jalali j) {
  final out = <OccItem>[];
  for (final o in kSolar) {
    if (o.m == j.month && o.d == j.day) out.add(OccItem(Tr.fa ? o.fa : o.en, o.holiday));
  }
  final g = j.toDateTime();
  for (final o in kGlobal) {
    if (o.m == g.month && o.d == g.day) out.add(OccItem(Tr.fa ? o.fa : o.en, false));
  }
  for (final u in app.userOcc) {
    if (u.m == j.month && u.d == j.day && (u.yearly || u.y == j.year)) {
      out.add(OccItem(u.title, false, userId: u.id));
    }
  }
  return out;
}

bool isHoliday(Jalali j) => j.weekdayIndex == 6 || occasionsOn(j).any((o) => o.holiday);
