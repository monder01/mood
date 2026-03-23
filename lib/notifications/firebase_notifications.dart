import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'الإشعارات المهمة',
  description: 'قناة الإشعارات المهمة',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("رسالة بالخلفية: ${message.messageId}");
}

class FirebaseNotifications {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? pendingRoute;

  static Future<void> init() async {
    await _requestPermission();
    await subscribeToAllUsersTopic();
    await _initLocalNotifications();
    await _setupFirebaseHandlers();
    _listenTokenRefresh();
  }

  static Future<void> subscribeToAllUsersTopic() async {
    await _messaging.subscribeToTopic("all_users");
    debugPrint("تم الاشتراك في all_users");
  }

  static Future<void> unsubscribeFromAllUsersTopic() async {
    await _messaging.unsubscribeFromTopic("all_users");
    debugPrint("تم إلغاء الاشتراك من all_users");
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint("حالة صلاحية الإشعارات: ${settings.authorizationStatus}");

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          await _handleNotificationNavigation(data);
        } catch (e) {
          debugPrint("خطأ في قراءة payload: $e");
        }
      },
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _setupFirebaseHandlers() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      await localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? "إشعار جديد",
        body: notification.body ?? "",
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'الإشعارات المهمة',
            channelDescription: 'قناة الإشعارات المهمة',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _handleNotificationNavigation(message.data);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _handleNotificationNavigation(initialMessage.data);
    }
  }

  static Future<void> _handleNotificationNavigation(
    Map<String, dynamic> data,
  ) async {
    final type = (data["type"] ?? "").toString();
    final senderId = (data["senderId"] ?? "").toString();
    final routePath = (data["routePath"] ?? "").toString();

    final targetType = (data["targetType"] ?? "").toString();
    final targetId = (data["targetId"] ?? "").toString();
    final targetName = (data["targetName"] ?? "").toString();

    if (type == "chat" && senderId.isNotEmpty) {
      pendingRoute = "/chat/$senderId";
      return;
    }

    if (type == "friend_request") {
      pendingRoute = "/fellows";
      return;
    }

    if (type == "security_login") {
      pendingRoute = "/browse";
      return;
    }

    if (type == "broadcast") {
      if (targetType.isNotEmpty &&
          targetId.isNotEmpty &&
          targetName.isNotEmpty) {
        final safeName = Uri.encodeComponent(targetName);

        if (targetType == "collegeDepartments") {
          pendingRoute = "/departments/$targetId/$safeName";
          return;
        }

        if (targetType == "departmentCourses") {
          pendingRoute = "/courses/$targetId/$safeName";
          return;
        }
      }

      if (routePath.isNotEmpty) {
        pendingRoute = routePath;
        return;
      }
    }

    if (routePath.isNotEmpty) {
      pendingRoute = routePath;
    }
  }

  static void _listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("admins")
          .doc(user.uid)
          .update({"messageToken": newToken});

      debugPrint("تم تحديث التوكن: $newToken");
    });
  }
}
