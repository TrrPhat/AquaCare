import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../animations/aqua_motion.dart';
import 'aqua_drink_painter.dart';

/// Waterllama-style Giant Draggable Cup Modal for tactile drink & volume selection.
/// Returns the effective ml logged if confirmed, or null if dismissed.
class AquaGiantCupModal extends StatefulWidget {
  const AquaGiantCupModal({
    super.key,
    required this.controller,
    this.initialVolumeMl,
  });

  final AquaUiController controller;
  final int? initialVolumeMl;

  static Future<int?> show(
    BuildContext context, {
    required AquaUiController controller,
    int? initialVolumeMl,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.90,
        child: AquaGiantCupModal(
          controller: controller,
          initialVolumeMl: initialVolumeMl,
        ),
      ),
    );
  }

  @override
  State<AquaGiantCupModal> createState() => _AquaGiantCupModalState();
}

class _AquaGiantCupModalState extends State<AquaGiantCupModal> {
  late AquaBeverageSpec _drink;
  late int _volumeMl;
  int _lastHapticStep = 250;

  @override
  void initState() {
    super.initState();
    _drink = AquaBeverageSpec.of(widget.controller.selectedDrink);
    _volumeMl = (widget.initialVolumeMl ?? widget.controller.cupVolumeMl.round())
        .clamp(50, 1500);
    _lastHapticStep = _volumeMl;
  }

  void _onDragDelta(double dy) {
    final deltaMl = (-dy * 2.5).round();
    if (deltaMl == 0) return;
    setState(() {
      final raw = (_volumeMl + deltaMl).clamp(50, 1500);
      _volumeMl = ((raw + 2) ~/ 5) * 5;
      if ((_volumeMl - _lastHapticStep).abs() >= 25) {
        _lastHapticStep = _volumeMl;
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fillFrac = (_volumeMl / 600.0).clamp(0.10, 0.94);
    final effectiveMl = _drink.computeEffectiveMl(_volumeMl);
    final caffeineMg = _drink.computeCaffeineMg(_volumeMl);
    final drinkColor = Color(_drink.colorValue);

    return Material(
      color: AppColors.pureWhite,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.homeIndicator,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 18, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn đồ uống & thể tích',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncyPressable(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.closeGrey,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.pureWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Beverage Selector Strip
            SizedBox(
              height: 82,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: AquaBeverageSpec.catalog.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final d = AquaBeverageSpec.catalog[index];
                  final selected = d.name == _drink.name;
                  final col = Color(d.colorValue);
                  return BouncyPressable(
                    pressedScale: 0.94,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _drink = d);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? col.withValues(alpha: 0.16)
                              : AppColors.iceCanvas,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected ? col : Colors.transparent,
                            width: 1.8,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AquaDrinkIcon(
                              kind: d.iconKind,
                              color: col,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.name,
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontSize: 11.5,
                                fontWeight:
                                    selected ? FontWeight.w800 : FontWeight.w600,
                                color: AppColors.navyInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),

            // Draggable Giant Cup
            AquaGiantInteractiveCup(
              fillFraction: fillFrac,
              liquidColor: drinkColor,
              onVerticalDragDelta: _onDragDelta,
            ),

            const SizedBox(height: 16),

            AnimatedIntText(
              value: _volumeMl,
              formatter: (v) => '$v ml',
              style: AppTypography.displayHero().copyWith(fontSize: 34),
            ),

            const SizedBox(height: 4),

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
                  child: Text(
                    'Cấp ẩm thực: +$effectiveMl ml (${(_drink.hydrationFactor * 100).round()}%)',
                    style: AppTypography.metricLabel(AppColors.oceanBlue),
                  ),
                ),
                if (caffeineMg > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.coralTile,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '☕ +$caffeineMg mg Caffeine',
                      style: AppTypography.metricLabel(AppColors.softCoral),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [150, 250, 350, 500, 750].map((presetMl) {
                final active = _volumeMl == presetMl;
                return BouncyPressable(
                  pressedScale: 0.93,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _volumeMl = presetMl);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.navyInk : AppColors.pillGrey,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$presetMl ml',
                        style: TextStyle(
                          fontFamily: AppTypography.bodyFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color:
                              active ? AppColors.pureWhite : AppColors.slateBody,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: BouncyPressable(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cyanVivid,
                      foregroundColor: AppColors.pureWhite,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.controller.selectDrink(_drink.name);
                      widget.controller.setCupVolume(_volumeMl.toDouble());
                      widget.controller.addWater(_volumeMl);
                      Navigator.of(context).pop<int>(effectiveMl);
                    },
                    child: Text(
                      '+ GHI NHẬN $_volumeMl ML ${_drink.name.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.pillCta(),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
