import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarFooter extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final VoidCallback onTap;

  CalendarFooter({
    required this.calendarFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: ClassliftColors.primaryGradient,
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Icon(
            calendarFormat == CalendarFormat.week
                ? Icons.expand_more
                : Icons.expand_less,
            color: ClassliftColors.White,
            size: 25,
          ),
        ),
      ),
    );
  }
}
