package com.example.mobile_expense_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class HomeWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val BALANCE_KEY = "SpendSmartWidget_balance"
        private const val TODAY_SPENT_KEY = "SpendSmartWidget_todaySpent"
        private const val TODAY_INCOME_KEY = "SpendSmartWidget_todayIncome"
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

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
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

        val views = RemoteViews(
            context.packageName,
            R.layout.home_widget_layout
        )
        views.setTextViewText(R.id.widget_balance, balance)
        views.setTextViewText(R.id.widget_today_spent, todaySpent)
        views.setTextViewText(R.id.widget_today_income, todayIncome)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
