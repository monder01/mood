import 'package:flutter/material.dart';
import 'package:mood01/contacting/reports_tab.dart';
import 'package:mood01/contacting/subscriptions_tab.dart';

class AdminResolvePage extends StatefulWidget {
  const AdminResolvePage({super.key});

  @override
  State<AdminResolvePage> createState() => _AdminResolvePageState();
}

class _AdminResolvePageState extends State<AdminResolvePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: Color.fromARGB(255, 90, 205, 150),
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
              tabs: const [
                Tab(text: "البلاغات"),
                Tab(text: "الإشتراكات"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // under construction tab 1 content
                  ReportsTab(),
                  // under construction tab 2 content
                  SubscriptionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
