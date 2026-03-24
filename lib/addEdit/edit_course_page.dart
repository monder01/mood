import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';

class EditCoursePage extends StatefulWidget {
  final DocumentReference courseRef;

  const EditCoursePage({super.key, required this.courseRef});

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final Interfaces interfaces = Interfaces();

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
  bool isLoadingData = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadCourseData();
  }

  Future<void> loadCourseData() async {
    try {
      final snapshot = await widget.courseRef.get();

      if (!snapshot.exists) {
        if (!mounted) return;
        await interfaces.showAlert(
          context,
          "المادة غير موجودة",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      courseNameController.text = data["courseName"]?.toString() ?? "";
      courseCodeController.text = data["courseCode"]?.toString() ?? "";
      courseDescriptionController.text =
          data["courseDescription"]?.toString() ?? "";
      courseUrlController.text = data["courseUrl"]?.toString() ?? "";
      courseLecturerController.text = data["courseLecturer"]?.toString() ?? "";
      lecturedAtController.text = data["lecturedAt"]?.toString() ?? "";
      selectedSemester = data["semester"]?.toString().trim().isEmpty == true
          ? null
          : data["semester"]?.toString();
      isActive = data["isActive"] ?? false;
    } catch (e) {
      if (!mounted) return;
      await interfaces.showAlert(
        context,
        "حدث خطأ أثناء تحميل بيانات المادة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingData = false;
        });
      }
    }
  }

  Future<void> pickYearDialog() async {
    int? selectedYear;

    final currentYear =
        int.tryParse(lecturedAtController.text.trim()) ?? DateTime.now().year;

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
        lecturedAtController.text = selectedYear.toString();
      });
    }
  }

  Widget yearPickerCard() {
    return TextField(
      readOnly: true,
      controller: lecturedAtController,
      decoration: InputDecoration(
        hintText: "سنة التدريس",
        suffixIcon: IconButton(
          onPressed: () async {
            await pickYearDialog();
          },
          icon: const Icon(Icons.calendar_month),
        ),
      ),
    );
  }

  Future<bool> isValidUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<void> updateCourse() async {
    if (isSaving) return;

    String name = courseNameController.text.trim();
    String code = courseCodeController.text.trim();
    String description = courseDescriptionController.text.trim();
    String url = courseUrlController.text.trim();
    String courseLecturer = courseLecturerController.text.trim();
    String year = lecturedAtController.text.trim();
    String semester = selectedSemester ?? "";

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

    if (semester.isEmpty) {
      year = "";
    }

    if (url.isEmpty) {
      interfaces.showFlutterToast("يرجى التأكد من كتابة رابط المادة لاحقًا");
    } else {
      if (!url.startsWith("http://") && !url.startsWith("https://")) {
        url = "https://$url";
      }

      final validUrl = await isValidUrl(url);
      if (!validUrl) {
        await interfaces.showAlert(
          context,
          "رابط المادة غير صالح",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
    }

    try {
      setState(() {
        isSaving = true;
      });

      await widget.courseRef.update({
        "courseUrl": url,
        "courseName": name,
        "courseCode": code,
        "courseDescription": description,
        "courseLecturer": courseLecturer,
        "lecturedAt": year,
        "semester": semester,
        "isActive": isActive,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await interfaces.showAlert(
        context,
        "تم تعديل المادة بنجاح ✅",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      await interfaces.showAlert(
        context,
        "حدث خطأ أثناء تعديل المادة ❌",
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
    courseNameController.dispose();
    courseCodeController.dispose();
    courseDescriptionController.dispose();
    courseUrlController.dispose();
    courseLecturerController.dispose();
    lecturedAtController.dispose();
    super.dispose();
  }

  Widget courseCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: interfaces.containerDecoration(context),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          interfaces.textField01(
            label: "اسم المعلم (إختياري)",
            keyboardType: TextInputType.text,
            controller: courseLecturerController,
          ),
          const SizedBox(height: 10),
          interfaces.textField01(
            label: "اسم المادة",
            keyboardType: TextInputType.text,
            controller: courseNameController,
          ),
          const SizedBox(height: 10),
          interfaces.textField01(
            label: "رمز المادة",
            keyboardType: TextInputType.text,
            controller: courseCodeController,
          ),
          const SizedBox(height: 10),
          interfaces.textField01(
            label: "وصف المادة (إختياري)",
            keyboardType: TextInputType.text,
            controller: courseDescriptionController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          interfaces.textField01(
            label: "رابط المادة (إختياري مؤقتا)",
            keyboardType: TextInputType.url,
            controller: courseUrlController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("(إختياري) : "),
              ChoiceChip(
                selectedColor: Colors.greenAccent.withValues(alpha: 0.7),
                label: const Text("خريف"),
                selected: selectedSemester == "خريف",
                onSelected: (value) {
                  setState(() {
                    selectedSemester = value ? "خريف" : null;
                    if (!value) {
                      lecturedAtController.clear();
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                selectedColor: Colors.greenAccent.withValues(alpha: 0.7),
                label: const Text("ربيع"),
                selected: selectedSemester == "ربيع",
                onSelected: (value) {
                  setState(() {
                    selectedSemester = value ? "ربيع" : null;
                    if (!value) {
                      lecturedAtController.clear();
                    }
                  });
                },
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: selectedSemester != null
                    ? yearPickerCard()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "تفعيل/تعطيل",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 10),
              Switch(
                activeTrackColor: Colors.greenAccent,
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(
        context,
        title: "تعديل المادة ${courseCodeController.text}",
        actions: false,
      ),
      body: isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : ListView(
              padding: const EdgeInsets.all(10),
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "يمكنك تعديل بيانات المادة :",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                courseCard(),
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            interfaces.submitButton01(
              context,
              "حفظ التعديلات",
              () async {
                final confirm = await interfaces.showConfirmationDialog(
                  context,
                  "هل جميع البيانات صحيحة ؟",
                  icon: Icons.info,
                  iconColor: Colors.greenAccent,
                );
                if (!confirm) return;
                await updateCourse();
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
