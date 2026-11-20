import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../animations/aqua_motion.dart';
import 'aqua_mascot_catalog.dart';

/// Represents a single colored beverage layer inside [AquaMascotWaveVessel].
class AquaLiquidSlice {
  const AquaLiquidSlice({
    required this.fraction,
    required this.color,
  });

  final double fraction;
  final Color color;
}

/// Waterllama-inspired 3-state Mascot Progress Vessel:
/// - `0%`: Clean `#ECEFF2` Silhouette shape.
/// - `1%–99%`: Clipped multi-layer dual-frequency sloshing waves with sheen & bubbles.
/// - `100%`: Smooth `480ms` crossfade to full-color vibrant vector illustration.
class AquaMascotWaveVessel extends StatefulWidget {
  const AquaMascotWaveVessel({
    super.key,
    required this.mascotId,
    required this.slices,
    this.totalFractionOverride,
    this.slosh = 0.0,
    this.waveEnabled = true,
    this.crossfadeFullAtComplete = true,
    this.waveAmplitude = 4.6,
    this.accessoryName,
    this.onTap,
  });

  final String mascotId;
  final List<AquaLiquidSlice> slices;
  final double? totalFractionOverride;
  final double slosh;
  final bool waveEnabled;
  final bool crossfadeFullAtComplete;
  final double waveAmplitude;
  final String? accessoryName;
  final VoidCallback? onTap;

  @override
  State<AquaMascotWaveVessel> createState() => _AquaMascotWaveVesselState();
}

class _AquaMascotWaveVesselState extends State<AquaMascotWaveVessel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWaveLoop();
  }

  @override
  void didUpdateWidget(covariant AquaMascotWaveVessel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waveEnabled != widget.waveEnabled) {
      _syncWaveLoop();
    }
  }

  void _syncWaveLoop() {
    if (widget.waveEnabled && AquaMotion.allowInfinite(context)) {
      if (!_waveController.isAnimating) {
        _waveController.repeat();
      }
    } else {
      if (_waveController.isAnimating) {
        _waveController.stop();
      }
      _waveController.value = 0.32;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sliceSum = widget.slices
        .fold<double>(0.0, (acc, s) => acc + s.fraction.clamp(0.0, 1.0))
        .clamp(0.0, 1.0);
    final totalFraction =
        (widget.totalFractionOverride ?? sliceSum).clamp(0.0, 1.0);
    final isFull = totalFraction >= 0.999;

    final effectiveSlices = widget.slices.isNotEmpty
        ? widget.slices
        : [
            AquaLiquidSlice(
              fraction: totalFraction,
              color: AquaMascotCatalog.byId(widget.mascotId).accentColor,
            ),
          ];

    final vessel = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: totalFraction),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      builder: (context, animatedTotal, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, _) {
                  return CustomPaint(
                    painter: _MascotWaveVesselPainter(
                      mascotId: widget.mascotId,
                      slices: effectiveSlices,
                      animatedTotal: animatedTotal,
                      phase: _waveController.value * 2 * math.pi,
                      amplitude:
                          widget.waveEnabled ? widget.waveAmplitude : 0.0,
                      slosh: widget.slosh,
                    ),
                  );
                },
              ),
            ),
            if (widget.crossfadeFullAtComplete)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: isFull ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 480),
                  curve: Curves.easeOut,
                  child: CustomPaint(
                    painter: _FullMascotPainter(
                      mascotId: widget.mascotId,
                      accessoryName: widget.accessoryName,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (widget.onTap == null) return vessel;
    return BouncyPressable(
      pressedScale: 0.96,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: vessel,
      ),
    );
  }
}

class _MascotWaveVesselPainter extends CustomPainter {
  const _MascotWaveVesselPainter({
    required this.mascotId,
    required this.slices,
    required this.animatedTotal,
    required this.phase,
    required this.amplitude,
    required this.slosh,
  });

  final String mascotId;
  final List<AquaLiquidSlice> slices;
  final double animatedTotal;
  final double phase;
  final double amplitude;
  final double slosh;

