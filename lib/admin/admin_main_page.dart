import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/admin/addEdit/add_college_page.dart';
import 'package:mood01/admin/addEdit/add_course_page.dart';
import 'package:mood01/admin/addEdit/add_department_page.dart';
import 'package:mood01/admin/addEdit/add_section_page.dart';
import 'package:mood01/admin/addEdit/edit_college_page.dart';
import 'package:mood01/admin/addEdit/edit_course_page.dart';
import 'package:mood01/admin/addEdit/edit_department_page.dart';
import 'package:mood01/global/interfaces.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  Interfaces interfaces = Interfaces();
  String searchText = "", searchText2 = "", searchText3 = "", searchText4 = "";

  File? departmentImage;

  /// show options bottom sheet
  Future<void> showOptionsDialog(
    String id,
    String collectionName,
    String modifiedName,
    String textName, {
    bool? hasSection,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (hasSection == true || collectionName == "colleges")
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
                          builder: (context) =>
                              AddDepartmentPage(collegeId: id),
                        ),
                      );
                    } else if (collectionName == "departments") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddSectionPage(departmentId: id),
                        ),
                      );
                    }
                  },
                ),
              if (hasSection == false)
                ListTile(
                  leading: const Icon(
                    Icons.add_box_outlined,
                    color: Colors.greenAccent,
                  ),
                  title: Text("إضافة مادة جديد ل $modifiedName"),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCoursePage(
                          departmentId: id,
                          collectionName: collectionName,
                        ),
                      ),
                    );
                  },
                ),

              ListTile(
                leading: const Icon(
                  Icons.mode_edit_outline,
                  color: Colors.blueAccent,
                ),
                title: Text("تعديل بيانات $modifiedName"),
                onTap: () async {
                  if (collectionName == "colleges") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCollegePage(collegeId: id),
                      ),
                    );
                  } else if (collectionName == "departments") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditDepartmentPage(departmentId: id),
                      ),
                    );
                  }
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

  // build section tab , but it's not used
  Widget sectionTab() {
    return Padding(
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
              prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
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
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد شعب مضافة بعد"));
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
                  return const Center(child: Text("لا توجد نتائج بحث"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final data = sections[index].data() as Map<String, dynamic>;
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
                            colors: [Colors.greenAccent, Colors.white],
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
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }

                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.greenAccent,
                                            ),
                                          );
                                        },

                                    errorBuilder: (context, error, stackTrace) {
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    data["SectionName"] ?? "اسم غير معروف",
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
                                  activeTrackColor: Colors.lightBlueAccent,
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
                                        .update({"isActive": value});
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
    );
  }

  /// show courses options bottom sheet
  Future<void> showCoursesOptions(DocumentReference courseRef) async {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.greenAccent),
                title: const Text("تعديل بيانات المادة"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditCoursePage(courseRef: courseRef),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("حذف المادة"),
                onTap: () async {
                  final confirm = await interfaces.showConfirmationDialog(
                    context,
                    "هل أنت متاكد من حذف هذه المادة؟ لا يمكن استرجاعها لاحقا! ⛔",
                  );
                  if (!confirm) return;

                  /// delete course
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  try {
                    await courseRef.delete();
                  } on FirebaseException catch (e) {
                    debugPrint("Error deleting course: $e");
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
          TabBar(
            indicatorColor: Color.fromARGB(255, 90, 205, 150),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
            labelPadding: const EdgeInsets.symmetric(vertical: 5),
            tabs: [
              Tab(text: "إدارة الكليات"),
              Tab(text: "إدارة الأقسام"),
              // Tab(text: "إدارة الشعب"),
              Tab(text: "إدارة المواد"),
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
                                    childAspectRatio: 0.8,
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
                                      hasSection: data["haveSection"],
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
                // sectionTab(),
                ////////////////
                // tab 4 courses
                ////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText4 = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          label: const Text(
                            "اسم المادة",
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
                              .collectionGroup("courses")
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
                              return const Center(child: Text("لا توجد نتائج"));
                            }

                            final docs = snapshot.data!.docs.where((doc) {
                              final name = doc["courseName"]
                                  .toString()
                                  .toLowerCase();
                              final code = doc["courseCode"]
                                  .toString()
                                  .toLowerCase();

                              return name.contains(searchText4) ||
                                  code.contains(searchText4);
                            }).toList();

                            if (docs.isEmpty) {
                              return const Center(child: Text("لا توجد نتائج"));
                            }

                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 5,
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      showCoursesOptions(docs[index].reference);
                                    },
                                    title: Text(data["courseName"]),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "رمز المادة : ${data["courseCode"]}",
                                        ),
                                        Text(data["courseDescription"]),
                                      ],
                                    ),
                                    trailing: Switch(
                                      activeTrackColor: Colors.greenAccent,
                                      value: data["isActive"] ?? false,
                                      onChanged: (value) async {
                                        final confirm = await interfaces
                                            .showConfirmationDialog(
                                              context,
                                              "هل أنت متاكد من أنك تريد تغيير حالة المادة؟",
                                            );
                                        if (!confirm) return;
                                        await docs[index].reference.update({
                                          "isActive": value,
                                        });
                                      },
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
