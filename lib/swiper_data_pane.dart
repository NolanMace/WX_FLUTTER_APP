import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mis/pagination_control.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'image_picker.dart';

class AppSwiperData extends StatefulWidget {
  const AppSwiperData({super.key});

  @override
  State<AppSwiperData> createState() => _AppSwiperDataState();
}

class _AppSwiperDataState extends State<AppSwiperData> {
  final Dio _dio = Dio();
  final String _createAppSwiperItem = AppConfig.createAppSwiperItem;
  final String _deleteAppSwiperItem = AppConfig.deleteAppSwiperItem;
  final String _updateAppSwiperItem = AppConfig.updateAppSwiperItem;
  final String _getAppSwiperItems = AppConfig.getAppSwiperItems;

  late List<dynamic> _items;
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
      Response res = await _dio.get(_getAppSwiperItems, options: options);
      setState(() {
        _selectedItemIds.clear();
        _isAllSelected = false;
        _currentPage = 0;
        _items = res.data;
        _searchResult = _items;
        _currentPageData = _searchResult
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('获取数据失败：$e');
      setState(() {
        _isLoading = true;
      });
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
        _searchResult = _items.where((item) {
          String value = item["app_id"].toString();
          return value == keyword;
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
      await _dio.delete(_deleteAppSwiperItem, options: options, data: {
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

  void _deleteItems() {
    if (_selectedItemIds.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确定删除吗？'),
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

  void _postCreateRequest(newItem, showResult) async {
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
      await _dio.post(_createAppSwiperItem, options: options, data: newItem);
      showResult();
      fetchData();
    } catch (error) {
      debugPrint('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _createItem() {
    showDialog(
        context: context,
        builder: (context) {
          Map<String, dynamic> newItem = {
            "app_id": '',
            "image_url": '',
            "link_url": '',
          };
          return AlertDialog(
            title: const Text('创建弹窗'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 250,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'APPID',
                      ),
                      onChanged: (value) {
                        newItem['app_id'] = value.toString();
                      },
                    ),
                    const Text('image_url', style: TextStyle(fontSize: 12)),
                    ImagePicker(
                        callback: (fileUrl) => newItem['image_url'] = fileUrl),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'link_url',
                      ),
                      onChanged: (value) {
                        newItem['link_url'] = value.toString();
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
                onPressed: () {
                  _postCreateRequest(
                    newItem,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('创建成功'),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                  );
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
  }

  void _postUpdateRequest(item, showResult) async {
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
      await _dio.post(_updateAppSwiperItem, options: options, data: item);
      showResult();
      fetchData();
    } catch (error) {
      debugPrint('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _editItem(item) {
    showDialog(
        context: context,
        builder: (context) {
          Map<String, dynamic> newItem = {
            "auto_id": item['auto_id'],
            "app_id": item['app_id'],
            "image_url": item['image_url'],
            "link_url": item['link_url'],
          };
          return AlertDialog(
            title: const Text('编辑'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 250,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'APPID',
                      ),
                      controller: TextEditingController(text: item['app_id']),
                      onChanged: (value) {
                        newItem['app_id'] = value.toString();
                      },
                    ),
                    ImagePicker(
                        callback: (fileUrl) => newItem['image_url'] = fileUrl),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'link_url',
                      ),
                      controller: TextEditingController(text: item['link_url']),
                      onChanged: (value) {
                        newItem['link_url'] = value.toString();
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
                onPressed: () {
                  _postUpdateRequest(
                    newItem,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('更新成功'),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                  );
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

  void _jumpToPage(page) {
    setState(() {
      if (page >= 1 && (page - 1) * _pageSize <= _searchResult.length) {
        _currentPage = page - 1;
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
        child: Text("自增ID"),
      )),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("APPID"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("图片地址"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("链接地址"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("编辑"),
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
                                    onPressed: _createItem,
                                    child: const Text('添加'),
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
                              ],
                            ),
                            DataTable(
                                dataTextStyle: const TextStyle(fontSize: 12),
                                dataRowMinHeight: 50,
                                dataRowMaxHeight: 90,
                                columnSpacing: 2,
                                columns: _columns,
                                rows: List<DataRow>.generate(
                                    _currentPageData.length,
                                    (index) => DataRow(cells: [
                                          DataCell(
                                            Checkbox(
                                                value:
                                                    _selectedItemIds.contains(
                                                        _currentPageData[index]
                                                            ['auto_id']),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    int? id =
                                                        _currentPageData[index]
                                                            ['auto_id'];
                                                    if (value!) {
                                                      _selectedItemIds.add(id!);
                                                    } else {
                                                      _selectedItemIds
                                                          .remove(id);
                                                    }
                                                  });
                                                }),
                                          ),
                                          DataCell(Text(
                                              _currentPageData[index]['auto_id']
                                                  .toString(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black))),
                                          DataCell(Text(
                                              _currentPageData[index]['app_id']
                                                  .toString(),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black))),
                                          DataCell(SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: Image.network(
                                                _currentPageData[index]
                                                        ['image_url']
                                                    .toString()),
                                          )),
                                          DataCell(Text(
                                            _currentPageData[index]['link_url']
                                                .toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          )),
                                          DataCell(SizedBox(
                                              width: 60,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  _editItem(
                                                      _currentPageData[index]);
                                                },
                                                child: const Text('编辑'),
                                              )))
                                        ]))),
                            PaginationControl(
                              currentPage: _currentPage,
                              totalItems: _searchResult.length,
                              pageSize: _pageSize,
                              onNextPage: _nextPage,
                              onPrevPage: _prevPage,
                              onJumpPage: _jumpToPage,
                            )
                          ],
                        )))));
  }
}
