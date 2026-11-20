import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';

/// Waterllama-inspired animated splash screen with floating ice backdrop,
/// 54-dot concentric spinner & bobbing Bé Giọt Nước mascot.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _autoTimer;
  double _scale = 0.86;
  late final AnimationController _bobController;
  bool _bobInitialized = false;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    Future<void>.microtask(() {
      if (mounted) setState(() => _scale = 1.0);
    });
    _autoTimer = Timer(const Duration(milliseconds: 1600), _proceed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bobInitialized) {
      _bobInitialized = true;
      if (AquaMotion.allowInfinite(context)) {
        _bobController.repeat();
      } else {
        _bobController.value = 0.25;
      }
    }
  }

  void _proceed() {
    _autoTimer?.cancel();
    _autoTimer = null;
    if (mounted) {
      widget.controller.completeSplash();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _autoTimer = null;
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AquaFloatingIceBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0.0, constraints.maxHeight - 48),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AquaConcentricDotsSpinner(
                            size: 226,
                            lightPalette: true,
                            child: AnimatedScale(
                              scale: _scale,
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOutBack,
                              child: AnimatedBuilder(
                                animation: _bobController,
                                builder: (_, child) {
                                  final dy = math.sin(
                                          _bobController.value * 2 * math.pi) *
                                      5.0;
                                  return Transform.translate(
                                    offset: Offset(0, dy),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: AppColors.pureWhite,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.navyInk
                                            .withValues(alpha: 0.14),
                                        blurRadius: 22,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: AquaMascotVectorArt(
                                      mascotId: 'giot_nuoc',
                                      size: 74,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          StaggeredEntrance(
                            index: 1,
                            child: Text(
                              'AquaCare',
                              style: AppTypography.displayHero(
                                      color: AppColors.pureWhite)
                                  .copyWith(fontSize: 36, letterSpacing: -0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          StaggeredEntrance(
                            index: 2,
                            child: Text(
                              'Nước sạch & sức khỏe mỗi ngày • Chuẩn SDG 6',
                              textAlign: TextAlign.center,
                              style: AppTypography.cardBody(
                                color:
                                    AppColors.pureWhite.withValues(alpha: 0.92),
                              ).copyWith(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.pureWhite.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '💧 Uống đủ nước • Nước sạch & Vệ sinh • Yêu hành tinh xanh',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: StaggeredEntrance(
                          index: 3,
                          child: BouncyPressable(
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.navyInk,
                                  foregroundColor: AppColors.pureWhite,
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                                onPressed: _proceed,
                                child: Text(
                                  'Bắt đầu ngay',
                                  style: AppTypography.pillCta(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
