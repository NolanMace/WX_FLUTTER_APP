import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class UserAgreementsPane extends StatefulWidget {
  const UserAgreementsPane({super.key});

  @override
  State<UserAgreementsPane> createState() => _UserAgreementsPaneState();
}

class _UserAgreementsPaneState extends State<UserAgreementsPane> {
  final QuillEditorController _controller = QuillEditorController();
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _addAppIdController = TextEditingController();
  final String _getUserAgreementByAppIdUrl = AppConfig.getUserAgreementByAppId;
  final String _updateUserAgreementUrl = AppConfig.updateUserAgreement;
  final String _createUserAgreementUrl = AppConfig.createUserAgreement;
  final String _deleteUserAgreementUrl = AppConfig.deleteUserAgreement;
  final GlobalKey<_QuillHtmlEditorContainerState> _quillHtmlEditorContainerKey =
      GlobalKey<_QuillHtmlEditorContainerState>();
  final Dio _dio = Dio();
  String _appId = '';
  int _autoId = 0;
  String _htmlText = '';
  final customToolBarList = [
    ToolBarStyle.bold,
    ToolBarStyle.italic,
    ToolBarStyle.align,
    ToolBarStyle.color,
  ];
  final customButtons = [
    InkWell(onTap: () {}, child: const Icon(Icons.favorite)),
    InkWell(onTap: () {}, child: const Icon(Icons.add_circle)),
  ];

  void _showQuillHtmlEditor() {
    final _QuillHtmlEditorContainerState? childState =
        _quillHtmlEditorContainerKey.currentState;
    childState?.showQuillHtmlEditor();
  }

  void _hideQuillHtmlEditor() async {
    String htmlText = await _getHtml();
    setState(() {
      _htmlText = htmlText;
    });
    final _QuillHtmlEditorContainerState? childState =
        _quillHtmlEditorContainerKey.currentState;
    childState?.hideQuillHtmlEditor();
  }

  Future<String> _getHtml() async {
    String? htmlText = await _controller.getText();
    if (htmlText.isEmpty) {
      return '';
    } else {
      return htmlText;
    }
  }

