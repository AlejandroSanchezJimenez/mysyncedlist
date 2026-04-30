import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/lista_service.dart';
import '../widgets/scope_selector.dart';

class ConsumosScreen extends StatefulWidget {
  const ConsumosScreen({super.key});

  @override
  State<ConsumosScreen> createState() => _ConsumosScreenState();
}

class _ConsumosScreenState extends State<ConsumosScreen> {
  final _service = ListaService();
  final _searchCtrl = TextEditingController();

  String _query = '';
  String? _selectedGroupId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultScope();
  }

  Future<void> _loadDefaultScope() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('groups')
        .orderBy('joinedAt')
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        _selectedGroupId = snap.docs.isNotEmpty ? snap.docs.first.id : null;
        _initialized = true;
      });
    }
  }

  Future<void> _addToLista(
    String nombre, {
    double? precio,
    String? photoUrl,
  }) async {
    try {
      await _service.addItem(
        nombre,
        groupId: _selectedGroupId,
        price: precio,
        photoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$nombre" añadido a la lista'),
            backgroundColor: const Color(0xFF6C3483),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0910),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _Orb(color: const Color(0xFF7B2FBE), size: 260),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: _Orb(color: const Color(0xFF4A0E8F), size: 280),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consumos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedGroupId == null
                                ? 'Historial personal'
                                : 'Historial de grupo',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SCOPES
                if (_initialized)
                  ScopeSelector(
                    selectedGroupId: _selectedGroupId,
                    onChanged: (id) => setState(() => _selectedGroupId = id),
                  ),

                const SizedBox(height: 12),

                // SEARCH
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.toLowerCase().trim()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white38,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: !_initialized
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
                          stream: _service.getConsumos(
                            groupId: _selectedGroupId,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final consumos = snapshot.data!.docs;

                            return StreamBuilder<QuerySnapshot>(
                              stream: _service.getLista(
                                groupId: _selectedGroupId,
                              ),
                              builder: (context, listaSnap) {
                                final enLista = <String>{};

                                for (final doc in listaSnap.data?.docs ?? []) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  enLista.add(
                                    (data['nombre'] ?? '').toLowerCase(),
                                  );
                                }

                                final filtered = consumos.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final nombre = (data['nombre'] ?? '')
                                      .toLowerCase();

                                  return _query.isEmpty ||
                                      nombre.contains(_query);
                                }).toList();

                                if (filtered.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Sin consumos',
                                      style: TextStyle(color: Colors.white38),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) {
                                    final data =
                                        filtered[i].data()
                                            as Map<String, dynamic>;

                                    final nombre = data['nombre'] ?? '';
                                    final veces = data['veces'] ?? 1;
                                    final photoUrl = data['photoUrl'];

                                    final yaEnLista = enLista.contains(
                                      nombre.toLowerCase(),
                                    );

                                    return _ConsumoTile(
                                      id: filtered[i].id,
                                      nombre: nombre,
                                      veces: veces,
                                      photoUrl: photoUrl,
                                      yaEnLista: yaEnLista,
                                      onDelete: () => _service.deleteConsumo(
                                        filtered[i].id,
                                        groupId: _selectedGroupId,
                                      ),

                                      onUpdate: (precio, photoUrl) =>
                                          _service.updateConsumo(
                                            filtered[i].id,
                                            groupId: _selectedGroupId,
                                            precio: precio,
                                            photoUrl: photoUrl,
                                          ),
                                      onAddToLista: yaEnLista
                                          ? null
                                          : () => _addToLista(
                                              nombre,
                                              precio: data['precio'],
                                              photoUrl: data['photoUrl'],
                                            ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumoTile extends StatelessWidget {
  final String nombre;
  final int veces;
  final bool yaEnLista;
  final String? photoUrl;
  final VoidCallback? onAddToLista;
  final String id;
  final VoidCallback? onDelete;
  final Future<void> Function(double? precio, String? photoUrl)? onUpdate;

  const _ConsumoTile({
    required this.id,
    required this.nombre,
    required this.veces,
    required this.yaEnLista,
    required this.onAddToLista,
    this.photoUrl,
    this.onDelete,
    this.onUpdate,
  });

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: Text(nombre, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(photoUrl!),
              )
            else
              const Icon(
                Icons.image_not_supported,
                color: Colors.white24,
                size: 50,
              ),
            const SizedBox(height: 12),
            Text(
              '$veces consumos',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Color(0xFFBB86FC)),
            ),
          ),

          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context);
            },
            child: const Text('Editar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  photoUrl!,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
              )
            else
              const Icon(Icons.shopping_bag, color: Colors.white38),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: const TextStyle(color: Colors.white)),
                  Text(
                    '$veces veces',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

            yaEnLista
                ? const Text(
                    'En lista',
                    style: TextStyle(color: Color(0xFFBB86FC)),
                  )
                : IconButton(
                    onPressed: onAddToLista,
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final precioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text(
          'Editar consumo',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Nuevo precio',
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final precio = double.tryParse(precioCtrl.text);

              await onUpdate?.call(precio, null);

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Guardar',
              style: TextStyle(color: Color(0xFFBB86FC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.35), color.withOpacity(0)],
        ),
      ),
    );
  }
}
