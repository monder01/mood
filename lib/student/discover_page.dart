import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/student/user_browse_courses_page.dart';
import 'package:mood01/student/user_browse_department_page.dart';
import 'package:url_launcher/url_launcher.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String collegeSearch = "";
  String departmentSearch = "";
  String courseSearch = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> openCourseUrl(String cUrl) async {
    if (cUrl.trim().isEmpty) return;

    final Uri url = Uri.parse(cUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  InputDecoration searchDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
      ),
    );
  }

  Widget buildSearchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        onChanged: (value) {
          onChanged(value.toLowerCase().trim());
        },
        decoration: searchDecoration(hint),
      ),
    );
  }

  Widget buildCollegeTab() {
    return Column(
      children: [
        buildSearchField(
          hint: "ابحث عن كلية",
          onChanged: (value) {
            setState(() {
              collegeSearch = value;
            });
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("colleges")
                .where("isActive", isEqualTo: true)
                .snapshots(),
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

              final allColleges = snapshot.data!.docs;

              final colleges = allColleges.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final collegeName = (data["CollegeName"] ?? "")
                    .toString()
                    .toLowerCase();
                final university = (data["University"] ?? "")
                    .toString()
                    .toLowerCase();

                return collegeName.contains(collegeSearch) ||
                    university.contains(collegeSearch);
              }).toList();

              if (colleges.isEmpty) {
                return const Center(child: Text("لا توجد نتائج"));
              }

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
                  final college = colleges[index];
                  final data = college.data() as Map<String, dynamic>;

                  final collegeName = data["CollegeName"] ?? "";
                  final collegeImageUrl = data["CollegeImageUrl"] ?? "";
                  final university = data["University"] ?? "";

                  return InkWell(
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
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          final String name = collegeName.toString();
                          final String image = collegeImageUrl.toString();
                          final String uni = university.toString();

                          return AlertDialog(
                            title: Text(name.isEmpty ? "كلية" : name),
                            content: SizedBox(
                              width: 260,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (image.trim().isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          image,
                                          height: 150,
                                          width: 250,
                                          fit: BoxFit.fill,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const SizedBox(
                                                  height: 200,
                                                  width: 260,
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ),
                                      )
                                    else
                                      const SizedBox(
                                        height: 200,
                                        width: 260,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "الاسم: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            name.isEmpty ? "غير متوفر" : name,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "الجامعة: ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            uni.isEmpty ? "غير متوفرة" : uni,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text(
                                  "إغلاق",
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          );
                        },
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
        ),
      ],
    );
  }

  Widget buildDepartmentTab() {
    return Column(
      children: [
        buildSearchField(
          hint: "ابحث عن قسم",
          onChanged: (value) {
            setState(() {
              departmentSearch = value;
            });
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("departments")
                .where("isActive", isEqualTo: true)
                .snapshots(),
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
                return const Center(child: Text("لا توجد أقسام"));
              }

              final allDepartments = snapshot.data!.docs;

              final departments = allDepartments.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final departmentName = (data["DepartmentName"] ?? "")
                    .toString()
                    .toLowerCase();

                return departmentName.contains(departmentSearch);
              }).toList();

              if (departments.isEmpty) {
                return const Center(child: Text("لا توجد نتائج"));
              }

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
                  final department = departments[index];
                  final data = department.data() as Map<String, dynamic>;

                  final departmentName = data["DepartmentName"] ?? "";
                  final departmentImageUrl = data["DepartmentImageUrl"] ?? "";

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
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(departmentName),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (departmentImageUrl
                                    .toString()
                                    .trim()
                                    .isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      departmentImageUrl,
                                      height: 250,
                                      width: 250,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const SizedBox(
                                              height: 180,
                                              width: 250,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                else
                                  const SizedBox(
                                    height: 180,
                                    width: 250,
                                    child: Center(
                                      child: Icon(Icons.broken_image, size: 40),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              departmentImageUrl,
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
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Text(
                              departmentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if ((data["haveSection"] ?? false) == true)
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
        ),
      ],
    );
  }

  Widget buildCourseTab() {
    return Column(
      children: [
        buildSearchField(
          hint: "ابحث عن مادة",
          onChanged: (value) {
            setState(() {
              courseSearch = value;
            });
          },
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup("courses")
                .where("isActive", isEqualTo: true)
                .orderBy("courseCode", descending: true)
                .snapshots(),
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
                return const Center(child: Text("لا توجد مواد"));
              }

              final allCourses = snapshot.data!.docs;

              final courses = allCourses.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final courseName = (data["courseName"] ?? "")
                    .toString()
                    .toLowerCase();
                final courseCode = (data["courseCode"] ?? "")
                    .toString()
                    .toLowerCase();
                final courseDescription = (data["courseDescription"] ?? "")
                    .toString()
                    .toLowerCase();

                return courseName.contains(courseSearch) ||
                    courseCode.contains(courseSearch) ||
                    courseDescription.contains(courseSearch);
              }).toList();

              if (courses.isEmpty) {
                return const Center(child: Text("لا توجد نتائج"));
              }

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
                  final course = courses[index];
                  final data = course.data() as Map<String, dynamic>;

                  final courseName = data["courseName"] ?? "";
                  final courseCode = data["courseCode"] ?? "";
                  final courseDescription = data["courseDescription"] ?? "";
                  final courseUrl = data["courseUrl"] ?? "";

                  return InkWell(
                    onTap: () async {
                      if (courseUrl.toString().trim().isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(courseName),
                            content: const Text("لا يوجد رابط لهذه المادة"),
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
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(courseName),
                          content: const Text(
                            "هل أنت متأكد من فتح رابط هذه المادة؟",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "إلغاء",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "فتح",
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await openCourseUrl(courseUrl);
                      }
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
                                    "رمز المادة: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(child: Text(courseCode)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                courseDescription.toString().isEmpty
                                    ? "لا يوجد وصف"
                                    : courseDescription,
                                textAlign: TextAlign.start,
                              ),
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
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "📗 $courseCode",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                courseName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Color.fromARGB(255, 90, 205, 150),
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
              tabs: const [
                Tab(text: "الكليات"),
                Tab(text: "الأقسام"),
                Tab(text: "المواد"),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildCollegeTab(),
                  buildDepartmentTab(),
                  buildCourseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
