import 'package:flutter/material.dart';
import 'box_display_pane.dart';
import 'box_instance_pane.dart';
import 'box_item_config_pane.dart';
import 'product_data.dart';
import 'user_data_pane.dart';
import 'box_data_pane.dart';
import 'product_instance_pane.dart';
import 'shipment_pane.dart';

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

  int _boxId = 0;

  void _toDisplay(int id) {
    setState(() {
      _boxId = id;
      _tabController.index = 1;
    });
  }

  void _toDetail(int id) {
    setState(() {
      _boxId = id;
      _tabController.index = 2;
    });
  }

  void _toBoxInstance(int id) {
    setState(() {
      _boxId = id;
      _tabController.index = 3;
    });
  }

  void _toProductInstance(int id) {
    setState(() {
      _boxId = id;
      _tabController.index = 4;
    });
  }

  @override
  void initState() {
    // 在 initState 中进行初始化
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
                text: "上架详情",
              ),
              Tab(
                text: "箱子配置",
              ),
              Tab(
                text: "箱子实例",
              ),
              Tab(
                text: "商品实例",
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
                  toDisplay: _toDisplay,
                ),
                BoxDisplay(boxId: _boxId),
                BoxItemConfigPane(
                    id: _boxId,
                    toBoxInstance: _toBoxInstance,
                    toProductInstance: _toProductInstance),
                BoxInstancePane(id: _boxId),
                ProductInstancePane(id: _boxId)
              ],
            ),
          ),
        ],
      );
    } else if (widget.subCategory == "Subcategory 3") {
      return ProductData();
    } else {
      return const ShipmentPane();
    }
  }
}
