import 'package:flutter/material.dart';
import 'package:mood01/navi_go.dart';
import 'package:mood01/global/theme_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
