import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum BallKind { red, blue, empty, missing }

class BallChip extends StatelessWidget {
  const BallChip({
    super.key,
    required this.number,
    this.kind = BallKind.red,
    this.size = 36,
    this.onTap,
    this.selected = false,
  });

  final int? number;
  final BallKind kind;
  final double size;
  final VoidCallback? onTap;
  final bool selected;

  Color get _bg {
    switch (kind) {
      case BallKind.red:
        return AppColors.redBall;
      case BallKind.blue:
        return AppColors.blueBall;
      case BallKind.empty:
        return AppColors.emptySlot.withValues(alpha: 0.25);
      case BallKind.missing:
        return AppColors.accent;
    }
  }

  Color get _fg {
    switch (kind) {
      case BallKind.empty:
        return AppColors.emptySlot;
      case BallKind.missing:
        return AppColors.ink;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = number == null
        ? (kind == BallKind.empty ? '空' : '—')
        : number!.toString().padLeft(2, '0');

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _bg,
        border: selected
            ? Border.all(color: AppColors.deepGreen, width: 2.5)
            : kind == BallKind.empty
                ? Border.all(color: AppColors.emptySlot, width: 1.5)
                : null,
        boxShadow: kind == BallKind.empty
            ? null
            : [
                BoxShadow(
                  color: _bg.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _fg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
          letterSpacing: -0.5,
        ),
      ),
    );

    // 无 onTap 时不要包 InkWell，避免 Web 上挡住父级点击
    if (onTap == null) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: child,
        ),
      ),
    );
  }
}
