import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'PaginationControl.dart';

class UserDataPane extends StatefulWidget {
  UserDataPane({
    Key? key,
  }) : super(key: key);

  @override
  _UserDataPaneState createState() => _UserDataPaneState();
}

class _UserDataPaneState extends State<UserDataPane> {
  final String _getUsersUrl = 'http://localhost:8080/api/GetAllUsers';
  final Dio _dio = Dio();
  late List<Map<String, dynamic>> _users;
  bool _isLoading = true;
  late String responseBody;
  late int _pageSize;
  late int _currentPage = 0;
  late List<dynamic> _currentPageData;
  //输入框控制器
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _searchResult;
  late String _dropdownValue = "id";
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
      Response response = await _dio.get(_getUsersUrl);
      print('Response body: ${response.data}');
      responseBody = response.data.toString();

      // 将数据格式转换为JSON格式
      responseBody = responseBody.replaceAllMapped(
          RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
          (match) =>
              '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
      print('JSON response body: ${responseBody}');

      List<dynamic> responseList = jsonDecode(responseBody);
      List<Map<String, dynamic>> users =
          responseList.map<Map<String, dynamic>>((item) {
        return {
          "id": item["user_id"].toString(),
          "unionid": item["unionid"] ?? "",
          "openid": item["openid"] ?? "",
          "avatarUrl": item["avatar_url"] ?? "assets/touxiang.jpg",
          "nickname": item["nickname"] ?? "",
          "created_at": item["created_at"]
                  .replaceAll("T", " ")
                  .replaceAll("+08:00", " ") ??
              "",
          "updated_at": item["updated_at"]
                  .replaceAll("T", " ")
                  .replaceAll("+08:00", " ") ??
              "",
        };
      }).toList();

      setState(() {
        _users = users;
        _pageSize = 1;
        _searchResult = _users;
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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  final List<DataColumn> _columns = [
    const DataColumn(
      label: Text(
        '用户ID',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '头像',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '昵称',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        'UNIONID',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        'OPENID',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '创建时间',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '更新时间',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
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

  void _searchUser() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _searchResult = _users.where((user) {
          return user[_dropdownValue].toString().contains(keyword);
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  items: <String>['id', 'unionid', 'openid', 'nickname']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: ElevatedButton(
                    onPressed: _searchUser,
                    child: const Text('查找'),
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
                    child: Column(children: [
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
                                      DataCell(Text(_currentPageData[index]
                                              ["id"]
                                          .toString())),
                                      const DataCell(Image(
                                        image:
                                            AssetImage("assets/touxiang.jpg"),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )),
                                      DataCell(Text(_currentPageData[index]
                                              ["nickname"]
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ["unionid"]
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ["openid"]
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ["created_at"]
                                          .toString())),
                                      DataCell(Text(_currentPageData[index]
                                              ["updated_at"]
                                          .toString())),
                                    ],
                                  ),
                                ),
                              ))),
                      PaginationControl(
                          currentPage: _currentPage,
                          totalItems: _searchResult.length,
                          pageSize: _pageSize,
                          onNextPage: _nextPage,
                          onPrevPage: _prevPage)
                    ])))
          ]);
  }
}
