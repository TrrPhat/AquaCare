import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/common/aqua_svg_icon.dart';
import '../../widgets/interactive/interactive_panel.dart';
import '../../widgets/mascot/aqua_mascot_wave_vessel.dart';

/// Tab 2: Full-screen Sunny Cream AquaKids gamified world with Mascot Shop, Bottle Sticker Preview,
/// 10-question SDG 6 Quiz & Parent Gate Customization.
class KidsTabScreen extends StatefulWidget {
  const KidsTabScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<KidsTabScreen> createState() => _KidsTabScreenState();
}

class _KidsTabScreenState extends State<KidsTabScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _jumpController;
  bool _floatInitialized = false;
  int _starRewardCount = 0;
  int _confettiKey = 0;

  static const List<Color> _cupPalette = [
    Color(0xFF00C2EC),
    Color(0xFF4ED8F5),
    Color(0xFF52D681),
    Color(0xFFFFC93C),
    Color(0xFF8E9AFE),
    Color(0xFFFF8A3C),
    Color(0xFFF472B6),
    Color(0xFF2CC8AE),
    Color(0xFF3BB8ED),
    Color(0xFFFFB703),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_floatInitialized) {
      _floatInitialized = true;
      if (AquaMotion.allowInfinite(context)) {
        _floatController.repeat(reverse: true);
      } else {
        _floatController.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void _feedMascot() {
    HapticFeedback.mediumImpact();
    widget.controller.feedKidsMascot();
    setState(() {
      _starRewardCount++;
      if (widget.controller.kidsCups >= widget.controller.kidsGoalCups) {
        _confettiKey++;
      }
    });
    _jumpController.forward(from: 0.0);
  }

  void _openQuizSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuizSheetBody(controller: widget.controller),
    );
  }

  void _openMascotShopSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            final c = widget.controller;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Cửa hàng phụ kiện Mascot',
                          style: AppTypography.cardTitle(isKids: true),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.starAmber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '★ ${c.kidsStars} sao',
                          style: AppTypography.rowTitle(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dùng Sao Vàng mở khóa và mặc đồ cho Bé Giọt Nước nhé!',
                    style: AppTypography.cardBody(),
                  ),
                  const SizedBox(height: 12),
                  ...AquaMascotAccessory.shopItems.map((item) {
                    final unlocked = c.unlockedMascotItems.contains(item.name);
                    final equipped = c.equippedMascotItem == item.name;
                    final canAfford = c.kidsStars >= item.costStars;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: equipped
                            ? AppColors.kidsCream
                            : AppColors.pastelMist,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: equipped
                                ? AppColors.starAmber
                                : AppColors.cardBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          title: Text(
                            item.name,
                            style: AppTypography.rowTitle(),
                          ),
                          subtitle: Text(
                            unlocked
                                ? (equipped
                                      ? 'Đang mặc cho Mascot'
                                      : 'Đã sở hữu')
                                : 'Giá: ${item.costStars} Sao Vàng',
                            style: AppTypography.cardBody(),
                          ),
                          trailing: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: equipped
                                  ? AppColors.emerald
                                  : (unlocked || canAfford
                                        ? AppColors.sunnyButter
                                        : AppColors.cardBorder),
                              foregroundColor: equipped
                                  ? AppColors.pureWhite
                                  : AppColors.navyInk,
                            ),
                            onPressed: equipped || (!unlocked && !canAfford)
                                ? null
                                : () => c.equipMascotItem(
                                    item.name,
                                    item.costStars,
                                  ),
                            child: Text(
                              equipped
                                  ? 'Đang dùng'
                                  : (unlocked
                                        ? 'Mặc ngay'
                                        : 'Đổi ${item.costStars}★'),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openHygieneMissionsSheet(BuildContext context) {
    const steps = [
      '1. Làm ướt tay & tắt vòi nước',
      '2. Xoa xà phòng tạo bọt',
      '3. Chà mu bàn tay & kẽ ngón',
      '4. Chà đầu ngón tay & ngón cái',
      '5. Xả sạch nhanh dưới vòi',
      '6. Khóa chặt vòi & lau khô',
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            final mins = (widget.controller.brushSecondsLeft ~/ 60).toString();
            final secs = (widget.controller.brushSecondsLeft % 60)
                .toString()
                .padLeft(2, '0');
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhiệm vụ khóa vòi & rửa tay',
                    style: AppTypography.cardTitle(isKids: true),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.kidsCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.kidsBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Đánh răng 2 phút khóa vòi ($mins:$secs)',
                            style: AppTypography.rowTitle(),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.sunnyButter,
                            foregroundColor: AppColors.navyInk,
                          ),
                          onPressed: widget.controller.toggleBrushTimer,
                          child: Text(
                            widget.controller.brushRunning ? 'Dừng' : 'Bắt đầu',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(steps.length, (i) {
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.emerald,
                      title: Text(steps[i], style: AppTypography.cardBody()),
                      value: widget.controller.handwashSteps[i],
                      onChanged: (_) => widget.controller.toggleHandwashStep(i),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openComicSheet(BuildContext context) {
    const pages = [
      'Trang 1: Giọt Nước Tí Hon rơi từ đám mây xanh xuống dòng suối mát.',
      'Trang 2: Bé đi qua nhà máy lọc nước sạch để trở nên tinh khiết.',
      'Trang 3: Bé Giọt Nước chạy vào bình cá nhân của Bé An đến trường!',
      'Trang 4: Bé An khóa vòi nước cẩn thận — Giọt Nước nhận vương miện!',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            final idx = widget.controller.comicPageIndex;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Truyện tranh Hành trình Giọt Nước (${idx + 1}/4)',
                    style: AppTypography.cardTitle(isKids: true),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: AquaSvg(
                        idx == 3
                            ? 'assets/svg/kids/mascot_hiep_si.svg'
                            : 'assets/svg/kids/mascot_nhac_uong_nuoc.svg',
                        key: ValueKey(idx),
                        width: 96,
                        height: 108,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(pages[idx], style: AppTypography.rowTitle()),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: idx > 0
                              ? () => widget.controller.setComicPage(idx - 1)
                              : null,
                          child: const Text('← Trang trước'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.sunnyButter,
                            foregroundColor: AppColors.navyInk,
                          ),
                          onPressed: idx < 3
                              ? () => widget.controller.setComicPage(idx + 1)
                              : () => widget.controller.setComicPage(0),
                          child: Text(idx < 3 ? 'Trang sau →' : 'Đọc lại'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openBadgesAndStickersSheet(BuildContext context) {
    const badgeTitles = [
      '6 Cốc Nước',
      'Khóa Vòi',
      'Sao Ngoan',
      'Rửa Tay',
      'Bảo Vệ Biển',
    ];
    const stickers = ['💧 Giọt nước', '⭐ Ngôi sao', '🐳 Cá voi', '🌿 Mầm xanh'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kho Huy hiệu & Dán Sticker Bình nước',
                    style: AppTypography.cardTitle(isKids: true),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (i) {
                      return Expanded(
                        child: Column(
                          children: [
                            AquaSvg(
                              'assets/svg/kids/kids_badge_$i.svg',
                              width: 44,
                              height: 44,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              badgeTitles[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.5,
                                color: AppColors.navyInk,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  _BottleStickerPreview(
                    kidsName: widget.controller.kidsName,
                    stickerIds: widget.controller.bottleStickers,
                    cups: widget.controller.kidsCups,
                    goalCups: widget.controller.kidsGoalCups,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Nhãn dán trang trí bình của ${widget.controller.kidsName}:',
                    style: AppTypography.rowTitle(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(stickers.length, (i) {
                      return AquaChoiceChip(
                        label: stickers[i],
                        selected: widget.controller.bottleStickers.contains(i),
                        selectedColor: AppColors.sunnyButter,
                        selectedTextColor: AppColors.navyInk,
                        onTap: () => widget.controller.toggleBottleSticker(i),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openParentGateSheet(BuildContext context) {
    final pinCtrl = TextEditingController();
    final rng = math.Random();
    final factorA = 3 + rng.nextInt(6); // 3..8
    final factorB = 3 + rng.nextInt(5); // 3..7
    final expectedAnswer = (factorA * factorB).toString();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            final c = widget.controller;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.parentGateUnlocked
                        ? 'Góc phụ huynh (đã mở khóa)'
                        : 'Cổng phụ huynh ($factorA × $factorB = ?)',
                    style: AppTypography.cardTitle(isKids: true),
                  ),
                  const SizedBox(height: 8),
                  if (!c.parentGateUnlocked) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.kidsCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.kidsBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.pinInput.isEmpty
                                  ? 'Nhập kết quả phép tính hoặc mã PIN 4 số...'
                                  : c.pinInput,
                              style: AppTypography.cardTitle(isKids: true),
                            ),
                          ),
                          IconButton(
                            onPressed: c.clearPin,
                            icon: const Icon(
                              Icons.backspace_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            '1',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                            '8',
                            '9',
                            '0',
                          ].map((d) {
                            return SizedBox(
                              width: 52,
                              height: 40,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => c.appendPinDigit(
                                  d,
                                  expectedChallengeAnswer: expectedAnswer,
                                ),
                                child: Text(d),
                              ),
                            );
                          }).toList(),
                    ),
                  ] else ...[
                    Material(
                      color: AppColors.kidsCream,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Mục tiêu cốc/ngày của ${c.kidsName}: ${c.kidsGoalCups} cốc',
                                style: AppTypography.rowTitle(),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  c.setKidsGoalCups(c.kidsGoalCups - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            IconButton(
                              onPressed: () =>
                                  c.setKidsGoalCups(c.kidsGoalCups + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Giới hạn nhắc trước 20:30 tối',
                        style: AppTypography.rowTitle(),
                      ),
                      value: c.morningReminder,
                      activeTrackColor: AppColors.emerald,
                      onChanged: (v) => c.toggleReminder(0, v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Gửi báo cáo tuần cho bố mẹ',
                        style: AppTypography.rowTitle(),
                      ),
                      value: c.watchSyncEnabled,
                      activeTrackColor: AppColors.emerald,
                      onChanged: c.toggleWatchSync,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pinCtrl,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  'Đổi PIN mới (hiện tại: ${c.parentPin})',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                          ),
                          onPressed: () {
                            if (pinCtrl.text.trim().length == 4) {
                              c.updateParentPin(pinCtrl.text);
                              pinCtrl.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã cập nhật mã PIN phụ huynh: ${c.parentPin}',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text('Lưu PIN'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.oceanBlue,
                          foregroundColor: AppColors.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          c.clearPin();
                          c.setRole(AquaRole.household);
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Thoát chế độ trẻ em → Về giao diện phụ huynh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(pinCtrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final goalCups = c.kidsGoalCups > 0 ? c.kidsGoalCups : 6;
    final kidsSlices = List.generate(
      c.kidsCups.clamp(0, goalCups),
      (i) => AquaLiquidSlice(
        fraction: 1.0 / goalCups,
        color: _cupPalette[i % _cupPalette.length],
      ),
    );
    final kidsFraction = (c.kidsCups / goalCups).clamp(0.0, 1.0);

    return Container(
      color: AppColors.kidsCream,
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hành tinh ${c.kidsName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.pageTitle().copyWith(fontSize: 21),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.starAmber,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AnimatedIntText(
                          value: c.kidsStars,
                          formatter: (v) => '★ $v sao',
                          style: AppTypography.metricLabel(AppColors.navyInk)
                              .copyWith(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BouncyPressable(
                        child: Material(
                          color: AppColors.pureWhite,
                          shape: const StadiumBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openParentGateSheet(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 15,
                                    color: AppColors.navyInk,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Phụ huynh',
                                    style: TextStyle(
                                      fontFamily: AppTypography.bodyFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                      color: AppColors.navyInk,
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
                  const SizedBox(height: 16),

                  // Borderless Hero Mascot Wave Stage
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sunnyTile,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            AquaMascotAccessory.badgeDisplayFor(
                              c.equippedMascotItem,
                            ),
                            style: AppTypography.metricLabel(AppColors.navyInk),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FloatingRewardHost(
                          triggerCount: _starRewardCount,
                          rewardText: '+10 ★ ✨',
                          backgroundColor: AppColors.starAmber,
                          textColor: AppColors.navyInk,
                          child: GestureDetector(
                            onTap: _feedMascot,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                _floatController,
                                _jumpController,
                              ]),
                              builder: (_, child) {
                                final idleY = -5.0 *
                                    Curves.easeInOut.transform(
                                      _floatController.value,
                                    );
                                final jt = _jumpController.value;
                                final jumpY = jt > 0
                                    ? -18.0 * math.sin(jt * math.pi)
                                    : 0.0;
                                final jumpScale = jt > 0
                                    ? 1.0 + 0.14 * math.sin(jt * math.pi)
                                    : 1.0;
                                return Transform.translate(
                                  offset: Offset(0, idleY + jumpY),
                                  child: Transform.scale(
                                    scale: jumpScale,
                                    child: child,
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 158,
                                height: 170,
                                child: AquaMascotWaveVessel(
                                  mascotId: 'giot_nuoc',
                                  slices: kidsSlices,
                                  totalFractionOverride: kidsFraction,
                                  accessoryName: c.equippedMascotItem,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.kidsCups >= c.kidsGoalCups
                              ? 'Bé Giọt Nước đã đầy ắp năng lượng! 🎉'
                              : 'Bé Giọt Nước Cấp 5 đang mỉm cười!',
                          textAlign: TextAlign.center,
                          style: AppTypography.cardTitle(isKids: true),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hôm nay bé đã uống ${c.kidsCups} / ${c.kidsGoalCups} cốc nước',
                          style: AppTypography.cardBody(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: List.generate(c.kidsGoalCups, (i) {
                            final filled = i < c.kidsCups;
                            final cupCol = _cupPalette[i % _cupPalette.length];
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: i < c.kidsGoalCups - 1 ? 6 : 0,
                                ),
                                child: AnimatedScale(
                                  scale: filled ? 1.0 : 0.94,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 240),
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: filled
                                          ? cupCol
                                          : AppColors.silhouetteGrey,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        BouncyPressable(
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.sunnyButter,
                                foregroundColor: AppColors.navyInk,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _feedMascot,
                              child: const Text(
                                '+ Cho Giọt Nước uống 1 cốc (+10 ★)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.bodyFont,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.sunnyTile,
                              foregroundColor: AppColors.navyInk,
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () => _openMascotShopSheet(context),
                            icon: const Icon(Icons.storefront_rounded, size: 18),
                            label: const Text(
                              'Cửa hàng phụ kiện Mascot',
                              style: TextStyle(
                                fontFamily: AppTypography.bodyFont,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BottleStickerPreview(
                    kidsName: c.kidsName,
                    stickerIds: c.bottleStickers,
                    cups: c.kidsCups,
                    goalCups: c.kidsGoalCups,
                    onTap: () => _openBadgesAndStickersSheet(context),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Thử thách & trò chơi của bé',
                    style: AppTypography.cardTitle(isKids: true),
                  ),
                  const SizedBox(height: 10),
                  StaggeredEntrance(
                    index: 1,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: BouncyPressable(
                              child: _KidsTileCard(
                                icon: Icons.quiz_rounded,
                                accent: AppColors.starAmber,
                                surfaceColor: AppColors.sunnyTile,
                                title: 'Đố vui nước sạch',
                                subtitle: 'Câu ${c.kidsQuizIndex + 1}/10 • +20 ★',
                                onTap: () => _openQuizSheet(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BouncyPressable(
                              child: _KidsTileCard(
                                icon: Icons.clean_hands_rounded,
                                accent: AppColors.emerald,
                                surfaceColor: AppColors.mintTile,
                                title: 'Khóa vòi & rửa tay',
                                subtitle: '6 bước sạch sẽ',
                                onTap: () => _openHygieneMissionsSheet(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StaggeredEntrance(
                    index: 2,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: BouncyPressable(
                              child: _KidsTileCard(
                                icon: Icons.menu_book_rounded,
                                accent: AppColors.cyanVivid,
                                surfaceColor: AppColors.cyanTile,
                                title: 'Truyện Giọt Nước',
                                subtitle: 'Trang ${c.comicPageIndex + 1}/4',
                                onTap: () => _openComicSheet(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BouncyPressable(
                              child: _KidsTileCard(
                                icon: Icons.workspace_premium_rounded,
                                accent: AppColors.periwinkle,
                                surfaceColor: AppColors.lavenderCard,
                                title: 'Huy hiệu & nhãn dán',
                                subtitle: '${c.bottleStickers.length} nhãn đã dán',
                                onTap: () => _openBadgesAndStickersSheet(context),
                              ),
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
          Positioned.fill(
            child: AquaConfettiOverlay(triggerKey: _confettiKey),
          ),
        ],
      ),
    );
  }
}

class _BottleStickerPreview extends StatelessWidget {
  const _BottleStickerPreview({
    required this.kidsName,
    required this.stickerIds,
    required this.cups,
    required this.goalCups,
    this.onTap,
  });

  final String kidsName;
  final Set<int> stickerIds;
  final int cups;
  final int goalCups;
  final VoidCallback? onTap;

  static const _stickerGlyphs = ['💧', '⭐', '🐳', '🌿'];

  @override
  Widget build(BuildContext context) {
    final activeGlyphs = stickerIds
        .where((id) => id >= 0 && id < _stickerGlyphs.length)
        .map((id) => _stickerGlyphs[id])
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F1F2C),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.cyanTile,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.cyanVivid,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        children: activeGlyphs.isEmpty
                            ? const [Text('🫗', style: TextStyle(fontSize: 20))]
                            : activeGlyphs
                                  .map(
                                    (g) => Text(
                                      g,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  )
                                  .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bình nước cá nhân của $kidsName',
                        style: AppTypography.rowTitle(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeGlyphs.isEmpty
                            ? 'Chưa dán sticker nào — Chạm để trang trí!'
                            : 'Đang dán ${activeGlyphs.join(" ")} ($cups/$goalCups cốc)',
                        style: AppTypography.cardBody(),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizSheetBody extends StatefulWidget {
  const _QuizSheetBody({required this.controller});

  final AquaUiController controller;

  @override
  State<_QuizSheetBody> createState() => _QuizSheetBodyState();
}

class _QuizSheetBodyState extends State<_QuizSheetBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _shakeController]),
      builder: (_, _) {
        final q = widget.controller.currentQuizQuestion;
        final selectedIndex = widget.controller.kidsSelectedQuizOption;
        final shakeX = _shakeController.isAnimating
            ? math.sin(_shakeController.value * math.pi * 4) * 6.0
            : 0.0;
        final answeredRight = selectedIndex == q.correctIndex;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đố vui nước sạch (+20 ★)',
                      style: AppTypography.cardTitle(isKids: true),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.kidsCream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.kidsBorder),
                    ),
                    child: Text(
                      'Câu ${widget.controller.kidsQuizIndex + 1}/10',
                      style: AppTypography.metricLabel(AppColors.navyInk),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(q.question, style: AppTypography.cardBody()),
              const SizedBox(height: 12),
              ...List.generate(q.options.length, (i) {
                final selected = selectedIndex == i;
                final correct = i == q.correctIndex;
                final bg = !selected
                    ? AppColors.pastelMist
                    : (correct ? AppColors.freshMint : AppColors.softCoral);
                final dx = selected && !correct ? shakeX : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: AnimatedScale(
                      scale: selected && correct ? 1.02 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Material(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            widget.controller.selectQuizOption(i);
                            if (!correct) {
                              _shakeController.forward(from: 0.0);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    q.options[i],
                                    style: AppTypography.rowTitle(
                                      color: selected
                                          ? AppColors.pureWhite
                                          : AppColors.navyInk,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (answeredRight) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.freshMint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🎉 Chính xác! ${q.explanation}',
                    style: AppTypography.cardBody(color: AppColors.emerald),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sunnyButter,
                      foregroundColor: AppColors.navyInk,
                    ),
                    onPressed: widget.controller.nextQuizQuestion,
                    child: const Text('Câu tiếp theo →'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _KidsTileCard extends StatelessWidget {
  const _KidsTileCard({
    required this.icon,
    required this.accent,
    required this.surfaceColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final Color surfaceColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
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
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(height: 12),
                Text(title, style: AppTypography.rowTitle()),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.cardBody(
                    color: AppColors.navyInk.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
