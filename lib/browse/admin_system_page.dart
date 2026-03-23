import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood01/adminTabs/quran_tab.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/global/system.dart';
import 'package:mood01/notifications/course_department_target_picker_page.dart';
import 'package:mood01/notifications/route_picker_page.dart';
import 'package:mood01/notifications/user_route_tree.dart';

class AdminSystemPage extends StatefulWidget {
  const AdminSystemPage({super.key});

  @override
  State<AdminSystemPage> createState() => _AdminSystemPageState();
}

class _AdminSystemPageState extends State<AdminSystemPage> {
  final interfaces = Interfaces();
  /////////////////tab 1 content///////////////
  final system = System();

  final versionController = TextEditingController();
  final updateLinkController = TextEditingController();
  final ayah =
      "﴿ ۞ وَقَضَىٰ رَبُّكَ أَلَّا تَعْبُدُوا إِلَّا إِيَّاهُ وَبِالْوَالِدَيْنِ إِحْسَانًا ۚ إِمَّا يَبْلُغَنَّ عِندَكَ الْكِبَرَ أَحَدُهُمَا أَوْ كِلَاهُمَا فَلَا تَقُل لَّهُمَا أُفٍّ وَلَا تَنْهَرْهُمَا وَقُل لَّهُمَا قَوْلًا كَرِيمًا﴾";

  bool isSystemLoading = false;
  bool isSystemUpdating = false;

