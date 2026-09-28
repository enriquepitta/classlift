import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
  static const _selectionAnimationDuration = Duration(milliseconds: 260);
  static const _selectionAnimationCurve = Curves.easeOutCubic;

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<String, int> classCountByDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final bool showBackground;

  CalendarWidget({
    this.showBackground = true,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.classCountByDay,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showBackground
          ? BoxDecoration(
              gradient: ClassliftColors.calendarSurfaceGradient,
            )
          : null,
      child: SafeArea(
        child: TableCalendar(
          locale: 'es_ES',
          focusedDay: focusedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          calendarFormat: calendarFormat,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,
          daysOfWeekHeight: 40,
          rowHeight: calendarFormat == CalendarFormat.week ? 38 : 42,
          calendarStyle: CalendarStyle(
            weekendTextStyle: const TextStyle(
              color: ClassliftColors.calendarInk,
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: const TextStyle(
              color: ClassliftColors.calendarInk,
              fontWeight: FontWeight.bold,
            ),
            todayTextStyle: const TextStyle(
              color: ClassliftColors.calendarToday,
              fontWeight: FontWeight.bold,
            ),
            todayDecoration: const BoxDecoration(),
            selectedDecoration: const BoxDecoration(),
            selectedTextStyle: const TextStyle(
              color: ClassliftColors.calendarSelectionInk,
              fontWeight: FontWeight.bold,
            ),
            outsideTextStyle: const TextStyle(
              color: ClassliftColors.calendarOutside,
            ),
          ),
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextFormatter: (date, locale) {
              String formattedDate = DateFormat('MMMM', 'es_ES').format(date);
              return formattedDate[0].toUpperCase() +
                  formattedDate.substring(1);
            },
            titleTextStyle: const TextStyle(
              color: ClassliftColors.calendarInk,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: ClassliftColors.calendarInk,
              size: 24,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: ClassliftColors.calendarInk,
              size: 24,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, locale) =>
                DateFormat.E(locale).format(date)[0].toUpperCase(),
            weekdayStyle: const TextStyle(
              color: ClassliftColors.calendarInk,
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: const TextStyle(
              color: ClassliftColors.calendarInk,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              final dayText =
                  DateFormat.E('es_ES').format(day)[0].toUpperCase();
              final isToday = isSameDay(day, DateTime.now());
              final isSelectedDay = isSameDay(selectedDay, day);
              final highlightTodayHeader =
                  calendarFormat == CalendarFormat.week &&
                      isToday &&
                      !isSelectedDay;
              final isSelected =
                  calendarFormat == CalendarFormat.week && isSelectedDay;

              final header = Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 38,
                  height: 34,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        duration: _selectionAnimationDuration,
                        curve: _selectionAnimationCurve,
                        opacity: highlightTodayHeader ? 1 : 0,
                        child: AnimatedContainer(
                          duration: _selectionAnimationDuration,
                          curve: _selectionAnimationCurve,
                          width: 38,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: ClassliftColors.calendarTodaySurface,
                            border: Border(
                              top: BorderSide(
                                color: ClassliftColors.calendarTodayAccent,
                                width: 1.3,
                              ),
                              left: BorderSide(
                                color: ClassliftColors.calendarTodayAccent,
                                width: 1.3,
                              ),
                              right: BorderSide(
                                color: ClassliftColors.calendarTodayAccent,
                                width: 1.3,
                              ),
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: _selectionAnimationDuration,
                        curve: _selectionAnimationCurve,
                        opacity: isSelected ? 1 : 0,
                        child: Container(
                          width: 38,
                          height: 34,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                ClassliftColors.calendarSelectionTop,
                                ClassliftColors.calendarAccent
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: _selectionAnimationDuration,
                        curve: _selectionAnimationCurve,
                        style: TextStyle(
                          color: isSelected
                              ? ClassliftColors.calendarSelectionInk
                              : highlightTodayHeader
                                  ? ClassliftColors.calendarInk
                                  : ClassliftColors.calendarMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(dayText),
                      ),
                    ],
                  ),
                ),
              );

              if (calendarFormat != CalendarFormat.week) return header;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onDaySelected(day, day),
                child: header,
              );
            },
            defaultBuilder: (context, day, focusedDay) => _dayCell(day),
            todayBuilder: (context, day, focusedDay) => _dayCell(day),
            selectedBuilder: (context, day, focusedDay) => _dayCell(day),
            outsideBuilder: (context, day, focusedDay) => _dayCell(day),
          ),
        ),
      ),
    );
  }

  int _classCountFor(DateTime day) {
    const dayNames = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return classCountByDay[dayNames[day.weekday - 1]] ?? 0;
  }

  Widget _dayCell(DateTime day) {
    final classCount = _classCountFor(day);
    final isSelected = isSameDay(selectedDay, day);
    final isWeekView = calendarFormat == CalendarFormat.week;
    final isToday = isSameDay(day, DateTime.now());
    final highlightToday = isToday && !isSelected;
    final isOutsideMonth =
        day.month != focusedDay.month || day.year != focusedDay.year;

    final textColor = isSelected
        ? ClassliftColors.calendarSelectionInk
        : isOutsideMonth
            ? ClassliftColors.calendarOutside
            : highlightToday
                ? ClassliftColors.calendarTodayAccent
                : ClassliftColors.calendarInk;

    final cellBorderRadius = isWeekView
        ? const BorderRadius.vertical(bottom: Radius.circular(10))
        : BorderRadius.circular(10);
    final cellContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: _selectionAnimationDuration,
          curve: _selectionAnimationCurve,
          style: TextStyle(
            color: textColor,
            fontWeight: isOutsideMonth ? FontWeight.normal : FontWeight.bold,
          ),
          child: Text('${day.day}'),
        ),
        if (classCount > 0) ...[
          const SizedBox(height: 2),
          _classDots(
            classCount,
            isSelected
                ? ClassliftColors.calendarSelectionInk
                : ClassliftColors.calendarDots,
          ),
        ],
      ],
    );

    final cell = SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: _selectionAnimationDuration,
            curve: _selectionAnimationCurve,
            opacity: highlightToday ? 1 : 0,
            child: AnimatedContainer(
              duration: _selectionAnimationDuration,
              curve: _selectionAnimationCurve,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ClassliftColors.calendarTodaySurface,
                border: isWeekView
                    ? const Border(
                        left: BorderSide(
                          color: ClassliftColors.calendarTodayAccent,
                          width: 1.3,
                        ),
                        right: BorderSide(
                          color: ClassliftColors.calendarTodayAccent,
                          width: 1.3,
                        ),
                        bottom: BorderSide(
                          color: ClassliftColors.calendarTodayAccent,
                          width: 1.3,
                        ),
                      )
                    : Border.all(
                        color: ClassliftColors.calendarTodayAccent,
                        width: 1.3,
                      ),
                borderRadius: cellBorderRadius,
              ),
            ),
          ),
          AnimatedOpacity(
            duration: _selectionAnimationDuration,
            curve: _selectionAnimationCurve,
            opacity: isSelected ? 1 : 0,
            child: AnimatedContainer(
              duration: _selectionAnimationDuration,
              curve: _selectionAnimationCurve,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ClassliftColors.calendarAccent,
                    ClassliftColors.calendarSelectionBottom
                  ],
                ),
                borderRadius: cellBorderRadius,
              ),
            ),
          ),
          cellContent,
        ],
      ),
    );

    return AnimatedSlide(
      duration: _selectionAnimationDuration,
      curve: _selectionAnimationCurve,
      offset: isWeekView ? const Offset(0, -0.08) : Offset.zero,
      child: cell,
    );
  }

  Widget _classDots(int count, Color color) {
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (index) => Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 2),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
