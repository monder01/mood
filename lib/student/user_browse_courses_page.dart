import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/friends/search_for_friends_page.dart';
import 'package:mood01/global/interfaces.dart';
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
      appBar: AppBar(
        title: Text("مواد ${widget.departmentName}"),
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
        shadowColor: Colors.greenAccent,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchForFriendsPage(),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications)),
        ],
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
                onTap: () async {
                  final confirm = await interfaces.showConfirmationDialog(
                    context,
                    "هل أنت متاكد من عرض هذه المادة؟\n سيتم توجيهك لرابط المادة.",
                  );
                  if (!confirm) return;

                  await openCourseUrl(courseUrl);
                },

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

                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
