import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mis/after_login_pane.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Dio _dio = Dio();
  final _loginUrl = AppConfig.loginUrl;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> saveDataToCache(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _dio.post(_loginUrl, data: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        });

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          String data = response.data.toString();
          data = data.replaceAllMapped(
              RegExp(r'(\w+)\s*:\s*([^,}\]]+)'),
              (match) =>
                  '"${match[1]}":"${match[2]?.replaceAll(RegExp(r"'"), "\'")}"');
          Map<String, dynamic> jsonData = json.decode(data);
          String token = jsonData['token'];
          //根据返回数据进行身份验证和页面跳转
          await saveDataToCache('token', token);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AfterLogin()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('登录失败，请检查用户名或密码')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请求失败，请稍后重试')),
        );
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: '用户名'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: '密码'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text('登录'),
                        ),
                ],
              ),
            ),
          )),
    );
  }
}
