import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../animations/aqua_motion.dart';
import '../animations/aqua_waterllama_motion.dart';
import 'aqua_drink_painter.dart';

/// Waterllama-style 7-Day Hydration Ring & Beverage Breakdown Modal.
class AquaHistoryModal extends StatelessWidget {
  const AquaHistoryModal({super.key, required this.controller});

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
        heightFactor: 0.85,
        child: AquaHistoryModal(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stats = controller.last7DaysStats;

        // Group today's beverage ml by drink type
        final Map<String, int> byDrink = {};
        for (final entry in controller.drinkLogs) {
          byDrink[entry.drink] = (byDrink[entry.drink] ?? 0) + entry.ml;
        }

        return Material(
          color: AppColors.pureWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AquaFlipStatBadge(
                        size: 86,
                        frontValue: '${controller.streakDays}',
                        frontLabel: 'CHUỖI\nNGÀY',
                        backValue: '${controller.weeklyAverageMl}',
                        backLabel: 'TRUNG BÌNH\nML/NGÀY',
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: BouncyPressable(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Chạm vào huy hiệu để lật xem chỉ số 3D',
                      style: AppTypography.sectionCaption(
                        color: AppColors.mutedGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 7-Day Ring Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.iceCanvas,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Nhịp cấp ẩm 7 ngày',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardTitle(),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                'Mục tiêu ${controller.dailyGoalMl} ml',
                                style: AppTypography.metricLabel(
                                  AppColors.oceanBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: List.generate(stats.length, (i) {
                            final (label, ml, ratio) = stats[i];
                            final isToday = i == stats.length - 1;
                            final reached = ratio >= 0.99;
                            return Expanded(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 38,
                                    height: 38,
                                    child: CustomPaint(
                                      painter: _DayRingPainter(
                                        ratio: ratio,
                                        color: reached
                                            ? AppColors.freshMint
                                            : (isToday
                                                  ? AppColors.cyanVivid
                                                  : AppColors.deepSky),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${(ratio * 100).round()}%',
                                              style: TextStyle(
                                                fontFamily: AppTypography.bodyFont,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: isToday
                                                    ? AppColors.navyInk
                                                    : AppColors.slateBody,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? AppColors.navyInk
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontFamily: AppTypography.bodyFont,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isToday
                                            ? AppColors.pureWhite
                                            : AppColors.mutedGrey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(ml / 1000).toStringAsFixed(1)}L',
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mutedGrey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Eco SDG 6 Highlight
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mintTile,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.pureWhite,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: AppColors.emerald,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tác động xanh SDG 6',
                                style: AppTypography.metricLabel(
                                  AppColors.emerald,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đã giảm ${controller.plasticSaved} chai nhựa dùng 1 lần nhờ bình cá nhân & trạm Refill!',
                                style: AppTypography.rowTitle(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Thành phần đồ uống hôm nay',
                    style: AppTypography.cardTitle(),
                  ),
                  const SizedBox(height: 10),
                  if (byDrink.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.iceCanvas,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Chưa có đồ uống nào hôm nay.',
                        style: AppTypography.cardBody(),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: byDrink.entries.map((entry) {
                        final col = Color(
                          AquaBeverageSpec.colorValueForName(entry.key),
                        );
                        final kind = AquaBeverageSpec.iconKindForName(entry.key);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AquaDrinkIcon(kind: kind, color: col, size: 22),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    entry.key,
                                    style: AppTypography.rowTitle()
                                        .copyWith(fontSize: 12.5),
                                  ),
                                  Text(
                                    '+${entry.value} ml',
                                    style: AppTypography.metricLabel(col),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayRingPainter extends CustomPainter {
  const _DayRingPainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.silhouetteGrey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ratio.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.2,
    );
  }

  @override
  bool shouldRepaint(covariant _DayRingPainter oldDelegate) =>
      oldDelegate.ratio != ratio || oldDelegate.color != color;
}
