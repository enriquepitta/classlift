import 'package:classlift/screens/login/widgets/login_background.dart';
import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const selectionAnimationDuration = Duration(milliseconds: 220);

/// Shared visual shell; selection, navigation and persistence belong to screens.
class SelectionFlowScaffold extends StatelessWidget {
  final String title;
  final String accentTitle;
  final String description;
  final int step;
  final List<Widget> slivers;
  final Widget footer;

  const SelectionFlowScaffold({
    super.key,
    required this.title,
    required this.accentTitle,
    required this.description,
    required this.step,
    required this.slivers,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ClassliftColors.selectionSurface,
        body: Stack(
          children: [
            const LoginBackground(
              backgroundGradient: ClassliftColors.selectionBackgroundGradient,
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => Navigator.maybePop(context),
                              tooltip: 'Volver',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    ClassliftColors.White.withValues(
                                        alpha: .28),
                                foregroundColor: ClassliftColors.selectionBlue,
                                minimumSize: const Size(48, 48),
                              ),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 20),
                            ),
                            Semantics(
                              label: 'Paso $step de 2',
                              child: Row(
                                children: List.generate(2, (index) {
                                  return Container(
                                    width: index + 1 == step ? 24 : 8,
                                    height: 6,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: ClassliftColors.White.withValues(
                                          alpha: index + 1 <= step ? .95 : .4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 18, 24, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: ClassliftColors.selectionInk,
                                        fontSize: 30,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.9,
                                      ),
                                    ),
                                    Text(
                                      accentTitle,
                                      style: const TextStyle(
                                        color: ClassliftColors.selectionBlue,
                                        fontSize: 30,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.9,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        color: ClassliftColors.selectionMuted,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...slivers,
                            const SliverToBoxAdapter(
                                child: SizedBox(height: 20)),
                          ],
                        ),
                      ),
                      footer,
                    ],
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

class SelectionFooter extends StatelessWidget {
  final String? caption;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SelectionFooter({
    super.key,
    this.caption,
    this.label = 'Continuar',
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ClassliftColors.selectionSurface.withValues(alpha: 0),
            ClassliftColors.selectionSurface.withValues(alpha: .9),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (caption != null) ...[
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ClassliftColors.selectionMuted,
                ),
              ),
              const SizedBox(height: 10),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: onPressed != null || isLoading
                      ? const [
                          ClassliftColors.selectionBlue,
                          ClassliftColors.selectionButtonEnd,
                        ]
                      : const [
                          ClassliftColors.selectionBorder,
                          ClassliftColors.SecondaryColor,
                        ],
                ),
                boxShadow: onPressed == null
                    ? []
                    : [
                        BoxShadow(
                          color: ClassliftColors.selectionBlue
                              .withValues(alpha: .18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                  shadowColor: ClassliftColors.transparent,
                  backgroundColor: ClassliftColors.transparent,
                  disabledBackgroundColor: ClassliftColors.transparent,
                  foregroundColor: ClassliftColors.White,
                  disabledForegroundColor: ClassliftColors.White,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ClassliftColors.White,
                          semanticsLabel: 'Cargando carreras',
                        ),
                      )
                    : Row(
                        children: [
                          const SizedBox(width: 36),
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  ClassliftColors.White.withValues(alpha: .18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                size: 21),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionSurface extends StatelessWidget {
  final Widget child;
  final bool selected;
  final EdgeInsetsGeometry? padding;

  const SelectionSurface({
    super.key,
    required this.child,
    this.selected = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: selectionAnimationDuration,
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: selected
            ? ClassliftColors.selectionIcon.withValues(alpha: .78)
            : ClassliftColors.White.withValues(alpha: .72),
        border: Border.all(
          color: selected
              ? ClassliftColors.selectionBorder
              : ClassliftColors.White.withValues(alpha: .9),
        ),
        boxShadow: [
          BoxShadow(
            color: ClassliftColors.selectionBlue
                .withValues(alpha: selected ? .1 : .04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(color: ClassliftColors.transparent, child: child),
    );
  }
}

class SelectionIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final double size;

  const SelectionIcon({
    super.key,
    this.icon = Icons.school_outlined,
    this.selected = false,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: selectionAnimationDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected
            ? ClassliftColors.selectionBlue
            : ClassliftColors.selectionIcon,
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          size: size * .53,
          color:
              selected ? ClassliftColors.White : ClassliftColors.selectionInk),
    );
  }
}

/// A checkbox (not a radio): the flow allows more than one career or subject.
class SelectionIndicator extends StatelessWidget {
  final bool selected;
  final bool partial;

  const SelectionIndicator({
    super.key,
    required this.selected,
    this.partial = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected || partial;
    return AnimatedContainer(
      duration: selectionAnimationDuration,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? ClassliftColors.selectionBlue
            : ClassliftColors.transparent,
        border: Border.all(
          width: 1.3,
          color: active
              ? ClassliftColors.selectionBlue
              : ClassliftColors.selectionMuted.withValues(alpha: .7),
        ),
      ),
      child: active
          ? Icon(partial && !selected ? Icons.remove : Icons.check_rounded,
              size: 15, color: ClassliftColors.White)
          : null,
    );
  }
}

class SelectionBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const SelectionBadge({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ClassliftColors.selectionIcon.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(icon,
                    size: 13, color: ClassliftColors.PrimaryColorVariant),
              ),
            ),
          TextSpan(text: label),
        ]),
        style: const TextStyle(
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w500,
          color: ClassliftColors.PrimaryColorVariant,
        ),
      ),
    );
  }
}