  void _postCreateUserAgreement(appId, showResult) async {
    Map<String, dynamic>? data = {
      'app_id': appId,
      'content': _htmlText,
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
      await _dio.post(_createUserAgreementUrl, data: data, options: options);
      showResult();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _clickAddUserAgreement() {
    _hideQuillHtmlEditor();
    showDialog(
        context: context,
        builder: (
          BuildContext context,
        ) {
          return AlertDialog(
            title: const Text('添加用户协议'),
            content: SizedBox(
              height: 150,
              child: Column(
                children: [
                  TextField(
                    controller: _addAppIdController,
                    decoration: const InputDecoration(
                      hintText: '输入APPID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _showQuillHtmlEditor();
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _postCreateUserAgreement(_addAppIdController.text, () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('添加成功'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showQuillHtmlEditor();
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        });
                  });
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
  }

  void _getUserAgreementByAppId() async {
    String appId = _appIdController.text;
    if (appId.isEmpty) {
      debugPrint('appId is empty');
      _resetUserAgreement();
      return;
    }
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
      Map<String, dynamic>? queryParameters = {
        'app_id': appId,
      };
      Response res = await _dio.get(_getUserAgreementByAppIdUrl,
          queryParameters: queryParameters, options: options);
      _controller.clear();
      _controller.setText(res.data['content']);
      setState(() {
        _appId = appId;
        _autoId = res.data['auto_id'];
      });
    } catch (e) {
      debugPrint(e.toString());
      _resetUserAgreement();
    }
  }

  void _postUpdateUserAgreement(showResult) async {
    Map<String, dynamic>? data = {
      'auto_id': _autoId,
      'app_id': _appId,
      'content': _htmlText,
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
      await _dio.post(_updateUserAgreementUrl, data: data, options: options);
      showResult();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _clickUpdateUserAgreement() {
    _hideQuillHtmlEditor();
    if (_appId.isEmpty || _autoId == 0) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('请先获取用户协议'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showQuillHtmlEditor();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          });
      return;
    }
    showDialog(
        context: context,
        builder: (
          BuildContext context,
        ) {
          return AlertDialog(
            title: const Text('更新用户协议'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showQuillHtmlEditor();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _postUpdateUserAgreement(() {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('更新成功'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showQuillHtmlEditor();
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        });
                  });
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
  }

  void _postDeleteUserAgreement(showResult) async {
    Map<String, dynamic>? data = {
      'auto_id': _autoId,
      'app_id': _appId,
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
      await _dio.delete(_deleteUserAgreementUrl, data: data, options: options);
      showResult();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _clickDeleteUserAgreement() {
    _hideQuillHtmlEditor();
    if (_appId.isEmpty || _autoId == 0) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('请先获取用户协议'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showQuillHtmlEditor();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          });
      return;
    }
    showDialog(
        context: context,
        builder: (
          BuildContext context,
        ) {
          return AlertDialog(
            title: const Text('删除用户协议'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showQuillHtmlEditor();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _postDeleteUserAgreement(() {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('删除成功'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showQuillHtmlEditor();
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          );
                        });
                  });
                  Navigator.pop(context);
                },
                child: const Text('确定'),
              ),
            ],
          );
        });
  }

  void _resetUserAgreement() {
    _controller.clear();
    setState(() {
      _appId = '';
      _autoId = 0;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: TextField(
                    controller: _appIdController,
                    decoration: const InputDecoration(
                      hintText: '输入APPID',
                      border: OutlineInputBorder(),
                    ),
                  )),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  _getUserAgreementByAppId();
                },
                child: const Text('获取'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ElevatedButton(
                onPressed: () {
                  _clickUpdateUserAgreement();
                },
                child: const Text('更新'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ElevatedButton(
                onPressed: () {
                  _clickAddUserAgreement();
                },
                child: const Text('添加'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ElevatedButton(
                onPressed: () {
                  _clickDeleteUserAgreement();
                },
                child: const Text('删除'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: ElevatedButton(
                onPressed: () {
                  _resetUserAgreement();
                },
                child: const Text('重置'),
              ),
            ),
          ],
        ),
        ToolBar(
            controller: _controller,
            toolBarConfig: customToolBarList,
            customButtons: customButtons),
        QuillHtmlEditorContainer(
          key: _quillHtmlEditorContainerKey,
          controller: _controller,
        ),
        SizedBox(
          width: 150,
          child: ElevatedButton(
            onPressed: () {
              _getHtml();
            },
            child: const Text('Get Text'),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _appIdController.dispose();
    _addAppIdController.dispose();
    _dio.close();
    super.dispose();
  }
}

class QuillHtmlEditorContainer extends StatefulWidget {
  final QuillEditorController controller;
  const QuillHtmlEditorContainer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<QuillHtmlEditorContainer> createState() =>
      _QuillHtmlEditorContainerState();
}

class _QuillHtmlEditorContainerState extends State<QuillHtmlEditorContainer> {
  bool hasShowedQuillHtmlEditor = true;
  void showQuillHtmlEditor() {
    setState(() {
      hasShowedQuillHtmlEditor = true;
    });
  }

  void hideQuillHtmlEditor() {
    setState(() {
      hasShowedQuillHtmlEditor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return hasShowedQuillHtmlEditor
        ? QuillHtmlEditor(
            text: "<h1>Hello</h1>This is a quill html editor example 😊",
            hintText: 'Hint text goes here',
            controller: widget.controller,
            isEnabled: true,
            minHeight: 300,
            hintTextAlign: TextAlign.start,
            padding: const EdgeInsets.only(left: 10, top: 5),
            hintTextPadding: EdgeInsets.zero,
            // onFocusChanged: (hasFocus) => debugPrint('has focus $hasFocus'),
            // onTextChanged: (text) => debugPrint('widget text change $text'),
            // onEditorCreated: () => debugPrint('Editor has been loaded'),
            // onEditorResized: (height) => debugPrint('Editor resized $height'),
            // onSelectionChanged: (sel) =>
            //     debugPrint('${sel.index},${sel.length}')
          )
        : Container();
  }
}
