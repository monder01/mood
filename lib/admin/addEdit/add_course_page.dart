import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/global/interfaces.dart';

class Course {
  TextEditingController courseNameController = TextEditingController();
  TextEditingController courseCodeController = TextEditingController();
  TextEditingController courseDescriptionController = TextEditingController();
  TextEditingController courseUrlController = TextEditingController();
  bool isActive = false;
}

class AddCoursePage extends StatefulWidget {
  final String? departmentId;
  final String? collectionName;

  const AddCoursePage({
    super.key,
    required this.departmentId,
    required this.collectionName,
  });
  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  List<Course> courses = [];
  Interfaces interfaces = Interfaces();
  bool isSaving = false;

  Widget courseCard(int index) {
    return Dismissible(
      key: ValueKey(courses[index]),
      confirmDismiss: (direction) async {
        return courses.length > 1;
      },
      onDismissed: (direction) {
        if (courses.length == 1) return;
        setState(() {
          courses[index].courseNameController.dispose();
          courses[index].courseCodeController.dispose();
          courses[index].courseDescriptionController.dispose();
          courses[index].courseUrlController.dispose();
          courses.removeAt(index);
        });
      },
      child: Container(
        key: ValueKey(courses[index]),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade900,
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            interfaces.textField01(
              label: "اسم المادة",
              keyboardType: TextInputType.text,
              controller: courses[index].courseNameController,
            ),
            interfaces.textField01(
              label: "رمز المادة",
              keyboardType: TextInputType.text,
              controller: courses[index].courseCodeController,
            ),
            interfaces.textField01(
              label: "وصف المادة",
              keyboardType: TextInputType.text,
              controller: courses[index].courseDescriptionController,
              maxLines: 2,
            ),
            interfaces.textField01(
              label: "رابط المادة",
              keyboardType: TextInputType.text,
              controller: courses[index].courseUrlController,
              maxLines: 2,
            ),
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      Text("المادة رقم", style: TextStyle(fontSize: 16)),
                      Text("${index + 1}", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    Text("تفعيل/تعطيل", style: TextStyle(fontSize: 16)),
                    Switch(
                      activeTrackColor: Colors.greenAccent,
                      value: courses[index].isActive,
                      onChanged: (value) {
                        setState(() {
                          courses[index].isActive = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("حذف", style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (courses.length == 1) return;
                        setState(() {
                          courses[index].courseNameController.dispose();
                          courses[index].courseCodeController.dispose();
                          courses[index].courseDescriptionController.dispose();
                          courses[index].courseUrlController.dispose();
                          courses.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveCourses() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    String nameId = "";

    try {
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      for (var course in courses) {
        String name = course.courseNameController.text.trim();
        String code = course.courseCodeController.text.trim();
        String description = course.courseDescriptionController.text.trim();
        String url = course.courseUrlController.text.trim();

        if (name.isEmpty || code.isEmpty || description.isEmpty) {
          interfaces.showAlert(
            context,
            "هناك حقول فارغة لم يتم تعبئتها",
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        if (url.isEmpty || url == "") {
          interfaces.showFlutterToast(
            context,
            "يرجى التأكد من كتابة رابط المادة لاحقا",
          );
        }

        if (!url.contains("http://") && !url.contains("https://")) {
          url = "https://$url";
        }

        if (widget.collectionName == "departments") {
          nameId = "departmentId";
        } else if (widget.collectionName == "sections") {
          nameId = "sectionId";
        }

        DocumentReference<Map<String, dynamic>> doc = firestore
            .collection("courses")
            .doc();

        batch.set(doc, {
          nameId: widget.departmentId,
          "courseUrl": url,
          "courseName": name,
          "courseCode": code,
          "courseDescription": description,
          "isActive": course.isActive,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      await interfaces.showAlert(context, "تم حفظ البيانات بنجاح ✅");
      courses.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;
      await interfaces.showAlert(context, "حدث خطأ أثناء الحفظ ❌");
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    courses.add(Course());
  }

  @override
  void dispose() {
    for (var c in courses) {
      c.courseNameController.dispose();
      c.courseCodeController.dispose();
      c.courseDescriptionController.dispose();
      c.courseUrlController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        onPressed: () {
          setState(() {
            courses.add(Course());
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(title: Text("إضافة مواد"), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "الرجاء تعبئة جميع الحقول :",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                courseCard(index),
              ],
            );
          }

          return courseCard(index);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            interfaces.submitButton01(
              context,
              "إضافة",
              () async {
                final confirm = await interfaces.showConfirmationDialog(
                  context,
                  " جميع البيانات صحيحة ؟",
                  icon: Icons.info,
                  iconColor: Colors.greenAccent,
                );
                if (!confirm) return;
                setState(() {
                  interfaces.isLoading = true;
                });
                await saveCourses();
                setState(() {
                  interfaces.isLoading = false;
                });
              },
              200,
              50,
            ),
          ],
        ),
      ),
    );
  }
}
