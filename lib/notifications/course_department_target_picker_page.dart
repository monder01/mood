import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/global/interfaces.dart';

class CourseDepartmentTargetPickerPage extends StatefulWidget {
  const CourseDepartmentTargetPickerPage({super.key});

  @override
  State<CourseDepartmentTargetPickerPage> createState() =>
      _CourseDepartmentTargetPickerPageState();
}

class _CourseDepartmentTargetPickerPageState
    extends State<CourseDepartmentTargetPickerPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final interfaces = Interfaces();
  String collegeSearch = "";
  String departmentSearch = "";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
      ),
    );
  }

  Widget buildCollegesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: inputStyle("ابحث عن كلية"),
            onChanged: (value) {
              setState(() {
                collegeSearch = value.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("colleges")
                .where("isActive", isEqualTo: true)
                .orderBy("CollegeName")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("لا توجد كليات"));
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final collegeName = (data["CollegeName"] ?? "")
                    .toString()
                    .toLowerCase();
                return collegeName.contains(collegeSearch);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("لا توجد نتائج"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final collegeName = (data["CollegeName"] ?? "").toString();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.school,
                        color: Colors.greenAccent,
                      ),
                      title: Text(collegeName),
                      subtitle: Text("يفتح الأقسام الخاصة بهذه الكلية"),
                      onTap: () {
                        Navigator.pop(context, {
                          "targetType": "collegeDepartments",
                          "targetId": doc.id,
                          "targetName": collegeName,
                        });
                      },
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

  Widget buildDepartmentsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: inputStyle("ابحث عن قسم"),
            onChanged: (value) {
              setState(() {
                departmentSearch = value.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("departments")
                .where("isActive", isEqualTo: true)
                .orderBy("DepartmentName")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("لا توجد أقسام"));
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final departmentName = (data["DepartmentName"] ?? "")
                    .toString()
                    .toLowerCase();
                return departmentName.contains(departmentSearch);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("لا توجد نتائج"));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final departmentName = (data["DepartmentName"] ?? "")
                      .toString();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.book_outlined,
                        color: Colors.greenAccent,
                      ),
                      title: Text(departmentName),
                      subtitle: Text("يفتح المواد الخاصة بهذا القسم"),
                      onTap: () {
                        Navigator.pop(context, {
                          "targetType": "departmentCourses",
                          "targetId": doc.id,
                          "targetName": departmentName,
                        });
                      },
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
      appBar: interfaces.showAppBar(
        context,
        title: "تحديد الهدف",
        actions: false,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              controller: tabController,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "كلية"),
                Tab(text: "قسم"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [buildCollegesTab(), buildDepartmentsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
