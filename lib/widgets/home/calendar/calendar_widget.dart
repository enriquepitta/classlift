import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
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
              gradient: ClassliftColors.primaryGradient,
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
              color: ClassliftColors.White,
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: const TextStyle(
              color: ClassliftColors.White,
              fontWeight: FontWeight.bold,
            ),
            todayTextStyle: const TextStyle(
              color: ClassliftColors.SecondaryColor,
              fontWeight: FontWeight.bold,
            ),
            todayDecoration: const BoxDecoration(),
            selectedDecoration: const BoxDecoration(),
            selectedTextStyle: const TextStyle(
              color: ClassliftColors.PrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            outsideTextStyle: const TextStyle(
              color: ClassliftColors.white54,
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
              color: ClassliftColors.White,
              fontSize: 18,
              fontWeight: FontWeight.normal,
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left,
              color: ClassliftColors.White,
              size: 24,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right,
              color: ClassliftColors.White,
              size: 24,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, locale) =>
                DateFormat.E(locale).format(date)[0].toUpperCase(),
            weekdayStyle: const TextStyle(
              color: ClassliftColors.White,
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: const TextStyle(
              color: ClassliftColors.White,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              final String dayText =
                  DateFormat.E('es_ES').format(day)[0].toUpperCase();
              final bool isToday = isSameDay(day, DateTime.now());
              // El encabezado forma parte de la selección únicamente en la
              // vista semanal. En la vista expandida solo se resalta la fecha.
              final isSelected = calendarFormat == CalendarFormat.week &&
                  isSameDay(selectedDay, day);

              // El Align evita que el builder del encabezado estire el fondo
              // a todo el ancho de la columna. Así coincide con la fecha.
              return Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 38,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ClassliftColors.SecondaryColor
                        : ClassliftColors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    dayText,
                    style: TextStyle(
                      color: isSelected
                          ? ClassliftColors.PrimaryColor
                          : isToday
                              ? ClassliftColors.SecondaryColor
                              : ClassliftColors.White,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
    final isOutsideMonth =
        day.month != focusedDay.month || day.year != focusedDay.year;

    final textColor = isSelected
        ? ClassliftColors.PrimaryColor
        : isOutsideMonth
            ? ClassliftColors.white54
            : isToday
                ? ClassliftColors.SecondaryColor
                : ClassliftColors.White;

    // En semana se desplaza suavemente hacia el encabezado para que ambas
    // mitades se perciban como una única selección continua.
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: Offset(0, isSelected && isWeekView ? -0.24 : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? ClassliftColors.SecondaryColor
              : ClassliftColors.transparent,
          borderRadius: isWeekView
              ? const BorderRadius.vertical(bottom: Radius.circular(10))
              : BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight:
                    isOutsideMonth ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            // Se dibujan aquí (y no con eventLoader), por lo que incluso la
            // fecha seleccionada conserva sus puntos sin duplicarlos.
            if (classCount > 0) ...[
              const SizedBox(height: 2),
              _classDots(
                classCount,
                isSelected
                    ? ClassliftColors.PrimaryColor
                    : ClassliftColors.SecondaryColor,
              ),
            ],
          ],
        ),
      ),
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
