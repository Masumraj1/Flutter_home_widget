# Home Widget 



   ![Screenshot_20241102_100028](https://github.com/user-attachments/assets/3640b26a-09c8-42fb-9864-631d8fe1e3b7)


# 1. Project Setup

# Step 1: Add Dependencies

# Add the home_widget package to your pubspec.yaml file:
    dependencies:
    home_widget: 0.7.0
    http: ^0.13.0
# 2. Setting Up main.dart
    void main() {
    WidgetsFlutterBinding.ensureInitialized();
    HomeWidget.registerInteractivityCallback(backgroundCallback);
    runApp(const MyApp());
    }

    Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'updateProduct') {
    await fetchProductData();
     }
     }
# 3.Step 2: Fetch and Save Product Data
    Future<void> fetchProductData() async {
    final response = await http.get(Uri.parse('https://fakestoreapi.com/products/'));

     if (response.statusCode == 200) {
    final products = json.decode(response.body);
    await HomeWidget.saveWidgetData<String>('products', json.encode(products));
    await HomeWidget.saveWidgetData<int>('productIndex', 0); // Set initial index
    await HomeWidget.updateWidget(name: 'HomeScreenWidgetProvider');
    } else {
    throw Exception('Failed to load products');
    }
    }
# 3. Creating MyHomePage Widget

    import 'package:flutter/material.dart';
    import 'package:home_widget/home_widget.dart';
    import 'dart:convert';

    class MyHomePage extends StatefulWidget {
    final String title;
    const MyHomePage({super.key, required this.title});

    @override
    MyHomePageState createState() => MyHomePageState();
    }

    class MyHomePageState extends State<MyHomePage> {
    List<dynamic> _products = [];

    @override
    void initState() {
    super.initState();
    HomeWidget.widgetClicked.listen((Uri? uri) => loadData());
    loadData();
    }

    void loadData() async {
    await HomeWidget.getWidgetData<String>('products', defaultValue: '[]').then((value) {
    setState(() {
    _products = json.decode(value!);
    });
    });
    }

    Future<void> updateAppWidget() async {
    await fetchProductData();
    loadData();
    }

    @override
    Widget build(BuildContext context) {
     return Scaffold(
    appBar: AppBar(
    title: Text(widget.title),
     ),
    body: Center(
    child: _products.isEmpty
     ? const CircularProgressIndicator()
     : ListView.builder(
    itemCount: _products.length,
     itemBuilder: (context, index) {
        final product = _products[index];
         return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
          leading: Image.network(
          product['image'],
          width: 50,
        height: 50,
         fit: BoxFit.cover,
          ),
        title: Text(product['title']),
         subtitle: Text("\$${product['price']}"),
          ),
          );
          },
        ),
      ),
       floatingActionButton: FloatingActionButton(
     onPressed: updateAppWidget,
       tooltip: 'Update Products',
     child: const Icon(Icons.refresh),
      ),
      );
     }
       }
# 4. Setting Up Android Files

# Step 1: Create widget_info.xml

# Navigate to android/app/src/main/res/xml and create a file named widget_info.xml:
    <appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/widget_layout"
    android:minWidth="150dp"
    android:minHeight="200dp"
    android:minResizeWidth="200dp"
    android:minResizeHeight="150dp"
    android:widgetCategory="home_screen" />
# Step 2: Create widget_layout.xml

# Navigate to android/app/src/main/res/layout and create a file named widget_layout.xml:

    <FrameLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/widget_root"
    android:layout_width="180dp"
    android:layout_height="210dp"
    android:background="#000000">
    <RelativeLayout
     android:layout_width="match_parent"
     android:layout_height="match_parent">

        <ImageView
            android:id="@+id/iv_banner_image"
            android:layout_width="match_parent"
            android:layout_height="120dp"
            android:layout_alignParentTop="true"
            android:scaleType="centerCrop"
            android:src="@drawable/placeholder_image" />
      <TextView
     android:id="@+id/tv_title"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout_below="@id/iv_banner_image"
    android:gravity="center_horizontal"
    android:padding="12dp"
    android:text="Title will appear here"
    android:textColor="@android:color/white"
    android:textSize="16sp" />
    </RelativeLayout>
    </FrameLayout>
# Step 3: Create Kotlin Class

# Navigate to android/app/src/main/kotlin/your/package/name/ and create HomeScreenWidgetProvider.kt
package com.example.tests

    import android.appwidget.AppWidgetManager
    import android.content.Context
    import android.content.SharedPreferences
    import android.graphics.Bitmap
    import android.widget.RemoteViews
    import com.squareup.picasso.Picasso
    import es.antonborri.home_widget.HomeWidgetProvider
    import kotlinx.coroutines.*
    import org.json.JSONArray

    class HomeScreenWidgetProvider : HomeWidgetProvider() {
     private var job: Job? = null

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val productsJson = widgetData.getString("products", "[]")
        val products = JSONArray(productsJson)
        var currentIndex = widgetData.getInt("productIndex", 0)

        job?.cancel()
        job = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                val product = products.optJSONObject(currentIndex)
                val title = product?.optString("title", "No Title Available") ?: "No Title Available"
                val imageUrl = product?.optString("image", "")

                val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                    setTextViewText(R.id.tv_title, title)
                    if (!imageUrl.isNullOrEmpty()) {
                        try {
                            val bitmap: Bitmap = Picasso.get().load(imageUrl).get()
                            setImageViewBitmap(R.id.iv_banner_image, bitmap)
                        } catch (e: Exception) {
                            println("Error loading image: ${e.message}")
                        }
                    }
                    val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }

                appWidgetIds.forEach { widgetId ->
                    appWidgetManager.updateAppWidget(widgetId, views)
                }

                currentIndex = (currentIndex + 1) % products.length()
                widgetData.edit().putInt("productIndex", currentIndex).apply()
                delay(10000) // Wait for 10 seconds before updating
            }
        }
    }

    override fun onDisabled(context: Context?) {
        super.onDisabled(context)
        job?.cancel()
    }
    }