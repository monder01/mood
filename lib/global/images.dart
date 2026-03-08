import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/auth/users.dart';
import 'package:mood01/global/interfaces.dart';

class Images {
  final Function(bool) setLoading;
  final VoidCallback refresh;

  Images(this.setLoading, this.refresh);

  Future<void> pickFromGallery(
    BuildContext context,
    Users users,
    Interfaces interfaces,
  ) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);

    if (!context.mounted) return;

    await uploadImage(file, context, users, interfaces);
  }

  Future<void> pickFromCamera(
    BuildContext context,
    Users users,
    Interfaces interfaces,
  ) async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);

    if (!context.mounted) return;

    await uploadImage(file, context, users, interfaces);
  }

  Future<void> uploadImage(
    File file,
    BuildContext context,
    Users users,
    Interfaces interfaces,
  ) async {
    try {
      setLoading(true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child("${user.uid}.jpg");

      await ref.putFile(file);

      final imageUrl = await ref.getDownloadURL();
      print("Image uploaded: $imageUrl");
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"photoUrl": imageUrl},
      );

      users.photoUrl = imageUrl;

      if (!context.mounted) return;

      interfaces.showAlert(
        context,
        "تم تحديث الصورة بنجاح",
        icon: Icons.done,
        iconColor: Colors.green,
      );

      refresh();
    } catch (e) {
      print(e);

      if (!context.mounted) return;

      interfaces.showAlert(
        context,
        "حدث خطأ أثناء رفع الصورة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> showImageSourceDialog(
    BuildContext context,
    Users users,
    Interfaces interfaces,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.greenAccent,
                ),
                title: const Text("التقاط صورة"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickFromCamera(context, users, interfaces);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.greenAccent),
                title: const Text("اختيار من المعرض"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickFromGallery(context, users, interfaces);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
