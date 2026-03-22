import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/friends/search_for_friends_page.dart';
import 'package:mood01/notifications/my_notifications_page.dart';

class Interfaces {
  bool isLoading = false;

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

  Widget threeDcontainer(
    BuildContext context,
    Color containerColor, {
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
          : null,
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
    title: Text(title),
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
    shadowColor: Colors.black54,
    actions: actions
        ? [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchForFriendsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
            ),
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

  // show toast
  void showFlutterToast(String message, {Color? color}) {
    Fluttertoast.showToast(
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color ?? Colors.grey,
      textColor: Colors.white,
      msg: message,
    );
  }

  // pick image
  Future<void> pickImage(File localImage) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    localImage = File(picked.path);
  }

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
