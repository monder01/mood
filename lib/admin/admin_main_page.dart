import 'package:flutter/material.dart';
import 'package:mood01/admin/add_college_page.dart';
import 'package:mood01/admin/add_department_page.dart';
import 'package:mood01/admin/add_section_page.dart';
import 'package:mood01/interfaces.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  Interfaces interfaces = Interfaces();
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color.fromARGB(255, 90, 205, 150),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
            tabs: [
              Tab(text: "إضافة كلية"),
              Tab(text: "إضافة قسم"),
              Tab(text: "إضافة شعبة"),
            ],
          ),

          Expanded(
            child: TabBarView(
              children: [
                /////////////////
                // Tab 1 content
                /////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      interfaces.submitButton01(
                        context,
                        "إضافة كلية",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddCollegePage(),
                            ),
                          );
                        },
                        double.infinity,
                        50,
                      ),
                      interfaces.textField01(
                        label: "اسم الكلية",
                        keyboardType: TextInputType.text,
                        controller: TextEditingController(),
                        icon: Icons.search,
                        iconColor: Colors.greenAccent,
                      ),
                      Center(
                        child: Text(
                          "Tab 1 Page",
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ],
                  ),
                ),
                ////////////////
                // Tab 2 content
                ////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      interfaces.submitButton01(
                        context,
                        "إضافة قسم",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddDepartmentPage(),
                            ),
                          );
                        },
                        double.infinity,
                        50,
                      ),
                      interfaces.textField01(
                        label: "اسم القسم",
                        keyboardType: TextInputType.text,
                        controller: TextEditingController(),
                        icon: Icons.search,
                        iconColor: Colors.greenAccent,
                      ),
                      Center(
                        child: Text(
                          "Tab 2 Page",
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ],
                  ),
                ),
                ////////////////
                // Tab 3 content
                ////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    spacing: 10,
                    children: [
                      interfaces.submitButton01(
                        context,
                        "إضافة شعبة",
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddSectionPage(),
                            ),
                          );
                        },
                        double.infinity,
                        50,
                      ),
                      interfaces.textField01(
                        label: "اسم الشعبة",
                        keyboardType: TextInputType.text,
                        controller: TextEditingController(),
                        icon: Icons.search,
                        iconColor: Colors.greenAccent,
                      ),

                      Center(
                        child: Text(
                          "Tab 3 Page",
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
