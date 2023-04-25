import 'package:flutter/material.dart';
import 'box_lottery_record_pane.dart';
import 'dq_lottery_record_pane.dart';
import 'pool_data_pane.dart';
import 'box_display_pane.dart';
import 'box_instance_pane.dart';
import 'box_item_config_pane.dart';
import 'pool_display_pane.dart';
import 'pool_item_pane.dart';
import 'pool_lottery_record_pane.dart';
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
  State<ContentPane> createState() => _ContentPaneState();
}

class _ContentPaneState extends State<ContentPane>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _pooltabController;

  int _boxId = 0;
  int _poolId = 0;

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

  void _toPoolDisplay(int id) {
    setState(() {
      _poolId = id;
      _pooltabController.index = 1;
    });
  }

  void _toPoolDetail(int id) {
    setState(() {
      _poolId = id;
      _pooltabController.index = 2;
    });
  }

  @override
  void initState() {
    // 在 initState 中进行初始化
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pooltabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subCategory == "用户管理") {
      return UserDataPane();
    } else if (widget.subCategory == "发货管理") {
      return const ShipmentPane();
    } else if (widget.subCategory == "商品管理") {
      return const ProductData();
    } else if (widget.subCategory == "箱子管理") {
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
              setState(() {});
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
    } else if (widget.subCategory == "池子管理") {
      return Column(
        children: [
          TabBar(
            controller: _pooltabController,
            labelColor: Colors.blue, // 选中标签的颜色
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                text: "池子模板",
              ),
              Tab(
                text: "上架详情",
              ),
              Tab(
                text: "池子配置",
              ),
            ],
            onTap: (index) {
              setState(() {});
            },
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pooltabController,
              children: [
                PoolDataPane(
                  toDetail: _toPoolDetail,
                  toDisplay: _toPoolDisplay,
                ),
                PoolDisplay(poolId: _poolId),
                PoolItemData(poolId: _poolId),
              ],
            ),
          ),
        ],
      );
    } else if (widget.subCategory == "一番赏记录") {
      return const BoxLotteryRecordPane();
    } else if (widget.subCategory == "打拳记录") {
      return const DqLotteryRecordPane();
    } else if (widget.subCategory == "无限赏记录") {
      return const PoolLotteryRecordPane();
    } else {
      return const Text("未知");
    }
  }
}
