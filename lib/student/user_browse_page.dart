import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        title: const Text("تصفح الكليات"),
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

              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(college["CollegeName"]),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              college["CollegeImageUrl"],
                              height: 200,
                              fit: BoxFit.fill,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  "الاسم: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(child: Text(college["CollegeName"])),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Text(
                                  "الجامعة: ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(child: Text(college["University"])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("اغلاق"),
                        ),
                      ],
                    ),
                  );
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserBrowseDepartmentPage(collegeId: college.id),
                    ),
                  );
                },

                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
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
                          college["CollegeImageUrl"],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
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
                              college["CollegeName"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              "جامعة ${college["University"]}",
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
