import 'package:flutter/material.dart';
import 'package:mood01/auth/users.dart';
import 'package:mood01/global/interfaces.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  final interfaces = Interfaces();
  Users users = Users();
  TextEditingController usernameController = TextEditingController();
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  // تصميم حقل النص

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.greenAccent[200]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Center(
              child: Image.asset(
                "assets/icons/monther.png",
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 200),
              ),
            ),
            const Text(
              "انشئ حسابك في مزاجي!",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            interfaces.textField01(
              label: "اسم المستخدم",
              keyboardType: TextInputType.text,
              controller: usernameController,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              spacing: 10,
              children: [
                Expanded(
                  child: interfaces.textField01(
                    label: "الاسم الاول",
                    keyboardType: TextInputType.text,
                    controller: firstnameController,
                  ),
                ),
                Expanded(
                  child: interfaces.textField01(
                    label: "الاسم الاخير",
                    keyboardType: TextInputType.text,
                    controller: lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "رقم الهاتف",
              keyboardType: TextInputType.phone,
              controller: phoneController,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "البريد الالكتروني",
              keyboardType: TextInputType.emailAddress,
              controller: emailController,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "كلمة المرور",
              keyboardType: TextInputType.visiblePassword,
              controller: passwordController,
            ),
            const SizedBox(height: 10),
            interfaces.textField01(
              label: "تأكيد كلمة المرور",
              keyboardType: TextInputType.visiblePassword,
              controller: confirmPasswordController,
            ),
            const SizedBox(height: 20),
            interfaces.submitButton01(
              context,
              "إنشاء الحساب",
              () async {
                setState(() {
                  interfaces.isLoading = true;
                });
                await users.signUp(
                  context,
                  usernameController,
                  firstnameController,
                  lastNameController,
                  emailController,
                  phoneController,
                  passwordController,
                  confirmPasswordController,
                );
                setState(() {
                  interfaces.isLoading = false;
                });
              },
              300,
              70,
            ),
          ],
        ),
      ),
    );
  }
}
