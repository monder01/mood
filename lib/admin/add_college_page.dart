import 'package:flutter/material.dart';

class AddCollegePage extends StatefulWidget {
  const AddCollegePage({super.key});

  @override
  State<AddCollegePage> createState() => _AddCollegePageState();
}

class _AddCollegePageState extends State<AddCollegePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إضافة كلية"), centerTitle: true),
      body: Center(
        child: Text("Add College Page", style: TextStyle(fontSize: 25)),
      ),
    );
  }
}
