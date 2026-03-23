import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';

class AdminAccountsControlTab extends StatefulWidget {
  const AdminAccountsControlTab({super.key});

  @override
  State<AdminAccountsControlTab> createState() =>
      _AdminAccountsControlTabState();
}

class _AdminAccountsControlTabState extends State<AdminAccountsControlTab> {
  final interfaces = Interfaces();
  String searchText = "";
  bool isLoading = false;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  ////////////////////////////////////////////////////////////////////////////////

  Future<void> changeUserStatus(String userId, bool currentStatus) async {
    final confirm = await interfaces.showConfirmationDialog(
      context,
      currentStatus
          ? "هل تريد تعطيل هذا الأدمن ؟"
          : "هل تريد تفعيل هذا الأدمن ؟",
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orange,
    );

    if (!confirm) return;

    await FirebaseFirestore.instance.collection("admins").doc(userId).update({
      "isActive": !currentStatus,
    });

    if (!mounted) return;
    interfaces.showAlert(
      context,
      !currentStatus ? "تم تفعيل حساب الأدمن" : "تم تعطيل حساب الأدمن",
      icon: Icons.check_circle,
      iconColor: Colors.green,
    );
  }

  Future<void> showUserDetails(
    Map<String, dynamic> userData,
    String userId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        final fullName =
            "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}";
        final userName = userData["userName"] ?? "";
        final email = userData["email"] ?? "";
        final phone = userData["phone"] ?? "";
        final role = userData["role"] ?? "user";
        final isOnline = userData["isOnline"] ?? false;
        final photoUrl = userData["photoUrl"] ?? "";

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("بيانات الادمن", textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundImage: photoUrl.toString().isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.toString().isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 15),
                Text(
                  fullName.trim().isEmpty ? "بدون اسم" : fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text("@$userName", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text(
                      "البريد: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(email)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "الهاتف: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(phone)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "الدور: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(role)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "الحالة: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(isOnline ? "متصل الآن" : "غير متصل")),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  "المعرف: $userId",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إغلاق", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteUser(String userId, String name) async {
    final confirm = await interfaces.showConfirmationDialog(
      context,
      "هل أنت متأكد من حذف الادمن $name ؟",
      icon: Icons.delete_forever,
      iconColor: Colors.red,
    );

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance
          .collection("admins")
          .doc(userId)
          .delete();

      if (!mounted) return;
      interfaces.showAlert(
        context,
        "تم حذف الادمن بنجاح",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء حذف الادمن",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  void showOptionsBottomSheet(String userId, Map<String, dynamic> userData) {
    final fullName =
        "${userData["firstName"] ?? ""} ${userData["lastName"] ?? ""}".trim();
    final isActive = userData["isActive"] ?? true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
                title: const Text("عرض البيانات"),
                onTap: () async {
                  Navigator.pop(context);
                  await showUserDetails(userData, userId);
                },
              ),

              ListTile(
                leading: Icon(
                  isActive ? Icons.block : Icons.check_circle,
                  color: isActive ? Colors.orange : Colors.green,
                ),
                title: Text(isActive ? "تعطيل الأدمن" : "تفعيل الأدمن"),
                onTap: () async {
                  Navigator.pop(context);
                  await changeUserStatus(userId, isActive);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("حذف الأدمن"),
                onTap: () async {
                  Navigator.pop(context);
                  await deleteUser(
                    userId,
                    fullName.isEmpty ? "بدون اسم" : fullName,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildUserCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userId = doc.id;

    final firstName = data["firstName"] ?? "";
    final lastName = data["lastName"] ?? "";
    final userName = data["userName"] ?? "";
    final email = data["email"] ?? "";
    final photoUrl = data["photoUrl"] ?? "";
    final role = data["role"] ?? "user";
    final isOnline = data["isOnline"] ?? false;
    final isActive = data["isActive"] ?? true;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => showOptionsBottomSheet(userId, data),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: photoUrl.toString().isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.toString().isEmpty
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$firstName $lastName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@$userName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: role == "admin"
                          ? Colors.blueAccent.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: role == "admin"
                            ? Colors.blueAccent
                            : Theme.of(context).textTheme.bodyMedium!.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    isActive ? Icons.verified_user : Icons.block,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminStream = FirebaseFirestore.instance
        .collection("admins")
        .orderBy("firstName")
        .snapshots();
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                searchText = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "ابحث بالاسم أو اسم المستخدم أو البريد",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Colors.greenAccent,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: adminStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("حدث خطأ: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("لا يوجد مستخدمون"));
                }

                final allUsers = snapshot.data!.docs;

                final filteredUsers = allUsers.where((doc) {
                  if (doc.id == currentUserId) return false;

                  final data = doc.data() as Map<String, dynamic>;

                  final firstName = (data["firstName"] ?? "")
                      .toString()
                      .toLowerCase();
                  final lastName = (data["lastName"] ?? "")
                      .toString()
                      .toLowerCase();
                  final userName = (data["userName"] ?? "")
                      .toString()
                      .toLowerCase();
                  final email = (data["email"] ?? "").toString().toLowerCase();

                  final fullName = "$firstName $lastName";

                  return fullName.contains(searchText) ||
                      userName.contains(searchText) ||
                      email.contains(searchText);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("لا توجد نتائج بحث"));
                }

                return ListView.separated(
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 5),
                  itemBuilder: (context, index) {
                    return buildUserCard(filteredUsers[index]);
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
