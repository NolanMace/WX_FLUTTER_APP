import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'pagination_control.dart';

class BoxLotteryRecordPane extends StatefulWidget {
  const BoxLotteryRecordPane({super.key});

  @override
  State<BoxLotteryRecordPane> createState() => _BoxLotteryRecordPaneState();
}

class _BoxLotteryRecordPaneState extends State<BoxLotteryRecordPane> {
  final Dio _dio = Dio();

  //网络请求相关参数
  final String _getBoxLotteryRecordAdmin = AppConfig.getBoxLotteryRecordAdmin;
  late List<dynamic> _boxLotteryRecordsList;

  //表格相关参数
  late List<DataColumn> _columns;
  late List<int> _selectedItemIds;
  late List<dynamic> _currentPageData;

  //分页相关参数
  final int _pageSize = 20;
  late int _currentPage;
  late List<dynamic> _searchResult;
  late List<dynamic> _appIdResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  //判断是否全选
  bool _isAllSelected = false;

  //输入框控制器
  final _searchController = TextEditingController();
  final _appIdController = TextEditingController();

  //下拉默认
  String _dropdownValue = 'nickname';

  //请求数据
  void fetchData() async {
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
          await _dio.get(_getBoxLotteryRecordAdmin, options: options);
      print(response.data);
      if (response.data == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _selectedItemIds.clear();
        _isAllSelected = false;
        _currentPage = 0;
        _boxLotteryRecordsList = response.data;
        _searchResult = _boxLotteryRecordsList;
        _currentPageData = _searchResult
            .skip(_currentPage * _pageSize)
            .take(_pageSize)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  //全选
  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.clear();
        _selectedItemIds = _searchResult.map((item) {
          int id = item["record_id"];
          return id;
        }).toList();
        _isAllSelected = false;
      } else {
        _selectedItemIds.clear();
        _isAllSelected = true;
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
        _appIdResult = _boxLotteryRecordsList.where((element) {
          return element["app_id"] == _appIdController.text.trim();
        }).toList();
        _searchResult = _appIdResult;
        _loadData();
      });
    }
  }

  //增删查改相关函数
  void _searchItems() {
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
    _boxLotteryRecordsList = [];
    _currentPageData = [];
    _selectedItemIds = [];
    _searchResult = [];
    _appIdResult = [];
    _currentPage = 0;
    _columns = [
      DataColumn(
          label: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("全选", style: TextStyle(fontSize: 12)),
          SizedBox(
              width: 40,
              child: Checkbox(
                  value: _isAllSelected,
                  onChanged: (value) => _selectAll(_isAllSelected)))
        ],
      )),
      const DataColumn(
        label: SizedBox(
          width: 50,
          child: Text("ID", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 50,
          child: Text("用户ID", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("用户头像", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 80,
          child: Text("用户昵称", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 50,
          child: Text("APPID", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("箱子ID", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 80,
          child: Text("箱子名称", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("箱子编号", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("商品ID", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 90,
          child: Text("商品名称", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("商品等级", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("商品图片", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("支付方式", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 50,
          child: Text("金额", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 50,
          child: Text("备注", style: TextStyle(fontSize: 12)),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 60,
          child: Text("抽取时间", style: TextStyle(fontSize: 12)),
        ),
      ),
    ];
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
                                        '箱子ID',
                                        '箱子名称',
                                        '商品ID',
                                        '商品名称',
                                        '商品等级',
                                        '箱子编号',
                                        '用户ID',
                                        '用户昵称',
                                        '支付方式',
                                      ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                        late String key;
                                        switch (value) {
                                          case '箱子ID':
                                            key = 'box_id';
                                            break;
                                        }
                                        switch (value) {
                                          case '箱子名称':
                                            key = 'box_name';
                                            break;
                                        }
                                        switch (value) {
                                          case '商品ID':
                                            key = 'product_id';
                                            break;
                                        }
                                        switch (value) {
                                          case '商品名称':
                                            key = 'product_name';
                                            break;
                                        }
                                        switch (value) {
                                          case '商品等级':
                                            key = 'product_level';
                                            break;
                                        }
                                        switch (value) {
                                          case '箱子编号':
                                            key = 'box_number';
                                            break;
                                        }
                                        switch (value) {
                                          case '用户ID':
                                            key = 'user_id';
                                            break;
                                        }
                                        switch (value) {
                                          case '用户昵称':
                                            key = 'nickname';
                                            break;
                                        }
                                        switch (value) {
                                          case '支付方式':
                                            key = 'payment_method';
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
                                        onPressed: _searchItems,
                                        child: const Text('查找'),
                                      ),
                                    ),
                                  ]),
                              DataTable(
                                  dataTextStyle: const TextStyle(fontSize: 12),
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 90,
                                  columnSpacing: 2,
                                  columns: _columns,
                                  rows: List<DataRow>.generate(
                                      _currentPageData.length, (index) {
                                    return DataRow(cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 40,
                                          child: Checkbox(
                                              value: _selectedItemIds.contains(
                                                  _currentPageData[index]
                                                      ['record_id']),
                                              onChanged: (value) {
                                                setState(() {
                                                  if (value!) {
                                                    _selectedItemIds.add(
                                                        _currentPageData[index]
                                                            ['record_id']);
                                                  } else {
                                                    _selectedItemIds.remove(
                                                        _currentPageData[index]
                                                            ['record_id']);
                                                  }
                                                });
                                              }),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            _currentPageData[index]['record_id']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]['user_id']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      const DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Image(
                                            image: AssetImage(
                                                'assets/wuxianshang.jpg'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            _currentPageData[index]['nickname'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            _currentPageData[index]['app_id']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]['box_id']
                                                .toString(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            _currentPageData[index]['box_name'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]
                                                    ['box_number']
                                                .toString(),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]
                                                    ['product_id']
                                                .toString(),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 90,
                                          child: Text(
                                            _currentPageData[index]
                                                ['product_name'],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            _currentPageData[index]
                                                ['product_level'],
                                          ),
                                        ),
                                      ),
                                      const DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Image(
                                            image: AssetImage(
                                                'assets/wuxianshang.jpg'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]
                                                ['payment_method'],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]['amount']
                                                .toString(),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                minWidth: 60, maxWidth: 200),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: Text(
                                                _currentPageData[index]
                                                    ['notes'],
                                              ),
                                            )),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            _currentPageData[index]
                                                ['created_at'],
                                          ),
                                        ),
                                      ),
                                    ]);
                                  })),
                              PaginationControl(
                                currentPage: _currentPage,
                                totalItems: _searchResult.length,
                                pageSize: _pageSize,
                                onNextPage: _nextPage,
                                onPrevPage: _prevPage,
                                onJumpPage: _jumpToPage,
                              )
                            ])))));
  }
}
