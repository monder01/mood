import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mood01/addEdit/add_quran_page.dart';
import 'package:mood01/designs/interfaces.dart';
import 'package:mood01/settings/system.dart';

class QuranTab extends StatefulWidget {
  const QuranTab({super.key});

  @override
  State<QuranTab> createState() => _QuranTabState();
}

class _QuranTabState extends State<QuranTab> {
  final system = System();

  final interfaces = Interfaces();

  final ayah =
      "﴿ ۞ وَقَضَىٰ رَبُّكَ أَلَّا تَعْبُدُوا إِلَّا إِيَّاهُ وَبِالْوَالِدَيْنِ إِحْسَانًا ۚ إِمَّا يَبْلُغَنَّ عِندَكَ الْكِبَرَ أَحَدُهُمَا أَوْ كِلَاهُمَا فَلَا تَقُل لَّهُمَا أُفٍّ وَلَا تَنْهَرْهُمَا وَقُل لَّهُمَا قَوْلًا كَرِيمًا﴾";

  /// عرض خيارات الاية
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

  /// تحقق اذا كانت الاية الابتداءية
  Future<bool> isFirstUpdated(DocumentSnapshot ayaDoc) async {
    final snapshot = await ayaDoc.reference.parent
        .orderBy("updatedAt", descending: false)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return false;

    return snapshot.docs.first.id == ayaDoc.id;
  }

  Future<void> refreshPage() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// زر إضافة آية
          interfaces.submitButton01(
            context,
            "إضافة آية",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddQuranVersesPage(systemDocId: system.systemId),
                ),
              );
            },
            double.infinity,
            50,
          ),

          const SizedBox(height: 15),

          /// عرض الآيات
          Expanded(
            child: RefreshIndicator(
              color: Colors.greenAccent,
              onRefresh: refreshPage,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("system")
                    .doc(system.systemId)
                    .collection("QuranVerses")
                    .orderBy("updatedAt", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("حدث خطأ أثناء تحميل الآيات"),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("لا توجد آيات مفعلة"));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final verse = data["verse"]?.toString() ?? "";
                      final isActive = data["isActive"] ?? false;
                      final isFirst = index == 0;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          showAyaOptions(context, docs[index].id, isActive);
                        },
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.greenAccent
                                      : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                verse,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1.7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isActive)
                              Positioned(
                                top: 20,
                                right: 5,
                                child: Container(
                                  height: 22,
                                  width: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.greenAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  child: FaIcon(
                                    isFirst
                                        ? FontAwesomeIcons.one
                                        : FontAwesomeIcons.two,
                                    color: Colors.black,
                                    size: 15,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
