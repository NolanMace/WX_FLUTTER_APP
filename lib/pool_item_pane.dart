import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mis/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_data_table.dart';
import 'pagination_control.dart';

class PoolItemData extends StatefulWidget {
  final int poolId;
  const PoolItemData({
    Key? key,
    required this.poolId,
  }) : super(key: key);

  @override
  State<PoolItemData> createState() => _PoolItemDataState();
}

class _PoolItemDataState extends State<PoolItemData> {
  final Dio _dio = Dio();
  //网络请求相关参数
  final _getPoolItemsByPoolIdUrl = AppConfig.getPoolItemsByPoolIdUrl;
  final _deletePoolItemUrl = AppConfig.deletePoolItemUrl;
  final _addPoolItemUrl = AppConfig.addPoolItemUrl;
  final _updatePoolItemUrl = AppConfig.updatePoolItemUrl;
  late List<Map<String, dynamic>> _items;
  late List<Map<String, dynamic>> _appIdResult;
  late String _responseBody;

//表格相关参数
  final List<String> columnTitles = [
    '选择',
    "实例ID",
    "APPID",
    "池子ID",
    "商品ID",
    "图片",
    "商品等级",
    "概率",
    "DrawnNum",
    "备注",
    '编辑',
    '创建时间',
    '更新时间',
  ];
  final List<String> _attributes = [
    'select',
    'pool_item_id',
    'app_id',
    'pool_id',
    'product_id',
    "product_image_url",
    'product_level',
    'probability',
    'drawn_num',
    'notes',
    'edit',
    'created_at',
    'updated_at'
  ];
  final int _imageColumnIndex = 5;
  late List<DataColumn> _columns;
  late List<int> _selectedPoolItemIds;
  late List<dynamic> _currentPageData;

  //分页相关参数
  final int _pageSize = 10;
  late int _currentPage = 0;
  late List<Map<String, dynamic>> _searchResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  //判断是否全选
  bool _isAllSelected = false;

  //输入框控制器
  final _searchController = TextEditingController();
  final _appIdController = TextEditingController();

  late String _dropdownValue = "product_id"; //下拉选择默认值

  //销毁控制器
  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  //初始化
  @override
  void initState() {
    super.initState();
    _columns = List<DataColumn>.generate(columnTitles.length, (index) {
      if (index == 0) {
        return DataColumn(
            label: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("全选", style: TextStyle(fontSize: 14)),
            SizedBox(
                width: 40,
                child: Checkbox(
                    value: _isAllSelected,
                    onChanged: (value) => _selectAll(_isAllSelected)))
          ],
        ));
      } else {
        return DataColumn(
          label: SizedBox(
            width: 70,
            child: Text(
              columnTitles[index],
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }
    });
    _selectedPoolItemIds = [];
    _currentPageData = [];
    _searchResult = [];
    fetchData();
  }

  @override
  void didUpdateWidget(covariant PoolItemData oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果新的 `id` 与旧的 `id` 不同，那么执行一些操作，例如重新获取数据
    if (widget.poolId != oldWidget.poolId) {
      fetchData(); // 重新获取数据
    }
  }

  //获取数据
  Future<void> fetchData() async {
    if (widget.poolId == 0) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _dio.interceptors
        .add(LogInterceptor(responseBody: true, requestBody: true));
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
      Response response = await _dio.get(queryParameters: {
        'pool_id': widget.poolId,
      }, _getPoolItemsByPoolIdUrl, options: options);
      _responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      _responseBody = _responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
      List<dynamic> responseList = jsonDecode(_responseBody);
      List<Map<String, dynamic>> items =
          responseList.map<Map<String, dynamic>>((item) {
        return {
          "product_id": item["product_id"],
          "app_id": item["app_id"] ?? "",
          "pool_item_id": item["pool_item_id"] ?? "",
          "pool_id": item["pool_id"] ?? "",
          "product_level": item["product_level"] ?? "",
          "probability": item["probability"] ?? "",
          "drawn_num": item["drawn_num"] ?? "",
          "notes": item["notes"] ?? "",
          "created_at": item["created_at"]
                  .replaceAll("T", " ")
                  .replaceAll("+08:00", " ") ??
              "",
          "updated_at": item["updated_at"]
                  .replaceAll("T", " ")
                  .replaceAll("+08:00", " ") ??
              "",
        };
      }).toList();

      setState(() {
        _selectedPoolItemIds.clear();
        _items = items;
        _searchResult = _items;
        _currentPageData = _searchResult
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  //分页相关函数
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

  //全选相关函数
  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedPoolItemIds.clear();
        _selectedPoolItemIds = _searchResult.map((item) {
          int id = item["pool_id"];
          return id;
        }).toList();
        _isAllSelected = false;
      } else {
        _selectedPoolItemIds.clear();
        _isAllSelected = true;
      }
    });
  }

