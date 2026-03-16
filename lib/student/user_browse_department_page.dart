import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/student/user_browse_courses_page.dart';

class UserBrowseDepartmentPage extends StatefulWidget {
  final String collegeId, collegeName;
  const UserBrowseDepartmentPage({
    super.key,
    required this.collegeId,
    required this.collegeName,
  });

  @override
  State<UserBrowseDepartmentPage> createState() =>
      _UserBrowseDepartmentPageState();
}

class _UserBrowseDepartmentPageState extends State<UserBrowseDepartmentPage> {
  final interfaces = Interfaces();
  late final Stream<QuerySnapshot> departmentsStream = FirebaseFirestore
      .instance
      .collection("departments")
      .where("isActive", isEqualTo: true)
      .where("collegeId", isEqualTo: widget.collegeId)
      .orderBy("DepartmentName", descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(
        context,
        title: "أقسام ${widget.collegeName}",
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: departmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد أقسام"));
          }

          var departments = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),

            itemCount: departments.length,

            itemBuilder: (context, index) {
              var department = departments[index];
              final departmentName = department["DepartmentName"] ?? "";
              final departmentImageUrl = department["DepartmentImageUrl"] ?? "";

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserBrowseCoursesPage(
                        departmentId: department.id,
                        departmentName: departmentName,
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
                      /// صورة القسم
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          departmentImageUrl,
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

                      /// اسم القسم
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Text(
                          departmentName ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      /// مؤشّر إذا كان القسم يحتوي على sections
                      if (department["haveSection"] ?? false)
                        const Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(Icons.list_alt, color: Colors.white),
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
