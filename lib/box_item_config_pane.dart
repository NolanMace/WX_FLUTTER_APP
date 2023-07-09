import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'custom_data_table.dart';
import 'pagination_control.dart';

class BoxItemConfigPane extends StatefulWidget {
  final int id;
  final Function(int)? toProductInstance;
  final Function(int)? toBoxInstance;
  const BoxItemConfigPane(
      {Key? key, required this.id, this.toBoxInstance, this.toProductInstance})
      : super(key: key);

  @override
  State<BoxItemConfigPane> createState() => _BoxItemConfigPaneState();
}

class _BoxItemConfigPaneState extends State<BoxItemConfigPane> {
  final Dio _dio = Dio();
  //请求参数
  final String _getAllBoxItemConfigByBoxIdUrl = AppConfig.getConfigUrl;
  final String _addConfigUrl = AppConfig.addConfigUrl;
  final String _deleteConfigUrl = AppConfig.deleteConfigUrl;
  final String _updateConfigUrl = AppConfig.updateConfigUrl;
  final String _generateBoxItemsUrl = AppConfig.generateBoxItemsUrl;
  final _getBoxUrl = AppConfig.getBoxUrl;
  late List<Map<String, dynamic>> _boxItemConfigData;

  final _boxInfo = {
    "box_id": 0,
    "box_type": "",
    "box_name": "",
    "image_url": "",
    "box_price": 0,
  };

  //表格参数
  final List<String> _columns = [
    'select',
    'auto_id',
    'box_template_config_id',
    'box_id',
    'product_id',
    'quantity',
    'drawn_num',
    'send_num',
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
    '数量',
    'drawn_num',
    'send_num',
    '商品等级',
    '编辑',
    '创建时间',
    '更新时间',
  ];
  List<DataColumn> _columnNames = [];
  List<int> _selectedItemIds = [];
  List<dynamic> _currentPageData = [];
  final int _imageColumnIndex = 10000;
  final bool _hasDetailButton = false;

  //分页参数
  final int _pageSize = 10;
  late int _currentPage = 0;
  late List<Map<String, dynamic>> _searchResult = [];

  //下拉默认
  String _dropdownValue = 'product_level';

  //输入框控制器
  final _searchController = TextEditingController();

  bool _isLoading = true;

  bool _gotBox = false;

