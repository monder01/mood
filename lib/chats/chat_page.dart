import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;

  const ChatPage({super.key, required this.otherUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();

  String? otherUserFirstName, otherUserLastName, otherUserImageUrl;
  String? chatId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    initChat();
    getOtherUser();
  }

  /// البحث عن chat أو إنشاء واحد
  Future<void> initChat() async {
    final chats = await FirebaseFirestore.instance
        .collection("chats")
        .where("participants", arrayContains: currentUser.uid)
        .get();

    for (var doc in chats.docs) {
      final users = List<String>.from(doc["participants"]);

      if (users.contains(widget.otherUserId)) {
        chatId = doc.id;
        setState(() => loading = false);
        return;
      }
    }

    /// إنشاء محادثة جديدة
    final newChat = await FirebaseFirestore.instance.collection("chats").add({
      "participants": [currentUser.uid, widget.otherUserId],
      "lastMessage": "",
      "lastSenderId": "",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    chatId = newChat.id;

    setState(() => loading = false);
  }

  /// إرسال رسالة
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || chatId == null) return;

    messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);

    await chatRef.collection("messages").add({
      "senderId": currentUser.uid,
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      "lastMessage": text,
      "lastSenderId": currentUser.uid,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // get other user
  Future<void> getOtherUser() async {
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.otherUserId)
        .get();
    otherUserFirstName = userDoc.get("firstName") ?? "";
    otherUserLastName = userDoc.get("lastName") ?? "";
    otherUserImageUrl = userDoc.get("photoUrl") ?? "";
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || chatId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final messagesStream = FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdAt")
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent[200],
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 60,
        shadowColor: Colors.greenAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: otherUserImageUrl != null && otherUserImageUrl!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(otherUserImageUrl ?? ""),
                  )
                : const CircleAvatar(child: Icon(Icons.person)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$otherUserFirstName",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$otherUserLastName",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// الرسائل
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text("لا يوجد رسائل بعد"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;

                    final isMe = data["senderId"] == currentUser.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.greenAccent
                              : Colors.grey.shade300,
                          borderRadius: isMe
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                )
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                        ),
                        child: Text(
                          data["text"] ?? "",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// إدخال الرسالة
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "اكتب رسالة ...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.greenAccent,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.greenAccent),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
