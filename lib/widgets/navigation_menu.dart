import 'dart:ui';

import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onAddPressed;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onAddPressed,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.calendar_month_outlined, label: 'Horario'),
    (icon: Icons.check_box_outlined, label: 'Tareas'),
    (icon: Icons.more_horiz_rounded, label: 'Más'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Acerca la barra al home indicator sin depender del padding de SafeArea.
    final bottomSpacing = Theme.of(context).platform == TargetPlatform.iOS
        ? (bottomInset - 8).clamp(0.0, double.infinity).toDouble()
        : bottomInset;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(26, 0, 26, bottomSpacing),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: ClassliftColors.navigationShadow.withOpacity(0.16),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: ClassliftColors.navigationShadow.withOpacity(0.20),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 74,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: ClassliftColors.White.withOpacity(0.2),
                          width: 0.8,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ClassliftColors.navigationGlass.withOpacity(0.0),
                            ClassliftColors.navigationGlass.withOpacity(0.0),
                          ],
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth =
                              constraints.maxWidth / _items.length;
                          return Stack(
                            children: [
                              AnimatedPositionedDirectional(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                start: selectedIndex * itemWidth,
                                top: 0,
                                bottom: 0,
                                width: itemWidth,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: ClassliftColors.White.withOpacity(
                                          0.85),
                                      width: 0.6,
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        ClassliftColors.White.withOpacity(0.78),
                                        ClassliftColors.navigationSelected
                                            .withOpacity(0.88),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ClassliftColors.navigationAccent
                                            .withOpacity(0.10),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  for (var i = 0; i < _items.length; i++)
                                    Expanded(
                                      child: _NavigationItem(
                                        icon: _items[i].icon,
                                        label: _items[i].label,
                                        isSelected: selectedIndex == i,
                                        onTap: () => onItemTapped(i),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ClassliftColors.navigationShadow.withOpacity(0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: ClassliftColors.navigationShadow.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: 60,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ClassliftColors.navigationAccent.withOpacity(0.70),
                            ClassliftColors.navigationAccentEnd
                                .withOpacity(0.44),
                          ],
                        ),
                      ),
                      child: Material(
                        color: ClassliftColors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          onPressed: onAddPressed,
                          tooltip: 'Añadir',
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add_rounded,
                            color: ClassliftColors.White,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        ? ClassliftColors.navigationAccent
        : ClassliftColors.navigationMuted;

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: ClassliftColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 25),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
