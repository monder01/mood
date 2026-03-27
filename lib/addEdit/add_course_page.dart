import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/designs/mini_interface.dart';

class Course {
  final String id = DateTime.now().microsecondsSinceEpoch.toString();

  final TextEditingController courseNameController = TextEditingController();
  final TextEditingController courseCodeController = TextEditingController();
  final TextEditingController courseDescriptionController =
      TextEditingController();
  final TextEditingController courseUrlController = TextEditingController();
  final TextEditingController courseLecturerController =
      TextEditingController();
  final TextEditingController lecturedAtController = TextEditingController();

  String? selectedSemester;
  bool isActive = false;

  void dispose() {
    courseNameController.dispose();
    courseCodeController.dispose();
    courseDescriptionController.dispose();
    courseUrlController.dispose();
    courseLecturerController.dispose();
    lecturedAtController.dispose();
  }
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
  final List<Course> courses = [];
  final Interfaces interfaces = Interfaces();
  final LightInterface lightInterface = LightInterface();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    courses.add(Course());
  }

  Future<void> pickYearDialog(int index) async {
    int? selectedYear;

    final currentYear =
        int.tryParse(courses[index].lecturedAtController.text.trim()) ??
        DateTime.now().year;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: Theme.of(dialogContext).colorScheme.copyWith(
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
                  Navigator.pop(dialogContext);
                },
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (selectedYear != null) {
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

  void removeCourseByObject(Course course) {
    if (courses.length == 1) {
      lightInterface.showFlutterToast("يجب أن تبقى مادة واحدة على الأقل");
      return;
    }

    setState(() {
      course.dispose();
      courses.remove(course);
    });
  }

  Future<bool> isValidUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.hasScheme && uri.host.isNotEmpty;
  }

  Widget courseCard(int index) {
    final course = courses[index];

    return Dismissible(
      key: ValueKey(course.id),
      confirmDismiss: (direction) async {
        if (courses.length == 1) {
          lightInterface.showFlutterToast("يجب أن تبقى مادة واحدة على الأقل");
          return false;
        }
        return true;
      },
      onDismissed: (direction) {
        removeCourseByObject(course);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: interfaces.containerDecoration(context),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            interfaces.textField01(
              label: "اسم المعلم (إختياري)",
              keyboardType: TextInputType.text,
              controller: course.courseLecturerController,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "اسم المادة",
              keyboardType: TextInputType.text,
              controller: course.courseNameController,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "رمز المادة",
              keyboardType: TextInputType.text,
              controller: course.courseCodeController,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "وصف المادة (إختياري)",
              keyboardType: TextInputType.text,
              controller: course.courseDescriptionController,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "رابط المادة (إختياري مؤقتا)",
              keyboardType: TextInputType.url,
              controller: course.courseUrlController,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("(إختياري) : "),
                ChoiceChip(
                  selectedColor: Colors.greenAccent.withValues(alpha: 0.7),
                  label: const Text("خريف"),
                  selected: course.selectedSemester == "خريف",
                  onSelected: (value) {
                    setState(() {
                      course.selectedSemester = value ? "خريف" : null;
                      if (!value) {
                        course.lecturedAtController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selectedColor: Colors.greenAccent.withValues(alpha: 0.7),
                  label: const Text("ربيع"),
                  selected: course.selectedSemester == "ربيع",
                  onSelected: (value) {
                    setState(() {
                      course.selectedSemester = value ? "ربيع" : null;
                      if (!value) {
                        course.lecturedAtController.clear();
                      }
                    });
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  child: course.selectedSemester != null
                      ? yearPickerCard(index)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Text("المادة رقم", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(
                        "${index + 1}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    const Text("تفعيل/تعطيل", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Switch(
                      activeTrackColor: Colors.greenAccent,
                      value: course.isActive,
                      onChanged: (value) {
                        setState(() {
                          course.isActive = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    const Text("حذف", style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        removeCourseByObject(course);
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
        "نوع الربط المحدد غير صالح",
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

      for (final course in courses) {
        final String name = course.courseNameController.text.trim();
        final String code = course.courseCodeController.text.trim();
        final String description = course.courseDescriptionController.text
            .trim();
        String url = course.courseUrlController.text.trim();
        final String courseLecturer = course.courseLecturerController.text
            .trim();
        final String year = course.lecturedAtController.text.trim();
        final String semester = course.selectedSemester ?? "";

        if (name.isEmpty || code.isEmpty) {
          lightInterface.showFlutterToast(
            "يرجى التأكد من كتابة الاسم رمز المادة",
          );
          return;
        }

        if (semester.isNotEmpty && year.isEmpty) {
          lightInterface.showFlutterToast("اختر سنة التدريس عند تحديد الفصل");
          return;
        }

        if (url.isEmpty) {
          lightInterface.showFlutterToast(
            "يرجى التأكد من كتابة رابط المادة لاحقًا",
          );
        } else {
          if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "https://$url";
          }

          final validUrl = await isValidUrl(url);
          if (!validUrl) {
            lightInterface.showFlutterToast("رابط المادة غير صالح");
            return;
          }
        }

        final doc = firestore.collection("courses").doc();

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

      for (final c in courses) {
        c.dispose();
      }
      courses.clear();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      await interfaces.showAlert(
        context,
        "حدث خطأ أثناء الحفظ ❌",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in courses) {
      c.dispose();
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
      appBar: interfaces.showAppBar(
        context,
        title: "إضافة مواد",
        actions: false,
      ),
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
