import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final ValueChanged<String> onFilePicked;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onFilePicked,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 78,
      color: ClassliftColors.White,
      elevation: 14,
      shadowColor: ClassliftColors.PrimaryColor.withOpacity(0.12),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              isSelected: selectedIndex == 0,
              onTap: () => onItemTapped(0),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.calendar_month_outlined,
              label: 'Horario',
              isSelected: selectedIndex == 1,
              onTap: () => onItemTapped(1),
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            child: _NavigationItem(
              icon: Icons.check_box_outlined,
              label: 'Tareas',
              isSelected: selectedIndex == 2,
              onTap: () => onItemTapped(2),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.bar_chart_rounded,
              label: 'Más',
              isSelected: selectedIndex == 3,
              onTap: () => onItemTapped(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? ClassliftColors.PrimaryColor
        : ClassliftColors.PrimaryColor.withOpacity(0.70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: isSelected ? 42 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: ClassliftColors.PrimaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
