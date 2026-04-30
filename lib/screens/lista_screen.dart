import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mysynclist/widgets/scope_selector.dart';
import '../services/lista_service.dart';
import '../widgets/scope_selector.dart';

// ── Cloudinary config ─────────────────────────────────────────────────
const _kCloudName = 'dlmcldvqc';
const _kUploadPreset = 'mysynclist_preset';

class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  final _service = ListaService();
  final _ctrl = TextEditingController();
  bool _adding = false;
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

  void _showAddDialog() {
    _ctrl.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AddItemDialog(
        controller: _ctrl,
        onConfirm: _addItem,
        isGroup: _selectedGroupId != null,
      ),
    );
  }

  Future<void> _addItem({
    required String nombre,
    double? precio,
    String? photoUrl,
  }) async {
    if (nombre.isEmpty) return;
    setState(() => _adding = true);
    try {
      await _service.addItem(
        nombre,
        groupId: _selectedGroupId,
        price: precio,
        photoUrl: photoUrl,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFF6C3483),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
            left: -60,
            child: _Orb(color: const Color(0xFF7B2FBE), size: 260),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _Orb(color: const Color(0xFF4A0E8F), size: 280),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBB86FC), Color(0xFF6C3483)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFBB86FC).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.list_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mi Lista',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            _selectedGroupId == null
                                ? 'Lista personal'
                                : 'Lista de grupo',
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

                if (_initialized)
                  ScopeSelector(
                    selectedGroupId: _selectedGroupId,
                    onChanged: (id) => setState(() => _selectedGroupId = id),
                  ),

                const SizedBox(height: 16),

                Expanded(
                  child: !_initialized
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFBB86FC),
                            strokeWidth: 2,
                          ),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: _service.getLista(groupId: _selectedGroupId),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];

                            double total = 0;

                            for (final doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final precio =
                                  (data['precio'] as num?)?.toDouble() ?? 0;
                              final comprado =
                                  data['comprado'] as bool? ?? false;

                              if (comprado) total += precio;
                            }

                            return Column(
                              children: [
                                // 🔥 TOTAL AQUÍ ARRIBA
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          '${total.toStringAsFixed(2)} €',
                                          style: const TextStyle(
                                            color: Color(0xFFBB86FC),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 🔥 LISTA ABAJO
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    itemCount: docs.length,
                                    itemBuilder: (context, i) {
                                      final doc = docs[i];
                                      final data =
                                          doc.data() as Map<String, dynamic>;

                                      final comprado =
                                          data['comprado'] as bool? ?? false;
                                      final nombre =
                                          data['nombre'] as String? ?? '';
                                      final precio = (data['precio'] as num?)
                                          ?.toDouble();
                                      final photoUrl =
                                          data['photoUrl'] as String?;

                                      return _ItemTile(
                                        nombre: nombre,
                                        comprado: comprado,
                                        precio: precio,
                                        photoUrl: photoUrl,
                                        onToggle: () => _service.toggleComprado(
                                          doc.id,
                                          comprado,
                                          groupId: _selectedGroupId,
                                        ),
                                        onDelete: () => _service.deleteItem(
                                          doc.id,
                                          groupId: _selectedGroupId,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _adding
          ? const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Color(0xFFBB86FC),
                strokeWidth: 2,
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBB86FC), Color(0xFF6C3483)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showAddDialog,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
    );
  }
}

// ── Item tile ────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final String nombre;
  final bool comprado;
  final double? precio;
  final String? photoUrl;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.nombre,
    required this.comprado,
    required this.onToggle,
    required this.onDelete,
    this.precio,
    this.photoUrl,
  });

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(nombre, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl!,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 12),
            if (precio != null)
              Text(
                '${precio!.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              comprado ? 'Comprado ✅' : 'Pendiente 🛒',
              style: const TextStyle(color: Colors.white54),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: comprado
                  ? const Color(0xFF6C3483).withOpacity(0.25)
                  : const Color(0xFF9B59B6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: comprado
                    ? const Color(0xFFBB86FC).withOpacity(0.3)
                    : const Color(0xFFBB86FC).withOpacity(0.1),
              ),
            ),
            child: ListTile(
              onTap: () => _showDetails(context),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),

              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: comprado
                            ? const Color(0xFFBB86FC)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: comprado
                              ? const Color(0xFFBB86FC)
                              : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: comprado
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),

                  if (photoUrl != null) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2FBE).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: comprado ? Colors.white38 : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  decoration: comprado
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.white38,
                ),
                child: Text(nombre),
              ),

              subtitle: precio != null
                  ? Text(
                      '${precio!.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: comprado
                            ? Colors.white24
                            : const Color(0xFFBB86FC).withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,

              trailing: IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white24,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Add dialog ───────────────────────────────────────────────────────

class _AddItemDialog extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function({
    required String nombre,
    double? precio,
    String? photoUrl,
  })
  onConfirm;
  final bool isGroup;

  const _AddItemDialog({
    required this.controller,
    required this.onConfirm,
    required this.isGroup,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _precioCtrl = TextEditingController();
  File? _pickedImage;
  bool _uploading = false;

  @override
  void dispose() {
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(),
    );
    if (source == null) return;

    final xfile = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (xfile != null && mounted) {
      setState(() => _pickedImage = File(xfile.path));
    }
  }

  void _removeImage() => setState(() => _pickedImage = null);

  /// Sube la imagen a Cloudinary con un unsigned preset (sin API key).
  Future<String?> _uploadImage(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_kCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _kUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final body = jsonDecode(await streamed.stream.bytesToString());

    if (streamed.statusCode != 200) {
      throw Exception(body['error']?['message'] ?? 'Error al subir imagen');
    }

    return body['secure_url'] as String?;
  }

  Future<void> _confirm() async {
    final nombre = widget.controller.text.trim();
    if (nombre.isEmpty) return;

    setState(() => _uploading = true);

    try {
      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await _uploadImage(_pickedImage!);
      }

      final precioText = _precioCtrl.text.trim().replaceAll(',', '.');
      final precio = precioText.isNotEmpty ? double.tryParse(precioText) : null;

      await widget.onConfirm(
        nombre: nombre,
        precio: precio,
        photoUrl: photoUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: $e'),
            backgroundColor: const Color(0xFF6C3483),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A2E).withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFBB86FC).withOpacity(0.2),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Añadir item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isGroup
                        ? 'Se añadirá a la lista del grupo'
                        : 'Se añadirá a tu lista personal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo nombre
                  TextField(
                    controller: widget.controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _confirm(),
                    decoration: InputDecoration(
                      hintText: 'Nombre del producto...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      prefixIcon: Icon(
                        Icons.shopping_bag_outlined,
                        color: const Color(0xFFBB86FC).withOpacity(0.7),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF7B2FBE).withOpacity(0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFBB86FC).withOpacity(0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFBB86FC),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Campo precio
                  TextField(
                    controller: _precioCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Precio (opcional)',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      prefixIcon: Icon(
                        Icons.euro_rounded,
                        color: const Color(0xFFBB86FC).withOpacity(0.7),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF7B2FBE).withOpacity(0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: const Color(0xFFBB86FC).withOpacity(0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFBB86FC),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sección foto
                  if (_pickedImage == null)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B2FBE).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFBB86FC).withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: const Color(0xFFBB86FC).withOpacity(0.6),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Añadir foto (opcional)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _pickedImage!,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cambiar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _uploading
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9B59B6).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _uploading ? null : _confirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Añadir',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Selector de fuente de imagen ─────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A2E).withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: const Color(0xFFBB86FC).withOpacity(0.15)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Seleccionar foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'Cámara',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: 'Galería',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF7B2FBE).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBB86FC).withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFBB86FC).withOpacity(0.8),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orb ──────────────────────────────────────────────────────────────

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
