import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classlift/models/moodle_task.dart';
import 'package:classlift/services/moodle_tasks_service.dart';

const _ink = Color(0xFF34377D);

class PendingTasksSection extends StatefulWidget {
  final Future<MoodleTasksResult>? future;
  final VoidCallback onRefresh;
  const PendingTasksSection(
      {super.key, required this.future, required this.onRefresh});

  @override
  State<PendingTasksSection> createState() => _PendingTasksSectionState();
}

class _PendingTasksSectionState extends State<PendingTasksSection> {
  Timer? _timer;
  Future<MoodleTasksResult>? get future => widget.future;
  VoidCallback get onRefresh => widget.onRefresh;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FutureBuilder<MoodleTasksResult>(
        future: future,
        builder: (context, snapshot) {
          final result = snapshot.data;
          final loading = future != null &&
              snapshot.connectionState != ConnectionState.done;
          final now = DateTime.now();
          final available = !loading && !snapshot.hasError ? result : null;
          final tasks = available?.allPendingAt(now) ?? <MoodleTask>[];
          final upcoming = available?.upcomingAt(now) ?? <MoodleTask>[];
          final overdue = available?.overdueAt(now) ?? <MoodleTask>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [
                      Text('Tareas pendientes',
                          style: TextStyle(
                              color: _ink,
                              fontSize: MediaQuery.sizeOf(context).width > 600
                                  ? 24
                                  : 18,
                              fontWeight: FontWeight.w800)),
                      if (tasks.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      _AllTasksScreen(tasks: tasks))),
                          style: TextButton.styleFrom(foregroundColor: _ink),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                    child: Text('Ver todas',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700))),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 20),
                              ]),
                        ),
                    ]),
              ),
              const SizedBox(height: 10),
              if (future == null)
                _Notice(
                    message: 'Conectá Moodle para ver tus próximas entregas.',
                    action: 'Conectar Moodle',
                    onTap: () async {
                      await context.push('/login/moodle');
                      if (context.mounted) onRefresh();
                    })
              else if (loading)
                const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                _Notice(
                    message: 'No se pudieron actualizar tus tareas.',
                    action: 'Reintentar',
                    onTap: onRefresh)
              else ...[
                if (upcoming.isEmpty)
                  _Notice(
                      message: tasks.isNotEmpty
                          ? 'No tenés próximas entregas.'
                          : result?.incomplete == true
                              ? 'No hay tareas disponibles para mostrar.'
                              : 'Estás al día. No tenés tareas pendientes.',
                      action: 'Actualizar',
                      onTap: onRefresh)
                else
                  _TaskCarousel(
                    key: ValueKey(
                        upcoming.take(4).map((task) => task.id).join(',')),
                    tasks: upcoming.take(4).toList(),
                  ),
                if (overdue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: _ink),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => _AllTasksScreen(
                                  tasks: overdue, title: 'Tareas vencidas'))),
                      child: Text(
                          '${overdue.length} ${overdue.length == 1 ? 'vencida' : 'vencidas'}'),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final String action;
  final VoidCallback onTap;
  const _Notice(
      {required this.message, required this.action, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFFEEEDF9),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(message, style: const TextStyle(color: _ink)),
          TextButton(onPressed: onTap, child: Text(action)),
        ]),
      );
}

class _TaskCarousel extends StatefulWidget {
  final List<MoodleTask> tasks;
  const _TaskCarousel({super.key, required this.tasks});
  @override
  State<_TaskCarousel> createState() => _TaskCarouselState();
}

class _TaskCarouselState extends State<_TaskCarousel> {
  PageController? _controller;
  double? _fraction;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final fraction = math.min(0.88, 610 / constraints.maxWidth);
        if (_fraction != fraction) {
          _controller?.dispose();
          _controller = PageController(
              viewportFraction: fraction,
              initialPage: _page.clamp(0, widget.tasks.length - 1));
          _fraction = fraction;
        }
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final height = 206.0 + math.max(0.0, scale - 1) * 200;
        return Column(children: [
          SizedBox(
            height: height,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: widget.tasks.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(left: 16, right: 0),
                child: MoodleTaskCard(task: widget.tasks[index]),
              ),
            ),
          ),
          if (widget.tasks.length > 1)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      widget.tasks.length,
                      (index) => Semantics(
                            label:
                                'Tarea ${index + 1} de ${widget.tasks.length}',
                            selected: index == _page,
                            button: true,
                            child: InkResponse(
                              onTap: () => _controller!.animateToPage(index,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut),
                              child: SizedBox(
                                  width: 28,
                                  height: 32,
                                  child: Center(
                                      child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index == _page
                                            ? _ink
                                            : const Color(0xFFBDC8E6)),
                                  ))),
                            ),
                          )),
                )),
        ]);
      });
}

