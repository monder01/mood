import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mood01/browse/admin_main_page.dart';
import 'package:mood01/browse/admin_system_page.dart';
import 'package:mood01/browse/admin_user_management_page.dart';
import 'package:mood01/auth/session_service.dart';
import 'package:mood01/auth/admin.dart';
import 'package:mood01/chats/coworkers_page.dart';
import 'package:mood01/designs/about_us_page.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/global/my_account.dart';
import 'package:mood01/global/setting_page.dart';
import 'package:mood01/global/system.dart';

class Browsepage extends StatefulWidget {
  const Browsepage({super.key});

  @override
  State<Browsepage> createState() => _BrowsepageState();
}

class _BrowsepageState extends State<Browsepage> with WidgetsBindingObserver {
  Admin admin = Admin();
  final interfaces = Interfaces();
  final System system = System();

  int currentIndex = 0;
  DateTime? lastBackPressed;

  final List<Widget> adminPages = const [
    AdminMainPage(),
    AdminUserManagementPage(),
    AdminSystemPage(),
  ];

  StreamSubscription<DocumentSnapshot>? _sessionSubscription;

  void startSessionMonitoring() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sessionSubscription = FirebaseFirestore.instance
        .collection("admin")
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;

          final data = snapshot.data() as Map<String, dynamic>;
          final bool isActive = data["isActive"] ?? true;
          final String? firestoreSessionId = data["activeSessionId"];

          final localSessionId = await SessionService.getLocalSessionId();

          if (!mounted) return;

          if (isActive == false) {
            await _logoutDueToIssue("تم تعطيل حسابك من قبل الإدارة");
            return;
          }

          if (localSessionId != null &&
              firestoreSessionId != null &&
              firestoreSessionId.isNotEmpty &&
              localSessionId != firestoreSessionId) {
            await _logoutDueToIssue("تم تسجيل الدخول من جهاز آخر");
          }
        });
  }

  Future<void> _logoutDueToIssue(String message) async {
    await _sessionSubscription?.cancel();
    _sessionSubscription = null;

    if (!mounted) return;
    await admin.signOut(context);

    if (!mounted) return;
    interfaces.showFlutterToast(message);
  }

  Future<void> getFcmToken() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection("admin")
          .doc(firebaseUser.uid)
          .get();

      final currentToken = doc.data()?["messageToken"];

      if (currentToken != fcmToken) {
        await FirebaseFirestore.instance
            .collection("admin")
            .doc(firebaseUser.uid)
            .set({"messageToken": fcmToken}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("FCM token error: $e");
    }
  }

  Future<void> loadUser() async {
    final user = await admin.getCurrentUser();
    if (!mounted) return;

    if (user != null) {
      setState(() {
        admin = user;
      });
    }
  }

  Future<void> loadSystemInfo() async {
    await system.getAppVersion();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadUser();
    loadSystemInfo();
    getFcmToken();
    startSessionMonitoring();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.greenAccent[200]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).cardColor,
                  radius: 40,
                  child: ClipOval(
                    child: admin.photoUrl != null && admin.photoUrl!.isNotEmpty
                        ? Image.network(
                            admin.photoUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, size: 50),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      admin.name ?? "",
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.black,
                      ),
                    ),
                    Text(
                      admin.email ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade800
                            : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text("تواصل إداري"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoworkersPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("الحساب"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyAccount()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("الإعدادات"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("عن التطبيق"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutAppPage()),
              );
            },
          ),

          ListTile(
            leading: system.isUpdateAvailable == false
                ? const Icon(Icons.phone_android)
                : const Icon(Icons.update),
            title: system.isUpdateAvailable == false
                ? Text(
                    "الاصدار محدث : ${system.appVersion ?? ""}",
                    style: const TextStyle(color: Colors.green),
                  )
                : Text(
                    "هناك تحديث : ${system.appVersion ?? ""}",
                    style: const TextStyle(color: Colors.orange),
                  ),
            onTap: () async {
              if (system.isUpdateAvailable == false) {
                interfaces.showFlutterToast("لا يوجد تحديثات");
              } else {
                final confirm = await interfaces.showConfirmationDialog(
                  context,
                  "هل تريد تحميل التحديث الجديد؟",
                );

                if (confirm) {
                  await system.openSystemUrl();
                }
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "تسجيل الخروج",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirm = await interfaces.showConfirmationDialog(
                context,
                "سيتم تسجيل الخروج وسيتم تحويلك للصفحة الرئيسية ، هل أنت متاكد ؟",
                icon: Icons.question_mark_outlined,
              );

              if (!confirm) return;
              if (!mounted) return;

              await admin.signOut(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (lastBackPressed == null ||
            now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;
          Fluttertoast.showToast(
            msg: "اضغط مرة أخرى للخروج",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.grey.shade700,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: interfaces.showAppBar(context, title: ""),
        drawer: buildDrawer(),
        body: adminPages[currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "الرئيسية",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_rounded),
              label: "المستخدمون",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.near_me_rounded),
              label: "النظام",
            ),
          ],
        ),
      ),
    );
  }
}
