import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Interfaces {
  bool isLoading = false;

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
                  color: Colors.black,
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
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
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
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
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
    // add optional parameters for icon and icon color
    IconData? icon,
    Color? iconColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: keyboardType == TextInputType.visiblePassword ? true : false,
      decoration: InputDecoration(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        prefixText: keyboardType == TextInputType.phone ? "+218 " : null,
        prefixStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 1),
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
    double height,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 5,
        minimumSize: Size(width, height),
        maximumSize: Size(width, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: Colors.greenAccent, width: 2),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? CircularProgressIndicator(color: Colors.greenAccent)
          : Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
    );
  }
}
