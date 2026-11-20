import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an SVG asset exported directly from Figma while keeping exact dimensions.
class AquaSvg extends StatelessWidget {
  const AquaSvg(
    this.assetPath, {
    super.key,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
