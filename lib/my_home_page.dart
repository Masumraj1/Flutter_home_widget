import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:tests/custom_loader/custom_loader.dart';
import 'dart:convert';

import 'package:tests/main.dart';

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
    loadData(); // Refresh data in the UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _products.isEmpty
            ? const CustomLoader() // Show a loader while data is loading
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
