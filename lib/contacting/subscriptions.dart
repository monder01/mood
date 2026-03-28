import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/designs/mini_interface.dart';

class Subscriptions {
  final Interfaces interfaces = Interfaces();

  Future<void> subscriptionsOptions(
    BuildContext context,
    String docId,
    String userId,
  ) async {
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text("عرض بيانات المستخدم"),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await displayUserInfo(parentContext, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text("قبول الطلب"),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  try {
                    LightInterface.showContainerLoading(parentContext);

                    await approveSubscription(
                      subscriptionDocId: docId,
                      userId: userId,
                    );

                    if (!parentContext.mounted) return;
                    LightInterface.hideLoading(parentContext);
                    LightInterface().showFlutterToast("تم قبول الطلب بنجاح");
                  } catch (e) {
                    if (!parentContext.mounted) return;
                    LightInterface.hideLoading(parentContext);
                    LightInterface().showFlutterToast(
                      "حدث خطأ أثناء قبول الطلب",
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text("رفض الطلب"),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  try {
                    LightInterface.showContainerLoading(parentContext);

                    await rejectSubscription(
                      subscriptionDocId: docId,
                      userId: userId,
                    );

                    if (!parentContext.mounted) return;
                    LightInterface.hideLoading(parentContext);
                    LightInterface().showFlutterToast("تم رفض الطلب بنجاح");
                  } catch (e) {
                    if (!parentContext.mounted) return;
                    LightInterface.hideLoading(parentContext);
                    LightInterface().showFlutterToast(
                      "حدث خطأ أثناء رفض الطلب",
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> approveSubscription({
    required String subscriptionDocId,
    required String userId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final subscriptionRef = FirebaseFirestore.instance
        .collection("subscriptions")
        .doc(subscriptionDocId);

    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

    batch.update(subscriptionRef, {
      "status": "approved",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      "isPremium": true,
      "PremiumDate": FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectSubscription({
    required String subscriptionDocId,
    required String userId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final subscriptionRef = FirebaseFirestore.instance
        .collection("subscriptions")
        .doc(subscriptionDocId);

    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

    batch.update(subscriptionRef, {
      "status": "rejected",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {
      "isPremium": false,
      "PremiumDate": FieldValue.delete(),
    });

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getUserInfo({required String userId}) async {
    final userDocInfo = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();
    return userDocInfo.data();
  }

  Future<void> displayUserInfo(BuildContext context, String userId) async {
    final userInfo = await getUserInfo(userId: userId);

    if (userInfo == null) {
      LightInterface().showFlutterToast("لم يتم العثور على بيانات المستخدم");
      return;
    }

    final userName = (userInfo["userName"] ?? "غير متوفر").toString();
    final userFirstName = (userInfo["firstName"] ?? "").toString();
    final userLastName = (userInfo["lastName"] ?? "").toString();

    final fullNameText = "${userFirstName.trim()} ${userLastName.trim()}"
        .trim();
    final userFullName = fullNameText.isEmpty ? "غير متوفر" : fullNameText;

    final userPhone = (userInfo["phone"] ?? "غير متوفر").toString();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue),
            SizedBox(width: 8),
            Text("معلومات المستخدم"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.alternate_email),
                    title: const Text("اسم المستخدم"),
                    subtitle: Text(userName),
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text("الاسم الكامل"),
                    subtitle: Text(userFullName),
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: const Text("رقم الجوال"),
                    subtitle: Text(userPhone),
                    onTap: () async {
                      // call phone
                      final confirm = await interfaces.showConfirmationDialog(
                        context,
                        "هل تريد الاتصال بالمستخدم؟",
                      );

                      if (!confirm) return;

                      if (!context.mounted) return;

                      Navigator.pop(dialogContext);

                      LightInterface().callPhoneFun(
                        context,
                        phoneNumber: userPhone,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.close),
            label: const Text("إغلاق"),
          ),
        ],
      ),
    );
  }
}
