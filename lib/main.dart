import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'my_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  runApp(const MyApp());
}

// Function to fetch product data from API
Future<void> fetchProductData() async {
  final response = await http.get(Uri.parse('https://fakestoreapi.com/products/'));

  if (response.statusCode == 200) {
    final products = json.decode(response.body);

    ///===========>>>>>>>>>>>>>> Save products as JSON strings in HomeWidget<<<<<<<<<<<<<<<<<============
    await HomeWidget.saveWidgetData<String>('products', json.encode(products));
    await HomeWidget.saveWidgetData<int>('productIndex', 0); // Set the initial index to 0
    await HomeWidget.updateWidget(
      name: 'HomeScreenWidgetProvider',
    );
  } else {
    throw Exception('Failed to load products');
  }
}

// Background callback function triggered by widget
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updateProduct') {
    await fetchProductData();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
