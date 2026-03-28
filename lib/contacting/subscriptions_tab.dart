import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mood01/contacting/subscriptions.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/designs/mini_interface.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  final Interfaces interfaces = Interfaces();
  final LightInterface lightInterface = LightInterface();
  final Subscriptions subscriptionsHelper = Subscriptions();

  String searchText = "";
  String selectedStatus = "all";

  Color getStatusColor(String? status) {
    switch (status) {
      case "pending":
        return Colors.orange.withValues(alpha: 0.15);
      case "approved":
        return Colors.green.withValues(alpha: 0.15);
      case "rejected":
        return Colors.red.withValues(alpha: 0.15);
      default:
        return Colors.grey.withValues(alpha: 0.12);
    }
  }

  Color getStatusTextColor(String? status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case "pending":
        return "قيد الانتظار";
      case "approved":
        return "مقبول";
      case "rejected":
        return "مرفوض";
      default:
        return "غير معروف";
    }
  }

  Widget buildStatusChip(String label, String value) {
    final bool isSelected = selectedStatus == value;

    return ChoiceChip(
      avatar: isSelected
          ? FaIcon(FontAwesomeIcons.circleDot, color: Colors.green)
          : FaIcon(FontAwesomeIcons.circle, color: Colors.grey),
      selectedColor: Colors.greenAccent.shade100,
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      selected: isSelected,
      showCheckmark: false,
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
                buildStatusChip("الكل", "all"),
                const SizedBox(width: 8),
                buildStatusChip("الانتظار", "pending"),
                const SizedBox(width: 8),
                buildStatusChip("مقبول", "approved"),
                const SizedBox(width: 8),
                buildStatusChip("مرفوض", "rejected"),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("subscriptions")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("حدث خطأ أثناء تحميل البيانات"),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا توجد طلبات اشتراك"));
                }

                final allSubscriptions = snapshot.data!.docs;

                final filteredSubscriptions = allSubscriptions.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final userName = (data["userName"] ?? "")
                      .toString()
                      .toLowerCase();
                  final status = (data["status"] ?? "pending")
                      .toString()
                      .toLowerCase();

                  final matchesSearch =
                      searchText.isEmpty || userName.contains(searchText);

                  final matchesStatus =
                      selectedStatus == "all" || status == selectedStatus;

                  return matchesSearch && matchesStatus;
                }).toList();

                if (filteredSubscriptions.isEmpty) {
                  return const Center(child: Text("لا توجد نتائج مطابقة"));
                }

                return ListView.builder(
                  itemCount: filteredSubscriptions.length,
                  itemBuilder: (context, index) {
                    final doc = filteredSubscriptions[index];
                    final subscription = doc.data() as Map<String, dynamic>;
                    final String docId = doc.id;

                    final String userId = (subscription['userId'] ?? '')
                        .toString();

                    final String cardCode = (subscription['cardCode'] ?? '')
                        .toString();

                    final String cardType =
                        (subscription['cardType'] ??
                                subscription['selectedCardType'] ??
                                '')
                            .toString();

                    final String cardValue =
                        (subscription['cardValue'] ??
                                subscription['selectedCardValue'] ??
                                '')
                            .toString();

                    final String status = (subscription['status'] ?? 'pending')
                        .toString();

                    final String userName =
                        (subscription['userName'] ?? 'مستخدم غير معروف')
                            .toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Colors.amber,
                          ),
                        ),
                        title: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "كود البطاقة: ${cardCode.isEmpty ? "غير متوفر" : cardCode}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "نوع البطاقة: ${cardType.isEmpty ? "غير متوفر" : cardType}",
                              ),
                              Text(
                                "قيمة البطاقة: ${cardValue.isEmpty ? "غير متوفر" : cardValue}",
                              ),
                            ],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            getStatusText(status),
                            style: TextStyle(
                              color: getStatusTextColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => subscriptionsHelper.subscriptionsOptions(
                          context,
                          docId,
                          userId,
                        ),
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
