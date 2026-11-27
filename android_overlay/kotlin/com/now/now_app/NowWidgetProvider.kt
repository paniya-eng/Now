package com.now.now_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.util.Calendar

/** ویجت صفحهٔ اصلی: کارت تاریخ شمسی + کارت ساعت و تاریخ میلادی (مدل سفید) */
open class NowWidgetProvider : AppWidgetProvider() {

    open val transparent: Boolean get() = false

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context, manager, id, transparent))
        scheduleMidnight(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, newOptions: Bundle) {
        super.onAppWidgetOptionsChanged(context, manager, id, newOptions)
        manager.updateAppWidget(id, build(context, manager, id, transparent))
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

        private val MONTHS_FA = arrayOf("فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند")
        private val MONTHS_EN = arrayOf("Farvardin", "Ordibehesht", "Khordad", "Tir", "Mordad", "Shahrivar", "Mehr", "Aban", "Azar", "Dey", "Bahman", "Esfand")
        private val DAYS_FA = arrayOf("شنبه", "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه")
        private val DAYS_EN = arrayOf("Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday")

        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            var any = false
            val kinds = listOf(
                Pair(NowWidgetProvider::class.java, false),
                Pair(NowWidgetTransparentProvider::class.java, true)
            )
            for ((cls, tr) in kinds) {
                val ids = mgr.getAppWidgetIds(ComponentName(context, cls))
                for (id in ids) {
                    mgr.updateAppWidget(id, build(context, mgr, id, tr))
                    any = true
                }
            }
            if (any) scheduleMidnight(context)
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

        private fun build(context: Context, manager: AppWidgetManager, id: Int, transparent: Boolean): RemoteViews {
            // خواندن تنظیمات برنامهٔ فلاتر (زبان، رنگ، ۲۴ ساعته)
            var fa = true
            var accent = Color.parseColor("#2F6BFF")
            var h24 = true
            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val raw = prefs.getString("flutter.data", null)
                if (raw != null) {
                    val j = JSONObject(raw)
                    fa = j.optString("lang", "fa") == "fa"
                    if (j.has("accentColor")) accent = j.optLong("accentColor").toInt()
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
            val yearText = if (fa) faDigits(jal[0].toString()) else jal[0].toString()

            val layout = when {
                transparent && fa -> R.layout.now_widget_transparent_fa
                transparent -> R.layout.now_widget_transparent_en
                fa -> R.layout.now_widget_fa
                else -> R.layout.now_widget_en
            }
            val v = RemoteViews(context.packageName, layout)

            // «ماه» کم‌رنگ و «روز هفته» پررنگ، مثل طرح برنامه
            val monthColor = if (transparent) Color.WHITE else Color.parseColor("#777777")
            val dayColor = if (transparent) Color.WHITE else Color.parseColor("#111111")
            val line = SpannableStringBuilder()
            line.append(month, ForegroundColorSpan(monthColor), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            line.append("  ")
            val start = line.length
            line.append(weekday)
            line.setSpan(StyleSpan(Typeface.BOLD), start, line.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            line.setSpan(ForegroundColorSpan(dayColor), start, line.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            v.setTextViewText(R.id.wd_month, line)
            v.setTextViewText(R.id.day, dayText)
            v.setTextViewText(R.id.year, yearText)
            if (!transparent) {
                val numColor = if (wd == 6) Color.parseColor("#E8564B") else accent
                v.setTextColor(R.id.day, numColor)
            }

            // اندازهٔ متن‌ها متناسب با اندازهٔ ویجت
            val opts = manager.getAppWidgetOptions(id)
            val wDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 260).toFloat()
            val hDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 120).toFloat()
            val cardH = (hDp - 8f).coerceAtLeast(60f)
            val dateW = (wDp - 24f) * 5f / 11f
            val clockW = (wDp - 24f) * 6f / 11f
            v.setTextViewTextSize(R.id.day, TypedValue.COMPLEX_UNIT_DIP, minOf(cardH * 0.46f, dateW * 0.55f))
            v.setTextViewTextSize(R.id.wd_month, TypedValue.COMPLEX_UNIT_DIP, minOf(cardH * 0.12f, dateW * 0.12f))
            v.setTextViewTextSize(R.id.year, TypedValue.COMPLEX_UNIT_DIP, minOf(cardH * 0.11f, dateW * 0.11f))
            val clockSize = minOf(cardH * 0.34f, clockW * 0.30f)
            val smallSize = minOf(cardH * 0.11f, clockW * 0.10f)

            // ساعت فارسی: فونت با ارقام فارسی؛ در حالت انگلیسی فونت با ارقام لاتین
            val fmt = if (h24) "HH:mm" else "h:mm"
            for (cid in intArrayOf(R.id.clock, R.id.clock_en)) {
                v.setTextViewTextSize(cid, TypedValue.COMPLEX_UNIT_DIP, clockSize)
                v.setCharSequence(cid, "setFormat24Hour", fmt)
                v.setCharSequence(cid, "setFormat12Hour", fmt)
            }
            for (cid in intArrayOf(R.id.date_g, R.id.date_g_en)) {
                v.setTextViewTextSize(cid, TypedValue.COMPLEX_UNIT_DIP, smallSize)
            }
            v.setViewVisibility(R.id.clock, if (fa) View.VISIBLE else View.GONE)
            v.setViewVisibility(R.id.clock_en, if (fa) View.GONE else View.VISIBLE)
            v.setViewVisibility(R.id.date_g, if (fa) View.VISIBLE else View.GONE)
            v.setViewVisibility(R.id.date_g_en, if (fa) View.GONE else View.VISIBLE)

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

/** ویجت با پس‌زمینهٔ شفاف (متن سفید روی والپیپر) */
class NowWidgetTransparentProvider : NowWidgetProvider() {
    override val transparent: Boolean get() = true
}
