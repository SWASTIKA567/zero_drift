import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ZeroDriftLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;
  final Color? color;

  const ZeroDriftLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.showSubtitle = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _ZeroDriftIconPainter(
          primaryColor: color ?? AppColors.primary,
        ),
      ),
    );

    if (!showText) {
      return iconWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ZERO',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'DRIFT',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                'Intelligent Dead Reckoning System',
                style: TextStyle(
                  fontSize: (size * 0.22).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ZeroDriftIconPainter extends CustomPainter {
  final Color primaryColor;

  _ZeroDriftIconPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer thick ring with gradient/tech feel
    final outerRingPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round;

    // Draw almost full outer arc (like a dead reckoning radar ring)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.72),
      -math.pi / 4,
      math.pi * 1.8,
      false,
      outerRingPaint,
    );

    // Inner target core
    final innerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, innerPaint);

    final corePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.20, corePaint);

    // Satellite point on outer edge
    final satAngle = -math.pi / 4;
    final satCenter = Offset(
      center.dx + radius * 0.72 * math.cos(satAngle),
      center.dy + radius * 0.72 * math.sin(satAngle),
    );
    final satPaint = Paint()
      ..color = const Color(0xFF00D1FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(satCenter, radius * 0.09, satPaint);
  }

  @override
  bool shouldRepaint(covariant _ZeroDriftIconPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor;
  }
}
