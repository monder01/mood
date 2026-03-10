import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/auth/session_service.dart';
import 'package:mood01/global/browse_page.dart';
import 'package:mood01/screens/blocked_page.dart';
import 'package:mood01/screens/home_page.dart';

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

        // حدث خطأ
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("حدث خطأ")));
        }

        // إذا غير مسجل دخول
        if (!snapshot.hasData) {
          return const Homepage();
        }

        final user = snapshot.data!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.greenAccent),
                ),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Homepage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;

            /// إذا الحساب معطل
            if (userData["isActive"] == false) {
              return const BlockedPage();
            }

            return FutureBuilder<String?>(
              future: SessionService.getLocalSessionId(),
              builder: (context, sessionSnapshot) {
                if (sessionSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ),
                    ),
                  );
                }

                final localSessionId = sessionSnapshot.data;
                final firestoreSessionId = userData["activeSessionId"];

                /// إذا لا توجد جلسة محلية أو الجلسة لا تطابق جلسة Firestore
                if (localSessionId == null &&
                    firestoreSessionId == null &&
                    localSessionId != firestoreSessionId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await SessionService.clearLocalSession();
                    await FirebaseAuth.instance.signOut();
                  });

                  return const Scaffold(
                    body: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "تم تسجيل الدخول إلى هذا الحساب من جهاز آخر",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                /// الحساب فعال والجلسة صحيحة
                return const Browsepage();
              },
            );
          },
        );
      },
    );
  }
}
