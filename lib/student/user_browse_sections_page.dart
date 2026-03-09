import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/friends/search_for_friends_page.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("مواد ${widget.sectionName}"),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[200],
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 50,
        shadowColor: Colors.greenAccent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchForFriendsPage(),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
        ],
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
