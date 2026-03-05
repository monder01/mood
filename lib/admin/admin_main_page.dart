import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/admin/add_college_page.dart';
import 'package:mood01/admin/add_department_page.dart';
import 'package:mood01/admin/add_section_page.dart';
import 'package:mood01/interfaces.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  Interfaces interfaces = Interfaces();
  String searchText = "", searchText2 = "", searchText3 = "";

  File? departmentImage;

  Future<void> showOptionsDialog(
    String id,
    String collectionName,
    String modifiedName,
    String textName,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.add_box_outlined,
                  color: Colors.greenAccent,
                ),
                title: Text("إضافة $textName جديد ل $modifiedName"),
                onTap: () async {
                  Navigator.pop(context);
                  if (collectionName == "colleges") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddDepartmentPage(collegeId: id),
                      ),
                    );
                  } else if (collectionName == "departments") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSectionPage(departmentId: id),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.mode_edit_outline,
                  color: Colors.blueAccent,
                ),
                title: Text("تعديل بيانات $modifiedName"),
                onTap: () async {
                  Navigator.pop(context);
                  // await pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                ),
                title: Text("حذف $modifiedName"),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await interfaces.showConfirmationDialog(
                    context,
                    "هل أنت متاكد من حذف $modifiedName؟",
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.red,
                  );
                  if (!confirm) return;
                  try {
                    await FirebaseFirestore.instance
                        .collection(collectionName)
                        .doc(id)
                        .delete();
                  } catch (e) {
                    print("Error deleting: $e");
                    if (context.mounted) {
                      interfaces.showAlert(
                        context,
                        "حدث خطأ أثناء حذف $modifiedName : \n$e",
                        icon: Icons.error_outline,
                        iconColor: Colors.red,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color.fromARGB(255, 90, 205, 150),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
            tabs: [
              Tab(text: "إدارة الكليات"),
              Tab(text: "إدارة الأقسام"),
              Tab(text: "إدارة الشعب"),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                /////////////////
                // Tab 1 content
                /////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      interfaces.submitButton01(
                        context,
                        "إضافة كلية",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddCollegePage(),
                            ),
                          );
                        },
                        double.infinity,
                        50,
                      ),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          label: const Text(
                            "اسم الكلية",
                            style: TextStyle(color: Colors.black54),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.greenAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("colleges")
                              .orderBy("CollegeName")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                ),
                              );
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("لا توجد كليات مضافة بعد"),
                              );
                            }

                            final allColleges = snapshot.data!.docs;

                            final colleges = allColleges.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data["CollegeName"] ?? "")
                                  .toString()
                                  .toLowerCase();

                              return name.contains(searchText);
                            }).toList();
                            if (colleges.isEmpty) {
                              return const Center(
                                child: Text("لا توجد نتائج بحث"),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: colleges.length,
                              itemBuilder: (context, index) {
                                final data =
                                    colleges[index].data()
                                        as Map<String, dynamic>;
                                final id = colleges[index].id;

                                return InkWell(
                                  onTap: () async {
                                    await showOptionsDialog(
                                      id,
                                      "colleges",
                                      data["CollegeName"],
                                      "قسم",
                                    );
                                  },
                                  child: Container(
                                    height: 150,
                                    margin: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.greenAccent,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.greenAccent,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          /// الصورة مع اللودر (في الخلف)
                                          Positioned.fill(
                                            child: Hero(
                                              tag: "college_$id",
                                              child: Image.network(
                                                data["CollegeImageUrl"] ?? "",
                                                fit: BoxFit.cover,

                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }

                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: Colors
                                                                  .greenAccent,
                                                            ),
                                                      );
                                                    },

                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white,
                                                          size: 70,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),

                                          /// النص فوق الصورة
                                          Positioned(
                                            right: 12,
                                            top: 12,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    offset: Offset(0, 5),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                data["CollegeName"] ??
                                                    "اسم غير معروف",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ),

                                          /// زر التفعيل (في الأعلى)
                                          Positioned(
                                            left: 5,
                                            top: 2,
                                            child: Switch(
                                              activeThumbColor: Colors.white,
                                              activeTrackColor:
                                                  Colors.lightBlueAccent,
                                              value: data["isActive"] ?? false,
                                              onChanged: (value) async {
                                                final confirm = await interfaces
                                                    .showConfirmationDialog(
                                                      context,
                                                      "هل أنت متاكد من أنك تريد تغيير حالة التصنيف؟",
                                                    );
                                                if (!confirm) return;
                                                await FirebaseFirestore.instance
                                                    .collection("colleges")
                                                    .doc(id)
                                                    .update({
                                                      "isActive": value,
                                                    });
                                              },
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
                      ),
                    ],
                  ),
                ),
                ////////////////
                // Tab 2 content
                ////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText2 = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          label: const Text(
                            "اسم القسم",
                            style: TextStyle(color: Colors.black54),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.greenAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("departments")
                              .orderBy("DepartmentName")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                ),
                              );
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("لا توجد أقسام مضافة بعد"),
                              );
                            }

                            final allDepartments = snapshot.data!.docs;

                            final departments = allDepartments.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data["DepartmentName"] ?? "")
                                  .toString()
                                  .toLowerCase();

                              return name.contains(searchText2);
                            }).toList();
                            if (departments.isEmpty) {
                              return const Center(
                                child: Text("لا توجد نتائج بحث"),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.all(10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemCount: departments.length,
                              itemBuilder: (context, index) {
                                final data =
                                    departments[index].data()
                                        as Map<String, dynamic>;
                                final id = departments[index].id;

                                return InkWell(
                                  onTap: () async {
                                    await showOptionsDialog(
                                      id,
                                      "departments",
                                      data["DepartmentName"],
                                      "شعبة",
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        /// صورة القسم
                                        Expanded(
                                          child: Hero(
                                            tag: "department_$id",
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(26),
                                                  ),
                                              child: Image.network(
                                                data["DepartmentImageUrl"] ??
                                                    "",
                                                width: double.infinity,
                                                fit: BoxFit.fill,

                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }

                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: Colors
                                                                  .greenAccent,
                                                            ),
                                                      );
                                                    },

                                                errorBuilder: (_, _, _) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 50,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        /// اسم القسم + التفعيل
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              /// اسم القسم
                                              Expanded(
                                                child: Text(
                                                  data["DepartmentName"] ??
                                                      "اسم غير معروف",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),

                                              /// زر التفعيل
                                              Switch(
                                                activeThumbColor: Colors.white,
                                                activeTrackColor:
                                                    Colors.lightBlueAccent,
                                                value:
                                                    data["isActive"] ?? false,
                                                onChanged: (value) async {
                                                  final confirm = await interfaces
                                                      .showConfirmationDialog(
                                                        context,
                                                        "هل أنت متاكد من أنك تريد تغيير حالة التصنيف؟",
                                                      );
                                                  if (!confirm) return;

                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection("departments")
                                                      .doc(id)
                                                      .update({
                                                        "isActive": value,
                                                      });
                                                },
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
                  ),
                ),
                ////////////////
                // Tab 3 content
                ////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText3 = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          label: const Text(
                            "اسم الشعبة",
                            style: TextStyle(color: Colors.black54),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.greenAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("sections")
                              .orderBy("SectionName")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                ),
                              );
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("لا توجد شعب مضافة بعد"),
                              );
                            }

                            final allSections = snapshot.data!.docs;

                            final sections = allSections.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data["SectionName"] ?? "")
                                  .toString()
                                  .toLowerCase();

                              return name.contains(searchText3);
                            }).toList();
                            if (sections.isEmpty) {
                              return const Center(
                                child: Text("لا توجد نتائج بحث"),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: sections.length,
                              itemBuilder: (context, index) {
                                final data =
                                    sections[index].data()
                                        as Map<String, dynamic>;
                                final id = sections[index].id;

                                return InkWell(
                                  onTap: () async {
                                    await showOptionsDialog(
                                      id,
                                      "sections",
                                      data["SectionName"],
                                      "مادة",
                                    );
                                  },
                                  child: Container(
                                    height: 150,
                                    margin: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.greenAccent,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.greenAccent,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          /// الصورة مع اللودر (في الخلف)
                                          Positioned.fill(
                                            child: Hero(
                                              tag: "section_$id",
                                              child: Image.network(
                                                data["SectionImageUrl"] ?? "",
                                                fit: BoxFit.cover,

                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }

                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: Colors
                                                                  .greenAccent,
                                                            ),
                                                      );
                                                    },

                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white,
                                                          size: 70,
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),

                                          /// النص فوق الصورة
                                          Positioned(
                                            right: 12,
                                            top: 12,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    offset: Offset(0, 5),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                data["SectionName"] ??
                                                    "اسم غير معروف",
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ),

                                          /// زر التفعيل (في الأعلى)
                                          Positioned(
                                            left: 5,
                                            top: 2,
                                            child: Switch(
                                              activeThumbColor: Colors.white,
                                              activeTrackColor:
                                                  Colors.lightBlueAccent,
                                              value: data["isActive"] ?? false,
                                              onChanged: (value) async {
                                                final confirm = await interfaces
                                                    .showConfirmationDialog(
                                                      context,
                                                      "هل أنت متاكد من أنك تريد تغيير حالة التصنيف؟",
                                                    );
                                                if (!confirm) return;
                                                await FirebaseFirestore.instance
                                                    .collection("sections")
                                                    .doc(id)
                                                    .update({
                                                      "isActive": value,
                                                    });
                                              },
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
                      ),
                    ],
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
