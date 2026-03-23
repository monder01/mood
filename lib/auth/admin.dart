import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood01/auth/presence_service.dart';
import 'package:mood01/auth/session_service.dart';
import 'package:mood01/designs/home_page.dart';
import 'package:mood01/browse/admin_browse_page.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/notifications/firebase_notifications.dart';

class Admin {
  static Admin? currentAdmin;
  String? userName,
      email,
      name,
      firstName,
      lastName,
      password,
      phone,
      lastLogin, // last login time = last seen time
      messageToken,
      photoUrl,
      role,
      id,
      activeSessionId,
      phoneNumber;
  bool? isActive, isOnline, isPremium, isPrivate;

  Admin({
    this.id,
    this.password,
    this.firstName,
    this.lastName,
    this.lastLogin,
    this.isActive,
    this.isOnline,
    this.isPremium,
    this.isPrivate,
    this.activeSessionId,
    this.email,
    this.name,
    this.userName,
    this.photoUrl,
    this.phoneNumber,
    this.role,
    this.messageToken,
  });

  // get admin data
  factory Admin.getAdminData(DocumentSnapshot adminDoc) {
    final adminData = adminDoc.data() as Map<String, dynamic>;
    final firstName = adminData["firstName"] ?? "";
    final lastName = adminData["lastName"] ?? "";
    return Admin(
      id: adminDoc.id,
      email: adminData["email"] ?? "",
      name: "$firstName $lastName",
      photoUrl: adminData["photoUrl"] ?? "",
      phoneNumber: adminData["phone"] ?? "",
      role: adminData["role"] ?? "",
      userName: adminData["userName"] ?? "",
      messageToken: adminData["messageToken"] ?? "",
      isActive: adminData["isActive"] ?? false,
      isOnline: adminData["isOnline"] ?? false,
      activeSessionId: adminData["activeSessionId"] ?? "",
      lastLogin: {adminData["lastLogin"] ?? ""}.toString(),
    );
  }

  static Future<Admin?> getOtherAdminInfo(String adminId) async {
    final doc = await FirebaseFirestore.instance
        .collection("admins")
        .doc(adminId)
        .get();
    if (!doc.exists) return null;
    return Admin.getAdminData(doc);
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
      await FirebaseFirestore.instance
          .collection("admins")
          .doc(user.uid)
          .update({
            "isOnline": true,
            "lastLogin": FieldValue.serverTimestamp(),
          });
      // get user data
      final userData = await FirebaseFirestore.instance
          .collection("admins")
          .doc(user.uid)
          .get();
      Admin.currentAdmin = Admin.getAdminData(userData);

      final name = Admin.currentAdmin!.name;

      await SessionService.saveSessionAfterLogin();

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

      // online status start
      await PresenceService.startPresence();

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

      await FirebaseFirestore.instance.collection("admins").doc(user!.uid).set({
        "uid": user.uid,
        "userName": usernameController.text.trim(),
        "firstName": firstnameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": "+218${phoneController.text.trim()}",
        "photoUrl": "",
        "isOnline": true,
        "isActive": true,
        "isPremium": false,
        "isPrivate": false,
        "messageToken": "",
        "activeSessionId": "",
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
      });

      final adminDoc = await FirebaseFirestore.instance
          .collection("admins")
          .doc(user.uid)
          .get();

      Admin.currentAdmin = Admin.getAdminData(adminDoc);

      await SessionService.saveSessionAfterLogin();

      // online status start
      await PresenceService.startPresence();

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

  // تسجيل الخروج
  Future<void> signOut(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await PresenceService.markOfflineNow();
      await PresenceService.disposePresence();

      await FirebaseNotifications.unsubscribeFromAllUsersTopic();

      if (user != null) {
        await FirebaseFirestore.instance
            .collection("admins")
            .doc(user.uid)
            .update({
              "isOnline": false,
              "lastLogin": FieldValue.serverTimestamp(),
              "messageToken": "",
            });
      }

      await SessionService.clearLocalSession();
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      Interfaces().showAlert(
        context,
        "حدث خطأ أثناء تسجيل الخروج: $e",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }
}
