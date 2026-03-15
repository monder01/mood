import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/global/interfaces.dart';

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

  bool isActive = false;
  bool isLoadingData = true;
  bool isSaving = false;

  Future<void> loadCourseData() async {
    try {
      final snapshot = await widget.courseRef.get();

      if (!snapshot.exists) {
        if (!mounted) return;
        interfaces.showAlert(
          context,
          "المادة غير موجودة",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        Navigator.pop(context);
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;

      courseNameController.text = data["courseName"]?.toString() ?? "";
      courseCodeController.text = data["courseCode"]?.toString() ?? "";
      courseDescriptionController.text =
          data["courseDescription"]?.toString() ?? "";
      courseUrlController.text = data["courseUrl"]?.toString() ?? "";
      isActive = data["isActive"] ?? false;
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
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

  Future<void> updateCourse() async {
    if (isSaving) return;

    String name = courseNameController.text.trim();
    String code = courseCodeController.text.trim();
    String description = courseDescriptionController.text.trim();
    String url = courseUrlController.text.trim();

    if (name.isEmpty || code.isEmpty || description.isEmpty || url.isEmpty) {
      interfaces.showAlert(
        context,
        "هناك حقول فارغة لم يتم تعبئتها",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    if (!url.startsWith("http://") && !url.startsWith("https://")) {
      url = "https://$url";
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
  void initState() {
    super.initState();
    loadCourseData();
  }

  @override
  void dispose() {
    courseNameController.dispose();
    courseCodeController.dispose();
    courseDescriptionController.dispose();
    courseUrlController.dispose();
    super.dispose();
  }

  Widget courseCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent, width: 2),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            label: "وصف المادة",
            keyboardType: TextInputType.text,
            controller: courseDescriptionController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          interfaces.textField01(
            label: "رابط المادة",
            keyboardType: TextInputType.text,
            controller: courseUrlController,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "تفعيل/تعطيل",
                style: TextStyle(color: Colors.black, fontSize: 16),
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
      appBar: AppBar(title: const Text("تعديل المادة"), centerTitle: true),
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
