import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String localSessionKey = "active_session_id";

  static String createSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<void> saveSessionAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessionId = createSessionId();
    final token = await FirebaseMessaging.instance.getToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(localSessionKey, sessionId);

    await FirebaseFirestore.instance.collection("admins").doc(user.uid).update({
      "activeSessionId": sessionId,
      "messageToken": token ?? "",
      "lastLogin": FieldValue.serverTimestamp(),
    });
  }

  static Future<String?> getLocalSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(localSessionKey);
  }

  static Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(localSessionKey);
  }
}
