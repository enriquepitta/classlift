import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/utils/fpuna_grade_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum _PepEntry { stages, direct }

String _formatPercent(double value) => value
    .toStringAsFixed(4)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

class FpUnaGradeCalculatorScreen extends StatefulWidget {
  const FpUnaGradeCalculatorScreen({super.key});

  @override
  State<FpUnaGradeCalculatorScreen> createState() =>
      _FpUnaGradeCalculatorScreenState();
}

class _FpUnaGradeCalculatorScreenState
    extends State<FpUnaGradeCalculatorScreen> {
  static final _regulation = Uri.parse(
    'https://www.pol.una.py/wp-content/uploads/'
    'Resol.-26-14-50-00-Reglamento-Academico-de-carreras-de-Grado-de-la-FP-UNA-1.pdf',
  );

  final _form = GlobalKey<FormState>();
  final _formStart = GlobalKey();
  final _results = GlobalKey();
  final _partial1 = TextEditingController();
  final _process1 = TextEditingController();
  final _partial2 = TextEditingController();
  final _process2 = TextEditingController();
  final _pep = TextEditingController();
  final _finalScore = TextEditingController();
  final _attendance = TextEditingController();
  _PepEntry _entry = _PepEntry.stages;
  FpUnaGradeCalculator? _calculation;
  int? _enteredFinal;
  int? _enteredAttendance;

  @override
  void dispose() {
    for (final controller in [
      _partial1,
      _process1,
      _partial2,
      _process2,
      _pep,
      _finalScore,
      _attendance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _score(TextEditingController controller) =>
      parseFpUnaPercentage(controller.text)!;

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _calculation = switch (_entry) {
        _PepEntry.stages => FpUnaGradeCalculator.fromStages(
            partial1: _score(_partial1),
            process1: _score(_process1),
            partial2: _score(_partial2),
            process2: _score(_process2),
          ),
        _PepEntry.direct => FpUnaGradeCalculator.fromPep(_score(_pep)),
      };
      _enteredFinal = parseFpUnaPercentage(_finalScore.text);
      _enteredAttendance = parseFpUnaPercentage(_attendance.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _results.currentContext;
      if (target != null) Scrollable.ensureVisible(target);
    });
  }

  void _invalidateResults(String _) {
    if (_calculation != null) setState(() => _calculation = null);
  }

  void _editInputs() {
    final start = _formStart.currentContext;
    if (start != null) Scrollable.ensureVisible(start);
  }

  Future<void> _openRegulation() async {
    if (await launchUrl(_regulation, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el reglamento.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculation = _calculation;
    final titleHeight = MediaQuery.textScalerOf(context).scale(20);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: ClassliftColors.calendarSurface,
          onPrimary: ClassliftColors.White,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          toolbarHeight: 76 + (titleHeight - 20).clamp(0, 80) * 4,
          backgroundColor: ClassliftColors.calendarSurface,
          foregroundColor: ClassliftColors.White,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: ClassliftColors.calendarSurfaceGradient,
            ),
            child: SizedBox.expand(),
          ),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculadora FPUNA',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                'Carreras de grado · desde 2026-2',
                style: TextStyle(
                  color: ClassliftColors.calendarMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: ClassliftColors.selectionSurface,
        body: Form(
          key: _form,
          child: Column(
            children: [
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Ingresá tus porcentajes',
                          key: _formStart,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: ClassliftColors.PrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _entryPicker(),
                        const SizedBox(height: 8),
                        Text(
                          'El PEP es el promedio general de las evaluaciones '
                          'de proceso de las dos etapas, incluidos los parciales.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ClassliftColors.taskText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_entry == _PepEntry.stages) ...[
                          Text(
                            'Cada etapa combina 50% del parcial y 50% del proceso.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ClassliftColors.taskText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CalculatorPanel(
                            title: 'Etapa 1',
                            child: _adaptivePair(
                              _percentageField(_partial1, 'Parcial 1'),
                              _percentageField(_process1, 'Proceso 1'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CalculatorPanel(
                            title: 'Etapa 2',
                            child: _adaptivePair(
                              _percentageField(_partial2, 'Parcial 2'),
                              _percentageField(_process2, 'Proceso 2'),
                            ),
                          ),
                          const _CalculatorDisclosure(
                            icon: Icons.info_outline_rounded,
                            title: 'Cómo ingresar el proceso',
                            description:
                                'Usá el porcentaje ponderado de tu planilla. '
                                'Si el aporte figura sobre 50 puntos, duplicalo '
                                'para ingresarlo como porcentaje.',
                          ),
                        ] else ...[
                          _CalculatorPanel(
                            title: 'Promedio de proceso',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Si tu planilla ya muestra el PEP, ingresá '
                                  'ese porcentaje.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                _percentageField(_pep, 'PEP de la materia'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _CalculatorPanel(
                          title: 'Final y asistencia',
                          caption: 'Opcional',
                          child: _adaptivePair(
                            _percentageField(
                              _finalScore,
                              'Examen final',
                              optional: true,
                            ),
                            _percentageField(
                              _attendance,
                              'Asistencia',
                              optional: true,
                            ),
                          ),
                        ),
                        if (calculation != null)
                          Padding(
                            key: _results,
                            padding: const EdgeInsets.only(top: 14),
                            child: _GradeResults(
                              calculation: calculation,
                              finalScore: _enteredFinal,
                              attendance: _enteredAttendance,
                            ),
                          ),
                        const SizedBox(height: 8),
                        const _CalculatorDisclosure(
                          icon: Icons.assignment_return_outlined,
                          title: 'Recuperación de un parcial',
                          description:
                              'Se realiza en la primera convocatoria del final. '
                              'Si faltaste a uno de los parciales, podés '
                              'recuperarlo si cumplís los demás requisitos. '
                              'Si rendiste ambos y no obtuviste el derecho al '
                              'final, podés recuperar el de menor porcentaje '
                              'si tu promedio de actividades de proceso, '
                              'excluidos los parciales, llega al 60% y cumplís '
                              'los demás requisitos.',
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _openRegulation,
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 18),
                            label: const Text('Reglamento FPUNA · arts. 12–15'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: ClassliftColors.White,
                  border: Border(
                    top: BorderSide(color: ClassliftColors.calendarAccent),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(18, 9, 18, 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: calculation == null ? _calculate : _editInputs,
                      icon: Icon(calculation == null
                          ? Icons.calculate_outlined
                          : Icons.edit_outlined),
                      label: Text(
                          calculation == null ? 'Calcular' : 'Editar datos'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ClassliftColors.calendarSurface,
                        foregroundColor: ClassliftColors.White,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _entryPicker() => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final (mode, label) in [
            (_PepEntry.stages, 'Por etapas'),
            (_PepEntry.direct, 'Ya tengo mi PEP'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: _entry == mode,
              showCheckmark: true,
              backgroundColor: ClassliftColors.White,
              selectedColor: ClassliftColors.calendarSurface,
              checkmarkColor: ClassliftColors.White,
              labelStyle: TextStyle(
                color: _entry == mode
                    ? ClassliftColors.White
                    : ClassliftColors.PrimaryColor,
                fontWeight: FontWeight.w600,
              ),
              shape: const StadiumBorder(),
              side: BorderSide(
                color: _entry == mode
                    ? ClassliftColors.calendarSurface
                    : ClassliftColors.selectionMuted,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _entry = mode;
                  _calculation = null;
                });
              },
            ),
        ],
      );

  Widget _percentageField(
    TextEditingController controller,
    String label, {
    bool optional = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        filled: true,
        fillColor: ClassliftColors.selectionSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        errorMaxLines: 2,
        border: border,
        enabledBorder: border.copyWith(
          borderSide: const BorderSide(color: ClassliftColors.selectionMuted),
        ),
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(
            color: ClassliftColors.calendarSurface,
            width: 2,
          ),
        ),
      ),
      onChanged: _invalidateResults,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return optional ? null : 'Ingresá un porcentaje.';
        }
        return parseFpUnaPercentage(value) == null
            ? 'Usá un valor de 0 a 100 con hasta dos decimales.'
            : null;
      },
    );
  }
}

Widget _adaptivePair(Widget first, Widget second) => LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth < 280 * textScale) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 8), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );

class _CalculatorPanel extends StatelessWidget {
  const _CalculatorPanel({
    required this.title,
    required this.child,
    this.caption,
  });

  final String title;
  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClassliftColors.White,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClassliftColors.calendarAccent),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: ClassliftColors.PrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ClassliftColors.taskText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _CalculatorDisclosure extends StatelessWidget {
  const _CalculatorDisclosure({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 2),
        childrenPadding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
        dense: true,
        leading: Icon(icon, size: 19),
        iconColor: ClassliftColors.calendarSurface,
        collapsedIconColor: ClassliftColors.calendarSurface,
        textColor: ClassliftColors.calendarSurface,
        collapsedTextColor: ClassliftColors.calendarSurface,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _GradeResults extends StatelessWidget {
  const _GradeResults({
    required this.calculation,
    this.finalScore,
    this.attendance,
  });

  final FpUnaGradeCalculator calculation;
  final int? finalScore;
  final int? attendance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage1 = calculation.stage1;
    final stage2 = calculation.stage2;
    final score = finalScore;
    final result = score == null ? null : calculation.resultWithFinal(score);
    final attended = attendance;
    final call = attended == null
        ? null
        : FpUnaGradeCalculator.callByAttendance(attended);
    final meetsPep = calculation.meetsPepRequirement;
    final maximumGrade =
        score == null && call != FpUnaFinalCall.insufficientAttendance
            ? calculation.resultWithFinal(10000)?.grade
            : null;
    final finalForMaximum = maximumGrade == null
        ? null
        : calculation.finalRequiredFor(maximumGrade);
    final gradeMetric = switch ((result?.grade, maximumGrade)) {
      (final int grade, _) => _ResultMetric(
          label: 'Nota estimada',
          value: '$grade',
          announcement: 'Nota estimada $grade',
          emphasized: true,
        ),
      (_, final int grade) => _ResultMetric(
          label: 'Nota máxima',
          value: '$grade',
          announcement: 'Nota máxima posible $grade',
          emphasized: true,
        ),
      _ => null,
    };
    final pep = _ResultMetric(
      label: 'PEP',
      value: '${_formatPercent(calculation.pep)}%',
      announcement: 'PEP de ${_formatPercent(calculation.pep)}%',
    );
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CalculatorPanel(
            title: 'Resultado',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (gradeMetric == null)
                  pep
                else
                  _adaptivePair(pep, gradeMetric),
                if (finalForMaximum != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Si cumplís los requisitos para rendir, necesitás al menos '
                    '${_formatPercent(finalForMaximum / 100)}% en el final '
                    'para alcanzar esta nota.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'El PEP aporta el 60% al rendimiento final de la materia.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ClassliftColors.taskText,
                  ),
                ),
                if (stage1 != null && stage2 != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Etapa 1 ${_formatPercent(stage1)}% · '
                    'Etapa 2 ${_formatPercent(stage2)}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (result != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'RP de ${_formatPercent(result.rp)}% · '
                    'redondeado a ${result.roundedRp}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ] else if (score != null && meetsPep) ...[
                  const SizedBox(height: 8),
                  const Text(
                      'Para computar el RP, el final debe llegar al 50%.'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _CalculatorPanel(
            title: 'Habilitación',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      meetsPep
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 19,
                      color: meetsPep
                          ? ClassliftColors.calendarSurface
                          : ClassliftColors.inputError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meetsPep
                            ? 'Cumplís el mínimo de PEP para rendir.'
                            : 'Para rendir necesitás un PEP de al menos 60%.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (call != null && meetsPep) ...[
                  const SizedBox(height: 6),
                  Text(switch (call) {
                    FpUnaFinalCall.first =>
                      'Por asistencia, podés rendir desde la primera convocatoria.',
                    FpUnaFinalCall.second =>
                      'Por asistencia, podés rendir desde la segunda convocatoria.',
                    FpUnaFinalCall.insufficientAttendance =>
                      'Para rendir necesitás al menos 50% de asistencia a clases.',
                  }),
                ],
                const SizedBox(height: 8),
                Text(
                  'El derecho al final también depende del laboratorio '
                  'obligatorio (100% de asistencia si corresponde), las '
                  'sanciones y los requisitos de tu materia.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ClassliftColors.taskText,
                  ),
                ),
              ],
            ),
          ),
          if (meetsPep) ...[
            const SizedBox(height: 10),
            _CalculatorPanel(
              title: 'Mínimo en el examen final',
              child: Column(
                children: [
                  for (final grade
                      in FpUnaGradeCalculator.passingThresholds.keys)
                    _FinalTarget(
                      grade: grade,
                      requiredScore: calculation.finalRequiredFor(grade),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.value,
    required this.announcement,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String announcement;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color =
        emphasized ? ClassliftColors.White : ClassliftColors.PrimaryColor;
    return Semantics(
      label: announcement,
      container: true,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: emphasized
              ? ClassliftColors.calendarSurface
              : ClassliftColors.selectionIcon,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  height: 1.2,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalTarget extends StatelessWidget {
  const _FinalTarget({required this.grade, required this.requiredScore});

  final int grade;
  final int? requiredScore;

  @override
  Widget build(BuildContext context) {
    final score = requiredScore;
    final reachable = score != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: grade == 2
              ? ClassliftColors.navigationSelected
              : ClassliftColors.selectionSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Nota $grade',
                  style: const TextStyle(
                    color: ClassliftColors.PrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  score == null
                      ? 'Fuera de alcance'
                      : '${_formatPercent(score / 100)}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: reachable
                        ? ClassliftColors.calendarSurface
                        : ClassliftColors.taskText,
                    fontWeight: reachable ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
