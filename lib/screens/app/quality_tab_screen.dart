import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/interactive/interactive_panel.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';
import '../../widgets/scanner/aqua_qr_scanner_sheet.dart';

/// Tab 1 (Household): Clean Water Safety (WHO/QCVN per source type + dynamic TDS history),
/// Household WASH Sanitation Checklist + Filter Safety, and Leak / Water-Saving Monitor.
class QualityTabScreen extends StatefulWidget {
  const QualityTabScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<QualityTabScreen> createState() => _QualityTabScreenState();
}

class _QualityTabScreenState extends State<QualityTabScreen> {
  int _subTab = 0; // 0 = Chỉ số nước, 1 = Vệ sinh & lọc, 2 = Tiết kiệm & rò rỉ
  int _confettiKey = 0;

  void _openQrWaterScanner() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AquaQrScannerSheet(
        title: 'Quét mã QR nguồn nước / que thử',
        subtitle:
            'Đưa camera vào mã QR kiểm định nguồn nước, hộp que thử hoặc tem bộ lọc để tự nhập kết quả đo.',
        confirmButtonLabel: 'Lưu kết quả quét ✓',
        accentColor: AppColors.oceanBlue,
        onResultConfirmed: (res) {
          final msg = widget.controller.applyScannedCodeResult(res);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
        },
        onConfirmed: (code) {
          widget.controller.saveWaterTestRecord(
            tds: 29,
            ph: 7.4,
            sourceNote: 'Quét QR ($code)',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Đã quét & lưu kết quả đo mới: TDS 29 ppm • pH 7.4'),
              ),
            );
          }
        },
      ),
    );
  }

  void _openTestWaterSheet() {
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
            final assessment = c.waterSafetyAssessment;
            final tintColor = switch (assessment.status) {
              AquaWaterSafetyStatus.safe => AppColors.mintTile,
              AquaWaterSafetyStatus.caution => AppColors.sunnyTile,
              AquaWaterSafetyStatus.warning => AppColors.coralTile,
            };
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
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
                    Text(
                      'Kiểm tra chất lượng nước (${c.waterSourceType.label})',
                      style: AppTypography.cardTitle(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quét mã QR que thử hoặc nhập chỉ số đo từ bút TDS & pH theo chuẩn WHO / QCVN.',
                      style: AppTypography.cardBody(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _openQrWaterScanner();
                        },
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Mở camera quét mã que thử / nguồn nước',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tintColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.colorize_rounded,
                            color: AppColors.oceanBlue,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${assessment.headline} (${assessment.standardNote})',
                              style: AppTypography.rowTitle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chỉ số TDS: ${c.tdsPpm} ppm (${assessment.standardNote})',
                      style: AppTypography.rowTitle(),
                    ),
                    Slider(
                      value: c.tdsPpm.toDouble().clamp(5.0, 450.0),
                      min: 5,
                      max: 450,
                      divisions: 89,
                      activeColor: assessment.isTdsOk
                          ? AppColors.freshMint
                          : AppColors.softCoral,
                      onChanged: (v) => c.setWaterMetrics(tds: v.round()),
                    ),
                    Text(
                      'Độ pH: ${c.phLevel.toStringAsFixed(1)}',
                      style: AppTypography.rowTitle(),
                    ),
                    Slider(
                      value: c.phLevel.clamp(5.5, 9.0),
                      min: 5.5,
                      max: 9.0,
                      divisions: 35,
                      activeColor: assessment.isPhOk
                          ? AppColors.deepSky
                          : AppColors.softCoral,
                      onChanged: (v) => c.setWaterMetrics(ph: v),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.freshMint,
                          foregroundColor: AppColors.pureWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          c.saveWaterTestRecord(
                            tds: c.tdsPpm,
                            ph: c.phLevel,
                            sourceNote: c.waterSourceType.fullLabel,
                          );
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã lưu kết quả đo: TDS ${c.tdsPpm} ppm • pH ${c.phLevel.toStringAsFixed(1)}',
                              ),
                            ),
                          );
                        },
                        child: const Text('Lưu kết quả đo hôm nay ✓'),
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

  void _openBookingSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        const slots = ['09:00 Sáng mai', '14:00 Chiều mai', '17:30 Cuối tuần'];
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhắc lịch bảo trì bộ lọc nước',
                    style: AppTypography.cardTitle(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kiểm tra bộ lọc & vệ sinh vòi nước uống gia đình.',
                    style: AppTypography.cardBody(),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(slots.length, (i) {
                      return AquaChoiceChip(
                        label: slots[i],
                        selected: widget.controller.selectedTechSlot == i,
                        onTap: () => widget.controller.setSelectedTechSlot(i),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.skyCyan,
                        foregroundColor: AppColors.pureWhite,
                      ),
                      onPressed: () {
                        final chosen = slots[widget.controller.selectedTechSlot];
                        widget.controller.addTechBooking(chosen);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Đã lưu lịch nhắc bảo trì lúc $chosen!'),
                          ),
                        );
                      },
                      child: const Text('Lưu lịch nhắc ✓'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Container(
      color: AppColors.iceCanvas,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nước sạch & vệ sinh',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.pageTitle().copyWith(
                                fontSize: 21,
                              ),
                            ),
                            Text(
                              'An toàn nguồn nước (WHO/QCVN), vệ sinh gia đình & chống rò rỉ',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardBody(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      BouncyPressable(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: AppColors.pureWhite,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _openTestWaterSheet,
                          icon: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 17,
                          ),
                          label: const Text(
                            'Đo mới',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A0F1F2C),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ('Chỉ số nước', 0),
                        ('Vệ sinh & lọc', 1),
                        ('Tiết kiệm & rò rỉ', 2),
                      ].map((tab) {
                        final active = _subTab == tab.$2;
                        return Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _subTab = tab.$2),
                            borderRadius: BorderRadius.circular(999),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 9.5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.cyanVivid
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tab.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.metricLabel(
                                  active
                                      ? AppColors.pureWhite
                                      : AppColors.slateBody,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: AquaSmoothSwitcher(
                      child: KeyedSubtree(
                        key: ValueKey<int>(_subTab),
                        child: switch (_subTab) {
                          0 => _buildTdsOverview(c),
                          1 => _buildSanitationAndFilters(c),
                          _ => _buildBillAndLeak(c),
                        },
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

  Widget _buildTdsOverview(AquaUiController c) {
    final assessment = c.waterSafetyAssessment;
    final bannerColor = switch (assessment.status) {
      AquaWaterSafetyStatus.safe => AppColors.mintTile,
      AquaWaterSafetyStatus.caution => AppColors.sunnyTile,
      AquaWaterSafetyStatus.warning => AppColors.coralTile,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AquaWaterSourceType.values.map((sourceType) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AquaChoiceChip(
                  label: '${sourceType.label} (${sourceType.standardRangeLabel})',
                  selected: c.waterSourceType == sourceType,
                  selectedColor: AppColors.emerald,
                  onTap: () => c.setWaterSourceType(sourceType),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bannerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const AquaMascotVectorArt(
                        mascotId: 'bup_sen',
                        size: 54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assessment.headline,
                              style: AppTypography.cardTitle(),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assessment.detail,
                              style: AppTypography.cardBody(
                                color: AppColors.navyInk.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ParamTile(
                      label: 'TDS (${c.waterSourceType.label})',
                      value: '${c.tdsPpm} ppm',
                      ok: assessment.isTdsOk,
                    ),
                    const SizedBox(width: 10),
                    _ParamTile(
                      label: 'Độ pH',
                      value: c.phLevel.toStringAsFixed(1),
                      ok: assessment.isPhOk,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ParamTile(
                      label: 'Clo dư (ước tính)',
                      value:
                          '${assessment.estimatedChlorineMgL.toStringAsFixed(2)} mg/L',
                      ok: assessment.isChlorineOk,
                    ),
                    const SizedBox(width: 10),
                    _ParamTile(
                      label: 'Độ đục (ước tính)',
                      value:
                          '${assessment.estimatedTurbidityNtu.toStringAsFixed(2)} NTU',
                      ok: assessment.isTurbidityOk,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        InteractivePanel(
          title: 'Biến động TDS theo các lần đo',
          badgeText: assessment.standardNote,
          accentColor: assessment.status == AquaWaterSafetyStatus.safe
              ? AppColors.emerald
              : AppColors.softCoral,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) {
              return SizedBox(
                height: 104,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TdsDynamicChartPainter(
                    drawRatio: t,
                    records: c.waterTestRecords,
                    currentTds: c.tdsPpm,
                    lineColor: assessment.status == AquaWaterSafetyStatus.safe
                        ? AppColors.emerald
                        : AppColors.softCoral,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Lịch sử đo chất lượng nước (${c.waterTestRecords.length})',
          style: AppTypography.cardTitle(),
        ),
        const SizedBox(height: 8),
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
            child: c.waterTestRecords.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Chưa có bản ghi đo nước nào. Nhấn "Đo mới" để thêm!',
                      style: AppTypography.cardBody(),
                    ),
                  )
                : Column(
                    children: c.waterTestRecords.map((rec) {
                      final recAssessment = AquaWaterSafetyAssessment.evaluate(
                        tdsPpm: rec.tdsPpm,
                        phLevel: rec.phLevel,
                        sourceType: c.waterSourceType,
                      );
                      final recSafe =
                          recAssessment.status == AquaWaterSafetyStatus.safe;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          recSafe
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          color:
                              recSafe ? AppColors.emerald : AppColors.softCoral,
                        ),
                        title: Text(
                          'TDS ${rec.tdsPpm} ppm • pH ${rec.phLevel.toStringAsFixed(1)}',
                          style: AppTypography.rowTitle(),
                        ),
                        subtitle: Text(
                          '${rec.dateLabel} • ${rec.sourceNote}',
                          style: AppTypography.cardBody(),
                        ),
                        trailing: IconButton(
                          tooltip: 'Xóa bản ghi',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          onPressed: () => c.deleteWaterTestRecord(rec.id),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSanitationAndFilters(AquaUiController c) {
    final tasks = c.householdSanitationTasks;
    final doneCount = tasks.where((t) => t.completed).length;
    final washRatio = c.householdSanitationProgress;

    const filterStages = [
      (
        'Bộ lọc thô cặn bẩn (Cấp 1)',
        'Ngăn bùn đất, rỉ sét thô • Chu kỳ ~180 ngày',
        180,
      ),
      (
        'Bộ lọc than hoạt tính khử Clo (Cấp 2)',
        'Hấp thụ mùi Clo, màu & chất hữu cơ • ~240 ngày',
        240,
      ),
      (
        'Bộ lọc tinh trầm tích (Cấp 3)',
        'Lọc vi hạt mịn bảo vệ nguồn nước • ~270 ngày',
        270,
      ),
      (
        'Màng lọc chính RO / UF (Cấp 4)',
        'Loại bỏ vi khuẩn & kim loại nặng • ~720 ngày',
        720,
      ),
    ];
    final health = c.roFilterHealth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Household WASH Sanitation Checklist
        InteractivePanel(
          title: 'Checklist vệ sinh nước sạch (WASH)',
          badgeText: '$doneCount/${tasks.length} mục',
          accentColor:
              washRatio >= 1.0 ? AppColors.emerald : AppColors.oceanBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thực hành vệ sinh nước uống, bồn chứa & bồn rửa tay gia đình theo chuẩn SDG 6:',
                style: AppTypography.cardBody(),
              ),
              const SizedBox(height: 10),
              AquaLiquidProgressBar(
                value: washRatio,
                color:
                    washRatio >= 1.0 ? AppColors.emerald : AppColors.cyanVivid,
                backgroundColor: AppColors.pillGrey,
                height: 9,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
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
              children: tasks.map((task) {
                return InkWell(
                  onTap: () {
                    final wasComplete = c.householdSanitationProgress >= 1.0;
                    c.toggleSanitationTask(task.id);
                    if (!wasComplete && c.householdSanitationProgress >= 1.0) {
                      setState(() => _confettiKey++);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: task.completed
                                ? AppColors.emerald
                                : AppColors.pillGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            task.completed
                                ? Icons.check_rounded
                                : Icons.clean_hands_outlined,
                            size: 16,
                            color: task.completed
                                ? AppColors.pureWhite
                                : AppColors.mutedGrey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: task.completed
                                ? AppColors.mintTile
                                : AppColors.iceCanvas,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            task.cadenceLabel,
                            style: AppTypography.metricLabel(
                              task.completed
                                  ? AppColors.emerald
                                  : AppColors.oceanBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. Clean Water Filter Safety (Optional, Unified Single Progress Indicator)
        Text(
          'An toàn bộ lọc nước uống (tùy chọn)',
          style: AppTypography.cardTitle(),
        ),
        const SizedBox(height: 2),
        Text(
          'Theo dõi định kỳ nếu gia đình sử dụng máy lọc để giữ nước sạch và tránh tích tụ vi khuẩn.',
          style: AppTypography.cardBody(),
        ),
        const SizedBox(height: 10),
        ...List.generate(4, (i) {
          final pct = health[i];
          final low = pct <= 20;
          final barColor = low ? AppColors.softCoral : AppColors.freshMint;
          final daysRemaining = ((pct / 100.0) * filterStages[i].$3).round();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: low ? AppColors.coralTile : AppColors.pureWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F1F2C),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          filterStages[i].$1,
                          style: AppTypography.rowTitle(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: low ? AppColors.pureWhite : AppColors.iceCanvas,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$pct% • ~$daysRemaining ngày',
                          style: AppTypography.metricLabel(
                            low ? AppColors.softCoral : AppColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(filterStages[i].$2, style: AppTypography.cardBody()),
                  const SizedBox(height: 10),
                  AquaLiquidProgressBar(
                    value: pct / 100.0,
                    color: barColor,
                    backgroundColor:
                        low ? AppColors.pureWhite : AppColors.pillGrey,
                    height: 9,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BouncyPressable(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              low ? AppColors.pureWhite : AppColors.cyanTile,
                          foregroundColor: AppColors.oceanBlue,
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          c.resetRoFilter(i);
                          setState(() => _confettiKey++);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text(
                                'Đã cập nhật ${filterStages[i].$1} về 100%!',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.cleaning_services_rounded, size: 15),
                        label: const Text('Đã vệ sinh / thay mới'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.oceanBlue,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _openBookingSheet,
            icon: const Icon(Icons.event_available_rounded, size: 18),
            label: const Text('Lên lịch nhắc bảo trì định kỳ'),
          ),
        ),
        if (c.techBookings.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Lịch nhắc bảo trì (${c.techBookings.length})',
            style: AppTypography.cardTitle(),
          ),
          const SizedBox(height: 8),
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
                children: c.techBookings.map((b) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      b.completed
                          ? Icons.task_alt_rounded
                          : Icons.event_note_rounded,
                      color:
                          b.completed ? AppColors.emerald : AppColors.cyanVivid,
                    ),
                    title: Text(b.slotLabel, style: AppTypography.rowTitle()),
                    subtitle: Text(
                      b.completed ? 'Đã hoàn tất bảo trì ✓' : b.createdAtLabel,
                      style: AppTypography.cardBody(),
                    ),
                    trailing: b.completed
                        ? null
                        : TextButton(
                            onPressed: () {
                              c.completeTechBooking(b.id);
                              setState(() => _confettiKey++);
                            },
                            child: const Text('Hoàn tất'),
                          ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillAndLeak(AquaUiController c) {
    final billFormatted = AquaWaterBillEntry.formatVnd(c.currentWaterBillVnd);
    final m3Label = '${c.monthlyCubicMeters.toStringAsFixed(0)} m³';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.isLeakSuspected) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.coralTile,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.pureWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_damage_rounded,
                    color: AppColors.softCoral,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cảnh báo nghi rò rỉ đường ống! Sản lượng $m3Label vượt mức trung bình gia đình (18 m³).',
                    style: AppTypography.rowTitle(color: AppColors.navyInk),
                  ),
                ),
              ],
            ),
          ),
        ],
        InteractivePanel(
          title: 'Phân bổ & hóa đơn nước tháng này',
          badgeText: '$m3Label • $billFormatted',
          accentColor:
              c.isLeakSuspected ? AppColors.softCoral : AppColors.oceanBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chỉ số đồng hồ tháng: $m3Label',
                      style: AppTypography.rowTitle(),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        c.updateMonthlyWaterMeter(c.monthlyCubicMeters - 1),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        c.updateMonthlyWaterMeter(c.monthlyCubicMeters + 1),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                ],
              ),
              Slider(
                value: c.monthlyCubicMeters.clamp(2.0, 35.0),
                min: 2.0,
                max: 35.0,
                divisions: 33,
                activeColor: c.isLeakSuspected
                    ? AppColors.softCoral
                    : AppColors.oceanBlue,
                onChanged: c.updateMonthlyWaterMeter,
              ),
              const SizedBox(height: 6),
              const _AllocationBar(
                label: 'Tắm giặt & Vệ sinh cá nhân',
                ratio: 0.48,
                color: AppColors.skyCyan,
              ),
              const SizedBox(height: 8),
              const _AllocationBar(
                label: 'Nấu ăn & Nước uống sạch',
                ratio: 0.28,
                color: AppColors.freshMint,
              ),
              const SizedBox(height: 8),
              const _AllocationBar(
                label: 'Tưới cây & Dọn dẹp',
                ratio: 0.24,
                color: AppColors.periwinkle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile.adaptive(
              title: Text(
                'Nhắc vệ sinh bồn chứa định kỳ',
                style: AppTypography.rowTitle(),
              ),
              subtitle: Text(
                'Thông báo trước 7 ngày vào đầu mỗi quý',
                style: AppTypography.cardBody(),
              ),
              value: c.tankCleanReminder,
              activeTrackColor: AppColors.freshMint,
              onChanged: c.toggleTankCleanReminder,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mintTile,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                color: AppColors.emerald,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mẹo tiết kiệm nước SDG 6',
                      style: AppTypography.rowTitle(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tận dụng nước rửa rau tưới cây ban công và gắn đầu sục khí tạo bọt cho vòi rửa giúp giảm 25–35% lượng nước thải sinh hoạt.',
                      style: AppTypography.cardBody(color: AppColors.navyInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ParamTile extends StatelessWidget {
  const _ParamTile({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.iceCanvas,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.metricLabel(
                ok ? AppColors.emerald : AppColors.softCoral,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardTitle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTypography.cardBody())),
            Text('${(ratio * 100).round()}%', style: AppTypography.rowTitle()),
          ],
        ),
        const SizedBox(height: 5),
        AquaLiquidProgressBar(
          value: ratio,
          color: color,
          backgroundColor: AppColors.pillGrey,
          height: 8,
        ),
      ],
    );
  }
}

class _TdsDynamicChartPainter extends CustomPainter {
  _TdsDynamicChartPainter({
    required this.drawRatio,
    required this.records,
    required this.currentTds,
    required this.lineColor,
  });

  final double drawRatio;
  final List<AquaWaterTestRecord> records;
  final int currentTds;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Chronological order (oldest -> newest), capped at 6 points
    final chronological = records.take(6).toList().reversed.toList();
    final pts = chronological.isNotEmpty
        ? chronological.map((r) => r.tdsPpm.toDouble()).toList()
        : [currentTds.toDouble(), currentTds.toDouble()];
    if (pts.length == 1) {
      pts.insert(0, pts.first);
    }

    final labels = chronological.length >= 2
        ? List.generate(chronological.length, (i) {
            if (i == chronological.length - 1) return 'Mới';
            return '#${i + 1}';
          })
        : ['Trước', 'Hiện tại'];

    final minVal = pts.reduce(math.min);
    final maxVal = pts.reduce(math.max);
    final lowerBound = math.max(0.0, minVal - 15.0);
    final upperBound = math.max(lowerBound + 20.0, maxVal + 15.0);
    final span = upperBound - lowerBound;

    final stepX = (size.width - 32) / math.max(1, pts.length - 1);
    final plotHeight = size.height - 38;
    final path = Path();
    final offsets = <Offset>[];

    for (int i = 0; i < pts.length; i++) {
      final x = 16 + i * stepX;
      final norm = ((pts[i] - lowerBound) / span).clamp(0.0, 1.0);
      final y = size.height - 22 - norm * plotHeight;
      final pt = Offset(x, y);
      offsets.add(pt);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '${pts[i].round()} • ${labels[i]}',
          style: const TextStyle(
            fontFamily: AppTypography.bodyFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedGrey,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(labelX, size.height - 15));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      final partial = metric.extractPath(0, metric.length * drawRatio);
      canvas.drawPath(partial, linePaint);
    }

    final visibleDots = (offsets.length * drawRatio).ceil();
    for (int i = 0; i < visibleDots && i < offsets.length; i++) {
      canvas.drawCircle(offsets[i], 4.2, Paint()..color = lineColor);
      canvas.drawCircle(offsets[i], 2.0, Paint()..color = AppColors.pureWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _TdsDynamicChartPainter oldDelegate) =>
      oldDelegate.drawRatio != drawRatio ||
      oldDelegate.records != records ||
      oldDelegate.currentTds != currentTds ||
      oldDelegate.lineColor != lineColor;
}