  void showAyaOptions(BuildContext context, String ayaId, bool isAyaActive) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  isAyaActive
                      ? Icons.remove_red_eye
                      : Icons.remove_red_eye_outlined,
                  color: isAyaActive ? Colors.redAccent : Colors.greenAccent,
                ),
                title: isAyaActive
                    ? const Text("تعطيل الاية")
                    : const Text("تفعيل الاية"),
                onTap: () async {
                  Navigator.pop(context);
                  await system.toggleAyaActive(context, ayaId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("حذف الاية"),
                onTap: () async {
                  Navigator.pop(context);
                  await system.deleteAya(context, ayaId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> loadSystemInfo() async {
    try {
      setState(() {
        isSystemLoading = true;
      });

      await system.getAppVersion();

      versionController.text = system.systemVersion ?? "";
      updateLinkController.text = system.systemUpdateLink?.toString() ?? "";

      if (!mounted) return;
      setState(() {
        isSystemLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSystemLoading = false;
      });
      interfaces.showFlutterToast("فشل تحميل معلومات النظام: $e");
    }
  }

  Future<void> updateSystemInfo() async {
    final version = versionController.text.trim();
    final updateLink = updateLinkController.text.trim();

    if (version.isEmpty || updateLink.isEmpty) {
      interfaces.showFlutterToast("يرجى ملء جميع الحقول");
      return;
    }

    final uri = Uri.tryParse(updateLink);
    if (uri == null ||
        !(uri.scheme == "http" || uri.scheme == "https") ||
        uri.host.isEmpty) {
      interfaces.showFlutterToast("رابط التحديث غير صالح");
      return;
    }
    // check if version format is valid
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
    if (!versionRegex.hasMatch(version)) {
      interfaces.showFlutterToast("صيغة النسخة غير صالحة");
      return;
    }

    final versionParts = version.split('.').map(int.parse).toList();
    if (versionParts.length != 3) {
      interfaces.showFlutterToast("صيغة النسخة غير صالحة");
      return;
    }

    if (system.systemVersion == version) {
      interfaces.showFlutterToast("الاصدار المستخدم هو نفسه الاصدار الجديد!");
      return;
    }

    try {
      setState(() {
        isSystemUpdating = true;
      });

      await FirebaseFirestore.instance
          .collection("system")
          .doc(system.systemId)
          .update({
            "version": version,
            "updateLink": updateLink,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      await system.getAppVersion();

      if (!mounted) return;
      interfaces.showFlutterToast("تم تحديث معلومات النظام بنجاح");
    } catch (e) {
      if (!mounted) return;
      interfaces.showFlutterToast("فشل تحديث معلومات النظام: $e");
    } finally {
      setState(() {
        isSystemUpdating = false;
      });
    }
  }

  ////////////tab 2 content//////////////
  bool hasCourseDepartmentTarget = false;
  String? selectedTargetType;
  String? selectedTargetId;
  String? selectedTargetName;
  //////////////////////////////////
  bool hasRoute = false;
  String? selectedRoutePath;
  String? selectedRouteTitle;
  ///////////////////////////////////
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  bool isLoading = false;

  Future<void> sendNotificationToAllUsersSafe({
    required BuildContext context,
    required String title,
    required String body,
    String? routePath,
    String? routeTitle,
    String? targetType,
    String? targetId,
    String? targetName,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لا يوجد مستخدم مسجل دخول")),
        );
        return;
      }

      await currentUser.getIdToken(true);

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('sendNotificationToAllUsers');

      final result = await callable.call({
        "title": title.trim(),
        "body": body.trim(),
        "routePath": routePath,
        "routeTitle": routeTitle,

        "targetType": targetType,
        "targetId": targetId,
        "targetName": targetName,
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.data["message"] ?? "تم الإرسال بنجاح")),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("فشل الإرسال: $e")));
    }
  }

  Future<void> openRoutePickerPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoutePickerPage(routesTree: userRouteTree),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedRouteTitle = result["title"];
        selectedRoutePath = result["path"];
      });
    }
  }

  Future<void> openCourseDepartmentTargetPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CourseDepartmentTargetPickerPage(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedTargetType = result["targetType"];
        selectedTargetId = result["targetId"];
        selectedTargetName = result["targetName"];
      });
    }
  }

  Widget systemInfo() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: isSystemLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      "الرجاء ملء جميع الحقول عند تحديث معلومات النظام :",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: versionController,
                    decoration: const InputDecoration(
                      hintText: "الإصدار",
                      prefixIcon: Icon(
                        Icons.system_update,
                        color: Colors.greenAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(
                          color: Colors.greenAccent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: updateLinkController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "رابط التحديث",
                      prefixIcon: Icon(Icons.link, color: Colors.greenAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(
                          color: Colors.greenAccent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text(
                        "نسخة التطبيق الحالية: ${system.appVersion ?? ''}",
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_done),
                      title: Text("نسخة النظام: ${system.systemVersion ?? ''}"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: ElevatedButton(
                      style: interfaces.elevatedButtonStyle(300, 50),
                      onPressed: isSystemUpdating
                          ? null
                          : () async {
                              await updateSystemInfo();
                            },
                      child: isSystemUpdating
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.greenAccent,
                              ),
                            )
                          : const Text(
                              "تحديث معلومات النظام",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget sendNotificationTab() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: "عنوان الإشعار",
              prefixIcon: Icon(Icons.title, color: Colors.greenAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "نص الإشعار",
              prefixIcon: Icon(Icons.message, color: Colors.greenAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide(color: Colors.greenAccent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: ListTile(
              title: const Text("يحتوي على مسار تنقل"),
              subtitle: const Text(
                "فعّلها إذا أردت أن يفتح الإشعار صفحة معينة",
              ),
              trailing: Switch(
                value: hasRoute,
                activeTrackColor: Colors.greenAccent,
                onChanged: (value) {
                  setState(() {
                    hasRoute = value;

                    if (value) {
                      hasCourseDepartmentTarget = false;
                      selectedTargetType = null;
                      selectedTargetId = null;
                      selectedTargetName = null;
                    } else {
                      selectedRoutePath = null;
                      selectedRouteTitle = null;
                    }
                  });
                },
              ),
            ),
          ),

          Card(
            child: ListTile(
              title: const Text("تنقل خاص بالأقسام أو المواد"),
              subtitle: const Text("خيار جديد بدون التأثير على route القديم"),
              trailing: Switch(
                value: hasCourseDepartmentTarget,
                activeTrackColor: Colors.greenAccent,
                onChanged: (value) {
                  setState(() {
                    hasCourseDepartmentTarget = value;

                    if (value) {
                      hasRoute = false;
                      selectedRoutePath = null;
                      selectedRouteTitle = null;
                    } else {
                      selectedTargetType = null;
                      selectedTargetId = null;
                      selectedTargetName = null;
                    }
                  });
                },
              ),
            ),
          ),

          if (hasRoute) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.greenAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: openRoutePickerPage,
              icon: const Icon(Icons.folder_open, color: Colors.green),
              label: Text(
                selectedRouteTitle == null
                    ? "اختر المسار"
                    : "المسار المختار: $selectedRouteTitle",
              ),
            ),
            if (selectedRoutePath != null) ...[
              const SizedBox(height: 6),
              Text(
                "Path: $selectedRoutePath",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],

          if (hasCourseDepartmentTarget) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.greenAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: openCourseDepartmentTargetPicker,
              icon: const Icon(Icons.folder_open, color: Colors.green),
              label: Text(
                selectedTargetName == null
                    ? "اختيار كلية أو قسم"
                    : "المختار: $selectedTargetName",
              ),
            ),
          ],

          const SizedBox(height: 40),

          Center(
            child: interfaces.submitButton01(
              context,
              "ارسل الإشعار لجميع المستخدمين",
              () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();

                if (title.isEmpty || body.isEmpty) {
                  interfaces.showFlutterToast("يرجى ملء جميع الحقول");
                  return;
                }

                if (hasRoute && selectedRoutePath == null) {
                  interfaces.showFlutterToast("يرجى اختيار مسار أولاً");
                  return;
                }
                if (hasCourseDepartmentTarget &&
                    (selectedTargetType == null ||
                        selectedTargetId == null ||
                        selectedTargetName == null)) {
                  interfaces.showFlutterToast("اختر الكلية أو القسم أولاً");
                  return;
                }

                setState(() {
                  interfaces.isLoading = true;
                });

                await sendNotificationToAllUsersSafe(
                  context: context,
                  title: titleController.text,
                  body: bodyController.text,
                  routePath: hasRoute ? selectedRoutePath : null,
                  routeTitle: hasRoute ? selectedRouteTitle : null,
                  targetType: hasCourseDepartmentTarget
                      ? selectedTargetType
                      : null,
                  targetId: hasCourseDepartmentTarget ? selectedTargetId : null,
                  targetName: hasCourseDepartmentTarget
                      ? selectedTargetName
                      : null,
                );

                setState(() {
                  interfaces.isLoading = false;
                });
              },
              double.infinity,
              50,
            ),
          ),
        ],
      ),
    );
  }

  Widget quranTab() {
    return const QuranTab();
  }

  @override
  void initState() {
    super.initState();
    loadSystemInfo();
  }

  @override
  void dispose() {
    versionController.dispose();
    updateLinkController.dispose();
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
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
                Tab(text: "معلومات النظام"),
                Tab(text: "إرسال الإشعارات"),
                Tab(text: "الأيات المعروضة"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // system info tab 1 content
                  systemInfo(),
                  // send notification tab 2 content
                  sendNotificationTab(),

                  // ayat tab 3 content
                  quranTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
