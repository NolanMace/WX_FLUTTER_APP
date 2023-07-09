import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final Function(String) onDateSelected;
  final String initialDate;
  const CustomDatePicker(
      {super.key, required this.onDateSelected, required this.initialDate});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late String selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(selectedDate),
      firstDate: DateTime(2010),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      final formattedDate = picked.toString();
      setState(() {
        selectedDate = formattedDate;
      });
      widget.onDateSelected(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => _selectDate(context),
          child: const Text('选择日期'),
        ),
        const SizedBox(height: 16.0),
        Text(
          '选择的日期：${selectedDate.toString()}',
        ),
      ],
    );
  }
}
