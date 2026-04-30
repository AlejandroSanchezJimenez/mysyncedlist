import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class ScopeSelector extends StatelessWidget {
  final String? selectedGroupId;
  final ValueChanged<String?> onChanged; // null = personal

  const ScopeSelector({
    super.key,
    required this.selectedGroupId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('groups')
          .orderBy('joinedAt')
          .snapshots(),
      builder: (context, snap) {
        final groups = snap.data?.docs ?? [];

        final tabs = <_ScopeTab>[
          const _ScopeTab(
            id: null,
            label: 'Personal',
            icon: Icons.person_rounded,
          ),
          ...groups.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _ScopeTab(
              id: doc.id,
              label: data['nombre'] as String? ?? 'Grupo',
              icon: Icons.group_rounded,
            );
          }),
        ];

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tab = tabs[i];
              final selected = selectedGroupId == tab.id;
              return GestureDetector(
                onTap: () => onChanged(tab.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                          )
                        : null,
                    color: selected
                        ? null
                        : const Color(0xFF7B2FBE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : const Color(0xFFBB86FC).withOpacity(0.15),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF9B59B6).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 14,
                        color: selected ? Colors.white : Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white38,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ScopeTab {
  final String? id;
  final String label;
  final IconData icon;
  const _ScopeTab({required this.id, required this.label, required this.icon});
}
