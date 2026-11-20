import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'aqua_motion.dart';

/// Full-screen rising cyan wave transition inspired by Waterllama (`WaterWavePageRoute`).
class AquaWavePageRoute<T> extends PageRouteBuilder<T> {
  AquaWavePageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 680),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              builder: (_, _) {
                if (curved.value >= 0.995) return child;
                return ClipPath(
                  clipper: _RisingWaveClipper(progress: curved.value),
                  child: child,
                );
              },
            );
          },
        );
}

class _RisingWaveClipper extends CustomClipper<Path> {
  const _RisingWaveClipper({required this.progress});

  final double progress;

  @override
  Path getClip(Size size) {
    final topY = size.height * (1.0 - progress) - 24;
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 6) {
      final y = topY +
          22 * math.sin((x / size.width) * 2 * math.pi + progress * 4.0);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _RisingWaveClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Finite 46-piece multi-color fluttering confetti burst triggered when hitting 100% goals.
class AquaConfettiOverlay extends StatefulWidget {
  const AquaConfettiOverlay({
    super.key,
    required this.triggerKey,
    this.duration = const Duration(milliseconds: 1700),
  });

  final int triggerKey;
  final Duration duration;

  @override
  State<AquaConfettiOverlay> createState() => _AquaConfettiOverlayState();
}

class _AquaConfettiOverlayState extends State<AquaConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_ConfettiPiece> _pieces;

  static const _palette = [
    Color(0xFFFF2469),
    Color(0xFF00BBE4),
    Color(0xFFFFC93C),
    Color(0xFF52D681),
    Color(0xFF8E9AFE),
    Color(0xFFFF8A3C),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _pieces = _generatePieces(widget.triggerKey);
    if (widget.triggerKey > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant AquaConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerKey != oldWidget.triggerKey && widget.triggerKey > 0) {
      _pieces = _generatePieces(widget.triggerKey);
      _controller.forward(from: 0);
    }
  }

  List<_ConfettiPiece> _generatePieces(int seed) {
    final rng = math.Random(seed + 17);
    return List.generate(46, (i) {
      return _ConfettiPiece(
        xNorm: 0.08 + rng.nextDouble() * 0.84,
        yStart: -0.05 + rng.nextDouble() * 0.42,
        fallDist: 0.48 + rng.nextDouble() * 0.52,
        swayAmp: 10 + rng.nextDouble() * 24,
        rotSpeed: (rng.nextDouble() - 0.5) * 10,
        w: 6 + rng.nextDouble() * 6,
        h: 9 + rng.nextDouble() * 7,
        color: _palette[i % _palette.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.triggerKey <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          if (_controller.isDismissed || _controller.isCompleted) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              pieces: _pieces,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.xNorm,
    required this.yStart,
    required this.fallDist,
    required this.swayAmp,
    required this.rotSpeed,
    required this.w,
    required this.h,
    required this.color,
  });

  final double xNorm;
  final double yStart;
  final double fallDist;
  final double swayAmp;
  final double rotSpeed;
  final double w;
  final double h;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.progress});

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity =
        progress > 0.72 ? ((1.0 - progress) / 0.28).clamp(0.0, 1.0) : 1.0;
    for (final p in pieces) {
      final x = p.xNorm * size.width +
          math.sin(progress * 6.0 + p.xNorm * 10) * p.swayAmp;
      final y = (p.yStart + progress * p.fallDist) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          const Radius.circular(1.8),
        ),
        Paint()..color = p.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Test-safe cyan gradient backdrop with drifting translucent ice cubes and rising bubbles.
class AquaFloatingIceBackground extends StatefulWidget {
  const AquaFloatingIceBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AquaFloatingIceBackground> createState() =>
      _AquaFloatingIceBackgroundState();
}

class _AquaFloatingIceBackgroundState extends State<AquaFloatingIceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cyanBright,
            AppColors.cyanVivid,
            AppColors.deepSky,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                return CustomPaint(
                  painter: _IceCubesAndBubblesPainter(t: _controller.value),
                );
              },
            ),
          ),
          ?widget.child,
        ],
      ),
    );
  }
}

