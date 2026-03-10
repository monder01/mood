import 'package:cloud_firestore/cloud_firestore.dart';

class FbServices {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // add document
  Future<void> add({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    await firestore.collection(collection).add(data);
  }

  // update document
  Future<void> update({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await firestore.collection(collection).doc(docId).update(data);
  }

  // delete document
  Future<void> delete({
    required String collection,
    required String docId,
  }) async {
    await firestore.collection(collection).doc(docId).delete();
  }

  // get data once
  Future<QuerySnapshot> get({required String collection}) async {
    return await firestore.collection(collection).get();
  }

  // realtime stream
  Stream<QuerySnapshot> stream({required String collection}) {
    return firestore.collection(collection).snapshots();
  }
}
// how to use
// FbServices().add(
//   collection: "users",
//   data: {
//     "name": "Ali",
//     "age": 20,
//   },
// );
// FbServices().update(
//   collection: "users",
//   docId: "documentID",
//   data: {
//     "name": "Ahmed",
//   },
// );
// FbServices().delete(
//   collection: "users",
//   docId: "documentID",
// );
// QuerySnapshot snapshot = await FbServices().get(collection: "users");

// for (var doc in snapshot.docs) {
//   print(doc["name"]);
// }
// StreamBuilder(
//   stream: FbServices().stream(collection: "users"),
//   builder: (context, snapshot) {
//     if (!snapshot.hasData) {
//       return CircularProgressIndicator();
//     }

//     var docs = snapshot.data!.docs;

//     return ListView.builder(
//       itemCount: docs.length,
//       itemBuilder: (context, index) {
//         return Text(docs[index]["name"]);
//       },
//     );
//   },
// )
