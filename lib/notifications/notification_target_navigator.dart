import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationTargetNavigator {
  static Future<void> openTarget(
    BuildContext context, {
    required String? targetType,
    required String? targetId,
    required String? targetName,
  }) async {
    final type = (targetType ?? "").trim();
    final id = (targetId ?? "").trim();
    final name = (targetName ?? "").trim();

    if (type.isEmpty || id.isEmpty || name.isEmpty) return;
    if (!context.mounted) return;

    final safeName = Uri.encodeComponent(name);

    if (type == "collegeDepartments") {
      await context.push("/departments/$id/$safeName");
      return;
    }

    if (type == "departmentCourses") {
      await context.push("/courses/$id/$safeName");
      return;
    }
  }
}
