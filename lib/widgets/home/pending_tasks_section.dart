import 'package:classlift/utils/classlift_colors.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:classlift/models/moodle_task.dart';
import 'package:classlift/services/moodle_auth_service.dart';
import 'package:classlift/services/moodle_tasks_service.dart';

const _ink = ClassliftColors.taskText;

class PendingTasksSection extends StatefulWidget {
  final Future<MoodleTasksResult>? future;
  final FutureOr<void> Function() onRefresh;
  final FutureOr<void> Function()? onReconnect;
  const PendingTasksSection({
    super.key,
    required this.future,
    required this.onRefresh,
    this.onReconnect,
  });

  @override
  State<PendingTasksSection> createState() => _PendingTasksSectionState();
}

class _PendingTasksSectionState extends State<PendingTasksSection> {
  Timer? _timer;
  Future<MoodleTasksResult>? get future => widget.future;
  FutureOr<void> Function() get onRefresh => widget.onRefresh;
  FutureOr<void> Function()? get onReconnect => widget.onReconnect;

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
          final overdueLabel =
              '${overdue.length} ${overdue.length == 1 ? 'vencida' : 'vencidas'}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    overflowAlignment: OverflowBarAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tareas pendientes',
                              style: TextStyle(
                                  color: _ink,
                                  fontSize:
                                      MediaQuery.sizeOf(context).width > 600
                                          ? 24
                                          : 18,
                                  fontWeight: FontWeight.w800)),
                          if (overdue.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => MoodleTasksScreen(
                                          tasks: overdue,
                                          title: 'Tareas vencidas'))),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 15,
                                        color: ClassliftColors.taskOverdue),
                                    const SizedBox(width: 5),
                                    Text(overdueLabel,
                                        style: const TextStyle(
                                            color: ClassliftColors.taskOverdue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (tasks.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      MoodleTasksScreen(tasks: tasks))),
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
                const SizedBox.shrink()
              else if (loading)
                const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError)
                _TaskErrorNotice(
                  error: snapshot.error,
                  onRetry: onRefresh,
                  onReconnect: onReconnect,
                )
              else ...[
                if (upcoming.isEmpty)
                  _Notice(
                      message: tasks.isNotEmpty
                          ? 'No tenés próximas entregas.'
                          : result?.incomplete == true
                              ? 'No hay tareas disponibles para mostrar.'
                              : 'Estás al día. No tenés tareas pendientes.',
                      action: 'Actualizar',
                      onTap: () => onRefresh())
                else
                  _TaskCarousel(
                    key: ValueKey(
                        upcoming.take(4).map((task) => task.id).join(',')),
                    tasks: upcoming.take(4).toList(),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TaskErrorNotice extends StatefulWidget {
  final Object? error;
  final FutureOr<void> Function() onRetry;
  final FutureOr<void> Function()? onReconnect;
  const _TaskErrorNotice({
    required this.error,
    required this.onRetry,
    required this.onReconnect,
  });

  @override
  State<_TaskErrorNotice> createState() => _TaskErrorNoticeState();
}

class _TaskErrorNoticeState extends State<_TaskErrorNotice> {
  bool _retrying = false;

  bool get _requiresReconnect =>
      widget.error is MoodleAuthException &&
      (widget.error as MoodleAuthException).requiresReconnect;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      if (_requiresReconnect && widget.onReconnect != null) {
        await widget.onReconnect!();
      } else {
        await widget.onRetry();
      }
    } catch (_) {
      // El FutureBuilder vuelve a mostrar el estado de error si Moodle falla.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _requiresReconnect
        ? 'Tu sesión de EDUCA venció.'
        : 'No se pudieron actualizar tus tareas.';
    final description = _requiresReconnect
        ? 'Volvé a conectar tu cuenta para traer tus entregas pendientes.'
        : 'Revisá tu conexión o intentá sincronizar EDUCA otra vez.';
    final idleLabel = _requiresReconnect ? 'Reconectar EDUCA' : 'Reintentar';
    final loadingLabel = _requiresReconnect ? 'Abriendo' : 'Actualizando';
    final idleIcon =
        _requiresReconnect ? Icons.login_rounded : Icons.refresh_rounded;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClassliftColors.educaSoftBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ClassliftColors.educaRed.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: ClassliftColors.educaRed.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ClassliftColors.White.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sync_problem_rounded,
              color: ClassliftColors.educaRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ClassliftColors.educaDarkRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: ClassliftColors.educaMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _retrying ? null : _retry,
                    style: FilledButton.styleFrom(
                      backgroundColor: ClassliftColors.educaRed,
                      disabledBackgroundColor:
                          ClassliftColors.educaRed.withValues(alpha: 0.58),
                      foregroundColor: ClassliftColors.White,
                      disabledForegroundColor: ClassliftColors.White,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _retrying
                        ? const SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ClassliftColors.White,
                            ),
                          )
                        : Icon(idleIcon, size: 17),
                    label: Text(
                      _retrying ? loadingLabel : idleLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            color: ClassliftColors.taskEmptyBackground,
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
                                            : ClassliftColors
                                                .taskPageIndicator),
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
    (ClassliftColors.taskPinkBackground, ClassliftColors.taskPinkAccent),
    (ClassliftColors.taskMintBackground, ClassliftColors.taskMintAccent),
    (ClassliftColors.taskBlueBackground, ClassliftColors.taskBlueAccent),
    (ClassliftColors.taskOrangeBackground, ClassliftColors.taskOrangeAccent),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: colors.$1.withValues(alpha: 0.54),
          child: InkWell(
            onTap: () => _showTask(context, task),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.$2, width: 6),
                  top: BorderSide(
                    color: ClassliftColors.White.withValues(alpha: 0.40),
                  ),
                  right: BorderSide(
                    color: ClassliftColors.White.withValues(alpha: 0.22),
                  ),
                  bottom: BorderSide(
                    color: ClassliftColors.White.withValues(alpha: 0.22),
                  ),
                ),
              ),
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
                                color: ClassliftColors.taskMuted,
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
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today_outlined,
                                            size: 16, color: colors.$2),
                                        const SizedBox(width: 7),
                                        Flexible(
                                            child: Text(
                                                _dateLabel(due, current),
                                                style: TextStyle(
                                                    color: colors.$2,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                      ]),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: urgent || overdue
                                            ? ClassliftColors
                                                .taskOverdueBackground
                                            : colors.$2.withValues(alpha: 0.09),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 14,
                                              color: urgent || overdue
                                                  ? ClassliftColors.taskOverdue
                                                  : colors.$2),
                                          const SizedBox(width: 5),
                                          Flexible(
                                              child: Text(badge,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: urgent || overdue
                                                          ? ClassliftColors
                                                              .taskOverdue
                                                          : colors.$2))),
                                        ]),
                                  ),
                                ])),
                      ]),
                ),
              ]),
            ),
          ),
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

