import 'dart:ui';

import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/widgets/home/schedule_quick_add.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HomeMenuItem {
  home(Icons.home_rounded, 'Inicio'),
  schedule(Icons.calendar_month_outlined, 'Horario'),
  tasks(Icons.check_box_outlined, 'Tareas'),
  more(Icons.more_horiz_rounded, 'Más'),
  evaluations(Icons.event_note_outlined, 'Próximas evaluaciones'),
  calculator(Icons.calculate_outlined, 'Calculadora FPUNA'),
  moodle(Icons.school_outlined, 'Conectar Moodle'),
  privacy(Icons.privacy_tip_outlined, 'Política de privacidad');

  const HomeMenuItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class CustomBottomNavigationBar extends StatelessWidget {
  static const _mainItems = [
    HomeMenuItem.home,
    HomeMenuItem.schedule,
    HomeMenuItem.tasks,
  ];
  static const _compactItems = [
    ..._mainItems,
    HomeMenuItem.more,
  ];
  static const _additionalItems = [
    HomeMenuItem.evaluations,
    HomeMenuItem.calculator,
    HomeMenuItem.moodle,
    HomeMenuItem.privacy,
  ];

  final HomeMenuItem selectedItem;
  final ValueChanged<HomeMenuItem> onItemTapped;
  final VoidCallback onAddFacultySchedule;
  final VoidCallback onImportExcel;
  final VoidCallback onAddOpened;
  final bool expanded;
  final bool moodleConnected;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedItem,
    required this.expanded,
    required this.moodleConnected,
    required this.onItemTapped,
    required this.onAddFacultySchedule,
    required this.onImportExcel,
    required this.onAddOpened,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Acerca la barra al home indicator sin depender del padding de SafeArea.
    final bottomSpacing = Theme.of(context).platform == TargetPlatform.iOS
        ? (bottomInset - 8).clamp(0.0, double.infinity).toDouble()
        : bottomInset;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260);
    const curve = Curves.easeOutCubic;
    final maxMenuHeight = (MediaQuery.sizeOf(context).height -
            MediaQuery.viewPaddingOf(Overlay.of(context).context).top -
            bottomSpacing -
            32)
        .clamp(0.0, double.infinity)
        .toDouble();

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, bottomSpacing),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: ClassliftColors.navigationShadow
                          .withValues(alpha: .16),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: ClassliftColors.navigationShadow
                          .withValues(alpha: .20),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: AnimatedContainer(
                      duration: duration,
                      curve: curve,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: ClassliftColors.White.withValues(
                              alpha: expanded ? .78 : .20),
                          width: 0.8,
                        ),
                        color: ClassliftColors.navigationGlass
                            .withValues(alpha: expanded ? .90 : 0),
                      ),
                      child: AnimatedSize(
                        alignment: Alignment.bottomCenter,
                        duration: duration,
                        curve: curve,
                        child: expanded
                            ? _expandedMenu(maxMenuHeight)
                            : SizedBox(
                                height: 58.4,
                                child: _compactMenu(duration),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: ScheduleQuickAdd(
                onFaculty: onAddFacultySchedule,
                onExcel: onImportExcel,
                onOpened: onAddOpened,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactMenu(Duration duration) => LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _compactItems.length;
          return Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: duration,
                curve: Curves.easeOutCubic,
                start: _compactItems.indexOf(selectedItem) * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: ClassliftColors.White.withValues(alpha: .85),
                      width: .6,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ClassliftColors.White.withValues(alpha: .78),
                        ClassliftColors.navigationSelected
                            .withValues(alpha: .88),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ClassliftColors.navigationAccent
                            .withValues(alpha: .10),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in _compactItems)
                    Expanded(
                      child: _NavigationItem(
                        icon: item.icon,
                        label: item.label,
                        isSelected: selectedItem == item,
                        onTap: () => onItemTapped(item),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      );

  Widget _expandedMenu(double maxHeight) {
    void close() => onItemTapped(HomeMenuItem.more);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: FocusScope(
        autofocus: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    children: [
                      for (final item in _mainItems) _expandedItem(item),
                      const Divider(
                        color: ClassliftColors.subjectListBorder,
                        height: 13,
                        indent: 16,
                        endIndent: 16,
                      ),
                      for (final item in _additionalItems) _expandedItem(item),
                    ],
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: TextButton.icon(
                  onPressed: close,
                  style: TextButton.styleFrom(
                    foregroundColor: ClassliftColors.navigationMuted,
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 23),
                  iconAlignment: IconAlignment.end,
                  label: const Text('Cerrar menú', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expandedItem(HomeMenuItem item) {
    final isSelected = selectedItem == item;
    final label = item == HomeMenuItem.moodle && moodleConnected
        ? 'Cambiar campus Moodle'
        : item.label;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected
            ? ClassliftColors.White.withValues(alpha: .8)
            : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onItemTapped(item),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 49),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected
                        ? ClassliftColors.navigationAccent
                        : ClassliftColors.PrimaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? ClassliftColors.navigationAccent
                            : ClassliftColors.PrimaryColor,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
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
