import 'dart:ui';

import 'package:classlift/utils/classlift_colors.dart';
import 'package:classlift/widgets/selection/selection_flow_widgets.dart';
import 'package:flutter/material.dart';

class OptionsBottomSheet extends StatefulWidget {
  final VoidCallback onExcel;
  final VoidCallback onManual;

  const OptionsBottomSheet({
    required this.onExcel,
    required this.onManual,
    super.key,
  });

  @override
  State<OptionsBottomSheet> createState() => _OptionsBottomSheetState();
}

class _OptionsBottomSheetState extends State<OptionsBottomSheet> {
  bool _isClosing = false;

  void _close([VoidCallback? action]) {
    if (_isClosing || ModalRoute.of(context)?.isCurrent == false) return;
    _isClosing = true;
    Navigator.of(context).pop();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extraTextHeight =
            (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 28);
        final initialSize =
            ((480 + extraTextHeight * 12) / constraints.maxHeight)
                .clamp(.45, .92);

        return DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: (220 / constraints.maxHeight).clamp(.35, initialSize),
          maxChildSize: .94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: ClassliftColors.PrimaryColor.withValues(alpha: .12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          ClassliftColors.selectionIcon.withValues(alpha: .96),
                          ClassliftColors.selectionSurface
                              .withValues(alpha: .97),
                          ClassliftColors.White.withValues(alpha: .98),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            decoration: BoxDecoration(
                              color: ClassliftColors.selectionBorder,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const SelectionIcon(
                                    icon: Icons.calendar_month_rounded,
                                    selected: true,
                                    size: 42,
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: _close,
                                    tooltip: 'Cerrar opciones',
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          ClassliftColors.White.withValues(
                                              alpha: .65),
                                      foregroundColor:
                                          ClassliftColors.selectionMuted,
                                      minimumSize: const Size(44, 44),
                                    ),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 21),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Agregá tus clases',
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.2,
                                  letterSpacing: -.5,
                                  fontWeight: FontWeight.w700,
                                  color: ClassliftColors.selectionInk,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Elegí cómo querés armar tu horario.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: ClassliftColors.selectionMuted,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _OptionCard(
                                icon: Icons.upload_file_rounded,
                                title: 'Importar desde Excel',
                                description:
                                    'Cargá el archivo de tu facultad y elegí tus materias.',
                                emphasized: true,
                                onTap: () => _close(widget.onExcel),
                              ),
                              const SizedBox(height: 12),
                              _OptionCard(
                                icon: Icons.edit_calendar_outlined,
                                title: 'Agregar manualmente',
                                description: 'Creá tus clases una por una.',
                                badge: 'Próximamente',
                                onTap: () => _close(widget.onManual),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                          child: SafeArea(
                            top: false,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ClassliftColors.selectionBlue,
                                    ClassliftColors.selectionButtonEnd,
                                  ],
                                ),
                                border: Border.all(
                                  color: ClassliftColors.White.withValues(
                                      alpha: .24),
                                  width: .8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        ClassliftColors.PrimaryColor.withValues(
                                            alpha: .16),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: _close,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  backgroundColor: ClassliftColors.transparent,
                                  foregroundColor: ClassliftColors.White,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool emphasized;
  final String? badge;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.emphasized = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SelectionSurface(
      selected: emphasized,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: ClassliftColors.selectionBlue.withValues(alpha: .1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: emphasized ? null : ClassliftColors.selectionIcon,
                  gradient: emphasized
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ClassliftColors.selectionBlue,
                            ClassliftColors.selectionButtonEnd,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: emphasized
                      ? ClassliftColors.White
                      : ClassliftColors.selectionBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: ClassliftColors.selectionInk,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 5),
                    Text(description,
                        style: const TextStyle(
                          color: ClassliftColors.selectionMuted,
                          fontSize: 12,
                          height: 1.45,
                        )),
                    if (badge != null) ...[
                      const SizedBox(height: 8),
                      SelectionBadge(label: badge!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 21,
                color: emphasized
                    ? ClassliftColors.selectionBlue
                    : ClassliftColors.selectionMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
