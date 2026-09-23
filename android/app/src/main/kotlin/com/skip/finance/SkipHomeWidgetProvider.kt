package com.skip.finance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.graphics.Color
import android.graphics.Typeface
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.text.style.TypefaceSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Reads this-month saved/spent totals written by the Flutter app (see
 * lib/core/home_widget/home_widget_service.dart) from the SharedPreferences
 * file the `home_widget` plugin bridges into, and mirrors the two SKIP
 * aesthetics (lib/core/constants/app_colors.dart / lib/core/theme/
 * theme_provider.dart) since this AppWidgetProvider has no access to the
 * app's ThemeData. Kotlin twin of ios/SkipWidget/SkipWidget.swift.
 */
class SkipHomeWidgetProvider : HomeWidgetProvider() {

    private companion object {
        /** Roughly 4 launcher cells; below this the widget uses the small layout. */
        const val WIDE_MIN_WIDTH_DP = 250
    }

    private enum class SkipAesthetic(
        val logoRes: Int,
        val backgroundRes: Int,
        /** Split bar for this aesthetic; the other one is hidden. */
        val barId: Int,
        /**
         * System stand-in for the app's bundled value face (the widget can't
         * load app fonts): serif echoes Playfair Display, black sans echoes
         * Titan One.
         */
        val valueFontFamily: String,
        /**
         * The motto matches each theme's voice: a quiet italic serif aside
         * for "Skip!", a loud black shout for "Skip!".
         */
        val mottoFontFamily: String,
        val mottoStyle: Int,
        val textColor: Int,
        val savedColor: Int,
        val spentColor: Int,
    ) {
        MINIMAL(
            logoRes = R.drawable.skip_widget_logo,
            backgroundRes = R.drawable.skip_widget_bg_minimal,
            barId = R.id.widget_bar_minimal,
            valueFontFamily = "serif",
            mottoFontFamily = "serif",
            mottoStyle = Typeface.ITALIC,
            textColor = Color.parseColor("#2C302E"),
            savedColor = Color.parseColor("#5C7A5A"),
            spentColor = Color.parseColor("#A35656"),
        ),
        Y2K(
            logoRes = R.drawable.skip_widget_logo_y2k,
            backgroundRes = R.drawable.skip_widget_bg_y2k,
            barId = R.id.widget_bar_y2k,
            valueFontFamily = "sans-serif-black",
            mottoFontFamily = "sans-serif-black",
            mottoStyle = Typeface.BOLD,
            textColor = Color.parseColor("#E0E0E0"),
            savedColor = Color.parseColor("#00E5FF"),
            spentColor = Color.parseColor("#FF5FC8"),
        );

        companion object {
            fun from(value: String?): SkipAesthetic = if (value == "y2k") Y2K else MINIMAL
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { render(context, appWidgetManager, it, widgetData) }
    }

    /** Resizing across the wide threshold swaps layouts, so redraw then too. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun render(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val aesthetic = SkipAesthetic.from(widgetData.getString("aesthetic", null))
        val currencyCode = widgetData.getString("currencyCode", null) ?: "usd"
        val saved = readDouble(widgetData, "saved")
        val spent = readDouble(widgetData, "spent")
        // Translated by the app; the strings.xml copies only cover the gap
        // before the app has pushed anything.
        val savedLabel =
            widgetData.getString("savedLabel", null)
                ?: context.getString(R.string.skip_widget_saved_label)
        val spentLabel =
            widgetData.getString("spentLabel", null)
                ?: context.getString(R.string.skip_widget_spent_label)

        // Wide from about 4 cells across, matching the iOS medium widget.
        val minWidthDp =
            appWidgetManager
                .getAppWidgetOptions(widgetId)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val isWide = minWidthDp >= WIDE_MIN_WIDTH_DP

        val labelColor = withAlpha(aesthetic.textColor, 0.55f)
        val month =
            SimpleDateFormat(if (isWide) "LLLL" else "LLL", Locale.getDefault())
                .format(Date())
                .uppercase(Locale.getDefault())

        // Saved share of this month's decisions by amount; secondaryProgress
        // fills the rest with the spent color, or stays 0 to show the empty
        // track when nothing's been logged.
        val total = saved.coerceAtLeast(0.0) + spent.coerceAtLeast(0.0)
        val savedPercent = if (total > 0) (saved.coerceAtLeast(0.0) / total * 100).toInt() else 0
        val spentFill = if (total > 0) 100 else 0

        val layout = if (isWide) R.layout.skip_widget_wide else R.layout.skip_widget
        val views =
            RemoteViews(context.packageName, layout).apply {
                setImageViewResource(R.id.widget_background, aesthetic.backgroundRes)
                setImageViewResource(R.id.widget_logo, aesthetic.logoRes)

                setTextViewText(R.id.widget_month, month)
                setTextColor(R.id.widget_month, withAlpha(aesthetic.textColor, 0.5f))

                setTextViewText(
                    R.id.widget_saved_label,
                    dotLabel(savedLabel.uppercase(Locale.getDefault()), aesthetic.savedColor),
                )
                setTextColor(R.id.widget_saved_label, labelColor)
                setTextViewText(
                    R.id.widget_spent_label,
                    dotLabel(spentLabel.uppercase(Locale.getDefault()), aesthetic.spentColor),
                )
                setTextColor(R.id.widget_spent_label, labelColor)

                setTextViewText(
                    R.id.widget_saved_value,
                    styledValue(formatCurrency(saved, currencyCode), aesthetic.valueFontFamily),
                )
                setTextColor(R.id.widget_saved_value, aesthetic.savedColor)

                setTextViewText(
                    R.id.widget_spent_value,
                    styledValue(formatCurrency(spent, currencyCode), aesthetic.valueFontFamily),
                )
                setTextColor(R.id.widget_spent_value, aesthetic.spentColor)

                if (isWide) {
                    setTextViewText(
                        R.id.widget_motto,
                        styled(
                            motto(widgetData, isEmpty = total == 0.0),
                            aesthetic.mottoFontFamily,
                            aesthetic.mottoStyle,
                        ),
                    )
                    setTextColor(R.id.widget_motto, withAlpha(aesthetic.textColor, 0.8f))
                }

                SkipAesthetic.values().forEach {
                    setViewVisibility(it.barId, if (it == aesthetic) View.VISIBLE else View.GONE)
                }
                setProgressBar(aesthetic.barId, 100, savedPercent, false)
                setInt(aesthetic.barId, "setSecondaryProgress", spentFill)
            }
        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /**
     * Today's line, already translated and in the aesthetic's voice (see
     * `widgetMottosMinimal`/`widgetMottosY2k` in app_strings.dart). One per
     * local calendar day, so it rotates without the app being opened.
     */
    private fun motto(prefs: SharedPreferences, isEmpty: Boolean): String {
        if (isEmpty) prefs.getString("mottoEmpty", null)?.let { return it }
        val mottos = prefs.getString("mottos", null)?.split("\n")?.filter { it.isNotBlank() }
        if (mottos.isNullOrEmpty()) return ""
        val now = System.currentTimeMillis()
        val localDay = (now + TimeZone.getDefault().getOffset(now)) / 86_400_000L
        return mottos[(localDay % mottos.size).toInt()]
    }

    /** "● LABEL", with the dot in the stat's color. */
    private fun dotLabel(label: String, dotColor: Int): CharSequence =
        SpannableString("\u25CF  $label").apply {
            setSpan(ForegroundColorSpan(dotColor), 0, 1, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

    private fun styledValue(value: String, fontFamily: String): CharSequence =
        styled(value, fontFamily, Typeface.BOLD)

    private fun styled(text: String, fontFamily: String, style: Int): CharSequence =
        SpannableString(text).apply {
            setSpan(TypefaceSpan(fontFamily), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(StyleSpan(style), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        }

    /** `home_widget`'s `saveWidgetData<double>` stores doubles as raw bits in a Long. */
    private fun readDouble(prefs: SharedPreferences, key: String): Double =
        java.lang.Double.longBitsToDouble(prefs.getLong(key, 0L))

    private fun withAlpha(color: Int, alpha: Float): Int =
        Color.argb((alpha * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))

    /**
     * Ports the two currency conventions from `currency_formatter.dart`'s
     * `formatCurrency`: USD is `$1,234.56` (prefix, comma thousands, dot
     * decimal); EUR is `1.234,56 €` (suffix, dot thousands, comma decimal).
     */
    private fun formatCurrency(value: Double, currencyCode: String): String {
        val isEuro = currencyCode.lowercase(Locale.ROOT) == "eur"
        val isNegative = value < 0
        val fixed = String.format(Locale.ROOT, "%.2f", Math.abs(value))
        val parts = fixed.split(".")
        val digits = parts[0]
        val cents = if (parts.size > 1) parts[1] else "00"

        val thousandsSeparator = if (isEuro) "." else ","
        val grouped = StringBuilder()
        for (index in digits.indices) {
            val distanceFromEnd = digits.length - index
            if (index > 0 && distanceFromEnd % 3 == 0) {
                grouped.append(thousandsSeparator)
            }
            grouped.append(digits[index])
        }

        val sign = if (isNegative) "-" else ""
        return if (isEuro) "$sign$grouped,$cents €" else "$sign\$$grouped.$cents"
    }
}
