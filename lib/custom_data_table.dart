
import 'package:flutter/material.dart';

class CustomDataTable extends StatefulWidget {
  final List<String> columns;
  final List<DataColumn> columnNames;
  final List<int> selectedItemIds;
  final List<dynamic> currentPageData;
  final int imageColumnIndex;
  final Function(Map<String, dynamic> data) editData;
  final bool hasDetailButton;
  final Function(String)? toDetail;
  final Function(bool)? selectAll;

  const CustomDataTable(
      {Key? key,
      required this.columns,
      required this.columnNames,
      required this.selectedItemIds,
      required this.hasDetailButton, //详情按钮默认放在倒数第四列
      required this.currentPageData,
      required this.imageColumnIndex,
      required this.editData,
      this.toDetail,
      this.selectAll})
      : super(key: key);

  @override
  _CustomDataTableState createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  final double _cellWidth = 100; // 设置 DataCell 的宽度

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: widget.columnNames,
      rows: List<DataRow>.generate(
        widget.currentPageData.length,
        (int index) => DataRow(
          cells: List<DataCell>.generate(
            widget.columns.length,
            (int columnIndex) {
              if (columnIndex != widget.imageColumnIndex) {
                if (columnIndex == 0) {
                  return DataCell(
                    Checkbox(
                      value: widget.selectedItemIds.contains(int.tryParse(
                          widget.currentPageData[index].values.elementAt(0))),
                      onChanged: (bool? value) {
                        setState(() {
                          int? id = int.tryParse(widget
                              .currentPageData[index].values
                              .elementAt(0));
                          if (value!) {
                            widget.selectedItemIds.add(id!);
                          } else {
                            widget.selectedItemIds.remove(id!);
                          }
                        });
                      },
                    ),
                  );
                } else if (columnIndex == widget.columnNames.length - 3) {
                  return DataCell(
                    ElevatedButton(
                      onPressed: () =>
                          widget.editData(widget.currentPageData[index]),
                      child: Text('Edit'),
                    ),
                  );
                } else if (columnIndex == widget.columnNames.length - 4 &&
                    widget.hasDetailButton) {
                  return DataCell(
                    ElevatedButton(
                      onPressed: () {
                        widget.toDetail!(widget.currentPageData[index].values
                            .elementAt(0)
                            .toString());
                      },
                      child: Text('配置详情'),
                    ),
                  );
                } else {
                  String key = widget.columns[columnIndex];
                  return DataCell(
                    SizedBox(
                      width: _cellWidth,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(
                          widget.currentPageData[index][key].toString(),
                          softWrap: true,
                        ),
                      ),
                    ),
                  );
                }
              } else {
                return const DataCell(
                  Image(
                    image: AssetImage('assets/wuxianshang.jpg'),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