  //请求数据
  Future<void> fetchData() async {
    if (widget.id == 0) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
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
      final boxInfoResponse = await _dio.get(
        queryParameters: {
          'box_id': widget.id,
        },
        _getBoxUrl,
        options: options,
      );
      Map<String, dynamic> queryParams = {
        'box_id': widget.id,
      };
      Response response = await _dio.get(
        _getAllBoxItemConfigByBoxIdUrl,
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
      _boxItemConfigData = responseList.map<Map<String, dynamic>>((item) {
        return {
          "auto_id": item["auto_id"] ?? "",
          "box_template_config_id": item["box_template_config_id"] ?? "",
          "box_id": item["box_id"] ?? "",
          "product_id": item["product_id"] ?? "",
          "quantity": item["quantity"] ?? "",
          "product_level": item["product_level"] ?? "",
          "drawn_num": item["drawn_num"] ?? "",
          "send_num": item["send_num"] ?? "",
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
        _boxInfo["box_id"] = boxInfoResponse.data["box_id"];
        _boxInfo["box_type"] = boxInfoResponse.data["box_type"];
        _boxInfo["box_name"] = boxInfoResponse.data["box_name"];
        _boxInfo["image_url"] = boxInfoResponse.data["image_url"];
        _boxInfo["box_price"] = boxInfoResponse.data["box_price"];
        _gotBox = true;
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

  void _jumpToPage(page) {
    setState(() {
      if (page >= 1 && (page - 1) * _pageSize <= _searchResult.length) {
        _currentPage = page - 1;
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
          String value = user[_dropdownValue].toString();
          RegExp regExp = RegExp(r"\b" + keyword + r"\b");
          return regExp.hasMatch(value);
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
          'box_id': widget.id,
          'box_template_config_id': null,
          'product_id': null,
          'quantity': null,
          'product_level': null,
          'drawn_num': null,
          'send_num': null,
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
                        controller:
                            TextEditingController(text: widget.id.toString()),
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
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '手脚',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newItem?['drawn_num'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '触发赠送',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newItem?['send_num'] = int.tryParse(value);
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
                  print(newItem);
                  await _dio.post(_addConfigUrl,
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
      await _dio.delete(_deleteConfigUrl, options: options, data: {
        "auto_ids": _selectedItemIds,
      });
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
    editedConfigItem['box_template_config_id'] =
        int.tryParse(editedConfigItem['box_template_config_id'].toString());
    editedConfigItem['box_id'] =
        int.tryParse(editedConfigItem['box_id'].toString());
    editedConfigItem['auto_id'] =
        int.tryParse(editedConfigItem['auto_id'].toString());
    editedConfigItem['product_id'] =
        int.tryParse(editedConfigItem['product_id'].toString());
    editedConfigItem['quantity'] =
        int.tryParse(editedConfigItem['quantity'].toString());
    editedConfigItem['drawn_num'] =
        int.tryParse(editedConfigItem['drawn_num'].toString());
    editedConfigItem['send_num'] =
        int.tryParse(editedConfigItem['send_num'].toString());
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
                      labelText: '配置ID',
                    ),
                    controller: TextEditingController(
                        text: configItem['box_template_config_id'].toString()),
                    onChanged: (value) {
                      editedConfigItem['box_template_config_id'] =
                          int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '商品ID',
                    ),
                    controller: TextEditingController(
                        text: configItem['product_id'].toString()),
                    onChanged: (value) {
                      editedConfigItem['product_id'] = int.tryParse(value);
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
                      editedConfigItem['quantity'] = int.tryParse(value);
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
                      labelText: '手脚',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['drawn_num'].toString()),
                    onChanged: (value) {
                      editedConfigItem['drawn_num'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '发货数量',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: configItem['send_num'].toString()),
                    onChanged: (value) {
                      editedConfigItem['send_num'] = int.tryParse(value);
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
                  print(editedConfigItem);
                  await _dio.post(_updateConfigUrl,
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

  void _addBoxInstance() async {
    Map<String, dynamic>? newItem = {
      'box_id': widget.id,
      'app_id': null,
      'box_template_config_id': null,
      'box_quantity': null,
    };
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('添加箱子实例'),
            content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '箱子ID',
                        ),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(text: widget.id.toString()),
                        enabled: false,
                      ),
                      TextField(
                          decoration: const InputDecoration(
                            labelText: '应用ID',
                          ),
                          onChanged: (value) {
                            newItem['app_id'] = value.toString();
                          }),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '配置ID',
                        ),
                        onChanged: (value) {
                          newItem['box_template_config_id'] =
                              int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '箱子数量',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newItem['box_quantity'] = int.tryParse(value);
                        },
                      ),
                    ]))),
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
                    await _dio.post(_generateBoxItemsUrl,
                        options: options, data: newItem);
                    Navigator.of(context).pop();
                  } catch (error) {
                    print('Error: $error');
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
  }

  @override
  void initState() {
    super.initState();
    _columnNames = _columnsTitle
        .map((e) => DataColumn(
              label: Text(
                e,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ))
        .toList();
    fetchData();
  }

  //销毁控制器
  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BoxItemConfigPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果新的 `id` 与旧的 `id` 不同，那么执行一些操作，例如重新获取数据
    if (widget.id != oldWidget.id) {
      fetchData(); // 重新获取数据
    }
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _gotBox
                                ? Image(
                                    image: NetworkImage(
                                        _boxInfo['image_url'].toString()),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : const Placeholder(
                                    fallbackHeight: 80,
                                    fallbackWidth: 80,
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
                              items: <String>[
                                '商品等级',
                                '商品ID',
                                '模板ID'
                              ].map<DropdownMenuItem<String>>((String value) {
                                late String key;
                                switch (value) {
                                  case '商品等级':
                                    key = 'product_level';
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
                        const SizedBox(
                          height: 20,
                        ),
                        Row(children: [
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 100,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: _addBoxInstance,
                              child: const Text('添加箱数'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () => widget.toBoxInstance!(widget.id),
                              child: const Text(
                                '查看箱子实例',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 120,
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () =>
                                  widget.toProductInstance!(widget.id),
                              child: const Text('查看商品实例'),
                            ),
                          ),
                        ]),
                        Column(
                          children: [
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
                              onPrevPage: _prevPage,
                              onJumpPage: _jumpToPage,
                            )
                          ],
                        )
                      ],
                    ),
                  )),
            ),
          );
  }
}
