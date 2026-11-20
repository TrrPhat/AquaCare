import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';
import '../../widgets/mascot/aqua_mascot_wave_vessel.dart';
import 'setup_wizard_screen.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.tag,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.surfaceColor,
    required this.highlights,
    this.isKids = false,
  });

  final String tag;
  final String title;
  final String description;
  final Color accentColor;
  final Color surfaceColor;
  final List<String> highlights;
  final bool isKids;
}

/// Interactive 3-page Waterllama-inspired onboarding showcase tailored to AquaCare's 3 pillars.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  int _previewStep = 4;
  Timer? _previewTimer;
  bool _showPersonalizer = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      tag: 'Sinh viên & người đi làm',
      title: 'Cấp ẩm thông minh theo ca học & làm việc',
      description: 'Nhắc uống nước đúng nhịp, quy đổi trà/cà phê bằng sóng đa sắc trực quan và tìm nhanh trạm Refill nước sạch.',
      accentColor: AppColors.cyanVivid,
      surfaceColor: AppColors.cyanTile,
      highlights: [
        'Theo dõi từng lớp đồ uống sinh động trên linh vật AquaCare',
        'Quét nhanh mã vạch chai nước & QR trạm Refill giảm nhựa',
      ],
    ),
    _OnboardingPageData(
      tag: 'Hộ gia đình • Nước sạch & vệ sinh',
      title: 'Kiểm soát an toàn nguồn nước (WHO/QCVN) & vệ sinh gia đình',
      description: 'Đánh giá chỉ số TDS/pH theo từng loại nguồn nước, thực hành checklist vệ sinh WASH và phát hiện sớm rò rỉ đường ống.',
      accentColor: AppColors.emerald,
      surfaceColor: AppColors.mintTile,
      highlights: [
        'Phân chuẩn rõ nước lọc RO (< 50 ppm), nước máy & nước khoáng (≤ 300 ppm)',
        'Theo dõi vệ sinh bồn chứa, vòi rót & cảnh báo rò rỉ tiết kiệm nước',
      ],
    ),
    _OnboardingPageData(
      tag: 'Chế độ trẻ em AquaKids',
      title: 'Bé Giọt Nước đồng hành tạo thói quen uống nước vui',
      description: 'Giao diện khóa toàn màn hình riêng cho bé với thử thách khóa vòi đánh răng, đố vui và tích sao đổi quà.',
      accentColor: AppColors.sunnyButter,
      surfaceColor: AppColors.sunnyTile,
      highlights: [
        'Nhân vật hoạt hình tương tác & dán nhãn bình nước',
        'Cổng phụ huynh bảo vệ bằng phép tính & mã PIN',
      ],
      isKids: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (!AquaMotion.isTestEnvironment) {
      _previewStep = 1;
      _previewTimer = Timer.periodic(const Duration(milliseconds: 1150), (_) {
        if (!mounted || _showPersonalizer) return;
        setState(() {
          _previewStep = (_previewStep % 4) + 1;
        });
      });
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _previewTimer = null;
    _pageController.dispose();
    super.dispose();
  }

  void _nextOrFinish() {
    if (_pageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _showPersonalizer = true);
    }
  }

  Widget _buildShowcaseCard(
    int idx,
    _OnboardingPageData p, {
    double cardHeight = 204,
  }) {
    if (idx == 0) {
      final previewSlices = <AquaLiquidSlice>[
        const AquaLiquidSlice(fraction: 0.25, color: Color(0xFF00C2EC)),
        if (_previewStep >= 2)
          const AquaLiquidSlice(fraction: 0.20, color: Color(0xFF7BC138)),
        if (_previewStep >= 3)
          const AquaLiquidSlice(fraction: 0.18, color: Color(0xFF6B4837)),
        if (_previewStep >= 4)
          const AquaLiquidSlice(fraction: 0.22, color: Color(0xFF2CC8AE)),
      ];
      return Container(
        height: cardHeight,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surfaceColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: AquaGentleFloat(
                amplitude: 4.5,
                rotationRadians: 0.025,
                child: AquaMascotWaveVessel(
                  mascotId: 'giot_nuoc',
                  slices: previewSlices,
                  crossfadeFullAtComplete: false,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniDrinkLegend(
                    label: 'Nước lọc',
                    color: const Color(0xFF00C2EC),
                    active: _previewStep >= 1,
                  ),
                  const SizedBox(height: 6),
                  _MiniDrinkLegend(
                    label: 'Trà xanh 95%',
                    color: const Color(0xFF7BC138),
                    active: _previewStep >= 2,
                  ),
                  const SizedBox(height: 6),
                  _MiniDrinkLegend(
                    label: 'Cà phê 80%',
                    color: const Color(0xFF6B4837),
                    active: _previewStep >= 3,
                  ),
                  const SizedBox(height: 6),
                  _MiniDrinkLegend(
                    label: 'Nước dừa 105%',
                    color: const Color(0xFF2CC8AE),
                    active: _previewStep >= 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (idx == 1) {
      return Container(
        height: cardHeight,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
        decoration: BoxDecoration(
          color: p.surfaceColor,
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'TDS 36 ppm • Chuẩn uống trực tiếp ✓',
                    style: AppTypography.metricLabel(AppColors.emerald),
                  ),
                ),
                const SizedBox(height: 14),
                const _MiniFilterRow(
                  label: 'Vệ sinh bồn & vòi nước',
                  pct: 0.75,
                  low: false,
                ),
                const SizedBox(height: 8),
                const _MiniFilterRow(
                  label: 'Bộ lọc thô cấp 1',
                  pct: 0.15,
                  low: true,
                ),
                const SizedBox(height: 8),
                const _MiniFilterRow(
                  label: 'Màng lọc RO / UF',
                  pct: 0.90,
                  low: false,
                ),
              ],
            ),
            const Positioned(
              right: -4,
              bottom: -6,
              child: AquaGentleFloat(
                amplitude: 4.5,
                rotationRadians: 0.03,
                child: AquaMascotVectorArt(mascotId: 'bup_sen', size: 86),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: cardHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Center(
              child: AquaGentleFloat(
                amplitude: 5.5,
                rotationRadians: 0.04,
                child: AquaMascotVectorArt(
                  mascotId: 'giot_nuoc',
                  size: 112,
                  accessoryName: 'Vương miện Giọt Nước',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.starAmber,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '★ +10 Sao mỗi cốc',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.navyInk,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '🚰 Khóa vòi 2 phút',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.navyInk,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '🔒 Cổng phụ huynh PIN',
                    style: TextStyle(
                      fontFamily: AppTypography.bodyFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.navyInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showPersonalizer) {
      return SetupWizardScreen(
        controller: widget.controller,
        finalCompleteLabel: 'Tiếp tục đến đăng nhập ✓',
        onBackFromStep0: () => setState(() => _showPersonalizer = false),
        onCompleted: () {
          widget.controller.markOnboardingSetupDone();
          widget.controller.completeOnboarding();
        },
      );
    }

    final page = _pages[_pageIndex];
    return Scaffold(
      backgroundColor: page.isKids ? AppColors.kidsCream : AppColors.pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Row(
                children: [
                  const AquaMascotVectorArt(mascotId: 'giot_nuoc', size: 28),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AquaCare',
                      style: TextStyle(
                        fontFamily: AppTypography.displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.navyInk,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.pillGrey,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                    ),
                    onPressed: widget.controller.completeOnboarding,
                    child: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slateBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (_, idx) {
                  final p = _pages[idx];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final cardHeight =
                          (constraints.maxHeight * 0.36).clamp(198.0, 268.0);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 28).clamp(
                              0.0,
                              double.infinity,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.surfaceColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      p.tag,
                                      style: TextStyle(
                                        fontFamily: AppTypography.bodyFont,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
                                        color: p.isKids
                                            ? AppColors.navyInk
                                            : p.accentColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AnimatedBuilder(
                                    animation: _pageController,
                                    builder: (_, child) {
                                      final current = _pageController.hasClients
                                          ? (_pageController.page ??
                                                _pageIndex.toDouble())
                                          : _pageIndex.toDouble();
                                      final delta =
                                          (idx - current).clamp(-1.0, 1.0);
                                      return Transform.translate(
                                        offset: Offset(delta * 26, 0),
                                        child: Transform.scale(
                                          scale: 1.0 - delta.abs() * 0.06,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildShowcaseCard(
                                      idx,
                                      p,
                                      cardHeight: cardHeight,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    p.title,
                                    style: AppTypography.displayHero().copyWith(
                                      fontSize: 24,
                                      height: 1.24,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    p.description,
                                    style: AppTypography.cardBody().copyWith(
                                      fontSize: 14.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  children: [
                                    ...p.highlights.asMap().entries.map(
                                      (entry) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: StaggeredEntrance(
                                          index: entry.key,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: p.surfaceColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_rounded,
                                                  size: 15,
                                                  color: p.isKids
                                                      ? AppColors.navyInk
                                                      : p.accentColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  entry.value,
                                                  style:
                                                      AppTypography.rowTitle(),
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
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _pageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? (page.isKids
                                    ? AppColors.starAmber
                                    : page.accentColor)
                              : AppColors.pillGrey,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  BouncyPressable(
                    child: AquaShimmerOverlay(
                      enabled: _pageIndex == _pages.length - 1,
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: page.isKids
                                ? AppColors.sunnyButter
                                : AppColors.navyInk,
                            foregroundColor: page.isKids
                                ? AppColors.navyInk
                                : AppColors.pureWhite,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: _nextOrFinish,
                          child: Text(
                            _pageIndex < _pages.length - 1
                                ? 'Tiếp tục'
                                : 'Thiết lập hồ sơ ngay →',
                            style: AppTypography.pillCta(
                              color: page.isKids
                                  ? AppColors.navyInk
                                  : AppColors.pureWhite,
                            ),
                          ),
                        ),
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
  }
}

class _MiniDrinkLegend extends StatelessWidget {
  const _MiniDrinkLegend({
    required this.label,
    required this.color,
    required this.active,
  });

  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      opacity: active ? 1.0 : 0.36,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.metricLabel(AppColors.navyInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFilterRow extends StatelessWidget {
  const _MiniFilterRow({
    required this.label,
    required this.pct,
    required this.low,
  });

  final String label;
  final double pct;
  final bool low;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 192,
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
                  style: AppTypography.metricLabel(AppColors.navyInk),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(pct * 100).round()}%',
                style: AppTypography.metricLabel(
                  low ? AppColors.softCoral : AppColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppColors.pureWhite,
              valueColor: AlwaysStoppedAnimation<Color>(
                low ? AppColors.softCoral : AppColors.freshMint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
