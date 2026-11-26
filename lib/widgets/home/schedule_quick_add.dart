import 'dart:math' as math;
import 'dart:ui';

import 'package:classlift/utils/classlift_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _ScheduleAction {
  faculty('Horarios de la facultad', Icons.school_outlined),
  excel('Importar desde Excel', Icons.upload_file_outlined);

  const _ScheduleAction(this.label, this.icon);

  final String label;
  final IconData icon;
}

class ScheduleQuickAdd extends StatefulWidget {
  const ScheduleQuickAdd({
    super.key,
    required this.onFaculty,
    required this.onExcel,
    this.onOpened,
  });

  final VoidCallback onFaculty;
  final VoidCallback onExcel;
  final VoidCallback? onOpened;

  @override
  State<ScheduleQuickAdd> createState() => _ScheduleQuickAddState();
}

class _ScheduleQuickAddState extends State<ScheduleQuickAdd>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 140),
  )..addStatusListener(_finishDismissal);

  LocalHistoryEntry? _historyEntry;
  _QuickAddLayout? _layout;
  _ScheduleAction? _highlighted;
  _ScheduleAction? _selection;
  bool _holding = false;

  void _show({bool holding = false}) {
    final route = ModalRoute.of(context);
    if (_portal.isShowing || route == null || !route.isCurrent) return;
    widget.onOpened?.call();
    _holding = holding;
    final entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: _closeFromHistory,
    );
    _historyEntry = entry;
    route.addLocalHistoryEntry(entry);
    _portal.show();
    _animation.forward();
    HapticFeedback.selectionClick();
  }

  void _dismiss([_ScheduleAction? action]) {
    final entry = _historyEntry;
    if (entry == null) return;
    _selection = action;
    entry.remove();
  }

  void _closeFromHistory() {
    if (_historyEntry == null) return;
    _historyEntry = null;
    _animation.reverse();
  }

  void _finishDismissal(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !_portal.isShowing) return;
    _portal.hide();
    _holding = false;
    _highlighted = null;
    _layout = null;
    final selection = _selection;
    _selection = null;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    switch (selection) {
      case _ScheduleAction.faculty:
        widget.onFaculty();
      case _ScheduleAction.excel:
        widget.onExcel();
      case null:
        break;
    }
  }

  Offset _overlayPosition(Offset globalPosition) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    return overlay.globalToLocal(globalPosition);
  }

  void _updateHold(LongPressMoveUpdateDetails details) {
    if (!_holding || _historyEntry == null) return;
    final action = _layout?.actionAt(_overlayPosition(details.globalPosition));
    if (action == _highlighted) return;
    setState(() => _highlighted = action);
    HapticFeedback.selectionClick();
  }

  void _endHold(LongPressEndDetails details) {
    if (!_holding || _historyEntry == null) return;
    final buttonBounds = Offset.zero & (context.size ?? Size.zero);
    if (buttonBounds.contains(details.localPosition)) {
      setState(() {
        _holding = false;
        _highlighted = null;
      });
    } else {
      _dismiss(_layout?.actionAt(_overlayPosition(details.globalPosition)));
    }
  }

  @override
  void dispose() {
    final entry = _historyEntry;
    _historyEntry = null;
    entry?.remove();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.viewPaddingOf(Overlay.of(context).context);
    final textScaler = MediaQuery.textScalerOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, info) {
        final anchor = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        final layout = _QuickAddLayout(
          anchor: anchor,
          bounds: safePadding.deflateRect(Offset.zero & info.overlaySize),
          labelFontSize: textScaler.scale(13),
        );
        _layout = layout;

        return BlockSemantics(
          child: FocusScope(
            autofocus: true,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): _dismiss
              },
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  final progress =
                      Curves.easeOutCubic.transform(_animation.value);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ModalBarrier(
                        color: ClassliftColors.Black.withValues(
                            alpha: .58 * progress),
                        onDismiss: _dismiss,
                        semanticsLabel: 'Cerrar acciones rápidas',
                        barrierSemanticsDismissible: false,
                      ),
                      for (final target in layout.targets)
                        Positioned.fromRect(
                          rect: target.frame,
                          child: Transform.translate(
                            offset: reduceMotion
                                ? Offset.zero
                                : (target.circle.center - anchor.center) *
                                    (progress - 1),
                            child: Opacity(
                              opacity: progress,
                              child: _QuickAddOption(
                                target: target,
                                highlighted: target.action == _highlighted,
                                onPressed: () => _dismiss(target.action),
                              ),
                            ),
                          ),
                        ),
                      if (_holding && layout.showGestureHints)
                        _GestureHints(layout: layout, opacity: progress),
                      Positioned.fromRect(
                        rect: anchor,
                        child: Opacity(
                          opacity: progress,
                          child: _AddButton(close: true, onPressed: _dismiss),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
      child: Listener(
        onPointerCancel: (_) {
          if (_holding) _dismiss();
        },
        child: RawGestureDetector(
          excludeFromSemantics: true,
          gestures: {
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: const Duration(milliseconds: 350),
              ),
              (recognizer) {
                recognizer.onLongPressStart = (_) => _show(holding: true);
                recognizer
                  ..onLongPressMoveUpdate = _updateHold
                  ..onLongPressEnd = _endHold;
              },
            ),
          },
          child: _AddButton(onPressed: _show),
        ),
      ),
    );
  }
}

