import 'package:flutter/material.dart';

class AddSectionPage extends StatefulWidget {
  const AddSectionPage({super.key});

  @override
  State<AddSectionPage> createState() => _AddSectionPageState();
}

class _AddSectionPageState extends State<AddSectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إضافة شعبة"), centerTitle: true),
      body: Center(
        child: Text("Add Section Page", style: TextStyle(fontSize: 25)),
      ),
    );
  }
}
