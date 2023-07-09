import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pagination_control.dart';
import 'config.dart';

class ShipmentPane extends StatefulWidget {
  const ShipmentPane({super.key});

  @override
  State<ShipmentPane> createState() => _ShipmentPaneState();
}

class _ShipmentPaneState extends State<ShipmentPane> {
  final Dio _dio = Dio();
  final _getAdminShipmentOrderResponses =
      AppConfig.getAdminShipmentOrderResponses;
  final _toShipUrl = AppConfig.toShipUrl;
  final _waitingShipUrl = AppConfig.waitingShipUrl;
  late List<dynamic> _shipmentOrders;

  //表格相关参数
  late List<DataColumn> _columns;
  late List<int> _selectedItemIds;
  late List<dynamic> _currentPageData;
  late List<dynamic> _appIdResult;

  //分页相关参数
  final int _pageSize = 15;
  late int _currentPage = 0;
  late List<dynamic> _searchResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  bool _isAllSelected = false;

  //输入框控制器
  final _searchController = TextEditingController();
  final _appIdController = TextEditingController();

  String _dropdownValue = "shipment_status"; //下拉选择默认值

  List<Map<String, dynamic>> _multiplyProduct(
      List<dynamic> productsData, String type) {
    if (productsData.isEmpty) {
      return [];
    }
    if (type != "box" && type != "pool") {
      return [];
    }
    Map<int, Map<String, dynamic>> aggregatedData = {};

    for (var item in productsData) {
      int id = item['${type}_id'];
      int productId = item['product_id'];
      String productLevel = item['product_level'];

      if (!aggregatedData.containsKey(id)) {
        aggregatedData[id] = {
          '${type}_id': id,
          '${type}_name': item['${type}_name'],
          'products': <Map<String, dynamic>>[]
        };
      }

      List<Map<String, dynamic>> products = aggregatedData[id]!['products'];
      Map<String, dynamic> product = products.firstWhere(
          (p) =>
              p['product_id'] == productId &&
              p['product_level'] == productLevel,
          orElse: () => {});

      if (!product.containsKey('product_id')) {
        products.add({
          'product_id': productId,
          'product_name': item['product_name'],
          'product_image': item['product_image'],
          'product_level': productLevel,
          'product_count': 1
        });
      } else {
        product['product_count'] += 1;
      }
    }

    List<Map<String, dynamic>> output = aggregatedData.values.toList();
    return output;
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    //获取名为“token”的值，如果该键不存在，则返回默认值null
    final token = prefs.getString('token');
    // 处理获取的值
    final options = Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    try {
      Response response =
          await _dio.get(_getAdminShipmentOrderResponses, options: options);
      if (response.data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      List<dynamic> rawData = response.data;
      List<dynamic> _rawShipmentOrders = [];
      for (var shipment in rawData) {
        Map<String, dynamic> newShipment = {
          "shipment_order_id": shipment['shipment_order_id'],
          "app_id": shipment['app_id'],
          "shipment_address": shipment["shipment_address"],
          "postage": shipment["postage"],
          "user_id": shipment["user_id"],
          "nickname": shipment["nickname"],
          "avatar_url": shipment["avatar_url"],
          "notes": shipment["notes"],
          "shipment_status": shipment["shipment_status"],
          "tracking_number": shipment["tracking_number"],
          "logistics_company": shipment["logistics_company"],
          "created_at": shipment["created_at"],
          "updated_at": shipment["updated_at"],
          "admin_shipment_box_product_items": [],
          "admin_shipment_pool_product_items": [],
        };
        if (shipment["admin_shipment_box_product_items"] != null) {
          newShipment["admin_shipment_box_product_items"] = _multiplyProduct(
              shipment["admin_shipment_box_product_items"], "box");
        }

        if (shipment["admin_shipment_pool_product_items"] != null) {
          newShipment["admin_shipment_pool_product_items"] = _multiplyProduct(
              shipment["admin_shipment_pool_product_items"], "pool");
        }
        _rawShipmentOrders.add(newShipment);
      }

      setState(() {
        _selectedItemIds.clear();
        _isAllSelected = false;
        _currentPage = 0;
        _shipmentOrders = _rawShipmentOrders;
        _searchResult = _shipmentOrders;
        _currentPageData = _searchResult
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  //选择APPID
  void _selectAppId() {
    String keyword = _appIdController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _selectedItemIds.clear();
        _appIdResult = _shipmentOrders.where((element) {
          return element["app_id"] == _appIdController.text.trim();
        }).toList();
        _searchResult = _appIdResult;
        _loadData();
      });
    }
  }

  //全选方法
  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.clear();
        _selectedItemIds = _searchResult.map((item) {
          int id = item["shipment_order_id"];
          return id;
        }).toList();
        _isAllSelected = false;
      } else {
        _selectedItemIds.clear();
        _isAllSelected = true;
      }
    });
  }

  void _searchItems() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _selectedItemIds.clear();
        _searchResult = _appIdResult.where((item) {
          String value = item[_dropdownValue].toString();
          RegExp regExp = RegExp(r"\b" + keyword + r"\b");
          return regExp.hasMatch(value);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _deleteItems() {}

  void _waitToShipItemsRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      //获取名为“token”的值，如果该键不存在，则返回默认值null
      final token = prefs.getString('token');
      // 处理获取的值
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      await _dio.post(_waitingShipUrl, options: options, data: {
        "json_int_arrays": _selectedItemIds,
      });
      fetchData();
    } catch (error) {
      debugPrint('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _waitToShipItems() {
    if (_selectedItemIds.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确定删除所选弹窗吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _waitToShipItemsRequest();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _toShip(item) async {
    Map<String, dynamic> toShipRequest = {
      'shipment_order_id': item['shipment_order_id'],
      'shipment_status': '',
      'tracking_number': '',
      'logistics_company': '',
    };
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('编辑箱子信息'),
            content: SizedBox(
              width: 250,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '发货订单ID',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: item['shipment_order_id'].toString()),
                      enabled: false,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'App ID',
                      ),
                      keyboardType: TextInputType.text,
                      controller: TextEditingController(
                          text: item['app_id'].toString()),
                      enabled: false,
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '用户ID',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: item['user_id'].toString()),
                      enabled: false,
                    ),
                    TextField(
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: '用户昵称',
                      ),
                      keyboardType: TextInputType.text,
                      controller: TextEditingController(text: item['nickname']),
                      enabled: false,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: SelectableText(
                        '收货地址${item['shipment_address']}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        '备注：${item['notes']}',
                        textAlign: TextAlign.left,
                        maxLines: 1000,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const Text(
                      "箱子商品",
                      style: TextStyle(fontSize: 12.0),
                    ),
                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.grey,
                    ),
                    Column(
                      children: List<Column>.generate(
                          item["admin_shipment_box_product_items"].length,
                          (int index) {
                        var box =
                            item["admin_shipment_box_product_items"][index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              box["box_id"].toString() + box["box_name"],
                              style: const TextStyle(fontSize: 12.0),
                              maxLines: 2, // 最多显示两行
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(
                              height: 2,
                              thickness: 2,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ShipmentShowedProducts(
                                  products: box["products"]),
                            )
                          ],
                        );
                      }),
                    ),
                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.grey,
                    ),
                    const Text(
                      "池子商品",
                      style: TextStyle(fontSize: 12.0),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 2,
                      color: Colors.grey,
                    ),
                    Column(
                      children: List<Column>.generate(
                          item["admin_shipment_pool_product_items"].length,
                          (index3) {
                        var pool =
                            item["admin_shipment_pool_product_items"][index3];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pool["pool_id"].toString() + pool["pool_name"],
                              style: const TextStyle(fontSize: 12.0),
                              maxLines: 2, // 最多显示两行
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(
                              height: 2,
                              thickness: 2,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ShipmentShowedProducts(
                                  products: pool["products"]),
                            )
                          ],
                        );
                      }),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '物流单号',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                          text: item['tracking_number'].toString()),
                      onChanged: (value) {
                        toShipRequest['tracking_number'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '物流公司',
                      ),
                      keyboardType: TextInputType.text,
                      controller: TextEditingController(
                          text: item['logistics_company']),
                      onChanged: (value) {
                        toShipRequest['logistics_company'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '发货状态',
                      ),
                      keyboardType: TextInputType.text,
                      controller:
                          TextEditingController(text: item['shipment_status']),
                      onChanged: (value) {
                        toShipRequest['shipment_status'] = value.toString();
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    //获取名为“token”的值，如果该键不存在，则返回默认值null
                    final token = prefs.getString('token');
                    // 处理获取的值
                    final options = Options(
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
                      },
                    );
                    await _dio.post(_toShipUrl,
                        options: options, data: toShipRequest);
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    fetchData();
                  } catch (e) {
                    print('Error: $e');
                    //提示发货失败
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('请求失败'),
                          content: const Text('请检查您的网络连接'),
                          actions: [
                            TextButton(
                              child: const Text('确定'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
  }

  //分页函数
  void _loadData() {
    int startIndex = _currentPage * _pageSize;
    //向后端请求数据
    _currentPageData = _searchResult.skip(startIndex).take(_pageSize).toList();
  }

  void _prevPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
        _loadData();
      }
    });
  }

  void _nextPage() {
    setState(() {
      if ((_currentPage + 1) * _pageSize < _searchResult.length) {
        _currentPage++;
        _loadData();
      }
    });
  }

  void _jumpToPage(int page) {
    setState(() {
      if (page >= 1 && (page - 1) * _pageSize < _searchResult.length) {
        _currentPage = page - 1;
        _loadData();
      }
    });
  }

  //初始化
  @override
  void initState() {
    super.initState();
    _columns = [
      DataColumn(
          label: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("全选", style: TextStyle(fontStyle: FontStyle.italic)),
          SizedBox(
              width: 40,
              child: Checkbox(
                  value: _isAllSelected,
                  onChanged: (value) => _selectAll(_isAllSelected)))
        ],
      )),
      const DataColumn(
          label: SizedBox(
        width: 50,
        child: Text('订单ID'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 50,
        child: Text('APPID'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 50,
        child: Text('USERID'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text('用户头像'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 100,
        child: Text('用户昵称'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 200,
        child: Text('发货商品'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 100,
        child: Text('备注'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 180,
        child: Text('收货地址'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text('发货状态'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 50,
        child: Text('邮费'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 130,
        child: Text('物流单号'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 100,
        child: Text('物流公司'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 80,
        child: Text('确认发货'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 120,
        child: Text('创建时间'),
      )),
      const DataColumn(
          label: SizedBox(
        width: 120,
        child: Text('更新时间'),
      )),
    ];
    _currentPageData = [];
    _selectedItemIds = [];
    _searchResult = [];
    fetchData();
  }

  //销毁控制器
  @override
  void dispose() {
    _searchController.dispose();
    _appIdController.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _appIdController,
                                decoration: const InputDecoration(
                                  hintText: '输入APPID',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: ElevatedButton(
                                onPressed: _selectAppId,
                                child: const Text('选择APPID'),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            SizedBox(
                              width: 200,
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: '输入查找内容',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            DropdownButton<String>(
                              value: _dropdownValue,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _dropdownValue = newValue!;
                                });
                              },
                              items: <String>[
                                '发货订单ID',
                                '用户ID',
                                '用户昵称',
                                '发货状态',
                              ].map<DropdownMenuItem<String>>((String value) {
                                late String key;
                                switch (value) {
                                  case '发货订单ID':
                                    key = 'shipment_order_id';
                                    break;
                                  case '用户ID':
                                    key = 'user_id';
                                    break;
                                  case '用户昵称':
                                    key = 'user_nickname';
                                    break;
                                  case '发货状态':
                                    key = 'shipment_status';
                                    break;
                                }
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: ElevatedButton(
                                onPressed: _searchItems,
                                child: const Text('查找'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: ElevatedButton(
                                onPressed: _deleteItems,
                                child: const Text('删除'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              child: ElevatedButton(
                                onPressed: _waitToShipItems,
                                child: const Text('待发货'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DataTable(
                                dataRowMinHeight: 50,
                                dataRowMaxHeight: 150,
                                columns: _columns,
                                rows: _currentPageData.map<DataRow>((item) {
                                  return DataRow(cells: [
                                    DataCell(
                                      Checkbox(
                                          value: _selectedItemIds.contains(
                                              item['shipment_order_id']),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              int? id =
                                                  item['shipment_order_id'];
                                              if (value!) {
                                                _selectedItemIds.add(id!);
                                              } else {
                                                _selectedItemIds.remove(id);
                                              }
                                            });
                                          }),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          item['shipment_order_id'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          item['app_id'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          item['user_id'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Image(
                                        image: NetworkImage(
                                            item['avatar_url'].toString()),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          item['nickname'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "箱子商品",
                                                    style: TextStyle(
                                                        fontSize: 12.0),
                                                  ),
                                                  const Divider(
                                                    height: 2,
                                                    thickness: 2,
                                                    color: Colors.grey,
                                                  ),
                                                  Column(
                                                    children: List<
                                                            Column>.generate(
                                                        item["admin_shipment_box_product_items"]
                                                            .length,
                                                        (int index) {
                                                      var box = item[
                                                              "admin_shipment_box_product_items"]
                                                          [index];
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            box["box_id"]
                                                                    .toString() +
                                                                box["box_name"],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12.0),
                                                            maxLines:
                                                                2, // 最多显示两行
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const Divider(
                                                            height: 2,
                                                            thickness: 2,
                                                            color: Colors.grey,
                                                          ),
                                                          ShipmentShowedProducts(
                                                              products: box[
                                                                  "products"])
                                                        ],
                                                      );
                                                    }),
                                                  ),
                                                  const Divider(
                                                    height: 2,
                                                    thickness: 2,
                                                    color: Colors.grey,
                                                  ),
                                                  const Text(
                                                    "池子商品",
                                                    style: TextStyle(
                                                        fontSize: 12.0),
                                                  ),
                                                  const Divider(
                                                    height: 1,
                                                    thickness: 2,
                                                    color: Colors.grey,
                                                  ),
                                                  Column(
                                                    children: List<
                                                            Column>.generate(
                                                        item["admin_shipment_pool_product_items"]
                                                            .length, (index3) {
                                                      var pool = item[
                                                              "admin_shipment_pool_product_items"]
                                                          [index3];
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            pool["pool_id"]
                                                                    .toString() +
                                                                pool[
                                                                    "pool_name"],
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        12.0),
                                                            maxLines:
                                                                2, // 最多显示两行
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const Divider(
                                                            height: 2,
                                                            thickness: 2,
                                                            color: Colors.grey,
                                                          ),
                                                          ShipmentShowedProducts(
                                                            products: pool[
                                                                "products"],
                                                          )
                                                        ],
                                                      );
                                                    }),
                                                  )
                                                ]),
                                          )),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          item['notes'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(SizedBox(
                                      width: 180,
                                      child: Text(
                                        item["shipment_address"],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                    )),
                                    DataCell(SizedBox(
                                      width: 40,
                                      child: Text(
                                          item["shipment_status"].toString()),
                                    )),
                                    DataCell(SizedBox(
                                      width: 40,
                                      child: Text(item["postage"].toString()),
                                    )),
                                    DataCell(SizedBox(
                                      width: 120,
                                      child: Text(
                                          item["tracking_number"]?.toString() ??
                                              "无"),
                                    )),
                                    DataCell(SizedBox(
                                      width: 100,
                                      child: Text(item["logistics_company"]),
                                    )),
                                    DataCell(SizedBox(
                                      width: 150,
                                      child: ElevatedButton(
                                          onPressed: () => _toShip(item),
                                          child: const Text("去发货")),
                                    )),
                                    DataCell(SizedBox(
                                      width: 160,
                                      child:
                                          Text(item["created_at"].toString()),
                                    )),
                                    DataCell(SizedBox(
                                      width: 160,
                                      child:
                                          Text(item["updated_at"].toString()),
                                    ))
                                  ]);
                                }).toList()),
                          ],
                        ),
                        PaginationControl(
                            currentPage: _currentPage,
                            totalItems: _searchResult.length,
                            pageSize: _pageSize,
                            onNextPage: _nextPage,
                            onPrevPage: _prevPage,
                            onJumpPage: _jumpToPage)
                      ],
                    ),
                  )),
            ),
          );
  }
}

class ShipmentShowedProducts extends StatelessWidget {
  const ShipmentShowedProducts({super.key, required this.products});

  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      spacing: 5.0,
      children: List<Widget>.generate(products.length, (int index2) {
        var product = products[index2];
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 70,
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Image.network(products[index2]["product_image"].toString(),
                width: 50, height: 50, fit: BoxFit.cover),
            Text(
              product["product_level"] + '赏' + product["product_name"],
              style: const TextStyle(fontSize: 12.0),
              maxLines: 2, // 最多显示两行
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product["product_count"].toString(),
              style: const TextStyle(fontSize: 10.0),
            )
          ]),
        );
      }),
    );
  }
}
