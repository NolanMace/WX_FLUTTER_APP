import 'package:flutter/material.dart';
import 'UserDataPane.dart';
import 'BoxDataPane.dart';

class ContentPane extends StatefulWidget {
  final String subCategory;
  ContentPane({
    Key? key,
    required this.subCategory,
  }) : super(key: key);

  @override
  _ContentPaneState createState() => _ContentPaneState();
}

class _ContentPaneState extends State<ContentPane> {
  @override
  Widget build(BuildContext context) {
    if (widget.subCategory == "Subcategory 1") {
      return UserDataPane();
    } else {
      return BoxDataPane();
    }
  }
}