class _IceCubesAndBubblesPainter extends CustomPainter {
  const _IceCubesAndBubblesPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cubePaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.14);
    final edgePaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.10);

    final cubes = [
      (
        size.width * 0.08,
        size.height * 0.22 + math.sin(t * 2 * math.pi) * 8,
        56.0,
        0.25,
      ),
      (
        size.width * 0.93,
        size.height * 0.29 - math.cos(t * 2 * math.pi) * 9,
        64.0,
        -0.30,
      ),
      (
        size.width * 0.05,
        size.height * 0.62 + math.cos(t * 2 * math.pi) * 7,
        52.0,
        -0.18,
      ),
      (
        size.width * 0.94,
        size.height * 0.72 - math.sin(t * 2 * math.pi) * 8,
        60.0,
        0.22,
      ),
    ];

    for (final (cx, cy, s, rot) in cubes) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rot);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          const Radius.circular(14),
        ),
        cubePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: const Offset(-4, -4),
            width: s * 0.68,
            height: s * 0.68,
          ),
          const Radius.circular(9),
        ),
        edgePaint,
      );
      canvas.restore();
    }

    final bubblePaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.24);
    for (int i = 0; i < 12; i++) {
      final bx = size.width * ((0.14 * i + 0.08) % 0.88);
      final by = size.height * (1.12 - ((t * 0.55 + i * 0.11) % 1.0));
      canvas.drawCircle(Offset(bx, by), 2.5 + (i % 3) * 1.1, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IceCubesAndBubblesPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// 54-dot 3-ring counter-rotating multi-color concentric dot spinner (test-safe).
class AquaConcentricDotsSpinner extends StatefulWidget {
  const AquaConcentricDotsSpinner({
    super.key,
    this.size = 220,
    this.dotScale = 1.0,
    this.lightPalette = false,
    this.customPalette,
    this.child,
  });

  final double size;
  final double dotScale;
  final bool lightPalette;
  final List<Color>? customPalette;
  final Widget? child;

  @override
  State<AquaConcentricDotsSpinner> createState() =>
      _AquaConcentricDotsSpinnerState();
}

class _AquaConcentricDotsSpinnerState extends State<AquaConcentricDotsSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.2;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ConcentricDotsPainter(
                  progress: _controller.value,
                  dotScale: widget.dotScale * (widget.size / 220.0),
                  lightPalette: widget.lightPalette,
                  customPalette: widget.customPalette,
                ),
              );
            },
          ),
          ?widget.child,
        ],
      ),
    );
  }
}

class _ConcentricDotsPainter extends CustomPainter {
  const _ConcentricDotsPainter({
    required this.progress,
    required this.dotScale,
    required this.lightPalette,
    this.customPalette,
  });

  final double progress;
  final double dotScale;
  final bool lightPalette;
  final List<Color>? customPalette;

  static const _vibrantColors = [
    Color(0xFF00BBE4),
    Color(0xFF0284C7),
    Color(0xFF8E9AFE),
    Color(0xFFFF2469),
    Color(0xFF52D681),
  ];

