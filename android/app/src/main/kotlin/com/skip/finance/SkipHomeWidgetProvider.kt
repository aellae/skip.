package com.skip.finance

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Locale

/**
 * Reads this-month saved/spent totals written by the Flutter app (see
 * lib/core/home_widget/home_widget_service.dart) from the SharedPreferences
 * file the `home_widget` plugin bridges into, and mirrors the two SKIP
 * aesthetics (lib/core/constants/app_colors.dart / lib/core/theme/
 * theme_provider.dart) since this AppWidgetProvider has no access to the
 * app's ThemeData. Kotlin twin of ios/SkipWidget/SkipWidget.swift.
 */
class SkipHomeWidgetProvider : HomeWidgetProvider() {

    private enum class SkipAesthetic(
        val logoText: String,
        val backgroundColor: Int,
        val textColor: Int,
        val savedColor: Int,
        val spentColor: Int,
    ) {
        MINIMAL(
            logoText = "skip.",
            backgroundColor = Color.parseColor("#FDFBF7"),
            textColor = Color.parseColor("#2C302E"),
            savedColor = Color.parseColor("#5C7A5A"),
            spentColor = Color.parseColor("#A35656"),
        ),
        Y2K(
            logoText = "SKIP!",
            backgroundColor = Color.parseColor("#241A33"),
            textColor = Color.parseColor("#E0E0E0"),
            savedColor = Color.parseColor("#00E5A0"),
            spentColor = Color.parseColor("#FF6B4A"),
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
        val aesthetic = SkipAesthetic.from(widgetData.getString("aesthetic", null))
        val currencyCode = widgetData.getString("currencyCode", null) ?: "usd"
        val saved = readDouble(widgetData, "saved")
        val spent = readDouble(widgetData, "spent")

        appWidgetIds.forEach { widgetId ->
            val views =
                RemoteViews(context.packageName, R.layout.skip_widget).apply {
                    // Tints the (opaque, white) rounded-rect background drawable via
                    // ImageView.setColorFilter's default SRC_ATOP mode, since a plain
                    // View can't take both a rounded background *and* a dynamic color.
                    setInt(R.id.widget_background, "setColorFilter", aesthetic.backgroundColor)

                    setTextViewText(R.id.widget_logo, aesthetic.logoText)
                    setTextColor(R.id.widget_logo, withAlpha(aesthetic.textColor, 0.6f))

                    setTextColor(R.id.widget_saved_label, withAlpha(aesthetic.textColor, 0.5f))
                    setTextColor(R.id.widget_spent_label, withAlpha(aesthetic.textColor, 0.5f))

                    setTextViewText(R.id.widget_saved_value, formatCurrency(saved, currencyCode))
                    setTextColor(R.id.widget_saved_value, aesthetic.savedColor)

                    setTextViewText(R.id.widget_spent_value, formatCurrency(spent, currencyCode))
                    setTextColor(R.id.widget_spent_value, aesthetic.spentColor)
                }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
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
