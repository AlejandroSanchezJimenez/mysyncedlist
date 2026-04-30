import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final db = FirebaseFirestore.instance;

  Stream getItems(String groupId) {
    return db.collection("groups").doc(groupId).collection("items").snapshots();
  }

  Future addItem(String groupId, Map<String, dynamic> data) {
    return db.collection("groups").doc(groupId).collection("items").add(data);
  }
}
