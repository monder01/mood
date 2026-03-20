import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/global/system.dart';

class UserCommentsPage extends StatefulWidget {
  final String courseId;

  const UserCommentsPage({super.key, required this.courseId});

  @override
  State<UserCommentsPage> createState() => _UserCommentsPageState();
}

class _UserCommentsPageState extends State<UserCommentsPage> {
  final interfaces = Interfaces();

  final TextEditingController commentController = TextEditingController();

  String courseName = "";
  String courseCode = "";
  bool isSending = false;
  bool isLoadingCourse = true;

  DocumentReference<Map<String, dynamic>> get courseRef =>
      FirebaseFirestore.instance.collection("courses").doc(widget.courseId);

  CollectionReference<Map<String, dynamic>> get commentsRef =>
      courseRef.collection("comments");

  @override
  void initState() {
    super.initState();
    loadCourseInfo();
  }

  Future<void> loadCourseInfo() async {
    try {
      final snapshot = await courseRef.get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          courseName = data?["courseName"]?.toString() ?? "";
          courseCode = data?["courseCode"]?.toString() ?? "";
          isLoadingCourse = false;
        });
      } else {
        setState(() {
          isLoadingCourse = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingCourse = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل تحميل بيانات المادة: $e")));
    }
  }

  Future<void> addComment() async {
    final text = commentController.text.trim();

    if (text.isEmpty || isSending) {
      interfaces.showFlutterToast("أكتب شيئا! 😑");
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      await commentsRef.add({
        "commentedBy": FirebaseAuth.instance.currentUser?.uid,
        "comment": text,
        "createdAt": FieldValue.serverTimestamp(),
      });

      commentController.clear();

      if (!mounted) return;
      interfaces.showFlutterToast("تم إضافة التعليق", color: Colors.green);
    } catch (e) {
      if (!mounted) return;
      interfaces.showFlutterToast("فشل اضافة التعليق: $e", color: Colors.red);
    }

    if (!mounted) return;
    setState(() {
      isSending = false;
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  String get appBarTitle {
    if (courseCode.isNotEmpty && courseName.isNotEmpty) {
      return "تعليقات $courseCode";
    }
    if (courseName.isNotEmpty) {
      return "تعليقات $courseName";
    }
    return "تعليقات المادة";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(
        context,
        title: appBarTitle,
        actions: false,
      ),
      body: Column(
        children: [
          if (isLoadingCourse)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(color: Colors.greenAccent),
            ),

          if (!isLoadingCourse &&
              (courseName.isNotEmpty || courseCode.isNotEmpty))
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 40,
                child: Marquee(
                  text: System.activeAyas.isNotEmpty
                      ? System.activeAyas[0]
                      : "لا توجد آية مفعلة",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  blankSpace: 80,
                  velocity: 40,
                  pauseAfterRound: const Duration(seconds: 1),
                  startPadding: 10,
                  accelerationDuration: const Duration(milliseconds: 500),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: const Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                ),
              ),
            ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsRef
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("حدث خطأ أثناء تحميل التعليقات"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد تعليقات بعد"));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final commentedBy = data["commentedBy"]?.toString() ?? "";
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
                    final comment = data["comment"]?.toString() ?? "";
                    final Timestamp? createdAt =
                        data["createdAt"] as Timestamp?;

                    final isMe = commentedBy == uid;

                    String timeText = "";
                    if (createdAt != null) {
                      final date = createdAt.toDate();
                      timeText =
                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} "
                          "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: isMe
                            ? BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(0),
                              )
                            : BorderRadius.only(
                                topLeft: Radius.circular(0),
                                topRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isMe
                              ? Colors.greenAccent
                              : Colors.greenAccent.withValues(alpha: 0.08),
                          child: Icon(Icons.comment),
                        ),
                        title: Text(comment),
                        subtitle: timeText.isEmpty ? null : Text(timeText),
                        trailing: commentedBy == uid
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await commentsRef
                                      .doc(docs[index].id)
                                      .delete();
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: "اكتب تعليقك...",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: isSending ? null : addComment,
                        icon: const Icon(Icons.send, color: Colors.greenAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
