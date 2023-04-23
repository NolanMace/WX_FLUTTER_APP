import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'pagination_control.dart';

class BoxDisplay extends StatefulWidget {
  const BoxDisplay({super.key, required this.boxId});
  final int boxId;

  @override
  State<BoxDisplay> createState() => _BoxDisplayState();
}

class _BoxDisplayState extends State<BoxDisplay> {
  final Dio _dio = Dio();
  final _getAdminDisplayBox = AppConfig.getAdminDisplayBox;
  final _getBoxUrl = AppConfig.getBoxUrl;
  final _deleteUrl = AppConfig.deleteDisplayBoxUrl;
  final _addUrl = AppConfig.addDisplayBoxUrl;
  late List<dynamic> _displayItems;
  var _boxInfo = {
    "box_id": 0,
    "box_type": "",
    "box_name": "",
    "image_url": "",
    "box_price": 0,
  };

  //表格相关参数
  late List<DataColumn> _columns;
  late List<int> _selectedItemIds;
  late List<dynamic> _currentPageData;

  //分页相关参数
  final int _pageSize = 15;
  late int _currentPage = 0;
  late List<dynamic> _searchResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  bool _isAllSelected = false;

  //输入框控制器
  final _searchController = TextEditingController();

  void fetchData() async {
    if (widget.boxId == 0) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
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
      final boxInfoResponse = await _dio.get(
        queryParameters: {
          'box_id': widget.boxId,
        },
        _getBoxUrl,
        options: options,
      );
      final response = await _dio.get(
        queryParameters: {
          'box_id': widget.boxId,
        },
        _getAdminDisplayBox,
        options: options,
      );
      if (response.data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final data = response.data;
      setState(() {
        _boxInfo["box_id"] = boxInfoResponse.data["box_id"];
        _boxInfo["box_type"] = boxInfoResponse.data["box_type"];
        _boxInfo["box_name"] = boxInfoResponse.data["box_name"];
        _boxInfo["image_url"] = boxInfoResponse.data["image_url"];
        _boxInfo["box_price"] = boxInfoResponse.data["box_price"];
        _selectedItemIds.clear();
        _isAllSelected = false;
        _currentPage = 0;
        _displayItems = data;
        _searchResult = _displayItems;
        _currentPageData = _searchResult
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      // ignore: use_build_context_synchronously
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
  }

  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.clear();
        _selectedItemIds = _searchResult.map((item) {
          int id = item["auto_id"];
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
        _searchResult = _displayItems.where((item) {
          String value = item["app_id"].toString();
          RegExp regExp = RegExp(r"\b" + keyword + r"\b");
          return regExp.hasMatch(value);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _postDeleteRequest() async {
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
      await _dio.delete(_deleteUrl, options: options, data: {
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

  void _deleteItems() {
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
                _postDeleteRequest();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _addItem() async {
    Map<String, dynamic>? newItem;
    await showDialog(
        context: context,
        builder: (context) {
          newItem = {
            "auto_id": 0,
            "box_id": widget.boxId,
            "app_id": "",
            "box_type": _boxInfo["box_type"],
          };
          return AlertDialog(
            title: const Text('添加配置'),
            content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '箱子ID',
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: widget.boxId.toString()),
                          enabled: false,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '箱子类型',
                          ),
                          controller: TextEditingController(
                              text: _boxInfo["box_type"].toString()),
                          enabled: false,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'APPID',
                          ),
                          onChanged: (value) {
                            newItem?['app_id'] = value;
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
                    await _dio.post(_addUrl, options: options, data: newItem);
                    fetchData();
                  } catch (e) {
                    print('Error: $e');
                    setState(() {
                      _isLoading = true;
                    });
                  }
                  Navigator.of(context).pop();
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
        width: 60,
        child: Text("箱子ID"),
      )),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("箱子类型"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("APPID"),
        ),
      ),
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
    _dio.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BoxDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果新的 `id` 与旧的 `id` 不同，那么执行一些操作，例如重新获取数据
    if (widget.boxId != oldWidget.boxId) {
      fetchData(); // 重新获取数据
    }
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
                                  const Image(
                                    image: AssetImage('assets/wuxianshang.jpg'),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
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
                                      onPressed: _addItem,
                                      child: const Text('上架'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 80,
                                    child: ElevatedButton(
                                      onPressed: _deleteItems,
                                      child: const Text('下架'),
                                    ),
                                  ),
                                ]),
                            DataTable(
                              columns: _columns,
                              rows: List<DataRow>.generate(
                                  _currentPageData.length, (item) {
                                return DataRow(cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 40,
                                      child: Checkbox(
                                          value: _selectedItemIds.contains(
                                              _currentPageData[item]
                                                  ['auto_id']),
                                          onChanged: (value) {
                                            setState(() {
                                              if (value!) {
                                                _selectedItemIds.add(
                                                    _currentPageData[item]
                                                        ['auto_id']);
                                              } else {
                                                _selectedItemIds.remove(
                                                    _currentPageData[item]
                                                        ['auto_id']);
                                              }
                                            });
                                          }),
                                    ),
                                  ),
                                  DataCell(SizedBox(
                                    width: 60,
                                    child: Text(
                                        _currentPageData[item]['box_id']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                        )),
                                  )),
                                  DataCell(SizedBox(
                                    width: 60,
                                    child:
                                        Text(_currentPageData[item]['box_type'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            )),
                                  )),
                                  DataCell(SizedBox(
                                    width: 60,
                                    child:
                                        Text(_currentPageData[item]['app_id'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            )),
                                  )),
                                ]);
                              }),
                            ),
                            PaginationControl(
                                currentPage: _currentPage,
                                totalItems: _searchResult.length,
                                pageSize: _pageSize,
                                onNextPage: _nextPage,
                                onPrevPage: _prevPage)
                          ],
                        )))));
  }
}
