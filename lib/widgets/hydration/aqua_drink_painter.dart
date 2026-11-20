import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../animations/aqua_motion.dart';

/// Crisp vector beverage icon painter supporting all AquaCare drink types.
class AquaDrinkIcon extends StatelessWidget {
  const AquaDrinkIcon({
    super.key,
    required this.kind,
    required this.color,
    this.size = 38,
    this.showPlusBadge = false,
  });

  final String kind;
  final Color color;
  final double size;
  final bool showPlusBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DrinkVectorPainter(kind: kind, color: color),
            ),
          ),
          if (showPlusBadge)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyInk.withValues(alpha: 0.14),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: size * 0.30,
                    color: AppColors.cyanVivid,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrinkVectorPainter extends CustomPainter {
  const _DrinkVectorPainter({required this.kind, required this.color});

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    switch (kind) {
      case 'warm_water':
        _paintWarmWater(canvas, w, h);
        break;
      case 'green_tea':
        _paintMug(canvas, w, h);
        break;
      case 'coffee':
        _paintCoffeeCup(canvas, w, h);
        break;
      case 'milk_coffee':
        _paintMilkCoffee(canvas, w, h);
        break;
      case 'coconut':
        _paintCoconut(canvas, w, h);
        break;
      case 'nut_milk':
        _paintMilkBottle(canvas, w, h);
        break;
      case 'juice':
        _paintJuiceCup(canvas, w, h);
        break;
      case 'water':
      default:
        _paintWaterGlass(canvas, w, h);
        break;
    }
  }

  void _paintWaterGlass(Canvas canvas, double w, double h) {
    final body = Path()
      ..moveTo(w * 0.20, h * 0.14)
      ..lineTo(w * 0.80, h * 0.14)
      ..lineTo(w * 0.72, h * 0.89)
      ..quadraticBezierTo(w * 0.71, h * 0.94, w * 0.65, h * 0.94)
      ..lineTo(w * 0.35, h * 0.94)
      ..quadraticBezierTo(w * 0.29, h * 0.94, w * 0.28, h * 0.89)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.16),
        width: w * 0.58,
        height: h * 0.10,
      ),
      Paint()..color = Color.lerp(color, Colors.white, 0.52)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.27, w * 0.08, h * 0.48),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _paintWarmWater(Canvas canvas, double w, double h) {
    final steamPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.34, h * 0.06, w * 0.12, h * 0.16),
      math.pi * 0.6,
      math.pi,
      false,
      steamPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.54, h * 0.04, w * 0.12, h * 0.16),
      math.pi * 0.6,
      math.pi,
      false,
      steamPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.22, h * 0.28, w * 0.56, h * 0.62),
        topLeft: Radius.circular(w * 0.06),
        topRight: Radius.circular(w * 0.06),
        bottomLeft: Radius.circular(w * 0.20),
        bottomRight: Radius.circular(w * 0.20),
      ),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.28),
        width: w * 0.56,
        height: h * 0.10,
      ),
      Paint()..color = Color.lerp(color, Colors.white, 0.52)!,
    );
  }

  void _paintMug(Canvas canvas, double w, double h) {
    canvas.drawArc(
      Rect.fromLTWH(w * 0.66, h * 0.36, w * 0.22, h * 0.36),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.18, h * 0.26, w * 0.56, h * 0.66),
        topLeft: Radius.circular(w * 0.06),
        topRight: Radius.circular(w * 0.06),
        bottomLeft: Radius.circular(w * 0.18),
        bottomRight: Radius.circular(w * 0.18),
      ),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.46, h * 0.26),
        width: w * 0.56,
        height: h * 0.12,
      ),
      Paint()..color = Color.lerp(color, Colors.white, 0.45)!,
    );
    canvas.drawLine(
      Offset(w * 0.36, h * 0.26),
      Offset(w * 0.36, h * 0.48),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = w * 0.03,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.29, h * 0.47, w * 0.14, h * 0.18),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }

  void _paintCoffeeCup(Canvas canvas, double w, double h) {
    final cup = Path()
      ..moveTo(w * 0.24, h * 0.26)
      ..lineTo(w * 0.76, h * 0.26)
      ..lineTo(w * 0.68, h * 0.92)
      ..lineTo(w * 0.32, h * 0.92)
      ..close();
    canvas.drawPath(cup, Paint()..color = color);
    final sleeve = Path()
      ..moveTo(w * 0.26, h * 0.44)
      ..lineTo(w * 0.74, h * 0.44)
      ..lineTo(w * 0.71, h * 0.72)
      ..lineTo(w * 0.29, h * 0.72)
      ..close();
    canvas.drawPath(
      sleeve,
      Paint()..color = Color.lerp(color, Colors.black, 0.25)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.20, h * 0.18, w * 0.60, h * 0.10),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = Color.lerp(color, Colors.black, 0.32)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.10, w * 0.48, h * 0.09),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = Color.lerp(color, Colors.black, 0.20)!,
    );
  }

  void _paintMilkCoffee(Canvas canvas, double w, double h) {
    final glass = Path()
      ..moveTo(w * 0.24, h * 0.20)
      ..lineTo(w * 0.76, h * 0.20)
      ..lineTo(w * 0.70, h * 0.92)
      ..lineTo(w * 0.30, h * 0.92)
      ..close();
    canvas.drawPath(glass, Paint()..color = color);
    canvas.save();
    canvas.clipPath(glass);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.64, w, h * 0.30),
      Paint()..color = const Color(0xFFF6EFE6),
    );
    canvas.restore();
    // Ice cube inside
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.36, h * 0.28, w * 0.24, h * 0.20),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _paintCoconut(Canvas canvas, double w, double h) {
    // Straw
    canvas.drawLine(
      Offset(w * 0.52, h * 0.28),
      Offset(w * 0.66, h * 0.06),
      Paint()
        ..color = AppColors.sunnyButter
        ..strokeWidth = w * 0.065
        ..strokeCap = StrokeCap.round,
    );
    // Green coconut shell
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.58),
        width: w * 0.66,
        height: h * 0.68,
      ),
      Paint()..color = color,
    );
    // White coconut meat rim on top
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.34),
        width: w * 0.46,
        height: h * 0.16,
      ),
      Paint()..color = const Color(0xFFECFDF5),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.34),
        width: w * 0.32,
        height: h * 0.09,
      ),
      Paint()..color = const Color(0xFFB5EFE4),
    );
  }

  void _paintMilkBottle(Canvas canvas, double w, double h) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.37, h * 0.08, w * 0.26, h * 0.09),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = const Color(0xFFB5C4CE),
    );
    final body = Path()
      ..moveTo(w * 0.39, h * 0.17)
      ..lineTo(w * 0.61, h * 0.17)
      ..quadraticBezierTo(w * 0.64, h * 0.30, w * 0.72, h * 0.38)
      ..lineTo(w * 0.72, h * 0.88)
      ..quadraticBezierTo(w * 0.72, h * 0.94, w * 0.64, h * 0.94)
      ..lineTo(w * 0.36, h * 0.94)
      ..quadraticBezierTo(w * 0.28, h * 0.94, w * 0.28, h * 0.88)
      ..lineTo(w * 0.28, h * 0.38)
      ..quadraticBezierTo(w * 0.36, h * 0.30, w * 0.39, h * 0.17)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.45, w * 0.36, h * 0.22),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  void _paintJuiceCup(Canvas canvas, double w, double h) {
    canvas.drawLine(
      Offset(w * 0.56, h * 0.30),
      Offset(w * 0.68, h * 0.06),
      Paint()
        ..color = Color.lerp(color, Colors.white, 0.35)!
        ..strokeWidth = w * 0.065
        ..strokeCap = StrokeCap.round,
    );
    final cup = Path()
      ..moveTo(w * 0.22, h * 0.26)
      ..lineTo(w * 0.78, h * 0.26)
      ..lineTo(w * 0.70, h * 0.92)
      ..lineTo(w * 0.30, h * 0.92)
      ..close();
    canvas.drawPath(cup, Paint()..color = color);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.26),
        width: w * 0.56,
        height: h * 0.09,
      ),
      Paint()..color = Color.lerp(color, Colors.white, 0.45)!,
    );
  }

  @override
  bool shouldRepaint(covariant _DrinkVectorPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// Interactive Waterllama-style Giant Cup with live sloshing waves, bubbles,
/// and a vertical drag handle for direct physical volume adjustment.
class AquaGiantInteractiveCup extends StatefulWidget {
  const AquaGiantInteractiveCup({
    super.key,
    required this.fillFraction,
    required this.liquidColor,
    required this.onVerticalDragDelta,
    this.waveEnabled = true,
  });

  final double fillFraction;
  final Color liquidColor;
  final ValueChanged<double> onVerticalDragDelta;
  final bool waveEnabled;

  @override
  State<AquaGiantInteractiveCup> createState() =>
      _AquaGiantInteractiveCupState();
}

class _AquaGiantInteractiveCupState extends State<AquaGiantInteractiveCup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.waveEnabled && AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.28;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handleY = (1.0 - widget.fillFraction.clamp(0.08, 0.94)) * 212 + 30;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) =>
          widget.onVerticalDragDelta(details.delta.dy),
      child: SizedBox(
        width: 228,
        height: 266,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                return CustomPaint(
                  size: const Size(228, 266),
                  painter: _GiantCupPainter(
                    fillFraction: widget.fillFraction,
                    liquidColor: widget.liquidColor,
                    phase: _controller.value * 2 * math.pi,
                  ),
                );
              },
            ),
            Positioned(
              top: handleY.clamp(34.0, 210.0),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.navyInk.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navyInk.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.unfold_more_rounded,
                  color: AppColors.pureWhite,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiantCupPainter extends CustomPainter {
  const _GiantCupPainter({
    required this.fillFraction,
    required this.liquidColor,
    required this.phase,
  });

  final double fillFraction;
  final Color liquidColor;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cupPath = Path()
      ..moveTo(w * 0.08, h * 0.05)
      ..lineTo(w * 0.92, h * 0.05)
      ..lineTo(w * 0.82, h * 0.92)
      ..quadraticBezierTo(w * 0.80, h * 0.98, w * 0.68, h * 0.98)
      ..lineTo(w * 0.32, h * 0.98)
      ..quadraticBezierTo(w * 0.20, h * 0.98, w * 0.18, h * 0.92)
      ..close();

    canvas.drawPath(cupPath, Paint()..color = const Color(0xFFF1F5F8));

    canvas.save();
    canvas.clipPath(cupPath);

    final topY = h * (0.94 - fillFraction.clamp(0.05, 0.94) * 0.86);
    final wavePath = Path()..moveTo(0, h);
    for (double x = 0; x <= w; x += 4) {
      final wy = topY + 5.0 * math.sin((x / w) * 2 * math.pi * 1.4 + phase);
      wavePath.lineTo(x, wy);
    }
    wavePath
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(wavePath, Paint()..color = liquidColor);

    final crest = Path()..moveTo(0, topY);
    for (double x = 0; x <= w; x += 4) {
      final wy = topY + 5.0 * math.sin((x / w) * 2 * math.pi * 1.4 + phase);
      crest.lineTo(x, wy);
    }
    canvas.drawPath(
      crest,
      Paint()
        ..color = Color.lerp(liquidColor, Colors.white, 0.45)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    final bPaint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    final t = phase / (2 * math.pi);
    final bubbles = [
      (0.34, (0.85 - t * 0.35) % 0.7 + 0.22, 4.8),
      (0.64, (0.92 - t * 0.45) % 0.7 + 0.22, 6.2),
      (0.49, (0.70 - t * 0.50) % 0.7 + 0.25, 3.8),
    ];
    for (final (bx, by, br) in bubbles) {
      final yPx = h * by;
      if (yPx > topY + 14) {
        canvas.drawCircle(Offset(w * bx, yPx), br, bPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GiantCupPainter oldDelegate) =>
      oldDelegate.fillFraction != fillFraction ||
      oldDelegate.liquidColor != liquidColor ||
      oldDelegate.phase != phase;
}
