import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../animations/aqua_motion.dart';
import 'aqua_mascot_catalog.dart';

/// Waterllama-inspired AquaCare SDG 6 Mascot Collection sheet.
class AquaMascotCollectionModal extends StatelessWidget {
  const AquaMascotCollectionModal({super.key, required this.controller});

  final AquaUiController controller;

  static Future<void> show(
    BuildContext context,
    AquaUiController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: AquaMascotCollectionModal(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = AquaMascotCatalog.byId(controller.selectedMascotId);
        final unlockedIds = AquaMascotCatalog.unlockedIdsFor(controller);

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
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: BouncyPressable(
                          pressedScale: 0.94,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              controller.pickRandomMascot(unlockedIds);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pillGrey,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shuffle_rounded,
                                    size: 15,
                                    color: AppColors.navyInk,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'ĐỔI NGẪU NHIÊN',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTypography.bodyFont,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyInk,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                              color: AppColors.pureWhite,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Featured Selected Mascot Hero
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected.cardBgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 82,
                          height: 90,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, anim) => ScaleTransition(
                              scale: Tween<double>(begin: 0.85, end: 1.0)
                                  .animate(anim),
                              child: FadeTransition(opacity: anim, child: child),
                            ),
                            child: Center(
                              key: ValueKey<String>(selected.id),
                              child: AquaMascotVectorArt(
                                mascotId: selected.id,
                                size: 76,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pureWhite
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${selected.badgeEmoji} ${selected.title}',
                                  style: AppTypography.metricLabel(
                                    selected.accentColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selected.name,
                                style: AppTypography.pageTitle()
                                    .copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected.description,
                                style: AppTypography.cardBody(
                                  color: AppColors.navyInk.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${unlockedIds.length} / ${AquaMascotCatalog.all.length} linh vật AquaCare',
                                style: AppTypography.metricLabel(
                                  AppColors.oceanBlue,
                                ).copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyanVivid,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${unlockedIds.length}/${AquaMascotCatalog.all.length}',
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.pureWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bộ sưu tập Hộ vệ Nước sạch',
                          style: AppTypography.cardTitle().copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.cyanTile,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: AquaMascotCatalog.all.length,
                      itemBuilder: (context, index) {
                        final item = AquaMascotCatalog.all[index];
                        final isUnlocked = item.isUnlocked(controller);
                        final isSelected = item.id == selected.id;

                        return BouncyPressable(
                          pressedScale: 0.94,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              if (isUnlocked) {
                                controller.selectMascot(item.id);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                      '🔒 ${item.name}: ${item.unlockHint}',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.pureWhite
                                    : AppColors.pureWhite.withValues(
                                        alpha: isUnlocked ? 0.65 : 0.45,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: item.accentColor
                                              .withValues(alpha: 0.24),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AquaMascotVectorArt(
                                        mascotId: item.id,
                                        size: 54,
                                        locked: !isUnlocked,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: AppTypography.bodyFont,
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: isUnlocked
                                              ? AppColors.navyInk
                                              : AppColors.mutedGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: AppColors.cyanVivid,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.pureWhite,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 13,
                                          color: AppColors.pureWhite,
                                        ),
                                      ),
                                    )
                                  else if (!isUnlocked)
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.lock_rounded,
                                        size: 15,
                                        color: AppColors.mutedGrey,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
