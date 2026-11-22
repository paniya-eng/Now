package com.now.now_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar

/** ویجت صفحهٔ اصلی: کارت تاریخ شمسی (چپ) + ساعت (راست) */
class NowWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
        scheduleMidnight(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_MIDNIGHT,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> refreshAll(context)
        }
    }

    companion object {
        const val ACTION_MIDNIGHT = "com.now.now_app.MIDNIGHT"

        private val ACCENTS = arrayOf("#2F6BFF", "#FF7A1A", "#E8362B", "#12A594", "#8B5CF6", "#EC4899")
        private val MONTHS_FA = arrayOf("فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند")
        private val MONTHS_EN = arrayOf("Farvardin", "Ordibehesht", "Khordad", "Tir", "Mordad", "Shahrivar", "Mehr", "Aban", "Azar", "Dey", "Bahman", "Esfand")
        private val DAYS_FA = arrayOf("شنبه", "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه")
        private val DAYS_EN = arrayOf("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday")

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, NowWidgetProvider::class.java))
            for (id in ids) mgr.updateAppWidget(id, build(context))
            if (ids.isNotEmpty()) scheduleMidnight(context)
        }

        private fun scheduleMidnight(context: Context) {
            try {
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val cal = Calendar.getInstance()
                cal.add(Calendar.DAY_OF_YEAR, 1)
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 5)
                cal.set(Calendar.MILLISECOND, 0)
                val intent = Intent(context, NowWidgetProvider::class.java).setAction(ACTION_MIDNIGHT)
                val pi = PendingIntent.getBroadcast(
                    context, 1, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                am.set(AlarmManager.RTC, cal.timeInMillis, pi)
            } catch (_: Exception) {
            }
        }

        private fun faDigits(s: String): String {
            val sb = StringBuilder()
            for (c in s) sb.append(if (c in '0'..'9') ('۰' + (c - '0')) else c)
            return sb.toString()
        }

        private fun build(context: Context): RemoteViews {
            // خواندن تنظیمات برنامهٔ فلاتر (زبان، رنگ، ۲۴ ساعته)
            var fa = true
            var accent = 0
            var h24 = true
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val raw = prefs.getString("flutter.data", null)
                if (raw != null) {
                    val j = JSONObject(raw)
                    fa = j.optString("lang", "fa") == "fa"
                    accent = j.optInt("accent", 0)
                    h24 = j.optBoolean("h24", true)
                }
            } catch (_: Exception) {
            }

            val cal = Calendar.getInstance()
            val jal = gregorianToJalali(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH))
            val dow = cal.get(Calendar.DAY_OF_WEEK) // یکشنبه=1 ... شنبه=7
            val wd = dow % 7 // شنبه=0 ... جمعه=6
            val month = (if (fa) MONTHS_FA else MONTHS_EN)[jal[1] - 1]
            val weekday = (if (fa) DAYS_FA else DAYS_EN)[wd]
            val dayText = if (fa) faDigits(jal[2].toString()) else jal[2].toString()

            val v = RemoteViews(context.packageName, R.layout.now_widget)
            v.setTextViewText(R.id.wd_month, "$weekday  $month")
            v.setTextViewText(R.id.day, dayText)
            val color = if (wd == 6) Color.parseColor("#E8564B") else Color.parseColor(ACCENTS[accent.coerceIn(0, ACCENTS.size - 1)])
            v.setTextColor(R.id.day, color)
            val fmt = if (h24) "HH:mm" else "h:mm"
            v.setCharSequence(R.id.clock, "setFormat24Hour", fmt)
            v.setCharSequence(R.id.clock, "setFormat12Hour", fmt)

            val open = Intent(context, MainActivity::class.java)
            val pi = PendingIntent.getActivity(
                context, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            v.setOnClickPendingIntent(R.id.root, pi)
            return v
        }

        /** تبدیل میلادی به شمسی (همان الگوریتم برنامه) */
        private fun gregorianToJalali(gy0: Int, gm: Int, gd: Int): IntArray {
            val gdm = intArrayOf(0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
            var gy = gy0
            var jy: Int
            if (gy > 1600) {
                jy = 979
                gy -= 1600
            } else {
                jy = 0
                gy -= 621
            }
            val gy2 = if (gm > 2) gy + 1 else gy
            var days = 365 * gy + (gy2 + 3) / 4 - (gy2 + 99) / 100 + (gy2 + 399) / 400 - 80 + gd + gdm[gm - 1]
            jy += 33 * (days / 12053)
            days %= 12053
            jy += 4 * (days / 1461)
            days %= 1461
            if (days > 365) {
                jy += (days - 1) / 365
                days = (days - 1) % 365
            }
            val jm: Int
            val jd: Int
            if (days < 186) {
                jm = 1 + days / 31
                jd = 1 + days % 31
            } else {
                jm = 7 + (days - 186) / 30
                jd = 1 + (days - 186) % 30
            }
            return intArrayOf(jy, jm, jd)
        }
    }
}