  //选择APPID
  void _selectAppId() {
    String keyword = _appIdController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _selectedPoolItemIds.clear();
        _appIdResult = _items.where((element) {
          return element["app_id"] == _appIdController.text.trim();
        }).toList();
        _searchResult = _appIdResult;
        _loadData();
      });
    }
  }

  //增删查改相关函数
  void _searchItems() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _selectedPoolItemIds.clear();
        _searchResult = _appIdResult.where((user) {
          String value = user[_dropdownValue].toString();
          RegExp regExp = RegExp(r"\b" + keyword + r"\b");
          return regExp.hasMatch(value);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _additem() async {
    Map<String, dynamic>? newItem;
    await showDialog(
      context: context,
      builder: (context) {
        newItem = {
          'product_id': null,
          'app_id': null,
          'pool_item_id': null,
          'pool_id': widget.poolId,
          'product_level': null,
          'probability': null,
          'drawn_num': null,
          'notes': null,
        };
        return AlertDialog(
          title: const Text('添加item'),
          content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '池子ID',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: widget.poolId.toString()),
                        enabled: false,
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'APP ID',
                        ),
                        onChanged: (value) {
                          newItem?['app_id'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品ID',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newItem?['product_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品等级',
                        ),
                        onChanged: (value) {
                          newItem?['product_level'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '概率',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          newItem?['probability'] = double.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Drawn Num',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newItem?['drawn_num'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '备注',
                        ),
                        onChanged: (value) {
                          newItem?['notes'] = value.toString();
                        },
                      ),
                    ],
                  ))),
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
                  await _dio.post(_addPoolItemUrl,
                      options: options, data: newItem);
                  Navigator.of(context).pop();
                  fetchData();
                } catch (error) {
                  print('Error: $error');
                }
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteData() async {
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
      Response response =
          await _dio.delete(_deletePoolItemUrl, options: options, data: {
        "pool_item_ids": _selectedPoolItemIds,
      });
      print('Response body: ${response.data}');
      fetchData();
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _deleteItems() {
    if (_selectedPoolItemIds.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确定删除所选商品吗？'),
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
                _deleteData();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _editPoolItem(Map<String, dynamic> itemData) async {
    Map<String, dynamic> editedItem = Map<String, dynamic>.from(itemData);
    editedItem['product_id'] =
        int.tryParse(editedItem['product_id'].toString());
    editedItem['drawn_num'] = int.tryParse(editedItem['drawn_num'].toString());
    editedItem['probability'] =
        double.tryParse(editedItem['probability'].toString());
    editedItem['pool_id'] = int.tryParse(editedItem['pool_id'].toString());
    editedItem['pool_item_id'] =
        int.tryParse(editedItem['pool_item_id'].toString());
    editedItem.remove("created_at");
    editedItem.remove("updated_at");
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑箱子信息'),
          content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '实例ID',
                        ),
                        controller: TextEditingController(
                            text: itemData['pool_item_id'].toString()),
                        enabled: false,
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '池子ID',
                        ),
                        controller: TextEditingController(
                            text: itemData['pool_id'].toString()),
                        enabled: false,
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'APPID',
                        ),
                        controller: TextEditingController(
                            text: itemData['app_id'].toString()),
                        onChanged: (value) {
                          editedItem['app_id'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品ID',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: itemData['product_id'].toString()),
                        onChanged: (value) {
                          editedItem['product_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品等级',
                        ),
                        controller: TextEditingController(
                            text: itemData['product_level'].toString()),
                        onChanged: (value) {
                          editedItem['product_level'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '概率',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        controller: TextEditingController(
                            text: itemData['probability'].toString()),
                        onChanged: (value) {
                          editedItem['probability'] = double.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Drawn Num',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: itemData['drawn_num'].toString()),
                        onChanged: (value) {
                          editedItem['drawn_num'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '备注',
                        ),
                        controller:
                            TextEditingController(text: itemData['notes']),
                        onChanged: (value) {
                          editedItem['notes'] = value.toString();
                        },
                      ),
                    ],
                  ))),
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
                  await _dio.post(_updatePoolItemUrl,
                      data: editedItem, options: options);
                  Navigator.of(context).pop();
                  fetchData();
                } catch (error) {
                  print('Error: $error');
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
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
                  const SizedBox(width: 20),
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
                      '商品ID',
                      '商品等级',
                    ].map<DropdownMenuItem<String>>((String value) {
                      late String key;
                      switch (value) {
                        case '商品ID':
                          key = 'product_id';
                          break;
                        case '商品等级':
                          key = 'product_level';
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
                      onPressed: _additem,
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: CustomDataTable(
                                  columns: _attributes,
                                  columnNames: _columns,
                                  selectedItemIds: _selectedPoolItemIds,
                                  hasDetailButton: false,
                                  currentPageData: _currentPageData,
                                  imageColumnIndex: _imageColumnIndex,
                                  editData: _editPoolItem))),
                      PaginationControl(
                          currentPage: _currentPage,
                          totalItems: _searchResult.length,
                          pageSize: _pageSize,
                          onNextPage: _nextPage,
                          onPrevPage: _prevPage)
                    ],
                  ),
                ),
              ),
            ],
          );
  }
}
