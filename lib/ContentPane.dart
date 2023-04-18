import 'package:flutter/material.dart';
import 'BoxItemConfigPane.dart';
import 'package:mis/ProductData.dart';
import 'UserDataPane.dart';
import 'BoxDataPane.dart';
import 'product_instance_pane.dart';

class ContentPane extends StatefulWidget {
  final String subCategory;

  const ContentPane({
    Key? key,
    required this.subCategory,
  }) : super(key: key);

  @override
  _ContentPaneState createState() => _ContentPaneState();
}

class _ContentPaneState extends State<ContentPane>
    with TickerProviderStateMixin {
  int _currentPageIndex = 0;

  late TabController _tabController;

  String _boxId = '';

  void _toDetail(String id) {
    setState(() {
      _boxId = id;
      _tabController.index = 1;
    });
  }

  void _toInstance(String id) {
    setState(() {
      _boxId = id;
      _tabController.index = 2;
    });
  }

  @override
  void initState() {
    // 在 initState 中进行初始化
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subCategory == "Subcategory 1") {
      return UserDataPane();
    } else if (widget.subCategory == "Subcategory 2") {
      return Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.blue, // 选中标签的颜色
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                text: "箱子模板",
              ),
              Tab(
                text: "箱子配置",
              ),
              Tab(
                text: "箱子实例",
              ),
            ],
            onTap: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                BoxDataPane(
                  toDetail: _toDetail,
                ),
                BoxItemConfigPane(id: _boxId, toInstance: _toInstance),
                ProductInstancePane(id: _boxId)
              ],
            ),
          ),
        ],
      );
    } else {
      return ProductData();
    }
  }
}
