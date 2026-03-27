import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/designs/mini_interface.dart';
import 'package:mood01/settings/system.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatelessWidget {
  AboutAppPage({super.key});
  final interfaces = Interfaces();
  final LightInterface lightInterface = LightInterface();
  System get system => System.current;
  Future<void> openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      query: 'subject=استفسار حول التطبيق',
    );

    await launchUrl(emailUri);
  }

  Future<void> openWhatsapp() async {
    final Uri whatsapp = Uri.parse(
      "https://whatsapp.com/channel/0029Vb6vhWX1t90d5vuGuD0z",
    );
    await launchUrl(whatsapp, mode: LaunchMode.externalApplication);
  }

  Future<void> openInstagram() async {
    final Uri instagram = Uri.parse(
      "https://www.instagram.com/taysir_app2025?igsh=ZDkyamV3bmp1a3U5&utm_source=qr",
    );
    await launchUrl(instagram, mode: LaunchMode.externalApplication);
  }

  // open facebook
  Future<void> openFacebook() async {
    final Uri facebook = Uri.parse(
      "https://www.facebook.com/share/1H9PfNFDT5/?mibextid=wwXIfr",
    );
    await launchUrl(facebook, mode: LaunchMode.externalApplication);
  }

  Future<void> openTelegram() async {
    final Uri telegram = Uri.parse("https://t.me/TaysirApp");
    await launchUrl(telegram, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: interfaces.showAppBar(context, title: "", actions: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(height: 5),

            Image.asset(
              "assets/icons/ControlMon01.png",
              width: 180,
              height: 180,
            ),

            Text("V${system.appVersion ?? " "}"),

            /// 🔹 وصف التطبيق
            Container(
              alignment: Alignment.center,
              child: Text(
                "تطبيق مزاجي هو منصة تعليمية تساعد الطلبة على الوصول إلى المواد وملخصاتها الدراسية بسهولة. "
                "يمكنك من خلاله تصفح الكليات والأقسام والمواد المختلفة بطريقة منظمة وواضحة. "
                "يوفر التطبيق أيضًا إمكانية التعرف على الزملاء والتواصل معهم عبر المحادثات. "
                "يساعد ذلك على تبادل المعلومات والملفات الدراسية بسرعة وسهولة. "
                "تم تصميم التطبيق ليكون بسيط الاستخدام ويوفر تجربة مريحة للطلبة.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 10),

            /// 🔹 معلومات المطور
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "معلومات المطور",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 5),
                    alignment: Alignment.centerRight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.badge,
                        size: 30,
                        color: Colors.greenAccent,
                      ), //company icon
                      title: Text(
                        "المطور",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "منذر الرعبوب",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 5),
                    alignment: Alignment.centerRight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.location_on,
                        size: 30,
                        color: Colors.greenAccent,
                      ),
                      title: Text(
                        "الدولة",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "ليبيا",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: Icon(Icons.email, size: 30, color: Colors.greenAccent),
                title: Text(
                  "البريد الألكتروني",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                subtitle: InkWell(
                  onLongPress: () {
                    Clipboard.setData(
                      const ClipboardData(text: "monther00147@gmail.com"),
                    );
                    lightInterface.showFlutterToast("تم نسخ البريد الإلكتروني");
                  },
                  child: Text(
                    "monther00147@gmail.com",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            const Divider(),

            const SizedBox(height: 15),

            /// 🔹 تواصل معنا
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "تابعنا على التطبيقات التالية",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                InkWell(
                  onTap: () async {
                    final confirm = await interfaces.showConfirmationDialog(
                      context,
                      "سيتم فتح الرابط خارج التطبيق، هل تريد المتابعة؟",
                      icon: Icons.open_in_browser,
                      iconColor: Colors.green,
                    );

                    if (!confirm) return;

                    await openWhatsapp();
                  },
                  child: Image.asset(
                    "assets/icons/whatsapp.png",
                    width: 50,
                    height: 50,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final confirm = await interfaces.showConfirmationDialog(
                      context,
                      "سيتم فتح الرابط خارج التطبيق، هل تريد المتابعة؟",
                      icon: Icons.open_in_browser,
                      iconColor: Colors.blue,
                    );

                    if (!confirm) return;

                    await openFacebook();
                  },
                  child: Image.asset(
                    "assets/icons/facebook.png",
                    width: 50,
                    height: 50,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final confirm = await interfaces.showConfirmationDialog(
                      context,
                      "سيتم فتح الرابط خارج التطبيق، هل تريد المتابعة؟",
                      icon: Icons.open_in_browser,
                      iconColor: Colors.purple,
                    );

                    if (!confirm) return;

                    await openInstagram();
                  },
                  child: Image.asset(
                    "assets/icons/instagram.png",
                    width: 50,
                    height: 50,
                  ),
                ),
                // telegram
                InkWell(
                  onTap: () async {
                    final confirm = await interfaces.showConfirmationDialog(
                      context,
                      "سيتم فتح الرابط خارج التطبيق، هل تريد المتابعة؟",
                      icon: Icons.open_in_browser,
                      iconColor: Colors.lightBlue,
                    );

                    if (!confirm) return;

                    await openTelegram();
                  },
                  child: Image.asset(
                    "assets/icons/telegram.png",
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "© 2026 جميع الحقوق محفوظة",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
