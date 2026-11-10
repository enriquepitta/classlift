import 'package:classlift/screens/select_career.dart';
import 'package:classlift/services/faculty_schedule_service.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/widgets/selection/selection_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FacultyScheduleScreen extends StatefulWidget {
  const FacultyScheduleScreen({super.key, this.service});

  final FacultyScheduleService? service;

  @override
  State<FacultyScheduleScreen> createState() => _FacultyScheduleScreenState();
}

class _FacultyScheduleScreenState extends State<FacultyScheduleScreen> {
  late final FacultyScheduleService _service;
  late Future<List<FacultyScheduleCatalog>> _catalogs;
  String? _period;
  String? _selectedId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? FacultyScheduleService();
    _catalogs = _service.listCatalogs();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final id = _selectedId;
    if (id == null || _loading) return;
    setState(() => _loading = true);
    try {
      final catalog = await _service.loadCatalog(id);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SelectCareerScreen(
            availableSheets: catalog.keys.toList(),
            facultyCatalog: catalog,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'No pudimos cargar los horarios. Revisá tu conexión e intentá de nuevo.'),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<FacultyScheduleCatalog>>(
        future: _catalogs,
        builder: (context, snapshot) {
          final catalogs = snapshot.data ?? const <FacultyScheduleCatalog>[];
          final periods =
              catalogs.map((catalog) => catalog.period).toSet().toList();
          final period = periods.contains(_period)
              ? _period
              : (periods.isEmpty ? null : periods.first);
          final options =
              catalogs.where((catalog) => catalog.period == period).toList();
          return SelectionFlowScaffold(
            title: 'Horarios de',
            accentTitle: 'la facultad',
            description:
                'Elegí el período y tu plan de estudios para encontrar tus materias.',
            step: 1,
            slivers: [
              if (snapshot.connectionState != ConnectionState.done)
                const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()))
              else if (snapshot.hasError || catalogs.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SelectionSurface(
                      child: Column(children: [
                        const Text(
                            'No pudimos cargar los horarios. Revisá tu conexión e intentá de nuevo.'),
                        TextButton(
                          onPressed: () => setState(
                              () => _catalogs = _service.listCatalogs()),
                          child: const Text('Reintentar'),
                        ),
                      ]),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList.list(children: [
                    const _SectionTitle('Período académico'),
                    const SizedBox(height: 10),
                    ...periods.map((item) => _ChoiceCard(
                          title: item,
                          selected: item == period,
                          onTap: () => setState(() {
                            _period = item;
                            _selectedId = null;
                          }),
                        )),
                    const SizedBox(height: 20),
                    const _SectionTitle('Plan de estudios'),
                    const SizedBox(height: 10),
                    ...options.map((catalog) => _ChoiceCard(
                          title: catalog.plan,
                          subtitle:
                              'Actualizado: ${DateFormat('dd/MM/yyyy').format(catalog.updatedAt.toLocal())}',
                          selected: _selectedId == catalog.id,
                          onTap: () => setState(() => _selectedId = catalog.id),
                        )),
                  ]),
                ),
            ],
            footer: SelectionFooter(
              label: 'Elegir carrera',
              isLoading: _loading,
              onPressed: _selectedId == null || _loading ? null : _continue,
            ),
          );
        },
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: ClassliftColors.selectionInk));
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(
      {required this.title,
      required this.selected,
      required this.onTap,
      this.subtitle});
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SelectionSurface(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            onTap: onTap,
            title: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ClassliftColors.selectionInk)),
            subtitle: subtitle == null
                ? null
                : Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 12, color: ClassliftColors.selectionMuted)),
            trailing: Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? ClassliftColors.selectionBlue
                    : ClassliftColors.selectionBorder),
          ),
        ),
      );
}
