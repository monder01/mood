import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  static StreamSubscription<DatabaseEvent>? _connectedSub;

  static Future<void> startPresence() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    final statusRef = _db.ref("status/$uid");
    final connectedRef = _db.ref(".info/connected");

    _connectedSub?.cancel();

    _connectedSub = connectedRef.onValue.listen((event) async {
      final isConnected = event.snapshot.value == true;

      if (!isConnected) return;

      await statusRef.onDisconnect().set({
        "state": "offline",
        "isOnline": false,
        "lastSeen": ServerValue.timestamp,
      });

      await statusRef.set({
        "state": "online",
        "isOnline": true,
        "lastSeen": ServerValue.timestamp,
      });
    });
  }

  static Future<void> markOfflineNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    await _db.ref("status/$uid").set({
      "state": "offline",
      "isOnline": false,
      "lastSeen": ServerValue.timestamp,
    });
  }

  static Future<void> disposePresence() async {
    await _connectedSub?.cancel();
    _connectedSub = null;
  }
}
