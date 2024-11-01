package com.example.tests

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.net.Uri
import android.widget.RemoteViews
import com.squareup.picasso.Picasso
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import kotlinx.coroutines.*
import org.json.JSONArray

class HomeScreenWidgetProvider : HomeWidgetProvider() {

    private var job: Job? = null

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager,
                          appWidgetIds: IntArray, widgetData: SharedPreferences) {

        val productsJson = widgetData.getString("products", "[]")
        val products = JSONArray(productsJson)
        var currentIndex = widgetData.getInt("productIndex", 0)

        // Log the current index and product list
        println("Initial Current Index: $currentIndex")
        println("Products: $productsJson")

        job?.cancel() // Cancel existing job
        job = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                val product = products.optJSONObject(currentIndex)

                val title = product?.optString("title", "No Title Available") ?: "No Title Available"
                val imageUrl = product?.optString("image", "")

                // Log the title and image URL
                println("Updating widget with title: $title and image URL: $imageUrl")

                val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                    setTextViewText(R.id.tv_title, title) // Set the title

                    // Load image using Picasso
                    if (!imageUrl.isNullOrEmpty()) {
                        try {
                            val bitmap: Bitmap = Picasso.get().load(imageUrl).get()
                            setImageViewBitmap(R.id.iv_banner_image, bitmap)
                        } catch (e: Exception) {
                            println("Error loading image: ${e.message}")
                        }
                    } else {
                        println("Image URL is empty.")
                    }

                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                appWidgetIds.forEach { widgetId ->
                    appWidgetManager.updateAppWidget(widgetId, views)
                    println("Updated widget with ID: $widgetId")
                }

                currentIndex = (currentIndex + 1) % products.length()
                widgetData.edit().putInt("productIndex", currentIndex).apply() // Save index

                // Wait for 10 seconds before showing the next product
                delay(10000)
            }
        }
    }

    override fun onDisabled(context: Context?) {
        super.onDisabled(context)
        job?.cancel() // Cancel the job when the widget is removed
        println("Widget disabled, job canceled.")
    }
}
