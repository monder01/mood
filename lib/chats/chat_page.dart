import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  final String otherUserId;

  const ChatPage({super.key, required this.otherUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController messageController = TextEditingController();

  String? chatId;
  bool loading = true;
  bool isUploadingFile = false;

  String otherUserFirstName = "";
  String otherUserLastName = "";
  String otherUserImageUrl = "";

  String myFirstName = "";
  String myLastName = "";
  String myImageUrl = "";
  final interfaces = Interfaces();

  String buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return "${ids[0]}_${ids[1]}";
  }

  @override
  void initState() {
    super.initState();
    initChat();
  }

  Future<void> initChat() async {
    try {
      final generatedChatId = buildChatId(currentUser.uid, widget.otherUserId);
      final chatRef = FirebaseFirestore.instance
          .collection("chats")
          .doc(generatedChatId);

      final myDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final otherDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.otherUserId)
          .get();

      if (!myDoc.exists || !otherDoc.exists) {
        if (!mounted) return;
        setState(() {
          loading = false;
        });
        return;
      }

      final myData = myDoc.data() ?? {};
      final otherData = otherDoc.data() ?? {};

      myFirstName = myData["firstName"]?.toString() ?? "";
      myLastName = myData["lastName"]?.toString() ?? "";
      myImageUrl = myData["photoUrl"]?.toString() ?? "";

      otherUserFirstName = otherData["firstName"]?.toString() ?? "";
      otherUserLastName = otherData["lastName"]?.toString() ?? "";
      otherUserImageUrl = otherData["photoUrl"]?.toString() ?? "";

      final chatSnap = await chatRef.get();

      if (!chatSnap.exists) {
        await chatRef.set({
          "participants": [currentUser.uid, widget.otherUserId],
          "lastMessage": "",
          "lastSenderId": "",
          "updatedAt": FieldValue.serverTimestamp(),
          "userData": {
            currentUser.uid: {
              "uid": currentUser.uid,
              "firstName": myFirstName,
              "lastName": myLastName,
              "photoUrl": myImageUrl,
            },
            widget.otherUserId: {
              "uid": widget.otherUserId,
              "firstName": otherUserFirstName,
              "lastName": otherUserLastName,
              "photoUrl": otherUserImageUrl,
            },
          },
        });
      }

      chatId = generatedChatId;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({"activeChatId": chatId});

      if (!mounted) return;
      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint("initChat error: $e");
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || chatId == null) return;

    messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);

    await chatRef.collection("messages").add({
      "senderId": currentUser.uid,
      "text": text,
      "type": "text",
      "createdAt": FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      "lastMessage": text,
      "lastMessageType": "text",
      "lastSenderId": currentUser.uid,
      "updatedAt": FieldValue.serverTimestamp(),
      "userData.${currentUser.uid}.firstName": myFirstName,
      "userData.${currentUser.uid}.lastName": myLastName,
      "userData.${currentUser.uid}.photoUrl": myImageUrl,
      "userData.${widget.otherUserId}.firstName": otherUserFirstName,
      "userData.${widget.otherUserId}.lastName": otherUserLastName,
      "userData.${widget.otherUserId}.photoUrl": otherUserImageUrl,
    });
  }

  Future<void> sendFileMessage() async {
    if (chatId == null || isUploadingFile) return;

    try {
      setState(() {
        isUploadingFile = true;
      });

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'png',
          'jpg',
          'jpeg',
          'zip',
          'rar',
        ],
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;
        setState(() {
          isUploadingFile = false;
        });
        return;
      }

      final picked = result.files.first;
      if (picked.path == null) {
        if (!mounted) return;
        setState(() {
          isUploadingFile = false;
        });
        return;
      }

      final file = File(picked.path!);
      final fileName = picked.name;
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : '';

      final storagePath =
          'chat_files/$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(contentType: _guessMimeType(ext));

      final snapshot = await ref.putFile(file, metadata);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final chatRef = FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId);

      await chatRef.collection("messages").add({
        "senderId": currentUser.uid,
        "text": "",
        "type": "file",
        "fileName": fileName,
        "fileUrl": downloadUrl,
        "fileSize": picked.size,
        "mimeType": _guessMimeType(ext),
        "createdAt": FieldValue.serverTimestamp(),
      });

      await chatRef.update({
        "lastMessage": "📎 $fileName",
        "lastMessageType": "file",
        "lastSenderId": currentUser.uid,
        "updatedAt": FieldValue.serverTimestamp(),
        "userData.${currentUser.uid}.firstName": myFirstName,
        "userData.${currentUser.uid}.lastName": myLastName,
        "userData.${currentUser.uid}.photoUrl": myImageUrl,
        "userData.${widget.otherUserId}.firstName": otherUserFirstName,
        "userData.${widget.otherUserId}.lastName": otherUserLastName,
        "userData.${widget.otherUserId}.photoUrl": otherUserImageUrl,
      });
    } catch (e) {
      debugPrint("sendFileMessage error: $e");
      if (!mounted) return;
      interfaces.showFlutterToast("فشل رفع الملف");
    } finally {
      if (mounted) {
        setState(() {
          isUploadingFile = false;
        });
      }
    }
  }

  String _guessMimeType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'txt':
        return 'text/plain';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  Future<void> openFileUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        interfaces.showFlutterToast("تعذر فتح الملف");
      }
    } catch (e) {
      debugPrint("openFileUrl error: $e");
      interfaces.showFlutterToast("رابط الملف غير صالح");
    }
  }

  Widget buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final type = data["type"]?.toString() ?? "text";

    BorderRadius bubbleRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          );

    if (type == "file") {
      final fileName = data["fileName"]?.toString() ?? "ملف";
      final fileUrl = data["fileUrl"]?.toString() ?? "";
      final fileSize = (data["fileSize"] as num?)?.toInt() ?? 0;

      final lowerName = fileName.toLowerCase();
      final isImage =
          lowerName.endsWith(".jpg") ||
          lowerName.endsWith(".jpeg") ||
          lowerName.endsWith(".png") ||
          lowerName.endsWith(".gif") ||
          lowerName.endsWith(".webp");

      if (isImage) {
        return InkWell(
          onTap: fileUrl.isEmpty
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Container(
                        alignment: Alignment.center,
                        child: InteractiveViewer(
                          child: Image.network(
                            fileUrl,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text("لا يمكن فتح الصورة"),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                  // await openFileUrl(fileUrl);
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 320),
            decoration: BoxDecoration(
              color: isMe ? Colors.greenAccent : Colors.grey.shade400,
              borderRadius: bubbleRadius,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fileUrl.isNotEmpty)
                  Image.network(
                    fileUrl,
                    width: 280,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 280,
                        height: 220,
                        alignment: Alignment.center,
                        color: Colors.black12,
                        child: const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.black54,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 280,
                        height: 220,
                        alignment: Alignment.center,
                        color: Colors.black12,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: 280,
                    height: 220,
                    alignment: Alignment.center,
                    color: Colors.black12,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.black54,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatFileSize(fileSize),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      IconButton(
                        onPressed: () async {
                          await openFileUrl(fileUrl);
                        },
                        icon: const Icon(
                          Icons.open_in_new,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return InkWell(
        onTap: fileUrl.isEmpty ? null : () => openFileUrl(fileUrl),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: isMe ? Colors.greenAccent : Colors.grey.shade400,
            borderRadius: bubbleRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.black),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatFileSize(fileSize),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, size: 18, color: Colors.black),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMe ? Colors.greenAccent : Colors.grey.shade400,
        borderRadius: bubbleRadius,
      ),
      child: Text(
        data["text"]?.toString() ?? "",
        style: const TextStyle(fontSize: 15, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    if (chatId != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({"activeChatId": null});
    }
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading || chatId == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.greenAccent),
        ),
      );
    }

    final messagesStream = FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("createdAt", descending: false)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 60,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade900,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: otherUserImageUrl.isNotEmpty
                ? CircleAvatar(backgroundImage: NetworkImage(otherUserImageUrl))
                : const CircleAvatar(child: Icon(Icons.person)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  otherUserFirstName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  otherUserLastName,
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
          if (isUploadingFile)
            LinearProgressIndicator(color: Colors.greenAccent),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text("لا يوجد رسائل بعد"));
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
                      child: buildMessageBubble(data, isMe),
                    );
                  },
                );
              },
            ),
          ),
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
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: isUploadingFile
                                  ? null
                                  : sendFileMessage,
                              icon: const Icon(Icons.attach_file),
                            ),
                            IconButton(
                              icon: Icon(Icons.send, color: Colors.greenAccent),
                              onPressed: sendMessage,
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
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
