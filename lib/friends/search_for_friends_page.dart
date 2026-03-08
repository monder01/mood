import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/friends/friends.dart';
import 'package:mood01/global/interfaces.dart';

class SearchForFriendsPage extends StatefulWidget {
  const SearchForFriendsPage({super.key});

  @override
  State<SearchForFriendsPage> createState() => _SearchForFriendsPageState();
}

class _SearchForFriendsPageState extends State<SearchForFriendsPage> {
  final interfaces = Interfaces();
  final friendService = FriendService();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String searchText = "";
  bool isLoadingButton = false;

  // البحث بالـ username
  Stream<QuerySnapshot> searchByUsername() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('userName', isGreaterThanOrEqualTo: searchText)
        .where('userName', isLessThanOrEqualTo: '$searchText\uf8ff')
        .snapshots();
  }

  // البحث بالـ firstName
  Stream<QuerySnapshot> searchByName() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('firstName', isGreaterThanOrEqualTo: searchText)
        .where('firstName', isLessThanOrEqualTo: '$searchText\uf8ff')
        .snapshots();
  }

  // ستايل الأزرار
  ButtonStyle buttonStyle() => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 2,
    side: const BorderSide(color: Colors.greenAccent, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
  );

  Future<void> showUserProfile01(
    BuildContext context,
    Map<String, dynamic> userData,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('friends')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                String status = "none";

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: const CircularProgressIndicator(
                      color: Colors.greenAccent,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                if (snapshot.hasData) {
                  final data =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final friends = List<String>.from(data['friends'] ?? []);
                  final sentRequests = List<String>.from(
                    data['sentRequests'] ?? [],
                  );
                  final friendRequests = List<String>.from(
                    data['friendRequests'] ?? [],
                  );

                  if (friends.contains(userId)) {
                    status = "friends";
                  } else if (sentRequests.contains(userId)) {
                    status = "requestSent";
                  } else if (friendRequests.contains(userId)) {
                    status = "requestReceived";
                  }
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: (userData['photoUrl'] ?? '').isNotEmpty
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child: (userData['photoUrl'] ?? '').isEmpty
                          ? const Icon(Icons.person, size: 45)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "${userData['firstName']} ${userData['lastName']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${userData['userName']}@",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (status == "none")
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoadingButton
                                  ? null
                                  : () async {
                                      final confirm = await interfaces
                                          .showConfirmationDialog(
                                            context,
                                            " هل تريد اضافة ${userData['firstName']} ك صديق ؟",
                                          );

                                      if (!confirm) return;

                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      setState(() {
                                        isLoadingButton = true;
                                      });
                                      // ارسال طلب صديق
                                      await friendService.sendFriendRequest(
                                        currentUserId,
                                        userId,
                                      );
                                      setState(() {
                                        isLoadingButton = false;
                                      });
                                    },
                              label: isLoadingButton
                                  ? CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                    )
                                  : Text("اظافة صديق"),
                              icon: Icon(
                                Icons.person_add,
                                color: Colors.greenAccent,
                              ),
                              style: buttonStyle(),
                            ),
                          ),
                        if (status == "requestSent")
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoadingButton
                                  ? null
                                  : () async {
                                      final confirm = await interfaces
                                          .showConfirmationDialog(
                                            context,
                                            " هل تريد الغاء الطلب المرسل ؟",
                                          );

                                      if (!confirm) return;

                                      setState(() {
                                        isLoadingButton = true;
                                      });
                                      await friendService.cancelSentRequest(
                                        currentUserId,
                                        userId,
                                      );
                                      setState(() {
                                        isLoadingButton = false;
                                      });
                                    },
                              label: isLoadingButton
                                  ? CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                    )
                                  : Text("إلغاء الطلب"),
                              icon: Icon(
                                Icons.person_remove,
                                color: Colors.red,
                              ),
                              style: buttonStyle(),
                            ),
                          ),
                        if (status == "requestReceived")
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoadingButton
                                  ? null
                                  : () async {
                                      final confirm = await interfaces
                                          .showConfirmationDialog(
                                            context,
                                            " هل تريد قبول طلب الصداقة ؟",
                                          );

                                      if (!confirm) return;
                                      setState(() {
                                        isLoadingButton = true;
                                      });
                                      await friendService.acceptFriendRequest(
                                        currentUserId,
                                        userId,
                                      );
                                      setState(() {
                                        isLoadingButton = false;
                                      });
                                    },
                              label: isLoadingButton
                                  ? CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                    )
                                  : Text("قبول الطلب"),
                              icon: Icon(Icons.how_to_reg, color: Colors.green),
                              style: buttonStyle(),
                            ),
                          ),
                        if (status == "friends")
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isLoadingButton
                                  ? null
                                  : () async {
                                      final confirm = await interfaces
                                          .showConfirmationDialog(
                                            context,
                                            " هل تريد حذف صديق ؟",
                                          );

                                      if (!confirm) return;

                                      setState(() {
                                        isLoadingButton = true;
                                      });
                                      await friendService.removeFriend(
                                        currentUserId,
                                        userId,
                                      );
                                      setState(() {
                                        isLoadingButton = false;
                                      });
                                    },
                              label: isLoadingButton
                                  ? CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                    )
                                  : Text("صديق"),
                              icon: Icon(
                                Icons.diversity_3,
                                color: Colors.greenAccent,
                              ),
                              style: buttonStyle(),
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
                              elevation: 2,
                              side: const BorderSide(
                                color: Colors.greenAccent,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "إغلاق",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "ابحث بالاسم او اسم المستخدم",
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 0),
            labelStyle: TextStyle(color: Colors.black54),
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
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

        backgroundColor: Colors.greenAccent[200],
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 50,
        shadowColor: Colors.greenAccent,
        actions: [
          // notification
          IconButton(
            onPressed: () {
              // navigate to notification page
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
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

                            // إزالة التكرارات واستبعاد المستخدم الحالي
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
                                final userDoc = users[index];
                                final userData =
                                    userDoc.data() as Map<String, dynamic>;
                                return Card(
                                  child: ListTile(
                                    onTap: () => showUserProfile01(
                                      context,
                                      userData,
                                      userDoc.id,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          userData['photoUrl']?.isNotEmpty ==
                                              true
                                          ? NetworkImage(userData['photoUrl'])
                                          : null,
                                      child:
                                          userData['photoUrl']?.isEmpty == true
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(
                                      "${userData['firstName']} ${userData['lastName']}",
                                    ),
                                    subtitle: Text("${userData['userName']}@"),
                                    trailing: userData['isOnline'] == true
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