class _QuickAddLayout {
  _QuickAddLayout({
    required this.anchor,
    required this.bounds,
    required double labelFontSize,
  }) {
    final largeText = labelFontSize > 17;
    final diameter = largeText ? 64.0 : 56.0;
    final labelWidth = math.min(largeText ? 148.0 : 112.0, bounds.width / 2);
    final labelHeight = labelFontSize * (largeText ? 3.6 : 2.5);
    final radius = math
        .min(
          largeText ? 195.0 : 164.0,
          math.min(anchor.center.dy - bounds.top - diameter / 2 - 12,
              (anchor.center.dx - bounds.left - diameter / 2 - 16) / .866),
        )
        .clamp(0.0, double.infinity)
        .toDouble();

    targets = [
      for (final action in _ScheduleAction.values)
        _target(
          action,
          anchor.center +
              Offset(
                action == _ScheduleAction.faculty ? 0 : -.866 * radius,
                action == _ScheduleAction.faculty ? -radius : -.5 * radius,
              ),
          diameter,
          labelWidth,
          labelHeight,
        ),
    ];
    showGestureHints = !largeText &&
        bounds.width >= 320 &&
        targets.first.circle.top - bounds.top >= 34;
  }

  final Rect anchor;
  final Rect bounds;
  late final List<_QuickAddTarget> targets;
  late final bool showGestureHints;

  _QuickAddTarget _target(_ScheduleAction action, Offset center,
      double diameter, double labelWidth, double labelHeight) {
    final circle =
        Rect.fromCenter(center: center, width: diameter, height: diameter);
    final margin = math.min(12.0, bounds.width / 4);
    final left = (center.dx - labelWidth / 2)
        .clamp(bounds.left + margin, bounds.right - labelWidth - margin)
        .toDouble();
    return _QuickAddTarget(
      action,
      circle,
      Rect.fromLTWH(left, circle.bottom + 5, labelWidth, labelHeight),
    );
  }

  _ScheduleAction? actionAt(Offset point) {
    for (final target in targets) {
      if ((point - target.circle.center).distance <= target.circle.width / 2 ||
          target.label.contains(point)) {
        return target.action;
      }
    }
    return null;
  }
}

class _QuickAddTarget {
  const _QuickAddTarget(this.action, this.circle, this.label);

  final _ScheduleAction action;
  final Rect circle;
  final Rect label;

  Rect get frame => circle.expandToInclude(label);
}

class _QuickAddOption extends StatelessWidget {
  const _QuickAddOption({
    required this.target,
    required this.highlighted,
    required this.onPressed,
  });

  final _QuickAddTarget target;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final origin = target.frame.topLeft;

    return ClipPath(
      clipper: _OptionHitArea(target),
      clipBehavior: Clip.none,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: ClassliftColors.White,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: target.circle.shift(-origin),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: highlighted
                      ? ClassliftColors.navigationAccent
                      : ClassliftColors.Black.withValues(alpha: .88),
                  border: Border.all(
                    color: ClassliftColors.White.withValues(
                        alpha: highlighted ? .7 : .22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ClassliftColors.Black.withValues(alpha: .18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(target.action.icon,
                    size: 25, color: ClassliftColors.White),
              ),
            ),
            Positioned.fromRect(
              rect: target.label.shift(-origin),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  target.action.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, height: 1.15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionHitArea extends CustomClipper<Path> {
  const _OptionHitArea(this.target);

  final _QuickAddTarget target;

  @override
  Path getClip(Size size) {
    final offset = -target.frame.topLeft;
    return Path()
      ..addOval(target.circle.shift(offset))
      ..addRect(target.label.shift(offset));
  }

  @override
  bool shouldReclip(_OptionHitArea oldClipper) => target != oldClipper.target;
}

class _GestureHints extends StatelessWidget {
  const _GestureHints({required this.layout, required this.opacity});

  final _QuickAddLayout layout;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: ClassliftColors.White, fontSize: 11);
    final firstCircle = layout.targets.first.circle;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacity * .85,
          child: Stack(
            children: [
              Positioned(
                left: firstCircle.right - 220,
                top: firstCircle.top - 32,
                width: 220,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(child: Text('Deslizá y soltá', style: style)),
                    SizedBox(width: 6),
                    Icon(Icons.turn_right_rounded,
                        color: ClassliftColors.White, size: 14),
                  ],
                ),
              ),
              Positioned(
                left: layout.bounds.left + 16,
                top: layout.anchor.center.dy - 8,
                child: const Text('Soltá fuera para cancelar', style: style),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({this.close = false, required this.onPressed});

  final bool close;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ClassliftColors.navigationShadow.withValues(alpha: .32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (close) ...[
            const BoxShadow(
              color: ClassliftColors.navigationAccent,
              spreadRadius: 3.5,
            ),
            const BoxShadow(color: ClassliftColors.White, spreadRadius: 1.5),
          ] else
            BoxShadow(
              color: ClassliftColors.navigationShadow.withValues(alpha: .12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: SizedBox.square(
        dimension: 60,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ClassliftColors.navigationAccent
                        .withValues(alpha: close ? 1 : .70),
                    ClassliftColors.navigationAccentEnd
                        .withValues(alpha: close ? 1 : .44),
                  ],
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  onPressed: onPressed,
                  tooltip: close ? 'Cerrar acciones rápidas' : 'Añadir',
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    close ? Icons.close_rounded : Icons.add_rounded,
                    color: ClassliftColors.White,
                    size: close ? 25 : 32,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
