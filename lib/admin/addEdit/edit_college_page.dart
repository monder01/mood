import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/global/interfaces.dart';

class EditCollegePage extends StatefulWidget {
  final String collegeId;

  const EditCollegePage({super.key, required this.collegeId});

  @override
  State<EditCollegePage> createState() => _EditCollegePageState();
}

class _EditCollegePageState extends State<EditCollegePage> {
  final Interfaces interfaces = Interfaces();
  final TextEditingController collegeNameController = TextEditingController();

  File? localImage;
  String? currentImageUrl;
  String? selectedUniversity;

  bool isActive = true;
  bool loadingCollege = false;
  bool loadingImage = false;
  bool loadingData = true;

  Future<void> loadCollegeData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("colleges")
          .doc(widget.collegeId)
          .get();

      if (!snapshot.exists) {
        if (!mounted) return;
        interfaces.showAlert(
          context,
          "الكلية غير موجودة",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        Navigator.pop(context);
        return;
      }

      final data = snapshot.data()!;

      String collegeName = data["CollegeName"]?.toString() ?? "";

      if (collegeName.startsWith("كلية ")) {
        collegeName = collegeName.replaceFirst("كلية ", "");
      }

      collegeNameController.text = collegeName;
      selectedUniversity = data["University"]?.toString();
      currentImageUrl = data["CollegeImageUrl"]?.toString();
      isActive = data["isActive"] ?? true;
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء تحميل بيانات الكلية",
        icon: Icons.error,
        iconColor: Colors.red,
      );
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

  Future<void> updateCollege() async {
    try {
      if (collegeNameController.text.trim().isEmpty ||
          selectedUniversity == null) {
        interfaces.showAlert(
          context,
          "الرجاء تعبئة جميع الحقول المطلوبة",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      setState(() {
        loadingCollege = true;
      });

      String imageUrl = currentImageUrl ?? "";

      if (localImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("colleges")
            .child("${widget.collegeId}.jpg");

        await ref.putFile(localImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection("colleges")
          .doc(widget.collegeId)
          .update({
            "CollegeName": "كلية ${collegeNameController.text.trim()}",
            "University": selectedUniversity,
            "CollegeImageUrl": imageUrl,
            "isActive": isActive,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      interfaces.showAlert(
        context,
        "تم تعديل الكلية بنجاح",
        icon: Icons.done,
        iconColor: Colors.green,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء تعديل الكلية",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      debugPrint("updateCollege error: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingCollege = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadCollegeData();
  }

  @override
  void dispose() {
    collegeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تعديل الكلية")),
      body: loadingData
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "يمكنك تعديل بيانات الكلية التالية :",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  interfaces.textField01(
                    label: "اسم الكلية",
                    keyboardType: TextInputType.text,
                    controller: collegeNameController,
                    icon: Icons.school,
                    iconColor: Colors.greenAccent,
                  ),
                  const SizedBox(height: 15),

                  DropdownMenu(
                    hintText: "اختر الجامعة",
                    initialSelection: selectedUniversity,
                    width: double.infinity,
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        gapPadding: 10,
                      ),
                    ),
                    menuStyle: MenuStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      elevation: WidgetStateProperty.all(5),
                    ),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: "طرابلس", label: "جامعة طرابلس"),
                      DropdownMenuEntry(value: "بنغازي", label: "جامعة بنغازي"),
                    ],
                    onSelected: (v) {
                      setState(() {
                        selectedUniversity = v;
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: loadingImage
                        ? null
                        : () async {
                            setState(() {
                              loadingImage = true;
                            });
                            await pickImage();
                            if (mounted) {
                              setState(() {
                                loadingImage = false;
                              });
                            }
                          },
                    child: Container(
                      height: 250,
                      width: 400,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                        image: localImage != null
                            ? DecorationImage(
                                image: FileImage(localImage!),
                                fit: BoxFit.fill,
                              )
                            : (currentImageUrl != null &&
                                  currentImageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(currentImageUrl!),
                                fit: BoxFit.fill,
                              )
                            : null,
                      ),
                      child: loadingImage
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.greenAccent,
                              ),
                            )
                          : (localImage == null &&
                                (currentImageUrl == null ||
                                    currentImageUrl!.isEmpty))
                          ? const Center(child: Text("اختيار صورة"))
                          : null,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SwitchListTile(
                    activeThumbColor: Colors.greenAccent.shade700,
                    activeTrackColor: Colors.greenAccent.shade100,
                    value: isActive,
                    title: const Text("تفعيل الكلية"),
                    onChanged: (v) {
                      setState(() {
                        isActive = v;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 3,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(
                          color: Colors.greenAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: loadingCollege
                        ? null
                        : () async {
                            final confirm = await interfaces.showConfirmationDialog(
                              context,
                              "هل أنت متأكد من جميع البيانات؟ سوف يتم تعديل الكلية",
                              icon: Icons.question_mark_outlined,
                            );

                            if (!confirm) return;
                            await updateCollege();
                          },
                    child: loadingCollege
                        ? const CircularProgressIndicator(
                            color: Colors.greenAccent,
                          )
                        : const Text(
                            "تعديل الكلية",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
