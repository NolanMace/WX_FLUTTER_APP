import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mis/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'CustomDataTable.dart';
import 'PaginationControl.dart';

class ProductData extends StatefulWidget {
  ProductData({
    Key? key,
  }) : super(key: key);

  @override
  _ProductDataState createState() => _ProductDataState();
}

class _ProductDataState extends State<ProductData> {
  final Dio _dio = Dio();
  //网络请求相关参数
  final _getAllProductsUrl = AppConfig.getAllProductsUrl;
  final _deleteProductUrl = AppConfig.deleteProductUrl;
  final _addProductUrl = AppConfig.addProductUrl;
  final _editProductUrl = AppConfig.updateProductUrl;
  late List<Map<String, dynamic>> _boxes;
  late String _responseBody;

//表格相关参数
  final List<String> columnTitles = [
    '选择',
    "商品ID",
    "商品名称",
    "商品图片",
    "是否现货",
    "备注",
    "发售时间",
    '编辑',
    '创建时间',
    '更新时间',
  ];
  final List<String> _attributes = [
    'select',
    'product_id',
    'product_name',
    'product_image_url',
    'in_stock',
    'notes',
    'release_date',
    'edit',
    'created_at',
    'updated_at'
  ];
  final int _imageColumnIndex = 3;
  late List<DataColumn> _columns;
  late List<int> _selectedProductIds;
  late List<dynamic> _currentPageData;

  //分页相关参数
  late int _pageSize;
  late int _currentPage = 0;
  late List<Map<String, dynamic>> _searchResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  //输入框控制器
  final _searchController = TextEditingController();

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
    _columns = columnTitles.map<DataColumn>((text) {
      return DataColumn(
        label: Text(
          text,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }).toList();
    _selectedProductIds = [];
    fetchData();
  }

  //获取数据
  Future<void> fetchData() async {
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
      Response response = await _dio.get(_getAllProductsUrl, options: options);
      _responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      _responseBody = _responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
      List<dynamic> responseList = jsonDecode(_responseBody);
      List<Map<String, dynamic>> boxes =
          responseList.map<Map<String, dynamic>>((item) {
        return {
          "product_id": item["product_id"],
          "product_name": item["product_name"] ?? "",
          "product_image_url": item["product_image_url"] ?? "",
          "in_stock": item["in_stock"] ?? "",
          "notes": item["notes"] ?? "",
          "release_date": item["release_date"] ?? "",
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
        _selectedProductIds.clear();
        _boxes = boxes;
        _pageSize = 20;
        _searchResult = _boxes;
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

  //增删查改相关函数
  void _searchBoxes() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _searchResult = _boxes.where((user) {
          return user[_dropdownValue].toString().contains(keyword);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _addBox() async {
    Map<String, dynamic>? newBox;
    await showDialog(
      context: context,
      builder: (context) {
        newBox = {
          'product_id': null,
          'product_name': null,
          'product_image_url': null,
          'in_stock': null,
          'notes': null,
          'release_date': null,
        };
        return AlertDialog(
          title: const Text('添加箱子'),
          content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品ID',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newBox?['product_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品名称',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newBox?['product_name'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '封面URL',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newBox?['product_image_url'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '是否现货',
                        ),
                        onChanged: (value) {
                          newBox?['in_stock'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '备注',
                        ),
                        onChanged: (value) {
                          newBox?['notes'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '发售时间',
                        ),
                        onChanged: (value) {
                          newBox?['release_date'] = value.toString();
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
                  await _dio.post(_addProductUrl,
                      options: options, data: newBox);
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
          await _dio.delete(_deleteProductUrl, options: options, data: {
        "product_ids": _selectedProductIds,
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

  void _deleteBoxes() {
    if (_selectedProductIds.isEmpty) {
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

  void _editBox(Map<String, dynamic> productData) async {
    Map<String, dynamic> editedBox = Map<String, dynamic>.from(productData);
    editedBox['product_id'] = int.tryParse(editedBox['product_id'].toString());
    editedBox.remove("created_at");
    editedBox.remove("updated_at");
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
                          labelText: '商品ID',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: productData['product_id'].toString()),
                        onChanged: (value) {
                          editedBox['product_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '商品名称',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: productData['product_name'].toString()),
                        onChanged: (value) {
                          editedBox['product_name'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '封面URL',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: productData['product_image_url'].toString()),
                        onChanged: (value) {
                          editedBox['product_image_url'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '是否现货',
                        ),
                        controller: TextEditingController(
                            text: productData['in_stock']),
                        onChanged: (value) {
                          editedBox['in_stock'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '备注',
                        ),
                        controller:
                            TextEditingController(text: productData['notes']),
                        onChanged: (value) {
                          editedBox['notes'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '发售时间',
                        ),
                        controller: TextEditingController(
                            text: productData['release_date']),
                        onChanged: (value) {
                          editedBox['release_date'] = value.toString();
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
                  await _dio.post(_editProductUrl,
                      data: editedBox, options: options);
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
                      '商品名称',
                      '商品等级',
                    ].map<DropdownMenuItem<String>>((String value) {
                      late String key;
                      switch (value) {
                        case '商品ID':
                          key = 'product_id';
                          break;
                        case '商品名称':
                          key = 'product_name';
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
                      onPressed: _searchBoxes,
                      child: const Text('查找'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _deleteBoxes,
                      child: const Text('删除'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _addBox,
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
                                  selectedItemIds: _selectedProductIds,
                                  hasDetailButton: false,
                                  currentPageData: _currentPageData,
                                  imageColumnIndex: _imageColumnIndex,
                                  editData: _editBox))),
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
