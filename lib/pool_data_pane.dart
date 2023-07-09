import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mis/config.dart';
import 'package:mis/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pagination_control.dart';

class PoolDataPane extends StatefulWidget {
  const PoolDataPane({
    Key? key,
    this.toDetail,
    this.toDisplay,
  }) : super(key: key);

  final Function(int)? toDetail;
  final Function(int)? toDisplay;

  @override
  State<PoolDataPane> createState() => _PoolDataPaneState();
}

class _PoolDataPaneState extends State<PoolDataPane> {
  final Dio _dio = Dio();
  //网络请求相关参数
  final _getAllPoolsUrl = AppConfig.getAllPoolsUrl;
  final _deletePoolUrl = AppConfig.deletePoolUrl;
  final _addPoolUrl = AppConfig.addPoolUrl;
  final _updatePoolUrl = AppConfig.updatePoolUrl;
  late List<dynamic> _pools;

//表格相关参数
  late List<DataColumn> _columns;
  late List<int> _selectedpoolIds;
  late List<dynamic> _currentPageData;

  //分页相关参数
  final int _pageSize = 20;
  late int _currentPage = 0;
  late List<dynamic> _searchResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  //判断是否全选
  bool _isAllSelected = false;

  //输入框控制器
  final _searchController = TextEditingController();

