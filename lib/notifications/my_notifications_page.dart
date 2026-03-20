import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mood01/chats/chat_page.dart';
import 'package:mood01/friends/user_fellows_page.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/global/my_account.dart';
import 'package:mood01/notifications/notification_target_navigator.dart';

class MyNotificationsPage extends StatefulWidget {
  const MyNotificationsPage({super.key});

  @override
  State<MyNotificationsPage> createState() => _MyNotificationsPageState();
}

class _MyNotificationsPageState extends State<MyNotificationsPage> {
  final interfaces = Interfaces();
  final currentUser = FirebaseAuth.instance.currentUser;
  late final Stream<QuerySnapshot> notificationsStream;
  final DocumentSnapshot? notificationSnapshot = null;
  bool isdeleteMode = false;
  bool isEmpty = false;

  final Map<String, double> dragProgress = {};

  Future<void> markAsRead(String notificationId) async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("notifications")
        .doc(notificationId)
        .update({"isRead": true});
  }

  Future<void> markAllAsRead() async {
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("notifications")
        .where("isRead", isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {"isRead": true});
    }

    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .collection("notifications")
        .doc(notificationId)
        .delete();
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.year}/${date.month}/${date.day} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case "friend_request":
        return Icons.person_add_alt_1;
      case "chat":
        return Icons.message;
      case "security_login":
        return Icons.security;
      case "broadcast":
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case "friend_request":
        return Colors.blue;
      case "chat":
        return Colors.green;
      case "security_login":
        return Colors.red;
      case "broadcast":
        return Colors.orange;
      default:
        return Colors.black54;
    }
  }

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      notificationsStream = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .collection("notifications")
          .orderBy("createdAt", descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("الإشعارات"),
          backgroundColor: Colors.greenAccent[200],
        ),
        body: const Center(child: Text("لا يوجد مستخدم مسجل دخول")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("الإشعارات"),
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
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade700
            : Colors.grey.shade900,
        actions: [
          IconButton(
            onPressed: () async {
              if (isEmpty) {
                interfaces.showFlutterToast("لا توجد إشعارات");
                return;
              }
              if (!context.mounted) return;
              final confirm = await interfaces.showConfirmationDialog(
                context,
                "سيتم حذف جميع الإشعارات، هل تريد المتابعة ؟",
              );
              if (!confirm) return;
              deleteAllNotifications();
            },
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () async {
              if (isEmpty) {
                interfaces.showFlutterToast("لا توجد إشعارات");
                return;
              }
              await markAllAsRead();
              if (!context.mounted) return;
              interfaces.showFlutterToast("تم تحديد الكل كمقروء");
            },
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: isdeleteMode
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: notificationsStream,
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
                  isEmpty = true;
                  return const Center(
                    child: Text(
                      "لا توجد إشعارات بعد",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final notifications = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title = data["title"] ?? "";
                    final body = data["body"] ?? "";
                    final type = data["type"] ?? "general";
                    final isRead = data["isRead"] ?? false;
                    final createdAt = data["createdAt"] as Timestamp?;
                    final senderId = data["senderId"] ?? "";
                    final routePath = data["routePath"] ?? "/";
                    final progress = dragProgress[doc.id] ?? 0.0;

                    return Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.endToStart,
                      resizeDuration: const Duration(milliseconds: 300),
                      movementDuration: const Duration(milliseconds: 200),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade900,
                              blurRadius: 5,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.delete, color: Colors.red.shade300),
                      ),
                      onUpdate: (details) {
                        setState(() {
                          dragProgress[doc.id] = details.progress.clamp(
                            0.0,
                            1.0,
                          );
                        });
                      },
                      onDismissed: (direction) async {
                        dragProgress.remove(doc.id);
                        await deleteNotification(doc.id);
                      },

                      child: Opacity(
                        opacity: (1 - (progress * 1.5)).clamp(0.0, 1.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (!isRead) {
                              await markAsRead(doc.id);
                            }

                            if (type == "chat") {
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatPage(otherUserId: senderId),
                                ),
                              );
                            } else if (type == "friend_request") {
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserFellowsPage(),
                                ),
                              );
                            } else if (type == "security_login") {
                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyAccount(),
                                ),
                              );
                            } else if (type == "broadcast") {
                              final targetType = data["targetType"];
                              final targetId = data["targetId"];
                              final targetName = data["targetName"];

                              if ((targetType ?? "").toString().isNotEmpty &&
                                  (targetId ?? "").toString().isNotEmpty &&
                                  (targetName ?? "").toString().isNotEmpty) {
                                if (!context.mounted) return;
                                await NotificationTargetNavigator.openTarget(
                                  context,
                                  targetType: targetType?.toString(),
                                  targetId: targetId?.toString(),
                                  targetName: targetName?.toString(),
                                );
                              } else if ((routePath ?? "")
                                  .toString()
                                  .isNotEmpty) {
                                if (!context.mounted) return;
                                await context.push(routePath);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Theme.of(context).cardColor
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade400,
                                  blurRadius: 2,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: getNotificationColor(
                                    type,
                                  ).withValues(alpha: 0.12),
                                  child: Icon(
                                    getNotificationIcon(type),
                                    color: getNotificationColor(type),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formatTime(createdAt),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void deleteAllNotifications() {
    try {
      if (currentUser == null) return;
      setState(() {
        isdeleteMode = true;
      });
      FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .collection("notifications")
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.delete();
            }
          });
      Interfaces().showFlutterToast("تم حذف جميع الاشعارات بنجاح");
      setState(() {
        isdeleteMode = false;
      });
    } on Exception catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isdeleteMode = false;
      });
      Interfaces().showFlutterToast("حدث خطأ اثناء حذف الاشعارات");
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        isdeleteMode = false;
      });
      Interfaces().showFlutterToast("حدث خطأ اثناء حذف الاشعارات");
    } finally {
      setState(() {
        isdeleteMode = false;
      });
    }
  }
}
