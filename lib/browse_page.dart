import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/admin/admin_main_page.dart';
import 'package:mood01/auth/users.dart';
import 'package:mood01/discover_page.dart';
import 'package:mood01/home_page.dart';
import 'package:mood01/interfaces.dart';
import 'package:mood01/main_page.dart';

class Browsepage extends StatefulWidget {
  const Browsepage({super.key});

  @override
  State<Browsepage> createState() => _BrowsepageState();
}

class _BrowsepageState extends State<Browsepage> {
  Users users = Users();
  Interfaces interfaces = Interfaces();
  bool isPhotoLoading = false;
  int currentIndex = 0;

  List<Widget> pages = [];
  final List<Widget> userPages = const [MainPage(), DiscoverPage()];

  final List<Widget> adminPages = const [
    AdminMainPage(),
    Center(child: Text("Admin Panel2")),
  ];
  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    await uploadImage(file);
  }

  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    await uploadImage(file);
  }

  Future<void> uploadImage(File file) async {
    try {
      setState(() => isPhotoLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child("${user.uid}.jpg");

      await ref.putFile(file);

      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"photoUrl": imageUrl},
      );

      users.photoUrl = imageUrl;

      if (!mounted) return;
      interfaces.showAlert(
        context,
        "تم تحديث الصورة بنجاح",
        icon: Icons.done,
        iconColor: Colors.green,
      );

      setState(() {});
    } catch (e) {
      print("Error uploading image: $e");
      if (!context.mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء رفع الصورة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => isPhotoLoading = false);
      }
    }
  }

  Future<void> showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.greenAccent,
                ),
                title: const Text("التقاط صورة"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.greenAccent),
                title: const Text("اختيار من المعرض"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> loadUser() async {
    final user = await users.getCurrentUser();
    if (user != null) {
      if (!mounted) return;
      setState(() {
        users = user;
      });
    }
    if (!mounted) return;
    setState(() {});

    if (users.role == "admin") {
      pages = adminPages;
    } else {
      pages = userPages;
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
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
                InkWell(
                  onTap: () async {
                    await showImageSourceDialog();
                  },
                  child: CircleAvatar(
                    radius: 40,
                    child: ClipOval(
                      child: isPhotoLoading
                          ? CircularProgressIndicator(color: Colors.greenAccent)
                          : users.photoUrl != null && users.photoUrl!.isNotEmpty
                          ? Image.network(
                              users.photoUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.person, size: 50, color: Colors.black54),
                    ),
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
            leading: const Icon(Icons.home),
            title: const Text("الرئيسية"),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("الحساب"),
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // do something if the pop was successful
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.greenAccent[200],
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          toolbarHeight: 50,
          shadowColor: Colors.greenAccent,
          actions: [
            IconButton(
              onPressed: () {
                // Action for search button
              },
              icon: Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {
                // Action for notification button
              },
              icon: Icon(Icons.notifications),
            ),
          ],
        ),
        drawer: drawerbutton(),
        body: pages.isEmpty
            ? Center(child: CircularProgressIndicator())
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "بحث"),
          ],
        ),
      ),
    );
  }
}
