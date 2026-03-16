import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mood01/global/system.dart';
import 'package:mood01/notifications/firebase_notifications.dart';
import 'package:mood01/global/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mood01/firebase_options.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final system = System();
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
    } catch (e) {
      debugPrint("Splash error: $e");
    }

    if (!mounted) return;

    context.go('/authWrapper');
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
            Image.asset("assets/icons/monther.png", width: 200, height: 200),

            const SizedBox(height: 20),

            Text(
              "MOOD",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 25),

            const CircularProgressIndicator(color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
