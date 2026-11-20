import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Shared motion helpers and test-safe animation primitives for AquaCare.
class AquaMotion {
  const AquaMotion._();

  /// Returns true when running inside automated Flutter widget/unit tests.
  static bool get isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// Returns false under Flutter automated widget tests or when OS "Reduce Motion" is enabled.
  static bool allowInfinite(BuildContext context) {
    if (isTestEnvironment) return false;
    return !MediaQuery.disableAnimationsOf(context);
  }
}

/// Tactile spring-like press feedback transparent to inner buttons and InkWells.
class BouncyPressable extends StatefulWidget {
  const BouncyPressable({
    super.key,
    required this.child,
    this.pressedScale = 0.94,
    this.enableHaptic = true,
  });

  final Widget child;
  final double pressedScale;
  final bool enableHaptic;

  @override
  State<BouncyPressable> createState() => _BouncyPressableState();
}

class _BouncyPressableState extends State<BouncyPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value && widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Staggered upward slide + fade entrance for cards and list sections.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 360),
  });

  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration duration;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    final clampedIndex = widget.index.clamp(0, 6);
    final delayMs = widget.delayStep.inMilliseconds * clampedIndex;
    final totalMs = widget.duration.inMilliseconds + delayMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    final start = delayMs / totalMs;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    _opacity = curve;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

/// Smoothly interpolates integer counters (ml, %, stars, ppm) on value change.
class AnimatedIntText extends StatelessWidget {
  const AnimatedIntText({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final int value;
  final String Function(int value) formatter;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: value, end: value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, animatedValue, _) {
        return Text(
          formatter(animatedValue),
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: style,
        );
      },
    );
  }
}

/// Renders an upward floating reward burst badge (+250 ml 💧 / +10 ★ ✨) on trigger.
class FloatingRewardHost extends StatefulWidget {
  const FloatingRewardHost({
    super.key,
    required this.triggerCount,
    required this.rewardText,
    required this.child,
    this.backgroundColor = AppColors.deepSky,
    this.textColor = AppColors.pureWhite,
  });

  final int triggerCount;
  final String rewardText;
  final Widget child;
  final Color backgroundColor;
  final Color textColor;

  @override
  State<FloatingRewardHost> createState() => _FloatingRewardHostState();
}

class _FloatingRewardHostState extends State<FloatingRewardHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void didUpdateWidget(covariant FloatingRewardHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerCount > oldWidget.triggerCount) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned(
          top: 10,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                final t = _controller.value;
                if (t == 0.0 || t == 1.0) return const SizedBox.shrink();
                final opacity = t < 0.2
                    ? (t / 0.2)
                    : (t > 0.68 ? ((1.0 - t) / 0.32).clamp(0.0, 1.0) : 1.0);
                final scale = t < 0.25 ? (0.7 + 1.4 * t) : 1.05;
                final dy = -52.0 * Curves.easeOutCubic.transform(t);
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.backgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x260B2545),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.rewardText,
                          style: TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: widget.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Smooth slide + fade page route for pushed sub-screens.
class AquaPageRoute<T> extends PageRouteBuilder<T> {
  AquaPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Test-safe gentle breathing scale/glow wrapper for active indicators & icons.
class AquaPulseHalo extends StatefulWidget {
  const AquaPulseHalo({
    super.key,
    required this.child,
    this.enabled = true,
    this.maxScale = 1.07,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final bool enabled;
  final double maxScale;
  final Duration duration;

  @override
  State<AquaPulseHalo> createState() => _AquaPulseHaloState();
}

class _AquaPulseHaloState extends State<AquaPulseHalo>
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
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AquaPulseHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.enabled && AquaMotion.allowInfinite(context)) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final s = 1.0 +
            (widget.maxScale - 1.0) *
                Curves.easeInOut.transform(_controller.value);
        return Transform.scale(scale: s, child: child);
      },
      child: widget.child,
    );
  }
}

/// Unified cross-fade + vertical micro-slide transition between step/sub-tab views.
class AquaSmoothSwitcher extends StatelessWidget {
  const AquaSmoothSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(anim),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

/// Smoothly animated rounded progress bar for hydration, caffeine, and filter health.
class AquaAnimatedProgressBar extends StatelessWidget {
  const AquaAnimatedProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.skyCyan,
    this.backgroundColor = AppColors.skySoftBg,
    this.height = 9,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: clamped, end: clamped),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (_, animated, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: animated,
            minHeight: height,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      },
    );
  }
}
