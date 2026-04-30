import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/group_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _groupService = GroupService();
  final _user = FirebaseAuth.instance.currentUser!;

  void _showCreateGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _GroupDialog(
        title: 'Crear grupo',
        subtitle: 'Elige un nombre para tu grupo',
        hint: 'Nombre del grupo...',
        icon: Icons.group_add_outlined,
        confirmLabel: 'Crear',
        controller: ctrl,
        onConfirm: () async {
          final nombre = ctrl.text.trim();
          if (nombre.isEmpty) return;
          Navigator.pop(context);
          try {
            final codigo = await _groupService.createGroup(nombre);
            if (mounted) _showCodeDialog(nombre, codigo);
          } catch (e) {
            if (mounted) _showError('$e');
          }
        },
      ),
    );
  }

  void _showJoinGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _GroupDialog(
        title: 'Unirse a grupo',
        subtitle: 'Introduce el código de invitación',
        hint: 'Código (ej: ABC123)...',
        icon: Icons.login_rounded,
        confirmLabel: 'Unirse',
        controller: ctrl,
        uppercase: true,
        onConfirm: () async {
          final codigo = ctrl.text.trim();
          if (codigo.isEmpty) return;
          Navigator.pop(context);
          try {
            final nombre = await _groupService.joinGroup(codigo);
            if (mounted) {
              _showSnack('✓ Te has unido a "$nombre"', success: true);
            }
          } catch (e) {
            if (mounted) _showError('$e');
          }
        },
      ),
    );
  }

  void _showCodeDialog(String nombre, String codigo) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFBB86FC).withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFBB86FC), Color(0xFF6C3483)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"$nombre" creado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comparte este código con tu grupo:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Código grande
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: codigo));
                      _showSnack('Código copiado', success: true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2FBE).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFBB86FC).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            codigo,
                            style: const TextStyle(
                              color: Color(0xFFBB86FC),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.copy_rounded,
                            color: Color(0xFFBB86FC),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(
                          0xFFBB86FC,
                        ).withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Listo',
                        style: TextStyle(
                          color: Color(0xFFBB86FC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLeave(String groupId, String nombre) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Salir del grupo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Seguro que quieres salir de "$nombre"?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
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
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _groupService.leaveGroup(groupId);
                            if (mounted) {
                              _showSnack('Saliste de "$nombre"');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Salir',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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

  void _showError(String msg) => _showSnack(msg, success: false);

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success
            ? const Color(0xFF6C3483)
            : Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
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
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perfil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Tu cuenta y grupos',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Card usuario
                  _GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBB86FC), Color(0xFF6C3483)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              (_user.email?[0] ?? '?').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cuenta',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _user.email ?? 'Sin email',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Cerrar sesión
                        IconButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          tooltip: 'Cerrar sesión',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sección grupos
                  const Text(
                    'Mis grupos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comparte lista y consumos con otros',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botones crear / unirse
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add_rounded,
                          label: 'Crear grupo',
                          onTap: _showCreateGroupDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.login_rounded,
                          label: 'Unirse',
                          onTap: _showJoinGroupDialog,
                          outlined: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Lista de grupos
                  StreamBuilder<QuerySnapshot>(
                    stream: _groupService.getMyGroups(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              color: Color(0xFFBB86FC),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }

                      final groups = snap.data?.docs ?? [];

                      if (groups.isEmpty) {
                        return _GlassCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                color: Colors.white12,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin grupos todavía',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Crea uno o únete con un código',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: groups.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nombre = data['nombre'] as String? ?? '';
                          return _GroupTile(
                            groupId: doc.id,
                            nombre: nombre,
                            groupService: _groupService,
                            onLeave: () => _confirmLeave(doc.id, nombre),
                            onShowCode: () async {
                              final code = await _groupService.getGroupCode(
                                doc.id,
                              );
                              if (mounted) _showCodeDialog(nombre, code);
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Group tile ───────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final String groupId;
  final String nombre;
  final GroupService groupService;
  final VoidCallback onLeave;
  final VoidCallback onShowCode;

  const _GroupTile({
    required this.groupId,
    required this.nombre,
    required this.groupService,
    required this.onLeave,
    required this.onShowCode,
  });

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
              color: const Color(0xFF9B59B6).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFBB86FC).withOpacity(0.12),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B2FBE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: Color(0xFFBB86FC),
                  size: 20,
                ),
              ),
              title: Text(
                nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupId)
                    .get(),
                builder: (_, snap) {
                  final count = snap.hasData
                      ? (snap.data!.data() as Map<String, dynamic>?) != null
                            ? ['miembros']?.length
                            : 0
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          color: const Color(0xFFBB86FC).withOpacity(0.5),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count ${count == 1 ? 'miembro' : 'miembros'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onShowCode,
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Color(0xFFBB86FC),
                      size: 20,
                    ),
                    tooltip: 'Ver código',
                  ),
                  IconButton(
                    onPressed: onLeave,
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white24,
                      size: 20,
                    ),
                    tooltip: 'Salir',
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

// ── Widgets auxiliares ───────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF9B59B6).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFBB86FC).withOpacity(0.14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: outlined
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFBB86FC).withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: const Color(0xFFBB86FC), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFBB86FC),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _GroupDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hint;
  final IconData icon;
  final String confirmLabel;
  final TextEditingController controller;
  final VoidCallback onConfirm;
  final bool uppercase;

  const _GroupDialog({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.icon,
    required this.confirmLabel,
    required this.controller,
    required this.onConfirm,
    this.uppercase = false,
  });

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: uppercase
                      ? TextCapitalization.characters
                      : TextCapitalization.sentences,
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: uppercase ? 4 : 0,
                    fontWeight: uppercase ? FontWeight.w700 : FontWeight.normal,
                  ),
                  onSubmitted: (_) => onConfirm(),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(
                      icon,
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
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
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
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
