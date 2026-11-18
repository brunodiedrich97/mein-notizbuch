package com.brunodiedrich.mein_notizbuch

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Widget "Palavra do dia".
 *
 * O app grava em "daily_words" o plano dos próximos dias (data, palavra,
 * classe, significado e cores). Aqui o widget escolhe a entrada de hoje, o
 * que funciona mesmo com o app fechado: o sistema chama onUpdate a cada
 * hora (updatePeriodMillis), e a palavra troca logo depois da meia-noite.
 */
class DailyWordWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) render(context, appWidgetManager, id, widgetData)
    }

    /** Ao redimensionar, troca entre os layouts compacto, quadrado, largo e alto. */
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
        manager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences,
    ) {
        // Em retrato, a largura útil é a mínima e a altura útil é a máxima.
        val options = manager.getAppWidgetOptions(widgetId)
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110)
        val small = width < 200
        // Compacto (4x1) e quadrado não têm cabeçalho nem data.
        val compact = !small && height < 100
        val layout = when {
            small -> R.layout.daily_word_widget_small
            compact -> R.layout.daily_word_widget_compact
            height >= 180 -> R.layout.daily_word_widget_large
            else -> R.layout.daily_word_widget
        }
        val views = RemoteViews(context.packageName, layout)

        val entry = todayEntry(data.getString("daily_words", null))
        val dark = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

        var uri = Uri.parse("meinnotizbuch://home")
        if (entry == null) {
            // Sem palavras cadastradas (ou o app ainda não foi aberto).
            views.setTextViewText(R.id.word, "Mein Notizbuch")
            views.setTextViewText(R.id.category, "Cadastre uma palavra no Notizbuch")
            views.setViewVisibility(R.id.meaning, View.GONE)
        } else {
            val color = (if (dark) entry.getLong("colorDark") else entry.getLong("colorLight")).toInt()
            views.setTextViewText(R.id.word, entry.getString("word"))
            views.setTextColor(R.id.word, color)
            views.setTextViewText(R.id.category, "(" + entry.getString("category") + ")")
            views.setTextColor(R.id.category, color)
            views.setTextViewText(R.id.meaning, entry.getString("meaning"))
            views.setViewVisibility(R.id.meaning, View.VISIBLE)
            uri = Uri.parse("meinnotizbuch://word?id=" + entry.getInt("id"))
        }
        if (!small && !compact) views.setTextViewText(R.id.date, todayLabel())

        // Tocar no widget abre o app (na ficha da palavra).
        views.setOnClickPendingIntent(
            R.id.root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
        )
        manager.updateAppWidget(widgetId, views)
    }

    /** Entrada de hoje; sem ela, a mais recente antes de hoje. */
    private fun todayEntry(json: String?): JSONObject? {
        if (json == null) return null
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        return try {
            val list = JSONArray(json)
            var best: JSONObject? = null
            for (i in 0 until list.length()) {
                val item = list.getJSONObject(i)
                val date = item.getString("date")
                if (date == today) return item
                if (date < today && (best == null || date > best.getString("date"))) best = item
            }
            best
        } catch (e: Exception) {
            null
        }
    }

    /** "ter, 18/11". */
    private fun todayLabel(): String {
        val days = arrayOf("dom", "seg", "ter", "qua", "qui", "sex", "sáb")
        val c = Calendar.getInstance()
        val weekday = days[c.get(Calendar.DAY_OF_WEEK) - 1]
        return String.format(
            Locale.US, "%s, %02d/%02d",
            weekday, c.get(Calendar.DAY_OF_MONTH), c.get(Calendar.MONTH) + 1,
        )
    }
}
