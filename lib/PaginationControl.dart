import 'package:flutter/material.dart';

class PaginationControl extends StatefulWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final Function onNextPage;
  final Function onPrevPage;

  const PaginationControl({
    Key? key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onNextPage,
    required this.onPrevPage,
  }) : super(key: key);

  @override
  _PaginationControlState createState() => _PaginationControlState();
}

class _PaginationControlState extends State<PaginationControl> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left),
          onPressed: () => widget.onPrevPage(),
        ),
        Text(
            '${widget.currentPage + 1}/${(widget.totalItems / widget.pageSize).ceil()}'),
        IconButton(
          icon: Icon(Icons.arrow_right),
          onPressed: () => widget.onNextPage(),
        ),
      ],
    );
  }
}
