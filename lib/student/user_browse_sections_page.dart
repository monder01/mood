import 'package:flutter/material.dart';
import 'package:mood01/global/interfaces.dart';

class UserBrowseSectionsPage extends StatefulWidget {
  final String sectionId, sectionName;
  const UserBrowseSectionsPage({
    super.key,
    required this.sectionId,
    required this.sectionName,
  });

  @override
  State<UserBrowseSectionsPage> createState() => _UserBrowseSectionsPageState();
}

class _UserBrowseSectionsPageState extends State<UserBrowseSectionsPage> {
  final interfaces = Interfaces();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(
        context,
        title: "مواد ${widget.sectionName}",
      ),
      body: Center(
        child: Text(
          "User Browse Sections Page",
          style: TextStyle(fontSize: 25),
        ),
      ),
    );
  }
}
