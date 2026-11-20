import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/interactive/interactive_panel.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';
import '../../widgets/mascot/aqua_mascot_collection_modal.dart';
import 'hydration_personalizer_flow.dart';

/// Tab 4: Personal Profile & Settings Hub.
/// - Clean section hierarchy with unified Vietnamese Sentence case.
/// - Role-adaptive summary metrics & quick in-place Profile Edit sheet.
class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key, required this.controller});

  final AquaUiController controller;

  Future<void> _shareWeeklyReport(BuildContext context) async {
    final text = controller.buildWeeklyShareReport();
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Báo cáo sức khỏe & nước sạch AquaCare (SDG 6)',
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép báo cáo tuần AquaCare vào bộ nhớ tạm!'),
          ),
        );
      }
    }
  }

  void _openEditProfileSheet(BuildContext context) {
    final c = controller;
    final nameCtrl = TextEditingController(text: c.userName);
    final kidsCtrl = TextEditingController(text: c.kidsName);
    final pinCtrl = TextEditingController(text: c.parentPin);
    double tempWeight = c.bodyWeightKg.clamp(40, 110);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final estGoal = ((tempWeight * 33) / 50).round() * 50;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.homeIndicator,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Chỉnh sửa hồ sơ cá nhân',
                        style: AppTypography.cardTitle()),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị của bạn',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cân nặng: ${tempWeight.round()} kg',
                          style: AppTypography.rowTitle(),
                        ),
                        Text(
                          'Mục tiêu: $estGoal ml/ngày',
                          style: AppTypography.metricLabel(AppColors.oceanBlue),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempWeight,
                      min: 40,
                      max: 110,
                      divisions: 70,
                      activeColor: AppColors.skyCyan,
                      onChanged: (v) => setSheetState(() => tempWeight = v),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: kidsCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tên gọi của bé (góc AquaKids)',
                        prefixIcon: Icon(Icons.child_care_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinCtrl,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mã PIN phụ huynh (4 chữ số)',
                        counterText: '',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              c.setStage(AppFlowStage.setup);
                            },
                            child: const Text('Thiết lập lại hồ sơ'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.skyCyan,
                              foregroundColor: AppColors.pureWhite,
                            ),
                            onPressed: () {
                              c.updateProfileInfo(
                                userName: nameCtrl.text,
                                kidsName: kidsCtrl.text,
                                bodyWeightKg: tempWeight,
                                parentPin: pinCtrl.text,
                              );
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã lưu thông tin hồ sơ ✓'),
                                ),
                              );
                            },
                            child: const Text('Lưu thay đổi ✓'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      kidsCtrl.dispose();
      pinCtrl.dispose();
    });
  }

  Future<void> _confirmResetDefaults(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Đặt lại dữ liệu ứng dụng?'),
          content: const Text(
            'Các chỉ số nước uống hôm nay, lịch sử đo chất lượng nước và tiến độ của bé sẽ được đặt lại về ban đầu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.softCoral,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Đặt lại'),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await controller.resetAllUserData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đặt lại dữ liệu trên thiết bị ✓')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final weeklyStats = c.last7DaysStats;
    final isHousehold = c.role == AquaRole.household;

    return Container(
      color: AppColors.iceCanvas,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cá nhân & cài đặt',
                style: AppTypography.pageTitle().copyWith(fontSize: 21),
              ),
              const SizedBox(height: 2),
              Text(
                'Quản lý hồ sơ, linh vật AquaCare & lịch nhắc nhở hằng ngày',
                style: AppTypography.cardBody(),
              ),
              const SizedBox(height: 16),

              // 1. Borderless User Profile + Mascot Card
              StaggeredEntrance(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D0F1F2C),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      BouncyPressable(
                        child: GestureDetector(
                          onTap: () =>
                              AquaMascotCollectionModal.show(context, c),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppColors.cyanTile,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: AquaMascotVectorArt(
                                mascotId: c.selectedMascotId,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.userName, style: AppTypography.cardTitle()),
                            const SizedBox(height: 2),
                            Text(
                              '${c.role.label} • Mục tiêu ${c.dailyGoalMl} ml/ngày',
                              style: AppTypography.cardBody(),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pillGrey,
                          foregroundColor: AppColors.oceanBlue,
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _openEditProfileSheet(context),
                        child: const Text(
                          'Sửa',
                          style: TextStyle(
                            fontFamily: AppTypography.bodyFont,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Role-Adaptive 3 Mini Stat Highlights (Pastel Borderless)
              StaggeredEntrance(
                index: 1,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: isHousehold
                        ? [
                            _MiniStatCard(
                              label: 'Chỉ số TDS',
                              value: '${c.tdsPpm} ppm',
                              accent: AppColors.emerald,
                              surfaceColor: AppColors.mintTile,
                            ),
                            const SizedBox(width: 8),
                            _MiniStatCard(
                              label: 'Tiêu thụ tháng',
                              value:
                                  '${c.monthlyCubicMeters.toStringAsFixed(0)} m³',
                              accent: AppColors.oceanBlue,
                              surfaceColor: AppColors.cyanTile,
                            ),
                            const SizedBox(width: 8),
                            _MiniStatCard(
                              label: c.kidsName,
                              value: '${c.kidsCups}/${c.kidsGoalCups} cốc',
                              accent: AppColors.starAmber,
                              surfaceColor: AppColors.sunnyTile,
                            ),
                          ]
                        : [
                            _MiniStatCard(
                              label: 'Chuỗi ngày',
                              value: '${c.streakDays} ngày',
                              accent: AppColors.starAmber,
                              surfaceColor: AppColors.sunnyTile,
                            ),
                            const SizedBox(width: 8),
                            _MiniStatCard(
                              label: 'Giảm nhựa',
                              value: '${c.plasticSaved} chai',
                              accent: AppColors.emerald,
                              surfaceColor: AppColors.mintTile,
                            ),
                            const SizedBox(width: 8),
                            _MiniStatCard(
                              label: 'Hôm nay',
                              value: '${c.intakePercent}%',
                              accent: AppColors.oceanBlue,
                              surfaceColor: AppColors.cyanTile,
                            ),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Compact 7-day Hydration Overview
              StaggeredEntrance(
                index: 2,
                child: InteractivePanel(
                  title: 'Thống kê cấp ẩm 7 ngày',
                  badgeText: 'TB ${c.weeklyAverageMl} ml/ngày',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutQuart,
                    builder: (_, t, _) {
                      return SizedBox(
                        height: 104,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _WeeklyStatsPainter(
                            growFactor: t,
                            stats: weeklyStats,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Mode Switcher Section
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Chế độ sử dụng',
                  style: AppTypography.sectionCaption(color: AppColors.navyInk),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F1F2C),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Các tab điều hướng và trợ lý AI tự động tối ưu theo đối tượng sử dụng.',
                      style: AppTypography.cardBody(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AquaChoiceChip(
                          label: 'SV / Đi làm',
                          selected: c.role == AquaRole.studentWorker,
                          selectedColor: AppColors.cyanVivid,
                          onTap: () => c.setRole(AquaRole.studentWorker),
                        ),
                        AquaChoiceChip(
                          label: 'Hộ gia đình',
                          selected: c.role == AquaRole.household,
                          selectedColor: AppColors.emerald,
                          onTap: () => c.setRole(AquaRole.household),
                        ),
                        AquaChoiceChip(
                          label: 'Giao máy cho bé',
                          selected: c.role == AquaRole.kids,
                          selectedColor: AppColors.sunnyButter,
                          selectedTextColor: AppColors.navyInk,
                          onTap: c.enterKidsMode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Personal Hydration Goal & Smart Reminders
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Mục tiêu & nhắc nhở thông minh',
                  style: AppTypography.sectionCaption(color: AppColors.navyInk),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyanTile,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.pureWhite,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            color: AppColors.cyanVivid,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tính mục tiêu uống nước cá nhân',
                                style: AppTypography.rowTitle(),
                              ),
                              Text(
                                '${c.genderProfile?.label ?? "Chưa chọn giới tính"} • ${c.bodyWeightKg.round()} kg • ${c.activityLevel.label} • ${c.climateLevel.label}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.cardBody(
                                  color: AppColors.navyInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.pureWhite,
                              foregroundColor: AppColors.oceanBlue,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                AquaWavePageRoute<void>(
                                  builder: (_) => AquaHydrationPersonalizerScreen(
                                    controller: c,
                                    initialStage: 0,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Lời nhắc thông minh',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.cyanVivid,
                              foregroundColor: AppColors.pureWhite,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                AquaWavePageRoute<void>(
                                  builder: (_) => AquaHydrationPersonalizerScreen(
                                    controller: c,
                                    initialStage: 1,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Tính lại mục tiêu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. Reminder & Smart Device Settings
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Lịch nhắc & thiết bị',
                  style: AppTypography.sectionCaption(color: AppColors.navyInk),
                ),
              ),
              Container(
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
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: Text(
                          'Nhắc uống nước buổi sáng',
                          style: AppTypography.rowTitle(),
                        ),
                        value: c.morningReminder,
                        activeTrackColor: AppColors.cyanVivid,
                        onChanged: (v) => c.toggleReminder(0, v),
                      ),
                      SwitchListTile.adaptive(
                        title: Text(
                          'Nhắc uống nước buổi chiều',
                          style: AppTypography.rowTitle(),
                        ),
                        value: c.afternoonReminder,
                        activeTrackColor: AppColors.cyanVivid,
                        onChanged: (v) => c.toggleReminder(1, v),
                      ),
                      SwitchListTile.adaptive(
                        title: Text(
                          'Nhắc uống nước buổi tối',
                          style: AppTypography.rowTitle(),
                        ),
                        value: c.eveningReminder,
                        activeTrackColor: AppColors.cyanVivid,
                        onChanged: (v) => c.toggleReminder(2, v),
                      ),
                      SwitchListTile.adaptive(
                        title: Text(
                          'Đồng bộ đồng hồ thông minh & sức khỏe',
                          style: AppTypography.rowTitle(),
                        ),
                        value: c.watchSyncEnabled,
                        activeTrackColor: AppColors.freshMint,
                        onChanged: c.toggleWatchSync,
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.cyanVivid,
                        ),
                        title: Text(
                          'Kiểm tra thông báo nhắc uống nước',
                          style: AppTypography.rowTitle(),
                        ),
                        subtitle: Text(
                          'Gửi thông báo nhanh để kiểm tra âm báo trên thiết bị',
                          style: AppTypography.cardBody(),
                        ),
                        trailing: const Icon(Icons.send_rounded, size: 18),
                        onTap: () async {
                          await c.sendTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '💧 Đã gửi thông báo nhắc uống nước!',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Cloud Sync, Share & Account Actions
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Dữ liệu & tài khoản',
                  style: AppTypography.sectionCaption(color: AppColors.navyInk),
                ),
              ),
              Container(
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
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          c.isFirebaseConfigured
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_queue_rounded,
                          color: c.isFirebaseConfigured
                              ? AppColors.emerald
                              : AppColors.oceanBlue,
                        ),
                        title: Text(
                          'Lưu trữ & đồng bộ đám mây',
                          style: AppTypography.rowTitle(),
                        ),
                        subtitle: Text(
                          c.cloudStatusLabel,
                          style: AppTypography.cardBody(),
                        ),
                        trailing: TextButton(
                          onPressed: c.isSyncing
                              ? null
                              : () async {
                                  final synced =
                                      await c.triggerManualCloudSync();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          synced
                                              ? 'Đã đồng bộ dữ liệu lên Firebase Cloud ✓'
                                              : 'Đã lưu an toàn trên thiết bị',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(c.isSyncing ? 'Đang lưu...' : 'Đồng bộ'),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.emerald,
                        ),
                        title: Text(
                          'Chia sẻ báo cáo tuần & SDG 6',
                          style: AppTypography.rowTitle(),
                        ),
                        subtitle: Text(
                          'Xuất tóm tắt cấp ẩm và thành tích giảm chai nhựa',
                          style: AppTypography.cardBody(),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _shareWeeklyReport(context),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.softCoral,
                        ),
                        title: Text(
                          'Đăng xuất tài khoản',
                          style: AppTypography.rowTitle(
                            color: AppColors.softCoral,
                          ),
                        ),
                        onTap: c.signOut,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Collapsible App Info & Local Data Reset
              Container(
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
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.mutedGrey,
                      ),
                      title: Text(
                        'Thông tin ứng dụng & dữ liệu',
                        style: AppTypography.rowTitle(),
                      ),
                      subtitle: Text(
                        'AquaCare v1.0.0 • Nước sạch & Vệ sinh (SDG 6)',
                        style: AppTypography.cardBody(),
                      ),
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.restore_rounded,
                            color: AppColors.softCoral,
                          ),
                          title: Text(
                            'Đặt lại dữ liệu trên thiết bị',
                            style: AppTypography.rowTitle(),
                          ),
                          subtitle: Text(
                            'Xóa nhật ký hiện tại và đặt lại các chỉ số về ban đầu',
                            style: AppTypography.cardBody(),
                          ),
                          onTap: () => _confirmResetDefaults(context),
                        ),
                      ],
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
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.surfaceColor,
  });

  final String label;
  final String value;
  final Color accent;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.metricLabel(accent),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.metricValue(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatsPainter extends CustomPainter {
  _WeeklyStatsPainter({
    required this.growFactor,
    required this.stats,
  });

  final double growFactor;
  final List<(String label, int ml, double ratio)> stats;

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;
    final barW = (size.width / (stats.length * 2.0)).clamp(14.0, 24.0);
    final gap = size.width / stats.length;
    final baseY = size.height - 20;
    final maxH = size.height - 30;

    for (int i = 0; i < stats.length; i++) {
      final (day, _, ratio) = stats[i];
      final x = gap * i + (gap - barW) / 2;
      final isToday = i == stats.length - 1;
      final h = math.max(6.0, maxH * (ratio * growFactor).clamp(0.05, 1.0));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, baseY - h, barW, h),
          const Radius.circular(6),
        ),
        Paint()
          ..color = isToday
              ? AppColors.skyCyan
              : (ratio >= 0.85 ? AppColors.freshMint : AppColors.deepSky),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: day,
          style: TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
            fontSize: 10.5,
            color: isToday ? AppColors.oceanBlue : AppColors.mutedGrey,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + (barW - tp.width) / 2, baseY + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyStatsPainter oldDelegate) =>
      oldDelegate.growFactor != growFactor || oldDelegate.stats != stats;
}
