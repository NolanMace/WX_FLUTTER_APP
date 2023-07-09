import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ImagePicker extends StatefulWidget {
  final Function callback;
  const ImagePicker({super.key, required this.callback});

  @override
  State<ImagePicker> createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePicker> {
  final _uploadFileUrl = AppConfig.uploadImage;
  bool _showImage = false;
  String _imageUrl = '';
  //图片本地地址
  String _filePath = '';
  void _selectFile(callback) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      if (kIsWeb) {
        _uploadFileWeb(callback, result);
      } else {
        setState(() {
          _filePath = result.files.single.path!;
        });
        _uploadFile(callback);
      }
    }
  }

  void _uploadFileWeb(callback, result) async {
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final options = Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      Uint8List fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;
      MultipartFile file =
          MultipartFile.fromBytes(fileBytes, filename: fileName);

      FormData formData = FormData.fromMap({
        'file': file,
      });

      try {
        Response response =
            await Dio().post(_uploadFileUrl, data: formData, options: options);
        debugPrint('Response: ${response.data}');
        String fileUrl = response.data['file_url'].toString();
        callback(fileUrl);
        setState(() {
          _showImage = true;
          _imageUrl = fileUrl;
        });
      } catch (error) {
        debugPrint('Error: $error');
      }
    } else {
      debugPrint('Please select a file first.');
    }
  }

  void _uploadFile(callback) async {
    if (_filePath.isNotEmpty) {
      Dio dio = Dio();

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
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_filePath),
        });

        Response response =
            await dio.post(_uploadFileUrl, data: formData, options: options);
        debugPrint('Response: ${response.data}');
        String fileUrl = response.data['file_url'].toString();
        callback(fileUrl);
        setState(() {
          _showImage = true;
          _imageUrl = fileUrl;
        });
      } catch (error) {
        debugPrint('Error: $error');
      }
    } else {
      debugPrint('Please select a file first.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _selectFile(widget.callback),
              child: const Text('Select File'),
            ),
          ),
          Expanded(
              child: _showImage
                  ? Image.network(_imageUrl)
                  : const Text('No Image',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18)))
        ],
      ),
    );
  }
}
