// متن‌های برنامه به دو زبان فارسی و انگلیسی
class Tr {
  static String lang = 'fa';
  static bool get fa => lang == 'fa';
  static String t(String k) => (fa ? _fa : _en)[k] ?? k;

  static String nd(Object n) {
    final s = n.toString();
    if (!fa) return s;
    const p = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final c in s.codeUnits) {
      b.write(c >= 48 && c <= 57 ? p[c - 48] : String.fromCharCode(c));
    }
    return b.toString();
  }

  static const _jmFa = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];
  static const _jmEn = ['Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar', 'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand'];
  static const _wdFa = ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'];
  static const _wdEn = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  static const _wsFa = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
  static const _wsEn = ['Sa', 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr'];
  static const _gmFa = ['ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن', 'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر'];
  static const _gmEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  static String jMonth(int m) => (fa ? _jmFa : _jmEn)[m - 1];
  static String weekday(int i) => (fa ? _wdFa : _wdEn)[i];
  static String weekdayShort(int i) => (fa ? _wsFa : _wsEn)[i];
  static String gMonth(int m) => (fa ? _gmFa : _gmEn)[m - 1];

  static const _fa = {
    'home': 'خانه', 'calendar': 'تقویم', 'clock': 'ساعت', 'search': 'جستجو', 'profile': 'پروفایل',
    'new_reminder': 'یادآوری جدید', 'edit_reminder': 'ویرایش یادآوری', 'reminders': 'یادآوری‌ها',
    'no_reminders_today': 'برای امروز یادآوری‌ای نیست', 'no_reminders_day': 'برای این روز یادآوری‌ای نیست',
    'occasions': 'مناسبت‌ها', 'no_occasion': 'امروز مناسبت ثبت‌شده‌ای نیست', 'no_occasion_day': 'مناسبتی برای این روز ثبت نشده',
    'holiday': 'تعطیل', 'archive': 'بایگانی', 'archive_empty': 'بایگانی خالی است', 'delete_all': 'حذف همه',
    'confirm_delete_all': 'همهٔ موارد بایگانی حذف شود؟', 'done_moved': 'به بایگانی رفت', 'undo': 'بازگردانی',
    'title_hint': 'عنوان یادآوری', 'date': 'تاریخ', 'time': 'ساعت', 'save': 'ذخیره', 'cancel': 'انصراف',
    'delete': 'حذف', 'ok': 'تأیید', 'add_reminder': 'افزودن یادآوری', 'add_occasion': 'افزودن مناسبت',
    'occasion_title': 'عنوان مناسبت', 'repeat_yearly': 'تکرار هر سال', 'my_occasions': 'مناسبت‌های من',
    'world_clock': 'ساعت جهانی', 'add_city': 'افزودن شهر', 'choose_city': 'انتخاب شهر', 'max_cities': 'حداکثر ۳ شهر',
    'timer': 'تایمر', 'stopwatch': 'کورنومتر', 'start': 'شروع', 'pause': 'توقف', 'resume': 'ادامه',
    'reset': 'ریست', 'lap': 'دور', 'laps': 'دورها', 'hours': 'ساعت', 'minutes': 'دقیقه', 'seconds': 'ثانیه',
    'timer_done': 'زمان تایمر تمام شد', 'search_hint': 'جستجو در یادآوری‌ها و مناسبت‌ها',
    'search_empty': 'عبارتی را بنویس تا بین یادآوری‌ها و مناسبت‌ها جستجو کنم', 'no_results': 'نتیجه‌ای پیدا نشد',
    'sec_reminders': 'یادآوری‌ها', 'sec_archived': 'بایگانی', 'sec_my_occ': 'مناسبت‌های من', 'sec_builtin': 'مناسبت‌های تقویم',
    'language': 'زبان', 'appearance': 'ظاهر', 'theme': 'حالت نمایش', 'light': 'روشن', 'dark': 'تاریک', 'system': 'خودکار',
    'color': 'رنگ', 'font': 'فونت', 'font_app': 'فونت برنامه', 'font_system': 'فونت سیستم', 'font_size': 'اندازهٔ متن',
    'small': 'کوچک', 'normal': 'متوسط', 'large': 'بزرگ', 'clock_settings': 'ساعت', 'h24': 'نمایش ۲۴ ساعته',
    'show_seconds': 'نمایش ثانیه', 'reminder_settings': 'تنظیمات یادآوری', 'silent_after': 'توقف خودکار زنگ بعد از',
    'snooze_len': 'مدت تعویق (Snooze)', 'never': 'هرگز', 'min_unit': 'دقیقه',
    'reminder_note': 'زنگ هشدار با اعلان سیستم هم کار می‌کند؛ در اندروید حتی وقتی برنامه بسته است. در ویندوز برنامه باید در کنار ساعت (Tray) در حال اجرا باشد.',
    'about': 'دربارهٔ برنامه', 'version': 'نسخه', 'credits': 'آیکون‌ها: Lucide (ISC) • مناسبت‌های جهانی: سازمان ملل، یونسکو و WHO (un.org/en/observances) • فونت: پوشهٔ fonts',
    'today': 'امروز', 'tomorrow': 'فردا', 'yesterday': 'دیروز', 'am': 'ق.ظ', 'pm': 'ب.ظ',
    'note_hint': 'توضیحات (اختیاری)', 'category': 'دسته‌بندی (اختیاری)', 'no_category': 'بدون دسته', 'new_category': 'دستهٔ جدید',
    'edit_category': 'ویرایش دسته', 'cat_name': 'نام دسته', 'cat_color': 'رنگ', 'categories': 'دسته‌بندی‌ها', 'cat_deleted': 'دستهٔ حذف‌شده',
    'cat_active': 'فعال', 'cat_archived': 'بایگانی', 'no_categories': 'هنوز دسته‌ای نساخته‌ای',
    'confirm_delete_cat': 'این دسته حذف شود؟ یادآوری‌های فعال بدون دسته می‌شوند و روی یادآوری‌های بایگانی‌شده نام این دسته باقی می‌ماند.',
    'repeat': 'تکرار', 'rep_none': 'بدون تکرار', 'every': 'هر', 'image': 'تصویر (اختیاری)', 'take_photo': 'عکس گرفتن',
    'from_gallery': 'انتخاب از گالری', 'from_file': 'انتخاب تصویر', 'replace': 'تغییر', 'remove': 'حذف',
    'hold_hint': 'برای تغییر سریع، دکمه‌های ▲ ▼ را نگه دار یا چرخ ماوس را بچرخان',
    'notify_before': 'یادآوری زودتر از موعد', 'lead_note': 'در لحظهٔ موعد هم یادآوری می‌شود. می‌توانی چند گزینه را هم‌زمان انتخاب کنی. هشدار زودتر هم با همین روش (برنامه باز یا در پس‌زمینه) نمایش داده می‌شود.',
    'sec_categories': 'دسته‌بندی‌ها', 'add_in_category': 'افزودن یادآوری در این دسته', 'manage_categories': 'مدیریت دسته‌بندی‌ها',
    'alarm_sound': 'صدای زنگ', 'add_sound': 'افزودن صدای دلخواه', 'sound_bell': 'زنگ', 'sound_chime': 'ملودی ملایم',
    'sound_beep': 'بوق دیجیتال', 'sound_melody': 'ملودی بیدارباش', 'sound_hint': 'فایل صوتی دلخواهت (mp3 ،wav و...) را اضافه کن؛ یک نسخه از آن داخل برنامه ذخیره می‌شود.',
    'snooze_word': 'تعویق', 'dismiss': 'بستن', 'mark_done': 'انجام شد',
    'sync_title': 'همگام‌سازی ویندوز و موبایل', 'sync_hint': 'یک سرور همگام‌سازی راه بینداز و همین آدرس و کلید را در برنامهٔ ویندوز و موبایل وارد کن (راهنما: پوشهٔ server).',
    'sync_url': 'آدرس سرور (مثلاً 192.168.1.5:8787)', 'sync_key': 'کلید همگام‌سازی (حداقل ۸ نویسه)', 'sync_auto': 'همگام‌سازی خودکار',
    'sync_now': 'همگام‌سازی همین حالا', 'sync_save': 'ذخیره و همگام‌سازی', 'sync_never': 'هنوز همگام‌سازی نشده', 'sync_last': 'آخرین همگام‌سازی',
    'sync_running': 'در حال همگام‌سازی...', 'sync_err_auth': 'کلید پذیرفته نشد', 'sync_err_net': 'اتصال به سرور برقرار نشد', 'sync_err_other': 'خطا',
    'clock_title': 'ساعت برنامه', 'clock_set': 'تنظیم ساعت', 'clock_reset': 'برگشت به ساعت دستگاه',
    'clock_note': 'فقط ساعت و تاریخ داخل برنامه و زمان هشدارها تغییر می‌کند؛ ساعت خود گوشی یا ویندوز عوض نمی‌شود.',
    'desktop_group': 'ویندوز', 'run_startup': 'اجرا با روشن شدن ویندوز', 'close_tray': 'بستن پنجره = ماندن در کنار ساعت ویندوز (برای زنگ در پس‌زمینه)',
    'widget_mode': 'نمایش ویجت روی دسکتاپ', 'tray_show': 'نمایش برنامه', 'tray_widget': 'ویجت دسکتاپ', 'tray_quit': 'خروج', 'widget_back': 'بازگشت به برنامه',
    'bg_title': 'زنگ وقتی گوشی قفل است',
    'bg_note': 'برای اینکه زنگ در حالت قفل و بسته بودن برنامه هم بخورد: دسترسی «اعلان‌ها» و «آلارم و یادآور دقیق» را به برنامه بده و باتری برنامه را روی «بدون محدودیت» بگذار. اگر صدای دلخواه انتخاب کرده باشی، در حالت قفل صدای «زنگ» پخش می‌شود.',
    'share': 'اشتراک‌گذاری',
    'test_alarm': 'اعلان آزمایشی (۱۰ ثانیه دیگر)', 'test_alarm_sent': 'اعلان آزمایشی برنامه‌ریزی شد؛ ۱۰ ثانیه دیگر ببین. می‌توانی برنامه را ببندی و گوشی را قفل کنی.',
    'select_date': 'انتخاب تاریخ', 'select_time': 'انتخاب ساعت', 'empty_title': 'عنوان را وارد کن',
  };

  static const _en = {
    'home': 'Home', 'calendar': 'Calendar', 'clock': 'Clock', 'search': 'Search', 'profile': 'Profile',
    'new_reminder': 'New reminder', 'edit_reminder': 'Edit reminder', 'reminders': 'Reminders',
    'no_reminders_today': 'No reminders for today', 'no_reminders_day': 'No reminders for this day',
    'occasions': 'Occasions', 'no_occasion': 'No occasions today', 'no_occasion_day': 'No occasions for this day',
    'holiday': 'Holiday', 'archive': 'Archive', 'archive_empty': 'Archive is empty', 'delete_all': 'Delete all',
    'confirm_delete_all': 'Delete everything in the archive?', 'done_moved': 'Moved to archive', 'undo': 'Undo',
    'title_hint': 'Reminder title', 'date': 'Date', 'time': 'Time', 'save': 'Save', 'cancel': 'Cancel',
    'delete': 'Delete', 'ok': 'OK', 'add_reminder': 'Add reminder', 'add_occasion': 'Add occasion',
    'occasion_title': 'Occasion title', 'repeat_yearly': 'Repeat every year', 'my_occasions': 'My occasions',
    'world_clock': 'World clock', 'add_city': 'Add city', 'choose_city': 'Choose a city', 'max_cities': 'Up to 3 cities',
    'timer': 'Timer', 'stopwatch': 'Stopwatch', 'start': 'Start', 'pause': 'Pause', 'resume': 'Resume',
    'reset': 'Reset', 'lap': 'Lap', 'laps': 'Laps', 'hours': 'Hours', 'minutes': 'Minutes', 'seconds': 'Seconds',
    'timer_done': "Time's up", 'search_hint': 'Search reminders and occasions',
    'search_empty': 'Type something to search reminders and occasions', 'no_results': 'No results',
    'sec_reminders': 'Reminders', 'sec_archived': 'Archive', 'sec_my_occ': 'My occasions', 'sec_builtin': 'Calendar occasions',
    'language': 'Language', 'appearance': 'Appearance', 'theme': 'Theme', 'light': 'Light', 'dark': 'Dark', 'system': 'System',
    'color': 'Color', 'font': 'Font', 'font_app': 'App font', 'font_system': 'System font', 'font_size': 'Text size',
    'small': 'Small', 'normal': 'Medium', 'large': 'Large', 'clock_settings': 'Clock', 'h24': '24-hour time',
    'show_seconds': 'Show seconds', 'reminder_settings': 'Reminder settings', 'silent_after': 'Silent after',
    'snooze_len': 'Snooze length', 'never': 'Never', 'min_unit': 'min',
    'reminder_note': 'Alarms also work through system notifications; on Android even when the app is closed. On Windows the app must keep running in the tray.',
    'about': 'About', 'version': 'Version', 'credits': 'Icons: Lucide (ISC) • Global days: UN, UNESCO, WHO (un.org/en/observances) • Font: see the fonts folder',
    'today': 'Today', 'tomorrow': 'Tomorrow', 'yesterday': 'Yesterday', 'am': 'AM', 'pm': 'PM',
    'note_hint': 'Notes (optional)', 'category': 'Category (optional)', 'no_category': 'No category', 'new_category': 'New category',
    'edit_category': 'Edit category', 'cat_name': 'Category name', 'cat_color': 'Color', 'categories': 'Categories', 'cat_deleted': 'deleted category',
    'cat_active': 'active', 'cat_archived': 'archived', 'no_categories': 'No categories yet',
    'confirm_delete_cat': 'Delete this category? Active reminders become uncategorized; archived reminders keep this category name as a label.',
    'repeat': 'Repeat', 'rep_none': 'No repeat', 'every': 'Every', 'image': 'Image (optional)', 'take_photo': 'Take photo',
    'from_gallery': 'Choose from gallery', 'from_file': 'Choose image', 'replace': 'Change', 'remove': 'Remove',
    'hold_hint': 'Hold the ▲ ▼ buttons for fast change, or use the mouse wheel',
    'notify_before': 'Remind me earlier', 'lead_note': 'You are always reminded at the exact time too. You can pick several options. Early alerts work the same way (app open or in the background).',
    'sec_categories': 'Categories', 'add_in_category': 'Add reminder in this category', 'manage_categories': 'Manage categories',
    'alarm_sound': 'Alarm sound', 'add_sound': 'Add your own sound', 'sound_bell': 'Bell', 'sound_chime': 'Soft chime',
    'sound_beep': 'Digital beep', 'sound_melody': 'Wake-up melody', 'sound_hint': 'Add your own audio file (mp3, wav, ...); a copy is stored inside the app.',
    'snooze_word': 'Snooze', 'dismiss': 'Dismiss', 'mark_done': 'Done',
    'sync_title': 'Windows & phone sync', 'sync_hint': 'Run a sync server and enter the same address and key in the Windows and phone apps (guide: server folder).',
    'sync_url': 'Server address (e.g. 192.168.1.5:8787)', 'sync_key': 'Sync key (at least 8 characters)', 'sync_auto': 'Automatic sync',
    'sync_now': 'Sync now', 'sync_save': 'Save and sync', 'sync_never': 'Not synced yet', 'sync_last': 'Last sync',
    'sync_running': 'Syncing...', 'sync_err_auth': 'Key was not accepted', 'sync_err_net': 'Could not reach the server', 'sync_err_other': 'Error',
    'clock_title': 'App clock', 'clock_set': 'Set time', 'clock_reset': 'Back to device time',
    'clock_note': 'Only the time and date inside the app and the alarm times change; the phone or Windows clock itself is untouched.',
    'desktop_group': 'Windows', 'run_startup': 'Start with Windows', 'close_tray': 'Closing the window keeps the app in the tray (for background alarms)',
    'widget_mode': 'Show desktop widget', 'tray_show': 'Show app', 'tray_widget': 'Desktop widget', 'tray_quit': 'Quit', 'widget_back': 'Back to app',
    'bg_title': 'Alarm when the phone is locked',
    'bg_note': 'To ring while the phone is locked or the app is closed: allow Notifications and Alarms & reminders for the app, and set its battery usage to Unrestricted. If you picked a custom sound, the built-in Bell plays while locked.',
    'share': 'Share',
    'test_alarm': 'Test alarm (in 10 seconds)', 'test_alarm_sent': 'Test alarm scheduled; watch in 10 seconds. You can close the app and lock the phone.',
    'select_date': 'Select date', 'select_time': 'Select time', 'empty_title': 'Enter a title',
  };
}

String tr(String k) => Tr.t(k);
String nd(Object n) => Tr.nd(n);
