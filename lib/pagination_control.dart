import 'package:flutter/material.dart';

class PaginationControl extends StatefulWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final Function onNextPage;
  final Function onPrevPage;
  final Function onJumpPage;

  const PaginationControl({
    Key? key,
    required this.currentPage,
    required this.totalItems,
    required this.pageSize,
    required this.onNextPage,
    required this.onPrevPage,
    required this.onJumpPage,
  }) : super(key: key);

  @override
  State<PaginationControl> createState() => _PaginationControlState();
}

class _PaginationControlState extends State<PaginationControl> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: () => widget.onPrevPage(),
        ),
        Text(
            '${widget.currentPage + 1}/${(widget.totalItems / widget.pageSize).ceil()}'),
        IconButton(
          icon: const Icon(Icons.arrow_right),
          onPressed: () => widget.onNextPage(),
        ),
        //跳转到指定页面
        SizedBox(
          width: 100,
          height: 50,
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            controller: _controller,
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(
          width: 80,
          height: 50,
          child: TextButton(
            onPressed: () => widget.onJumpPage(int.parse(_controller.text)),
            child: const Text('跳转'),
          ),
        )
      ],
    );
  }
}
