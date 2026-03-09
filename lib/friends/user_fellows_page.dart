import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/chats/chat_page.dart';
import 'package:mood01/friends/friends.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/friends/search_for_friends_page.dart';

class UserFellowsPage extends StatefulWidget {
  const UserFellowsPage({super.key});

  @override
  State<UserFellowsPage> createState() => _UserFellowsPageState();
}

class _UserFellowsPageState extends State<UserFellowsPage> {
  final interfaces = Interfaces();
  late String currentUserId;
  final friendService = FriendService();
  final friendsRef = FirebaseFirestore.instance.collection('friends');
  final usersRef = FirebaseFirestore.instance.collection('users');
  bool isLoading01 = false, isLoading02 = false, isLoading03 = false;

  /// دالة لإلغاء الطلب المرسل
  Future<void> cancelSentRequest(String targetUserId) async {
    final currentDoc = friendsRef.doc(currentUserId);
    final targetDoc = friendsRef.doc(targetUserId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final currentSnapshot = await transaction.get(currentDoc);
      final targetSnapshot = await transaction.get(targetDoc);

      final sentRequests = List<String>.from(
        currentSnapshot['sentRequests'] ?? [],
      );
      final friendRequests = List<String>.from(
        targetSnapshot['friendRequests'] ?? [],
      );

      if (sentRequests.contains(targetUserId)) {
        sentRequests.remove(targetUserId);
        friendRequests.remove(currentUserId);

        transaction.update(currentDoc, {'sentRequests': sentRequests});
        transaction.update(targetDoc, {'friendRequests': friendRequests});
      }
    });
  }

  /// دالة مساعدة لتحميل بيانات مجموعة من المستخدمين دفعة واحدة
  Future<Map<String, Map<String, dynamic>>> fetchUsersData(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    final snapshots = await Future.wait(
      ids.map((id) => usersRef.doc(id).get()).toList(),
    );
    final result = <String, Map<String, dynamic>>{};
    for (var snap in snapshots) {
      result[snap.id] = snap.data() ?? {};
    }
    return result;
  }

  void showProfile(Map<String, dynamic> userData) {
    // عرض نافذة بروفايل المستخدم بشكل ممتع وبسيط
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (userData['photoUrl'] ?? '').isNotEmpty
                      ? NetworkImage(userData['photoUrl'])
                      : null,
                  child: (userData['photoUrl'] ?? '').isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  "${userData['firstName']} ${userData['lastName']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${userData['userName']}@",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  ButtonStyle buttonStyle01() => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 5,
    minimumSize: const Size(135, 40),
    maximumSize: const Size(135, 40),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    side: const BorderSide(color: Colors.greenAccent, width: 2),
  );

  void friendShowProfile(Map<String, dynamic> userData) {
    // عرض نافذة بروفايل المستخدم بشكل ممتع وبسيط
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (userData['photoUrl'] ?? '').isNotEmpty
                      ? NetworkImage(userData['photoUrl'])
                      : null,
                  child: (userData['photoUrl'] ?? '').isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  "${userData['firstName']} ${userData['lastName']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${userData['userName']}@",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: buttonStyle01(),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatPage(otherUserId: userData['uid']),
                          ),
                        );
                      },
                      child: const Text("مراسلة"),
                    ),
                    ElevatedButton(
                      style: buttonStyle01(),
                      onPressed: () async {
                        final confirm = await interfaces.showConfirmationDialog(
                          context,
                          " هل حقا تريد إلغاء الصداقة ؟",
                        );

                        if (!confirm) return;
                        await friendService.removeFriend(
                          currentUserId,
                          userData['uid'],
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text("إلغاء الصداقة"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.greenAccent[200],
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          toolbarHeight: 40,
          shadowColor: Colors.greenAccent,
          actions: [
            // if (users.role == "user")
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchForFriendsPage(),
                  ),
                );
              },
              icon: Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {
                // Action for notification button
              },
              icon: Icon(Icons.notifications),
            ),
          ],
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            tabs: const [
              Tab(text: 'أصدقائي'),
              Tab(text: 'طلبات واردة'),
              Tab(text: 'طلبات مرسلة'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: friendsRef.doc(currentUserId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.greenAccent,
                ),
              );
            }

            if (!snapshot.data!.exists) {
              return const Center(child: Text("لا يوجد بيانات حتى الآن"));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.greenAccent,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final friends = List<String>.from(data['friends'] ?? []);
            final friendRequests = List<String>.from(
              data['friendRequests'] ?? [],
            );
            final sentRequests = List<String>.from(data['sentRequests'] ?? []);

            return TabBarView(
              children: [
                /// Tab 1: أصدقائي
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: friends.isEmpty
                      ? const Center(child: Text("لا يوجد أصدقاء حتى الآن"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friendId = friends[index];

                            return StreamBuilder<DocumentSnapshot>(
                              stream: usersRef.doc(friendId).snapshots(),
                              builder: (context, userSnap) {
                                if (!userSnap.hasData ||
                                    !userSnap.data!.exists) {
                                  return const SizedBox();
                                }

                                final userData =
                                    userSnap.data!.data()
                                        as Map<String, dynamic>? ??
                                    {};

                                return InkWell(
                                  onTap: () => friendShowProfile(userData),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(bottom: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 5,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Stack(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundImage:
                                                  (userData['photoUrl'] ?? '')
                                                      .toString()
                                                      .isNotEmpty
                                                  ? NetworkImage(
                                                      userData['photoUrl'],
                                                    )
                                                  : null,
                                              child:
                                                  (userData['photoUrl'] ?? '')
                                                      .toString()
                                                      .isEmpty
                                                  ? const Icon(Icons.person)
                                                  : null,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              left: 5,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      (userData['isOnline'] ??
                                                          false)
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              "${userData['userName'] ?? ''}@",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Column(
                                          children: [
                                            Icon(
                                              Icons.group_outlined,
                                              size: 25,
                                              color: Colors.green,
                                            ),
                                            const Text("اصدقاء"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),

                /// Tab 2: طلبات واردة
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: fetchUsersData(friendRequests),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        );
                      }
                      final requestsData = snap.data!;
                      if (friendRequests.isEmpty) {
                        return const Center(child: Text("لا يوجد طلبات واردة"));
                      }

                      return ListView(
                        padding: const EdgeInsets.all(10),
                        children: friendRequests.map((requestId) {
                          final userData = requestsData[requestId];
                          if (userData == null) return const SizedBox();
                          return InkWell(
                            onTap: () => showProfile(userData),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundImage:
                                            (userData['photoUrl'] ?? '')
                                                .isNotEmpty
                                            ? NetworkImage(userData['photoUrl'])
                                            : null,
                                        child:
                                            (userData['photoUrl'] ?? '').isEmpty
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${userData['firstName']} ${userData['lastName']}",
                                          ),
                                          Text(
                                            "${userData['userName']}@",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        style: buttonStyle01(),
                                        onPressed: isLoading02
                                            ? null
                                            : () async {
                                                final confirm = await interfaces
                                                    .showConfirmationDialog(
                                                      context,
                                                      " هل تريد قبول طلب الصداقة ✅ ؟",
                                                    );

                                                if (!confirm) return;
                                                setState(() {
                                                  isLoading02 = true;
                                                });
                                                await friendService
                                                    .acceptFriendRequest(
                                                      currentUserId,
                                                      requestId,
                                                    );
                                                setState(() {
                                                  isLoading02 = false;
                                                });
                                              },
                                        child: const Text(
                                          "قبول",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: buttonStyle01(),
                                        onPressed: isLoading02
                                            ? null
                                            : () async {
                                                final confirm = await interfaces
                                                    .showConfirmationDialog(
                                                      context,
                                                      " هل تريد رفض طلب الصداقة ❌ ؟",
                                                    );

                                                if (!confirm) return;
                                                setState(() {
                                                  isLoading02 = true;
                                                });
                                                await friendService
                                                    .rejectFriendRequest(
                                                      currentUserId,
                                                      requestId,
                                                    );
                                                setState(() {
                                                  isLoading02 = false;
                                                });
                                              },
                                        child: const Text(
                                          "رفض",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                /// Tab 3: طلبات مرسلة
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: fetchUsersData(sentRequests),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        );
                      }
                      final sentDataMap = snap.data!;
                      if (sentRequests.isEmpty) {
                        return const Center(child: Text("لا يوجد طلبات مرسلة"));
                      }

                      return ListView(
                        padding: const EdgeInsets.all(10),
                        children: sentRequests.map((sentId) {
                          final userData = sentDataMap[sentId];
                          if (userData == null) return const SizedBox();
                          return InkWell(
                            onTap: () => showProfile(userData),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        (userData['photoUrl'] ?? '').isNotEmpty
                                        ? NetworkImage(userData['photoUrl'])
                                        : null,
                                    child: (userData['photoUrl'] ?? '').isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${userData['firstName']} ${userData['lastName']}",
                                      ),
                                      Text(
                                        "${userData['userName']}@",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
                                      shadowColor: Colors.black,
                                    ),
                                    onPressed: isLoading03
                                        ? null
                                        : () async {
                                            final confirm = await interfaces
                                                .showConfirmationDialog(
                                                  context,
                                                  " هل تريد إلغاء طلب الصداقة ❌ ؟",
                                                );

                                            if (!confirm) return;
                                            setState(() {
                                              isLoading03 = true;
                                            });
                                            await friendService
                                                .cancelSentRequest(
                                                  currentUserId,
                                                  sentId,
                                                );
                                            setState(() {
                                              isLoading03 = false;
                                            });
                                          },
                                    child: Text("إلغاء الإرسال"),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
