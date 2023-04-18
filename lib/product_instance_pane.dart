import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'CustomDataTable.dart';
import 'PaginationControl.dart';

class ProductInstancePane extends StatefulWidget {
  final String id;
  const ProductInstancePane({Key? key, required this.id}) : super(key: key);

  _ProductInstancePaneState createState() => _ProductInstancePaneState();
}

class _ProductInstancePaneState extends State<ProductInstancePane> {
  final Dio _dio = Dio();
  //请求参数
  final String _getBoxItemsByBoxId = AppConfig.getBoxItemsByBoxIdUrl;
  final String _deleteBoxItemsUrl = AppConfig.deleteBoxItemsUrl;
  final String _updateBoxItemUrl = AppConfig.updateBoxItemUrl;
  late List<Map<String, dynamic>> _productInstanceData;
  late List<Map<String, dynamic>> _appIdResult;

  //表格参数
  final List<String> _columns = [
    'select',
    'box_item_id',
    'app_id',
    'box_id',
    'product_id',
    'box_number',
    'product_level',
    'img_url',
    'is_drawn',
    'notes',
    'edit',
    'created_at',
    'updated_at',
  ];
  final _columnsTitle = [
    '全选',
    '实例ID',
    '应用ID',
    '箱子ID',
    '商品ID',
    '箱子编号',
    '商品等级',
    '图片',
    '是否已抽取',
    '备注',
    '编辑',
    '创建时间',
    '更新时间',
  ];
  List<DataColumn> _columnNames = [];
  List<int> _selectedItemIds = [];
  List<dynamic> _currentPageData = [];
  final int _imageColumnIndex = 7;
  final bool _hasDetailButton = false;

  //分页参数
  late int _pageSize = 10;
  late int _currentPage = 0;
  late List<Map<String, dynamic>> _searchResult = [];

  //下拉默认
  String _dropdownValue = 'box_number';

  //输入框控制器
  final _searchController = TextEditingController();
  final _appIdController = TextEditingController();

  bool _isLoading = true;
  bool _isAllSelected = false;

