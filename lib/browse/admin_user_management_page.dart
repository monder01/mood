import 'package:flutter/material.dart';
import 'package:mood01/adminTabs/account_control_tab.dart';
import 'package:mood01/adminTabs/admin_accounts_control_tab.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
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
                Tab(text: "حسابات المستخدمين"),
                Tab(text: "حسابات الإدارايين"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Users Tab 1 content
                  AccountControlTab(),
                  // under construction tab 2 content
                  AdminAccountsControlTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
