import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

class ThemeController {
  static const String themeKey = "isDarkMode";

  // ---------------- LIGHT THEME ----------------

  ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black,
        shadowColor: Colors.grey.shade900,
        elevation: 1,
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),

      cardColor: Colors.white,

      dividerColor: Colors.grey,

      iconTheme: const IconThemeData(color: Colors.black87),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
        bodyLarge: TextStyle(color: Colors.black87),
      ),

      // Text Selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.greenAccent,
      ),

      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black54,
        indicatorColor: Colors.greenAccent,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.greenAccent.withValues(alpha: 0.5);
          }
          return Colors.grey.shade200;
        }),
      ),

      // TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),

        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.greenAccent, width: 2),
        ),

        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.red),
        ),

        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.grey),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.green),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          side: const BorderSide(color: Colors.green),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.black87,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  // ---------------- DARK THEME ----------------

  ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.green,

      scaffoldBackgroundColor: const Color(0xFF121212),

      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        shadowColor: Colors.grey.shade800,
        elevation: 1,
      ),

      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1E1E1E)),

      cardColor: const Color(0xFF1E1E1E),

      dividerColor: Colors.grey,

      iconTheme: const IconThemeData(color: Colors.white70),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        bodyLarge: TextStyle(color: Colors.white70),
      ),

      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.greenAccent,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.greenAccent.withValues(alpha: 0.5);
          }
          return Colors.grey.shade700;
        }),
      ),

      // TextField
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E1E1E),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.grey),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.grey),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.greenAccent, width: 2),
        ),

        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.grey),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.greenAccent,
          side: const BorderSide(color: Colors.greenAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF2A2A2A),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  // ---------------- LOAD THEME ----------------

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(themeKey) ?? false;
    appThemeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // ---------------- SAVE THEME ----------------

  static Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDarkMode);
    appThemeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
