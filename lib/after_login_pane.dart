import 'package:flutter/material.dart';

import 'content_pane.dart';
import 'navigation_pane.dart';

class AfterLogin extends StatefulWidget {
  const AfterLogin({Key? key}) : super(key: key);

  @override
  _AfterLoginState createState() => _AfterLoginState();
}

class _AfterLoginState extends State<AfterLogin> {
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
          SizedBox(
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
