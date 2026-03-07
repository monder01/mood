import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchForFriendsPage extends StatefulWidget {
  const SearchForFriendsPage({super.key});

  @override
  State<SearchForFriendsPage> createState() => _SearchForFriendsPageState();
}

class _SearchForFriendsPageState extends State<SearchForFriendsPage> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String searchText = "";

  Stream<QuerySnapshot> searchByUsername() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('userName', isGreaterThanOrEqualTo: searchText)
        .where('userName', isLessThanOrEqualTo: '$searchText\uf8ff')
        .snapshots();
  }

  Stream<QuerySnapshot> searchByName() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('firstName', isGreaterThanOrEqualTo: searchText)
        .where('firstName', isLessThanOrEqualTo: '$searchText\uf8ff')
        .snapshots();
  }

  Future<void> showProfile01(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        final photo = user['photoUrl'] ?? "";
        final firstName = user['firstName'] ?? "";
        final lastName = user['lastName'] ?? "";
        final username = user['userName'] ?? "";

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// profile picture
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: photo.isEmpty
                        ? const Icon(Icons.person, size: 45)
                        : null,
                  ),

                  const SizedBox(height: 15),

                  /// name
                  Text(
                    "$firstName $lastName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// username
                  Text(
                    "@$username",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  /// buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.greenAccent,
                          ),
                          label: const Text("إضافة صديق"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 3,
                            side: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.message_outlined,
                            color: Colors.greenAccent,
                          ),
                          label: const Text("مراسلة"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 3,
                            side: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  /// close button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "إغلاق",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ابحث عن زملائك")),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "ابحث بالاسم او اسم المستخدم",
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide(color: Colors.greenAccent, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 20),

            Expanded(
              child: searchText.isEmpty
                  ? const Center(child: Text("ابدأ البحث"))
                  : StreamBuilder<QuerySnapshot>(
                      stream: searchByUsername(),
                      builder: (context, snapshot1) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: searchByName(),
                          builder: (context, snapshot2) {
                            if (!snapshot1.hasData || !snapshot2.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                ),
                              );
                            }

                            var users = [
                              ...snapshot1.data!.docs,
                              ...snapshot2.data!.docs,
                            ];

                            /// remove duplicates
                            final ids = <String>{};
                            users = users.where((doc) {
                              if (ids.contains(doc.id)) return false;
                              if (doc.id == currentUserId) return false;
                              ids.add(doc.id);
                              return true;
                            }).toList();

                            if (users.isEmpty) {
                              return const Center(child: Text("لا يوجد نتائج"));
                            }

                            return ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                var user = users[index];

                                return InkWell(
                                  onTap: () async {
                                    await showProfile01(
                                      context,
                                      user.data() as Map<String, dynamic>,
                                      user.id,
                                    );
                                  },
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: user['photoUrl'] != ""
                                          ? NetworkImage(user['photoUrl'])
                                          : null,
                                      child: user['photoUrl'] == ""
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(
                                      "${user['firstName']} ${user['lastName']}",
                                    ),
                                    subtitle: Text("@${user['userName']}"),
                                    trailing: user['isOnline']
                                        ? const Icon(
                                            Icons.circle,
                                            color: Colors.green,
                                            size: 12,
                                          )
                                        : const Icon(
                                            Icons.circle,
                                            color: Colors.red,
                                            size: 12,
                                          ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