class MoodleTaskCard extends StatelessWidget {
  final MoodleTask task;
  final DateTime? now;
  const MoodleTaskCard({super.key, required this.task, this.now});

  static const _palette = [
    (Color(0xFFFBE4F1), Color(0xFFA63B77)),
    (Color(0xFFDEF5F0), Color(0xFF277C79)),
    (Color(0xFFE6EAFC), Color(0xFF5366AB)),
    (Color(0xFFFFEEDC), Color(0xFF9D6428)),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palette[task.courseId % _palette.length];
    final current = now ?? DateTime.now();
    final due = task.dueDate;
    final remaining = due?.difference(current);
    final overdue = remaining != null && remaining <= Duration.zero;
    final urgent = remaining != null && !overdue && remaining.inHours < 24;
    final badge = !task.statusKnown
        ? 'Estado sin verificar'
        : overdue
            ? 'Vencida'
            : urgent
                ? remaining.inMinutes < 60
                    ? 'Vence en ${math.max(1, remaining.inMinutes)} min'
                    : 'Vence en ${remaining.inHours} h'
                : task.submissionStatus == 'draft'
                    ? 'Borrador'
                    : 'Pendiente';
    return Material(
      color: colors.$1,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTask(context, task),
        child: DecoratedBox(
          decoration: BoxDecoration(
              border: Border(left: BorderSide(color: colors.$2, width: 6))),
          child: Stack(children: [
            Positioned(
                right: 18,
                top: 22,
                child: ExcludeSemantics(
                    child: Transform.rotate(
                  angle: 0.24,
                  child: Icon(Icons.description_outlined,
                      size: 66, color: colors.$2.withValues(alpha: 0.10)),
                ))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.$2,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7),
                    Text(task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                        task.description.isEmpty
                            ? 'Consultá la consigna en Moodle.'
                            : task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF747598),
                            fontSize: 12,
                            height: 1.3)),
                    const Spacer(),
                    SizedBox(
                        width: double.infinity,
                        child: OverflowBar(
                            alignment: MainAxisAlignment.spaceBetween,
                            overflowAlignment: OverflowBarAlignment.end,
                            spacing: 12,
                            overflowSpacing: 6,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 16, color: colors.$2),
                                const SizedBox(width: 7),
                                Flexible(
                                    child: Text(_dateLabel(due, current),
                                        style: TextStyle(
                                            color: colors.$2,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600))),
                              ]),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                    color: urgent || overdue
                                        ? const Color(0xFFFFDCE2)
                                        : colors.$2.withValues(alpha: 0.09),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 14,
                                          color: urgent || overdue
                                              ? const Color(0xFFD53D50)
                                              : colors.$2),
                                      const SizedBox(width: 5),
                                      Flexible(
                                          child: Text(badge,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: urgent || overdue
                                                      ? const Color(0xFFD53D50)
                                                      : colors.$2))),
                                    ]),
                              ),
                            ])),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime? due, DateTime now) {
  if (due == null) return 'Sin fecha límite';
  final day = DateUtils.dateOnly(due);
  final today = DateUtils.dateOnly(now);
  final label = day == today
      ? 'Hoy'
      : day == DateTime(today.year, today.month, today.day + 1)
          ? 'Mañana'
          : DateFormat(due.year == now.year ? 'dd/MM' : 'dd/MM/yy').format(due);
  return '$label · ${DateFormat('HH:mm').format(due)}';
}

class _AllTasksScreen extends StatelessWidget {
  final List<MoodleTask> tasks;
  final String title;
  const _AllTasksScreen(
      {required this.tasks, this.title = 'Tareas pendientes'});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(
                  height: 206 +
                      math.max(
                              0,
                              MediaQuery.textScalerOf(context).scale(14) / 14 -
                                  1) *
                          200,
                  child: MoodleTaskCard(task: task)),
            ),
        ]),
      );
}

void _showTask(BuildContext context, MoodleTask task) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.courseName,
                style:
                    const TextStyle(color: _ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(task.title,
                style: const TextStyle(
                    color: _ink, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(_dateLabel(task.dueDate, DateTime.now())),
            const SizedBox(height: 16),
            SelectableText(task.description.isEmpty
                ? 'La consigna está disponible en Moodle.'
                : task.description),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en Moodle'),
              onPressed: () async {
                try {
                  if (await launchUrl(task.url,
                      mode: LaunchMode.externalApplication)) {
                    return;
                  }
                } catch (_) {
                  // Keep the detail visible and allow the user to retry.
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'No se pudo abrir Moodle. Intentá nuevamente.')));
                }
              },
            ),
          ]),
    ),
  );
}