  static const _lightColors = [
    Color(0xFFFFFFFF),
    Color(0xFFE6F8FD),
    Color(0xFFFFC93C),
    Color(0xFFCCF5FC),
    Color(0xFF9BE4F6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = (customPalette != null && customPalette!.isNotEmpty)
        ? customPalette!
        : (lightPalette ? _lightColors : _vibrantColors);
    final rings = [
      (size.width * 0.27, 14, 4.6 * dotScale),
      (size.width * 0.36, 18, 5.4 * dotScale),
      (size.width * 0.45, 22, 6.2 * dotScale),
    ];

    for (int rIdx = 0; rIdx < rings.length; rIdx++) {
      final (radius, count, dotR) = rings[rIdx];
      for (int i = 0; i < count; i++) {
        final theta = (i / count) * 2 * math.pi +
            progress * 2 * math.pi * (rIdx.isEven ? 0.5 : -0.4);
        final pos = center +
            Offset(math.cos(theta) * radius, math.sin(theta) * radius);
        final wave =
            0.55 + 0.45 * math.sin(theta * 2 - progress * 4 * math.pi + rIdx);
        final col = colors[(i + rIdx) % colors.length]
            .withValues(alpha: 0.45 + 0.55 * wave);
        canvas.drawCircle(
          pos,
          math.max(1.8, dotR * (0.82 + 0.25 * wave)),
          Paint()..color = col,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricDotsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.dotScale != dotScale ||
      oldDelegate.lightPalette != lightPalette ||
      oldDelegate.customPalette != customPalette;
}

/// Waterllama-style circular 3D coin-flip stat badge (`520ms Matrix4.rotateY`).
class AquaFlipStatBadge extends StatefulWidget {
  const AquaFlipStatBadge({
    super.key,
    required this.frontValue,
    required this.frontLabel,
    required this.backValue,
    required this.backLabel,
    this.size = 64,
    this.frontColor = AppColors.cyanVivid,
    this.backColor = AppColors.navyInk,
    this.onFlipped,
  });

  final String frontValue;
  final String frontLabel;
  final String backValue;
  final String backLabel;
  final double size;
  final Color frontColor;
  final Color backColor;
  final ValueChanged<bool>? onFlipped;

  @override
  State<AquaFlipStatBadge> createState() => _AquaFlipStatBadgeState();
}

class _AquaFlipStatBadgeState extends State<AquaFlipStatBadge> {
  bool _showBack = false;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _showBack = !_showBack);
    widget.onFlipped?.call(_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.size < 68;
    return BouncyPressable(
      pressedScale: 0.92,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          transitionBuilder: (child, anim) {
            return AnimatedBuilder(
              animation: anim,
              builder: (_, _) {
                final angle = (1.0 - anim.value) * math.pi;
                if (angle > math.pi / 2) return const SizedBox.shrink();
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(angle),
                  child: child,
                );
              },
            );
          },
          child: Container(
            key: ValueKey<bool>(_showBack),
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _showBack ? widget.backColor : widget.frontColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_showBack ? widget.backColor : widget.frontColor)
                      .withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _showBack ? widget.backValue : widget.frontValue,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontSize: compact ? 15 : 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.pureWhite,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _showBack ? widget.backLabel : widget.frontLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.bodyFont,
                    fontSize: compact ? 7.5 : 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pureWhite.withValues(alpha: 0.92),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced animated pill progress bar with subtle liquid sheen.
class AquaLiquidProgressBar extends StatelessWidget {
  const AquaLiquidProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.cyanVivid,
    this.backgroundColor = AppColors.cyanTile,
    this.height = 10,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: clamped),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, animated, _) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height),
          ),
          clipBehavior: Clip.antiAlias,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animated.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(color, AppColors.pureWhite, 0.22)!,
                    color,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Test-safe gentle vertical floating & tilt animation for hero illustrations and mascots.
class AquaGentleFloat extends StatefulWidget {
  const AquaGentleFloat({
    super.key,
    required this.child,
    this.amplitude = 6.0,
    this.rotationRadians = 0.0,
    this.duration = const Duration(milliseconds: 2800),
    this.phaseOffset = 0.0,
    this.enabled = true,
  });

  final Widget child;
  final double amplitude;
  final double rotationRadians;
  final Duration duration;
  final double phaseOffset;
  final bool enabled;

  @override
  State<AquaGentleFloat> createState() => _AquaGentleFloatState();
}

class _AquaGentleFloatState extends State<AquaGentleFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  void _syncMotion() {
    if (widget.enabled && AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AquaGentleFloat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _syncMotion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !AquaMotion.allowInfinite(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final wave =
            math.sin((_controller.value + widget.phaseOffset) * 2 * math.pi);
        return Transform.translate(
          offset: Offset(0, wave * widget.amplitude),
          child: widget.rotationRadians == 0.0
              ? child
              : Transform.rotate(
                  angle: wave * widget.rotationRadians,
                  child: child,
                ),
        );
      },
      child: widget.child,
    );
  }
}

/// Test-safe glossy diagonal shimmer sheen sweep for primary CTAs and featured cards.
class AquaShimmerOverlay extends StatefulWidget {
  const AquaShimmerOverlay({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.duration = const Duration(milliseconds: 2600),
    this.shimmerColor = const Color(0x55FFFFFF),
    this.enabled = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Duration duration;
  final Color shimmerColor;
  final bool enabled;

  @override
  State<AquaShimmerOverlay> createState() => _AquaShimmerOverlayState();
}

class _AquaShimmerOverlayState extends State<AquaShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  void _syncMotion() {
    if (widget.enabled && AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AquaShimmerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !AquaMotion.allowInfinite(context)) {
      return widget.child;
    }
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  final t = _controller.value;
                  if (t > 0.45) return const SizedBox.shrink();
                  final sweep = Curves.easeInOutCubic.transform(t / 0.45);
                  return CustomPaint(
                    painter: _DiagonalShimmerPainter(
                      progress: sweep,
                      color: widget.shimmerColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalShimmerPainter extends CustomPainter {
  const _DiagonalShimmerPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bandW = math.max(48.0, size.width * 0.28);
    final travel = size.width + size.height * 0.6 + bandW * 2;
    final startX = -bandW - size.height * 0.3 + travel * progress;

    final path = Path()
      ..moveTo(startX, size.height)
      ..lineTo(startX + bandW, size.height)
      ..lineTo(startX + bandW + size.height * 0.38, 0)
      ..lineTo(startX + size.height * 0.38, 0)
      ..close();

    final rect = path.getBounds();
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.0),
          color,
          color.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Test-safe dual-ring water pulse halo behind interactive goals, icons, and mascots.
class AquaWaterHalo extends StatefulWidget {
  const AquaWaterHalo({
    super.key,
    required this.color,
    this.size = 96,
    this.maxScale = 1.45,
    this.duration = const Duration(milliseconds: 2200),
    this.child,
  });

  final Color color;
  final double size;
  final double maxScale;
  final Duration duration;
  final Widget? child;

  @override
  State<AquaWaterHalo> createState() => _AquaWaterHaloState();
}

class _AquaWaterHaloState extends State<AquaWaterHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AquaMotion.allowInfinite(context)) {
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
    final animate = AquaMotion.allowInfinite(context);
    return SizedBox(
      width: widget.size * widget.maxScale,
      height: widget.size * widget.maxScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  return CustomPaint(
                    painter: _WaterHaloPainter(
                      progress: _controller.value,
                      baseSize: widget.size,
                      maxScale: widget.maxScale,
                      color: widget.color,
                      animate: animate,
                    ),
                  );
                },
              ),
            ),
          ),
          ?widget.child,
        ],
      ),
    );
  }
}

