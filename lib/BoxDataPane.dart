import 'package:flutter/material.dart';

class BoxDataPane extends StatefulWidget {
  final List<Map<String, dynamic>> boxes = [
    {
      "id": "001",
      "capacity": "10",
      "quantity": "5",
      "title": "Box 1",
      "coverUrl": "assets/wuxianshang.jpg",
      "price": "20"
    },
    {
      "id": "002",
      "capacity": "20",
      "quantity": "10",
      "title": "Box 2",
      "coverUrl": "assets/wuxianshang.jpg",
      "price": "30"
    },
    {
      "id": "003",
      "capacity": "30",
      "quantity": "20",
      "title": "Box 3",
      "coverUrl": "assets/wuxianshang.jpg",
      "price": "40"
    },
  ];
  BoxDataPane({
    Key? key,
  }) : super(key: key);

  @override
  _BoxDataPaneState createState() => _BoxDataPaneState();
}

class _BoxDataPaneState extends State<BoxDataPane> {
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

  @override
  void initState() {
    super.initState();
    _searchResult = widget.boxes;
  }

  final List<DataColumn> _columns = [
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
        '剩余数量',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
    const DataColumn(
      label: Text(
        '标题',
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
        '封面URL',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    ),
  ];

  void _searchBox() {
    String keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searchResult = widget.boxes; // 如果搜索框为空，则显示所有箱子
      });
    } else {
      setState(() {
        _searchResult = widget.boxes.where((box) {
          return box[_dropdownValue].toString().contains(keyword);
        }).toList(); // 根据关键字和选择的属性筛选箱子
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                '箱子标题',
                '价格',
              ].map<DropdownMenuItem<String>>((String value) {
                late String key;
                switch (value) {
                  case '箱子ID':
                    key = 'id';
                    break;
                  case '箱子标题':
                    key = 'title';
                    break;
                  case '价格':
                    key = 'price';
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
                onPressed: _searchBox,
                child: const Text('查找'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: _columns,
            rows: List<DataRow>.generate(
              _searchResult.length,
              (int index) => DataRow(
                cells: <DataCell>[
                  DataCell(Text(_searchResult[index]['id'])),
                  DataCell(Text(_searchResult[index]['title'])),
                  DataCell(Text(_searchResult[index]['price'].toString())),
                  DataCell(Text(_searchResult[index]['capacity'].toString())),
                  DataCell(Text(_searchResult[index]['quantity'].toString())),
                  const DataCell(
                      Image(image: AssetImage('assets/wuxianshang.jpg'))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
