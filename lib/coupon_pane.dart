import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'config.dart';
import 'custom_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pagination_control.dart';

class CouponPane extends StatefulWidget {
  const CouponPane({super.key});

  @override
  State<CouponPane> createState() => _CouponPaneState();
}

class _CouponPaneState extends State<CouponPane> {
  final Dio _dio = Dio();
  final String _getCoupons = AppConfig.getCoupons;
  final String _createCoupon = AppConfig.createCoupon;
  final String _updateCoupon = AppConfig.updateCoupon;
  final String _deleteCoupons = AppConfig.deleteCoupons;
  final String _createCouponTemplates = AppConfig.createCouponTemplates;
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

  String _dropdownValue = 'coupon_id';

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
      Response res = await _dio.get(_getCoupons, options: options);
      debugPrint(res.data.toString());
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
    }
  }

  void _selectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.clear();
        _selectedItemIds = _searchResult.map((item) {
          int id = item["coupon_id"];
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
          String value = item[_dropdownValue].toString();
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
      await _dio.delete(_deleteCoupons, options: options, data: {
        "coupons_ids": _selectedItemIds,
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
      await _dio.post(_createCoupon, options: options, data: newItem);
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
            "coupon_type": '',
            "description": '',
            "discount_type": '',
            "discount_value": 0,
            "minimum_order_amount": 0,
            "start_date": '',
            "end_date": '',
            "expired_day": 0,
            "usage_limit": 0,
            "is_active": false,
          };
          return AlertDialog(
            title: const Text('创建优惠券'),
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
                        labelText: 'coupon_type',
                      ),
                      onChanged: (value) {
                        newItem['coupon_type'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'description',
                      ),
                      onChanged: (value) {
                        newItem['description'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'discount_type',
                      ),
                      onChanged: (value) {
                        newItem['discount_type'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'discount_value',
                      ),
                      onChanged: (value) {
                        newItem['discount_value'] = double.tryParse(value);
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'minimum_order_amount',
                      ),
                      onChanged: (value) {
                        newItem['minimum_order_amount'] =
                            double.tryParse(value);
                      },
                    ),
                    CustomDatePicker(
                        initialDate: '2023-05-01',
                        onDateSelected: (value) {
                          newItem['start_date'] = value.toString();
                        }),
                    CustomDatePicker(
                        initialDate: '2023-05-02',
                        onDateSelected: (value) {
                          newItem['end_date'] = value.toString();
                        }),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'expired_day',
                      ),
                      onChanged: (value) {
                        newItem['expired_day'] = int.tryParse(value);
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'usage_limit',
                      ),
                      onChanged: (value) {
                        newItem['usage_limit'] = int.tryParse(value);
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'is_active',
                      ),
                      onChanged: (value) {
                        newItem['is_active'] = int.tryParse(value) == 1;
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
      await _dio.post(_updateCoupon, options: options, data: item);
      showResult();
      fetchData();
    } catch (error) {
      debugPrint('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _updateItem(item) {
    Map<String, dynamic> newItem = {
      "coupon_id": item['coupon_id'],
      "coupon_type": item['coupon_type'],
      "description": item['description'],
      "discount_type": item['discount_type'],
      "discount_value": item['discount_value'],
      "minimum_order_amount": item['minimum_order_amount'],
      "start_date": item['start_date'],
      "end_date": item['end_date'],
      "expired_day": item['expired_day'],
      "usage_limit": item['usage_limit'],
      "is_active": item['is_active'],
    };
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('创建优惠券'),
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
                      controller: TextEditingController(
                        text: item['coupon_id'].toString(),
                      ),
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'coupon_id',
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'coupon_type',
                      ),
                      controller: TextEditingController(
                        text: item['coupon_type'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['coupon_type'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'description',
                      ),
                      controller: TextEditingController(
                        text: item['description'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['description'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'discount_type',
                      ),
                      controller: TextEditingController(
                        text: item['discount_type'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['discount_type'] = value.toString();
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'discount_value',
                      ),
                      controller: TextEditingController(
                        text: item['discount_value'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['discount_value'] = double.tryParse(value);
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'minimum_order_amount',
                      ),
                      controller: TextEditingController(
                        text: item['minimum_order_amount'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['minimum_order_amount'] =
                            double.tryParse(value);
                      },
                    ),
                    CustomDatePicker(
                        initialDate: item['start_date'].toString(),
                        onDateSelected: (value) {
                          newItem['start_date'] = value.toString();
                        }),
                    CustomDatePicker(
                        initialDate: item['end_date'].toString(),
                        onDateSelected: (value) {
                          newItem['end_date'] = value.toString();
                        }),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'expired_day',
                      ),
                      controller: TextEditingController(
                        text: item['expired_day'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['expired_day'] = int.tryParse(value);
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'usage_limit',
                      ),
                      controller: TextEditingController(
                        text: item['usage_limit'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['usage_limit'] = int.tryParse(value);
                      },
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'is_active',
                      ),
                      controller: TextEditingController(
                        text: item['is_active'].toString(),
                      ),
                      onChanged: (value) {
                        newItem['is_active'] = int.tryParse(value) == 1;
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

  void _postPackRequest(selectedIds, templateId, showResult) async {
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
      Map<String, dynamic> data = {
        "coupon_ids": selectedIds,
        "coupon_template_id": templateId,
      };
      await _dio.post(_createCouponTemplates, options: options, data: data);
      showResult();
      fetchData();
    } catch (error) {
      debugPrint('Error: $error');
      setState(() {
        _isLoading = true;
      });
    }
  }

  void _packItems() {
    if (_selectedItemIds.isEmpty) {
      return;
    }
    List<int> selectedIds = _selectedItemIds;
    int? templateId;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('打包优惠券'),
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
                        labelText: 'template_id',
                      ),
                      controller: TextEditingController(
                        text: '',
                      ),
                      onChanged: (value) {
                        templateId = int.tryParse(value);
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
                  if (templateId == null) {
                    return;
                  }
                  _postPackRequest(
                    selectedIds,
                    templateId,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('打包成功'),
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
        width: 30,
        child: Text("ID"),
      )),
      const DataColumn(
          label: SizedBox(
        width: 120,
        child: Text("couponType"),
      )),
      const DataColumn(
        label: SizedBox(
          width: 90,
          child: Text("description"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("discountType"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("discountValue"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 180,
          child: Text("minimumOrderAmount"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("startDate"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("endDate"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("expiredDay"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("usageLimit"),
        ),
      ),
      const DataColumn(
        label: SizedBox(
          width: 120,
          child: Text("isActive"),
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
                                  DropdownButton<String>(
                                    value: _dropdownValue,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _dropdownValue = newValue!;
                                      });
                                    },
                                    items: <String>[
                                      'coupon_id',
                                      'discount_type',
                                      'coupon_type',
                                    ].map<DropdownMenuItem<String>>(
                                        (String value) {
                                      late String key;
                                      switch (value) {
                                        case 'coupon_id':
                                          key = 'coupon_id';
                                          break;
                                        case 'discount_type':
                                          key = 'discount_type';
                                          break;
                                        case 'coupon_type':
                                          key = 'coupon_type';
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
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 80,
                                    child: ElevatedButton(
                                      onPressed: _packItems,
                                      child: const Text('打包'),
                                    ),
                                  ),
                                ],
                              ),
                              DataTable(
                                  border: const TableBorder(
                                    verticalInside: BorderSide(
                                        width: 1, color: Colors.grey),
                                  ),
                                  dataTextStyle: const TextStyle(fontSize: 12),
                                  dataRowMinHeight: 50,
                                  dataRowMaxHeight: 90,
                                  columnSpacing: 0,
                                  columns: _columns,
                                  rows: List<DataRow>.generate(
                                      _currentPageData.length,
                                      (index) => DataRow(cells: [
                                            DataCell(
                                              Checkbox(
                                                  value:
                                                      _selectedItemIds.contains(
                                                          _currentPageData[
                                                                  index]
                                                              ['coupon_id']),
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      int? id =
                                                          _currentPageData[
                                                                  index]
                                                              ['coupon_id'];
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
                                                        ['coupon_id']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                    ['coupon_type'])),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                    ['description'])),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                    ['discount_type'])),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['discount_value']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['minimum_order_amount']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['start_date']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['end_date']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['expired_day']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['usage_limit']
                                                    .toString())),
                                            DataCell(Text(
                                                _currentPageData[index]
                                                        ['is_active']
                                                    .toString())),
                                            DataCell(SizedBox(
                                                width: 60,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    _updateItem(
                                                        _currentPageData[
                                                            index]);
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
                            ])))));
  }
}
