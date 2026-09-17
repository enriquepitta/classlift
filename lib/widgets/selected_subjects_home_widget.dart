import 'package:flutter/material.dart';
import 'package:classlift/services/database_service.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/models/database_models.dart';

class SelectedSubjectsHomeWidget extends StatefulWidget {
  final bool showCompactView;
  final VoidCallback? onSubjectTap;
  final VoidCallback? onRefreshRequested; // Callback para cuando se necesite refrescar

  const SelectedSubjectsHomeWidget({
    Key? key,
    this.showCompactView = false,
    this.onSubjectTap,
    this.onRefreshRequested,
  }) : super(key: key);

  @override
  State<SelectedSubjectsHomeWidget> createState() => _SelectedSubjectsHomeWidgetState();
}

class _SelectedSubjectsHomeWidgetState extends State<SelectedSubjectsHomeWidget> {
  Map<String, Map<int, List<SelectedSubject>>> groupedSubjects = {};
  int totalSubjects = 0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Método público para recargar datos
  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final results = await Future.wait([
        DatabaseService.getGroupedSelectedSubjects(),
        DatabaseService.getTotalSubjectsCount(),
      ]);

      if (mounted) {
        setState(() {
          groupedSubjects = results[0] as Map<String, Map<int, List<SelectedSubject>>>;
          totalSubjects = results[1] as int;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    // Escalas de iPad
    final double pad = isTablet ? 24 : 16;
    final double padLarge = isTablet ? 28 : 20;
    final double radius = isTablet ? 24 : 16;
    final double chipRadius = isTablet ? 16 : 12;
    final double headerIconSize = isTablet ? 28 : 24;
    final double bigIconSize = isTablet ? 56 : 40;
    final double titleSize = isTablet ? 22 : 20;
    final double subtitleSize = isTablet ? 16 : 14;
    final double bodySize = isTablet ? 15 : 13;
    final double statBadgeFont = isTablet ? 18 : 16;

    if (isLoading) {
      return Container(
        margin: EdgeInsets.all(pad),
        padding: EdgeInsets.all(padLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Cargando materias...',
                style: TextStyle(color: Colors.grey[600], fontSize: subtitleSize),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        margin: EdgeInsets.all(pad),
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: isTablet ? 40 : 32, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              'Error al cargar materias',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w700,
                fontSize: isTablet ? 18 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(fontSize: isTablet ? 14 : 12, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(chipRadius)),
              ),
              child: Text('Reintentar', style: TextStyle(color: Colors.white, fontSize: isTablet ? 16 : 14)),
            ),
          ],
        ),
      );
    }

    if (totalSubjects == 0) {
      return Container(
        margin: EdgeInsets.all(pad),
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 560 : 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 28 : 20),
                  decoration: BoxDecoration(
                    color: ClassliftColors.PrimaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ClassliftColors.PrimaryColor.withOpacity(0.12),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.schedule_outlined,
                    size: bigIconSize,
                    color: ClassliftColors.PrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin horarios configurados',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Organizá tu semestre de manera inteligente',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: isTablet ? 17 : 16,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Features horizontales con más separación y tamaño
                Wrap(
                  spacing: isTablet ? 56 : 50,
                  runSpacing: isTablet ? 24 : 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeatureCard(
                      icon: Icons.calendar_view_week,
                      title: 'Vista\nSemanal',
                      color: Colors.blue,
                      isTablet: isTablet,
                    ),
                    _buildFeatureCard(
                      icon: Icons.notifications_active,
                      title: 'Alertas\nInteligentes',
                      color: Colors.orange,
                      isTablet: isTablet,
                    ),
                    _buildFeatureCard(
                      icon: Icons.analytics,
                      title: 'Progreso\nAcadémico',
                      color: Colors.green,
                      isTablet: isTablet,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 14 : 12,
                    horizontal: isTablet ? 18 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: ClassliftColors.PrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ClassliftColors.PrimaryColor.withOpacity(0.18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: ClassliftColors.PrimaryColor,
                        size: isTablet ? 20 : 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Comenzá con el botón + abajo',
                        style: TextStyle(
                          color: ClassliftColors.PrimaryColor,
                          fontSize: isTablet ? 15 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            margin: EdgeInsets.all(pad),
            padding: EdgeInsets.all(padLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClassliftColors.PrimaryColor,
                  ClassliftColors.PrimaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: ClassliftColors.PrimaryColor.withOpacity(0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 14 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: headerIconSize,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mi Horario',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$totalSubjects materia${totalSubjects != 1 ? 's' : ''} configurada${totalSubjects != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8, vertical: isTablet ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Text(
                    '${groupedSubjects.keys.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: statBadgeFont,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de materias por carrera/semestre
          ...groupedSubjects.entries.map((careerEntry) {
            final semesterMap = careerEntry.value;
            final careerName = semesterMap.values.first.first.careerName;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: pad, vertical: isTablet ? 10 : 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de la carrera
                  Container(
                    padding: EdgeInsets.all(isTablet ? 18 : 16),
                    decoration: BoxDecoration(
                      color: ClassliftColors.PrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(radius),
                        topRight: Radius.circular(radius),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 10 : 8),
                          decoration: BoxDecoration(
                            color: ClassliftColors.PrimaryColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                          ),
                          child: Icon(
                            Icons.school_outlined,
                            color: ClassliftColors.PrimaryColor,
                            size: isTablet ? 22 : 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            careerName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 18 : 16,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Materias por semestre
                  ...semesterMap.entries.map((semesterEntry) {
                    final semester = semesterEntry.key;
                    final subjects = semesterEntry.value;

                    // Para iPad, aumentamos minWidth de chip y espaciamientos
                    final double chipMinWidth = isTablet ? 160 : 120;

                    return Padding(
                      padding: EdgeInsets.all(isTablet ? 18 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 10,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ClassliftColors.PrimaryColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ClassliftColors.PrimaryColor.withOpacity(0.22),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Semestre $semester',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isTablet ? 13.5 : 12,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${subjects.length} materia${subjects.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: isTablet ? 14 : 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Chips / Grid compacta
                          Wrap(
                            spacing: isTablet ? 12 : 8,
                            runSpacing: isTablet ? 12 : 8,
                            children: subjects.map((subject) {
                              return _SubjectChip(
                                label: subject.subjectName,
                                minWidth: chipMinWidth,
                                radius: chipRadius,
                                isTablet: isTablet,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),

          SizedBox(height: isTablet ? 120 : 100), // Espacio para el FAB
        ],
      ),
    );
  }
}

// Chip de materia con estilo iPad
class _SubjectChip extends StatelessWidget {
  final String label;
  final double minWidth;
  final double radius;
  final bool isTablet;

  const _SubjectChip({
    Key? key,
    required this.label,
    required this.minWidth,
    required this.radius,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 14 : 12, vertical: isTablet ? 10 : 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFFE6EBF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isTablet ? 7 : 6,
              height: isTablet ? 7 : 6,
              decoration: BoxDecoration(
                color: ClassliftColors.PrimaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14.5 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase adicional para manejar el refresh desde fuera
class SelectedSubjectsRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

// Tarjeta de feature con ajuste iPad
Widget _buildFeatureCard({
  required IconData icon,
  required String title,
  required Color color,
  bool isTablet = false,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: isTablet ? 28 : 24,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isTablet ? 13.5 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.2,
        ),
      ),
    ],
  );
}