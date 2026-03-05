import 'package:flutter/material.dart';

class AdminFellowsPage extends StatefulWidget {
  const AdminFellowsPage({super.key});

  @override
  State<AdminFellowsPage> createState() => _AdminFellowsPageState();
}

class _AdminFellowsPageState extends State<AdminFellowsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("زملائي")),
      body: const Center(
        child: Text("Admin Fellows Page", style: TextStyle(fontSize: 25)),
      ),
    );
  }
}
