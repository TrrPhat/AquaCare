import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/aqua_models.dart';
import '../animations/aqua_motion.dart';
import 'aqua_svg_icon.dart';

/// Floating-center 5-tab navigation bar with role-adaptive tabs and central Camera Scanner CTA.
class AquaBottomTabBar extends StatelessWidget {
  const AquaBottomTabBar({
    super.key,
    required this.activeIndex,
    required this.onSelectTab,
    required this.role,
    this.onCenterScanTap,
  });

  final int activeIndex;
  final ValueChanged<int> onSelectTab;
  final AquaRole role;
  final VoidCallback? onCenterScanTap;

  List<String> get _labels {
    return switch (role) {
      AquaRole.studentWorker => const [
          'Trang chủ',
          'Sống xanh',
          'Quét mã',
          'Trạm nước',
          'Cá nhân',
        ],
      AquaRole.household || AquaRole.kids => const [
          'Gia đình',
          'Nước & vệ sinh',
          'Quét mã',
          'Trạm & sự cố',
          'Cá nhân',
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;

    final rowContent = SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (index) {
                final isCenter = index == 2;
                final active = index == activeIndex && !isCenter;
                final iconPath = active
                    ? 'assets/svg/icons/tab_${index}_active.svg'
                    : 'assets/svg/icons/tab_${index}_inactive.svg';

                Widget iconWidget;
                if (isCenter) {
                  iconWidget = Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pureWhite, width: 3.5),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.cyanBright, AppColors.cyanVivid],
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.pureWhite,
                      size: 23,
                    ),
                  );
                } else if (index == 1 && role == AquaRole.studentWorker) {
                  iconWidget = Icon(
                    active ? Icons.eco_rounded : Icons.eco_outlined,
                    size: 24,
                    color: active ? AppColors.emerald : AppColors.mutedGrey,
                  );
                } else {
                  iconWidget = AquaSvg(
                    iconPath,
                    width: 24,
                    height: 24,
                  );
                }

                return Expanded(
                  child: BouncyPressable(
                    pressedScale: 0.91,
                    child: InkWell(
                      onTap: () {
                        if (isCenter && onCenterScanTap != null) {
                          onCenterScanTap!();
                        } else {
                          onSelectTab(index);
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 60,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            if (!isCenter)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                top: active ? 2 : 5,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  width: active ? 44 : 32,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.cyanTile
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutBack,
                              top: isCenter ? -18 : (active ? 4 : 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                decoration: isCenter
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.cyanVivid
                                                .withValues(alpha: 0.34),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      )
                                    : null,
                                child: AnimatedScale(
                                  scale: active ? 1.08 : 1.0,
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutBack,
                                  child: iconWidget,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 37,
                              left: 2,
                              right: 2,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: AppTypography.tabLabel(active: active),
                                child: Text(
                                  labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x120F1F2C),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: rowContent),
    );
  }
}
