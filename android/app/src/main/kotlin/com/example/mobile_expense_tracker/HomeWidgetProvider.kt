package com.example.mobile_expense_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class HomeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val BALANCE_KEY = "SpendSmartWidget_balance"
        private const val TODAY_SPENT_KEY = "SpendSmartWidget_todaySpent"
        private const val TODAY_INCOME_KEY = "SpendSmartWidget_todayIncome"

        private const val LIGHT_BG = 0xFFFFFFFF.toInt()
        private const val DARK_BG = 0xFF2D2D2D.toInt()
        private const val LIGHT_TEXT = 0xFF1A1A2E.toInt()
        private const val DARK_TEXT = 0xFFFFFFFF.toInt()
        private const val LIGHT_SECONDARY = 0xFF999999.toInt()
        private const val DARK_SECONDARY = 0xFFA0A0A0.toInt()
        private const val LIGHT_SPENT = 0xFFFF6B6B.toInt()
        private const val DARK_SPENT = 0xFFFF8A80.toInt()
        private const val LIGHT_INCOME = 0xFF4CAF50.toInt()
        private const val DARK_INCOME = 0xFF81C784.toInt()
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val prefs = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE
        )

        val balance = prefs.getString(BALANCE_KEY, "\$0.00") ?: "\$0.00"
        val todaySpent = prefs.getString(TODAY_SPENT_KEY, "\$0") ?: "\$0"
        val todayIncome = prefs.getString(TODAY_INCOME_KEY, "\$0") ?: "\$0"

        val isNightMode = (context.resources.configuration.uiMode
            and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        val bgColor = if (isNightMode) DARK_BG else LIGHT_BG
        val textPrimary = if (isNightMode) DARK_TEXT else LIGHT_TEXT
        val textSecondary = if (isNightMode) DARK_SECONDARY else LIGHT_SECONDARY
        val spentColor = if (isNightMode) DARK_SPENT else LIGHT_SPENT
        val incomeColor = if (isNightMode) DARK_INCOME else LIGHT_INCOME

        val bgResId = if (isNightMode) R.drawable.widget_bg_dark else R.drawable.widget_bg_light

        val views = RemoteViews(
            context.packageName,
            R.layout.home_widget_layout
        )

        views.setInt(R.id.widget_container, "setBackgroundResource", bgResId)
        views.setTextColor(R.id.widget_title, textPrimary)
        views.setTextColor(R.id.widget_balance, textPrimary)
        views.setTextColor(R.id.widget_balance_label, textSecondary)
        views.setTextColor(R.id.widget_spent_label, textSecondary)
        views.setTextColor(R.id.widget_today_spent, spentColor)
        views.setTextColor(R.id.widget_income_label, textSecondary)
        views.setTextColor(R.id.widget_today_income, incomeColor)

        views.setTextViewText(R.id.widget_balance, balance)
        views.setTextViewText(R.id.widget_today_spent, todaySpent)
        views.setTextViewText(R.id.widget_today_income, todayIncome)

        val openIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java
        )
        views.setOnClickPendingIntent(R.id.widget_container, openIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}