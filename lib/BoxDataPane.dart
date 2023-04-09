import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'PaginationControl.dart';

class BoxDataPane extends StatefulWidget {
  BoxDataPane({
    Key? key,
  }) : super(key: key);

  @override
  _BoxDataPaneState createState() => _BoxDataPaneState();
}

class _BoxDataPaneState extends State<BoxDataPane> {
  final Dio _dio = Dio();
  final _getAllBoxesUrl = 'http://192.168.1.113:8080/api/GetAllBoxes';
  final _deleteBoxUrl = 'http://192.168.1.113:8080/api/DeleteBoxes';
  final _addBoxUrl = 'http://192.168.1.113:8080/api/CreateBox';
  final _editBoxUrl = 'http://192.168.1.113:8080/api/UpdateBox';
  late List<int> _selectedBoxIds;
  late List<Map<String, dynamic>> _boxes;
  bool _isLoading = true;
  late String _responseBody;
  late int _pageSize;
  late int _currentPage = 0;
  late List<dynamic> _currentPageData;
  //输入框控制器
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _searchResult;
  late String _dropdownValue = "box_id";
  //销毁控制器
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    _dio.interceptors
        .add(LogInterceptor(responseBody: true, requestBody: true));
    try {
      Response response = await _dio.get(_getAllBoxesUrl);
      print('Response body: ${response.data}');
      _responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      _responseBody = _responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
      print('JSON response body: ${_responseBody}');

      List<dynamic> responseList = jsonDecode(_responseBody);
      List<Map<String, dynamic>> boxes =
          responseList.map<Map<String, dynamic>>((item) {
        return {
          "box_id": item["box_id"],
          "capacity": item["capacity"] ?? "",
          "box_name": item["box_name"] ?? "",
          "box_level": item["box_level"] ?? "",
          "box_type": item["box_type"] ?? "",
          "image_url": item["image_url"] ?? "assets/touxiang.jpg",
          "notes": item["notes"] ?? "",
          "box_price": item["box_price"] ?? "",
          "created_at": item["created_at"] ?? "",
          "updated_at": item["updated_at"] ?? "",
        };
      }).toList();

      setState(() {
        _selectedBoxIds.clear();
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

  Future<void> _deleteData() async {
    try {
      Response response = await _dio.delete(_deleteBoxUrl, data: {
        "box_id": _selectedBoxIds,
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

  @override
  void initState() {
    super.initState();
    _selectedBoxIds = [];
    fetchData();
  }

  final List<DataColumn> _columns = [
    const DataColumn(
      label: Text(
        '选择',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '箱子ID',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '容量',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '箱子名称',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '箱子等级',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '箱子类型',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '封面URL',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '价格',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '备注',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
        label: Text('编辑', style: TextStyle(fontStyle: FontStyle.italic)))
  ];

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
          title: Text('添加箱子'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子ID',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newBox?['box_id'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '容量',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newBox?['capacity'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子名称',
                    ),
                    onChanged: (value) {
                      newBox?['box_name'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子等级',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newBox?['box_level'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子类型',
                    ),
                    onChanged: (value) {
                      newBox?['box_type'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '封面URL',
                    ),
                    onChanged: (value) {
                      newBox?['image_url'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '备注',
                    ),
                    onChanged: (value) {
                      newBox?['notes'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '价格',
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      newBox?['box_price'] = double.tryParse(value);
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
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final response = await _dio.post(_addBoxUrl, data: newBox);
                  print('Request body2222222: ${newBox}');
                  Navigator.of(context).pop();
                  fetchData();
                } catch (error) {
                  print('Error: $error');
                }
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
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

  void _editBox(Map<String, dynamic> boxData) async {
    Map<String, dynamic> editedBox = Map<String, dynamic>.from(boxData);
    editedBox['box_id'] = int.tryParse(editedBox['box_id'].toString());
    editedBox['capacity'] = int.tryParse(editedBox['capacity'].toString());
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑箱子信息'),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子ID',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: boxData['box_id'].toString()),
                    onChanged: (value) {
                      print('Box ID onChanged: $value');
                      editedBox['box_id'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
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
                    decoration: InputDecoration(
                      labelText: '箱子名称',
                    ),
                    controller:
                        TextEditingController(text: boxData['box_name']),
                    onChanged: (value) {
                      editedBox['box_name'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
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
                    decoration: InputDecoration(
                      labelText: '箱子类型',
                    ),
                    controller:
                        TextEditingController(text: boxData['box_type']),
                    onChanged: (value) {
                      editedBox['box_type'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '封面URL',
                    ),
                    controller:
                        TextEditingController(text: boxData['image_url']),
                    onChanged: (value) {
                      editedBox['image_url'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '备注',
                    ),
                    controller: TextEditingController(text: boxData['notes']),
                    onChanged: (value) {
                      editedBox['notes'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '价格',
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    controller:
                        TextEditingController(text: boxData['box_price']),
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
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final response =
                      await _dio.post(_editBoxUrl, data: editedBox);
                  Navigator.of(context).pop();
                  fetchData();
                } catch (error) {
                  print('Error: $error');
                }
              },
              child: Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
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
              const SizedBox(height: 10),
              Divider(),
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
                              child: DataTable(
                                columns: _columns,
                                rows: List<DataRow>.generate(
                                  _currentPageData.length,
                                  (int index) => DataRow(
                                    cells: <DataCell>[
                                      DataCell(
                                        Checkbox(
                                          value: _selectedBoxIds.contains(
                                              int.parse(_currentPageData[index]
                                                  ['box_id'])),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value != null && value) {
                                                _selectedBoxIds.add(int.parse(
                                                    _currentPageData[index]
                                                        ['box_id']));
                                              } else {
                                                _selectedBoxIds.remove(
                                                    int.parse(
                                                        _currentPageData[index]
                                                            ['box_id']));
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(Text(
                                          _currentPageData[index]['box_id'])),
                                      DataCell(Text(
                                          _currentPageData[index]['capacity'])),
                                      DataCell(Text(_currentPageData[index]
                                              ['box_name']
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ['box_level']
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ['box_type']
                                          .toString())),
                                      const DataCell(Image(
                                        image: AssetImage(
                                            'assets/wuxianshang.jpg'),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )),
                                      DataCell(Text(_currentPageData[index]
                                              ['box_price']
                                          .toString())),
                                      DataCell(
                                        SizedBox(
                                          width: 100,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            child: Text(
                                              _currentPageData[index]['notes']
                                                  .toString(),
                                              softWrap: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () =>
                                              _editBox(_currentPageData[index]),
                                          child: Text('Edit'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
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
