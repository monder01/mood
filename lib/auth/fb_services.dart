import 'package:cloud_firestore/cloud_firestore.dart';

class FbServices {
  // firestore add fun
  Future<void> addToFirestore01(
    List fields,
    List values,
    String collection,
  ) async {
    Map<String, dynamic> data = {};

    for (int i = 0; i < fields.length; i++) {
      data[fields[i]] = values[i];
    }

    await FirebaseFirestore.instance.collection(collection).add(data);
    // how to use
    // FbServices().addToFirestore(["name", "age"], ["Ali", 20], "users");
  }

  // another way
  Future<void> addToFirestore02(
    Map<String, dynamic> data,
    String collection,
  ) async {
    await FirebaseFirestore.instance.collection(collection).add(data);
    // how to use
    // FbServices().addToFirestore02({"name": "Ali", "age": 20}, "users");
  }
}
