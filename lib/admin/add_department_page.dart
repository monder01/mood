import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/interfaces.dart';

class DepartmentForm {
  TextEditingController nameController = TextEditingController();
  File? image;
}

class AddDepartmentPage extends StatefulWidget {
  final String? collegeId;
  const AddDepartmentPage({super.key, required this.collegeId});

  @override
  State<AddDepartmentPage> createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends State<AddDepartmentPage> {
  Interfaces interfaces = Interfaces();
  bool isLoadingPic = false;
  List<DepartmentForm> departments = [];

  @override
  void initState() {
    super.initState();
    addDepartmentField();
  }

  void addDepartmentField() {
    setState(() {
      departments.add(DepartmentForm());
    });
  }

  Future<void> pickImage(int index) async {
    setState(() {
      isLoadingPic = true;
    });
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) {
      setState(() {
        isLoadingPic = false;
      });
      return;
    }
    ;

    setState(() {
      departments[index].image = File(picked.path);
      isLoadingPic = false;
    });
  }

  @override
  void dispose() {
    for (var d in departments) {
      d.nameController.dispose();
    }
    super.dispose();
  }

  Widget departmentCard(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent, width: 2),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          interfaces.textField01(
            label: "اسم القسم",
            keyboardType: TextInputType.text,
            controller: departments[index].nameController,
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text("شعار القسم :", style: TextStyle(fontSize: 18)),

              InkWell(
                onTap: isLoadingPic
                    ? null
                    : () async {
                        await pickImage(index);
                      },
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoadingPic
                      ? Center(
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              color: Colors.greenAccent,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : departments[index].image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            departments[index].image!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.add_photo_alternate,
                          size: 35,
                          color: Colors.grey,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> saveDepartments() async {
    if (widget.collegeId == null) return;

    try {
      setState(() => interfaces.isLoading = true);
      for (var d in departments) {
        final name = d.nameController.text.trim();

        if (name.isEmpty) continue;

        String imageUrl =
            "https://dummyimage.com/400x400/cccccc/000000&text=Department";

        /// رفع الصورة إلى Firebase Storage
        if (d.image != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child("departments")
              .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

          await storageRef.putFile(d.image!);

          imageUrl = await storageRef.getDownloadURL();
        }

        /// حفظ القسم في collection مستقلة
        await FirebaseFirestore.instance.collection("departments").add({
          "collegeId": widget.collegeId, // الربط مع الكلية
          "DepartmentName": "قسم $name",
          "DepartmentImageUrl": imageUrl,
          "isActive": true,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      setState(() => interfaces.isLoading = false);
      if (!mounted) return;

      await interfaces.showAlert(
        context,
        "تم إضافة الأقسام بنجاح",
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
      // free the memory
      departments.clear();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      print("Error saving departments: $e");

      if (!mounted) return;

      interfaces.showAlert(
        context,
        "حدث خطأ أثناء حفظ الأقسام",
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة أقسام"), centerTitle: true),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        onPressed: addDepartmentField,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "يمكنك إضافة أكثر من قسم",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: departments.length,
              itemBuilder: (context, index) {
                return departmentCard(index);
              },
            ),

            const SizedBox(height: 20),

            interfaces.submitButton01(
              context,
              "حفظ الأقسام",
              saveDepartments,
              double.infinity,
              50,
            ),
          ],
        ),
      ),
    );
  }
}