class MoodleTasksScreen extends StatefulWidget {
  final List<MoodleTask> tasks;
  final String title;
  const MoodleTasksScreen(
      {super.key, this.tasks = const [], this.title = 'Tareas pendientes'});

  @override
  State<MoodleTasksScreen> createState() => _MoodleTasksScreenState();
}

class _MoodleTasksScreenState extends State<MoodleTasksScreen> {
  Future<MoodleTasksResult>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.tasks.isEmpty) {
      _future = MoodleTasksService.lastLoad ??
          MoodleTasksService.loadCurrentSession();
    }
  }

  void _refresh() {
    setState(() => _future = MoodleTasksService.loadCurrentSession());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isNotEmpty) {
      return _TasksListScaffold(title: widget.title, tasks: widget.tasks);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const _TasksBackButton(),
        title: Text(widget.title),
      ),
      body: FutureBuilder<MoodleTasksResult>(
        future: _future,
        builder: (context, snapshot) {
          if (_future == null) {
            return _TasksStateMessage(
              icon: Icons.school_outlined,
              title: 'Conectá Moodle',
              message:
                  'Conectá tu campus para ver tus entregas pendientes acá.',
              actionLabel: 'Conectar Moodle',
              onAction: () => context.push('/login/moodle'),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _TasksStateMessage(
              icon: Icons.sync_problem_rounded,
              title: 'No se pudieron cargar tus tareas',
              message: 'Intentá actualizar o conectá Moodle nuevamente.',
              actionLabel: 'Actualizar',
              onAction: _refresh,
            );
          }

          final tasks =
              snapshot.data?.allPendingAt(DateTime.now()) ?? <MoodleTask>[];
          if (tasks.isEmpty) {
            return _TasksStateMessage(
              icon: Icons.check_circle_outline_rounded,
              title: 'Sin tareas pendientes',
              message:
                  'Cuando Moodle tenga entregas pendientes aparecerán acá.',
              actionLabel: 'Actualizar',
              onAction: _refresh,
            );
          }
          return _TasksList(tasks: tasks);
        },
      ),
    );
  }
}

class _TasksListScaffold extends StatelessWidget {
  final String title;
  final List<MoodleTask> tasks;
  const _TasksListScaffold({required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: const _TasksBackButton(),
          title: Text(title),
        ),
        body: _TasksList(tasks: tasks),
      );
}

class _TasksBackButton extends StatelessWidget {
  const _TasksBackButton();

  @override
  Widget build(BuildContext context) => BackButton(
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/home');
          }
        },
      );
}

class _TasksList extends StatelessWidget {
  final List<MoodleTask> tasks;
  const _TasksList({required this.tasks});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
        ],
      );
}

class _TasksStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _TasksStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _ink, size: 44),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ClassliftColors.taskMuted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
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
