import 'package:flutter/material.dart';

class AddDepartmentPage extends StatefulWidget {
  const AddDepartmentPage({super.key});

  @override
  State<AddDepartmentPage> createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends State<AddDepartmentPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إضافة قسم"), centerTitle: true),
      body: Center(
        child: Text("Add Department Page", style: TextStyle(fontSize: 25)),
      ),
    );
  }
}
