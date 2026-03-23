import 'package:flutter/material.dart';
import 'package:mood01/auth/admin.dart';
import 'package:mood01/designs/interfaces.dart';

class Signinpage extends StatefulWidget {
  const Signinpage({super.key});

  @override
  State<Signinpage> createState() => _SigninpageState();
}

class _SigninpageState extends State<Signinpage> {
  final interfaces = Interfaces();
  Admin admin = Admin();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isObscure = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent[200],
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        toolbarHeight: 50,
        shadowColor: Colors.greenAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Center(
              child: Image.asset(
                "assets/icons/monther.png",
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "مرحبًا بك في مزاجي!",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 68, 238, 156),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                label: const Text(
                  "البريد الالكتروني",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: isObscure,
              decoration: InputDecoration(
                label: const Text(
                  "كلمة المرور",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      isObscure = !isObscure;
                    });
                  },
                  icon: isObscure
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 20),
            interfaces.submitButton01(
              context,
              "تسجيل الدخول",
              () async {
                if (!mounted) return;
                setState(() {
                  interfaces.isLoading = true;
                });
                await admin.signIn(
                  context,
                  emailController,
                  passwordController,
                );
                if (!mounted) return;
                setState(() {
                  interfaces.isLoading = false;
                });
              },
              300,
              70,
            ),

            const SizedBox(height: 50),
            Text(
              "عن طريق تسجيل الدخول ، فإنك توافق على شروط الخدمة وسياسة الخصوصية الخاصة بنا",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