class _WaterHaloPainter extends CustomPainter {
  const _WaterHaloPainter({
    required this.progress,
    required this.baseSize,
    required this.maxScale,
    required this.color,
    required this.animate,
  });

  final double progress;
  final double baseSize;
  final double maxScale;
  final Color color;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (!animate) {
      canvas.drawCircle(
        center,
        baseSize * 0.56,
        Paint()..color = color.withValues(alpha: 0.16),
      );
      return;
    }

    for (final offset in const [0.0, 0.5]) {
      final p = (progress + offset) % 1.0;
      final scale = 0.85 + (maxScale - 0.85) * p;
      final alpha = ((1.0 - p) * 0.30).clamp(0.0, 0.30);
      canvas.drawCircle(
        center,
        (baseSize * 0.5) * scale,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterHaloPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.animate != animate;
}

/// Test-safe soft pastel gradient canvas with drifting ambient orbs and micro water bubbles.
class AquaAmbientOrbsBackdrop extends StatefulWidget {
  const AquaAmbientOrbsBackdrop({
    super.key,
    required this.child,
    this.gradientColors = const [AppColors.iceCanvas, AppColors.pureWhite],
    this.orbColors = const [
      Color(0x285DCCFC),
      Color(0x228E9AFE),
      Color(0x2252D681),
    ],
  });

  final Widget child;
  final List<Color> gradientColors;
  final List<Color> orbColors;

  @override
  State<AquaAmbientOrbsBackdrop> createState() =>
      _AquaAmbientOrbsBackdropState();
}

class _AquaAmbientOrbsBackdropState extends State<AquaAmbientOrbsBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.gradientColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, _) {
                  return CustomPaint(
                    painter: _AmbientOrbsPainter(
                      t: _controller.value,
                      orbColors: widget.orbColors,
                    ),
                  );
                },
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AmbientOrbsPainter extends CustomPainter {
  const _AmbientOrbsPainter({required this.t, required this.orbColors});

  final double t;
  final List<Color> orbColors;

  @override
  void paint(Canvas canvas, Size size) {
    final c0 = orbColors.isNotEmpty ? orbColors[0] : const Color(0x245DCCFC);
    final c1 = orbColors.length > 1 ? orbColors[1] : c0;
    final c2 = orbColors.length > 2 ? orbColors[2] : c1;
    final angle = t * 2 * math.pi;

    canvas.drawCircle(
      Offset(
        size.width * 0.14 + math.sin(angle) * 14,
        size.height * 0.14 + math.cos(angle) * 10,
      ),
      94,
      Paint()..color = c0,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.90 + math.cos(angle) * 12,
        size.height * 0.28 + math.sin(angle) * 14,
      ),
      78,
      Paint()..color = c1,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.82 - math.sin(angle) * 16,
        size.height * 0.78 + math.cos(angle) * 12,
      ),
      96,
      Paint()..color = c2,
    );
    canvas.drawCircle(
      Offset(
        size.width * 0.08 + math.cos(angle) * 10,
        size.height * 0.66 - math.sin(angle) * 12,
      ),
      64,
      Paint()..color = c0.withValues(alpha: (c0.a * 0.85).clamp(0.0, 1.0)),
    );

    final bubblePaint =
        Paint()..color = AppColors.pureWhite.withValues(alpha: 0.45);
    for (int i = 0; i < 8; i++) {
      final bx = size.width * ((0.11 + i * 0.12) % 0.9);
      final by = size.height * (1.06 - ((t * 0.45 + i * 0.13) % 1.0));
      canvas.drawCircle(Offset(bx, by), 2.2 + (i % 3) * 1.1, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientOrbsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.orbColors != orbColors;
}
