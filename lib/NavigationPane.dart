import 'package:flutter/material.dart';

class NavigationPane extends StatelessWidget {
  final void Function(String) onSelectCategory;

  const NavigationPane({Key? key, required this.onSelectCategory})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ExpansionTile(
          title: const Text("Category 1"),
          children: [
            ListTile(
              title: const Text("Subcategory 1"),
              onTap: () {
                onSelectCategory("Subcategory 1");
              },
            ),
            ListTile(
              title: const Text("Subcategory 2"),
              onTap: () {
                onSelectCategory("Subcategory 2");
              },
            ),
          ],
        ),
        ExpansionTile(
          title: const Text("Category 2"),
          children: [
            ListTile(
              title: const Text("Subcategory 1"),
              onTap: () {
                onSelectCategory("Subcategory 3");
              },
            ),
            ListTile(
              title: const Text("Subcategory 2"),
              onTap: () {
                onSelectCategory("Subcategory 4");
              },
            ),
          ],
        ),
      ],
    );
  }
}
