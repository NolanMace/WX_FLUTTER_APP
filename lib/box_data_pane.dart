import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mis/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pagination_control.dart';

class BoxDataPane extends StatefulWidget {
  const BoxDataPane({
    Key? key,
    this.toDetail,
    this.toDisplay,
  }) : super(key: key);

  final Function(int)? toDetail;
  final Function(int)? toDisplay;

  @override
  _BoxDataPaneState createState() => _BoxDataPaneState();
}

class _BoxDataPaneState extends State<BoxDataPane> {
  final Dio _dio = Dio();
  //网络请求相关参数
  final _getAllBoxesUrl = AppConfig.getAllBoxesUrl;
  final _deleteBoxUrl = AppConfig.deleteBoxUrl;
  final _addBoxUrl = AppConfig.addBoxUrl;
  final _editBoxUrl = AppConfig.updateBoxUrl;
  late List<dynamic> _boxes;

//表格相关参数
  late List<DataColumn> _columns;
  late List<int> _selectedBoxIds;
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

  late String _dropdownValue = "box_id"; //下拉选择默认值

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
        child: Text("箱子ID", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 60,
        child: Text("容量", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 100,
        child: Text(
          "箱子名称",
          style: TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text("箱子等级", style: TextStyle(fontSize: 14)),
      )),
      const DataColumn(
          label: SizedBox(
        width: 70,
        child: Text("箱子类型", style: TextStyle(fontSize: 14)),
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
    _selectedBoxIds = [];
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
      Response response = await _dio.get(_getAllBoxesUrl, options: options);
      print(response.data);
      if (response.data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _selectedBoxIds.clear();
        _isAllSelected = false;
        _currentPage = 0;
        _boxes = response.data;
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

  //全选相关函数
  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedBoxIds.clear();
        _selectedBoxIds = _searchResult.map((item) {
          int id = item["box_id"];
          return id;
        }).toList();
        _isAllSelected = false;
      } else {
        _selectedBoxIds.clear();
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
          'box_id': null,
          'capacity': null,
          'box_name': null,
          'box_level': null,
          'box_type': null,
          'image_url': null,
          'notes': null,
          'box_price': null,
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
                          labelText: '箱子ID',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newBox?['box_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '容量',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newBox?['capacity'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '箱子名称',
                        ),
                        onChanged: (value) {
                          newBox?['box_name'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '箱子等级',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          newBox?['box_level'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '箱子类型',
                        ),
                        onChanged: (value) {
                          newBox?['box_type'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '封面URL',
                        ),
                        onChanged: (value) {
                          newBox?['image_url'] = value.toString();
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
                          labelText: '价格',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          newBox?['box_price'] = double.tryParse(value);
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
                  await _dio.post(_addBoxUrl, options: options, data: newBox);
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
      await _dio.delete(_deleteBoxUrl, options: options, data: {
        "box_id": _selectedBoxIds,
      });
      fetchData();
    } catch (error) {
      print('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _deleteBoxes() {
    if (_selectedBoxIds.isEmpty) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('确定删除所选箱子吗？'),
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

  void _editBox(boxData) async {
    Map<String, dynamic> editedBox = {
      'box_id': boxData['box_id'],
      'capacity': boxData['capacity'],
      'box_name': boxData['box_name'],
      'box_level': boxData['box_level'],
      'box_type': boxData['box_type'],
      'image_url': boxData['image_url'],
      'notes': boxData['notes'],
      'box_price': boxData['box_price'],
    };
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
                      labelText: '箱子ID',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: boxData['box_id'].toString()),
                    enabled: false,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '容量',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: boxData['capacity'].toString()),
                    onChanged: (value) {
                      editedBox['capacity'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '箱子名称',
                    ),
                    controller:
                        TextEditingController(text: boxData['box_name']),
                    onChanged: (value) {
                      editedBox['box_name'] = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '箱子等级',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: boxData['box_level'].toString()),
                    onChanged: (value) {
                      editedBox['box_level'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '箱子类型',
                    ),
                    controller:
                        TextEditingController(text: boxData['box_type']),
                    onChanged: (value) {
                      editedBox['box_type'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '封面URL',
                    ),
                    controller:
                        TextEditingController(text: boxData['image_url']),
                    onChanged: (value) {
                      editedBox['image_url'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '备注',
                    ),
                    controller: TextEditingController(text: boxData['notes']),
                    onChanged: (value) {
                      editedBox['notes'] = value;
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '价格',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(
                        text: boxData['box_price'].toString()),
                    onChanged: (value) {
                      editedBox['box_price'] = double.tryParse(value);
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
                  await _dio.post(_editBoxUrl,
                      options: options, data: editedBox);
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
                      '箱子ID',
                      '箱子名称',
                      '箱子类型',
                    ].map<DropdownMenuItem<String>>((String value) {
                      late String key;
                      switch (value) {
                        case '箱子ID':
                          key = 'box_id';
                          break;
                        case '箱子名称':
                          key = 'box_name';
                          break;
                        case '箱子类型':
                          key = 'box_type';
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
                                  columns: _columns,
                                  rows: List<DataRow>.generate(
                                      _currentPageData.length, (index) {
                                    final item = _currentPageData[index];
                                    return DataRow(cells: [
                                      DataCell(
                                        Checkbox(
                                            value: _selectedBoxIds
                                                .contains(item['box_id']),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                int? id = item['box_id'];
                                                if (value!) {
                                                  _selectedBoxIds.add(id!);
                                                } else {
                                                  _selectedBoxIds.remove(id);
                                                }
                                              });
                                            }),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            item['box_id'].toString(),
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            item['capacity'].toString(),
                                            style:
                                                const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            item['box_name'],
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
                                            item['box_level'],
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
                                            item['box_type'],
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      const DataCell(
                                        SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Image(
                                            image: AssetImage(
                                                'assets/wuxianshang.jpg'),
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
                                            item['box_price'].toString(),
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
                                              widget.toDetail!(item['box_id']);
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
                                              widget.toDisplay!(item['box_id']);
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
                                              _editBox(item);
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
                            onPrevPage: _prevPage)
                      ],
                    )),
              ),
            ],
          );
  }
}
