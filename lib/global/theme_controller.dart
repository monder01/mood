import 'package:flutter/material.dart';

ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

class ThemeController {
  ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    );
  }

  ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1E1E1E)),
    );
  }
}
