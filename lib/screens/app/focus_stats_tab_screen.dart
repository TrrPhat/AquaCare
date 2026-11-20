import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/hydration/aqua_drink_painter.dart';
import '../../widgets/interactive/interactive_panel.dart';

/// Tab 1 riêng cho Sinh viên / Người đi làm (SDG 6):
/// Tác động Xanh giảm chai nhựa & biểu đồ 7 ngày, Vệ sinh bình nước & rửa tay (WASH),
/// Theo dõi Caffeine, Bù nước theo thời tiết/vận động & Nhắc uống nước theo ca (25 phút).
class FocusStatsTabScreen extends StatefulWidget {
  const FocusStatsTabScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<FocusStatsTabScreen> createState() => _FocusStatsTabScreenState();
}

class _FocusStatsTabScreenState extends State<FocusStatsTabScreen> {
  String _activeBoostTag = 'standard';

  void _applyContextBoost(String tag, int extraMl, String label) {
    final c = widget.controller;
    final baseGoal = ((c.bodyWeightKg * 33) / 50).round() * 50;
    setState(() {
      _activeBoostTag = tag;
    });
    c.setDailyGoalMl(baseGoal + extraMl);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          extraMl > 0
              ? 'Đã cộng +$extraMl ml ($label) → Mục tiêu mới: ${baseGoal + extraMl} ml'
              : 'Đã đưa mục tiêu về mức chuẩn theo cân nặng ($baseGoal ml)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final mins = (c.pomodoroSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (c.pomodoroSeconds % 60).toString().padLeft(2, '0');
    final pct = c.pomodoroSeconds / (25 * 60);
    final weeklyStats = c.last7DaysStats;

    final washTasks = c.personalSanitationTasks;
    final washDone = washTasks.where((t) => t.completed).length;
    final washRatio = c.personalSanitationProgress;

    final cafRatio = (c.caffeineMg / 300).clamp(0.0, 1.0);
    final cafColor = c.caffeineMg >= 300
        ? AppColors.softCoral
        : (c.caffeineMg >= 200 ? AppColors.starAmber : AppColors.freshMint);
    final cafStatus = c.caffeineMg >= 300
        ? 'Vượt ngưỡng 300 mg'
        : (c.caffeineMg >= 200 ? 'Gần ngưỡng' : 'Mức an toàn');
    final recommendedCompMl =
        c.caffeineMg == 0 ? 150 : ((c.caffeineMg / 100) * 200).round();

    return Container(
      color: AppColors.iceCanvas,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sống xanh & vệ sinh',
                          style: AppTypography.pageTitle().copyWith(fontSize: 21),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giảm rác nhựa, vệ sinh bình nước & cân bằng cấp ẩm (SDG 6)',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardBody(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AquaFlipStatBadge(
                    size: 58,
                    frontValue: '${c.plasticSaved}',
                    frontLabel: 'CHAI\nGIẢM',
                    backValue: '${c.streakDays}',
                    backLabel: 'CHUỖI\nNGÀY',
                    frontColor: AppColors.emerald,
                    backColor: AppColors.starAmber,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. SDG 6 Eco Score & 7-Day Hydration Chart
              StaggeredEntrance(
                index: 0,
                child: InteractivePanel(
                  title: 'Tác động xanh SDG 6 & thống kê 7 ngày',
                  badgeText: 'TB ${c.weeklyAverageMl} ml/ngày',
                  accentColor: AppColors.emerald,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutQuart,
                        builder: (_, t, _) {
                          return SizedBox(
                            height: 118,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _FocusWeeklyStatsPainter(
                                growFactor: t,
                                stats: weeklyStats,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mintTile,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    color: AppColors.pureWhite,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    size: 19,
                                    color: AppColors.emerald,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Đã tiết kiệm ${c.plasticSaved} chai nhựa dùng 1 lần (~${c.plasticSaved * 20}g nhựa • ~${c.plasticSaved * 82}g CO₂)',
                                    style: AppTypography.cardBody(
                                      color: AppColors.navyInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: BouncyPressable(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.emerald,
                                    foregroundColor: AppColors.pureWhite,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: () {
                                    c.checkInReusableBottle();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        duration: Duration(seconds: 2),
                                        content: Text(
                                          'Tuyệt vời! +1 lần dùng bình cá nhân giảm rác thải nhựa 🌱',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.recycling_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('+1 Refill bình cá nhân'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Personal Water Hygiene & Sanitation (WASH) Checklist
              StaggeredEntrance(
                index: 1,
                child: InteractivePanel(
                  title: 'Vệ sinh bình nước & rửa tay (WASH)',
                  badgeText: '$washDone/${washTasks.length} hôm nay',
                  accentColor: AppColors.oceanBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AquaLiquidProgressBar(
                        value: washRatio,
                        color: washRatio >= 1.0
                            ? AppColors.emerald
                            : AppColors.cyanVivid,
                        backgroundColor: AppColors.pillGrey,
                        height: 9,
                      ),
                      const SizedBox(height: 12),
                      ...washTasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: task.completed
                                ? AppColors.mintTile
                                : AppColors.iceCanvas,
                            borderRadius: BorderRadius.circular(16),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => c.toggleSanitationTask(task.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      task.completed
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 22,
                                      color: task.completed
                                          ? AppColors.emerald
                                          : AppColors.mutedGrey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: AppTypography.rowTitle(),
                                          ),
                                          Text(
                                            task.subtitle,
                                            style: AppTypography.cardBody(),
                                          ),
                                        ],
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
              const SizedBox(height: 14),

              // 3. Caffeine Tracker & Hydration Compensation
              StaggeredEntrance(
                index: 2,
                child: InteractivePanel(
                  title: 'Theo dõi Caffeine & bù nước',
                  badgeText: '${c.caffeineMg} / 300 mg',
                  accentColor: cafColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.warmSand,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: AquaDrinkIcon(
                                kind: 'coffee',
                                color: Color(0xFF6B4837),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cafStatus,
                                  style: AppTypography.rowTitle(color: cafColor),
                                ),
                                Text(
                                  'Nên bù +$recommendedCompMl ml nước lọc',
                                  style: AppTypography.cardBody(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AquaLiquidProgressBar(
                        value: cafRatio,
                        color: cafColor,
                        backgroundColor: AppColors.pillGrey,
                        height: 10,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          BouncyPressable(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.cyanTile,
                                foregroundColor: AppColors.oceanBlue,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () {
                                c.addScannedDrink(
                                  rawMl: 200,
                                  drinkLabel: 'Nước bù Caffeine',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    duration: Duration(seconds: 2),
                                    content: Text(
                                      'Đã uống bù +200 ml nước lọc cân bằng Caffeine!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.local_drink_rounded,
                                size: 17,
                              ),
                              label: const Text('+200 ml bù cà phê/trà'),
                            ),
                          ),
                          BouncyPressable(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.warmSand,
                                foregroundColor: const Color(0xFF6B4837),
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: () => c.addCaffeine(65),
                              icon: const Icon(Icons.coffee_rounded, size: 16),
                              label: const Text('+1 ly cà phê (65 mg)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Weather / Workout Goal Boost Chips
              StaggeredEntrance(
                index: 3,
                child: InteractivePanel(
                  title: 'Bù nước theo thời tiết & vận động',
                  badgeText: 'Mục tiêu ${c.dailyGoalMl} ml',
                  accentColor: AppColors.cyanVivid,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tùy chỉnh nhanh mục tiêu hôm nay khi trời nắng nóng hoặc tập thể thao:',
                        style: AppTypography.cardBody(),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AquaChoiceChip(
                            label: '🎯 Chuẩn cân nặng',
                            selected: _activeBoostTag == 'standard',
                            onTap: () =>
                                _applyContextBoost('standard', 0, 'mức chuẩn'),
                          ),
                          AquaChoiceChip(
                            label: '☀️ Trời nắng (+250 ml)',
                            selected: _activeBoostTag == 'hot',
                            selectedColor: AppColors.starAmber,
                            selectedTextColor: AppColors.navyInk,
                            onTap: () => _applyContextBoost(
                              'hot',
                              250,
                              'thời tiết nắng nóng',
                            ),
                          ),
                          AquaChoiceChip(
                            label: '🏃 Vận động / gym (+400 ml)',
                            selected: _activeBoostTag == 'workout',
                            selectedColor: AppColors.emerald,
                            onTap: () => _applyContextBoost(
                              'workout',
                              400,
                              'tập luyện thể thao',
                            ),
                          ),
                          AquaChoiceChip(
                            label: '❄️ Phòng điều hòa (+150 ml)',
                            selected: _activeBoostTag == 'ac',
                            selectedColor: AppColors.periwinkle,
                            onTap: () => _applyContextBoost(
                              'ac',
                              150,
                              'ngồi máy lạnh cả ngày',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Compact Shift Hydration Helper (Pomodoro 25 min)
              StaggeredEntrance(
                index: 4,
                child: InteractivePanel(
                  title: 'Nhắc uống nước theo ca (25 phút)',
                  badgeText: c.pomodoroRunning ? 'Đang chạy' : 'Hỗ trợ',
                  accentColor: AppColors.periwinkle,
                  child: Row(
                    children: [
                      AquaPulseHalo(
                        enabled: c.pomodoroRunning,
                        maxScale: 1.05,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lavenderCard.withValues(alpha: 0.45),
                            boxShadow: c.pomodoroRunning
                                ? [
                                    BoxShadow(
                                      color: AppColors.periwinkle
                                          .withValues(alpha: 0.30),
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: CustomPaint(
                            painter: _FocusPomodoroRingPainter(progress: pct),
                            child: Center(
                              child: Text(
                                '$mins:$secs',
                                style: AppTypography.cardTitle(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nghỉ giải lao mỗi 25 phút học/làm để đứng dậy vận động và uống 150 ml nước.',
                              style: AppTypography.cardBody(),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                BouncyPressable(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.periwinkle,
                                      foregroundColor: AppColors.pureWhite,
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: c.togglePomodoro,
                                    child: Text(
                                      c.pomodoroRunning ? 'Tạm dừng' : 'Bắt đầu',
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.pillGrey,
                                    foregroundColor: AppColors.navyInk,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: c.resetPomodoro,
                                  child: const Text('Đặt lại'),
                                ),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.cyanTile,
                                    foregroundColor: AppColors.oceanBlue,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                  ),
                                  onPressed: () {
                                    c.addScannedDrink(
                                      rawMl: 150,
                                      drinkLabel: 'Nước nghỉ giữa ca',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        duration: Duration(seconds: 2),
                                        content: Text(
                                          'Đã ghi nhận +150 ml nước nghỉ giữa ca!',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.water_drop_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('+150 ml'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusPomodoroRingPainter extends CustomPainter {
  const _FocusPomodoroRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final bgPaint = Paint()
      ..color = AppColors.periwinkle.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = AppColors.periwinkle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusPomodoroRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FocusWeeklyStatsPainter extends CustomPainter {
  const _FocusWeeklyStatsPainter({
    required this.growFactor,
    required this.stats,
  });

  final double growFactor;
  final List<(String label, int ml, double ratio)> stats;

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;
    final barWidth = (size.width / (stats.length * 1.9)).clamp(14.0, 24.0);
    final spacing = size.width / stats.length;
    final bottomY = size.height - 22;
    final maxBarH = size.height - 34;

    final goalY = bottomY - maxBarH * 0.88;
    canvas.drawLine(
      Offset(0, goalY),
      Offset(size.width, goalY),
      Paint()
        ..color = AppColors.cardBorder
        ..strokeWidth = 1.2,
    );

    for (int i = 0; i < stats.length; i++) {
      final (label, _, ratio) = stats[i];
      final x = spacing * i + (spacing - barWidth) / 2;
      final animatedRatio = (ratio * growFactor).clamp(0.05, 1.0);
      final h = math.max(6.0, maxBarH * animatedRatio);
      final isToday = i == stats.length - 1;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottomY - h, barWidth, h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = isToday
              ? AppColors.cyanVivid
              : (ratio >= 0.9 ? AppColors.freshMint : AppColors.deepSky),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 10.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? AppColors.oceanBlue : AppColors.mutedGrey,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x + (barWidth - tp.width) / 2, bottomY + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FocusWeeklyStatsPainter oldDelegate) =>
      oldDelegate.growFactor != growFactor || oldDelegate.stats != stats;
}
