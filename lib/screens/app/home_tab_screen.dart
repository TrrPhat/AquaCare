import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/common/aqua_cards.dart';
import '../../widgets/common/aqua_svg_icon.dart';
import '../../widgets/hydration/aqua_drink_painter.dart';
import '../../widgets/hydration/aqua_giant_cup_modal.dart';
import '../../widgets/hydration/aqua_history_modal.dart';
import '../../widgets/interactive/interactive_panel.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';
import '../../widgets/mascot/aqua_mascot_collection_modal.dart';
import '../../widgets/mascot/aqua_mascot_wave_vessel.dart';
import 'aquabot_chat_screen.dart';
import 'hydration_personalizer_flow.dart';
import 'notifications_screen.dart';

/// Tab 0: Waterllama-inspired multi-mode Home Dashboard with Mascot Wave Vessel,
/// 3-button Action Dock, Giant Draggable Cup Modal, Sticky Mini-Dock & Confetti celebration.
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _splashImpulseController;
  bool _showCompactHeaderDock = false;
  int _rewardTriggerCount = 0;
  int _lastAddedMl = 250;
  int _confettiKey = 0;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _lastProgress = widget.controller.intakeProgress;
    _splashImpulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant HomeTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _lastProgress = widget.controller.intakeProgress;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onScroll() {
    final compact =
        _scrollController.hasClients && _scrollController.offset > 280;
    if (compact != _showCompactHeaderDock) {
      setState(() => _showCompactHeaderDock = compact);
    }
  }

  void _onControllerChanged() {
    final nextProg = widget.controller.intakeProgress;
    if (_lastProgress < 0.999 && nextProg >= 0.999 && mounted) {
      setState(() => _confettiKey++);
    }
    _lastProgress = nextProg;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _splashImpulseController.dispose();
    super.dispose();
  }

  void _triggerVisualReward(int effectiveMl) {
    setState(() {
      _lastAddedMl = effectiveMl;
      _rewardTriggerCount++;
    });
    _splashImpulseController.forward(from: 0.0);
  }

  void _drinkWater(int rawMl) {
    HapticFeedback.mediumImpact();
    final spec = AquaBeverageSpec.of(widget.controller.selectedDrink);
    final effectiveMl = spec.computeEffectiveMl(rawMl);
    widget.controller.addWater(rawMl);
    _triggerVisualReward(effectiveMl);
  }

  Future<void> _openGiantCupSheet({int? initialVolumeMl}) async {
    final addedEffective = await AquaGiantCupModal.show(
      context,
      controller: widget.controller,
      initialVolumeMl: initialVolumeMl,
    );
    if (addedEffective != null && addedEffective > 0 && mounted) {
      _triggerVisualReward(addedEffective);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final selectedSpec = AquaBeverageSpec.of(c.selectedDrink);
    final selectedMascot = AquaMascotCatalog.byId(c.selectedMascotId);

    return Container(
      color: AppColors.iceCanvas,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: _buildGreetingHeader(
                    context,
                    c,
                    selectedSpec,
                    selectedMascot,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<AquaRole>(c.role),
                        child: c.role == AquaRole.household
                            ? _buildHouseholdBody(c)
                            : _buildStudentWorkerBody(
                                c,
                                selectedSpec,
                                selectedMascot,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: AquaConfettiOverlay(triggerKey: _confettiKey),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(
    BuildContext context,
    AquaUiController c,
    AquaBeverageSpec selectedSpec,
    AquaMascotSpec selectedMascot,
  ) {
    final showCompactDock =
        _showCompactHeaderDock && c.role != AquaRole.household;

    return Row(
      children: [
        BouncyPressable(
          pressedScale: 0.93,
          child: GestureDetector(
            onTap: () => AquaHistoryModal.show(context, c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.cyanTile,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${c.streakDays}',
                    style: const TextStyle(
                      fontFamily: AppTypography.displayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: showCompactDock
                ? Container(
                    key: const ValueKey('compact_dock'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D0F1F2C),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _openGiantCupSheet(),
                          child: AquaDrinkIcon(
                            kind: selectedSpec.iconKind,
                            color: Color(selectedSpec.colorValue),
                            size: 24,
                            showPlusBadge: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${c.intakePercent}%',
                          style: AppTypography.metricValue(
                            color: AppColors.cyanVivid,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () =>
                              AquaMascotCollectionModal.show(context, c),
                          child: AquaMascotVectorArt(
                            mascotId: selectedMascot.id,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    key: const ValueKey('greeting_title'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, ${c.userName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.pageTitle().copyWith(fontSize: 18),
                      ),
                      Text(
                        c.weatherLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardBody().copyWith(fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 8),
        BouncyPressable(
          child: Material(
            color: AppColors.pureWhite,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  AquaWavePageRoute<void>(
                    builder: (_) => AquaBotChatScreen(controller: c),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AquaPulseHalo(
                      maxScale: 1.14,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppColors.cyanVivid,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: AppTypography.metricLabel(AppColors.oceanBlue)
                          .copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        BouncyPressable(
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: () {
              Navigator.of(context).push(
                AquaWavePageRoute<void>(
                  builder: (_) => NotificationsScreen(controller: c),
                ),
              );
            },
            child: c.unreadNotifications > 0
                ? const AquaSvg(
                    'assets/svg/icons/icon_bell_red_dot.svg',
                    width: 38,
                    height: 38,
                  )
                : Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.oceanBlue,
                      size: 20,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentWorkerBody(
    AquaUiController c,
    AquaBeverageSpec selectedSpec,
    AquaMascotSpec selectedMascot,
  ) {
    final rem = (c.dailyGoalMl - c.intakeMl).clamp(0, 6000);
    final goal = c.dailyGoalMl > 0 ? c.dailyGoalMl : 2100;
    final bevInfo =
        'Hệ số cấp ẩm ${c.selectedDrink}: ${(selectedSpec.hydrationFactor * 100).round()}%${selectedSpec.caffeinePer250Ml > 0 ? ' • +${selectedSpec.caffeinePer250Ml} mg Caffeine / 250 ml' : ''}';

    // Build chronological multi-layer liquid slices from today's logs (oldest at bottom)
    final logs = c.drinkLogs;
    final slices = logs.reversed
        .where((entry) => entry.ml > 0)
        .map(
          (entry) => AquaLiquidSlice(
            fraction: entry.ml / goal,
            color: Color(AquaBeverageSpec.colorValueForName(entry.drink)),
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Borderless Hero Mascot Card (Waterllama centerpiece)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F1F2C),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Crisp Waterllama-style Readout Header
              AnimatedIntText(
                value: c.intakeMl,
                formatter: (v) => '$v / ${c.dailyGoalMl} ml',
                style: AppTypography.displayHero(color: AppColors.cyanVivid)
                    .copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyanTile,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedIntText(
                      value: c.intakePercent,
                      formatter: (v) => '$v% mục tiêu',
                      style: AppTypography.metricLabel(AppColors.oceanBlue),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rem == 0 ? AppColors.mintTile : AppColors.pillGrey,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rem == 0 ? 'Đã đạt mục tiêu! 🎉' : 'Còn $rem ml nữa',
                      style: AppTypography.metricLabel(
                        rem == 0 ? AppColors.emerald : AppColors.slateBody,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      Navigator.of(context).push(
                        AquaWavePageRoute<void>(
                          builder: (_) => AquaHydrationPersonalizerScreen(
                            controller: c,
                            initialStage: 1,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintTile,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_graph_rounded,
                            size: 13,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tính mục tiêu',
                            style: AppTypography.metricLabel(AppColors.emerald),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mascot Wave Vessel + Floating Reward
              FloatingRewardHost(
                triggerCount: _rewardTriggerCount,
                rewardText: '+$_lastAddedMl ml 💧',
                backgroundColor: AppColors.cyanVivid,
                child: SizedBox(
                  height: 214,
                  width: 214,
                  child: AnimatedBuilder(
                    animation: _splashImpulseController,
                    builder: (_, _) {
                      return AquaMascotWaveVessel(
                        mascotId: selectedMascot.id,
                        slices: slices,
                        totalFractionOverride: c.intakeProgress,
                        slosh: _splashImpulseController.value,
                        onTap: () => _openGiantCupSheet(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Waterllama 3-Button Action Dock (Drink Cup | 3D Flip Stat | Mascot Switcher)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BouncyPressable(
                        pressedScale: 0.93,
                        child: GestureDetector(
                          onTap: () => _openGiantCupSheet(),
                          child: Column(
                            children: [
                              AquaDrinkIcon(
                                kind: selectedSpec.iconKind,
                                color: Color(selectedSpec.colorValue),
                                size: 46,
                                showPlusBadge: true,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedSpec.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mutedGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          AquaFlipStatBadge(
                            size: 48,
                            frontValue: '${c.streakDays}',
                            frontLabel: 'CHUỖI',
                            backValue: '${c.plasticSaved}',
                            backLabel: 'CHAI XANH',
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () => AquaHistoryModal.show(context, c),
                            child: const Text(
                              'LỊCH SỬ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cyanVivid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: BouncyPressable(
                        pressedScale: 0.93,
                        child: GestureDetector(
                          onTap: () =>
                              AquaMascotCollectionModal.show(context, c),
                          child: Column(
                            children: [
                              AquaMascotVectorArt(
                                mascotId: selectedMascot.id,
                                size: 42,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedMascot.name.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mutedGrey,
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

              const SizedBox(height: 16),

              // Beverage Selector Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AquaBeverageSpec.catalog.map((spec) {
                    final selected = c.selectedDrink == spec.name;
                    final col = Color(spec.colorValue);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AquaChoiceChip(
                        label: spec.name,
                        selected: selected,
                        selectedColor: col,
                        onTap: () => c.selectDrink(spec.name),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bevInfo,
                textAlign: TextAlign.center,
                style: AppTypography.sectionCaption(color: AppColors.mutedGrey),
              ),
              const SizedBox(height: 12),

              // Quick 1-Tap Volume Pills (preserving FilledButton '+250 ml' contract)
              Row(
                children: [150, 250, 500].map((ml) {
                  final isPrimary = ml == 250;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: ml == 500 ? 0 : 8),
                      child: BouncyPressable(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: isPrimary
                                ? AppColors.cyanVivid
                                : AppColors.cyanTile,
                            foregroundColor: isPrimary
                                ? AppColors.pureWhite
                                : AppColors.oceanBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () => _drinkWater(ml),
                          child: Text(
                            '+$ml ml',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTypography.bodyFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pillGrey,
                    foregroundColor: AppColors.navyInk,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => _openGiantCupSheet(),
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: Text(
                    'Kéo cốc nước khổng lồ (Mặc định ${c.cupVolumeMl.round()} ml)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Borderless Pastel Shortcut Cards
        StaggeredEntrance(
          index: 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BouncyPressable(
                    child: _PastelShortcutCard(
                      icon: Icons.location_on_rounded,
                      accent: AppColors.emerald,
                      surfaceColor: AppColors.mintTile,
                      label: 'Trạm gần nhất',
                      value:
                          '${c.selectedStation.name.split(' ').take(3).join(' ')} • ${c.distanceToStation(c.selectedStation)}m',
                      onTap: () => c.setActiveTab(3),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncyPressable(
                    child: _PastelShortcutCard(
                      icon: Icons.eco_rounded,
                      accent: AppColors.emerald,
                      surfaceColor: AppColors.lavenderCard,
                      label: 'Sống xanh & vệ sinh',
                      value: 'Giảm ${c.plasticSaved} chai nhựa • WASH',
                      onTap: () => c.setActiveTab(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: Text(
                'Nhật ký uống nước hôm nay (${c.drinkLogs.length})',
                style: AppTypography.cardTitle(),
              ),
            ),
            if (c.caffeineMg > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coralTile,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '☕ ${c.caffeineMg} mg',
                  style: AppTypography.metricLabel(AppColors.softCoral),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        StaggeredEntrance(
          index: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F1F2C),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: c.drinkLogs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(18),
                      child: Center(
                        child: Text(
                          'Chưa có lần uống nước nào hôm nay. Hãy bấm +250 ml bên trên!',
                          style: AppTypography.cardBody(),
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(
                        math.min(c.drinkLogs.length, 6),
                        (index) {
                          final entry = c.drinkLogs[index];
                          final drinkColor = Color(
                            AquaBeverageSpec.colorValueForName(entry.drink),
                          );
                          final iconKind =
                              AquaBeverageSpec.iconKindForName(entry.drink);
                          final sub = entry.rawMl != entry.ml
                              ? '${entry.time} • Uống ${entry.rawMl} ml (quy đổi ${entry.ml} ml)'
                              : entry.time;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: drinkColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: AquaDrinkIcon(
                                  kind: iconKind,
                                  color: drinkColor,
                                  size: 22,
                                ),
                              ),
                            ),
                            title: Text(
                              entry.drink,
                              style: AppTypography.rowTitle(),
                            ),
                            subtitle: Text(sub, style: AppTypography.cardBody()),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${entry.ml} ml',
                                  style: AppTypography.metricValue(
                                    color: drinkColor,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Xóa lần ghi nhận này',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.mutedGrey,
                                  ),
                                  onPressed: () {
                                    c.removeDrinkLogAt(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        duration: const Duration(seconds: 1),
                                        content: Text(
                                          'Đã xóa ${entry.drink} (+${entry.ml} ml)',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdBody(AquaUiController c) {
    final roLow = c.roFilterHealth[0] <= 20;
    final billFormatted = AquaWaterBillEntry.formatVnd(c.currentWaterBillVnd);
    final assessment = c.waterSafetyAssessment;
    final heroSurface = switch (assessment.status) {
      AquaWaterSafetyStatus.safe => AppColors.mintTile,
      AquaWaterSafetyStatus.caution => AppColors.sunnyTile,
      AquaWaterSafetyStatus.warning => AppColors.coralTile,
    };
    final heroAccent = switch (assessment.status) {
      AquaWaterSafetyStatus.safe => AppColors.emerald,
      AquaWaterSafetyStatus.caution => AppColors.navyInk,
      AquaWaterSafetyStatus.warning => AppColors.softCoral,
    };
    final tdsTargetHint = c.waterSourceType == AquaWaterSourceType.roPurified
        ? 'chuẩn < 50'
        : 'QCVN ≤ 300';
    final washPct = (c.householdSanitationProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Borderless Family Water Purity Hero Card with edge-anchored Lotus Mascot
        StaggeredEntrance(
          index: 0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: heroSurface,
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned(
                  right: -6,
                  bottom: -6,
                  child: Opacity(
                    opacity: 0.92,
                    child: AquaMascotVectorArt(
                      mascotId: 'bup_sen',
                      size: 102,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pureWhite,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Nước sạch & vệ sinh gia đình (SDG 6)',
                          style: AppTypography.metricLabel(heroAccent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 84),
                        child: Text(
                          assessment.headline,
                          style: AppTypography.pageTitle().copyWith(
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(right: 86),
                        child: Text(
                          '${c.waterSourceType.fullLabel} • ${c.isLeakSuspected ? 'Cảnh báo tiêu thụ tăng cao' : 'Đường ống ổn định'}',
                          style: AppTypography.cardBody(
                            color: AppColors.navyInk.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AquaMetricRow(
                        leftLabel: 'Chỉ số TDS',
                        leftValue: '${c.tdsPpm} ppm ($tdsTargetHint)',
                        rightLabel: 'Độ pH nước',
                        rightValue:
                            '${c.phLevel.toStringAsFixed(1)} (${assessment.isPhOk ? 'tốt' : 'cần xem'})',
                        isKidsTheme: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (roLow)
          StaggeredEntrance(
            index: 1,
            child: BouncyPressable(
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.coralTile,
                  borderRadius: BorderRadius.circular(22),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => c.setActiveTab(1),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.pureWhite,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.softCoral,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bộ lọc thô cấp 1 còn ${c.roFilterHealth[0]}%',
                                  style: AppTypography.rowTitle(),
                                ),
                                Text(
                                  'Chạm để kiểm tra vệ sinh nước & bảo trì bộ lọc',
                                  style: AppTypography.cardBody(),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.navyInk,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        StaggeredEntrance(
          index: 2,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BouncyPressable(
                    child: _PastelShortcutCard(
                      icon: Icons.clean_hands_rounded,
                      accent: AppColors.oceanBlue,
                      surfaceColor: AppColors.cyanTile,
                      label: 'Nước sạch & vệ sinh',
                      value: 'WASH $washPct% • TDS ${c.tdsPpm}',
                      onTap: () => c.setActiveTab(1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncyPressable(
                    child: _PastelShortcutCard(
                      icon: Icons.receipt_long_rounded,
                      accent: AppColors.periwinkle,
                      surfaceColor: AppColors.lavenderCard,
                      label: 'Tiêu thụ tháng',
                      value:
                          '${c.monthlyCubicMeters.toStringAsFixed(0)} m³ (~$billFormatted)',
                      onTap: () => c.setActiveTab(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        StaggeredEntrance(
          index: 3,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F1F2C),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => AquaMascotCollectionModal.show(context, c),
                      child: Tooltip(
                        message: 'Đổi linh vật AquaCare',
                        child: AquaMascotVectorArt(
                          mascotId: c.selectedMascotId,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lượng nước cá nhân hôm nay',
                        style: AppTypography.rowTitle(),
                      ),
                    ),
                    AnimatedIntText(
                      value: c.intakeMl,
                      formatter: (v) => '$v / ${c.dailyGoalMl} ml',
                      style: AppTypography.metricValue(
                        color: AppColors.oceanBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AquaLiquidProgressBar(
                  value: c.intakeProgress,
                  color: AppColors.cyanVivid,
                  height: 9,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BouncyPressable(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyanVivid,
                            foregroundColor: AppColors.pureWhite,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: () => _drinkWater(250),
                          child: const Text('+250 ml'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BouncyPressable(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyanTile,
                            foregroundColor: AppColors.oceanBlue,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: () => _openGiantCupSheet(),
                          child: const Text('Kéo cốc nước'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Borderless Sunny AquaKids Handoff Card
        StaggeredEntrance(
          index: 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.sunnyTile,
              borderRadius: BorderRadius.circular(26),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AquaMascotVectorArt(
                        mascotId: 'giot_nuoc',
                        size: 52,
                        accessoryName: 'Vương miện Giọt Nước',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Góc của ${c.kidsName} trong gia đình',
                              style: AppTypography.cardTitle(isKids: true),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hôm nay: ${c.kidsCups}/${c.kidsGoalCups} cốc • ★ ${c.kidsStars} sao',
                              style: AppTypography.cardBody(
                                color: AppColors.navyInk.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  BouncyPressable(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sunnyButter,
                          foregroundColor: AppColors.navyInk,
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: c.enterKidsMode,
                        icon: const Icon(Icons.child_care_rounded, size: 19),
                        label: const Text(
                          'Giao máy cho bé (khóa chế độ trẻ em) →',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

class _PastelShortcutCard extends StatelessWidget {
  const _PastelShortcutCard({
    required this.icon,
    required this.accent,
    required this.surfaceColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final Color surfaceColor;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                const SizedBox(height: 10),
                Text(label, style: AppTypography.metricLabel(accent)),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.rowTitle()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
