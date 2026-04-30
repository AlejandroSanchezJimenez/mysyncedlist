import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class GroupService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // Crear grupo
  Future<String> createGroup(String nombre) async {
    final codigo = _generateCode();
    final ref = await _db.collection('groups').add({
      'nombre': nombre.trim(),
      'creadoPor': _uid,
      'codigo': codigo,
      'miembros': [_uid],
      'creadoEn': FieldValue.serverTimestamp(),
    });

    // Guarda referencia en el usuario
    await _db
        .collection('users')
        .doc(_uid)
        .collection('groups')
        .doc(ref.id)
        .set({
          'groupId': ref.id,
          'nombre': nombre.trim(),
          'joinedAt': FieldValue.serverTimestamp(),
        });

    return codigo;
  }

  // Unirse a grupo por código
  Future<String> joinGroup(String codigo) async {
    final snap = await _db
        .collection('groups')
        .where('codigo', isEqualTo: codigo.toUpperCase().trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) throw Exception('Código no válido');

    final doc = snap.docs.first;
    final data = doc.data();
    final miembros = List<String>.from(data['miembros'] ?? []);

    if (miembros.contains(_uid))
      throw Exception('Ya eres miembro de este grupo');

    miembros.add(_uid);
    await _db.collection('groups').doc(doc.id).update({'miembros': miembros});

    await _db
        .collection('users')
        .doc(_uid)
        .collection('groups')
        .doc(doc.id)
        .set({
          'groupId': doc.id,
          'nombre': data['nombre'],
          'joinedAt': FieldValue.serverTimestamp(),
        });

    return data['nombre'];
  }

  // Stream de grupos del usuario
  Stream<QuerySnapshot> getMyGroups() => _db
      .collection('users')
      .doc(_uid)
      .collection('groups')
      .orderBy('joinedAt', descending: false)
      .snapshots();

  // Salir de un grupo
  Future<void> leaveGroup(String groupId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('groups')
        .doc(groupId)
        .delete();

    final ref = _db.collection('groups').doc(groupId);
    final snap = await ref.get();
    final miembros = List<String>.from(snap.data()?['miembros'] ?? []);
    miembros.remove(_uid);

    if (miembros.isEmpty) {
      await ref.delete();
    } else {
      await ref.update({'miembros': miembros});
    }
  }

  // Obtener código de un grupo
  Future<String> getGroupCode(String groupId) async {
    final snap = await _db.collection('groups').doc(groupId).get();
    return snap.data()?['codigo'] ?? '';
  }
}
