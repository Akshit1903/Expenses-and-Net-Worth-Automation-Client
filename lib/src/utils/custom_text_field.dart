import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
  });
  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        suffixIcon: IconButton(
          onPressed: () => setState(() {
            widget.controller.clear();
            FocusScope.of(context).requestFocus(_focusNode);
          }),
          icon: Icon(Icons.cancel),
        ),
      ),
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: (value) {
        setState(() {});
      },
    );
  }
}
