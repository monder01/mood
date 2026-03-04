import 'package:flutter/material.dart';
import 'package:mood01/auth/users.dart';

class Signuppage extends StatefulWidget {
  const Signuppage({super.key});

  @override
  State<Signuppage> createState() => _SignuppageState();
}

class _SignuppageState extends State<Signuppage> {
  Users users = Users();
  TextEditingController usernameController = TextEditingController();
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  // تصميم حقل النص
  Widget textField01({
    required String label,
    required TextInputType keyboardType,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: keyboardType == TextInputType.visiblePassword ? true : false,
      decoration: InputDecoration(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        prefixText: keyboardType == TextInputType.phone ? "+218 " : null,
        prefixStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 1),
        ),
      ),
    );
  }

  // تصميم زر الإرسال
  Widget submitButton01(
    BuildContext context,
    String text,
    VoidCallback onPressed,
    double width,
    double height,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 5,
        minimumSize: Size(width, height),
        maximumSize: Size(width, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: const BorderSide(color: Colors.greenAccent, width: 2),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? CircularProgressIndicator(color: Colors.greenAccent)
          : Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
    );
  }

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
              ),
            ),
            const Text(
              "انشئ حسابك في مزاجي!",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            textField01(
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
                  child: textField01(
                    label: "الاسم الاول",
                    keyboardType: TextInputType.text,
                    controller: firstnameController,
                  ),
                ),
                Expanded(
                  child: textField01(
                    label: "الاسم الاخير",
                    keyboardType: TextInputType.text,
                    controller: lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            textField01(
              label: "رقم الهاتف",
              keyboardType: TextInputType.phone,
              controller: phoneController,
            ),
            const SizedBox(height: 10),
            textField01(
              label: "البريد الالكتروني",
              keyboardType: TextInputType.emailAddress,
              controller: emailController,
            ),
            const SizedBox(height: 10),
            textField01(
              label: "كلمة المرور",
              keyboardType: TextInputType.visiblePassword,
              controller: passwordController,
            ),
            const SizedBox(height: 10),
            textField01(
              label: "تأكيد كلمة المرور",
              keyboardType: TextInputType.visiblePassword,
              controller: confirmPasswordController,
            ),
            const SizedBox(height: 20),
            submitButton01(
              context,
              "إنشاء الحساب",
              () async {
                setState(() {
                  isLoading = true;
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
                  isLoading = false;
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
