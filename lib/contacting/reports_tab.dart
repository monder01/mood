import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/designs/mini_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final Interfaces interfaces = Interfaces();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          interfaces.buildSearchField(
            hint: "اسم المستخدم",
            onChanged: (value) {},
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("reports")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
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
                  return const Center(child: Text("لا توجد بلاغات"));
                }
                final reports = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final report = reports[index].data();

                    final description = report["description"];
                    final itemId = report["itemId"];
                    final reportedId = report["reportedId"];
                    final reportedName = report["reportedName"];
                    final reportedType = report["reportedType"];
                    final reporterId = report["reporterId"];
                    final reporterName = report["reporterName"];
                    final status = report["status"];

                    return Card(
                      child: ListTile(
                        leading: reportedType == "comment"
                            ? FaIcon(FontAwesomeIcons.scroll)
                            : reportedType == "image"
                            ? const FaIcon(FontAwesomeIcons.image)
                            : const FaIcon(FontAwesomeIcons.message),
                        title: Text(report["reportedName"]),
                        subtitle: Text(report["description"]),
                        trailing: SizedBox(
                          height: 40,
                          child: Container(
                            width: 70,
                            decoration: BoxDecoration(
                              color: status == "pending"
                                  ? Colors.yellow.withValues(alpha: 0.5)
                                  : status == "resolved"
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.red.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                reportedType == "comment"
                                    ? "تعليق"
                                    : reportedType == "image"
                                    ? "صورة"
                                    : "رسالة",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
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
