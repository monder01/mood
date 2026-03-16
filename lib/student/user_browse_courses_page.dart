import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/student/user_comments_page.dart';
import 'package:url_launcher/url_launcher.dart';

class UserBrowseCoursesPage extends StatefulWidget {
  final String departmentId, departmentName;

  const UserBrowseCoursesPage({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  State<UserBrowseCoursesPage> createState() => _UserBrowseCoursesPageState();
}

class _UserBrowseCoursesPageState extends State<UserBrowseCoursesPage> {
  final interfaces = Interfaces();

  late final Stream<QuerySnapshot> coursesStream = FirebaseFirestore.instance
      .collectionGroup("courses")
      .where("departmentId", isEqualTo: widget.departmentId)
      .where("isActive", isEqualTo: true)
      .orderBy("courseCode", descending: true)
      .snapshots();

  Future<void> openCourseUrl(String cUrl) async {
    final Uri courseUrl = Uri.parse(cUrl);
    await launchUrl(courseUrl, mode: LaunchMode.externalApplication);
  }

  void showOptionsDialog(String courseUrl, String courseId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text("عرض المادة"),
                onTap: () async {
                  Navigator.pop(context);

                  if (courseUrl.isEmpty ||
                      courseUrl == "" ||
                      courseUrl == "https://") {
                    interfaces.showFlutterToast(
                      context,
                      "لم يتم إضافة ملفات لهذه المادة بعد.",
                    );
                    return;
                  }

                  await openCourseUrl(courseUrl);
                },
              ),
              ListTile(
                leading: const Icon(Icons.comment),
                title: const Text("التعليقات"),
                onTap: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserCommentsPage(courseId: courseId),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(
        context,
        title: "مواد ${widget.departmentName}",
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: coursesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text("حدث خطأ"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد مواد"));
          }

          var courses = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),

            itemCount: courses.length,

            itemBuilder: (context, index) {
              var course = courses[index];
              final courseName = course["courseName"] ?? "";
              final courseCode = course["courseCode"] ?? "";
              final courseDescription = course["courseDescription"] ?? "";
              final courseUrl = course["courseUrl"] ?? "";

              return InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => showOptionsDialog(courseUrl, course.id),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(courseName),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "رمز المادة : ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(courseCode),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(courseDescription, textAlign: TextAlign.center),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "إغلاق",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                },

                child: Card(
                  elevation: 3,
                  shadowColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.black.withValues(alpha: 0.30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: Colors.greenAccent,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                courseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                courseCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
