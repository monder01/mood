import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
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
                  .collection("subscriptions")
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
                  return const Center(child: Text("لا توجد طلبات إشتراك"));
                }

                final subscriptions = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final subscription = subscriptions[index].data();
                    final cardCode = subscription['cardCode'] ?? '';
                    final cardType = subscription['cardType'] ?? '';
                    final cardValue = subscription['cardValue'] ?? '';
                    final status = subscription['status'] ?? '';
                    final userId = subscription['userId'] ?? '';

                    return Card(
                      child: ListTile(
                        title: Text('طلب اشتراك جديد'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('كود البطاقة: $cardCode'),
                            Text('نوع البطاقة: $cardType'),
                            Text('قيمة البطاقة: $cardValue'),
                            Text('حالة الطلب: $status'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("subscriptions")
                                .doc(subscriptions[index].id)
                                .delete();
                          },
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
