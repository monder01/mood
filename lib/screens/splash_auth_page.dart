import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashAuthPage extends StatefulWidget {
  const SplashAuthPage({super.key});

  @override
  State<SplashAuthPage> createState() => _SplashAuthPageState();
}

class _SplashAuthPageState extends State<SplashAuthPage> {
  @override
  void initState() {
    super.initState();
    startApp();
  }

  Future<void> startApp() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      context.go('/home');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        context.go('/home');
        return;
      }

      context.go('/browse');
    } catch (e) {
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 90,
              color: Colors.greenAccent.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              "MOOD",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.black,
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
