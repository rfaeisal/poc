import 'package:flutter/material.dart';

class HyteraNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HyteraNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF060910),
        border: Border(top: BorderSide(color: Color(0xFF0F1E2E), width: 1)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.cell_tower,
            label: 'Channel',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Pesan',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Pengaturan',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF4A9EFF) : const Color(0xFF2A4A6A);

    return Expanded(
      child: Focus(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: isActive ? const Color(0xFF0A1628) : Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
