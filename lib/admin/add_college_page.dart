import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/global/interfaces.dart';

class AddCollegePage extends StatefulWidget {
  const AddCollegePage({super.key});

  @override
  State<AddCollegePage> createState() => _AddCollegePageState();
}

class _AddCollegePageState extends State<AddCollegePage> {
  Interfaces interfaces = Interfaces();
  TextEditingController collegeNameController = TextEditingController();
  File? localImage;
  bool isActive = true;
  bool loadingCollege = false, loadingImage = false;
  String? selectedUniversity;

  final List<String> items = ["جامعة طرابلس", "جامعة بنغازي"];
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() => localImage = File(picked.path));
  }

  Future<void> addCollege() async {
    try {
      if (collegeNameController.text.isEmpty ||
          selectedUniversity == null ||
          localImage == null) {
        interfaces.showAlert(
          context,
          "الرجاء تعبئة جميع الحقول واختيار صورة",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      setState(() => loadingCollege = true);

      final String id = FirebaseFirestore.instance
          .collection("colleges")
          .doc()
          .id;

      final ref = FirebaseStorage.instance
          .ref()
          .child("colleges")
          .child("$id.jpg");

      await ref.putFile(localImage!);

      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("colleges").doc(id).set({
        "CollegeId": id,
        "CollegeName": "كلية ${collegeNameController.text.trim()}",
        "University": selectedUniversity,
        "CollegeImageUrl": imageUrl,
        "isActive": isActive,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      interfaces.showAlert(
        context,
        "تم إضافة الكلية بنجاح",
        icon: Icons.done,
        iconColor: Colors.green,
      );

      collegeNameController.clear();
      setState(() {
        selectedUniversity = null;
        localImage = null;
        isActive = true;
      });
    } catch (e) {
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء إضافة الكلية",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      print(e);
    } finally {
      if (mounted) {
        setState(() => loadingCollege = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "الرجاء تعبئة جميع الحقول التالية :",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 15),
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
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                elevation: WidgetStateProperty.all(5),
              ),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: "طرابلس", label: "جامعة طرابلس"),
                DropdownMenuEntry(value: "بنغازي", label: "جامعة بنغازي"),
              ],
              onSelected: (v) => setState(() => selectedUniversity = v),
            ),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: loadingImage
                  ? null
                  : () async {
                      setState(() => loadingImage = true);
                      await pickImage();
                      setState(() => loadingImage = false);
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
                      : null,
                ),
                child: loadingImage
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                      )
                    : localImage == null
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
              onChanged: (v) => setState(() => isActive = v),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 3,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.greenAccent, width: 2),
                ),
              ),
              onPressed: loadingCollege
                  ? null
                  : () async {
                      final confirm = await interfaces.showConfirmationDialog(
                        context,
                        " هل أنت متاكد من جميع البيانات؟، سوف يتم اضافة الكلية",
                        icon: Icons.question_mark_outlined,
                      );

                      if (!confirm) return;
                      await addCollege();
                    },
              child: loadingCollege
                  ? const CircularProgressIndicator(color: Colors.greenAccent)
                  : const Text(
                      "إضافة الكلية",
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
