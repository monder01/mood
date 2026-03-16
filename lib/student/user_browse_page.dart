import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';
import 'package:mood01/global/system.dart';
import 'package:mood01/student/user_browse_department_page.dart';

class UserBrowsePage extends StatefulWidget {
  const UserBrowsePage({super.key});

  @override
  State<UserBrowsePage> createState() => _UserBrowsePageState();
}

class _UserBrowsePageState extends State<UserBrowsePage> {
  final Stream<QuerySnapshot> collegesStream = FirebaseFirestore.instance
      .collection("colleges")
      .where("isActive", isEqualTo: true)
      .orderBy("CollegeName", descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: SizedBox(
          height: 40,
          child: Marquee(
            text: System.activeAyas.isNotEmpty
                ? System.activeAyas[1]
                : "لا توجد آية مفعلة",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        automaticallyImplyLeading: false,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: collegesStream,
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
            return const Center(child: Text("لا توجد كليات"));
          }

          var colleges = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),

            itemCount: colleges.length,

            itemBuilder: (context, index) {
              var college = colleges[index];
              final data = college.data() as Map<String, dynamic>;
              final collegeName = data["CollegeName"] ?? "";
              final collegeImageUrl = data["CollegeImageUrl"] ?? "";
              final university = data["University"] ?? "";

              return InkWell(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(collegeName),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              collegeImageUrl,
                              height: 200,
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  "الاسم: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(child: Text(collegeName)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Text(
                                  "الجامعة: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(child: Text(university)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "اغلاق",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserBrowseDepartmentPage(
                        collegeId: college.id,
                        collegeName: collegeName,
                      ),
                    ),
                  );
                },

                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.black.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Stack(
                    children: [
                      /// صورة الكلية
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          collegeImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 40),
                              ),
                            );
                          },
                        ),
                      ),

                      /// طبقة تدرج فوق الصورة
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      /// اسم الكلية
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collegeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              "جامعة $university",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
