import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';

class Course {
  final String id = UniqueKey().toString();

  TextEditingController courseNameController = TextEditingController();
  TextEditingController courseCodeController = TextEditingController();
  TextEditingController courseDescriptionController = TextEditingController();
  TextEditingController courseUrlController = TextEditingController();
  TextEditingController courseLecturerController = TextEditingController();
  TextEditingController lecturedAtController = TextEditingController();

  String? selectedSemester;
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

  Future<void> pickYearDialog(int index) async {
    int? selectedYear;

    final currentYear =
        int.tryParse(courses[index].lecturedAtController.text.trim()) ??
        DateTime.now().year;

    await showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.greenAccent,
              onPrimary: Colors.white,
            ),
          ),
          child: AlertDialog(
            title: const Text("اختر سنة التدريس"),
            content: SizedBox(
              width: 300,
              height: 300,
              child: YearPicker(
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                selectedDate: DateTime(currentYear),
                onChanged: (DateTime dateTime) {
                  selectedYear = dateTime.year;
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );

    if (selectedYear != null && mounted) {
      setState(() {
        courses[index].lecturedAtController.text = selectedYear.toString();
      });
    }
  }

  Widget yearPickerCard(int index) {
    return TextField(
      readOnly: true,
      controller: courses[index].lecturedAtController,
      decoration: InputDecoration(
        hintText: "سنة التدريس",
        suffixIcon: IconButton(
          onPressed: () async {
            await pickYearDialog(index);
          },
          icon: const Icon(Icons.calendar_month),
        ),
      ),
    );
  }

  void removeCourse(int index) {
    if (courses.length == 1) return;

    setState(() {
      courses[index].courseNameController.dispose();
      courses[index].courseCodeController.dispose();
      courses[index].courseDescriptionController.dispose();
      courses[index].courseUrlController.dispose();
      courses[index].courseLecturerController.dispose();
      courses[index].lecturedAtController.dispose();
      courses.removeAt(index);
    });
  }

  Widget courseCard(int index) {
    return Dismissible(
      key: ValueKey(courses[index].id),
      confirmDismiss: (direction) async {
        return courses.length > 1;
      },
      onDismissed: (direction) {
        removeCourse(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: interfaces.containerDecoration(context),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            interfaces.textField01(
              label: "اسم المعلم (إختياري)",
              keyboardType: TextInputType.text,
              controller: courses[index].courseLecturerController,
            ),
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
              label: "وصف المادة (إختياري)",
              keyboardType: TextInputType.text,
              controller: courses[index].courseDescriptionController,
              maxLines: 2,
            ),
            interfaces.textField01(
              label: "رابط المادة (إختياري مؤقتا)",
              keyboardType: TextInputType.text,
              controller: courses[index].courseUrlController,
              maxLines: 2,
            ),
            Row(
              children: [
                const Text("(إختياري) : "),
                ChoiceChip(
                  selectedColor: Colors.greenAccent.withValues(alpha: 0.7),
                  label: const Text("خريف"),
                  selected: courses[index].selectedSemester == "خريف",
                  onSelected: (value) {
                    setState(() {
                      courses[index].selectedSemester = value ? "خريف" : null;
                      if (!value) {
                        courses[index].lecturedAtController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selectedColor: Colors.greenAccent.withValues(alpha: 0.7),
                  label: const Text("ربيع"),
                  selected: courses[index].selectedSemester == "ربيع",
                  onSelected: (value) {
                    setState(() {
                      courses[index].selectedSemester = value ? "ربيع" : null;
                      if (!value) {
                        courses[index].lecturedAtController.clear();
                      }
                    });
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: courses[index].selectedSemester != null
                      ? yearPickerCard(index)
                      : const SizedBox.shrink(),
                ),
              ],
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
                      const Text("المادة رقم", style: TextStyle(fontSize: 16)),
                      Text(
                        "${index + 1}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Row(
                  spacing: 10,
                  children: [
                    const Text("تفعيل/تعطيل", style: TextStyle(fontSize: 16)),
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
                        removeCourse(index);
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

    if (widget.departmentId == null || widget.departmentId!.trim().isEmpty) {
      await interfaces.showAlert(
        context,
        "المعرف المطلوب غير موجود",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    String nameId;

    if (widget.collectionName == "departments") {
      nameId = "departmentId";
    } else if (widget.collectionName == "sections") {
      nameId = "sectionId";
    } else {
      await interfaces.showAlert(
        context,
        "collectionName غير صالحة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final WriteBatch batch = firestore.batch();

      for (var course in courses) {
        String name = course.courseNameController.text.trim();
        String code = course.courseCodeController.text.trim();
        String description = course.courseDescriptionController.text.trim();
        String url = course.courseUrlController.text.trim();
        String courseLecturer = course.courseLecturerController.text.trim();
        String year = course.lecturedAtController.text.trim();
        String semester = course.selectedSemester ?? "";

        if (name.isEmpty || code.isEmpty) {
          await interfaces.showAlert(
            context,
            "هناك حقول مهمة فارغة لم يتم تعبئتها",
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        if (semester.isNotEmpty && year.isEmpty) {
          await interfaces.showAlert(
            context,
            "اختر سنة التدريس عند تحديد الفصل",
            icon: Icons.error,
            iconColor: Colors.red,
          );
          return;
        }

        if (url.isEmpty) {
          interfaces.showFlutterToast("يرجى التأكد من كتابة رابط المادة لاحقا");
        } else if (!url.startsWith("http://") && !url.startsWith("https://")) {
          url = "https://$url";
        }

        final DocumentReference<Map<String, dynamic>> doc = firestore
            .collection("courses")
            .doc();

        batch.set(doc, {
          nameId: widget.departmentId,
          "courseUrl": url,
          "courseName": name,
          "courseCode": code,
          "courseDescription": description,
          "courseLecturer": courseLecturer,
          "lecturedAt": year,
          "semester": semester,
          "isActive": course.isActive,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;

      await interfaces.showAlert(context, "تم حفظ البيانات بنجاح ✅");

      for (var c in courses) {
        c.courseNameController.dispose();
        c.courseCodeController.dispose();
        c.courseDescriptionController.dispose();
        c.courseUrlController.dispose();
        c.courseLecturerController.dispose();
        c.lecturedAtController.dispose();
      }

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
      c.courseLecturerController.dispose();
      c.lecturedAtController.dispose();
    }
    courses.clear();
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
      appBar: AppBar(title: const Text("إضافة مواد"), centerTitle: true),
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
                    "الرجاء تعبئة جميع الحقول :",
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
                  "جميع البيانات صحيحة ؟",
                  icon: Icons.info,
                  iconColor: Colors.greenAccent,
                );

                if (!confirm) return;

                await saveCourses();
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
