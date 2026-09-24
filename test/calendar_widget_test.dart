import 'package:classlift/widgets/home/calendar/calendar_footer.dart';
import 'package:classlift/widgets/home/calendar/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_ES'));

  testWidgets('Letters and dates select the same day and can clear selection',
      (tester) async {
    final key = GlobalKey<CalendarHarnessState>();
    await tester.pumpWidget(MaterialApp(home: CalendarHarness(key: key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('V').hitTestable());
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 25)),
        isTrue);
    await tester.tap(find.text('25').hitTestable());
    await tester.pumpAndSettle();
    expect(key.currentState!.selected, isNull);
    await tester.tap(find.text('22').hitTestable());
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 22)),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Chevrons and swipes page through weeks without changing selection',
      (tester) async {
    final key = GlobalKey<CalendarHarnessState>();
    await tester.pumpWidget(MaterialApp(home: CalendarHarness(key: key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.focused, DateTime.utc(2026, 10, 1)),
        isTrue);
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 24)),
        isTrue);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.focused, DateTime.utc(2026, 9, 24)),
        isTrue);
    await tester.drag(find.byType(TableCalendar), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.focused, DateTime.utc(2026, 10, 1)),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Month expansion preserves selection and weekday headings remain passive',
      (tester) async {
    final key = GlobalKey<CalendarHarnessState>();
    await tester.pumpWidget(MaterialApp(home: CalendarHarness(key: key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(key.currentState!.format, CalendarFormat.month);
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 24)),
        isTrue);
    await tester.tap(find.text('V').hitTestable());
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 24)),
        isTrue);
    await tester.tap(find.text('15').hitTestable());
    await tester.pumpAndSettle();
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 15)),
        isTrue);
    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pumpAndSettle();
    expect(key.currentState!.format, CalendarFormat.week);
    expect(isSameDay(key.currentState!.selected, DateTime.utc(2026, 9, 15)),
        isTrue);
    expect(tester.takeException(), isNull);
  });
}

class CalendarHarness extends StatefulWidget {
  const CalendarHarness({super.key});

  @override
  State<CalendarHarness> createState() => CalendarHarnessState();
}

class CalendarHarnessState extends State<CalendarHarness> {
  DateTime focused = DateTime.utc(2026, 9, 24);
  DateTime? selected = DateTime.utc(2026, 9, 24);
  CalendarFormat format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(children: [
      CalendarWidget(
        focusedDay: focused,
        selectedDay: selected,
        calendarFormat: format,
        classCountByDay: const {
          'Lunes': 2,
          'Martes': 3,
          'Jueves': 2,
          'Viernes': 1
        },
        onDaySelected: (day, focus) => setState(() {
          selected = isSameDay(selected, day) ? null : day;
          focused = focus;
        }),
        onFormatChanged: (value) => setState(() => format = value),
        onPageChanged: (value) => setState(() => focused = value),
      ),
      CalendarFooter(
          calendarFormat: format,
          onTap: () => setState(() {
                format = format == CalendarFormat.week
                    ? CalendarFormat.month
                    : CalendarFormat.week;
              })),
    ]));
  }
}
