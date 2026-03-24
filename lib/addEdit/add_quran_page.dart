import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood01/designs/interfaces.dart';

class VerseItem {
  final TextEditingController verseController = TextEditingController();
  bool isActive = false;
}

class AddQuranVersesPage extends StatefulWidget {
  final String systemDocId;

  const AddQuranVersesPage({super.key, required this.systemDocId});

  @override
  State<AddQuranVersesPage> createState() => _AddQuranVersesPageState();
}

class _AddQuranVersesPageState extends State<AddQuranVersesPage> {
  final Interfaces interfaces = Interfaces();
  final List<VerseItem> verses = [VerseItem()];

  bool isSaving = false;
  int activeCountInFirestore = 0;
  bool isLoadingActiveCount = true;

  CollectionReference<Map<String, dynamic>> get versesRef => FirebaseFirestore
      .instance
      .collection("system")
      .doc(widget.systemDocId)
      .collection("QuranVerses");

  @override
  void initState() {
    super.initState();
    loadActiveCount();
  }

  Future<void> loadActiveCount() async {
    try {
      final snapshot = await versesRef.where("isActive", isEqualTo: true).get();

      if (!mounted) return;
      setState(() {
        activeCountInFirestore = snapshot.docs.length;
        isLoadingActiveCount = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingActiveCount = false;
      });
      interfaces.showFlutterToast(
        "فشل تحميل عدد الآيات المفعلة",
        color: Colors.red,
      );
    }
  }

  int get localActiveCount => verses.where((e) => e.isActive).length;

  Future<void> saveVerses() async {
    if (isSaving) return;

    final totalActiveAfterSave = activeCountInFirestore + localActiveCount;

    if (totalActiveAfterSave > 2) {
      interfaces.showAlert(
        context,
        "لا يمكن تفعيل أكثر من آيتين فقط",
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    for (final verse in verses) {
      if (verse.verseController.text.trim().isEmpty) {
        interfaces.showAlert(
          context,
          "الرجاء تعبئة جميع الحقول",
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final verse in verses) {
        final doc = versesRef.doc();

        batch.set(doc, {
          "verse": verse.verseController.text.trim(),
          "isActive": verse.isActive,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      await interfaces.showAlert(context, "تم حفظ الآيات بنجاح ✅");

      for (final verse in verses) {
        verse.verseController.dispose();
      }

      verses.clear();

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      await interfaces.showAlert(
        context,
        "حدث خطأ أثناء الحفظ ❌",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget verseCard(int index) {
    return Dismissible(
      key: ValueKey(verses[index]),
      confirmDismiss: (direction) async {
        return verses.length > 1;
      },
      onDismissed: (direction) {
        if (verses.length == 1) return;
        setState(() {
          verses[index].verseController.dispose();
          verses.removeAt(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          spacing: 12,
          children: [
            interfaces.textField01(
              label: "الآية",
              keyboardType: TextInputType.multiline,
              controller: verses[index].verseController,
              maxLines: 4,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                  child: Text(
                    "الآية رقم ${index + 1}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Row(
                  children: [
                    const Text("تفعيل", style: TextStyle(fontSize: 16)),
                    Switch(
                      activeTrackColor: Colors.greenAccent,
                      value: verses[index].isActive,
                      onChanged: (value) {
                        final currentLocalActive = verses
                            .where((e) => e.isActive)
                            .length;

                        if (value == true &&
                            (activeCountInFirestore + currentLocalActive) >=
                                2) {
                          interfaces.showFlutterToast(
                            "فقط آيتان يمكن أن تكونا مفعّلتين",
                            color: Colors.red,
                          );
                          return;
                        }

                        setState(() {
                          verses[index].isActive = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("حذف", style: TextStyle(fontSize: 16)),
                    IconButton(
                      onPressed: () {
                        if (verses.length == 1) return;
                        setState(() {
                          verses[index].verseController.dispose();
                          verses.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final verse in verses) {
      verse.verseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة آيات"), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        onPressed: () {
          setState(() {
            verses.add(VerseItem());
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          if (isLoadingActiveCount)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(color: Colors.greenAccent),
            ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "عدد الآيات المفعلة حاليًا: $activeCountInFirestore / 2",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "الرجاء تعبئة جميع الحقول:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      verseCard(index),
                    ],
                  );
                }

                return verseCard(index);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            interfaces.submitButton01(
              context,
              "حفظ",
              () async {
                final confirm = await interfaces.showConfirmationDialog(
                  context,
                  "هل جميع البيانات صحيحة؟",
                  icon: Icons.info,
                  iconColor: Colors.greenAccent,
                );
                if (!confirm) return;

                setState(() {
                  interfaces.isLoading = true;
                });

                await saveVerses();

                if (!mounted) return;
                setState(() {
                  interfaces.isLoading = false;
                });
              },
              200,
              50,
            ),
          ],
        ),
      ),
    );
  }
}
