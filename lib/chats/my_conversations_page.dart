import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/chats/chat_page.dart';

class MyConversationsPage extends StatefulWidget {
  const MyConversationsPage({super.key});

  @override
  State<MyConversationsPage> createState() => _MyConversationsPageState();
}

class _MyConversationsPageState extends State<MyConversationsPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  Stream<QuerySnapshot> getMyChats() {
    return FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: currentUser.uid)
        .orderBy("updatedAt", descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getOtherUserData(
    List<dynamic> participants,
  ) async {
    try {
      final otherUserId = participants.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => null,
      );

      if (otherUserId == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(otherUserId)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() ?? {};
      data["uid"] = otherUserId;
      return data;
    } catch (e) {
      return null;
    }
  }

  String formatLastMessage(dynamic value) {
    if (value == null) return "";
    final text = value.toString().trim();
    if (text.isEmpty) return "ابدأ المحادثة";
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("محادثاتي"),
        centerTitle: true,
        backgroundColor: Colors.greenAccent[200],
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "لا توجد محادثات بعد",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = List<dynamic>.from(
                chatData["participants"] ?? [],
              );

              return FutureBuilder<Map<String, dynamic>?>(
                future: getOtherUserData(participants),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.greenAccent,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Text("جاري تحميل البيانات...")),
                        ],
                      ),
                    );
                  }

                  final userData = userSnapshot.data;

                  if (userData == null) {
                    return const SizedBox();
                  }

                  final otherUserId = userData["uid"] ?? "";
                  final firstName = userData["firstName"] ?? "";
                  final lastName = userData["lastName"] ?? "";
                  final userName = userData["userName"] ?? "";
                  final photoUrl = userData["photoUrl"] ?? "";
                  final isOnline = userData["isOnline"] ?? false;

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatPage(otherUserId: otherUserId),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: photoUrl.toString().isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.toString().isEmpty
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
                                  "$firstName $lastName",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "@$userName",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    formatLastMessage(chatData["lastMessage"]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
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
}
