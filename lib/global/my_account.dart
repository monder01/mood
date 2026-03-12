import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mood01/auth/users.dart';
import 'package:mood01/global/interfaces.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  final interfaces = Interfaces();
  Users users = Users();
  final currentUser = FirebaseAuth.instance.currentUser;

  bool isPhotoLoading = false;

  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    await uploadImage(file);
  }

  Future<void> pickFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    await uploadImage(file);
  }

  Future<void> uploadImage(File file) async {
    try {
      setState(() => isPhotoLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child("users")
          .child("${user.uid}.jpg");

      await ref.putFile(file);

      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(
        {"photoUrl": imageUrl},
      );

      users.photoUrl = imageUrl;

      if (!mounted) return;
      interfaces.showAlert(
        context,
        "تم تحديث الصورة بنجاح",
        icon: Icons.done,
        iconColor: Colors.green,
      );

      setState(() {});
    } catch (e) {
      if (!context.mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء رفع الصورة",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => isPhotoLoading = false);
      }
    }
  }

  Future<void> showImageSourceDialog() async {
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
                leading: const Icon(
                  Icons.camera_alt,
                  color: Colors.greenAccent,
                ),
                title: const Text("التقاط صورة"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.greenAccent),
                title: const Text("اختيار من المعرض"),
                onTap: () async {
                  Navigator.pop(context);
                  await pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateField({
    required String title,
    required String fieldName,
    required String currentValue,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: currentValue);
    if (keyboardType == TextInputType.phone) {
      controller.text = currentValue.replaceAll("+218", "");
    }

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              suffixText: keyboardType == TextInputType.phone ? "218+" : null,
              hintText: "أدخل القيمة الجديدة",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text("حفظ", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .update({fieldName: result});

      if (!mounted) return;
      interfaces.showAlert(
        context,
        "تم التعديل بنجاح",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء التعديل",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        bool obscureOld = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "تغيير كلمة المرور",
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        hintText: "كلمة المرور القديمة",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              obscureOld = !obscureOld;
                            });
                          },
                          icon: Icon(
                            obscureOld
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        hintText: "كلمة المرور الجديدة",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              obscureNew = !obscureNew;
                            });
                          },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: "تأكيد كلمة المرور الجديدة",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "إلغاء",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, {
                      "oldPassword": oldPasswordController.text.trim(),
                      "newPassword": newPasswordController.text.trim(),
                      "confirmPassword": confirmPasswordController.text.trim(),
                    });
                  },
                  child: const Text(
                    "حفظ",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || currentUser == null) return;

    final oldPassword = result["oldPassword"] ?? "";
    final newPassword = result["newPassword"] ?? "";
    final confirmPassword = result["confirmPassword"] ?? "";

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "يرجى ملء جميع الحقول",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    if (newPassword.length < 6) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "كلمة المرور الجديدة يجب أن تكون 6 أحرف أو أكثر",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "كلمتا المرور الجديدتان غير متطابقتين",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    try {
      final email = currentUser!.email;
      if (email == null || email.isEmpty) {
        if (!mounted) return;
        interfaces.showAlert(
          context,
          "تعذر التحقق من البريد الإلكتروني",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);

      if (!mounted) return;
      interfaces.showAlert(
        context,
        "تم تغيير كلمة المرور بنجاح",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String message = "حدث خطأ أثناء تغيير كلمة المرور";

      if (e.code == "wrong-password" || e.code == "invalid-credential") {
        message = "كلمة المرور القديمة غير صحيحة";
      } else if (e.code == "weak-password") {
        message = "كلمة المرور الجديدة ضعيفة";
      } else if (e.code == "too-many-requests") {
        message = "عدد المحاولات كبير، حاول لاحقًا";
      } else if (e.code == "requires-recent-login") {
        message = "يرجى تسجيل الدخول من جديد ثم إعادة المحاولة";
      }

      if (!mounted) return;
      interfaces.showAlert(
        context,
        message,
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
      interfaces.showAlert(
        context,
        "حدث خطأ أثناء تغيير كلمة المرور",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  Widget buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.green,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: interfaces.showAppBar(context, title: "حسابي", actions: false),
        body: const Center(child: Text("لا يوجد مستخدم مسجل دخول")),
      );
    }

    final userStream = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .snapshots();

    return Scaffold(
      appBar: interfaces.showAppBar(context, title: "حسابي", actions: false),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("حدث خطأ: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("تعذر تحميل بيانات الحساب"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final firstName = (data["firstName"] ?? "").toString();
          final lastName = (data["lastName"] ?? "").toString();
          final fullName = "$firstName $lastName".trim();
          final userName = (data["userName"] ?? "").toString();
          final phone = (data["phone"] ?? "").toString();
          final email = (data["email"] ?? "").toString();
          final photoUrl = (data["photoUrl"] ?? "").toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(55),
                  onTap: isPhotoLoading ? null : () => showImageSourceDialog(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: isPhotoLoading
                            ? null
                            : photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: isPhotoLoading
                            ? const CircularProgressIndicator(
                                color: Colors.greenAccent,
                              )
                            : photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 55,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          radius: 16,
                          child: const Icon(
                            Icons.edit,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName.isEmpty ? "بدون اسم" : fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "@$userName",
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 25),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "خيارات الحساب",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                buildOptionTile(
                  icon: Icons.badge_outlined,
                  title: "تغيير الاسم",
                  onTap: () {
                    updateField(
                      title: "تغيير الاسم",
                      fieldName: "firstName",
                      currentValue: firstName,
                    );
                  },
                ),

                buildOptionTile(
                  icon: Icons.phone_android,
                  title: "تغيير رقم الهاتف",
                  onTap: () {
                    updateField(
                      title: "تغيير رقم الهاتف",
                      fieldName: "phone",
                      currentValue: phone,
                      keyboardType: TextInputType.phone,
                    );
                  },
                ),

                buildOptionTile(
                  icon: Icons.lock_outline,
                  title: "تغيير كلمة المرور",
                  onTap: changePassword,
                  iconColor: Colors.redAccent,
                ),

                buildOptionTile(
                  icon: Icons.alternate_email,
                  title: "تغيير اسم المستخدم",
                  onTap: () {
                    updateField(
                      title: "تغيير اسم المستخدم",
                      fieldName: "userName",
                      currentValue: userName,
                    );
                  },
                  iconColor: Colors.blueAccent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
