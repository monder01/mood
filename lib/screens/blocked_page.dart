import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood01/global/interfaces.dart';
import 'package:mood01/screens/home_page.dart';

class BlockedPage extends StatelessWidget {
  const BlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.greenAccent[200],
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          toolbarHeight: 50,
          shadowColor: Colors.greenAccent,
          actionsPadding: const EdgeInsets.all(10),
          actions: [
            // logout button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 3,
              ),
              onPressed: () async {
                final confirm = await Interfaces().showConfirmationDialog(
                  context,
                  "هل تريد تسجيل خروج؟",
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                );

                if (!confirm) return;

                // delete fcm token
                final messageToken = await FirebaseMessaging.instance
                    .getToken();
                if (messageToken != null && messageToken.isNotEmpty) {
                  // update fcm token
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({"messageToken": ""});
                }

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Homepage()),
                );
                Interfaces().showAlert(
                  context,
                  "تم تسجيل الخروج بنجاح",
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                );
              },
              child: const Text(
                maxLines: 1,
                "تسجيل خروج",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 90, color: Colors.redAccent),
                SizedBox(height: 20),
                Text(
                  "لقد تم تعطيل حسابك من قبل الإدارة",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  "يرجى التواصل مع الإدارة لمزيد من المعلومات",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
