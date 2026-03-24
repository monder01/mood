import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class System {
  static final System current = System();

  static List<String> activeAyas = [];
  String systemId = 'VSMYggbeAwkzLPP7hMJp';
  String? appVersion; // نسخة التطبيق في الجهاز
  String? systemVersion; // النسخة المطلوبة من السيرفر
  String? systemState;
  Uri? systemUpdateLink;
  Timestamp? systemUpdatedAt;
  bool isUpdateAvailable = false;

  // تفعيل او تعطيل الاية في النظام
  Future<void> toggleAyaActive(BuildContext context, String ayaId) async {
    try {
      final ayaRef = FirebaseFirestore.instance
          .collection("system")
          .doc(systemId)
          .collection("QuranVerses")
          .doc(ayaId);

      final ayaSnap = await ayaRef.get();

      if (!ayaSnap.exists) {
        if (!context.mounted) return;
        Interfaces().showFlutterToast("الآية غير موجودة");
        return;
      }

      final data = ayaSnap.data();
      final bool isActive = data?["isActive"] == true;

      if (isActive) {
        await ayaRef.update({
          "isActive": false,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        if (!context.mounted) return;
        Interfaces().showFlutterToast("تم تعطيل الآية");
        return;
      }

      final activeVerses = await FirebaseFirestore.instance
          .collection("system")
          .doc("VSMYggbeAwkzLPP7hMJp")
          .collection("QuranVerses")
          .where("isActive", isEqualTo: true)
          .get();

      if (activeVerses.docs.length >= 2) {
        if (!context.mounted) return;
        Interfaces().showFlutterToast(
          "لا يمكن تفعيل أكثر من آيتين",
          color: Colors.red,
        );
        return;
      }

      await ayaRef.update({
        "isActive": true,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      Interfaces().showFlutterToast("تم تفعيل الآية", color: Colors.green);
    } catch (e) {
      if (!context.mounted) return;
      Interfaces().showFlutterToast(
        "فشل تغيير حالة الآية: $e",
        color: Colors.red,
      );
    }
  }

  // حذف الآية من قاعدة البيانات
  Future<void> deleteAya(BuildContext context, String ayaId) async {
    try {
      await FirebaseFirestore.instance
          .collection("system")
          .doc(systemId)
          .collection("QuranVerses")
          .doc(ayaId)
          .delete();

      if (!context.mounted) return;
      Interfaces().showFlutterToast("تم حذف الآية", color: Colors.green);
    } catch (e) {
      if (!context.mounted) return;
      Interfaces().showFlutterToast("فشل حذف الآية: $e", color: Colors.red);
    }
  }

  Future<void> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();

    appVersion = info.version;
    debugPrint("App Version: $appVersion");

    final snapshot = await FirebaseFirestore.instance
        .collection('system')
        .doc(systemId)
        .get();

    if (!snapshot.exists) return;

    final data = snapshot.data()!;

    systemVersion = data['version']?.toString();
    systemState = data['state']?.toString();
    systemUpdatedAt = data['updatedAt'] as Timestamp?;

    final link = data['updateLink']?.toString();
    if (link != null && link.isNotEmpty) {
      systemUpdateLink = Uri.tryParse(link);
    } else {
      systemUpdateLink = null;
    }

    if (appVersion != null && systemVersion != null) {
      isUpdateAvailable = compareVersions(appVersion!, systemVersion!);
    }
  }

  // مقارنة النسخ
  bool compareVersions(String current, String server) {
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
