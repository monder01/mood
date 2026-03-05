import 'package:flutter/material.dart';

class AdminBrowsePage extends StatefulWidget {
  const AdminBrowsePage({super.key});

  @override
  State<AdminBrowsePage> createState() => _AdminBrowsePageState();
}

class _AdminBrowsePageState extends State<AdminBrowsePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Admin Browse Page", style: TextStyle(fontSize: 25)),
      ),
    );
  }
}
