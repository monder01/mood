import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/designs/mini_interface.dart';
import 'package:mood01/designs/theme_controller.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final Interfaces interfaces = Interfaces();
  final LightInterface lightInterface = LightInterface();

  bool isDarkMode = false;
  bool isNotificationsEnabled = false;
  bool isProfilePrivate = false;

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget settingTile({
    required IconData leadingIcon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(leadingIcon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void showDevMessage({String? message}) {
    if (message != null && message.isNotEmpty) {
      lightInterface.showFlutterToast(message);
    } else {
      lightInterface.showFlutterToast("قيد التطوير، لن يحدث شيء الآن");
    }
  }

  @override
  void initState() {
    super.initState();
    isDarkMode = appThemeMode.value == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(
        context,
        title: "الإعدادات",
        actions: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("الإشعارات :"),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  settingTile(
                    leadingIcon: Icons.notifications_active_outlined,
                    title: "التنبيهات",
                    subtitle: isNotificationsEnabled ? "مفعلة" : "متوقفة",
                    onTap: () {
                      setState(() {
                        isNotificationsEnabled = !isNotificationsEnabled;
                      });
                      showDevMessage();
                    },
                    trailing: Switch(
                      activeTrackColor: Colors.greenAccent,
                      value: isNotificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          isNotificationsEnabled = value;
                        });
                        showDevMessage();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            sectionTitle("الخصوصية :"),
            Container(
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  settingTile(
                    leadingIcon: Icons.privacy_tip_outlined,
                    title: "خصوصية الحساب",
                    subtitle: isProfilePrivate ? "خاص" : "عام",
                    onTap: () {
                      setState(() {
                        isProfilePrivate = !isProfilePrivate;
                      });
                      lightInterface.showFlutterToast(
                        "قيد التطوير، لن يحدث شيء الآن",
                      );
                    },
                    trailing: Switch(
                      activeTrackColor: Colors.greenAccent,
                      value: isProfilePrivate,
                      onChanged: (value) {
                        setState(() {
                          isProfilePrivate = value;
                        });
                        showDevMessage();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            sectionTitle("الأمان :"),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  settingTile(
                    leadingIcon: Icons.devices_outlined,
                    title: "الأجهزة المرتبطة",
                    subtitle: "عرض الأجهزة المسجل منها الدخول",
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                    ),
                    onTap: () {
                      showDevMessage();
                    },
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            sectionTitle("المظهر :"),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  settingTile(
                    leadingIcon: isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    title: "الوضع الداكن",
                    subtitle: isDarkMode ? "مفعل" : "متوقف",
                    onTap: () async {
                      final newValue = !isDarkMode;

                      setState(() {
                        isDarkMode = newValue;
                      });

                      await ThemeController.saveTheme(newValue);
                    },
                    trailing: Switch(
                      activeTrackColor: Colors.greenAccent,
                      activeThumbColor: Colors.white,
                      value: isDarkMode,
                      onChanged: (value) async {
                        setState(() {
                          isDarkMode = value;
                        });

                        await ThemeController.saveTheme(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            sectionTitle("التطبيق :"),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  settingTile(
                    leadingIcon: Icons.support_agent_outlined,
                    title: "تواصل معنا",
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                    ),
                    onTap: () {
                      showDevMessage();
                    },
                  ),
                  settingTile(
                    leadingIcon: Icons.privacy_tip_outlined,
                    title: "سياسة الخصوصية",
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                    ),
                    onTap: () {
                      showDevMessage();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
