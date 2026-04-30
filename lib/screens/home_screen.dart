import 'package:flutter/material.dart';
import 'dart:ui';
import 'lista_screen.dart';
import 'consumos_screen.dart';
import 'perfil_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ListaScreen(),
    ConsumosScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0910),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _PurpleNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _PurpleNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PurpleNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.list_alt_rounded, Icons.list_alt_outlined, 'Lista'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Consumos'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Perfil'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A2E).withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFBB86FC).withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final selected = i == currentIndex;
                  final (iconOn, iconOff, label) = items[i];
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFBB86FC).withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selected ? iconOn : iconOff,
                              key: ValueKey(selected),
                              color: selected
                                  ? const Color(0xFFBB86FC)
                                  : Colors.white38,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? const Color(0xFFBB86FC)
                                  : Colors.white38,
                            ),
                            child: Text(label),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
