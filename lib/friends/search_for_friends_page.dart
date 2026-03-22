import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/auth/users.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/friends/friends.dart';

class SearchForFriendsPage extends StatefulWidget {
  const SearchForFriendsPage({super.key});

  @override
  State<SearchForFriendsPage> createState() => _SearchForFriendsPageState();
}

class _SearchForFriendsPageState extends State<SearchForFriendsPage> {
  Users usersInfo = Users();
  final interfaces = Interfaces();
  final friendService = FriendService();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  String searchText = "";
  bool isLoadingButton = false;

  @override
  void initState() {
    loadUser();
    super.initState();
  }

  Future<void> loadUser() async {
    final user = await usersInfo.getCurrentUser();
    if (!mounted) return;

    if (user != null) {
      setState(() {
        usersInfo = user;
      });
    }
  }

  // stream builder to get info from friends collection
  Stream<DocumentSnapshot> friendsStream() {
    return FirebaseFirestore.instance
        .collection("friends")
        .doc(currentUserId)
        .snapshots();
  }

  Stream<QuerySnapshot> friendsStream02() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots();
  }

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

  Future<void> showProfileOptions(
    BuildContext context,
    String otherUserId,
    Map<String, dynamic> userData,
  ) async {
    if (currentUserId == otherUserId) return;

    // عرض نافذة بروفايل المستخدم بشكل ممتع وبسيط
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: friendsStream(),
          builder: (context, snapshot) {
            String friendStatus = "none";

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              );
            }

            if (snapshot.hasError) return const Text("حدث خطأ");

            if (!snapshot.hasData) {
              return CircularProgressIndicator(color: Colors.greenAccent);
            }

            if (snapshot.hasData) {
              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

              final friends = List<String>.from(data['friends'] ?? []);
              final sentRequests = List<String>.from(
                data['sentRequests'] ?? [],
              );
              final friendRequests = List<String>.from(
                data['friendRequests'] ?? [],
              );

              if (friends.contains(otherUserId)) {
                friendStatus = "friends";
              } else if (sentRequests.contains(otherUserId)) {
                friendStatus = "requestSent";
              } else if (friendRequests.contains(otherUserId)) {
                friendStatus = "requestReceived";
              }
            }

            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: interfaces.threeDcontainer(
                      context,
                      Colors.greenAccent,
                      icon: Icons.remove_red_eye_rounded,
                    ),
                    title: const Text("ملف المستخدم"),
                    onTap: () {
                      Navigator.pop(context);
                      interfaces.showProfile(context, userData);
                    },
                  ),
                  if (friendStatus == "none")
                    ListTile(
                      leading: interfaces.threeDcontainer(
                        context,
                        Colors.greenAccent,
                        icon: Icons.person_add_alt_1,
                      ),
                      title: const Text("اضافة صديق"),
                      onTap: () async {
                        final confirm = await interfaces.showConfirmationDialog(
                          context,
                          "متأكد من إرسال طلب الصداقة؟",
                        );
                        if (!confirm) return;

                        if (!context.mounted) return;
                        await friendService.sendFriendRequest(
                          currentUserId,
                          otherUserId,
                          context: context,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  if (friendStatus == "requestSent")
                    ListTile(
                      leading: interfaces.threeDcontainer(
                        context,
                        Colors.greenAccent,
                        icon: Icons.hourglass_bottom,
                      ),
                      title: const Text("تم ارسال طلب الصداقة"),
                      onTap: () async {
                        final confirm = await interfaces.showConfirmationDialog(
                          context,
                          "متاءكد من الغاء طلب الصداقة؟",
                          icon: Icons.cancel_schedule_send_outlined,
                          iconColor: Colors.red,
                        );
                        if (!confirm) return;

                        if (!context.mounted) return;
                        await friendService.cancelSentRequest(
                          currentUserId,
                          otherUserId,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  if (friendStatus == "requestReceived")
                    ListTile(
                      leading: interfaces.threeDcontainer(
                        context,
                        Colors.greenAccent,
                        icon: Icons.how_to_reg,
                      ),
                      title: const Text("قبول طلب الصداقة؟"),
                      onTap: () async {
                        final confirm = await interfaces.showConfirmationDialog(
                          context,
                          "متاءكد من قبول طلب الصداقة؟",
                        );
                        if (!confirm) return;

                        await friendService.acceptFriendRequest(
                          currentUserId,
                          otherUserId,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                  if (friendStatus == "friends")
                    ListTile(
                      leading: interfaces.threeDcontainer(
                        context,
                        Colors.greenAccent,
                        icon: Icons.group_outlined,
                      ),
                      title: const Text("صديق"),
                      onTap: () async {
                        final confirm = await interfaces.showConfirmationDialog(
                          context,
                          "متاءكد من حذف صديق؟",
                        );
                        if (!confirm) return;

                        await friendService.removeFriend(
                          currentUserId,
                          otherUserId,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 40,
        automaticallyImplyLeading: false,
        titleSpacing: 2,
        title: interfaces.buildSearchField(
          hint: "ابحث عن صديق",
          onChanged: (value) {
            setState(() {
              searchText = value.toLowerCase();
            });
          },
        ),
        backgroundColor: Colors.greenAccent,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 50,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: searchText.isEmpty
                  ? const Center(
                      child: Text("ابدأ البحث عن طريق اسم المستخدم او الاسم"),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: searchByUsername(),
                      builder: (context, snapshot1) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: searchByName(),
                          builder: (context, snapshot2) {
                            if (!snapshot1.hasData || !snapshot2.hasData) {
                              return Center(
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
                              if (usersInfo.role == doc["role"]) return false;
                              if (doc.id == currentUserId) return false;
                              if (doc["isPrivate"] == true) return false;
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
                                    onTap: () => showProfileOptions(
                                      context,
                                      userDoc.id,
                                      userData,
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
