import 'package:flutter/material.dart';
import 'PaginationControl.dart';

class CustomDataTable extends StatefulWidget {
  final List<String> columns;
  final List<DataColumn> columnNames;
  final List<int> selectedItemIds;
  final List<dynamic> currentPageData;
  final int imageColumnIndex;
  final Function(Map<String, dynamic> data) editData;

  CustomDataTable({
    Key? key,
    required this.columns,
    required this.columnNames,
    required this.selectedItemIds,
    required this.currentPageData,
    required this.imageColumnIndex,
    required this.editData,
  }) : super(key: key);

  @override
  _CustomDataTableState createState() => _CustomDataTableState();
}

class _CustomDataTableState extends State<CustomDataTable> {
  final double cellWidth = 100; // 设置 DataCell 的宽度

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
              if (columnIndex == 0) {
                return DataCell(
                  Checkbox(
                    value: widget.selectedItemIds
                        .contains(widget.currentPageData[index][columnIndex]),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value!) {
                          widget.selectedItemIds
                              .add(widget.currentPageData[index][columnIndex]);
                        } else {
                          widget.selectedItemIds.remove(
                              widget.currentPageData[index][columnIndex]);
                        }
                      });
                    },
                  ),
                );
              } else if (columnIndex == widget.imageColumnIndex) {
                return const DataCell(
                  Image(
                    image: AssetImage('assets/wuxianshang.jpg'),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
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
              } else {
                String key = widget.columns[columnIndex];
                return DataCell(
                  SizedBox(
                    width: cellWidth,
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
            },
          ),
        ),
      ),
    );
  }
}
