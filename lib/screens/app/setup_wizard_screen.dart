import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';
import 'hydration_personalizer_flow.dart';

/// Role-adaptive setup wizard (used inside pre-login Onboarding or when re-configuring from Profile).
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({
    super.key,
    required this.controller,
    this.onBackFromStep0,
    this.onCompleted,
    this.finalCompleteLabel = 'Bắt đầu hành trình AquaCare ✓',
  });

  final AquaUiController controller;
  final VoidCallback? onBackFromStep0;
  final VoidCallback? onCompleted;
  final String finalCompleteLabel;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;
  late final TextEditingController _userNameCtrl;
  late final TextEditingController _kidsNameCtrl;
  late final TextEditingController _pinCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _userNameCtrl = TextEditingController(text: c.userName);
    _kidsNameCtrl = TextEditingController(text: c.kidsName);
    _pinCtrl = TextEditingController(text: c.parentPin);
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _kidsNameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _commitTextInputs() {
    final c = widget.controller;
    c.updateProfileInfo(
      userName: _userNameCtrl.text,
      kidsName: _kidsNameCtrl.text,
      parentPin: _pinCtrl.text,
    );
  }

  void _finishWizard() {
    _commitTextInputs();
    if (widget.onCompleted != null) {
      widget.onCompleted!();
    } else {
      widget.controller.completeSetup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.role == AquaRole.studentWorker && _step >= 2) {
      return Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: AquaHydrationPersonalizerFlow(
          controller: c,
          initialStage: 0,
          completeButtonLabel: widget.finalCompleteLabel,
          onBack: () => setState(() => _step = 1),
          onCompleted: _finishWizard,
        ),
      );
    }

    if (c.role != AquaRole.studentWorker && _step >= 4) {
      return Scaffold(
        backgroundColor: AppColors.pureWhite,
        body: AquaHydrationPersonalizerFlow(
          controller: c,
          initialStage: 3,
          completeButtonLabel: widget.finalCompleteLabel,
          onBack: () => setState(() => _step = 3),
          onCompleted: _finishWizard,
        ),
      );
    }

    final totalSteps = c.role == AquaRole.studentWorker ? 2 : 4;
    final currentStep = (_step + 1).clamp(1, totalSteps);
    final isLastRoleStep = currentStep >= totalSteps;

    return Scaffold(
      backgroundColor: c.role == AquaRole.kids
          ? AppColors.kidsCream
          : AppColors.iceCanvas,
      body: AquaAmbientOrbsBackdrop(
        gradientColors: c.role == AquaRole.kids
            ? const [AppColors.kidsCream, AppColors.pureWhite]
            : const [AppColors.iceCanvas, AppColors.pureWhite],
        orbColors: c.role == AquaRole.kids
            ? const [Color(0x33FFC93C), Color(0x285DCCFC), Color(0x2252D681)]
            : const [Color(0x285DCCFC), Color(0x228E9AFE), Color(0x2252D681)],
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: () {
                        _commitTextInputs();
                        if (_step > 0) {
                          setState(() => _step--);
                        } else if (widget.onBackFromStep0 != null) {
                          widget.onBackFromStep0!();
                        } else if (c.isAuthenticated) {
                          c.setStage(AppFlowStage.main);
                        } else {
                          c.setStage(AppFlowStage.auth);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: AquaLiquidProgressBar(
                        value: currentStep / totalSteps,
                        height: 8,
                        color: c.role == AquaRole.kids
                            ? AppColors.starAmber
                            : AppColors.cyanVivid,
                        backgroundColor: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F0F1F2C),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Bước $currentStep/$totalSteps',
                        style: AppTypography.metricLabel(AppColors.oceanBlue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - 32).clamp(
                            0.0,
                            double.infinity,
                          ),
                        ),
                        child: AquaSmoothSwitcher(
                          child: KeyedSubtree(
                            key: ValueKey<String>('${c.role.name}_$_step'),
                            child: _buildStepBody(c),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: BouncyPressable(
                  child: AquaShimmerOverlay(
                    enabled: isLastRoleStep,
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.role == AquaRole.kids
                              ? AppColors.sunnyButter
                              : AppColors.navyInk,
                          foregroundColor: c.role == AquaRole.kids
                              ? AppColors.navyInk
                              : AppColors.pureWhite,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        onPressed: () {
                          _commitTextInputs();
                          if (c.role == AquaRole.studentWorker) {
                            setState(() => _step = _step < 1 ? 1 : 2);
                          } else {
                            setState(() => _step = _step < 3 ? _step + 1 : 4);
                          }
                        },
                        child: Text(
                          isLastRoleStep
                              ? 'Tiếp tục tính mục tiêu →'
                              : 'Tiếp tục',
                          style: AppTypography.pillCta(
                            color: c.role == AquaRole.kids
                                ? AppColors.navyInk
                                : AppColors.pureWhite,
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

  Widget _buildStepBody(AquaUiController c) {
    if (_step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cyanTile,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '✨ Cá nhân hóa AquaCare',
              style: AppTypography.metricLabel(AppColors.oceanBlue),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bạn muốn dùng AquaCare với vai trò nào?',
            style: AppTypography.pageTitle().copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(
            'Giao diện, thanh điều hướng và trợ lý AI sẽ tối ưu riêng cho vai trò bạn chọn (có thể đổi lại trong mục Cá nhân).',
            style: AppTypography.cardBody(),
          ),
          const SizedBox(height: 20),
          StaggeredEntrance(
            index: 0,
            child: _OptionCard(
              title: 'Sinh viên & người đi làm',
              subtitle: 'Sống xanh giảm chai nhựa, vệ sinh bình nước (WASH), Caffeine & trạm Refill',
              icon: Icons.water_drop_rounded,
              accent: AppColors.cyanVivid,
              surfaceTint: AppColors.cyanTile,
              mascotId: 'giot_nuoc',
              selected: c.role == AquaRole.studentWorker,
              onTap: () => c.setRole(AquaRole.studentWorker),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredEntrance(
            index: 1,
            child: _OptionCard(
              title: 'Hộ gia đình',
              subtitle: 'Kiểm soát an toàn nguồn nước (WHO/QCVN), vệ sinh WASH, chống rò rỉ & góc của bé',
              icon: Icons.home_rounded,
              accent: AppColors.emerald,
              surfaceTint: AppColors.mintTile,
              mascotId: 'bup_sen',
              selected: c.role == AquaRole.household,
              onTap: () => c.setRole(AquaRole.household),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredEntrance(
            index: 2,
            child: _OptionCard(
              title: 'Chế độ trẻ em AquaKids',
              subtitle: 'Giao diện khóa riêng cho bé với Giọt Nước vui nhộn, đố vui & sao thưởng',
              icon: Icons.child_care_rounded,
              accent: AppColors.starAmber,
              surfaceTint: AppColors.sunnyTile,
              mascotId: 'ca_voi_xanh',
              selected: c.role == AquaRole.kids,
              onTap: () => c.setRole(AquaRole.kids),
            ),
          ),
        ],
      );
    }

    return switch (c.role) {
      AquaRole.studentWorker => _buildStudentStep(c),
      AquaRole.household => _buildHouseholdStep(c),
      AquaRole.kids => _buildKidsStep(c),
    };
  }

  Widget _buildStudentStep(AquaUiController c) {
    const shifts = [
      (
        'Ca sáng & chiều (08:00 - 17:30)',
        'Nhắc nhẹ mỗi 90 phút trong giờ học & làm việc',
      ),
      (
        'Ca học đại học linh hoạt',
        'Tạm ngắt nhắc nhở trong giờ thi hoặc trên giảng đường',
      ),
      ('Ca tối / làm việc tự do', 'Kéo dài khung nhắc uống nước đến 22:00 tối'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.lavenderCard,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '⏰ Khung giờ thông minh',
            style: AppTypography.metricLabel(const Color(0xFF53488C)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Lịch học tập & làm việc',
          style: AppTypography.pageTitle().copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn khung giờ phù hợp để lời nhắc luôn đúng lúc, không gây phiền.',
          style: AppTypography.cardBody(),
        ),
        const SizedBox(height: 20),
        ...shifts.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaggeredEntrance(
              index: entry.key,
              child: _OptionCard(
                title: entry.value.$1,
                subtitle: entry.value.$2,
                icon: Icons.schedule_rounded,
                accent: AppColors.periwinkle,
                selected: c.selectedShift == entry.value.$1,
                onTap: () => c.setShift(entry.value.$1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdStep(AquaUiController c) {
    switch (_step) {
      case 1:
        final billVnd = AquaWaterBillEntry.formatVnd(c.currentWaterBillVnd);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin hộ gia đình',
              style: AppTypography.pageTitle().copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Thiết lập tên hiển thị và ước tính lượng nước sinh hoạt trung bình mỗi tháng.',
              style: AppTypography.cardBody(),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextField(
                      controller: _userNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tên đại diện gia đình',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${c.monthlyCubicMeters.toStringAsFixed(0)} m³ / tháng',
                      style: AppTypography.pageTitle(color: AppColors.oceanBlue)
                          .copyWith(fontSize: 30),
                    ),
                    Slider(
                      value: c.monthlyCubicMeters.clamp(4, 35),
                      min: 4,
                      max: 35,
                      divisions: 31,
                      activeColor: AppColors.freshMint,
                      onChanged: c.updateMonthlyWaterMeter,
                    ),
                    const Divider(height: 20),
                    Text(
                      'Chi phí ước tính: ~$billVnd / tháng',
                      style: AppTypography.rowTitle(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.auto_graph_rounded, size: 18),
                        label: const Text('Tính mục tiêu uống nước cá nhân →'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case 2:
        const sources = [
          (
            'Máy lọc RO gia đình',
            'Theo dõi chuẩn uống trực tiếp (< 50 ppm), vệ sinh WASH & bảo trì bộ lọc',
          ),
          (
            'Nước máy đô thị / Đun sôi',
            'Giám sát TDS/pH theo QCVN (≤ 300 ppm) & cảnh báo sự cố đường ống',
          ),
          (
            'Nước khoáng thiên nhiên / Bình 20L',
            'Theo dõi chất lượng khoáng an toàn (≤ 300 ppm) & vệ sinh bình rót',
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nguồn nước uống của gia đình',
              style: AppTypography.pageTitle().copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn hệ thống nước chính để nhận cảnh báo kiểm định phù hợp.',
              style: AppTypography.cardBody(),
            ),
            const SizedBox(height: 20),
            ...sources.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OptionCard(
                  title: s.$1,
                  subtitle: s.$2,
                  icon: Icons.verified_user_outlined,
                  accent: AppColors.freshMint,
                  selected: c.waterSource == s.$1,
                  onTap: () => c.setWaterSource(s.$1),
                ),
              ),
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Góc trẻ em & mã PIN phụ huynh',
              style: AppTypography.pageTitle().copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Cá nhân hóa tên của bé và đặt mã PIN 4 chữ số khi giao máy cho bé chơi.',
              style: AppTypography.cardBody(),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextField(
                      controller: _kidsNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Tên thân mật của bé',
                        hintText: 'VD: Bé An, Bé Bắp...',
                        prefixIcon: Icon(Icons.child_care_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pinCtrl,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mã PIN phụ huynh (4 chữ số)',
                        counterText: '',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildKidsStep(AquaUiController c) {
    switch (_step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tên của bạn nhỏ là gì nhỉ?',
              style: AppTypography.pageTitle().copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Giọt Nước sẽ gọi tên bé mỗi ngày để cùng nhau uống nước thật vui!',
              style: AppTypography.cardBody(),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.kidsBorder, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _kidsNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên của bé',
                    hintText: 'VD: Bé An',
                    prefixIcon: Icon(Icons.face_retouching_natural_rounded),
                  ),
                ),
              ),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mục tiêu số cốc nước mỗi ngày',
              style: AppTypography.pageTitle().copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Mỗi cốc nhỏ tương ứng khoảng 150–200 ml nước lọc phù hợp độ tuổi của bé.',
              style: AppTypography.cardBody(),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.kidsBorder, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '${c.kidsGoalCups} cốc / ngày',
                      style: AppTypography.pageTitle(color: AppColors.oceanBlue)
                          .copyWith(fontSize: 32),
                    ),
                    Slider(
                      value: c.kidsGoalCups.toDouble(),
                      min: 4,
                      max: 10,
                      divisions: 6,
                      activeColor: AppColors.sunnyButter,
                      onChanged: (v) => c.setKidsGoalCups(v.round()),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: List.generate(
                        c.kidsGoalCups,
                        (_) => const Icon(
                          Icons.local_drink_rounded,
                          color: AppColors.aquaTeal,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thiết lập mã PIN phụ huynh',
              style: AppTypography.pageTitle().copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã PIN giúp bố mẹ khóa an toàn không gian của bé và quay lại giao diện người lớn khi cần.',
              style: AppTypography.cardBody(),
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.kidsBorder, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _pinCtrl,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mã PIN phụ huynh 4 chữ số',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.surfaceTint,
    this.mascotId,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final Color? surfaceTint;
  final String? mascotId;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? (surfaceTint ?? AppColors.pureWhite)
        : AppColors.pureWhite;
    return BouncyPressable(
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.72)
                : AppColors.pureWhite.withValues(alpha: 0.8),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? accent.withValues(alpha: 0.24)
                  : const Color(0x0A0F1F2C),
              blurRadius: selected ? 18 : 12,
              offset: const Offset(0, 5),
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
                  if (mascotId != null)
                    AquaGentleFloat(
                      enabled: selected,
                      amplitude: 3.5,
                      rotationRadians: 0.04,
                      child: AnimatedScale(
                        scale: selected ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AquaMascotVectorArt(
                          mascotId: mascotId!,
                          size: 46,
                        ),
                      ),
                    )
                  else
                    AnimatedScale(
                      scale: selected ? 1.06 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.22)
                              : accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: accent),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.cardTitle()),
                        const SizedBox(height: 3),
                        Text(subtitle, style: AppTypography.cardBody()),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.pureWhite,
                        size: 16,
                      ),
                    ),
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