  @override
  void paint(Canvas canvas, Size size) {
    final silhouette = buildMascotSilhouettePath(mascotId, size);
    final bounds = silhouette.getBounds();

    // 1. Base #ECEFF2 silhouette
    canvas.drawPath(
      silhouette,
      Paint()..color = AppColors.silhouetteGrey,
    );

    // 2. Clipped multi-layer sloshing liquid bands
    if (animatedTotal > 0.001 && slices.isNotEmpty) {
      final rawTotal =
          slices.fold<double>(0.0, (a, s) => a + s.fraction.clamp(0.0, 1.0));
      if (rawTotal > 0.0001) {
        final bottomY = bounds.bottom;
        final usableH = bounds.height;
        final scale = (animatedTotal / rawTotal).clamp(0.0, 1.0);
        final sloshBoost = slosh > 0 ? math.sin(slosh * math.pi) * 5.0 : 0.0;

        final bands =
            <({double bottomFraction, double topFraction, Color color})>[];
        double cursor = 0.0;
        for (final s in slices) {
          final f = s.fraction * scale;
          if (f <= 0.0001) continue;
          final next = (cursor + f).clamp(0.0, 1.0);
          bands.add((bottomFraction: cursor, topFraction: next, color: s.color));
          cursor = next;
          if (cursor >= 1.0) break;
        }

        canvas.save();
        canvas.clipPath(silhouette);

        for (int i = bands.length - 1; i >= 0; i--) {
          final band = bands[i];
          final crestY = bottomY - band.topFraction * usableH;
          final amp = band.topFraction >= 0.995
              ? 0.0
              : (amplitude + sloshBoost) *
                  (0.7 + 0.3 * math.sin(i * 1.1 + 1.0));
          final bandPhase = phase + i * 1.15;

          final path = Path();
          if (amp <= 0.05) {
            path.addRect(Rect.fromLTRB(0, crestY, size.width, size.height));
          } else {
            path.moveTo(0, size.height);
            path.lineTo(0, _waveY(0, size.width, crestY, amp, bandPhase));
            const step = 4.0;
            for (double x = step; x <= size.width; x += step) {
              path.lineTo(
                x,
                _waveY(x, size.width, crestY, amp, bandPhase),
              );
            }
            path.lineTo(
              size.width,
              _waveY(size.width, size.width, crestY, amp, bandPhase),
            );
            path.lineTo(size.width, size.height);
            path.close();
          }

          canvas.drawPath(path, Paint()..color = band.color);

          if (amp > 0.2) {
            final highlight = Path()
              ..moveTo(0, _waveY(0, size.width, crestY, amp, bandPhase));
            for (double x = 4.0; x <= size.width; x += 4.0) {
              highlight.lineTo(
                x,
                _waveY(x, size.width, crestY, amp, bandPhase),
              );
            }
            canvas.drawPath(
              highlight,
              Paint()
                ..color = AppColors.pureWhite.withValues(alpha: 0.34)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.2,
            );
          }
        }

        // Subtle rising micro-bubbles inside the filled liquid
        final topFillY = bottomY - animatedTotal * usableH;
        final bubblePaint = Paint()
          ..color = AppColors.pureWhite.withValues(alpha: 0.32);
        const seeds = [
          (0.32, 0.10, 3.2),
          (0.50, 0.45, 2.6),
          (0.66, 0.72, 3.8),
          (0.42, 0.88, 2.4),
        ];
        final normT = phase / (2 * math.pi);
        for (final (bxN, offset, r) in seeds) {
          final bt = (normT + offset) % 1.0;
          final bx = bounds.left + bounds.width * bxN + math.sin(bt * 6.28) * 3;
          final by = bottomY - bt * (bottomY - topFillY) - 6;
          if (by > topFillY + 8) {
            canvas.drawCircle(Offset(bx, by), r, bubblePaint);
          }
        }

        canvas.restore();
      }
    }

    // 3. Soft facial expression overlay so silhouette & filling state feels alive
    paintMascotMinimalFace(
      canvas,
      size,
      mascotId,
      inkColor: AppColors.navyInk,
      opacity: animatedTotal > 0.48 ? 0.84 : 0.34,
    );
  }

  double _waveY(double x, double width, double baseY, double amp, double ph) {
    final nx = (x / width) * 2 * math.pi;
    return baseY +
        amp * math.sin(nx * 1.35 + ph) +
        amp * 0.45 * math.sin(nx * 2.4 - ph * 1.35);
  }

  @override
  bool shouldRepaint(covariant _MascotWaveVesselPainter oldDelegate) =>
      oldDelegate.mascotId != mascotId ||
      oldDelegate.animatedTotal != animatedTotal ||
      oldDelegate.phase != phase ||
      oldDelegate.slosh != slosh ||
      oldDelegate.slices.length != slices.length;
}

class _FullMascotPainter extends CustomPainter {
  const _FullMascotPainter({
    required this.mascotId,
    this.accessoryName,
  });

  final String mascotId;
  final String? accessoryName;

  @override
  void paint(Canvas canvas, Size size) {
    paintFullMascot(canvas, size, mascotId, accessoryName: accessoryName);
  }

  @override
  bool shouldRepaint(covariant _FullMascotPainter oldDelegate) =>
      oldDelegate.mascotId != mascotId ||
      oldDelegate.accessoryName != accessoryName;
}
