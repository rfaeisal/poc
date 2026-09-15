import 'package:flutter/material.dart';

class KsunNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KsunNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF060910),
        border: Border(top: BorderSide(color: Color(0xFF0F1E2E), width: 1)),
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'CH',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            label: 'SET',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? const Color(0xFF4A9EFF) : const Color(0xFF2A4A6A);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: isActive ? const Color(0xFF0A1628) : Colors.transparent,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