  late String _dropdownValue = "pool_id"; //下拉选择默认值

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
    _columns = [
      DataColumn(
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
      )),
      const DataColumn(
          label: SizedBox(
        width: 60,
        child: Text("池子ID", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 100,
        child: Text(
          "池子名称",
          style: TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text("池子等级", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text("池子类型", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text("封面URL", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 80,
        child: Text("备注", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 60,
        child: Text("价格", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 80,
        child: Text("配置详情", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 80,
        child: Text("上架详情", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 60,
        child: Text("编辑", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 80,
        child: Text("创建时间", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 80,
        child: Text("更新时间", style: TextStyle(fontSize: 14)),
      )),
    ];
    _selectedpoolIds = [];
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
      Response response = await _dio.get(_getAllPoolsUrl, options: options);
      debugPrint(response.data.toString());
      if (response.data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _selectedpoolIds.clear();
        _isAllSelected = false;
        _currentPage = 0;
        _pools = response.data;
        _searchResult = _pools;
        _currentPageData = _searchResult
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error: $error');
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

  void _jumpToPage(page) {
    setState(() {
      if (page >= 1 && (page - 1) * _pageSize <= _searchResult.length) {
        _currentPage = page - 1;
        _loadData();
      }
    });
  }

  //全选相关函数
  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedpoolIds.clear();
        _selectedpoolIds = _searchResult.map((item) {
          int id = item["pool_id"];
          return id;
        }).toList();
        _isAllSelected = false;
      } else {
        _selectedpoolIds.clear();
        _isAllSelected = true;
      }
    });
  }

  //增删查改相关函数
  void _searchpools() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _searchResult = _pools.where((user) {
          return user[_dropdownValue].toString().contains(keyword);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _addpool() async {
    Map<String, dynamic>? newpool;
    await showDialog(
      context: context,
      builder: (context) {
        newpool = {
          'pool_id': null,
          'pool_name': null,
          'pool_level': null,
          'pool_type': null,
          'image_url': null,
          'notes': null,
          'pool_price': null,
        };
        return AlertDialog(
          title: const Text('添加池子'),
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
                        onChanged: (value) {
                          newpool?['pool_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '池子名称',
                        ),
                        onChanged: (value) {
                          newpool?['pool_name'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '池子等级',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newpool?['pool_level'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '池子类型',
                        ),
                        onChanged: (value) {
                          newpool?['pool_type'] = value.toString();
                        },
                      ),
                      const Text(
                        "image_url",
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                      ImagePicker(
                          callback: (file) =>
                              newpool?['image_url'] = file.toString()),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '备注',
                        ),
                        onChanged: (value) {
                          newpool?['notes'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '价格',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          newpool?['pool_price'] = double.tryParse(value);
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
                  await _dio.post(_addPoolUrl, options: options, data: newpool);
                  Navigator.of(context).pop();
                  fetchData();
                } catch (error) {
                  debugPrint('Error: $error');
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
      await _dio.delete(_deletePoolUrl, options: options, data: {
        "pool_ids": _selectedpoolIds,
      });
      fetchData();
    } catch (error) {
      debugPrint('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _deletepools() {
    if (_selectedpoolIds.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确定删除所选池子吗？'),
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

  void _editpool(poolData) async {
    Map<String, dynamic> editedpool = {
      'pool_id': poolData['pool_id'],
      'pool_name': poolData['pool_name'],
      'pool_level': poolData['pool_level'],
      'pool_type': poolData['pool_type'],
      'image_url': poolData['image_url'],
      'notes': poolData['notes'],
      'pool_price': poolData['pool_price'],
    };
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑池子信息'),
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
                        text: poolData['pool_id'].toString()),
                    enabled: false,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '池子名称',
                    ),
                    controller:
                        TextEditingController(text: poolData['pool_name']),
                    onChanged: (value) {
                      editedpool['pool_name'] = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '池子等级',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: poolData['pool_level'].toString()),
                    onChanged: (value) {
                      editedpool['pool_level'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '池子类型',
                    ),
                    controller:
                        TextEditingController(text: poolData['pool_type']),
                    onChanged: (value) {
                      editedpool['pool_type'] = value.toString();
                    },
                  ),
                  const Text(
                    "image_url",
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                  ImagePicker(
                      callback: (file) =>
                          editedpool['image_url'] = file.toString()),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '备注',
                    ),
                    controller: TextEditingController(text: poolData['notes']),
                    onChanged: (value) {
                      editedpool['notes'] = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '价格',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(
                        text: poolData['pool_price'].toString()),
                    onChanged: (value) {
                      editedpool['pool_price'] = double.tryParse(value);
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
                  await _dio.post(_updatePoolUrl,
                      options: options, data: editedpool);
                  Navigator.of(context).pop();
                  fetchData();
                } catch (error) {
                  debugPrint('Error: $error');
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
                      '池子ID',
                      '池子名称',
                      '池子类型',
                    ].map<DropdownMenuItem<String>>((String value) {
                      late String key;
                      switch (value) {
                        case '池子ID':
                          key = 'pool_id';
                          break;
                        case '池子名称':
                          key = 'pool_name';
                          break;
                        case '池子类型':
                          key = 'pool_type';
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
                      onPressed: _searchpools,
                      child: const Text('查找'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _deletepools,
                      child: const Text('删除'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _addpool,
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        SizedBox(
                            width: double.infinity,
                            child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 5,
                                  columns: _columns,
                                  rows: List<DataRow>.generate(
                                      _currentPageData.length, (index) {
                                    final item = _currentPageData[index];
                                    return DataRow(cells: [
                                      DataCell(
                                        Checkbox(
                                            value: _selectedpoolIds
                                                .contains(item['pool_id']),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                int? id = item['pool_id'];
                                                if (value!) {
                                                  _selectedpoolIds.add(id!);
                                                } else {
                                                  _selectedpoolIds.remove(id);
                                                }
                                              });
                                            }),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            item['pool_id'].toString(),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            item['pool_name'],
                                            style:
                                                const TextStyle(fontSize: 14),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            item['pool_level'],
                                            style:
                                                const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            item['pool_type'],
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Image(
                                            image: NetworkImage(
                                                item["image_url"].toString()),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            item['notes'].toString(),
                                            style:
                                                const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 4,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            item['pool_price'].toString(),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              widget.toDetail!(item['pool_id']);
                                            },
                                            child: const Text('配置详情',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              widget
                                                  .toDisplay!(item['pool_id']);
                                            },
                                            child: const Text('上架详情',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _editpool(item);
                                            },
                                            child: const Text('编辑',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      ),
                                      DataCell(SizedBox(
                                        width: 80,
                                        child: Text(
                                          item['created_at'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      )),
                                      DataCell(SizedBox(
                                        width: 80,
                                        child: Text(
                                          item['updated_at'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      )),
                                    ]);
                                  }),
                                ))),
                        PaginationControl(
                          currentPage: _currentPage,
                          totalItems: _searchResult.length,
                          pageSize: _pageSize,
                          onNextPage: _nextPage,
                          onPrevPage: _prevPage,
                          onJumpPage: _jumpToPage,
                        )
                      ],
                    )),
              ),
            ],
          );
  }
}
