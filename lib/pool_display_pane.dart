import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'image_picker.dart';
import 'pagination_control.dart';

class PoolDisplay extends StatefulWidget {
  const PoolDisplay({super.key, required this.poolId});
  final int poolId;

  @override
  State<PoolDisplay> createState() => _PoolDisplayState();
}

class _PoolDisplayState extends State<PoolDisplay> {
  final Dio _dio = Dio();
  final _getAdminDisplayPool = AppConfig.getAdminDisplayPool;
  final _getPoolUrl = AppConfig.getPoolUrl;
  final _deleteUrl = AppConfig.deleteDisplayPoolUrl;
  final _addUrl = AppConfig.addDisplayPoolUrl;
  final _updateUrl = AppConfig.updatePoolsDisplayUrl;
  final _updateShowNewLabelUrl = AppConfig.updatePoolsDisplayShowNewLabel;
  late List<dynamic> _displayItems;
  final _poolInfo = {
    "pool_id": 0,
    "pool_type": "",
    "pool_name": "",
    "image_url": "",
    "pool_price": 0,
  };
  bool _gotPoolInfo = false;

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
    if (widget.poolId == 0) {
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
      final poolInfoResponse = await _dio.get(
        queryParameters: {
          'pool_id': widget.poolId,
        },
        _getPoolUrl,
        options: options,
      );
      final response = await _dio.get(
        queryParameters: {
          'pool_id': widget.poolId,
        },
        _getAdminDisplayPool,
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
        _poolInfo["pool_id"] = poolInfoResponse.data["pool_id"];
        _poolInfo["pool_type"] = poolInfoResponse.data["pool_type"];
        _poolInfo["pool_name"] = poolInfoResponse.data["pool_name"];
        _poolInfo["image_url"] = poolInfoResponse.data["image_url"];
        _poolInfo["pool_price"] = poolInfoResponse.data["pool_price"];
        _gotPoolInfo = true;
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
            "pool_id": widget.poolId,
            "app_id": "",
            "pool_type": _poolInfo["pool_type"],
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
                            labelText: '池子ID',
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                              text: widget.poolId.toString()),
                          enabled: false,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '池子类型',
                          ),
                          controller: TextEditingController(
                              text: _poolInfo["pool_type"].toString()),
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
                        const Text(
                          '分享图片',
                          style: TextStyle(fontSize: 16),
                        ),
                        ImagePicker(callback: (value) {
                          newItem?['share_img'] = value;
                        }),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '分享标题',
                          ),
                          onChanged: (value) {
                            newItem?['share_title'] = value;
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

  void _setNewLabel(item, bool value) async {
    Map<String, dynamic>? newItem = {
      "auto_id": item["auto_id"],
      "pool_id": item["pool_id"],
      "app_id": item["app_id"],
      "pool_type": item["pool_type"],
      "lottery_count": item["lottery_count"],
      "show_new_label": value,
    };
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
      await _dio.post(_updateShowNewLabelUrl, options: options, data: newItem);
      fetchData();
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _postEditRequest(item) async {
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
      await _dio.post(_updateUrl, options: options, data: item);
      fetchData();
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _editItem(item) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('编辑配置'),
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
                              text: item["pool_id"].toString()),
                          enabled: false,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '池子类型',
                          ),
                          controller: TextEditingController(
                              text: item["pool_type"].toString()),
                          enabled: false,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'APPID',
                          ),
                          controller: TextEditingController(
                              text: item["app_id"].toString()),
                          onChanged: (value) {
                            item["app_id"] = value;
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '分享图片',
                          style: TextStyle(fontSize: 16),
                        ),
                        ImagePicker(
                            callback: (value) =>
                                item["share_img"] = value.toString()),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '分享标题',
                          ),
                          controller: TextEditingController(
                              text: item["share_title"].toString()),
                          onChanged: (value) {
                            item["share_title"] = value;
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
                onPressed: () {
                  Navigator.of(context).pop();
                  _postEditRequest(item);
                },
                child: const Text('确定'),
              )
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
        child: Text("池子ID"),
      )),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("池子类型"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 80,
          child: Text("抽奖次数"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("APPID"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("上新提醒"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 80,
          child: Text("分享图片"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 80,
          child: Text("分享标题"),
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
  void didUpdateWidget(covariant PoolDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果新的 `id` 与旧的 `id` 不同，那么执行一些操作，例如重新获取数据
    if (widget.poolId != oldWidget.poolId) {
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
                                  _gotPoolInfo
                                      ? Image(
                                          image: NetworkImage(
                                              _poolInfo['image_url']
                                                  .toString()),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : const Placeholder(
                                          fallbackHeight: 80,
                                          fallbackWidth: 80,
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
                                        _currentPageData[item]['pool_id']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                        )),
                                  )),
                                  DataCell(SizedBox(
                                    width: 60,
                                    child: Text(
                                        _currentPageData[item]['pool_type'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                        )),
                                  )),
                                  DataCell(SizedBox(
                                    width: 80,
                                    child: Text(
                                        _currentPageData[item]['lottery_count']
                                            .toString(),
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
                                  DataCell(SizedBox(
                                      width: 60,
                                      child: Switch(
                                        value: _currentPageData[item]
                                            ['show_new_label'],
                                        onChanged: (value) {
                                          _setNewLabel(
                                              _currentPageData[item], value);
                                        },
                                      ))),
                                  DataCell(SizedBox(
                                    width: 80,
                                    child: Image.network(
                                        _currentPageData[item]['share_img']
                                            .toString(),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.fill),
                                  )),
                                  DataCell(SizedBox(
                                    width: 80,
                                    child: Text(
                                        _currentPageData[item]['share_title']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                        )),
                                  )),
                                  DataCell(SizedBox(
                                    width: 60,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _editItem(_currentPageData[item]);
                                      },
                                      child: const Text('编辑'),
                                    ),
                                  )),
                                ]);
                              }),
                            ),
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
