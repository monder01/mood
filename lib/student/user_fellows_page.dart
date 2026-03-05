import 'package:flutter/material.dart';

class UserFellowsPage extends StatefulWidget {
  const UserFellowsPage({super.key});

  @override
  State<UserFellowsPage> createState() => _UserFellowsPageState();
}

class _UserFellowsPageState extends State<UserFellowsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("زملائي")),
      body: const Center(
        child: Text("User Fellows Page", style: TextStyle(fontSize: 25)),
      ),
    );
  }
}
