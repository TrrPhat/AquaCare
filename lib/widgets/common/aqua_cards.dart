import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

const BoxShadow kAquaCardShadow = BoxShadow(
  color: AppColors.cardShadow,
  blurRadius: 20,
  offset: Offset(0, 6),
);

/// Side-by-side 2-metric row card.
class AquaMetricRow extends StatelessWidget {
  const AquaMetricRow({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.isKidsTheme,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final bool isKidsTheme;

  @override
  Widget build(BuildContext context) {
    final radius = isKidsTheme ? 18.0 : 16.0;
    final leftLabelColor =
        isKidsTheme ? AppColors.aquaTeal : AppColors.deepSky;
    final rightLabelColor =
        isKidsTheme ? AppColors.emerald : AppColors.freshMint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricCard(
              label: leftLabel,
              value: leftValue,
              labelColor: leftLabelColor,
              radius: radius,
              isKidsTheme: isKidsTheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              label: rightLabel,
              value: rightValue,
              labelColor: rightLabelColor,
              radius: radius,
              isKidsTheme: isKidsTheme,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.radius,
    required this.isKidsTheme,
  });

  final String label;
  final String value;
  final Color labelColor;
  final double radius;
  final bool isKidsTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [kAquaCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metricLabel(labelColor),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.metricValue(isKids: isKidsTheme),
          ),
        ],
      ),
    );
  }
}
