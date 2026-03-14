import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    startSplash();
  }

  Future<void> startSplash() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    context.go('/authWrapper');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/icons/monther.png", width: 200, height: 200),
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
