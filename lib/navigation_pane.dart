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
          title: const Text("用户管理"),
          children: [
            ListTile(
              title: const Text("用户管理"),
              onTap: () {
                onSelectCategory("用户管理");
              },
            ),
            ListTile(
              title: const Text("发货管理"),
              onTap: () {
                onSelectCategory("发货管理");
              },
            ),
          ],
        ),
        ExpansionTile(
          title: const Text("商品管理"),
          children: [
            ListTile(
              title: const Text("商品管理"),
              onTap: () {
                onSelectCategory("商品管理");
              },
            ),
            ListTile(
              title: const Text("箱子管理"),
              onTap: () {
                onSelectCategory("箱子管理");
              },
            ),
            ListTile(
              title: const Text("池子管理"),
              onTap: () {
                onSelectCategory("池子管理");
              },
            ),
          ],
        ),
        ExpansionTile(title: const Text("消费记录"), children: [
          ListTile(
            title: const Text("一番赏记录"),
            onTap: () {
              onSelectCategory("一番赏记录");
            },
          ),
          ListTile(
            title: const Text("打拳记录"),
            onTap: () {
              onSelectCategory("打拳记录");
            },
          ),
          ListTile(
            title: const Text("无限赏记录"),
            onTap: () {
              onSelectCategory("无限赏记录");
            },
          ),
        ]),
        ExpansionTile(title: const Text("小程序设置"), children: [
          ListTile(
            title: const Text("用户协议"),
            onTap: () {
              onSelectCategory("用户协议");
            },
          ),
          ListTile(
            title: const Text("首页弹窗"),
            onTap: () {
              onSelectCategory("首页弹窗");
            },
          ),
          ListTile(
            title: const Text("轮播图设置"),
            onTap: () {
              onSelectCategory("轮播图设置");
            },
          ),
          ListTile(
            title: const Text("优惠券设置"),
            onTap: () {
              onSelectCategory("优惠券设置");
            },
          ),
        ]),
      ],
    );
  }
}
