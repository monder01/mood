// reports_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mood01/contacting/reports.dart';
import 'package:mood01/designs/interfaces.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final Interfaces interfaces = Interfaces();
  final Reports reportsHelper = Reports();

  String searchText = "";
  String selectedStatus = "all";

  String getReportedTypeText(String? reportedType) {
    switch (reportedType) {
      case "comment":
        return "تعليقات";
      case "image":
        return "صورة";
      case "message":
        return "رسالة";
      default:
        return "غير معروف";
    }
  }

  FaIconData getReportedTypeIcon(String? reportedType) {
    switch (reportedType) {
      case "comment":
        return FontAwesomeIcons.scroll;
      case "image":
        return FontAwesomeIcons.image;
      default:
        return FontAwesomeIcons.message;
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case "pending":
        return Colors.orange.withValues(alpha: 0.5);
      case "resolved":
      case "accepted":
        return Colors.green.withValues(alpha: 0.5);
      case "delayed":
        return Colors.red.withValues(alpha: 0.5);
      default:
        return Colors.grey.withValues(alpha: 0.4);
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case "pending":
        return "الانتظار";
      case "resolved":
        return "محلول";
      case "delayed":
        return "مؤجل";
      default:
        return "الكل";
    }
  }

  Widget buildStatusFilterChip(String label, String value) {
    final bool isSelected = selectedStatus == value;

    return ChoiceChip(
      showCheckmark: false,
      avatar: isSelected
          ? FaIcon(FontAwesomeIcons.circleDot, color: Colors.green)
          : FaIcon(FontAwesomeIcons.circle, color: Colors.grey),
      selectedColor: Colors.greenAccent.shade100,
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedStatus = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          interfaces.buildSearchField(
            hint: "اسم المستخدم",
            onChanged: (value) {
              setState(() {
                searchText = value.trim().toLowerCase();
              });
            },
          ),

          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildStatusFilterChip("الكل", "all"),
                const SizedBox(width: 8),
                buildStatusFilterChip("الانتظار", "pending"),
                const SizedBox(width: 8),
                buildStatusFilterChip("محلول", "resolved"),
                const SizedBox(width: 8),
                buildStatusFilterChip("مؤجل", "delayed"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("reports")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot,
                  ) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("حدث خطأ أثناء تحميل البيانات"),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("لا توجد بلاغات"));
                    }

                    final allReports = snapshot.data!.docs;

                    final filteredReports = allReports.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      final reporterName = (data["reporterName"] ?? "")
                          .toString()
                          .toLowerCase();
                      final reportedName = (data["reportedName"] ?? "")
                          .toString()
                          .toLowerCase();
                      final status = (data["status"] ?? "pending")
                          .toString()
                          .toLowerCase();

                      final matchesSearch =
                          searchText.isEmpty ||
                          reporterName.contains(searchText) ||
                          reportedName.contains(searchText);

                      final matchesStatus =
                          selectedStatus == "all" || status == selectedStatus;

                      return matchesSearch && matchesStatus;
                    }).toList();

                    if (filteredReports.isEmpty) {
                      return const Center(child: Text("لا توجد نتائج مطابقة"));
                    }

                    return ListView.builder(
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final doc = filteredReports[index];
                        final report = doc.data() as Map<String, dynamic>;

                        final String reportId = doc.id;
                        final String description = (report["description"] ?? "")
                            .toString();
                        final String reportedName =
                            (report["reportedName"] ?? "غير معروف").toString();
                        final String reportedType =
                            (report["reportedType"] ?? "").toString();
                        final String reporterName =
                            (report["reporterName"] ?? "غير معروف").toString();
                        final String status = (report["status"] ?? "pending")
                            .toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: FaIcon(getReportedTypeIcon(reportedType)),
                            title: Text(
                              reportedName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  description.isEmpty
                                      ? "لا يوجد وصف"
                                      : description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "الحالة: ${getStatusText(status)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Container(
                              width: 75,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: getStatusColor(status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  getReportedTypeText(reportedType),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () {
                              reportsHelper.reportsOptions(
                                () {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                },
                                context,
                                reportId,
                                description,
                                reporterName,
                                reportedName,
                                status,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
