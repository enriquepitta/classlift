import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarFooter extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final VoidCallback onTap;
  final VoidCallback? onTodayTap;
  final bool showTodayButton;

  const CalendarFooter({
    super.key,
    required this.calendarFormat,
    required this.onTap,
    this.onTodayTap,
    this.showTodayButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: ClassliftColors.calendarSurface,
          boxShadow: [
            BoxShadow(
                color: Color(0x0D5276B0), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 25,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Tooltip(
                message: calendarFormat == CalendarFormat.week
                    ? 'Expandir calendario'
                    : 'Contraer calendario',
                child: SizedBox(
                  width: 48,
                  height: 25,
                  child: Center(
                    child: Icon(
                      calendarFormat == CalendarFormat.week
                          ? Icons.expand_more
                          : Icons.expand_less,
                      color: ClassliftColors.calendarMuted,
                      size: 25,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: showTodayButton && onTodayTap != null
                      ? _TodayButton(onTap: onTodayTap!)
                      : const SizedBox.shrink(key: ValueKey('today-hidden')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ir a hoy',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('today-visible'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: ClassliftColors.calendarTodaySurface,
              border: Border.all(
                color: ClassliftColors.calendarTodayAccent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.today_rounded,
                  color: ClassliftColors.calendarInk,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Hoy',
                  style: TextStyle(
                    color: ClassliftColors.calendarInk,
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
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
