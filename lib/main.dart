import 'package:flutter/material.dart';
import 'ContentPane.dart';
import 'NavigationPane.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _selectedSubCategory = "Subcategory 1";

  void _updateSelectedCategory(String subCategory) {
    setState(() {
      _selectedSubCategory = subCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("后台管理"),
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            child: NavigationPane(
              onSelectCategory: _updateSelectedCategory,
            ),
          ),
          Expanded(
            child: ContentPane(
              subCategory: _selectedSubCategory,
            ),
          ),
        ],
      ),
    );
  }
}
