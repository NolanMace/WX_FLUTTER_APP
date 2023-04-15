import 'package:flutter/material.dart';
import 'ContentPane.dart';
import 'NavigationPane.dart';
import 'login_pane.dart';

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
  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }
}
