import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListaService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Rutas dinámicas según modo
  CollectionReference _lista({String? groupId}) => groupId != null
      ? _db.collection('groups').doc(groupId).collection('lista')
      : _db.collection('users').doc(_uid).collection('lista');

  CollectionReference _consumos({String? groupId}) => groupId != null
      ? _db.collection('groups').doc(groupId).collection('consumos')
      : _db.collection('users').doc(_uid).collection('consumos');

  Stream<QuerySnapshot> getLista({String? groupId}) => _lista(
    groupId: groupId,
  ).orderBy('fechaAdd', descending: true).snapshots();

  Stream<QuerySnapshot> getConsumos({String? groupId}) => _consumos(
    groupId: groupId,
  ).orderBy('veces', descending: true).snapshots();

  Future<void> addItem(
    String nombre, {
    String? groupId,
    double? price,
    String? photoUrl,
  }) async {
    final nombreLower = nombre.trim().toLowerCase();

    await _lista(groupId: groupId).add({
      'nombre': nombre.trim(),
      'comprado': false,
      'fechaAdd': FieldValue.serverTimestamp(),
      if (price != null) 'precio': price,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });

    final existing = await _consumos(
      groupId: groupId,
    ).where('nombreLower', isEqualTo: nombreLower).limit(1).get();

    if (existing.docs.isEmpty) {
      await _consumos(groupId: groupId).add({
        'nombre': nombre.trim(),
        'nombreLower': nombreLower,
        'fechaPrimera': FieldValue.serverTimestamp(),
        'veces': 1,

        // 🔥 NUEVO
        'precio': price,
        'photoUrl': photoUrl,
      });
    } else {
      await _consumos(groupId: groupId).doc(existing.docs.first.id).update({
        'veces': FieldValue.increment(1),

        if (price != null) 'precio': price,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    }
  }

  Future<void> toggleComprado(String itemId, bool actual, {String? groupId}) =>
      _lista(groupId: groupId).doc(itemId).update({'comprado': !actual});

  Future<void> deleteItem(String itemId, {String? groupId}) =>
      _lista(groupId: groupId).doc(itemId).delete();

  Future<void> deleteConsumo(String consumoId, {String? groupId}) async {
    if (consumoId.isEmpty) return;
    await _consumos(groupId: groupId).doc(consumoId).delete();
  }

  /// Actualiza un consumo (precio y/o photoUrl)
  Future<void> updateConsumo(
    String consumoId, {
    String? groupId,
    double? precio,
    String? photoUrl,
  }) async {
    if (consumoId.isEmpty) return;

    final Map<String, dynamic> updates = {};
    if (precio != null) updates['precio'] = precio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isEmpty) return;

    await _consumos(groupId: groupId).doc(consumoId).update(updates);
  }
}
