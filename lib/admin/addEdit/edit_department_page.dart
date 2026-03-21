import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/designs/interfaces.dart';

class EditDepartmentPage extends StatefulWidget {
  final String departmentId;

  const EditDepartmentPage({super.key, required this.departmentId});

  @override
  State<EditDepartmentPage> createState() => _EditDepartmentPageState();
}

class _EditDepartmentPageState extends State<EditDepartmentPage> {
  final Interfaces interfaces = Interfaces();

  final TextEditingController departmentNameController =
      TextEditingController();

  File? localImage;
  String? currentImageUrl;

  bool haveSection = false;
  bool isActive = true;

  bool loadingData = true;
  bool loadingImage = false;
  bool loadingDepartment = false;

  String? collegeId;

  Future<void> loadDepartmentData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("departments")
          .doc(widget.departmentId)
          .get();

      if (!snapshot.exists) {
        if (!mounted) return;
        interfaces.showAlert(
          context,
          "القسم غير موجود",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        Navigator.pop(context);
        return;
      }

      final data = snapshot.data()!;

      String departmentName = data["DepartmentName"]?.toString() ?? "";
      if (departmentName.startsWith("قسم ")) {
        departmentName = departmentName.replaceFirst("قسم ", "");
      }

      departmentNameController.text = departmentName;
      currentImageUrl = data["DepartmentImageUrl"]?.toString();
      haveSection = data["haveSection"] ?? false;
      isActive = data["isActive"] ?? true;
      collegeId = data["collegeId"]?.toString();
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء تحميل بيانات القسم",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      debugPrint("loadDepartmentData error: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingData = false;
        });
      }
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      localImage = File(picked.path);
    });
  }

  Future<void> updateDepartment() async {
    try {
      final name = departmentNameController.text.trim();

      if (name.isEmpty) {
        interfaces.showAlert(
          context,
          "الرجاء إدخال اسم القسم",
          icon: Icons.warning_amber_outlined,
          iconColor: Colors.redAccent,
        );
        return;
      }

      setState(() {
        loadingDepartment = true;
      });

      String imageUrl =
          currentImageUrl ??
          "https://dummyimage.com/400x400/cccccc/000000&text=Department";

      if (localImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("departments")
            .child("${widget.departmentId}.jpg");

        await storageRef.putFile(localImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection("departments")
          .doc(widget.departmentId)
          .update({
            "collegeId": collegeId,
            "DepartmentName": "قسم $name",
            "DepartmentImageUrl": imageUrl,
            "haveSection": haveSection,
            "isActive": isActive,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      await interfaces.showAlert(
        context,
        "تم تعديل القسم بنجاح",
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      interfaces.showAlert(
        context,
        "حدث خطأ أثناء تعديل القسم",
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );

      debugPrint("updateDepartment error: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingDepartment = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadDepartmentData();
  }

  @override
  void dispose() {
    departmentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تعديل القسم"), centerTitle: true),
      body: loadingData
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "يمكنك تعديل بيانات القسم",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  interfaces.textField01(
                    label: "اسم القسم",
                    keyboardType: TextInputType.text,
                    controller: departmentNameController,
                  ),

                  const SizedBox(height: 15),

                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      color: Theme.of(context).cardColor,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "شعار القسم (اختياري) :",
                              style: TextStyle(fontSize: 18),
                            ),
                            InkWell(
                              onTap: loadingImage
                                  ? null
                                  : () async {
                                      setState(() {
                                        loadingImage = true;
                                      });
                                      await pickImage();
                                      if (!mounted) return;
                                      setState(() {
                                        loadingImage = false;
                                      });
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
                                child: loadingImage
                                    ? const Center(
                                        child: SizedBox(
                                          height: 30,
                                          width: 30,
                                          child: CircularProgressIndicator(
                                            color: Colors.greenAccent,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : localImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.file(
                                          localImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : (currentImageUrl != null &&
                                          currentImageUrl!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          currentImageUrl!,
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

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "القسم يحتوي على شعب ؟",
                              style: TextStyle(fontSize: 18),
                            ),
                            Switch(
                              value: haveSection,
                              onChanged: (value) {
                                setState(() {
                                  haveSection = value;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "تفعيل القسم",
                              style: TextStyle(fontSize: 18),
                            ),
                            Switch(
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
                  ),

                  const SizedBox(height: 20),

                  interfaces.submitButton01(
                    context,
                    "حفظ التعديلات",
                    () async {
                      final confirm = await interfaces.showConfirmationDialog(
                        context,
                        "هل أنت متأكد من جميع بيانات القسم ؟",
                        icon: Icons.warning_amber_outlined,
                        iconColor: Colors.redAccent,
                      );

                      if (!confirm) return;
                      await updateDepartment();
                    },
                    double.infinity,
                    50,
                  ),
                ],
              ),
            ),
    );
  }
}
