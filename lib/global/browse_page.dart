import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mood01/admin/admin_user_management_page.dart';
import 'package:mood01/auth/session_service.dart';
import 'package:mood01/chats/my_conversations_page.dart';
import 'package:mood01/global/my_account.dart';
import 'package:mood01/notifications/firebase_notifications.dart';
import 'package:mood01/screens/about_us_page.dart';
import 'package:mood01/admin/admin_browse_page.dart';
import 'package:mood01/admin/admin_main_page.dart';
import 'package:mood01/auth/users.dart';
import 'package:mood01/student/discover_page.dart';
import 'package:mood01/screens/home_page.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/friends/user_fellows_page.dart';
import 'package:mood01/student/user_browse_page.dart';

class Browsepage extends StatefulWidget {
  const Browsepage({super.key});

  @override
  State<Browsepage> createState() => _BrowsepageState();
}

class _BrowsepageState extends State<Browsepage> with WidgetsBindingObserver {
  Users users = Users();
  Interfaces interfaces = Interfaces();
  bool isPhotoLoading = false;
  int currentIndex = 0, counter = 0;

  DateTime? lastBackPressed;

  List<Widget> pages = [];
  final List<Widget> userPages = const [UserBrowsePage(), DiscoverPage()];

  final List<Widget> adminPages = const [
    AdminMainPage(),
    AdminUserManagementPage(),
    AdminBrowsePage(),
  ];

  // أضف هذا المتغير في أعلى الكلاس
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;

  void startSessionMonitoring() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // استماع مباشر للتغييرات في مستند المستخدم
    _sessionSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;

          final data = snapshot.data() as Map<String, dynamic>;
          final bool isActive = data["isActive"] ?? true;
          final String? firestoreSessionId = data["activeSessionId"];

          // جلب المعرف المحلي
          final localSessionId = await SessionService.getLocalSessionId();

          if (!mounted) return;

          // 1. فحص إذا تم تعطيل الحساب
          if (isActive == false) {
            _logoutDueToIssue("تم تعطيل حسابك من قبل الإدارة");
            return;
          }

          // 2. فحص إذا تم الدخول من جهاز آخر
          if (localSessionId != null &&
              firestoreSessionId != null &&
              firestoreSessionId.isNotEmpty &&
              localSessionId != firestoreSessionId) {
            _logoutDueToIssue("تم تسجيل الدخول من جهاز آخر");
          }
        });
  }

  void _logoutDueToIssue(String message) async {
    // إيقاف المستمع أولاً لتجنب التكرار
    _sessionSubscription?.cancel();

    await setOnlineStatus(false);
    await SessionService.clearLocalSession();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // إظهار تنبيه للمستخدم والعودة للرئيسية
    interfaces.showFlutterToast(context, message);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
      (route) => false,
    );
  }

  // get user fcm
  Future<void> getFcmToken() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(firebaseUser.uid)
          .get();

      final currentToken = doc.data()?["messageToken"];

      if (currentToken != fcmToken) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUser.uid)
            .set({"messageToken": fcmToken}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("FCM token error: $e");
    }
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"isOnline": isOnline, "lastLogin": FieldValue.serverTimestamp()},
      );
    } catch (e) {
      print("Error updating online status: $e");
    }
  }

  Future<void> loadUser() async {
    final user = await users.getCurrentUser();
    if (!mounted) return;

    if (user != null) {
      setState(() {
        users = user;
        pages = users.role == "admin" ? adminPages : userPages;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
    getFcmToken();
    WidgetsBinding.instance.addObserver(this);
    setOnlineStatus(true);

    startSessionMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      setOnlineStatus(false);
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    setOnlineStatus(false);
    super.dispose();
  }

  Widget drawerbutton() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.greenAccent[200]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: ClipOval(
                    child: users.photoUrl != null && users.photoUrl!.isNotEmpty
                        ? Image.network(
                            users.photoUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.person, size: 50, color: Colors.black54),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${users.name}", style: TextStyle(fontSize: 20)),
                    Text("${users.email}", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.history_edu),
            title: const Text("زملائي"),
            onTap: () {
              if (users.role == "admin") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserFellowsPage(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserFellowsPage(),
                  ),
                );
              }
            },
          ),

          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text("محادثاتي"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyConversationsPage()),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("الحساب"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyAccount()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("الإعدادات"),
            onTap: () {
              Navigator.pop(context);
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

              await setOnlineStatus(false);
              // delete fcm token
              // إلغاء الاشتراك من إشعارات الجميع
              await FirebaseNotifications.unsubscribeFromAllUsersTopic();

              final messageToken = await FirebaseMessaging.instance.getToken();
              if (messageToken != null && messageToken.isNotEmpty) {
                // update fcm token
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({"messageToken": ""});
              }
              await SessionService.clearLocalSession();
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Homepage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: (counter >= 2),
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

        SystemNavigator.pop(); // close app
      },
      child: Scaffold(
        appBar: interfaces.showAppBar(context, title: ""),
        drawer: drawerbutton(),
        body: pages.isEmpty
            ? Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
            : pages[currentIndex],

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
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "الرئيسية",
            ),
            if (users.role == "admin")
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_rounded),
                label: "التحكم",
              ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.near_me_rounded),
              label: "تصفح",
            ),
          ],
        ),
      ),
    );
  }
}
