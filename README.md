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