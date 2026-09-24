import 'package:classlift/components/evaluation_bottom_sheet.dart';
import 'package:classlift/utils/excel_picker_service.dart';
import 'package:classlift/utils/options_bottom_sheet.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:classlift/widgets/home/calendar/calendar_widget.dart';
import 'package:classlift/widgets/home/calendar/calendar_footer.dart';
import 'package:classlift/widgets/navigation_menu.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/models/database_models.dart';
import 'package:classlift/services/database_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'select_career.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';
import 'package:classlift/utils/home_subtitle.dart';
import 'package:classlift/widgets/home/pending_tasks_section.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classlift/widgets/home/home_profile_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _dismissedScheduleRecommendationKey =
      'dismissed_schedule_recommendation';
  static const _dismissedEducaRecommendationKey =
      'dismissed_educa_recommendation';

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedIndex = 0;
  List<ScheduledClass> _classesForSelectedDay = [];
  List<ScheduledClass> _allActiveClasses = [];
  Map<String, int> _classesCountByDay = {};
  Map<String, int> _colorIndexBySubject = {};
  _NextClassOccurrence? _nextClassOccurrence;
  List<UpcomingEvaluation> _nextEvaluations = [];
  bool _isWeeklySummary = false;
  bool _signingOut = false;
  bool _dismissedScheduleRecommendation = false;
  bool _dismissedEducaRecommendation = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await DatabaseService.clearAllData();
      MoodleAuthService.instance.signOut();
      MoodleTasksService.clearCache();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No se pudo cerrar sesión. Intentá nuevamente.'),
      ));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _refreshMoodleTasks() {
    MoodleTasksService.loadCurrentSession();
  }

  Future<void> _connectMoodle() async {
    await context.push('/login/moodle');
  }

  bool _isLoadingClasses = true;
  double _horizontalDragDistance = 0;
  int _dayTransitionDirection = 1;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    Intl.defaultLocale = 'es_ES';
    if (MoodleAuthService.instance.session != null &&
        MoodleTasksService.lastLoad == null) {
      MoodleTasksService.loadCurrentSession();
    }

    // Añadir observer para detectar cuando la app regrese del background
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClassesForSelectedDay();
      _loadRecommendationPreferences();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadClassesForSelectedDay();
      _refreshMoodleTasks();
    }
  }

  Future<void> _loadClassesForSelectedDay() async {
    final selectedDay = _selectedDay;
    if (selectedDay == null) return;

    setState(() => _isLoadingClasses = true);
    final results = await Future.wait([
      DatabaseService.getClassesForDay(_dayNameFor(selectedDay)),
      DatabaseService.getClassesCountByDay(),
      DatabaseService.getSelectedSubjects(),
      DatabaseService.getAllActiveClasses(),
      DatabaseService.getNextUpcomingEvaluations(),
    ]);
    final classes = results[0] as List<ScheduledClass>;
    final countsByDay = results[1] as Map<String, int>;
    final subjects = results[2] as List<SelectedSubject>;
    final allClasses = results[3] as List<ScheduledClass>;
    final nextEvaluations = results[4] as List<UpcomingEvaluation>;

    if (!mounted || !isSameDay(selectedDay, _selectedDay)) return;
    setState(() {
      _classesForSelectedDay = classes;
      _allActiveClasses = allClasses;
      _classesCountByDay = countsByDay;
      _colorIndexBySubject = _buildColorIndexes(subjects);
      _nextClassOccurrence = _findNextClassAfter(selectedDay, allClasses);
      _nextEvaluations = nextEvaluations;
      _isLoadingClasses = false;
    });
  }

  Future<void> _loadRecommendationPreferences() async {
    final results = await Future.wait([
      DatabaseService.getAppSetting(_dismissedScheduleRecommendationKey),
      DatabaseService.getAppSetting(_dismissedEducaRecommendationKey),
    ]);

    if (!mounted) return;
    setState(() {
      _dismissedScheduleRecommendation = results[0] == 'true';
      _dismissedEducaRecommendation = results[1] == 'true';
    });
  }

  Future<void> _dismissRecommendation(String key) async {
    if (key == _dismissedScheduleRecommendationKey) {
      setState(() => _dismissedScheduleRecommendation = true);
    } else if (key == _dismissedEducaRecommendationKey) {
      setState(() => _dismissedEducaRecommendation = true);
    }

    await DatabaseService.setAppSetting(key, 'true');
  }

  String _dayNameFor(DateTime day) {
    const dayNames = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dayNames[day.weekday - 1];
  }

  String _homeSubtitle(MoodleTasksResult? moodleTasks) {
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final hasSchedule = _allActiveClasses.isNotEmpty;
    final classesToday = _allActiveClasses
        .where(
            (scheduledClass) => scheduledClass.dayOfWeek == _dayNameFor(today))
        .length;
    final examsToday = _nextEvaluations
        .where((evaluation) => DateUtils.isSameDay(evaluation.date, today))
        .length;
    final examsTomorrow = _nextEvaluations
        .where((evaluation) => DateUtils.isSameDay(evaluation.date, tomorrow))
        .length;
    final isMoodleConnected = MoodleAuthService.instance.session != null;
    final tasksDueToday = isMoodleConnected
        ? (moodleTasks?.tasks
                .where((task) =>
                    !task.submitted &&
                    task.dueDate != null &&
                    DateUtils.isSameDay(task.dueDate, today))
                .length ??
            0)
        : 0;

    return getHomeSubtitle(
      hasSchedule: hasSchedule,
      classesToday: classesToday,
      examsToday: examsToday,
      examsTomorrow: examsTomorrow,
      tasksDueToday: tasksDueToday,
      isMoodleConnected: isMoodleConnected,
    );
  }

  _NextClassOccurrence? _findNextClassAfter(
    DateTime day,
    List<ScheduledClass> classes,
  ) {
    _NextClassOccurrence? nextOccurrence;
    final selectedDate = DateUtils.dateOnly(day);

    for (final scheduledClass in classes) {
      final classWeekday = _weekdayForName(scheduledClass.dayOfWeek);
      if (classWeekday == null) continue;

      final daysUntilClass = (classWeekday - selectedDate.weekday + 7) % 7;
      final date = selectedDate.add(Duration(days: daysUntilClass));
      final occurrence = _NextClassOccurrence(
        scheduledClass: scheduledClass,
        date: date,
      );
      if (nextOccurrence == null ||
          occurrence.startsAt.isBefore(nextOccurrence.startsAt)) {
        nextOccurrence = occurrence;
      }
    }
    return nextOccurrence;
  }

  int? _weekdayForName(String dayName) {
    const weekdays = {
      'Lunes': DateTime.monday,
      'Martes': DateTime.tuesday,
      'Miércoles': DateTime.wednesday,
      'Jueves': DateTime.thursday,
      'Viernes': DateTime.friday,
      'Sábado': DateTime.saturday,
      'Domingo': DateTime.sunday,
    };
    return weekdays[dayName];
  }

  void _goToNextClass(_NextClassOccurrence occurrence) {
    setState(() {
      _dayTransitionDirection = 1;
      _selectedDay = occurrence.date;
      _focusedDay = occurrence.date;
      _isWeeklySummary = false;
    });
    _loadClassesForSelectedDay();
  }

  void _toggleWeeklySummary(DateTime selectedDay, DateTime focusedDay) {
    if (isSameDay(selectedDay, _selectedDay)) {
      setState(() {
        _selectedDay = null;
        _focusedDay = focusedDay;
        _isWeeklySummary = true;
      });
      return;
    }

    setState(() {
      _dayTransitionDirection = selectedDay.isAfter(_focusedDay) ? 1 : -1;
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _isWeeklySummary = false;
    });
    _loadClassesForSelectedDay();
  }

  void _selectWeeklyDay(DateTime day) {
    setState(() {
      _dayTransitionDirection = day.isAfter(_focusedDay) ? 1 : -1;
      _selectedDay = day;
      _focusedDay = day;
      _isWeeklySummary = false;
    });
    _loadClassesForSelectedDay();
  }

  String get _contentKey {
    if (_isWeeklySummary) {
      final weekStart = _weekStartFor(_focusedDay);
      return 'week-${weekStart.millisecondsSinceEpoch}';
    }
    return 'day-${_selectedDay?.millisecondsSinceEpoch ?? 0}';
  }

  void _changeSelectedDay(int dayOffset) {
    final currentDay = _selectedDay;
    if (currentDay == null) return;

    final nextDay = DateUtils.dateOnly(
      currentDay.add(Duration(days: dayOffset)),
    );
    final firstDay = DateTime.utc(2020, 1, 1);
    final lastDay = DateTime.utc(2030, 12, 31);
    if (nextDay.isBefore(firstDay) || nextDay.isAfter(lastDay)) return;

    setState(() {
      _dayTransitionDirection = dayOffset.isNegative ? -1 : 1;
      _selectedDay = nextDay;
      // Mantiene el calendario centrado en el nuevo día, incluso al cruzar
      // semanas o meses.
      _focusedDay = nextDay;
    });
    _loadClassesForSelectedDay();
  }

  void _handleDaySwipeEnd(DragEndDetails details) {
    const minimumDragDistance = 48.0;
    const minimumVelocity = 380.0;
    final velocity = details.primaryVelocity ?? 0;
    final didSwipeLeft = _horizontalDragDistance < -minimumDragDistance ||
        velocity < -minimumVelocity;
    final didSwipeRight = _horizontalDragDistance > minimumDragDistance ||
        velocity > minimumVelocity;

    if (didSwipeLeft) {
      _changeSelectedDay(1);
    } else if (didSwipeRight) {
      _changeSelectedDay(-1);
    }
    _horizontalDragDistance = 0;
  }

  Future<void> _startExcelImport() async {
    try {
      final result = await ExcelPickerService.pickSheets();
      if (!mounted) return;

      final materialRoute = MaterialPageRoute(
        builder: (_) => SelectCareerScreen(
          availableSheets: result['sheets'] as List<String>,
          excelFilePath: result['path'] as String,
        ),
      );

      Navigator.push(context, materialRoute).then((_) {
        _loadClassesForSelectedDay();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: ClassliftColors.White, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al seleccionar archivo: $e')),
            ],
          ),
          backgroundColor: ClassliftColors.red,
        ),
      );
    }
  }

  Future<void> _handleExcel() async {
    Navigator.pop(context);
    await _startExcelImport();
  }

  void _handleManual() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función manual próximamente...'),
        backgroundColor: ClassliftColors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Future<MoodleTasksResult>?>(
        valueListenable: MoodleTasksService.loadListenable,
        builder: (context, tasks, _) => _buildHome(context, tasks),
      );

  Widget _buildHome(BuildContext context, Future<MoodleTasksResult>? tasks) {
    final showNewUserState = !_isLoadingClasses && _allActiveClasses.isEmpty;
    final hasMoodleSession = MoodleAuthService.instance.session != null;
    final cachedTasks = hasMoodleSession ? MoodleTasksService.lastResult : null;
    final showScheduleRecommendation =
        !_dismissedScheduleRecommendation && showNewUserState;
    final showEducaRecommendation =
        !_dismissedEducaRecommendation && !hasMoodleSession;

    return Scaffold(
      extendBody: true,
      backgroundColor: ClassliftColors.homeBackground,
      body: Container(
        color: ClassliftColors.homeBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white, Colors.white],
                    stops: [0, 0.15, 1],
                  ).createShader(bounds),
                  child: Image.asset(
                    'assets/images/classlift_home_background.png',
                    fit: BoxFit.fitWidth,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                      gradient: ClassliftColors.calendarSurfaceGradient),
                  child: Column(children: [
                    FutureBuilder<MoodleTasksResult>(
                      future: hasMoodleSession ? tasks : null,
                      initialData: cachedTasks,
                      builder: (context, snapshot) => HomeProfileHeader(
                        displayName:
                            FirebaseAuth.instance.currentUser?.displayName ??
                                MoodleAuthService.instance.session?.fullName,
                        email: FirebaseAuth.instance.currentUser?.email,
                        subtitle: _homeSubtitle(snapshot.data),
                        signingOut: _signingOut,
                        onSignOut: _signOut,
                      ),
                    ),
                    // Calendario (parte superior)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _calendarFormat == CalendarFormat.week
                            ? 0.84
                            : 0.94,
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: CalendarWidget(
                            showBackground: false,
                            focusedDay: _focusedDay,
                            selectedDay: _selectedDay,
                            calendarFormat: _calendarFormat,
                            classCountByDay: _classesCountByDay,
                            onDaySelected: _toggleWeeklySummary,
                            onFormatChanged: (fmt) =>
                                setState(() => _calendarFormat = fmt),
                            onPageChanged: (foc) =>
                                setState(() => _focusedDay = foc),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                // Footer del calendario
                CalendarFooter(
                  calendarFormat: _calendarFormat,
                  onTap: () => setState(() {
                    _calendarFormat = _calendarFormat == CalendarFormat.week
                        ? CalendarFormat.month
                        : CalendarFormat.week;
                  }),
                ),

                // Área principal con scroll para mostrar materias
                Expanded(
                  child: GestureDetector(
                    // Ocupa toda el área disponible, también la parte vacía de
                    // días sin clases. El ScrollView conserva el gesto vertical.
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) => _horizontalDragDistance = 0,
                    onHorizontalDragUpdate: (details) {
                      _horizontalDragDistance += details.delta.dx;
                    },
                    onHorizontalDragEnd: _handleDaySwipeEnd,
                    child: SizedBox.expand(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        reverseDuration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        // AnimatedSwitcher centra sus hijos por defecto. Al usar un
                        // Stack alineado arriba, el horario empieza siempre justo
                        // debajo del calendario, sin importar cuántas clases haya.
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                        transitionBuilder: (child, animation) {
                          final isIncoming = child.key == ValueKey(_contentKey);
                          final offset = isIncoming
                              ? Offset(_dayTransitionDirection * 0.08, 0)
                              : Offset(-_dayTransitionDirection * 0.08, 0);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: offset,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_contentKey),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(
                              bottom:
                                  92 + MediaQuery.viewPaddingOf(context).bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showNewUserState) ...[
                                  if (showScheduleRecommendation ||
                                      showEducaRecommendation)
                                    _buildNewUserSetupSection(
                                      showScheduleCard:
                                          showScheduleRecommendation,
                                      showEducaCard: showEducaRecommendation,
                                    ),
                                  if (hasMoodleSession)
                                    PendingTasksSection(
                                      future: tasks,
                                      onRefresh: _refreshMoodleTasks,
                                    ),
                                ] else ...[
                                  _isWeeklySummary
                                      ? _buildWeeklySummary()
                                      : Column(
                                          children: [
                                            _buildDailySchedule(),
                                            _buildUpcomingEvaluations(),
                                          ],
                                        ),
                                  if (hasMoodleSession)
                                    PendingTasksSection(
                                      future: tasks,
                                      onRefresh: _refreshMoodleTasks,
                                    )
                                  else if (showEducaRecommendation)
                                    _buildMoodleConnectSection(),
                                ],
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (i) {
          if (i == 2) {
            context.go('/tasks');
            return;
          }
          setState(() => _selectedIndex = i);
        },
        onAddPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: ClassliftColors.transparent,
          barrierColor: ClassliftColors.PrimaryColor.withOpacity(0.15),
          builder: (_) => OptionsBottomSheet(
            onExcel: _handleExcel,
            onManual: _handleManual,
          ),
        ),
      ),
    );
  }

  Widget _buildNewUserSetupSection({
    required bool showScheduleCard,
    required bool showEducaCard,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          if (showScheduleCard)
            _DismissibleSetupRecommendation(
              key: const ValueKey(_dismissedScheduleRecommendationKey),
              onDismissed: () =>
                  _dismissRecommendation(_dismissedScheduleRecommendationKey),
              child: _SetupCard(
                backgroundColor: ClassliftColors.setupScheduleBackground,
                accentColor: ClassliftColors.homeAction,
                titleColor: ClassliftColors.PrimaryColor,
                eyebrow: 'Recomendado',
                title: 'Configurá tu horario',
                description:
                    'Importá el horario de tu facultad y seleccioná las materias que estás cursando.',
                actionLabel: 'Importar horario',
                actionIcon: Icons.description_outlined,
                illustrationIcon: Icons.calendar_month_rounded,
                badgeIcon: Icons.add_rounded,
                onAction: _startExcelImport,
              ),
            ),
          if (showEducaCard) ...[
            if (showScheduleCard) const SizedBox(height: 12),
            _buildMoodleConnectCard(
              onDismissed: () =>
                  _dismissRecommendation(_dismissedEducaRecommendationKey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodleConnectSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: _buildMoodleConnectCard(
        onDismissed: () =>
            _dismissRecommendation(_dismissedEducaRecommendationKey),
      ),
    );
  }

  Widget _buildMoodleConnectCard({required VoidCallback onDismissed}) {
    return _DismissibleSetupRecommendation(
      key: const ValueKey(_dismissedEducaRecommendationKey),
      onDismissed: onDismissed,
      child: _SetupCard(
        backgroundColor: ClassliftColors.educaSoftBackground,
        accentColor: ClassliftColors.educaRed,
        titleColor: ClassliftColors.educaDarkRed,
        eyebrowColor: ClassliftColors.educaBadge,
        eyebrow: 'EDUCA Moodle',
        title: 'Traé tus tareas al inicio',
        description:
            'Conectá tu campus y ClassLift mostrará tus entregas pendientes en cards apenas vuelvas al Home.',
        actionLabel: 'Conectar Moodle',
        actionIcon: Icons.school_outlined,
        illustrationIcon: Icons.assignment_turned_in_rounded,
        badgeIcon: Icons.sync_rounded,
        onAction: _connectMoodle,
      ),
    );
  }

  Widget _buildDailySchedule() {
    if (_isLoadingClasses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_classesForSelectedDay.isEmpty) {
      return _buildEmptySchedule();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Horario de clases',
              style: TextStyle(
                color: ClassliftColors.PrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvaluations() {
    if (_isLoadingClasses || _nextEvaluations.isEmpty) {
      return const SizedBox.shrink();
    }

    final plural = _nextEvaluations.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plural ? 'Próximas evaluaciones' : 'Próxima evaluación',
            style: const TextStyle(
              color: ClassliftColors.PrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          for (final evaluation in _nextEvaluations)
            Padding(
              padding: EdgeInsets.only(
                bottom: evaluation == _nextEvaluations.last ? 0 : 7,
              ),
              child: _buildUpcomingEvaluationCard(evaluation),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvaluationCard(UpcomingEvaluation evaluation) {
    final subjectName = evaluation.subjectName.split(' — ').first.trim();
    final cardColor = _cardColorFor(subjectName);
    final accentColor = _accentColorFor(cardColor);
    final countdown = _evaluationCountdown(evaluation.date);
    final countdownTextColor = accentColor.computeLuminance() <= 0.183
        ? ClassliftColors.White
        : ClassliftColors.Black;
    final dateLabel =
        DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(evaluation.date);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showEvaluationBottomSheet(
        context,
        evaluation,
        cardColor,
        accentColor,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: accentColor, width: 6)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 82,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                ),
                child: Center(
                  child: Text(
                    countdown,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: countdownTextColor,
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 5, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          evaluation.evaluationType,
                          style: const TextStyle(
                            color: ClassliftColors.White,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_capitalize(dateLabel)}${evaluation.time == null ? '' : ' · ${evaluation.time}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accentColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (evaluation.classroom != null ||
                          evaluation.professor != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (evaluation.professor != null) ...[
                              Icon(Icons.person_rounded,
                                  color: accentColor, size: 14),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  evaluation.professor!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: accentColor.withOpacity(0.86),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ] else
                              const Spacer(),
                            if (evaluation.classroom != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  evaluation.classroom!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ClassliftColors.White,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: accentColor.withOpacity(0.7),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _evaluationCountdown(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final difference = DateUtils.dateOnly(date).difference(today).inDays;
    if (difference == 0) return 'Hoy';
    if (difference == 1) return 'Mañana';
    return '$difference\ndías faltan';
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  Widget _buildWeeklySummary() {
    final weekStart = _weekStartFor(_focusedDay);
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          _buildWeeklyHeader(),
          const SizedBox(height: 14),
          ...weekDays.map(_buildWeeklyDay),
        ],
      ),
    );
  }

  Widget _buildWeeklyHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final iconSize = compact ? 36.0 : 42.0;
        final illustrationWidth = compact ? 58.0 : 72.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 13 : 15,
          ),
          decoration: BoxDecoration(
            color: ClassliftColors.scheduleSummaryBackground,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: ClassliftColors.PrimaryColor.withOpacity(0.76),
                  size: compact ? 27 : 31,
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vista semanal',
                      style: TextStyle(
                        color: ClassliftColors.PrimaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seleccioná un día para ver el detalle de tus clases.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ClassliftColors.PrimaryColor.withOpacity(0.62),
                        fontSize: compact ? 11 : 12,
                        height: 1.28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 10),
              _buildWeeklyHeaderIllustration(illustrationWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyHeaderIllustration(double width) {
    final calendarWidth = width * 0.7;
    final calendarHeight = width * 0.68;
    final headerHeight = width * 0.18;

    return SizedBox(
      width: width,
      height: width * 0.9,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: width * 0.12,
            left: 0,
            child: Container(
              width: calendarWidth,
              height: calendarHeight,
              decoration: BoxDecoration(
                color: ClassliftColors.White,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ClassliftColors.PrimaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: headerHeight,
                    decoration: BoxDecoration(
                      color: ClassliftColors.illustrationHeader,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.1),
                      child: Wrap(
                        spacing: width * 0.07,
                        runSpacing: width * 0.07,
                        children: List.generate(
                          6,
                          (_) => Container(
                            width: width * 0.09,
                            height: width * 0.08,
                            decoration: BoxDecoration(
                              color: ClassliftColors.illustrationCell,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: width * 0.17,
            child: Container(
              width: width * 0.07,
              height: width * 0.24,
              decoration: BoxDecoration(
                color: ClassliftColors.illustrationBinding,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: width * 0.47,
            child: Container(
              width: width * 0.07,
              height: width * 0.24,
              decoration: BoxDecoration(
                color: ClassliftColors.illustrationBinding,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: width * 0.03,
            child: Container(
              width: width * 0.42,
              height: width * 0.42,
              decoration: const BoxDecoration(
                color: ClassliftColors.illustrationBadge,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: ClassliftColors.illustrationCheck,
                size: width * 0.26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDay(DateTime day) {
    final dayName = _dayNameFor(day);
    final classes = _allActiveClasses
        .where((scheduledClass) => scheduledClass.dayOfWeek == dayName)
        .toList()
      ..sort((first, second) => _minutesFromTime(first.startTime)
          .compareTo(_minutesFromTime(second.startTime)));

    return InkWell(
      onTap: () => _selectWeeklyDay(day),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
        decoration: BoxDecoration(
          color: ClassliftColors.PrimaryColor.withOpacity(0.035),
          borderRadius: BorderRadius.circular(16),
        ),
        child: classes.isEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeeklyDayLabel(day),
                  const SizedBox(width: 8),
                  Expanded(child: _buildWeeklyFreeDay()),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: ClassliftColors.PrimaryColor.withOpacity(0.52),
                    size: 21,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeeklyDayLabel(day, width: 28),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.chevron_right_rounded,
                          color: ClassliftColors.PrimaryColor.withOpacity(0.52),
                          size: 21,
                        ),
                        for (final scheduledClass in classes)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: scheduledClass == classes.last ? 0 : 5,
                            ),
                            child: _buildWeeklyClassCard(scheduledClass),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWeeklyDayLabel(DateTime day, {double width = 54}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _shortDayName(day),
            style: TextStyle(
              color: ClassliftColors.PrimaryColor.withOpacity(0.78),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.day}',
            style: const TextStyle(
              color: ClassliftColors.PrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyClassCard(ScheduledClass scheduledClass) {
    final details = _classDetails(scheduledClass);
    final cardColor = _cardColorFor(details.subjectName);
    final accentColor = _accentColorFor(cardColor);
    final location = [
      if (details.section != null) details.section!,
      if (scheduledClass.classroom?.isNotEmpty == true)
        scheduledClass.classroom!,
    ].join(' - ');

    return _SubjectGlassCard(
      color: cardColor,
      accentColor: accentColor,
      radius: 11,
      borderWidth: 4,
      padding: const EdgeInsets.fromLTRB(7, 5, 6, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  details.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildWeeklyLocationBadge(location, accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Flexible(
                flex: 4,
                child: Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: accentColor,
                          size: 12,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ${scheduledClass.startTime} - ${scheduledClass.endTime}',
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.person_rounded,
                          color: accentColor,
                          size: 13,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ${details.professor ?? 'Docente sin registrar'}',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyLocationBadge(String location, Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 70),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          location.isEmpty ? 'Sin aula' : location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ClassliftColors.White,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyFreeDay() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            color: ClassliftColors.emptyScheduleIcon,
            size: 25,
          ),
          SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sin clases',
                style: TextStyle(
                  color: ClassliftColors.PrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Disfrutá el día libre.',
                style: TextStyle(
                  color: ClassliftColors.emptyScheduleText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _weekStartFor(DateTime day) {
    final date = DateUtils.dateOnly(day);
    return date.subtract(Duration(days: date.weekday % DateTime.sunday));
  }

  String _shortDayName(DateTime day) {
    const names = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return names[day.weekday % DateTime.sunday];
  }

  Widget _buildEmptySchedule() {
    final nextClass = _nextClassOccurrence;
    final hasClasses = nextClass != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          _buildEmptyScheduleIllustration(),
          const SizedBox(height: 16),
          Text(
            hasClasses ? 'No tenés clases este día' : 'Todavía no tenés clases',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ClassliftColors.PrimaryColor,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasClasses
                ? 'Disfrutá el día libre y recargá energías\npara lo que viene.'
                : 'Agregá tus materias para organizar tu\nhorario de clases.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ClassliftColors.PrimaryColor.withOpacity(0.62),
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (nextClass != null) ...[
            const SizedBox(height: 26),
            Row(
              children: [
                const Text(
                  'Próxima clase',
                  style: TextStyle(
                    color: ClassliftColors.PrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _goToNextClass(nextClass),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.chevron_right_rounded, size: 19),
                  label: const Text('Ver horario'),
                  style: TextButton.styleFrom(
                    foregroundColor: ClassliftColors.PrimaryColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildNextClassCard(nextClass),
          ],
          const SizedBox(height: 22),
          _buildRestMessage(),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleIllustration() {
    const illustrationColor = ClassliftColors.illustrationPrimary;
    return SizedBox(
      width: 168,
      height: 136,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 136,
            height: 116,
            decoration: BoxDecoration(
              color: illustrationColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(58),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              width: 102,
              height: 86,
              decoration: BoxDecoration(
                color: ClassliftColors.White,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: illustrationColor.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 25,
                    decoration: const BoxDecoration(
                      color: illustrationColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: List.generate(
                      8,
                      (_) => Container(
                        width: 11,
                        height: 9,
                        decoration: BoxDecoration(
                          color: illustrationColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            top: 19,
            right: 23,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: ClassliftColors.illustrationBadge,
              child:
                  Icon(Icons.check_rounded, color: illustrationColor, size: 27),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextClassCard(_NextClassOccurrence occurrence) {
    final scheduledClass = occurrence.scheduledClass;
    final details = _classDetails(scheduledClass);
    final cardColor = _cardColorFor(details.subjectName);
    final accentColor = _accentColorFor(cardColor);
    final dayLabel = _nextClassDayLabel(occurrence.date);

    return InkWell(
      onTap: () => _goToNextClass(occurrence),
      borderRadius: BorderRadius.circular(14),
      child: _SubjectGlassCard(
        color: cardColor,
        accentColor: accentColor,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details.subjectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$dayLabel · ${scheduledClass.startTime} - ${scheduledClass.endTime}',
              style: TextStyle(
                color: accentColor.withOpacity(0.78),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_rounded, size: 17, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    details.professor ?? 'Docente sin registrar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.86),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSectionBadge(
                  details.section,
                  scheduledClass.classroom,
                  accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _nextClassDayLabel(DateTime date) {
    final selectedDay = DateUtils.dateOnly(_selectedDay!);
    final difference = DateUtils.dateOnly(date).difference(selectedDay).inDays;
    if (difference == 1) return 'Mañana';
    if (difference == 0) return 'Hoy';
    return DateFormat('EEEE', 'es_ES').format(date);
  }

  Widget _buildRestMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: ClassliftColors.restMessageBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_sunny_rounded,
              color: ClassliftColors.illustrationPrimary,
              size: 29,
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              color: ClassliftColors.illustrationPrimary.withOpacity(0.28),
            ),
            const Text(
              '“Un descanso también\nes parte del progreso”',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ClassliftColors.illustrationCheck,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final classes = [..._classesForSelectedDay]..sort((first, second) =>
        _minutesFromTime(first.startTime)
            .compareTo(_minutesFromTime(second.startTime)));
    final conflictsByClassIndex = _conflictsByClassIndex(classes);
    final exactTimeConflict = _firstExactTimeConflict(classes);

    return Column(
      children: [
        if (exactTimeConflict != null) ...[
          _buildExactTimeConflictBanner(exactTimeConflict),
          const SizedBox(height: 12),
        ],
        ..._buildTimelineRows(classes, conflictsByClassIndex),
      ],
    );
  }

  List<Widget> _buildTimelineRows(
    List<ScheduledClass> classes,
    Map<int, _ScheduleOverlap> conflictsByClassIndex,
  ) {
    final rows = <Widget>[];
    for (var index = 0; index < classes.length; index++) {
      final sharesRangeWithPrevious =
          index > 0 && _hasSameTimeRange(classes[index - 1], classes[index]);
      final sharesRangeWithNext = index < classes.length - 1 &&
          _hasSameTimeRange(classes[index], classes[index + 1]);
      final conflictForCurrent = conflictsByClassIndex[index];
      final conflictForNext = conflictsByClassIndex[index + 1];

      rows.add(
        _buildTimelineClassRow(
          classes[index],
          startsInConflict: false,
          showStartPoint:
              !sharesRangeWithPrevious && conflictForCurrent == null,
          showEndPoint: !sharesRangeWithNext && conflictForNext == null,
        ),
      );

      if (index == classes.length - 1) continue;
      if (sharesRangeWithNext) {
        rows.add(_buildDirectTimelineConnector());
      } else if (conflictForNext != null) {
        rows.add(
          _buildConflictSeparator(overlap: conflictForNext),
        );
      } else {
        rows.add(
          _buildFreeTimeSeparator(
            gapInMinutes: (_minutesFromTime(classes[index + 1].startTime) -
                    _minutesFromTime(classes[index].endTime))
                .clamp(0, 24 * 60)
                .toInt(),
            nextStartTime: classes[index + 1].startTime,
          ),
        );
      }
    }
    return rows;
  }

  Map<int, _ScheduleOverlap> _conflictsByClassIndex(
      List<ScheduledClass> classes) {
    final conflicts = <int, _ScheduleOverlap>{};
    for (var currentIndex = 1; currentIndex < classes.length; currentIndex++) {
      _ScheduleOverlap? largestOverlap;
      for (var previousIndex = 0;
          previousIndex < currentIndex;
          previousIndex++) {
        final overlap =
            _overlapBetween(classes[previousIndex], classes[currentIndex]);
        if (overlap != null &&
            (largestOverlap == null ||
                overlap.duration > largestOverlap.duration)) {
          largestOverlap = overlap;
        }
      }
      if (largestOverlap != null) conflicts[currentIndex] = largestOverlap;
    }
    return conflicts;
  }

  _ScheduleOverlap? _overlapBetween(
      ScheduledClass first, ScheduledClass second) {
    final firstStart = _minutesFromTime(first.startTime);
    final secondStart = _minutesFromTime(second.startTime);
    final firstEnd = _minutesFromTime(first.endTime);
    final secondEnd = _minutesFromTime(second.endTime);
    final start = firstStart > secondStart ? firstStart : secondStart;
    final end = firstEnd < secondEnd ? firstEnd : secondEnd;
    if (end <= start) return null;
    return _ScheduleOverlap(
      startMinutes: start,
      endMinutes: end,
      conflictingSubjectName: second.subjectName.split(' — ').first,
    );
  }

  bool _hasSameTimeRange(ScheduledClass first, ScheduledClass second) {
    return first.startTime == second.startTime &&
        first.endTime == second.endTime;
  }

  List<ScheduledClass>? _firstExactTimeConflict(List<ScheduledClass> classes) {
    final groups = <String, List<ScheduledClass>>{};
    for (final scheduledClass in classes) {
      final key = '${scheduledClass.startTime}-${scheduledClass.endTime}';
      groups.putIfAbsent(key, () => []).add(scheduledClass);
    }
    for (final group in groups.values) {
      if (group.length > 1) return group;
    }
    return null;
  }

  Widget _buildExactTimeConflictBanner(List<ScheduledClass> classes) {
    final firstClass = classes.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClassliftColors.AccentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ClassliftColors.AccentColor.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: ClassliftColors.AccentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coincidencia de horario',
                  style: TextStyle(
                    color: ClassliftColors.scheduleConflictTitle,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${classes.length} clases se dictan en el mismo horario '
                  '(${firstClass.startTime} - ${firstClass.endTime})',
                  style: TextStyle(
                    color: ClassliftColors.PrimaryColor.withOpacity(0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineClassRow(
    ScheduledClass scheduledClass, {
    required bool startsInConflict,
    required bool showStartPoint,
    required bool showEndPoint,
  }) {
    const timelineWidth = 52.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timelineWidth,
            child: Stack(
              children: [
                Positioned(
                  left: 43,
                  top: showStartPoint ? 8 : 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: ClassliftColors.PrimaryColor.withOpacity(0.45),
                  ),
                ),
                if (showStartPoint)
                  _buildTimePoint(
                    time: scheduledClass.startTime,
                    top: 0,
                    isStart: true,
                    isConflicted: startsInConflict,
                  ),
                if (showEndPoint)
                  _buildTimePoint(
                    time: scheduledClass.endTime,
                    bottom: 0,
                    isStart: false,
                    isConflicted: false,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: _buildClassCard(scheduledClass, inTimeline: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePoint({
    required String time,
    double? top,
    double? bottom,
    required bool isStart,
    required bool isConflicted,
  }) {
    final pointColor = isConflicted
        ? ClassliftColors.AccentColor
        : isStart
            ? ClassliftColors.PrimaryColor
            : ClassliftColors.SecondaryColor;

    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              time,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: isConflicted
                    ? ClassliftColors.AccentColor
                    : isStart
                        ? ClassliftColors.PrimaryColor
                        : ClassliftColors.PrimaryColor.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: pointColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectTimelineConnector() {
    return SizedBox(
      height: 12,
      child: Padding(
        padding: const EdgeInsets.only(left: 43),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 2,
            height: double.infinity,
            color: ClassliftColors.PrimaryColor.withOpacity(0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildFreeTimeSeparator({
    required int gapInMinutes,
    required String nextStartTime,
  }) {
    if (gapInMinutes == 0) return const SizedBox(height: 0);

    final isLongGap = gapInMinutes > 60;
    final height = isLongGap ? 72.0 : 44.0;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 43),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 2,
                  height: double.infinity,
                  child: isLongGap
                      ? const _DashedTimelineConnector()
                      : Container(
                          color: ClassliftColors.PrimaryColor.withOpacity(0.45),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ClassliftColors.PrimaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: ClassliftColors.PrimaryColor.withOpacity(0.78),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: isLongGap
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatFreeTime(gapInMinutes)} libres',
                                  style: const TextStyle(
                                    color: ClassliftColors.PrimaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Siguiente clase a las $nextStartTime',
                                  style: TextStyle(
                                    color: ClassliftColors.PrimaryColor
                                        .withOpacity(0.72),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '${_formatFreeTime(gapInMinutes)} libres',
                              style: const TextStyle(
                                color: ClassliftColors.PrimaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictSeparator({required _ScheduleOverlap overlap}) {
    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Stack(
              children: [
                Positioned(
                  left: 40,
                  top: 8,
                  bottom: 8,
                  child: const SizedBox(
                    width: 8,
                    child: _ConflictTimelineConnector(),
                  ),
                ),
                _buildConflictTimePoint(
                  time: _formatTime(overlap.startMinutes),
                  top: 0,
                ),
                _buildConflictTimePoint(
                  time: _formatTime(overlap.endMinutes),
                  bottom: 0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: ClassliftColors.AccentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.priority_high_rounded,
                      color: ClassliftColors.AccentColor,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cruce con ${overlap.conflictingSubjectName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ClassliftColors.scheduleConflictText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_formatFreeTime(overlap.duration)} en conflicto',
                            style: const TextStyle(
                              color: ClassliftColors.scheduleConflictText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictTimePoint({
    required String time,
    double? top,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: 0,
      right: 0,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              time,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: ClassliftColors.AccentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: ClassliftColors.AccentColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  int _minutesFromTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(int totalMinutes) {
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatFreeTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  Widget _buildClassCard(ScheduledClass scheduledClass,
      {bool inTimeline = false}) {
    final details = _classDetails(scheduledClass);
    final cardColor = _cardColorFor(details.subjectName);
    final accentColor = _accentColorFor(cardColor);
    final durationDots =
        _durationInHours(scheduledClass.startTime, scheduledClass.endTime);

    return _SubjectGlassCard(
      color: cardColor,
      accentColor: accentColor,
      margin: inTimeline ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${scheduledClass.startTime} - ${scheduledClass.endTime}',
                      style: TextStyle(
                          color: accentColor.withOpacity(0.68),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              _buildDurationBadge(durationDots, accentColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: accentColor.withOpacity(0.16),
                      child: Icon(Icons.person, color: accentColor, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        details.professor ?? 'Docente sin registrar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: accentColor.withOpacity(0.82),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildSectionBadge(
                  details.section, scheduledClass.classroom, accentColor),
            ],
          ),
        ],
      ),
    );
  }

  _ClassDetails _classDetails(ScheduledClass scheduledClass) {
    final parts = scheduledClass.subjectName.split(' — ');
    final metadata =
        parts.skip(1).where((part) => !part.contains(':')).toList();
    final section = metadata.firstWhere(
      (part) => RegExp(r'^[A-Z]{1,3}$').hasMatch(part),
      orElse: () => '',
    );
    final professor = metadata.firstWhere(
      (part) =>
          part != section && !const ['Mañana', 'Tarde', 'Noche'].contains(part),
      orElse: () => '',
    );

    return _ClassDetails(
      subjectName: parts.first,
      section: section.isEmpty ? null : section,
      professor: professor.isEmpty ? null : professor,
    );
  }

  int _durationInHours(String startTime, String endTime) {
    int minutes(String time) {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    return ((minutes(endTime) - minutes(startTime)) / 60)
        .ceil()
        .clamp(1, 4)
        .toInt();
  }

  Color _cardColorFor(String subjectName) {
    final index = _colorIndexBySubject[_subjectKey(subjectName)] ??
        _stableSubjectIndex(subjectName);
    return ClassliftColors.subjectBackgroundFor(index);
  }

  Color _accentColorFor(Color cardColor) =>
      ClassliftColors.subjectAccentFor(cardColor);

  Map<String, int> _buildColorIndexes(List<SelectedSubject> subjects) {
    final names = subjects
        .map((subject) =>
            _subjectKey(_classDetailsFromName(subject.subjectName)))
        .toSet()
        .toList()
      ..sort();

    return {
      for (var index = 0; index < names.length; index++) names[index]: index,
    };
  }

  String _subjectKey(String name) => name.trim().toLowerCase();

  int _stableSubjectIndex(String subjectName) {
    var hash = 2166136261;
    for (final codeUnit in _subjectKey(subjectName).codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  String _classDetailsFromName(String subjectName) =>
      subjectName.split(' — ').first.trim();

  Widget _buildDurationBadge(int dots, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          dots,
          (index) => Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(left: index == 0 ? 0 : 3),
            decoration: const BoxDecoration(
                color: ClassliftColors.White, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionBadge(String? section, String? classroom, Color color) {
    final label = [
      if (section != null) section,
      if (classroom?.isNotEmpty == true) classroom!
    ].join(' - ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Text(
        label.isEmpty ? 'Sin aula' : label,
        style: const TextStyle(
            color: ClassliftColors.White,
            fontSize: 11,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DashedTimelineConnector extends StatelessWidget {
  const _DashedTimelineConnector();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashHeight = 5.0;
        const dashGap = 5.0;
        final dashCount =
            (constraints.maxHeight / (dashHeight + dashGap)).ceil();

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(
              width: 2,
              height: dashHeight,
              color: ClassliftColors.PrimaryColor.withOpacity(0.45),
            ),
          ),
        );
      },
    );
  }
}

class _ConflictTimelineConnector extends StatelessWidget {
  const _ConflictTimelineConnector();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _ConflictStripePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ConflictStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = ClassliftColors.AccentColor.withOpacity(0.18);
    final stripe = Paint()
      ..color = ClassliftColors.AccentColor.withOpacity(0.52)
      ..strokeWidth = 1.4;

    canvas.drawRect(Offset.zero & size, background);
    for (var offset = -size.height; offset < size.height; offset += 6) {
      canvas.drawLine(
        Offset(0, offset),
        Offset(size.width, offset + size.width),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConflictStripePainter oldDelegate) => false;
}

class _SetupCard extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;
  final Color titleColor;
  final Color? eyebrowColor;
  final String eyebrow;
  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final IconData illustrationIcon;
  final IconData badgeIcon;
  final VoidCallback onAction;

  const _SetupCard({
    required this.backgroundColor,
    required this.accentColor,
    required this.titleColor,
    this.eyebrowColor,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.illustrationIcon,
    required this.badgeIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 390;
    final textContent = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _SetupEyebrow(
          label: eyebrow,
          color: accentColor,
          backgroundColor: eyebrowColor,
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: titleColor,
            fontSize: compact ? 21 : 23,
            height: 1.08,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: ClassliftColors.PrimaryColor.withValues(alpha: 0.68),
            fontSize: compact ? 13 : 14,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        _SetupActionButton(
          label: actionLabel,
          icon: actionIcon,
          color: accentColor,
          onPressed: onAction,
        ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14, compact ? 12 : 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor.withValues(alpha: 0.70),
                backgroundColor.withValues(alpha: 0.44),
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: compact
                    ? Column(
                        children: [
                          _SetupIllustration(
                            accentColor: accentColor,
                            icon: illustrationIcon,
                            badgeIcon: badgeIcon,
                          ),
                          const SizedBox(height: 6),
                          textContent,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _SetupIllustration(
                            accentColor: accentColor,
                            icon: illustrationIcon,
                            badgeIcon: badgeIcon,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: textContent),
                        ],
                      ),
              ),
              const SizedBox(width: 4),
              _SetupDismissButton(color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _DismissibleSetupRecommendation extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const _DismissibleSetupRecommendation({
    super.key,
    required this.child,
    required this.onDismissed,
  });

  @override
  State<_DismissibleSetupRecommendation> createState() =>
      _DismissibleSetupRecommendationState();
}

class _DismissibleSetupRecommendationState
    extends State<_DismissibleSetupRecommendation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _sizeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 280),
    )..value = 1;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeAnimation = curve;
    _sizeAnimation = curve;
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(curve);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SetupDismissScope(
      onDismiss: _dismiss,
      child: SizeTransition(
        sizeFactor: _sizeAnimation,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: IgnorePointer(
              ignoring: _dismissing,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupDismissScope extends InheritedWidget {
  final VoidCallback onDismiss;

  const _SetupDismissScope({
    required this.onDismiss,
    required super.child,
  });

  static VoidCallback of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_SetupDismissScope>();
    return scope?.onDismiss ?? () {};
  }

  @override
  bool updateShouldNotify(covariant _SetupDismissScope oldWidget) {
    return onDismiss != oldWidget.onDismiss;
  }
}

class _SetupDismissButton extends StatelessWidget {
  final Color color;

  const _SetupDismissButton({required this.color});

  @override
  Widget build(BuildContext context) {
    final onPressed = _SetupDismissScope.of(context);

    return Semantics(
      button: true,
      label: 'Cerrar recomendación',
      child: Material(
        color: color.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 32,
            child: Icon(
              Icons.close_rounded,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupIllustration extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final IconData badgeIcon;

  const _SetupIllustration({
    required this.accentColor,
    required this.icon,
    required this.badgeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ClassliftColors.White.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 34),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 15,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(badgeIcon, color: ClassliftColors.White, size: 25),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupEyebrow extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;

  const _SetupEyebrow({
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SetupActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SetupActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: ClassliftColors.White,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

class _ScheduleOverlap {
  final int startMinutes;
  final int endMinutes;
  final String conflictingSubjectName;

  const _ScheduleOverlap({
    required this.startMinutes,
    required this.endMinutes,
    required this.conflictingSubjectName,
  });

  int get duration => endMinutes - startMinutes;
}

class _NextClassOccurrence {
  final ScheduledClass scheduledClass;
  final DateTime date;

  const _NextClassOccurrence({
    required this.scheduledClass,
    required this.date,
  });

  DateTime get startsAt {
    final parts = scheduledClass.startTime.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]),
        int.parse(parts[1]));
  }
}

class _SubjectGlassCard extends StatelessWidget {
  final Color color;
  final Color accentColor;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double radius;
  final double borderWidth;
  final Widget child;

  const _SubjectGlassCard({
    required this.color,
    required this.accentColor,
    required this.padding,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.radius = 14,
    this.borderWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border(
                left: BorderSide(color: accentColor, width: borderWidth),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.70),
                  color.withValues(alpha: 0.44),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ClassDetails {
  final String subjectName;
  final String? section;
  final String? professor;

  const _ClassDetails(
      {required this.subjectName, this.section, this.professor});
}
