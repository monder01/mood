import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/browse_page.dart';
import 'package:mood01/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // أثناء التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            ),
          );
        }
        print(FirebaseAuth.instance.currentUser);
        // إذا المستخدم مسجل دخول
        if (snapshot.hasData) {
          return const Browsepage();
        }

        // إذا غير مسجل دخول
        return const Homepage();
      },
    );
  }
}