  //请求数据
  Future<void> fetchData() async {
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
      Map<String, dynamic> queryParams = {
        'box_id': int.parse(widget.id),
      };
      Response response = await _dio.get(
        _getBoxItemsByBoxId,
        queryParameters: queryParams,
        options: options,
      );
      String responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      responseBody = responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');

      List<dynamic> responseList = jsonDecode(responseBody);
      List<Map<String, dynamic>> productInstanceData =
          responseList.map<Map<String, dynamic>>((item) {
        return {
          "box_item_id": item["box_item_id"] ?? "",
          "app_id": item["app_id"] ?? "",
          "box_id": item["box_id"] ?? "",
          "product_id": item["product_id"] ?? "",
          "box_number": item["box_number"] ?? "",
          "product_level": item["product_level"] ?? "",
          "is_drawn": item["is_drawn"] ?? "",
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
        _selectedItemIds.clear();
        _productInstanceData = productInstanceData;
        _searchResult = _productInstanceData;
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

  //选择APPID
  void _selectAppId() {
    String keyword = _appIdController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _selectedItemIds.clear();
        _appIdResult = _productInstanceData.where((element) {
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
          int id = int.tryParse(item["box_item_id"])!;
          return id;
        }).toList();
        _isAllSelected = false;
      } else {
        _selectedItemIds.clear();
        _isAllSelected = true;
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
        _selectedItemIds.clear();
        _searchResult = _appIdResult.where((user) {
          String value = user[_dropdownValue].toString();
          RegExp regExp = RegExp(r"\b" + keyword + r"\b");
          return regExp.hasMatch(value);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
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
          await _dio.delete(_deleteBoxItemsUrl, options: options, data: {
        "box_item_ids": _selectedItemIds,
      });
      print(_selectedItemIds);
      print('Response body: ${response.data}');
      fetchData();
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _deleteConfigItem() {
    if (_selectedItemIds.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确定删除所选实例吗？'),
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

  void _editData(Map<String, dynamic> configItem) async {
    Map<String, dynamic> editedConfigItem =
        Map<String, dynamic>.from(configItem);
    editedConfigItem['box_item_id'] =
        int.tryParse(editedConfigItem['box_item_id'].toString());
    editedConfigItem['box_id'] =
        int.tryParse(editedConfigItem['box_id'].toString());
    editedConfigItem['product_id'] =
        int.tryParse(editedConfigItem['product_id'].toString());
    editedConfigItem['box_number'] =
        int.tryParse(editedConfigItem['box_number'].toString());
    editedConfigItem['is_drawn'] =
        int.tryParse(editedConfigItem['is_drawn'].toString());
    editedConfigItem.remove("created_at");
    editedConfigItem.remove("updated_at");
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑箱子配置信息'),
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
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['box_item_id'].toString()),
                    enabled: false,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '应用ID',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['app_id'].toString()),
                    enabled: false,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '箱子ID',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['box_id'].toString()),
                    enabled: false,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '商品ID',
                    ),
                    controller: TextEditingController(
                        text: configItem['product_id'].toString()),
                    onChanged: (value) {
                      editedConfigItem['product_id'] = int.parse(value);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '箱子编号',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['box_number'].toString()),
                    onChanged: (value) {
                      editedConfigItem['box_number'] = int.parse(value);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '商品等级',
                    ),
                    controller: TextEditingController(
                        text: configItem['product_level']),
                    onChanged: (value) {
                      editedConfigItem['product_level'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '是否已抽取',
                    ),
                    controller: TextEditingController(
                        text: configItem['is_drawn'].toString()),
                    onChanged: (value) {
                      editedConfigItem['is_drawn'] = int.parse(value);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '备注',
                    ),
                    controller: TextEditingController(
                        text: configItem['notes'].toString()),
                    onChanged: (value) {
                      editedConfigItem['notes'] = value.toString();
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
                  await _dio.post(_updateBoxItemUrl,
                      options: options, data: editedConfigItem);
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
  void initState() {
    super.initState();
    _columnNames = _columnsTitle.map((e) {
      if (e == '全选') {
        return DataColumn(
            label: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(e, style: const TextStyle(fontStyle: FontStyle.italic)),
            SizedBox(
                width: 40,
                child: Checkbox(
                    value: _isAllSelected,
                    onChanged: (value) => _selectAll(_isAllSelected)))
          ],
        ));
      } else {
        return DataColumn(
          label: Text(
            e,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
    }).toList();
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
  build(context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SizedBox.expand(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Image(
                              image: AssetImage('assets/wuxianshang.jpg'),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                            Column(
                              children: [
                                Text('ID: ${widget.id}'),
                                const Text('Name: 标题标题'),
                              ],
                            ),
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
                                '箱子编号',
                                '商品等级',
                                '商品ID'
                              ].map<DropdownMenuItem<String>>((String value) {
                                late String key;
                                switch (value) {
                                  case '箱子编号':
                                    key = 'box_number';
                                    break;
                                  case '商品等级':
                                    key = 'product_level';
                                    break;
                                  case '商品ID':
                                    key = 'product_id';
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
                                onPressed: _deleteConfigItem,
                                child: const Text('删除'),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                        Column(
                          children: [
                            CustomDataTable(
                              columns: _columns,
                              columnNames: _columnNames,
                              selectedItemIds: _selectedItemIds,
                              hasDetailButton: _hasDetailButton,
                              currentPageData: _currentPageData,
                              imageColumnIndex: _imageColumnIndex,
                              editData: _editData,
                              selectAll: _selectAll,
                            ),
                            PaginationControl(
                                currentPage: _currentPage,
                                totalItems: _searchResult.length,
                                pageSize: _pageSize,
                                onNextPage: _nextPage,
                                onPrevPage: _prevPage)
                          ],
                        )
                      ],
                    ),
                  )),
            ),
          );
  }
}
