import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mood01/auth/presence_service.dart';
import 'package:mood01/designs/theme_controller.dart';
import 'package:mood01/firebase_options.dart';
import 'package:mood01/global/system.dart';
import 'package:mood01/notifications/firebase_notifications.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final system = System.current;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    try {
      // تهيئة Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // تحميل الثيم
      await ThemeController.loadTheme();

      // تهيئة الإشعارات
      await FirebaseNotifications.init();

      // تحميل معلومات النظام والآيات
      await system.getAppVersion();
      await system.loadActiveAyas();

      // online status start
      await PresenceService.startPresence();

      // فحص المستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      // إذا لم يوجد مستخدم مسجل دخول
      if (user == null) {
        context.go('/home');
        return;
      }

      // إذا يوجد مستخدم، نفحص هل وثيقته موجودة
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        context.go('/browse');
      } else {
        context.go('/home');
      }
    } catch (e) {
      debugPrint("Splash error: $e");

      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/ControlMon01.png",
              width: 250,
              height: 250,
            ),

            const SizedBox(height: 25),
            const CircularProgressIndicator(color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
