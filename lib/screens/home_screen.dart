import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:classify/utils/classlift_colors.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Intl.defaultLocale = 'es_ES'; // Configura el idioma en español
  }

  void _toggleCalendarFormat() {
    setState(() {
      _calendarFormat = _calendarFormat == CalendarFormat.week
          ? CalendarFormat.month
          : CalendarFormat.week;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Horario de Clases",
          style: TextStyle(
            color: ClassliftColors.SecondaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ClassliftColors.PrimaryColor,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.today, color: ClassliftColors.White),
          //   onPressed: () {
          //     setState(() {
          //       _selectedDay = DateTime.now();
          //       _focusedDay = DateTime.now();
          //     });
          //   },
          // ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ClassliftColors.White, ClassliftColors.BackgroundColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Calendario
            CalendarWidget(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              calendarFormat: _calendarFormat,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
            // Footer interactivo
            CalendarFooter(
              calendarFormat: _calendarFormat,
              onTap: _toggleCalendarFormat,
            ),
            // Día seleccionado
            Expanded(
              child: Center(
                child: Text(
                  _selectedDay != null
                      ? 'Día seleccionado: ${DateFormat.yMMMMd('es_ES').format(_selectedDay!)}'
                      : 'Selecciona un día',
                  style: TextStyle(
                    fontSize: 16,
                    color: ClassliftColors.TextColor,
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

class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;

  CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: ClassliftColors.primaryGradient,
      ),
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
        calendarStyle: CalendarStyle(
          weekendTextStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
          defaultTextStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: TextStyle(
            color: ClassliftColors.SecondaryColor,
            fontWeight: FontWeight.bold,
          ),
          todayDecoration: BoxDecoration(),
          selectedDecoration: BoxDecoration(
            gradient: ClassliftColors.secondaryGradient,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: ClassliftColors.PrimaryColor,
            fontWeight: FontWeight.bold,
          ),
          outsideTextStyle: TextStyle(
            color: Colors.white54,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextFormatter: (date, locale) {
            String formattedDate = DateFormat('MMMM', 'es_ES').format(date);
            return formattedDate[0].toUpperCase() + formattedDate.substring(1);
          },
          titleTextStyle: TextStyle(
            color: ClassliftColors.White,
            fontSize: 18,
            fontWeight: FontWeight.normal,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: ClassliftColors.White,
            size: 24,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: ClassliftColors.White,
            size: 24,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          dowTextFormatter: (date, locale) =>
              DateFormat.E(locale).format(date)[0].toUpperCase(),
          weekdayStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: TextStyle(
            color: ClassliftColors.White,
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final String dayText = DateFormat.E('es_ES').format(day)[0].toUpperCase();
            final bool isToday = isSameDay(day, DateTime.now());

            return Center(
              child: Text(
                dayText,
                style: TextStyle(
                  color: isToday ? ClassliftColors.SecondaryColor : ClassliftColors.White,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Icon(
            calendarFormat == CalendarFormat.week
                ? Icons.expand_more
                : Icons.expand_less,
            color: ClassliftColors.White,
            size: 24,
          ),
        ),
      ),
    );
  }
}
