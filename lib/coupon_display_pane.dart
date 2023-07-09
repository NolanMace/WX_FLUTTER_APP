import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'pagination_control.dart';

class CouponDisplay extends StatefulWidget {
  const CouponDisplay({super.key});

  @override
  State<CouponDisplay> createState() => _CouponDisplayState();
}

class _CouponDisplayState extends State<CouponDisplay> {
  final Dio _dio = Dio();
  final String _getCouponDisplays = AppConfig.getCouponDisplays;
  final String _deleteCouponDisplays = AppConfig.deleteCouponDisplays;

  late List<dynamic> _items;
  //表格相关参数
  late List<DataColumn> _columns;
  late List<int> _selectedItemIds;
  late List<dynamic> _currentPageData;

  //分页相关参数
  final int _pageSize = 15;
  late int _currentPage = 0;
  late List<dynamic> _searchResult;
  late List<dynamic> _appIdResult;

  //判断是否正在加载数据
  bool _isLoading = true;

  bool _isAllSelected = false;

  //输入框控制器
  final _searchController = TextEditingController();
  final _appIdController = TextEditingController();

  String _dropdownValue = 'coupon_template_id';

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
      final res = await _dio.get(
        _getCouponDisplays,
        options: options,
      );
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
      debugPrint(e.toString());
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

  void _searchAppId() {
    String keyword = _appIdController.text.trim();
    if (keyword.isEmpty) {
      fetchData();
      return;
    }
    setState(() {
      _selectedItemIds.clear();
      _appIdResult = _items.where((item) {
        String value = item["app_id"].toString();
        return value == keyword;
      }).toList();
      _searchResult = _appIdResult;
      _loadData();
    });
  }

  void _searchItems() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
      return;
    }
    if (_appIdResult.isEmpty) {
      setState(() {
        _selectedItemIds.clear();
        _searchResult = _items.where((item) {
          String value = item[_dropdownValue].toString();
          return value == keyword;
        }).toList();
        _loadData();
      });
      return;
    }
    setState(() {
      _selectedItemIds.clear();
      _searchResult = _appIdResult.where((item) {
        String value = item[_dropdownValue].toString();
        return value == keyword;
      }).toList();
      _loadData();
    });
  }

  void _deleteRequest() async {
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
      await _dio.delete(
        _deleteCouponDisplays,
        options: options,
        data: {
          'auto_ids': _selectedItemIds,
        },
      );
      fetchData();
    } catch (e) {
      debugPrint(e.toString());
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
          content: const Text('确定删除所选弹窗吗？'),
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
                _deleteRequest();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
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
        width: 30,
        child: Text("ID"),
      )),
      const DataColumn(
        label: SizedBox(
          width: 130,
          child: Text("couponTemplateId"),
        ),
      ),
      const DataColumn(
          label: SizedBox(
        width: 100,
        child: Text("couponId"),
      )),
      const DataColumn(
          label: SizedBox(
        width: 60,
        child: Text("appId"),
      )),
      const DataColumn(
          label: SizedBox(
        width: 150,
        child: Text("createdAt"),
      )),
      const DataColumn(
          label: SizedBox(
        width: 150,
        child: Text("updatedAt"),
      )),
    ];
    _currentPageData = [];
    _selectedItemIds = [];
    _searchResult = [];
    _appIdResult = [];
    _currentPage = 0;
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
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: TextField(
                                        controller: _appIdController,
                                        decoration: const InputDecoration(
                                          hintText: '请输入appId',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: ElevatedButton(
                                        onPressed: _searchAppId,
                                        child: const Text('搜索'),
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
                                        'coupon_template_id',
                                        'coupon_id',
                                      ].map<DropdownMenuItem<String>>(
                                          (String value) {
                                        late String key;
                                        switch (value) {
                                          case 'coupon_template_id':
                                            key = 'coupon_template_id';
                                            break;
                                          case 'coupon_id':
                                            key = 'coupon_id';
                                            break;
                                        }
                                        return DropdownMenuItem<String>(
                                          value: key,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ),
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
                                        onPressed: _deleteItems,
                                        child: const Text('删除'),
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
                                      _currentPageData.length,
                                      (index) => DataRow(cells: [
                                            DataCell(
                                              Checkbox(
                                                  value: _selectedItemIds
                                                      .contains(
                                                          _currentPageData[
                                                                  index]
                                                              ['auto_id']),
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      int? id =
                                                          _currentPageData[
                                                              index]['auto_id'];
                                                      if (value!) {
                                                        _selectedItemIds
                                                            .add(id!);
                                                      } else {
                                                        _selectedItemIds
                                                            .remove(id);
                                                      }
                                                    });
                                                  }),
                                            ),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['auto_id']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['coupon_template_id']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['coupon_id']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['app_id']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['created_at']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['updated_at']
                                                    .toString())),
                                          ]))),
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
