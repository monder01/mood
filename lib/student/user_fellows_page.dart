import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/friends/friends.dart';
import 'package:mood01/interfaces.dart';
import 'package:mood01/friends/search_for_friends_page.dart';

class UserFellowsPage extends StatefulWidget {
  const UserFellowsPage({super.key});

  @override
  State<UserFellowsPage> createState() => _UserFellowsPageState();
}

class _UserFellowsPageState extends State<UserFellowsPage> {
  final interfaces = Interfaces();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
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
          toolbarHeight: 50,
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
            indicatorColor: Colors.greenAccent,
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
                  child: FutureBuilder<Map<String, Map<String, dynamic>>>(
                    future: fetchUsersData(friends),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        );
                      }
                      final friendsData = snap.data!;
                      if (friends.isEmpty) {
                        return const Center(
                          child: Text("لا يوجد أصدقاء حتى الآن"),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(10),
                        children: friends.map((friendId) {
                          final userData = friendsData[friendId]!;
                          return ListTile(
                            onTap: () {},
                            leading: CircleAvatar(
                              backgroundImage:
                                  (userData['photoUrl'] ?? '').isNotEmpty
                                  ? NetworkImage(userData['photoUrl'])
                                  : null,
                              child: (userData['photoUrl'] ?? '').isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              "${userData['firstName']} ${userData['lastName']}",
                            ),
                            subtitle: Text("${userData['userName']}@"),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm = await interfaces
                                    .showConfirmationDialog(
                                      context,
                                      " هل تريد حذف هذا الصديق ؟",
                                      icon: Icons.question_mark_outlined,
                                    );

                                if (!confirm) return;
                                await friendService.removeFriend(
                                  currentUserId,
                                  friendId,
                                );
                              },
                            ),
                          );
                        }).toList(),
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
                          final userData = requestsData[requestId]!;
                          return Card(
                            child: ListTile(
                              onTap: () {
                                showProfile(userData);
                              },
                              leading: CircleAvatar(
                                backgroundImage:
                                    (userData['photoUrl'] ?? '').isNotEmpty
                                    ? NetworkImage(userData['photoUrl'])
                                    : null,
                                child: (userData['photoUrl'] ?? '').isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                "${userData['firstName']} ${userData['lastName']}",
                              ),
                              subtitle: Text("${userData['userName']}@"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
                                      shadowColor: Colors.black,
                                    ),
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
                                    child: isLoading02
                                        ? Center(
                                            child:
                                                const CircularProgressIndicator(
                                                  color: Colors.greenAccent,
                                                ),
                                          )
                                        : const Text("قبول"),
                                  ),
                                  const SizedBox(width: 2),
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
                                    child: isLoading02
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.greenAccent,
                                            ),
                                          )
                                        : const Text("رفض"),
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
                          final userData = sentDataMap[sentId]!;
                          return Card(
                            child: ListTile(
                              onTap: () => showProfile(userData),
                              leading: CircleAvatar(
                                backgroundImage:
                                    (userData['photoUrl'] ?? '').isNotEmpty
                                    ? NetworkImage(userData['photoUrl'])
                                    : null,
                                child: (userData['photoUrl'] ?? '').isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                "${userData['firstName']} ${userData['lastName']}",
                              ),
                              subtitle: Text("${userData['userName']}@"),
                              trailing: TextButton(
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
                                        await cancelSentRequest(sentId);
                                        setState(() {
                                          isLoading03 = false;
                                        });
                                      },
                                child: isLoading03
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.greenAccent,
                                        ),
                                      )
                                    : const Text("إلغاء الطلب"),
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
