import 'dart:convert';
import 'config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'CustomDataTable.dart';
import 'PaginationControl.dart';

class BoxItemConfigPane extends StatefulWidget {
  final String id;
  const BoxItemConfigPane({Key? key, required this.id}) : super(key: key);

  _BoxItemConfigPaneState createState() => _BoxItemConfigPaneState();
}

class _BoxItemConfigPaneState extends State<BoxItemConfigPane> {
  final Dio _dio = Dio();
  //请求参数
  final String _getAllBoxItemConfigByBoxIdUrl = AppConfig.getConfigUrl;
  final String _addConfigUrl = AppConfig.addConfigUrl;
  final String _deleteConfigUrl = AppConfig.deleteConfigUrl;
  final String _updateConfigUrl = AppConfig.updateConfigUrl;
  late List<Map<String, dynamic>> _boxItemConfigData;

  //表格参数
  final List<String> _columns = [
    'select',
    'auto_id',
    'box_template_config_id',
    'box_id',
    'product_id',
    'img_url',
    'quantity',
    'product_level',
    'edit',
    'created_at',
    'updated_at',
  ];
  final _columnsTitle = [
    '选择',
    'ID',
    '箱子配置ID',
    '箱子ID',
    '商品ID',
    '图片',
    '数量',
    '商品等级',
    '编辑',
    '创建时间',
    '更新时间',
  ];
  List<DataColumn> _columnNames = [];
  List<int> _selectedItemIds = [];
  List<dynamic> _currentPageData = [];
  final int _imageColumnIndex = 5;
  final bool _hasDetailButton = false;

  //分页参数
  late int _pageSize = 3;
  late int _currentPage = 0;
  late List<Map<String, dynamic>> _searchResult = [];

  //下拉默认
  String _dropdownValue = 'box_id';

  //输入框控制器
  final _searchController = TextEditingController();

  bool _isLoading = true;

  //请求数据
  Future<void> fetchData() async {
    _dio.interceptors
        .add(LogInterceptor(responseBody: true, requestBody: true));
    try {
      Map<String, dynamic> queryParams = {
        'box_id': int.parse(widget.id),
      };
      Response response = await _dio.get(
        _getAllBoxItemConfigByBoxIdUrl,
        queryParameters: queryParams,
      );
      print('Response body: ${response.data}');
      String _responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      _responseBody = _responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
      print('JSON response body: ${_responseBody}');

      List<dynamic> responseList = jsonDecode(_responseBody);
      _boxItemConfigData = responseList.map<Map<String, dynamic>>((item) {
        return {
          "auto_id": item["auto_id"] ?? "",
          "box_template_config_id": item["box_template_config_id"] ?? "",
          "box_id": item["box_id"] ?? "",
          "product_id": item["product_id"] ?? "",
          "quantity": item["quantity"] ?? "",
          "product_level": item["product_level"] ?? "",
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
        _searchResult = _boxItemConfigData;
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

  //增删查改相关函数
  void _searchBoxes() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _searchResult = _boxItemConfigData.where((user) {
          return user[_dropdownValue].toString().contains(keyword);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _addConfigItem() async {
    Map<String, dynamic>? newItem;
    await showDialog(
      context: context,
      builder: (context) {
        newItem = {
          'box_id': int.parse(widget.id),
          'box_template_config_id': null,
          'product_id': null,
          'quantity': null,
          'product_level': null,
        };
        return AlertDialog(
          title: const Text('添加箱子模板'),
          content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: TextEditingController(text: widget.id),
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: '箱子ID',
                        ),
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
                          labelText: '商品数量',
                        ),
                        onChanged: (value) {
                          newItem?['quantity'] = int.tryParse(value);
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
                          labelText: '模板ID',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newItem?['box_template_config_id'] =
                              int.tryParse(value);
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
                  final response =
                      await _dio.post(_addConfigUrl, data: newItem);
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
      Response response = await _dio.delete(_deleteConfigUrl, data: {
        "auto_ids": _selectedItemIds,
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
          content: const Text('确定删除所选配置吗？'),
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
    editedConfigItem['box_id'] =
        int.tryParse(editedConfigItem['box_id'].toString());
    editedConfigItem['auto_id'] =
        int.tryParse(editedConfigItem['auto_id'].toString());
    editedConfigItem['product_id'] =
        int.tryParse(editedConfigItem['product_id'].toString());
    editedConfigItem['quantity'] =
        int.tryParse(editedConfigItem['quantity'].toString());
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
                      labelText: 'ID',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['auto_id'].toString()),
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
                      labelText: '商品数量',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['quantity'].toString()),
                    onChanged: (value) {
                      editedConfigItem['quantity'] = int.parse(value);
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
                  final response =
                      await _dio.post(_updateConfigUrl, data: editedConfigItem);
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
    _columnNames = _columnsTitle
        .map((e) => DataColumn(
              label: Text(e),
            ))
        .toList();
    fetchData();
    super.initState();
  }

  @override
  build(context) {
    return SizedBox.expand(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
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
                        items: <String>['箱子ID', '商品ID', '模板ID']
                            .map<DropdownMenuItem<String>>((String value) {
                          late String key;
                          switch (value) {
                            case '箱子ID':
                              key = 'box_id';
                              break;
                            case '商品ID':
                              key = 'product_id';
                              break;
                            case '模板ID':
                              key = 'box_template_config_id';
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
                      SizedBox(
                        width: 80,
                        child: ElevatedButton(
                          onPressed: _addConfigItem,
                          child: const Text('添加'),
                        ),
                      ),
                    ],
                  ),
                  CustomDataTable(
                      columns: _columns,
                      columnNames: _columnNames,
                      selectedItemIds: _selectedItemIds,
                      hasDetailButton: _hasDetailButton,
                      currentPageData: _currentPageData,
                      imageColumnIndex: _imageColumnIndex,
                      editData: _editData),
                  PaginationControl(
                      currentPage: _currentPage,
                      totalItems: _searchResult.length,
                      pageSize: _pageSize,
                      onNextPage: _nextPage,
                      onPrevPage: _prevPage)
                ],
              ),
            )),
      ),
    );
  }
}
