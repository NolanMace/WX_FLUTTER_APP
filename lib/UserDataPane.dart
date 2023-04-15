import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mis/CustomDataTable.dart';
import 'package:mis/config.dart';
import 'PaginationControl.dart';

class UserDataPane extends StatefulWidget {
  UserDataPane({
    Key? key,
  }) : super(key: key);

  @override
  _UserDataPaneState createState() => _UserDataPaneState();
}

class _UserDataPaneState extends State<UserDataPane> {
  //数据请求地址
  final String _getUsersUrl = AppConfig.getAllUsersUrl;
  final String _editUserUrl = AppConfig.editUserUrl;
  final Dio _dio = Dio();
  late List<Map<String, dynamic>> _users;
  late String responseBody;

  //判断是否正在加载数据
  bool _isLoading = true;

  //分页控制
  final int _pageSize = 15;
  late int _currentPage = 0;
  late List<Map<String, dynamic>> _appIdResult;
  late List<Map<String, dynamic>> _searchResult;

  //表格参数
  final List<String> columnTitles = [
    "选择",
    "id",
    "avatarUrl",
    "nickname",
    "app_id",
    "手机号",
    "unionid",
    "openid",
    "eidt",
    "创建时间",
    "更新时间"
  ];
  final List<String> _attributes = [
    "select",
    "user_id",
    "avatarUrl",
    "nickname",
    "app_id",
    "phone",
    "unionid",
    "openid",
    "eidt",
    "created_at",
    "updated_at"
  ];
  final int _imageColumnIndex = 2;
  late List<DataColumn> _columns;
  late List<int> _selectedUserIds;
  late List<dynamic> _currentPageData;

  //输入框控制器
  final _searchController = TextEditingController();
  final _appIdController = TextEditingController();

  //下拉菜单默认选项
  late String _dropdownValue = "user_id";

  //销毁控制器
  @override
  void dispose() {
    _searchController.dispose();
    _appIdController.dispose();
    _dio.close();
    super.dispose();
  }

  //请求数据
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
          "user_id": item["user_id"],
          "app_id": item["app_id"] ?? "",
          "unionid": item["unionid"] ?? "",
          "openid": item["openid"] ?? "",
          "avatarUrl": item["avatar_url"] ?? "assets/touxiang.jpg",
          "nickname": item["nickname"] ?? "",
          "phone": item["phone"] ?? "",
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
        _selectedUserIds.clear();
        _users = users;
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

  //初始化函数
  @override
  void initState() {
    super.initState();
    _columns = columnTitles.map<DataColumn>((text) {
      return DataColumn(
        label: Text(
          text,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }).toList();
    _selectedUserIds = [];
    fetchData();
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

  //选择APPID
  void _selectAppId() {
    String keyword = _appIdController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _appIdResult = _users.where((element) {
          return element["app_id"] == _appIdController.text.trim();
        }).toList();
        _searchResult = _appIdResult;
        _loadData();
      });
    }
  }

  //搜索函数
  void _searchUser() {
    String keyword = _searchController.text.trim();
    _currentPage = 0;
    if (keyword.isEmpty) {
      fetchData();
    } else {
      setState(() {
        _searchResult = _appIdResult.where((user) {
          return user[_dropdownValue].toString() == keyword;
        }).toList(); // 根据关键字和选择的属性筛选用户
        _loadData();
      });
    }
  }

  //编辑函数
  void _editUser(Map<String, dynamic> userData) async {
    Map<String, dynamic> editedUser = Map<String, dynamic>.from(userData);
    editedUser['user_id'] = int.tryParse(editedUser['user_id'].toString());
    editedUser.remove("created_at");
    editedUser.remove("updated_at");
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑用户信息'),
          content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '用户ID',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: userData['user_id'].toString()),
                        onChanged: (value) {
                          editedUser['user_id'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'app_id',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: userData['app_id'].toString()),
                        onChanged: (value) {
                          editedUser['app_id'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '昵称',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: userData['nickname'].toString()),
                        onChanged: (value) {
                          editedUser['nickname'] = int.tryParse(value);
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'unionid',
                        ),
                        controller:
                            TextEditingController(text: userData['unionid']),
                        onChanged: (value) {
                          editedUser['unionid'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'openid',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: userData['openid'].toString()),
                        onChanged: (value) {
                          editedUser['openid'] = value.toString();
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: '手机号',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(
                            text: userData['phone'].toString()),
                        onChanged: (value) {
                          editedUser['phone'] = value.toString();
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
                  final response =
                      await _dio.post(_editUserUrl, data: editedUser);
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
                  items: <String>['user_id', 'unionid', 'openid', 'nickname']
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
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(children: [
                      SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: CustomDataTable(
                                  columns: _attributes,
                                  columnNames: _columns,
                                  selectedItemIds: _selectedUserIds,
                                  hasDetailButton: false,
                                  currentPageData: _currentPageData,
                                  imageColumnIndex: _imageColumnIndex,
                                  editData: _editUser))),
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
