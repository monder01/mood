import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/navi_go.dart';

class CoworkersPage extends StatefulWidget {
  const CoworkersPage({super.key});

  @override
  State<CoworkersPage> createState() => _CoworkersPageState();
}

class _CoworkersPageState extends State<CoworkersPage> {
  final interfaces = Interfaces();
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyChats() {
    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("adminsChats")
        .where("participants", arrayContains: currentUser!.uid)
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }

  String formatLastMessage(dynamic value) {
    if (value == null) return "";
    final text = value.toString().trim();
    if (text.isEmpty) return "ابدأ المحادثة";
    return text;
  }

  Map<String, dynamic> getOtherUserDataFromChat(Map<String, dynamic> chatData) {
    final userData = Map<String, dynamic>.from(chatData["userData"] ?? {});

    for (final entry in userData.entries) {
      if (entry.key != currentUser?.uid) {
        return Map<String, dynamic>.from(entry.value ?? {});
      }
    }

    return {};
  }

  Future<void> refreshPage() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget adminsTab() {
    return RefreshIndicator(
      color: Colors.greenAccent,
      onRefresh: refreshPage,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("admins").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(
                  child: Text(
                    "حدث خطأ أثناء تحميل البيانات",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            );
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((doc) => doc.id != currentUser?.uid)
              .toList();

          if (docs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(
                  child: Text("لا توجد مشرفين", style: TextStyle(fontSize: 18)),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final firstName = data["firstName"]?.toString() ?? "";
              final lastName = data["lastName"]?.toString() ?? "";
              final userName = data["userName"]?.toString() ?? "";
              final email = data["email"]?.toString() ?? "";
              final name = "$firstName $lastName".trim();
              final adminUid = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.5),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.greenAccent.shade700,
                    ),
                  ),
                  title: Text(
                    name.isNotEmpty ? name : userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(email.isNotEmpty ? email : userName),
                  trailing: IconButton(
                    onPressed: () {
                      context.push(NaviGo.chatPath(adminUid));
                    },
                    icon: Icon(Icons.mail),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget chatsTab() {
    return RefreshIndicator(
      color: Colors.greenAccent,
      onRefresh: refreshPage,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 300),
                Center(child: Text("حدث خطأ: ${snapshot.error}")),
              ],
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 300),
                Center(
                  child: Text(
                    "لا توجد محادثات بعد",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data();

              final otherUserData = getOtherUserDataFromChat(chatData);

              final otherUserId = otherUserData["uid"]?.toString() ?? "";
              final firstName = otherUserData["firstName"]?.toString() ?? "";
              final lastName = otherUserData["lastName"]?.toString() ?? "";
              final photoUrl = otherUserData["photoUrl"]?.toString() ?? "";
              final lastMessage = formatLastMessage(chatData["lastMessage"]);

              if (otherUserId.isEmpty) {
                return const SizedBox();
              }

              final fullName = "$firstName $lastName".trim();
              final displayName = fullName.isEmpty ? "مستخدم" : fullName;

              String lastMessageText = "";
              if (chatData["lastSenderId"] == currentUser!.uid) {
                lastMessageText = "أنت: $lastMessage";
              } else {
                lastMessageText = "$displayName: $lastMessage";
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("admins")
                    .doc(otherUserId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  bool isOnline = false;

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final liveUserData = userSnapshot.data!.data() ?? {};
                    isOnline = liveUserData["isOnline"] == true;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      context.push(NaviGo.chatPath(otherUserId));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.black12,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? const Icon(Icons.person, size: 28)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    lastMessageText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              interfaces.showAppBar(context, title: "", actions: false),
              const TabBar(
                tabs: [
                  Tab(text: "زملائي"),
                  Tab(text: "محادثة"),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(children: [adminsTab(), chatsTab()]),
      ),
    );
  }
}
