import 'package:flutter/material.dart';
import 'package:mood01/notifications/firebase_notifications.dart';
import 'package:mood01/navi_go.dart';
import 'package:mood01/global/theme_controller.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseNotifications.init();

  runApp(const MyApp());

  // تحميل الثيم بعد تشغيل التطبيق
  ThemeController.loadTheme();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Router ثابت حتى لا يعاد إنشاؤه
  static final router = NaviGo.router;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,

          routerConfig: router,

          title: 'Mood01',

          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          themeMode: themeMode,

          theme: ThemeController().lightTheme(),

          darkTheme: ThemeController().darkTheme(),
        );
      },
    );
  }
}
