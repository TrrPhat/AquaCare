import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../animations/aqua_motion.dart';

/// Shared borderless squircle card wrapper for interactive UI sections across all modules.
class InteractivePanel extends StatelessWidget {
  const InteractivePanel({
    super.key,
    required this.title,
    required this.child,
    this.badgeText,
    this.accentColor = AppColors.cyanVivid,
    this.surfaceColor,
    this.isKids = false,
  });

  final String title;
  final Widget child;
  final String? badgeText;
  final Color accentColor;
  final Color? surfaceColor;
  final bool isKids;

  @override
  Widget build(BuildContext context) {
    final radius = isKids ? 26.0 : 24.0;
    final bg = surfaceColor ?? (isKids ? AppColors.pureWhite : AppColors.pureWhite);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F1F2C),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.cardTitle(
                        isKids: isKids,
                        color: AppColors.navyInk,
                      ).copyWith(fontSize: 15),
                    ),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText!,
                        style: AppTypography.metricLabel(accentColor)
                            .copyWith(fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact selectable borderless pill chip with tactile bounce & animated state transition.
class AquaChoiceChip extends StatelessWidget {
  const AquaChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.cyanVivid,
    this.selectedTextColor = AppColors.pureWhite,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedTextColor;

  @override
  Widget build(BuildContext context) {
    return BouncyPressable(
      pressedScale: 0.94,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? selectedColor : AppColors.pillGrey,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.bodyFont,
              fontWeight: FontWeight.w800,
              fontVariations: AppTypography.wght(800),
              fontSize: 12.5,
              color: selected ? selectedTextColor : AppColors.slateBody,
            ),
          ),
        ),
      ),
    );
  }
}
