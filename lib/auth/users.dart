import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood01/auth/session_service.dart';
import 'package:mood01/global/browse_page.dart';
import 'package:mood01/global/interfaces.dart';

class Users {
  String? id;
  String? email;
  String? name;
  String? userName;
  String? photoUrl;
  String? phoneNumber;
  String? role;
  String? messageToken;

  Users({
    this.id,
    this.email,
    this.name,
    this.userName,
    this.photoUrl,
    this.phoneNumber,
    this.role,
    this.messageToken,
  });

  // get current user data
  Future<Users?> getCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      return Users(
        id: user.uid,
        email: user.email,
        name: "${userDoc.get("firstName")} ${userDoc.get("lastName")}",
        photoUrl: userDoc.get("photoUrl") ?? "",
        phoneNumber: userDoc.get("phone") ?? "",
        role: userDoc.get("role") ?? "",
        userName: userDoc.get("userName") ?? "",
        messageToken: userDoc.get("messageToken") ?? "",
      );
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  // Sign In method
  Future<void> signIn(
    BuildContext context,
    TextEditingController emailController,
    TextEditingController passwordController,
  ) async {
    // التحقق من صحة الحقول
    if (!context.mounted) return;
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Interfaces().showAlert(
        context,
        "يرجى إدخال البريد الإلكتروني وكلمة المرور",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;

      if (!context.mounted) return;

      if (user == null) {
        Interfaces().showAlert(
          context,
          "فشل تسجيل الدخول",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      // تحديث حالة الاتصال
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"isOnline": true, "lastLogin": FieldValue.serverTimestamp()},
      );
      // get user data
      final userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      final name = "${userData.get("firstName")} ${userData.get("lastName")}";
      messageToken = await FirebaseMessaging.instance.getToken();
      if (messageToken != userData["messageToken"]) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .update({"messageToken": messageToken});
      }

      // force logout
      if (userData["isActive"] == false) {
        await FirebaseAuth.instance.signOut();

        if (!context.mounted) return;
        Interfaces().showAlert(
          context,
          "تم تعطيل حسابك من قبل الإدارة",
          icon: Icons.block,
          iconColor: Colors.red,
        );
        return;
      }

      await SessionService.saveSessionAfterLogin();

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Browsepage()),
      );
      Interfaces().showAlert(
        context,
        "مرحبا بك $name",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String? message;

      if (e.code == "user-not-found") {
        message = "لا يوجد حساب بهذا البريد الإلكتروني";
      } else if (e.code == "wrong-password") {
        message = "كلمة المرور غير صحيحة";
      } else if (e.code == "invalid-email") {
        message = "البريد الإلكتروني غير صالح";
      } else if (e.code == "user-disabled") {
        message = "هذا الحساب معطل";
      } else if (e.code == "too-many-requests") {
        message = "عدد محاولات كبير، حاول لاحقاً";
      } else if (e.code == "network-request-failed") {
        message = "تحقق من اتصال الإنترنت";
      } else if (e.code == "invalid-credential") {
        message = "بيانات الدخول غير صحيحة";
      } else {
        message = "حدث خطأ غير متوقع";
      }

      Interfaces().showAlert(
        context,
        message,
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } catch (e) {
      Interfaces().showAlert(
        context,
        "حدث خطأ غير متوقع: $e",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  // Sign Up method
  Future<void> signUp(
    BuildContext context,
    TextEditingController usernameController,
    TextEditingController firstnameController,
    TextEditingController lastNameController,
    TextEditingController emailController,
    TextEditingController phoneController,
    TextEditingController passwordController,
    TextEditingController confirmPasswordController,
  ) async {
    // التحقق من صحة الحقول
    if (usernameController.text.isEmpty ||
        firstnameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      Interfaces().showAlert(
        context,
        "يرجى ملء جميع الحقول",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // التحقق من صحة رقم الهاتف
    if (phoneController.text.length != 9) {
      Interfaces().showAlert(
        context,
        "رقم الهاتف يجب أن يكون مكون من 9 أرقام بدون أن يبدا ب 0 أو +218",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // التحقق من صحة كلمة المرور
    if (passwordController.text != confirmPasswordController.text) {
      Interfaces().showAlert(
        context,
        "كلمة المرور غير متطابقة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    // التحقق من طول كلمة المرور
    if (passwordController.text.length < 6) {
      Interfaces().showAlert(
        context,
        "كلمة المرور يجب أن تكون مكونة من 6 خانات على الأقل",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      // إنشاء حساب في Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = credential.user;
      messageToken = await FirebaseMessaging.instance.getToken();

      // حفظ بيانات المستخدم في Firestore
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "uid": user.uid,
        "userName": usernameController.text.trim(),
        "firstName": firstnameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": "+218${phoneController.text.trim()}",
        "password": passwordController.text.trim(),
        "photoUrl": "",
        "isOnline": true,
        "isActive": true,
        "messageToken": messageToken,
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
      });

      await SessionService.saveSessionAfterLogin();

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Browsepage()),
      );
      Interfaces().showAlert(
        context,
        "تم إنشاء الحساب بنجاح يمكنك الآن تصفح التطبيق \n ${usernameController.text.trim()} \n ${firstnameController.text.trim()} \n ${lastNameController.text.trim()} \n ${phoneController.text.trim()} \n ${emailController.text.trim()} \n ${passwordController.text.trim()}",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String? message;

      if (e.code == "email-already-in-use") {
        message = "البريد الإلكتروني مستخدم بالفعل";
      } else if (e.code == "invalid-email") {
        message = "البريد الإلكتروني غير صالح";
      } else if (e.code == "weak-password") {
        message = "كلمة المرور ضعيفة جداً";
      } else if (e.code == "operation-not-allowed") {
        message = "طريقة التسجيل هذه غير مفعلة في Firebase";
      } else if (e.code == "network-request-failed") {
        message = "تحقق من اتصال الإنترنت";
      } else if (e.code == "too-many-requests") {
        message = "عدد محاولات كبير، حاول لاحقاً";
      } else if (e.code == "user-disabled") {
        message = "هذا الحساب معطل";
      } else if (e.code == "invalid-credential") {
        message = "بيانات التسجيل غير صحيحة";
      } else if (e.code == "credential-already-in-use") {
        message = "بيانات الاعتماد مستخدمة مسبقاً";
      } else if (e.code == "account-exists-with-different-credential") {
        message = "الحساب موجود بطريقة تسجيل مختلفة";
      } else if (e.code == "requires-recent-login") {
        message = "يرجى تسجيل الدخول مجدداً";
      } else if (e.code == "user-token-expired") {
        message = "انتهت صلاحية الجلسة، أعد تسجيل الدخول";
      } else if (e.code == "invalid-action-code") {
        message = "رمز التحقق غير صالح";
      } else if (e.code == "expired-action-code") {
        message = "انتهت صلاحية رابط التحقق";
      } else {
        message = "حدث خطأ غير متوقع";
      }

      Interfaces().showAlert(
        context,
        message,
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } catch (e) {
      Interfaces().showAlert(
        context,
        "حدث خطأ غير متوقع : \n$e",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }
}
