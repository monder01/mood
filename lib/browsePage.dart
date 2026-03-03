import 'package:flutter/material.dart';

class Browsepage extends StatefulWidget {
  const Browsepage({super.key});

  @override
  State<Browsepage> createState() => _BrowsepageState();
}

class _BrowsepageState extends State<Browsepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Browse")));
  }
}
