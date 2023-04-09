import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'PaginationControl.dart';

class ProductDataPane extends StatefulWidget {
  ProductDataPane({
    Key? key,
  }) : super(key: key);

  @override
  _ProductDataPaneState createState() => _ProductDataPaneState();
}

class _ProductDataPaneState extends State<ProductDataPane> {
  final Dio _dio = Dio();
  final _getAllProductsUrl = 'http://192.168.1.113:8080/api/GetAllProductes';
  final _deleteProductUrl = 'http://192.168.1.113:8080/api/DeleteProductes';
  final _addProductUrl = 'http://192.168.1.113:8080/api/CreateProduct';
  final _editProductUrl = 'http://192.168.1.113:8080/api/UpdateProduct';
  late List<int> _selectedProductIds;
  late List<Map<String, dynamic>> _Productes;
  bool _isLoading = true;
  late String _responseBody;
  late int _pageSize;
  late int _currentPage = 0;
  late List<dynamic> _currentPageData;
  //输入框控制器
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _searchResult;
  late String _dropdownValue = "Product_id";
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
      Response response = await _dio.get(_getAllProductsUrl);
      print('Response body: ${response.data}');
      _responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      _responseBody = _responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
      print('JSON response body: ${_responseBody}');

      List<dynamic> responseList = jsonDecode(_responseBody);
      List<Map<String, dynamic>> Productes =
          responseList.map<Map<String, dynamic>>((item) {
        return {
          "Product_id": item["Product_id"],
          "capacity": item["capacity"] ?? "",
          "Product_name": item["Product_name"] ?? "",
          "Product_level": item["Product_level"] ?? "",
          "Product_type": item["Product_type"] ?? "",
          "image_url": item["image_url"] ?? "assets/touxiang.jpg",
          "notes": item["notes"] ?? "",
          "Product_price": item["Product_price"] ?? "",
          "created_at": item["created_at"] ?? "",
          "updated_at": item["updated_at"] ?? "",
        };
      }).toList();

      setState(() {
        _selectedProductIds.clear();
        _Productes = Productes;
        _pageSize = 20;
        _searchResult = _Productes;
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
      Response response = await _dio.delete(_deleteProductUrl, data: {
        "Product_id": _selectedProductIds,
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
    _selectedProductIds = [];
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

  void _searchProductes() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _searchResult = _Productes.where((user) {
          return user[_dropdownValue].toString().contains(keyword);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  void _addProduct() async {
    Map<String, dynamic>? newProduct;
    await showDialog(
      context: context,
      builder: (context) {
        newProduct = {
          'Product_id': null,
          'capacity': null,
          'Product_name': null,
          'Product_level': null,
          'Product_type': null,
          'image_url': null,
          'notes': null,
          'Product_price': null,
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
                      newProduct?['Product_id'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '容量',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newProduct?['capacity'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子名称',
                    ),
                    onChanged: (value) {
                      newProduct?['Product_name'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子等级',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      newProduct?['Product_level'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子类型',
                    ),
                    onChanged: (value) {
                      newProduct?['Product_type'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '封面URL',
                    ),
                    onChanged: (value) {
                      newProduct?['image_url'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '备注',
                    ),
                    onChanged: (value) {
                      newProduct?['notes'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '价格',
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      newProduct?['Product_price'] = double.tryParse(value);
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
                      await _dio.post(_addProductUrl, data: newProduct);
                  print('Request body2222222: ${newProduct}');
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

  void _deleteProductes() {
    if (_selectedProductIds.isEmpty) {
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

  void _editProduct(Map<String, dynamic> ProductData) async {
    Map<String, dynamic> editedProduct = Map<String, dynamic>.from(ProductData);
    editedProduct['Product_id'] =
        int.tryParse(editedProduct['Product_id'].toString());
    editedProduct['capacity'] =
        int.tryParse(editedProduct['capacity'].toString());
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
                        text: ProductData['Product_id'].toString()),
                    onChanged: (value) {
                      print('Product ID onChanged: $value');
                      editedProduct['Product_id'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '容量',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: ProductData['capacity'].toString()),
                    onChanged: (value) {
                      editedProduct['capacity'] = int.tryParse(value);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子名称',
                    ),
                    controller: TextEditingController(
                        text: ProductData['Product_name']),
                    onChanged: (value) {
                      editedProduct['Product_name'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子等级',
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: ProductData['Product_level'].toString()),
                    onChanged: (value) {
                      editedProduct['Product_level'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '箱子类型',
                    ),
                    controller: TextEditingController(
                        text: ProductData['Product_type']),
                    onChanged: (value) {
                      editedProduct['Product_type'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '封面URL',
                    ),
                    controller:
                        TextEditingController(text: ProductData['image_url']),
                    onChanged: (value) {
                      editedProduct['image_url'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '备注',
                    ),
                    controller:
                        TextEditingController(text: ProductData['notes']),
                    onChanged: (value) {
                      editedProduct['notes'] = value.toString();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '价格',
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    controller: TextEditingController(
                        text: ProductData['Product_price']),
                    onChanged: (value) {
                      editedProduct['Product_price'] = double.tryParse(value);
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
                      await _dio.post(_editProductUrl, data: editedProduct);
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
                          key = 'Product_id';
                          break;
                        case '箱子名称':
                          key = 'Product_name';
                          break;
                        case '箱子类型':
                          key = 'Product_type';
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
                      onPressed: _searchProductes,
                      child: const Text('查找'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _deleteProductes,
                      child: const Text('删除'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _addProduct,
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
                                          value: _selectedProductIds.contains(
                                              int.parse(_currentPageData[index]
                                                  ['Product_id'])),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value != null && value) {
                                                _selectedProductIds.add(
                                                    int.parse(
                                                        _currentPageData[index]
                                                            ['Product_id']));
                                              } else {
                                                _selectedProductIds.remove(
                                                    int.parse(
                                                        _currentPageData[index]
                                                            ['Product_id']));
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      DataCell(Text(_currentPageData[index]
                                          ['Product_id'])),
                                      DataCell(Text(
                                          _currentPageData[index]['capacity'])),
                                      DataCell(Text(_currentPageData[index]
                                              ['Product_name']
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ['Product_level']
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ['Product_type']
                                          .toString())),
                                      const DataCell(Image(
                                        image: AssetImage(
                                            'assets/wuxianshang.jpg'),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )),
                                      DataCell(Text(_currentPageData[index]
                                              ['Product_price']
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
                                          onPressed: () => _editProduct(
                                              _currentPageData[index]),
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
