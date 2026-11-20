import 'dart:async';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/app/auth_screen.dart';
import 'screens/app/main_app_shell.dart';
import 'screens/app/onboarding_screen.dart';
import 'screens/app/setup_wizard_screen.dart';
import 'screens/app/splash_screen.dart';
import 'state/aqua_ui_controller.dart';

const SystemUiOverlayStyle _kAquaEdgeToEdgeOverlay = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_kAquaEdgeToEdgeOverlay);
  unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));
  runApp(const AquaCareApp());
}

/// Root Flutter application implementing the full AquaCare mobile app experience.
class AquaCareApp extends StatefulWidget {
  const AquaCareApp({
    super.key,
    this.initialStage = AppFlowStage.splash,
    this.enablePersistence = true,
  });

  final AppFlowStage initialStage;
  final bool enablePersistence;

  @override
  State<AquaCareApp> createState() => _AquaCareAppState();
}

class _AquaCareAppState extends State<AquaCareApp> {
  late final AquaUiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AquaUiController(
      initialStage: widget.initialStage,
      enablePersistence: widget.enablePersistence,
    );
    unawaited(
      _controller.initialize(
        autoRedirectAuthenticated: widget.initialStage == AppFlowStage.splash,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStage() {
    switch (_controller.stage) {
      case AppFlowStage.splash:
        return SplashScreen(
          key: const ValueKey(AppFlowStage.splash),
          controller: _controller,
        );
      case AppFlowStage.onboarding:
        return OnboardingScreen(
          key: const ValueKey(AppFlowStage.onboarding),
          controller: _controller,
        );
      case AppFlowStage.auth:
        return AuthScreen(
          key: const ValueKey(AppFlowStage.auth),
          controller: _controller,
        );
      case AppFlowStage.setup:
        return SetupWizardScreen(
          key: const ValueKey(AppFlowStage.setup),
          controller: _controller,
        );
      case AppFlowStage.main:
        return MainAppShell(
          key: const ValueKey(AppFlowStage.main),
          controller: _controller,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaCare – Nước sạch & Sức khỏe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final clampedScaler = mq.textScaler.clamp(
          minScaleFactor: 0.90,
          maxScaleFactor: 1.12,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _kAquaEdgeToEdgeOverlay,
          child: MediaQuery(
            data: mq.copyWith(textScaler: clampedScaler),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final child = AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (widget, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.97,
                          end: 1.0,
                        ).animate(animation),
                        child: widget,
                      ),
                    ),
                  );
                },
                child: _buildStage(),
              );
              if (constraints.maxWidth < 600) {
                return child;
              }
              return ColoredBox(
                color: AppColors.cyanTile,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Material(
                      elevation: 14,
                      shadowColor: const Color(0x1F0F1F2C),
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(32),
                      color: AppColors.iceCanvas,
                      child: child,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
