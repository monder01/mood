import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/auth/admin.dart';
import 'package:mood01/designs/mini_interface.dart';
import 'package:mood01/notifications/my_notifications_page.dart';

class Interfaces {
  Admin get admin => Admin.currentAdmin!;

  bool isLoading = false;

  final ImagePicker picker = ImagePicker();
  bool isPhotoLoading = false;
  bool isCoverLoading = false;
  bool isPasswordLoading = false;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> displayImageDialog(BuildContext context, String imageUrl) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                height: double.infinity,
                color: Colors.black,
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 100,
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: threeDcontainer(
                  context,
                  Colors.black.withValues(alpha: 0.5),
                  iconButton: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close, size: 30, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showProfile(BuildContext context, Map<String, dynamic> userData) {
    // عرض نافذة بروفايل المستخدم بشكل ممتع وبسيط
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(60),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Container(
                          alignment: Alignment.center,
                          child: Image.network(
                            userData['photoUrl'] ?? '',
                            errorBuilder: (context, error, stackTrace) =>
                                CircleAvatar(
                                  radius: 60,
                                  child: const Icon(Icons.person, size: 60),
                                ),
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: (userData['photoUrl'] ?? '').isNotEmpty
                        ? NetworkImage(userData['photoUrl'])
                        : null,
                    child: (userData['photoUrl'] ?? '').isEmpty
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "${userData['firstName']} ${userData['lastName']}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${userData['userName']}@",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickCoverPhoto(ImageSource source, BuildContext context) async {
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'قص الصورة',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.square,
            cropStyle: CropStyle.rectangle,
          ),
          IOSUiSettings(
            title: 'قص الصورة',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      final file = File(croppedFile.path);

      if (!context.mounted) return;
      await uploadImage(file, context, isCover: true);
    } catch (e) {
      if (!context.mounted) return;
      showAlert(
        context,
        "حدث خطأ أثناء اختيار الصورة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'قص الصورة',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
            initAspectRatio: CropAspectRatioPreset.square,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'قص الصورة',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      final file = File(croppedFile.path);

      if (!context.mounted) return;
      await uploadImage(file, context, isCover: false);
    } catch (e) {
      if (!context.mounted) return;
      showAlert(
        context,
        "حدث خطأ أثناء اختيار الصورة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> uploadImage(
    File file,
    BuildContext context, {
    bool? isCover,
  }) async {
    final user = currentUser;
    if (user == null) return;

    bool loadingShown = false;

    try {
      if (context.mounted && isCover != null) {
        LightInterface.showContainerLoading(context);
        loadingShown = true;
      }

      if (isCover == false) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("admins")
            .child("${user.uid}.jpg");

        await ref.putFile(file);
        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("admins")
            .doc(user.uid)
            .update({"photoUrl": imageUrl});

        admin.photoUrl = imageUrl;
      } else if (isCover == true) {
        final ref = FirebaseStorage.instance
            .ref()
            .child("admins")
            .child("${user.uid}_cover.jpg");

        await ref.putFile(file);
        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection("admins")
            .doc(user.uid)
            .update({"coverUrl": imageUrl});

        admin.coverUrl = imageUrl;
      }

      if (loadingShown && context.mounted) {
        LightInterface.hideLoading(context);
        loadingShown = false;
      }

      if (!context.mounted) return;
      showAlert(
        context,
        "تم تحديث الصورة بنجاح",
        icon: Icons.done,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (loadingShown && context.mounted) {
        LightInterface.hideLoading(context);
        loadingShown = false;
      }

      if (!context.mounted) return;
      showAlert(
        context,
        "حدث خطأ أثناء رفع الصورة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  Widget threeDcontainer(
    BuildContext context,
    Color containerColor, {
    IconButton? iconButton,
    IconData? icon,
    Color? iconColor,
    String? assetPath,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: containerColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade900,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: icon != null
          ? Icon(icon, color: iconColor ?? Colors.white)
          : assetPath != null
          ? CircleAvatar(child: Image.asset(assetPath))
          : iconButton ?? Container(),
    );
  }

  // container decoration
  BoxDecoration containerDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.greenAccent, width: 2),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade800,
        blurRadius: 4,
        offset: Offset(0, 3),
      ),
    ],
  );
  BoxDecoration containerDecoration2(BuildContext context, {Color? color}) =>
      BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: Offset(0, 3),
          ),
        ],
      );

  // elevated button style
  ButtonStyle elevatedButtonStyle(double width, double height) =>
      ElevatedButton.styleFrom(
        elevation: 5,
        side: const BorderSide(color: Colors.greenAccent, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        minimumSize: Size(width, height),
        maximumSize: Size(width, height),
      );

  // show appbar
  AppBar showAppBar(
    BuildContext context, {
    required String title,
    bool actions = true,
  }) => AppBar(
    title: title.isEmpty
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: containerDecoration2(
              context,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.4),
            ),
            child: title.isEmpty ? null : Text(title),
          ),
    centerTitle: true,
    backgroundColor: Colors.greenAccent[200],
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    toolbarHeight: 50,
    actions: actions
        ? [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyNotificationsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications),
            ),
          ]
        : null,
  );

  // show confirmation dialog
  Future<bool> showConfirmationDialog(
    BuildContext context, // السياق المطلوب لعرض مربع الحوار
    String message, { // الرسالة التي ستظهر داخل مربع التأكيد
    IconData? icon, // الايقونة التي ستظهر داخل مربع التأكيد
    Color? iconColor,
  }) async {
    // فتح مربع حوار من نوع AlertDialog وإرجاع قيمة منطقية حسب اختيار المستخدم
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible:
          true, // السماح بإغلاق مربع الحوار عند الضغط خارجَه أو بالرجوع
      builder: (context) {
        return AlertDialog(
          elevation: 5,
          title: const Text(
            'هل أنت متأكد؟', // عنوان مربع الحوار
            textAlign: TextAlign.right, // جعل النص بمحاذاة اليمين (العربية)
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ), // جعل الخط عريضًا
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message, // عرض الرسالة المرسلة للتابع
                textAlign: TextAlign.right, // محاذاة النص لليمين
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ), // لون مميز للرسالة
              ),
              SizedBox(height: 20),
              if (icon != null) ...[Icon(icon, color: iconColor, size: 70)],
            ],
          ),
          actions: [
            TextButton(
              // زر الإلغاء
              onPressed: () =>
                  Navigator.of(context).pop(false), // إرجاع false عند الإلغاء
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            SizedBox(width: 100), // مسافة بين زري الإلغاء والتأكيد
            TextButton(
              // زر التأكيد
              onPressed: () =>
                  Navigator.of(context).pop(true), // إرجاع true عند التأكيد
              child: const Text(
                'تأكيد',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    // إذا أغلق المستخدم مربع الحوار بدون اختيار، اعتبر القيمة false
    return result ?? false;
  }

  // show alert dialog
  Future<void> showAlert(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? iconColor,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'تنبيه',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 20),
              if (icon != null) ...[Icon(icon, color: iconColor, size: 70)],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'حسناً',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // تصميم حقل النص
  Widget textField01({
    required String label,
    required TextInputType keyboardType,
    required TextEditingController controller,
    IconData? icon,
    Color? iconColor,
    int? maxLines,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: keyboardType == TextInputType.visiblePassword ? true : false,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        label: Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        suffixText: keyboardType == TextInputType.phone ? "+218 " : null,
        prefixStyle: TextStyle(fontWeight: FontWeight.bold),
        prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
      ),
    );
  }

  // تصميم حقل البحث
  Widget buildSearchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        onChanged: (value) {
          onChanged(value.toLowerCase().trim());
        },
        decoration: InputDecoration(
          hint: Text(hint, style: const TextStyle(fontSize: 16)),
          prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
          contentPadding: const EdgeInsets.all(5),
        ),
      ),
    );
  }

  // تصميم زر الإرسال
  Widget submitButton01(
    BuildContext context,
    String text,
    VoidCallback onPressed,
    double width,
    double height, {
    double? fontSize,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 5,
        minimumSize: Size(width, height),
        maximumSize: Size(width, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? CircularProgressIndicator(color: Colors.greenAccent)
          : Text(
              text,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? 22,
              ),
            ),
    );
  }
}
