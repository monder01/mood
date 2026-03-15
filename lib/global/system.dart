import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class System {
  String? appVersion; // نسخة التطبيق في الجهاز
  String? systemVersion; // النسخة المطلوبة من السيرفر
  String? systemState;
  Uri? systemUpdateLink;
  Timestamp? systemUpdatedAt;
  bool isUpdateAvailable = false;

  Future<void> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();

    appVersion = info.version;
    debugPrint("App Version: $appVersion");

    final snapshot = await FirebaseFirestore.instance
        .collection('system')
        .doc('VSMYggbeAwkzLPP7hMJp')
        .get();

    if (!snapshot.exists) return;

    final data = snapshot.data()!;

    systemVersion = data['version']?.toString();
    systemState = data['state']?.toString();
    systemUpdatedAt = data['updatedAt'] as Timestamp?;

    final link = data['updateLink']?.toString();
    if (link != null && link.isNotEmpty) {
      systemUpdateLink = Uri.tryParse(link);
    }

    // فحص التحديث
    if (appVersion != null && systemVersion != null) {
      isUpdateAvailable = _compareVersions(appVersion!, systemVersion!);
    }
  }

  // مقارنة النسخ بشكل صحيح
  bool _compareVersions(String current, String server) {
    final currentParts = current.split('.').map(int.parse).toList();
    final serverParts = server.split('.').map(int.parse).toList();

    for (int i = 0; i < serverParts.length; i++) {
      if (currentParts.length <= i) return true;

      if (serverParts[i] > currentParts[i]) return true;
      if (serverParts[i] < currentParts[i]) return false;
    }

    return false;
  }

  // فتح رابط التحديث
  Future<void> openSystemUrl() async {
    final uri = systemUpdateLink;

    if (uri == null) {
      debugPrint("لا يوجد رابط تحديث");
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) {
      debugPrint("فشل فتح الرابط");
    }
  }
}
