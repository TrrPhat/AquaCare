import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';

/// Standalone full-screen wrapper around [AquaHydrationPersonalizerFlow]
/// opened from Home, Household setup, or Profile Settings.
class AquaHydrationPersonalizerScreen extends StatelessWidget {
  const AquaHydrationPersonalizerScreen({
    super.key,
    required this.controller,
    this.initialStage = 1,
  });

  final AquaUiController controller;
  final int initialStage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      body: AquaHydrationPersonalizerFlow(
        controller: controller,
        initialStage: initialStage,
        onBack: () => Navigator.of(context).pop(),
        onCompleted: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                'Đã cập nhật mục tiêu cá nhân: ${controller.dailyGoalMl} ml/ngày ✓',
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 4-Stage interactive personalization sequence:
/// - Stage 0: Lời nhắc thông minh + Smart reminder permission / activation + rising wave wipe
/// - Stage 1: Tính mục tiêu uống nước của bạn (Giới tính, Cân nặng kg/lbs wheel, Hoạt động, Khí hậu)
/// - Stage 2: Lợi ích khi uống đủ nước vs mất nước
/// - Stage 3: Hoạt ảnh tính toán 3 thanh tiến trình đồng tâm
class AquaHydrationPersonalizerFlow extends StatefulWidget {
  const AquaHydrationPersonalizerFlow({
    super.key,
    required this.controller,
    this.initialStage = 0,
    this.completeButtonLabel = 'Bắt đầu hành trình AquaCare ✓',
    this.onBack,
    required this.onCompleted,
  });

  final AquaUiController controller;
  final int initialStage;
  final String completeButtonLabel;
  final VoidCallback? onBack;
  final VoidCallback onCompleted;

  @override
  State<AquaHydrationPersonalizerFlow> createState() =>
      _AquaHydrationPersonalizerFlowState();
}

class _AquaHydrationPersonalizerFlowState
    extends State<AquaHydrationPersonalizerFlow>
    with TickerProviderStateMixin {
  late int _stage;

  // Interactive hydration calculation state
  AquaGenderProfile? _selectedGender;
  late double _weightKg;
  late AquaWeightUnit _weightUnit;
  late AquaActivityLevel _selectedActivity;
  late AquaClimateLevel _selectedClimate;
  int? _customGoalOverride;
  bool _weightPicked = false;
  bool _hasUserAdjusted = false;
  double _goalBumpScale = 1.0;

  // Stage 0 animation controllers & notification cycler
  late final AnimationController _meadowWalkCtrl;
  late final AnimationController _waveWipeCtrl;
  Timer? _notifCycleTimer;
  int _notifIndex = 0;

  // Stage 2 benefits topic toggle (`0 = Toàn diện SDG 6`, `1 = Nước sạch & WASH`)
  int _benefitsTopicIndex = 0;

  // Stage 1 swimming mascot
  late final AnimationController _swimCtrl;

  // Shared ambient UI controller (sparkles, bell wiggle, dehydrated droop)
  late final AnimationController _ambientCtrl;

  // Stage 3 finite 3-bar calculation sequence & completion confetti
  late final AnimationController _calcCtrl;
  int _calcConfettiTrigger = 0;

  static const List<({String text, String time})> _reminderPreviews = [
    (text: 'Nước làm giảm căng thẳng', time: '14:46'),
    (text: 'Giữa ca rồi — nhấp 200ml nạp năng lượng!', time: '10:15'),
    (text: 'Còn 1 cốc. Bạn làm được!', time: '20:30'),
    (text: 'Rửa bình cá nhân & refill nước sạch nhé!', time: '09:30'),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _stage = widget.initialStage.clamp(0, 3);
    _selectedGender = c.genderProfile;
    _weightKg = c.bodyWeightKg.clamp(35.0, 140.0);
    _weightUnit = c.weightUnit;
    _selectedActivity = c.activityLevel;
    _selectedClimate = c.climateLevel;
    _weightPicked = c.genderProfile != null;
    _hasUserAdjusted = c.genderProfile != null;

    _meadowWalkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8600),
    );
    _waveWipeCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _stage = 1);
            _waveWipeCtrl.reset();
          }
        });

    _swimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6800),
    );

    _ambientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _calcCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _calcConfettiTrigger++);
          }
        });

    if (!AquaMotion.isTestEnvironment) {
      _notifCycleTimer = Timer.periodic(const Duration(milliseconds: 2400), (
        _,
      ) {
        if (!mounted || _stage != 0) return;
        setState(() {
          _notifIndex = (_notifIndex + 1) % _reminderPreviews.length;
        });
      });
    }

    if (_stage == 3) {
      _calcCtrl.forward(from: 0.0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allowInfinite = AquaMotion.allowInfinite(context);
    if (allowInfinite) {
      if (!_meadowWalkCtrl.isAnimating) _meadowWalkCtrl.repeat();
      if (!_swimCtrl.isAnimating) _swimCtrl.repeat();
      if (!_ambientCtrl.isAnimating) _ambientCtrl.repeat();
    } else {
      if (_meadowWalkCtrl.isAnimating) _meadowWalkCtrl.stop();
      if (_swimCtrl.isAnimating) _swimCtrl.stop();
      if (_ambientCtrl.isAnimating) _ambientCtrl.stop();
      _meadowWalkCtrl.value = 0.22;
      _swimCtrl.value = 0.42;
      _ambientCtrl.value = 0.3;
    }
  }

  @override
  void dispose() {
    _notifCycleTimer?.cancel();
    _notifCycleTimer = null;
    _meadowWalkCtrl.dispose();
    _waveWipeCtrl.dispose();
    _swimCtrl.dispose();
    _ambientCtrl.dispose();
    _calcCtrl.dispose();
    super.dispose();
  }

  int get _previewGoalMl {
    if (_customGoalOverride != null) return _customGoalOverride!;
    if (!_hasUserAdjusted) return 2000;
    return AquaHydrationCalculator.calculateRecommendedMl(
      bodyWeightKg: _weightKg,
      gender: _selectedGender ?? AquaGenderProfile.preferNotToSay,
      activity: _selectedActivity,
      climate: _selectedClimate,
    );
  }

  AquaHydrationBreakdown get _previewBreakdown {
    return AquaHydrationCalculator.breakdown(
      bodyWeightKg: _weightKg,
      gender: _selectedGender ?? AquaGenderProfile.preferNotToSay,
      activity: _selectedActivity,
      climate: _selectedClimate,
    );
  }

  String get _formattedWeight {
    if (_weightUnit == AquaWeightUnit.lbs) {
      final lbs = (_weightKg * 2.20462).round();
      return '$lbs lbs';
    }
    return '${_weightKg.round()} kg';
  }

  void _triggerGoalChangePulse() {
    setState(() => _goalBumpScale = 1.07);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        setState(() => _goalBumpScale = 1.0);
      }
    });
  }

  void _goToStage1WithWave() {
    unawaited(widget.controller.enableSmartReminders());
    _waveWipeCtrl.forward(from: 0.0);
  }

  void _goToStage2() {
    setState(() => _stage = 2);
  }

  void _commitAndRunCalculation() {
    widget.controller.updateHydrationProfile(
      gender:
          _selectedGender ??
          widget.controller.genderProfile ??
          AquaGenderProfile.preferNotToSay,
      bodyWeightKg: _weightKg,
      activity: _selectedActivity,
      climate: _selectedClimate,
      weightUnit: _weightUnit,
      customGoalMl: _customGoalOverride,
      recalculateGoal: _customGoalOverride == null,
    );
    setState(() {
      _calcConfettiTrigger = 0;
      _stage = 3;
    });
    _calcCtrl.forward(from: 0.0);
  }

  void _handleBack() {
    if (_stage > widget.initialStage) {
      setState(() => _stage--);
      return;
    }
    widget.onBack?.call();
  }

  // --------------------------------------------------------------------------
  // Calculator Modals (Gender, Weight Wheel, Activity, Climate, Info, Custom)
  // --------------------------------------------------------------------------

  void _showFormulaBreakdownSheet() {
    final bd = _previewBreakdown;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.pillGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cách AquaCare tính mục tiêu nước',
                style: AppTypography.cardTitle(),
              ),
              const SizedBox(height: 6),
              Text(
                'Tính theo khuyến nghị khoa học về cân nặng, giới tính, vận động và khí hậu:',
                style: AppTypography.cardBody(),
              ),
              const SizedBox(height: 14),
              _BreakdownRow(
                label:
                    'Cơ bản (${_weightKg.round()} kg × ${(_selectedGender ?? AquaGenderProfile.preferNotToSay).mlPerKg.round()} ml)',
                value: '${bd.baseMl} ml',
              ),
              if (bd.genderExtraMl > 0)
                _BreakdownRow(
                  label: 'Bổ sung (${_selectedGender!.label})',
                  value: '+${bd.genderExtraMl} ml',
                ),
              _BreakdownRow(
                label: 'Mức độ (${_selectedActivity.label})',
                value: '+${bd.activityExtraMl} ml',
              ),
              _BreakdownRow(
                label: 'Khí hậu (${_selectedClimate.label})',
                value: '+${bd.climateExtraMl} ml',
              ),
              const Divider(height: 18),
              _BreakdownRow(
                label: 'Tổng mục tiêu đề xuất',
                value: '${bd.totalMl} ml / ngày',
                highlight: true,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openGenderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Giới tính',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.navyInk,
                          ),
                        ),
                      ),
                      _SheetCloseButton(onTap: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...AquaGenderProfile.values.map((gender) {
                    final selected = _selectedGender == gender;
                    final icon = switch (gender) {
                      AquaGenderProfile.male => Icons.face_6_rounded,
                      AquaGenderProfile.female => Icons.face_3_rounded,
                      AquaGenderProfile.pregnant =>
                        Icons.pregnant_woman_rounded,
                      AquaGenderProfile.breastfeeding =>
                        Icons.child_friendly_rounded,
                      AquaGenderProfile.preferNotToSay =>
                        Icons.sentiment_satisfied_rounded,
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? AppColors.cyanTile
                            : AppColors.iceCanvas,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedGender = gender;
                              _hasUserAdjusted = true;
                              _customGoalOverride = null;
                            });
                            Navigator.of(ctx).pop();
                            _triggerGoalChangePulse();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    gender.label,
                                    style: AppTypography.rowTitle(
                                      color: selected
                                          ? AppColors.oceanBlue
                                          : AppColors.navyInk,
                                    ),
                                  ),
                                ),
                                Icon(
                                  icon,
                                  color: selected
                                      ? AppColors.cyanVivid
                                      : AppColors.slateBody,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'Thông tin cá nhân của bạn chỉ được lưu cục bộ trên thiết bị, không thu thập hay chia sẻ.',
                    textAlign: TextAlign.center,
                    style: AppTypography.cardBody().copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openWeightSheet() {
    AquaWeightUnit tempUnit = _weightUnit;
    int tempKg = _weightKg.round().clamp(35, 140);
    int tempLbs = (tempKg * 2.20462).round().clamp(77, 308);
    FixedExtentScrollController? valueCtrl = FixedExtentScrollController(
      initialItem: tempUnit == AquaWeightUnit.kg ? tempKg - 35 : tempLbs - 77,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final itemCount = tempUnit == AquaWeightUnit.kg
                ? (140 - 35 + 1)
                : (308 - 77 + 1);
            final currentIdx = tempUnit == AquaWeightUnit.kg
                ? (tempKg - 35)
                : (tempLbs - 77);

            void switchUnit(AquaWeightUnit nextUnit) {
              if (tempUnit == nextUnit) return;
              setSheetState(() {
                tempUnit = nextUnit;
                final newIdx = tempUnit == AquaWeightUnit.kg
                    ? ((tempLbs / 2.20462).round().clamp(35, 140) - 35)
                    : ((tempKg * 2.20462).round().clamp(77, 308) - 77);
                if (tempUnit == AquaWeightUnit.kg) {
                  tempKg = newIdx + 35;
                } else {
                  tempLbs = newIdx + 77;
                }
                valueCtrl?.jumpToItem(newIdx);
              });
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 34),
                        const Expanded(
                          child: Text(
                            'Cân nặng',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.displayFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.navyInk,
                            ),
                          ),
                        ),
                        _SheetCloseButton(onTap: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppColors.iceCanvas,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                child: ListWheelScrollView.useDelegate(
                                  controller: valueCtrl,
                                  itemExtent: 42,
                                  diameterRatio: 1.5,
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (idx) {
                                    setSheetState(() {
                                      if (tempUnit == AquaWeightUnit.kg) {
                                        tempKg = 35 + idx;
                                        tempLbs = (tempKg * 2.20462)
                                            .round()
                                            .clamp(77, 308);
                                      } else {
                                        tempLbs = 77 + idx;
                                        tempKg = (tempLbs / 2.20462)
                                            .round()
                                            .clamp(35, 140);
                                      }
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: itemCount,
                                    builder: (_, idx) {
                                      final val = tempUnit == AquaWeightUnit.kg
                                          ? (35 + idx)
                                          : (77 + idx);
                                      final isSel = idx == currentIdx;
                                      return Center(
                                        child: Text(
                                          '$val',
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.displayFont,
                                            fontWeight: isSel
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: isSel ? 22 : 17,
                                            color: isSel
                                                ? AppColors.navyInk
                                                : AppColors.mutedGrey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _UnitTogglePill(
                                    label: 'kg',
                                    selected: tempUnit == AquaWeightUnit.kg,
                                    onTap: () => switchUnit(AquaWeightUnit.kg),
                                  ),
                                  const SizedBox(height: 6),
                                  _UnitTogglePill(
                                    label: 'lbs',
                                    selected: tempUnit == AquaWeightUnit.lbs,
                                    onTap: () => switchUnit(AquaWeightUnit.lbs),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thông tin cá nhân của bạn chỉ lưu trên thiết bị, không thu thập hay chia sẻ.',
                      textAlign: TextAlign.center,
                      style: AppTypography.cardBody().copyWith(fontSize: 11.5),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 180,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyInk,
                          foregroundColor: AppColors.pureWhite,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          final resolvedKg = tempUnit == AquaWeightUnit.kg
                              ? tempKg.toDouble()
                              : (tempLbs / 2.20462);
                          setState(() {
                            _weightKg = resolvedKg.clamp(35.0, 140.0);
                            _weightUnit = tempUnit;
                            _weightPicked = true;
                            _hasUserAdjusted = true;
                            _customGoalOverride = null;
                          });
                          Navigator.of(ctx).pop();
                          _triggerGoalChangePulse();
                        },
                        child: Text('Xong', style: AppTypography.pillCta()),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      valueCtrl?.dispose();
      valueCtrl = null;
    });
  }

  void _openActivitySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mức độ hoạt động',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.navyInk,
                          ),
                        ),
                      ),
                      _SheetCloseButton(onTap: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...AquaActivityLevel.values.map((level) {
                    final selected = _selectedActivity == level;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? AppColors.cyanTile
                            : AppColors.iceCanvas,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedActivity = level;
                              _hasUserAdjusted = true;
                              _customGoalOverride = null;
                            });
                            Navigator.of(ctx).pop();
                            _triggerGoalChangePulse();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.label,
                                        style: AppTypography.rowTitle(
                                          color: selected
                                              ? AppColors.oceanBlue
                                              : AppColors.navyInk,
                                        ),
                                      ),
                                      Text(
                                        level.subtitle,
                                        style: AppTypography.cardBody(),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    level.extraMl == 0
                                        ? 'Cơ bản'
                                        : '+${level.extraMl} ml',
                                    style: AppTypography.metricLabel(
                                      AppColors.oceanBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openClimateSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Điều kiện khí hậu',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.navyInk,
                          ),
                        ),
                      ),
                      _SheetCloseButton(onTap: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...AquaClimateLevel.values.map((climate) {
                    final selected = _selectedClimate == climate;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? AppColors.mintTile
                            : AppColors.iceCanvas,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedClimate = climate;
                              _hasUserAdjusted = true;
                              _customGoalOverride = null;
                            });
                            Navigator.of(ctx).pop();
                            _triggerGoalChangePulse();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        climate.label,
                                        style: AppTypography.rowTitle(
                                          color: selected
                                              ? AppColors.emerald
                                              : AppColors.navyInk,
                                        ),
                                      ),
                                      Text(
                                        climate.subtitle,
                                        style: AppTypography.cardBody(),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    climate.extraMl == 0
                                        ? 'Cơ bản'
                                        : '+${climate.extraMl} ml',
                                    style: AppTypography.metricLabel(
                                      AppColors.emerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCustomGoalSheet() {
    double tempMl = (_customGoalOverride ?? _previewGoalMl).toDouble().clamp(
      1200,
      4500,
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mục tiêu tùy chỉnh',
                            style: TextStyle(
                              fontFamily: AppTypography.displayFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.navyInk,
                            ),
                          ),
                        ),
                        _SheetCloseButton(onTap: () => Navigator.of(ctx).pop()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${tempMl.round()} ml / ngày',
                      style: AppTypography.displayHero(
                        color: AppColors.cyanVivid,
                      ),
                    ),
                    Slider(
                      value: tempMl,
                      min: 1200,
                      max: 4500,
                      divisions: 66,
                      activeColor: AppColors.cyanVivid,
                      onChanged: (v) => setSheetState(() {
                        tempMl = ((v / 50).round() * 50).toDouble();
                      }),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyInk,
                          foregroundColor: AppColors.pureWhite,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            _customGoalOverride = tempMl.round();
                            _hasUserAdjusted = true;
                          });
                          Navigator.of(ctx).pop();
                          _triggerGoalChangePulse();
                        },
                        child: Text(
                          'Lưu mục tiêu',
                          style: AppTypography.pillCta(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // UI Stages
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final stageBody = AquaSmoothSwitcher(
      child: KeyedSubtree(
        key: ValueKey<int>(_stage),
        child: switch (_stage) {
          0 => _buildSmartRemindersStage(),
          1 => _buildGoalCalculatorStage(),
          2 => _buildBenefitsComparisonStage(),
          _ => _buildCalculatingStage(),
        },
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: stageBody),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _waveWipeCtrl,
              builder: (_, _) {
                if (_waveWipeCtrl.isDismissed) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _CyanWaveWipePainter(progress: _waveWipeCtrl.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartRemindersStage() {
    final c = widget.controller;
    final currentReminder = _reminderPreviews[_notifIndex];
    final nextReminder =
        _reminderPreviews[(_notifIndex + 1) % _reminderPreviews.length];

    return AquaAmbientOrbsBackdrop(
      gradientColors: const [Color(0xFFEFFAFF), AppColors.pureWhite],
      orbColors: const [
        Color(0x285DCCFC),
        Color(0x208E9AFE),
        Color(0x2252D681),
      ],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Column(
            children: [
              Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: _handleBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cyanVivid,
                      foregroundColor: AppColors.pureWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _goToStage1WithWave,
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sceneHeight = (constraints.maxHeight * 0.56).clamp(
                      320.0,
                      460.0,
                    );
                    final sceneWidth = constraints.maxWidth;
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                StaggeredEntrance(
                                  index: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyanTile,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.cyanVivid.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _ambientCtrl,
                                          builder: (_, child) {
                                            final angle =
                                                math.sin(
                                                  _ambientCtrl.value *
                                                      4 *
                                                      math.pi,
                                                ) *
                                                0.16;
                                            return Transform.rotate(
                                              angle: angle,
                                              child: child,
                                            );
                                          },
                                          child: const Icon(
                                            Icons.notifications_active_rounded,
                                            size: 14,
                                            color: AppColors.oceanBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Nhắc nhở thông minh SDG 6',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.metricLabel(
                                              AppColors.oceanBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StaggeredEntrance(
                                  index: 1,
                                  child: Text(
                                    'Lời nhắc thông minh',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.displayHero().copyWith(
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StaggeredEntrance(
                                  index: 1,
                                  child: Text(
                                    'Những thông báo vì sức khỏe khi bạn quên uống nước',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.cardBody().copyWith(
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Video-matched tall speech-bubble card with 2-act meadow trot + close-up peek
                            StaggeredEntrance(
                              index: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: PhysicalShape(
                                  clipper: const _SpeechBubbleCardClipper(),
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 10,
                                  shadowColor: const Color(0x3300BBE4),
                                  color: const Color(0xFFCDEFFD),
                                  child: Container(
                                    height: sceneHeight,
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFCDEFFD),
                                          Color(0xFFECF9FF),
                                        ],
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _meadowWalkCtrl,
                                            builder: (_, _) {
                                              return CustomPaint(
                                                painter: _ReminderMeadowPainter(
                                                  progress:
                                                      _meadowWalkCtrl.value,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // 2-Act mascot animation layer (rendered behind notification banner on Act 2)
                                        Positioned.fill(
                                          child: AnimatedBuilder(
                                            animation: _meadowWalkCtrl,
                                            builder: (_, _) {
                                              final t = _meadowWalkCtrl.value;
                                              if (t < 0.50) {
                                                // Act 1: full left-to-right joyful meadow trot
                                                final p = t / 0.50;
                                                final dx =
                                                    (-sceneWidth * 0.42) +
                                                    p * (sceneWidth * 1.04);
                                                final hop = math
                                                    .sin(p * 10 * math.pi)
                                                    .abs();
                                                final dy = -hop * 14.0;
                                                final tilt =
                                                    math.cos(p * 10 * math.pi) *
                                                    0.08;
                                                final squashX =
                                                    1.0 + (1.0 - hop) * 0.04;
                                                final squashY =
                                                    1.0 - (1.0 - hop) * 0.03;
                                                final shadowScale =
                                                    (1.0 - hop * 0.32).clamp(
                                                      0.62,
                                                      1.0,
                                                    );
                                                return Align(
                                                  alignment:
                                                      Alignment.bottomCenter,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 30,
                                                        ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                          height: 118,
                                                          width: 160,
                                                          child: Stack(
                                                            alignment: Alignment
                                                                .center,
                                                            children: [
                                                              CustomPaint(
                                                                size:
                                                                    const Size(
                                                                      160,
                                                                      118,
                                                                    ),
                                                                painter:
                                                                    _HydratedSparklesPainter(
                                                                      t: p,
                                                                    ),
                                                              ),
                                                              Transform.translate(
                                                                offset: Offset(
                                                                  dx,
                                                                  dy,
                                                                ),
                                                                child: Transform.rotate(
                                                                  angle: tilt,
                                                                  child: Transform.scale(
                                                                    scaleX:
                                                                        squashX,
                                                                    scaleY:
                                                                        squashY,
                                                                    child: AquaMascotVectorArt(
                                                                      mascotId:
                                                                          c.selectedMascotId,
                                                                      size: 102,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Transform.translate(
                                                          offset: Offset(dx, 0),
                                                          child: Transform.scale(
                                                            scaleX: shadowScale,
                                                            child: Container(
                                                              width: 68,
                                                              height: 10,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFF1D6E2E,
                                                                    ).withValues(
                                                                      alpha:
                                                                          0.22,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      999,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }

                                              // Act 2: Giant playful mascot peeking in from the right edge
                                              final p = (t - 0.50) / 0.50;
                                              final double enterExit;
                                              if (p < 0.18) {
                                                enterExit = Curves.easeOutBack
                                                    .transform(
                                                      (p / 0.18).clamp(
                                                        0.0,
                                                        1.0,
                                                      ),
                                                    );
                                              } else if (p > 0.82) {
                                                enterExit =
                                                    1.0 -
                                                    Curves.easeInCubic
                                                        .transform(
                                                          ((p - 0.82) / 0.18)
                                                              .clamp(0.0, 1.0),
                                                        );
                                              } else {
                                                enterExit = 1.0;
                                              }
                                              final peekDx =
                                                  (1.0 - enterExit) * 190.0;
                                              final nod =
                                                  math.sin(p * 4 * math.pi) *
                                                  0.06;
                                              final bobY =
                                                  math.cos(p * 4 * math.pi) *
                                                  4.0;
                                              return Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    26 + peekDx,
                                                    bobY - 22,
                                                  ),
                                                  child: Transform.rotate(
                                                    angle: -0.14 + nod,
                                                    child: AquaMascotVectorArt(
                                                      mascotId:
                                                          c.selectedMascotId,
                                                      size: 184,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Stacked depth background notification preview
                                        Positioned(
                                          top: 34,
                                          left: 26,
                                          right: 26,
                                          child: Transform.scale(
                                            scale: 0.94,
                                            child: Opacity(
                                              opacity: 0.65,
                                              child: Container(
                                                height: 54,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                                alignment: Alignment.centerLeft,
                                                decoration: BoxDecoration(
                                                  color: AppColors.pureWhite,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Text(
                                                  nextReminder.text,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTypography.cardBody(
                                                    color: AppColors.mutedGrey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Foreground interactive notification banner
                                        Positioned(
                                          top: 18,
                                          left: 16,
                                          right: 16,
                                          child: GestureDetector(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _notifIndex =
                                                    (_notifIndex + 1) %
                                                    _reminderPreviews.length;
                                              });
                                            },
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 380,
                                              ),
                                              switchInCurve: Curves.easeOutBack,
                                              switchOutCurve: Curves.easeIn,
                                              transitionBuilder: (child, anim) {
                                                return FadeTransition(
                                                  opacity: anim,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(
                                                        0,
                                                        -0.18,
                                                      ),
                                                      end: Offset.zero,
                                                    ).animate(anim),
                                                    child: ScaleTransition(
                                                      scale: Tween<double>(
                                                        begin: 0.96,
                                                        end: 1.0,
                                                      ).animate(anim),
                                                      child: child,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                key: ValueKey<int>(_notifIndex),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.pureWhite
                                                      .withValues(alpha: 0.96),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: AppColors.cyanTile,
                                                    width: 1.2,
                                                  ),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x1A0284C7),
                                                      blurRadius: 16,
                                                      offset: Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .cyanTile,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: const Center(
                                                            child:
                                                                AquaMascotVectorArt(
                                                                  mascotId: 'giot_nuoc',
                                                                  size: 26,
                                                                ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          right: -3,
                                                          top: -3,
                                                          child: Container(
                                                            width: 12,
                                                            height: 12,
                                                            decoration: BoxDecoration(
                                                              color: AppColors
                                                                  .cyanVivid,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: AppColors
                                                                    .pureWhite,
                                                                width: 1.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'AquaCare',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                AppTypography.metricLabel(
                                                                  AppColors
                                                                      .oceanBlue,
                                                                ),
                                                          ),
                                                          Text(
                                                            currentReminder
                                                                .text,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                AppTypography.rowTitle(),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.iceCanvas,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        currentReminder.time,
                                                        style:
                                                            AppTypography.metricLabel(
                                                              AppColors
                                                                  .slateBody,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Compact single-row pill strip preserving tall speech-bubble dominance
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 2,
                                      child: _ReminderFeatureChip(
                                        icon: Icons.schedule_rounded,
                                        color: AppColors.cyanVivid,
                                        bgColor: AppColors.cyanTile,
                                        title: 'Đúng lịch',
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 3,
                                      child: _ReminderFeatureChip(
                                        icon: Icons.auto_awesome_rounded,
                                        color: AppColors.periwinkle,
                                        bgColor: AppColors.lavenderCard,
                                        title: 'Tự điều chỉnh',
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: StaggeredEntrance(
                                      index: 4,
                                      child: _ReminderFeatureChip(
                                        icon: Icons.eco_rounded,
                                        color: AppColors.emerald,
                                        bgColor: AppColors.mintTile,
                                        title: 'Sống xanh',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              BouncyPressable(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: AquaShimmerOverlay(
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x330F1F2C),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyInk,
                            foregroundColor: AppColors.pureWhite,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: _goToStage1WithWave,
                          icon: const Icon(
                            Icons.notifications_active_rounded,
                            size: 19,
                          ),
                          label: Text(
                            'Nhắc tôi uống nước',
                            style: AppTypography.pillCta(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCalculatorStage() {
    final topActionLabel = _hasUserAdjusted ? 'Xong' : 'Bỏ qua';
    final bd = _previewBreakdown;

    return AquaFloatingIceBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: AppColors.pureWhite.withValues(alpha: 0.22),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: 'Quay lại',
                      onPressed: _handleBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: AppColors.pureWhite,
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _hasUserAdjusted
                          ? AppColors.navyInk
                          : AppColors.pureWhite.withValues(alpha: 0.24),
                      foregroundColor: AppColors.pureWhite,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                    ),
                    onPressed: _goToStage2,
                    child: Text(
                      topActionLabel,
                      style: const TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Gently swimming whale mascot with dynamic flip, banking tilt & trailing bubbles
                            SizedBox(
                              height: 62,
                              width: 220,
                              child: AnimatedBuilder(
                                animation: _swimCtrl,
                                builder: (_, child) {
                                  final t = _swimCtrl.value;
                                  final dx = math.sin(t * 2 * math.pi) * 44;
                                  final dy = math.cos(t * 4 * math.pi) * 4;
                                  final velX = math.cos(t * 2 * math.pi);
                                  final facing = velX >= 0 ? -1.0 : 1.0;
                                  final bank = -velX * 0.08;
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(220, 62),
                                        painter: _SwimmingBubblesPainter(
                                          t: t,
                                          whaleDx: dx,
                                          facing: facing,
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: Offset(dx, dy),
                                        child: Transform.rotate(
                                          angle: bank,
                                          child: Transform.flip(
                                            flipX: facing < 0,
                                            child: child,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                child: const AquaMascotVectorArt(
                                  mascotId: 'ca_voi_xanh',
                                  size: 54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: _showFormulaBreakdownSheet,
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _hasUserAdjusted
                                          ? 'Mục tiêu khuyến nghị'
                                          : 'Mục tiêu phổ biến',
                                      style: const TextStyle(
                                        fontFamily: AppTypography.bodyFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: AppColors.pureWhite,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: AppColors.pureWhite,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AquaWaterHalo(
                              color: AppColors.pureWhite,
                              size: 74,
                              maxScale: 1.45,
                              child: AnimatedScale(
                                scale: _goalBumpScale,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutBack,
                                child: AnimatedIntText(
                                  value: _previewGoalMl,
                                  formatter: (v) => '${v}ml',
                                  style: AppTypography.displayHero(
                                    color: AppColors.pureWhite,
                                  ).copyWith(fontSize: 44, height: 1.05),
                                ),
                              ),
                            ),
                            Text(
                              _hasUserAdjusted
                                  ? 'Mục tiêu uống nước của bạn'
                                  : 'Tính mục tiêu của bạn',
                              style: const TextStyle(
                                fontFamily: AppTypography.displayFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.pureWhite,
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              child: _hasUserAdjusted
                                  ? GestureDetector(
                                      onTap: _showFormulaBreakdownSheet,
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _FormulaMiniChip(
                                              text: 'Cơ bản ${bd.baseMl}ml',
                                            ),
                                            if (bd.activityExtraMl > 0)
                                              _FormulaMiniChip(
                                                text:
                                                    'Vận động +${bd.activityExtraMl}ml',
                                              ),
                                            if (bd.climateExtraMl > 0)
                                              _FormulaMiniChip(
                                                text:
                                                    'Khí hậu +${bd.climateExtraMl}ml',
                                              ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 16),
                            StaggeredEntrance(
                              index: 0,
                              child: _CalculatorSelectorPill(
                                label: _selectedGender?.label ?? 'Giới tính',
                                filled: _selectedGender != null,
                                icon: Icons.face_rounded,
                                onTap: _openGenderSheet,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StaggeredEntrance(
                              index: 1,
                              child: _CalculatorSelectorPill(
                                label: _weightPicked
                                    ? _formattedWeight
                                    : 'Cân nặng',
                                filled: _weightPicked,
                                icon: Icons.monitor_weight_outlined,
                                onTap: _openWeightSheet,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StaggeredEntrance(
                              index: 2,
                              child: _CalculatorSelectorPill(
                                label: _selectedActivity.label,
                                filled: true,
                                icon: Icons.directions_run_rounded,
                                onTap: _openActivitySheet,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StaggeredEntrance(
                              index: 3,
                              child: _CalculatorSelectorPill(
                                label: _selectedClimate.label,
                                filled: true,
                                icon: Icons.wb_sunny_outlined,
                                onTap: _openClimateSheet,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _openCustomGoalSheet,
                              child: Text(
                                _customGoalOverride != null
                                    ? 'MỤC TIÊU TÙY CHỈNH: $_customGoalOverride ML'
                                    : 'MỤC TIÊU TÙY CHỈNH',
                                style: const TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.4,
                                  color: AppColors.pureWhite,
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
              const SizedBox(height: 8),
              BouncyPressable(
                child: AquaShimmerOverlay(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navyInk,
                        foregroundColor: AppColors.pureWhite,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: _goToStage2,
                      child: Text('Tiếp tục →', style: AppTypography.pillCta()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsComparisonStage() {
    final c = widget.controller;
    const mutedMatrix = ColorFilter.matrix(<double>[
      0.62, 0.28, 0.10, 0, 0, //
      0.18, 0.72, 0.10, 0, 0, //
      0.18, 0.28, 0.54, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
    final isOverallTopic = _benefitsTopicIndex == 0;
    final leftBadge = isOverallTopic ? 'Thiếu chuẩn SDG 6' : 'Rủi ro tiềm ẩn';
    final leftTitle = isOverallTopic
        ? 'Khi thiếu nước sạch\n& vệ sinh chưa chuẩn'
        : 'Khi bỏ qua an toàn\nnước & vệ sinh';
    final leftPoints = isOverallTopic
        ? const [
            'Thiếu nước khiến mệt mỏi, kém tập trung',
            'Bình cá nhân & vòi lọc dễ tích cặn, vi khuẩn',
            'Dùng nhiều chai nhựa 1 lần, lãng phí nước',
            'Quên rửa tay & vệ sinh lõi lọc định kỳ',
          ]
        : const [
            'Không rõ chỉ số TDS/pH nguồn nước sinh hoạt',
            'Lõi lọc quá hạn, bồn chứa lâu ngày không rửa',
            'Rò rỉ đường ống âm thầm tăng hóa đơn nước',
            'Khó tìm điểm tiếp nước sạch & WC công cộng',
          ];

    final rightBadge = isOverallTopic ? 'Chuẩn AquaCare' : 'An toàn toàn diện';
    final rightTitle = isOverallTopic
        ? 'Khi sống chuẩn\nAquaCare SDG 6'
        : 'Khi bảo vệ nguồn nước\ncùng AquaCare';
    final rightPoints = isOverallTopic
        ? const [
            'Uống đủ nước giúp tỉnh táo & sảng khoái',
            'An tâm nguồn nước chuẩn WHO/QCVN',
            'Thực hành WASH rửa tay, sạch bình, ngừa rò rỉ',
            'Dùng trạm Refill — giảm hàng chục chai nhựa',
          ]
        : const [
            'Cảnh báo TDS/pH chuẩn WHO & QCVN ngay tức thì',
            'Checklist WASH nhắc rửa bình, vòi & thay lọc',
            'Theo dõi hóa đơn m³ phát hiện rò rỉ sớm',
            'Bản đồ trạm Refill & nhà vệ sinh sạch gần bạn',
          ];

    return AquaAmbientOrbsBackdrop(
      gradientColors: const [Color(0xFFF3FAFF), AppColors.pureWhite],
      orbColors: const [
        Color(0x285DCCFC),
        Color(0x22EFE8FF),
        Color(0x2252D681),
      ],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: _handleBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.mintTile,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '✨ Chuẩn SDG 6 mỗi ngày',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.metricLabel(AppColors.emerald),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minCardsHeight = (constraints.maxHeight * 0.50).clamp(
                      300.0,
                      410.0,
                    );
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                StaggeredEntrance(
                                  index: 0,
                                  child: Text(
                                    'Cảm thấy tuyệt nhất\nmỗi ngày',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.displayHero().copyWith(
                                      fontSize: 25,
                                      height: 1.18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                StaggeredEntrance(
                                  index: 0,
                                  child: _BenefitsTopicToggle(
                                    selectedIndex: _benefitsTopicIndex,
                                    onSelect: (index) => setState(
                                      () => _benefitsTopicIndex = index,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeIn,
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_benefitsTopicIndex),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: minCardsHeight,
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          11,
                                                          13,
                                                          11,
                                                          11,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              Color(0xFFF6F2FF),
                                                              Color(0xFFECE4FF),
                                                            ],
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            24,
                                                          ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFDFD5FA,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 3,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: AppColors
                                                                    .pureWhite
                                                                    .withValues(
                                                                      alpha:
                                                                          0.78,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      999,
                                                                    ),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .warning_amber_rounded,
                                                                    size: 13,
                                                                    color: Color(
                                                                      0xFF7B6DA8,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Flexible(
                                                                    child: Text(
                                                                      leftBadge,
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: const TextStyle(
                                                                        fontFamily:
                                                                            AppTypography.bodyFont,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        fontSize:
                                                                            10,
                                                                        color: Color(
                                                                          0xFF6B5F96,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              leftTitle,
                                                              style:
                                                                  AppTypography.cardTitle(
                                                                    color: const Color(
                                                                      0xFF493E78,
                                                                    ),
                                                                  ).copyWith(
                                                                    fontSize:
                                                                        14,
                                                                    height:
                                                                        1.24,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            for (
                                                              int i = 0;
                                                              i <
                                                                  leftPoints
                                                                      .length;
                                                              i++
                                                            ) ...[
                                                              if (i > 0)
                                                                const SizedBox(
                                                                  height: 7,
                                                                ),
                                                              _BenefitPointRow(
                                                                positive: false,
                                                                text:
                                                                    leftPoints[i],
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 10,
                                                              ),
                                                          child: Center(
                                                            child: SizedBox(
                                                              width: 112,
                                                              height: 92,
                                                              child: AnimatedBuilder(
                                                                animation:
                                                                    _ambientCtrl,
                                                                builder: (_, child) {
                                                                  final t =
                                                                      _ambientCtrl
                                                                          .value;
                                                                  final sway =
                                                                      math.sin(
                                                                        t *
                                                                            2 *
                                                                            math.pi,
                                                                      );
                                                                  return Stack(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    children: [
                                                                      CustomPaint(
                                                                        size: const Size(
                                                                          112,
                                                                          92,
                                                                        ),
                                                                        painter:
                                                                            _DehydratedMoodOverlayPainter(
                                                                              t: t,
                                                                            ),
                                                                      ),
                                                                      Transform.translate(
                                                                        offset: Offset(
                                                                          0,
                                                                          2.5 +
                                                                              sway.abs() * 2.5,
                                                                        ),
                                                                        child: Transform.rotate(
                                                                          angle:
                                                                              sway *
                                                                              0.06,
                                                                          child:
                                                                              child,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                                child: Opacity(
                                                                  opacity: 0.72,
                                                                  child: ColorFiltered(
                                                                    colorFilter:
                                                                        mutedMatrix,
                                                                    child: AquaMascotVectorArt(
                                                                      mascotId:
                                                                          c.selectedMascotId,
                                                                      size: 80,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 12,
                                                      ),
                                                  child: AquaShimmerOverlay(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                    shimmerColor: const Color(
                                                      0x44FFFFFF,
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                            11,
                                                            13,
                                                            11,
                                                            11,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Color(
                                                                  0xFFE0F8FF,
                                                                ),
                                                                Color(
                                                                  0xFFE7FFF4,
                                                                ),
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFF8BE2FA,
                                                          ),
                                                          width: 1.4,
                                                        ),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: Color(
                                                              0x1E00BBE4,
                                                            ),
                                                            blurRadius: 18,
                                                            offset: Offset(
                                                              0,
                                                              8,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          3,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: AppColors
                                                                      .pureWhite,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        999,
                                                                      ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .verified_rounded,
                                                                      size: 13,
                                                                      color: AppColors
                                                                          .cyanVivid,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 4,
                                                                    ),
                                                                    Flexible(
                                                                      child: Text(
                                                                        rightBadge,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: const TextStyle(
                                                                          fontFamily:
                                                                              AppTypography.bodyFont,
                                                                          fontWeight:
                                                                              FontWeight.w800,
                                                                          fontSize:
                                                                              10,
                                                                          color:
                                                                              AppColors.oceanBlue,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Text(
                                                                rightTitle,
                                                                style:
                                                                    AppTypography.cardTitle(
                                                                      color: AppColors
                                                                          .oceanBlue,
                                                                    ).copyWith(
                                                                      fontSize:
                                                                          14,
                                                                      height:
                                                                          1.24,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              for (
                                                                int i = 0;
                                                                i <
                                                                    rightPoints
                                                                        .length;
                                                                i++
                                                              ) ...[
                                                                if (i > 0)
                                                                  const SizedBox(
                                                                    height: 7,
                                                                  ),
                                                                _BenefitPointRow(
                                                                  positive:
                                                                      true,
                                                                  text:
                                                                      rightPoints[i],
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 10,
                                                                ),
                                                            child: Center(
                                                              child: SizedBox(
                                                                width: 112,
                                                                height: 92,
                                                                child: AnimatedBuilder(
                                                                  animation:
                                                                      _ambientCtrl,
                                                                  builder: (_, child) {
                                                                    final t =
                                                                        _ambientCtrl
                                                                            .value;
                                                                    final bounce =
                                                                        -math
                                                                            .sin(
                                                                              t * 4 * math.pi,
                                                                            )
                                                                            .abs() *
                                                                        6.0;
                                                                    final tilt =
                                                                        math.sin(
                                                                          t *
                                                                              2 *
                                                                              math.pi,
                                                                        ) *
                                                                        0.05;
                                                                    return Stack(
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      children: [
                                                                        const AquaWaterHalo(
                                                                          color:
                                                                              AppColors.cyanVivid,
                                                                          size:
                                                                              64,
                                                                          maxScale:
                                                                              1.4,
                                                                        ),
                                                                        CustomPaint(
                                                                          size: const Size(
                                                                            112,
                                                                            92,
                                                                          ),
                                                                          painter: _HydratedSparklesPainter(
                                                                            t: t,
                                                                          ),
                                                                        ),
                                                                        Transform.translate(
                                                                          offset: Offset(
                                                                            0,
                                                                            bounce,
                                                                          ),
                                                                          child: Transform.rotate(
                                                                            angle:
                                                                                tilt,
                                                                            child:
                                                                                child,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                  child: AquaMascotVectorArt(
                                                                    mascotId: c
                                                                        .selectedMascotId,
                                                                    accessoryName: 'Vương miện Giọt Nước',
                                                                    size: 86,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Animated pulsing gradient arrow bridging both states
                                      AquaWaterHalo(
                                        color: AppColors.cyanVivid,
                                        size: 42,
                                        maxScale: 1.5,
                                        child: AnimatedBuilder(
                                          animation: _ambientCtrl,
                                          builder: (_, child) {
                                            final dx =
                                                math.sin(
                                                  _ambientCtrl.value *
                                                      4 *
                                                      math.pi,
                                                ) *
                                                2.5;
                                            return Transform.translate(
                                              offset: Offset(dx, 0),
                                              child: child,
                                            );
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.cyanVivid,
                                                  AppColors.oceanBlue,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.pureWhite,
                                                width: 2.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x3300BBE4),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                              color: AppColors.pureWhite,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 3-Column SDG 6 Impact Summary Strip
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: StaggeredEntrance(
                                index: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.iceCanvas,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.cardBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _ImpactMetricColumn(
                                          value: '$_previewGoalMl ml',
                                          label: 'Cấp ẩm chuẩn',
                                          color: AppColors.cyanVivid,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: AppColors.cardBorder,
                                      ),
                                      const Expanded(
                                        child: _ImpactMetricColumn(
                                          value: 'WHO / QCVN',
                                          label: 'An toàn WASH',
                                          color: AppColors.oceanBlue,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: AppColors.cardBorder,
                                      ),
                                      const Expanded(
                                        child: _ImpactMetricColumn(
                                          value: '-30 chai',
                                          label: 'Giảm nhựa/tháng',
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
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
              BouncyPressable(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: AquaShimmerOverlay(
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x330F1F2C),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyInk,
                            foregroundColor: AppColors.pureWhite,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: _commitAndRunCalculation,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 19,
                          ),
                          label: Text(
                            'Cảm thấy tuyệt nhất!',
                            style: AppTypography.pillCta(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatingStage() {
    final c = widget.controller;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _calcCtrl,
            builder: (_, _) {
              final t = _calcCtrl.value;
              final bar1 = (t / 0.34).clamp(0.0, 1.0);
              final bar2 = ((t - 0.33) / 0.34).clamp(0.0, 1.0);
              final bar3 = ((t - 0.66) / 0.34).clamp(0.0, 1.0);
              final done = t >= 0.99;

              final activeColor = done
                  ? AppColors.emerald
                  : (t < 0.34
                        ? AppColors.cyanVivid
                        : (t < 0.68
                              ? const Color(0xFF3A7BFD)
                              : const Color(0xFFE8669F)));

              final phaseTint = done
                  ? const Color(0xFFECFFF5)
                  : (t < 0.34
                        ? const Color(0xFFEBF9FF)
                        : (t < 0.68
                              ? const Color(0xFFEFF3FF)
                              : const Color(0xFFFFF0F7)));

              final phaseCaption = done
                  ? 'Sẵn sàng đồng hành cùng bạn! ✨'
                  : (t < 0.34
                        ? 'Đang phân tích thể trạng & thói quen...'
                        : (t < 0.68
                              ? 'Đang cân chỉnh mục tiêu khoa học...'
                              : 'Đang hoàn thiện lộ trình SDG 6...'));

              final phasePalette = t < 0.34
                  ? const [
                      AppColors.cyanVivid,
                      Color(0xFF6AE2FB),
                      AppColors.oceanBlue,
                    ]
                  : (t < 0.68
                        ? const [
                            Color(0xFF4285F4),
                            AppColors.periwinkle,
                            Color(0xFF7B61FF),
                          ]
                        : const [
                            Color(0xFFF06292),
                            AppColors.emerald,
                            Color(0xFF9C6ADE),
                          ]);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [phaseTint, AppColors.pureWhite],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final orbSize = (constraints.maxWidth * 0.60).clamp(
                        206.0,
                        246.0,
                      );
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 38).clamp(
                              0.0,
                              double.infinity,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: orbSize + 24,
                                height: orbSize + 24,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AquaWaterHalo(
                                      color: activeColor,
                                      size: orbSize * 0.72,
                                      maxScale: 1.48,
                                    ),
                                    AquaConcentricDotsSpinner(
                                      size: orbSize,
                                      customPalette: phasePalette,
                                      child: AquaGentleFloat(
                                        amplitude: 4.5,
                                        rotationRadians: 0.03,
                                        child: AnimatedScale(
                                          scale: done ? 1.12 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 360,
                                          ),
                                          curve: Curves.easeOutBack,
                                          child: AquaMascotVectorArt(
                                            mascotId: c.selectedMascotId,
                                            accessoryName: done
                                                ? 'Vương miện Giọt Nước'
                                                : null,
                                            size: 74,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: CustomPaint(
                                        size: Size(orbSize, orbSize),
                                        painter: _OrbProgressArcPainter(
                                          progress: t,
                                          color: activeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                child: Container(
                                  key: ValueKey<String>(phaseCaption),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: activeColor.withValues(
                                        alpha: 0.28,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    phaseCaption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.metricLabel(
                                      activeColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _CalculationStepRow(
                                label: 'Phân tích dữ liệu của bạn',
                                progress: bar1,
                                color: AppColors.cyanVivid,
                              ),
                              const SizedBox(height: 10),
                              _CalculationStepRow(
                                label: 'Cá nhân hóa các mục tiêu',
                                progress: bar2,
                                color: const Color(0xFF3A7BFD),
                              ),
                              const SizedBox(height: 10),
                              _CalculationStepRow(
                                label: 'Chuẩn bị lộ trình nước sạch SDG 6',
                                progress: bar3,
                                color: const Color(0xFFE8669F),
                              ),
                              const SizedBox(height: 18),
                              AnimatedOpacity(
                                opacity: done ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 280),
                                child: AnimatedScale(
                                  scale: done ? 1.0 : 0.92,
                                  duration: const Duration(milliseconds: 340),
                                  curve: Curves.easeOutBack,
                                  child: IgnorePointer(
                                    ignoring: !done,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppColors.mintTile,
                                                AppColors.cyanTile,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            border: Border.all(
                                              color: AppColors.emerald
                                                  .withValues(alpha: 0.35),
                                              width: 1.4,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x1410B981),
                                                blurRadius: 16,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.water_drop_rounded,
                                                    color: AppColors.emerald,
                                                    size: 19,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      c.role == AquaRole.kids
                                                          ? 'Mục tiêu của bé: ${c.kidsGoalCups} cốc / ngày'
                                                          : 'Mục tiêu của bạn: ${c.dailyGoalMl} ml / ngày',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          AppTypography.rowTitle(
                                                            color: AppColors
                                                                .emerald,
                                                          ).copyWith(
                                                            fontSize: 15.5,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (c.role != AquaRole.kids) ...[
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  alignment:
                                                      WrapAlignment.center,
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: [
                                                    _RevealTagPill(
                                                      text:
                                                          '${c.bodyWeightKg.round()} kg',
                                                    ),
                                                    _RevealTagPill(
                                                      text:
                                                          c.activityLevel.label,
                                                    ),
                                                    _RevealTagPill(
                                                      text:
                                                          c.climateLevel.label,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        BouncyPressable(
                                          child: AquaShimmerOverlay(
                                            child: SizedBox(
                                              width: double.infinity,
                                              height: 54,
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.navyInk,
                                                  foregroundColor:
                                                      AppColors.pureWhite,
                                                  shape: const StadiumBorder(),
                                                  elevation: 0,
                                                ),
                                                onPressed: widget.onCompleted,
                                                child: Text(
                                                  widget.completeButtonLabel,
                                                  style:
                                                      AppTypography.pillCta(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
              );
            },
          ),
        ),
        Positioned.fill(
          child: AquaConfettiOverlay(triggerKey: _calcConfettiTrigger),
        ),
      ],
    );
  }
}

class _CalculatorSelectorPill extends StatelessWidget {
  const _CalculatorSelectorPill({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.pureWhite.withValues(alpha: 0.30)
              : AppColors.pureWhite.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.pureWhite.withValues(alpha: filled ? 0.55 : 0.24),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontWeight: filled ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 14.5,
                        color: filled
                            ? AppColors.pureWhite
                            : AppColors.pureWhite.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: filled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.pureWhite,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: AppColors.oceanBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17, color: AppColors.pureWhite),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitTogglePill extends StatelessWidget {
  const _UnitTogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyanTile : AppColors.iceCanvas,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.metricLabel(
            selected ? AppColors.oceanBlue : AppColors.mutedGrey,
          ),
        ),
      ),
    );
  }
}

class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.pillGrey,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 18,
          color: AppColors.slateBody,
        ),
      ),
    );
  }
}

class _SpeechBubbleCardClipper extends CustomClipper<Path> {
  const _SpeechBubbleCardClipper();

  static const double _tailHeight = 16.0;
  static const double _tailHalfWidth = 17.0;
  static const double _radius = 30.0;

  @override
  Path getClip(Size size) {
    final bodyBottom = math.max(_radius * 2, size.height - _tailHeight);
    final cx = size.width / 2;

    return Path()
      ..moveTo(_radius, 0)
      ..lineTo(size.width - _radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, _radius)
      ..lineTo(size.width, bodyBottom - _radius)
      ..quadraticBezierTo(
        size.width,
        bodyBottom,
        size.width - _radius,
        bodyBottom,
      )
      ..lineTo(cx + _tailHalfWidth, bodyBottom)
      ..lineTo(cx + 2, size.height - 2)
      ..quadraticBezierTo(cx, size.height, cx - 2, size.height - 2)
      ..lineTo(cx - _tailHalfWidth, bodyBottom)
      ..lineTo(_radius, bodyBottom)
      ..quadraticBezierTo(0, bodyBottom, 0, bodyBottom - _radius)
      ..lineTo(0, _radius)
      ..quadraticBezierTo(0, 0, _radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _SpeechBubbleCardClipper oldClipper) => false;
}

class _BenefitsTopicToggle extends StatelessWidget {
  const _BenefitsTopicToggle({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = ['Toàn diện SDG 6', 'Nước sạch & WASH'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.iceCanvas,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!active) {
                    HapticFeedback.selectionClick();
                    onSelect(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.navyInk : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    items[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.metricLabel(
                      active ? AppColors.pureWhite : AppColors.slateBody,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BenefitPointRow extends StatelessWidget {
  const _BenefitPointRow({required this.positive, required this.text});

  final bool positive;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 19,
          height: 19,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: positive ? AppColors.cyanVivid : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            positive ? Icons.check_rounded : Icons.close_rounded,
            size: 13,
            color: positive ? AppColors.pureWhite : const Color(0xFFA098C8),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTypography.cardBody(color: AppColors.navyInk)
                .copyWith(fontSize: 12, height: 1.28),
          ),
        ),
      ],
    );
  }
}

class _CalculationStepRow extends StatelessWidget {
  const _CalculationStepRow({
    required this.label,
    required this.progress,
    required this.color,
  });

  final String label;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final completed = progress >= 0.99;
    final active = progress > 0.02 && !completed;
    final pct = (progress * 100).round();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: completed ? color.withValues(alpha: 0.08) : AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active || completed
              ? color.withValues(alpha: 0.36)
              : AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x080F1F2C),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.rowTitle(color: color),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedScale(
                scale: completed ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: completed
                    ? Icon(Icons.check_circle_rounded, color: color, size: 20)
                    : Text(
                        '$pct%',
                        style: AppTypography.metricLabel(
                          active ? color : AppColors.mutedGrey,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 9,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.antiAlias,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(color, AppColors.pureWhite, 0.32)!,
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: active
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 14,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: highlight
                  ? AppTypography.rowTitle(color: AppColors.oceanBlue)
                  : AppTypography.cardBody(color: AppColors.navyInk),
            ),
          ),
          Text(
            value,
            style: highlight
                ? AppTypography.cardTitle(color: AppColors.emerald)
                : AppTypography.rowTitle(),
          ),
        ],
      ),
    );
  }
}

class _ReminderFeatureChip extends StatelessWidget {
  const _ReminderFeatureChip({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F1F2C),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.metricLabel(AppColors.navyInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaMiniChip extends StatelessWidget {
  const _FormulaMiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.pureWhite.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AppTypography.bodyFont,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          color: AppColors.pureWhite,
        ),
      ),
    );
  }
}

class _ImpactMetricColumn extends StatelessWidget {
  const _ImpactMetricColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.cardTitle(color: color)
                  .copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.cardBody().copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RevealTagPill extends StatelessWidget {
  const _RevealTagPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.metricLabel(AppColors.oceanBlue),
      ),
    );
  }
}

class _ReminderMeadowPainter extends CustomPainter {
  const _ReminderMeadowPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shift = math.sin(progress * 2 * math.pi) * 14.0;

    // Soft glowing sun & rotating ambient ray halo
    final sunCenter = Offset(size.width * 0.82, size.height * 0.22);
    canvas.drawCircle(
      sunCenter,
      38 + math.sin(progress * 4 * math.pi) * 3,
      Paint()..color = const Color(0xFFFFF4C2).withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      sunCenter,
      20,
      Paint()..color = const Color(0xFFFFE58F).withValues(alpha: 0.82),
    );

    // Diagonal sunlight beams
    final beamPaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.34);
    final beam1 = Path()
      ..moveTo(size.width * 0.50 + shift * 0.4, 0)
      ..lineTo(size.width * 0.72 + shift * 0.4, 0)
      ..lineTo(size.width * 0.22, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(beam1, beamPaint);

    // Drifting multi-puff pastel clouds
    final cloudPaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.85);
    void drawCloud(double cx, double cy, double scale) {
      canvas.drawCircle(Offset(cx, cy), 14 * scale, cloudPaint);
      canvas.drawCircle(
        Offset(cx - 13 * scale, cy + 4 * scale),
        10 * scale,
        cloudPaint,
      );
      canvas.drawCircle(
        Offset(cx + 14 * scale, cy + 4 * scale),
        11 * scale,
        cloudPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, cy + 7 * scale),
            width: 34 * scale,
            height: 12 * scale,
          ),
          Radius.circular(8 * scale),
        ),
        cloudPaint,
      );
    }

    drawCloud(
      ((size.width * 0.24 + progress * 38) % (size.width + 60)) - 30,
      size.height * 0.24,
      1.0,
    );
    drawCloud(
      ((size.width * 0.62 + progress * 24) % (size.width + 60)) - 30,
      size.height * 0.36,
      0.78,
    );

    // Distant pastel skyline silhouettes with subtle window highlights
    final skylinePaint = Paint()
      ..color = const Color(0xFFB3E4FA).withValues(alpha: 0.82);
    final windowPaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.55);
    const heights = [0.22, 0.30, 0.25, 0.36, 0.20, 0.28, 0.32, 0.24];
    final colW = size.width / heights.length;
    for (int i = 0; i < heights.length; i++) {
      final h = size.height * heights[i];
      final bx = i * colW + 4;
      final by = size.height - 64 - h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, colW - 8, h + 18),
          const Radius.circular(6),
        ),
        skylinePaint,
      );
      if (i.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(bx + 6, by + 10, 6, 8),
            const Radius.circular(2),
          ),
          windowPaint,
        );
      }
    }

    // Back green hill
    final backHill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 84)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height - 116,
        size.width * 0.68,
        size.height - 86,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height - 68,
        size.width,
        size.height - 90,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(backHill, Paint()..color = const Color(0xFF7AD87D));

    // Subtle winding turquoise water creek
    final creek = Path()
      ..moveTo(size.width * 0.52, size.height - 88)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height - 68,
        size.width * 0.94,
        size.height - 54,
      );
    canvas.drawPath(
      creek,
      Paint()
        ..color = AppColors.cyanTile.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    // Foreground bright green meadow
    final frontHill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 54)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height - 76,
        size.width,
        size.height - 46,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(frontHill, Paint()..color = const Color(0xFF47BC5C));

    // Tiny swaying grass tufts seated cleanly above the 16px tail
    final tuftPaint = Paint()
      ..color = const Color(0xFF2D9D44)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final sway = math.sin(progress * 4 * math.pi) * 2.5;
    for (final gx in [
      size.width * 0.14,
      size.width * 0.34,
      size.width * 0.80,
    ]) {
      final gy = size.height - 44;
      canvas.drawLine(Offset(gx, gy), Offset(gx - 3 + sway, gy - 9), tuftPaint);
      canvas.drawLine(Offset(gx, gy), Offset(gx + 3 + sway, gy - 8), tuftPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReminderMeadowPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SwimmingBubblesPainter extends CustomPainter {
  const _SwimmingBubblesPainter({
    required this.t,
    required this.whaleDx,
    required this.facing,
  });

  final double t;
  final double whaleDx;
  final double facing;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + whaleDx;
    final cy = size.height / 2;
    final trailDir = -facing; // behind the swimming tail
    for (int i = 0; i < 4; i++) {
      final phase = (t * 2.5 + i * 0.25) % 1.0;
      final bx = cx + trailDir * (26 + i * 11 + phase * 8);
      final by = cy + math.sin(phase * math.pi * 2 + i) * 5 - phase * 10;
      final r = 2.0 + (3 - i) * 0.8;
      canvas.drawCircle(
        Offset(bx, by),
        r,
        Paint()
          ..color = AppColors.pureWhite.withValues(alpha: (1.0 - phase) * 0.72),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SwimmingBubblesPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.whaleDx != whaleDx ||
      oldDelegate.facing != facing;
}

class _DehydratedMoodOverlayPainter extends CustomPainter {
  const _DehydratedMoodOverlayPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Drifting drowsy puff clouds & falling sweat bead
    final cloudOffset = math.sin(t * 2 * math.pi) * 3.0;
    final puffPaint = Paint()
      ..color = const Color(0xFFB5A8DF).withValues(alpha: 0.45);
    canvas.drawCircle(
      Offset(size.width * 0.24 + cloudOffset, size.height * 0.20),
      5.5,
      puffPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.30 + cloudOffset, size.height * 0.14),
      4.0,
      puffPaint,
    );

    final dropCycle = t % 1.0;
    final dropY = size.height * (0.28 + dropCycle * 0.28);
    final dropAlpha = (1.0 - dropCycle) * 0.65;
    canvas.drawCircle(
      Offset(size.width * 0.78, dropY),
      3.4,
      Paint()..color = const Color(0xFF9C8CE0).withValues(alpha: dropAlpha),
    );
  }

  @override
  bool shouldRepaint(covariant _DehydratedMoodOverlayPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _HydratedSparklesPainter extends CustomPainter {
  const _HydratedSparklesPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const spots = [
      (0.16, 0.22, Color(0xFFFFC93C), 0.0),
      (0.84, 0.20, Color(0xFF00BBE4), 0.25),
      (0.12, 0.62, Color(0xFF52D681), 0.5),
      (0.88, 0.58, Color(0xFFFFC93C), 0.75),
      (0.50, 0.10, Color(0xFF00BBE4), 0.4),
    ];

    for (final (nx, ny, color, phaseOffset) in spots) {
      final pulse =
          0.45 + 0.55 * math.sin((t + phaseOffset) * 2 * math.pi).abs();
      final center = Offset(size.width * nx, size.height * ny);
      final arm = 4.2 + pulse * 3.2;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.45 + pulse * 0.55);
      final star = Path()
        ..moveTo(center.dx, center.dy - arm)
        ..lineTo(center.dx + arm * 0.28, center.dy - arm * 0.28)
        ..lineTo(center.dx + arm, center.dy)
        ..lineTo(center.dx + arm * 0.28, center.dy + arm * 0.28)
        ..lineTo(center.dx, center.dy + arm)
        ..lineTo(center.dx - arm * 0.28, center.dy + arm * 0.28)
        ..lineTo(center.dx - arm, center.dy)
        ..lineTo(center.dx - arm * 0.28, center.dy - arm * 0.28)
        ..close();
      canvas.drawPath(star, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HydratedSparklesPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _OrbProgressArcPainter extends CustomPainter {
  const _OrbProgressArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.21;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _CyanWaveWipePainter extends CustomPainter {
  const _CyanWaveWipePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
    final topY = size.height * (1.0 - eased) - 28;

    // Translucent leading crest wave
    final backWave = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 8) {
      final y =
          topY -
          12 +
          18 * math.cos((x / size.width) * 2 * math.pi + eased * 4.0);
      backWave.lineTo(x, y);
    }
    backWave
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      backWave,
      Paint()..color = AppColors.skyCyan.withValues(alpha: 0.55),
    );

    // Main vivid cyan wave
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 8) {
      final y =
          topY + 20 * math.sin((x / size.width) * 2 * math.pi + eased * 5.0);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.cyanVivid);

    // Rising translucent wave bubbles
    final bubblePaint = Paint()
      ..color = AppColors.pureWhite.withValues(alpha: 0.36);
    for (int i = 0; i < 7; i++) {
      final bx = size.width * (0.12 + i * 0.13);
      final by = topY + 26 + (i % 3) * 18;
      if (by < size.height) {
        canvas.drawCircle(Offset(bx, by), 3.0 + (i % 2) * 2.0, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CyanWaveWipePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
