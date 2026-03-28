// reports.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mood01/designs/mini_interface.dart';

class Reports {
  static Reports? currentReports;

  // get status

  Future<bool> getStatus(String reportId, String expectedStatus) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("reports")
        .doc(reportId)
        .get();

    final data = snapshot.data();
    if (data == null) return false;

    final status = data["status"];
    return status == expectedStatus;
  }

  Future<void> updateStatusDialog(BuildContext context, String reportId) async {
    final parentContext = context;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.report_gmailerrorred, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text("تحديث حالة البلاغ")),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusTile(
                parentContext: parentContext,
                dialogContext: dialogContext,
                reportId: reportId,
                title: "قيد الانتظار",
                statusValue: "pending",
                icon: Icons.hourglass_top_rounded,
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildStatusTile(
                parentContext: parentContext,
                dialogContext: dialogContext,
                reportId: reportId,
                title: "تم الحل",
                statusValue: "resolved",
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStatusTile(
                parentContext: parentContext,
                dialogContext: dialogContext,
                reportId: reportId,
                title: "مؤجل",
                statusValue: "delayed",
                icon: Icons.schedule,
                color: Colors.red,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusTile({
    required BuildContext parentContext,
    required BuildContext dialogContext,
    required String reportId,
    required String title,
    required String statusValue,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          Navigator.pop(dialogContext);

          try {
            LightInterface.showContainerLoading(parentContext);

            if (await getStatus(reportId, statusValue) == true) {
              if (!parentContext.mounted) return;
              LightInterface.hideLoading(parentContext);
              LightInterface().showFlutterToast(
                "الحالة بالفعل $statusValue 😑 (ركز!)",
              );
              return;
            }

            await FirebaseFirestore.instance
                .collection("reports")
                .doc(reportId)
                .update({
                  "status": statusValue,
                  "updatedAt": FieldValue.serverTimestamp(),
                });

            if (!parentContext.mounted) return;
            LightInterface.hideLoading(parentContext);

            LightInterface().showFlutterToast("تم تحديث حالة البلاغ بنجاح");
          } catch (e) {
            if (!parentContext.mounted) return;
            LightInterface.hideLoading(parentContext);

            LightInterface().showFlutterToast("حدث خطأ أثناء تحديث الحالة");
          }
        },
      ),
    );
  }

  Future<void> reportDetails(
    BuildContext context,
    String description,
    String reporterName,
    String reportedName,
    String status,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.report_gmailerrorred, color: Colors.orange),
              SizedBox(width: 8),
              Text("تفاصيل البلاغ"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportItem("وصف البلاغ", description),
                const SizedBox(height: 12),
                _buildReportItem("اسم المستخدم المُبلِّغ", reporterName),
                const SizedBox(height: 12),
                _buildReportItem("اسم المستخدم المُبلَّغ عليه", reportedName),
                const SizedBox(height: 12),
                _buildStatusItem(status),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext),
              icon: const Icon(Icons.close),
              label: const Text("إغلاق"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.isEmpty ? "غير متوفر" : value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case "pending":
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case "accepted":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "rejected":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "حالة البلاغ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withAlpha(80)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> reportsOptions(
    VoidCallback? setState,
    BuildContext context,
    String reportId,
    String description,
    String reporterName,
    String reportedName,
    String status,
  ) async {
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text("تفاصيل البلاغ"),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await reportDetails(
                    context,
                    description,
                    reporterName,
                    reportedName,
                    status,
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.report_gmailerrorred),
                title: const Text("تحديث حالة البلاغ"),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await updateStatusDialog(context, reportId);
                },
              ),

              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.trashCan,
                  color: Colors.red,
                ),
                title: const Text("حذف البلاغ"),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  try {
                    LightInterface.showContainerLoading(parentContext);

                    await FirebaseFirestore.instance
                        .collection("reports")
                        .doc(reportId)
                        .delete();

                    if (!parentContext.mounted) return;
                    LightInterface.hideLoading(parentContext);

                    LightInterface().showFlutterToast("تم حذف البلاغ بنجاح");

                    setState?.call();
                  } catch (e) {
                    if (!parentContext.mounted) return;

                    LightInterface.hideLoading(parentContext);

                    LightInterface().showFlutterToast("حدث خطأ أثناء الحذف");
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
