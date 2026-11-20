import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../state/aqua_ui_controller.dart';

/// Metadata for an original AquaCare SDG 6 Guardian Mascot.
class AquaMascotSpec {
  const AquaMascotSpec({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.unlockHint,
    required this.accentColor,
    required this.secondaryColor,
    required this.cardBgColor,
    required this.badgeEmoji,
    required this.isUnlocked,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final String unlockHint;
  final Color accentColor;
  final Color secondaryColor;
  final Color cardBgColor;
  final String badgeEmoji;
  final bool Function(AquaUiController controller) isUnlocked;
}

class AquaMascotCatalog {
  const AquaMascotCatalog._();

  static final List<AquaMascotSpec> all = [
    AquaMascotSpec(
      id: 'giot_nuoc',
      name: 'Bé Giọt Nước',
      title: 'Sứ giả SDG 6',
      description:
          'Linh vật biểu tượng của AquaCare — luôn nhắc bạn tiếp nước tinh khiết mỗi ngày.',
      unlockHint: 'Mở khóa mặc định',
      accentColor: const Color(0xFF00BBE4),
      secondaryColor: const Color(0xFF8BE4FA),
      cardBgColor: AppColors.cyanTile,
      badgeEmoji: '💧',
      isUnlocked: (_) => true,
    ),
    AquaMascotSpec(
      id: 'ca_voi_xanh',
      name: 'Cá Voi Xanh',
      title: 'Chiến binh giảm nhựa',
      description:
          'Đồng hành cùng thói quen dùng bình cá nhân tại trạm Refill, bảo vệ đại dương xanh.',
      unlockHint: 'Mở khóa mặc định',
      accentColor: const Color(0xFF0284C7),
      secondaryColor: const Color(0xFF7DD3FC),
      cardBgColor: const Color(0xFFE0F2FE),
      badgeEmoji: '🐋',
      isUnlocked: (_) => true,
    ),
    AquaMascotSpec(
      id: 'rua_bien',
      name: 'Rùa Biển Xanh',
      title: 'Hộ vệ nguồn nước',
      description:
          'Chậm rãi nhưng bền bỉ — giữ nhịp uống nước đều đặn suốt ca học và làm việc.',
      unlockHint: 'Mở khóa mặc định',
      accentColor: const Color(0xFF10B981),
      secondaryColor: const Color(0xFF6EE7B7),
      cardBgColor: AppColors.mintTile,
      badgeEmoji: '🐢',
      isUnlocked: (_) => true,
    ),
    AquaMascotSpec(
      id: 'bup_sen',
      name: 'Búp Sen Tinh Khiết',
      title: 'Tinh hoa lọc sạch RO',
      description:
          'Biểu tượng nước sạch gia đình Việt — giữ chỉ số TDS dưới 50 ppm an toàn cho cả nhà.',
      unlockHint: 'Mở khóa mặc định',
      accentColor: const Color(0xFFF472B6),
      secondaryColor: const Color(0xFFFBCFE8),
      cardBgColor: AppColors.coralTile,
      badgeEmoji: '🪷',
      isUnlocked: (_) => true,
    ),
    AquaMascotSpec(
      id: 'ech_suoi',
      name: 'Ếch Suối Mát',
      title: 'Người bạn thiên nhiên',
      description:
          'Sống ở dòng suối trong lành — phần thưởng khi bạn tiết kiệm từ 15 chai nhựa hoặc đạt 100% mục tiêu.',
      unlockHint: 'Tiết kiệm 15 chai nhựa hoặc đạt 100% hôm nay',
      accentColor: const Color(0xFF52D681),
      secondaryColor: const Color(0xFFA7F3D0),
      cardBgColor: AppColors.mintTile,
      badgeEmoji: '🐸',
      isUnlocked: (c) => c.plasticSaved >= 15 || c.intakePercent >= 100,
    ),
    AquaMascotSpec(
      id: 'hai_cau_ro',
      name: 'Hải Cẩu Pha Lê',
      title: 'Bậc thầy chuỗi ngày',
      description:
          'Biểu tượng của sự kiên trì — mở khóa khi đạt chuỗi 14 ngày, 140 sao hoặc 100% mục tiêu ngày.',
      unlockHint: 'Đạt chuỗi 14 ngày, 140★ hoặc 100% mục tiêu',
      accentColor: const Color(0xFF8E9AFE),
      secondaryColor: const Color(0xFFC7D2FE),
      cardBgColor: AppColors.lavenderCard,
      badgeEmoji: '🦭',
      isUnlocked: (c) =>
          c.streakDays >= 14 || c.kidsStars >= 140 || c.intakePercent >= 100,
    ),
  ];

  static AquaMascotSpec byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return all.first;
  }

  static List<String> unlockedIdsFor(AquaUiController controller) =>
      all.where((m) => m.isUnlocked(controller)).map((m) => m.id).toList();
}

/// Builds the unified outer silhouette path used for both the #ECEFF2 empty mask
/// and liquid wave clipping inside [AquaMascotWaveVessel].
Path buildMascotSilhouettePath(String id, Size size) {
  final w = size.width;
  final h = size.height;

  switch (id) {
    case 'ca_voi_xanh':
      return Path()
        ..moveTo(w * 0.44, h * 0.19)
        ..quadraticBezierTo(w * 0.72, h * 0.19, w * 0.78, h * 0.48)
        ..quadraticBezierTo(w * 0.84, h * 0.48, w * 0.90, h * 0.34)
        ..quadraticBezierTo(w * 0.96, h * 0.36, w * 0.91, h * 0.54)
        ..quadraticBezierTo(w * 0.97, h * 0.68, w * 0.87, h * 0.70)
        ..quadraticBezierTo(w * 0.78, h * 0.64, w * 0.75, h * 0.70)
        ..quadraticBezierTo(w * 0.68, h * 0.88, w * 0.42, h * 0.88)
        ..quadraticBezierTo(w * 0.10, h * 0.88, w * 0.10, h * 0.54)
        ..quadraticBezierTo(w * 0.10, h * 0.19, w * 0.44, h * 0.19)
        ..close();

    case 'rua_bien':
      final body = Path()
        // Top head dome
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.21),
            width: w * 0.28,
            height: h * 0.26,
          ),
        )
        // Left & right front flippers
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.16, h * 0.44),
            width: w * 0.20,
            height: h * 0.16,
          ),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.84, h * 0.44),
            width: w * 0.20,
            height: h * 0.16,
          ),
        )
        // Left & right rear flippers
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.22, h * 0.78),
            width: w * 0.18,
            height: h * 0.16,
          ),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.78, h * 0.78),
            width: w * 0.18,
            height: h * 0.16,
          ),
        )
        // Plump shell core
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w * 0.50, h * 0.56),
              width: w * 0.66,
              height: h * 0.62,
            ),
            Radius.circular(w * 0.31),
          ),
        );
      return body;

    case 'bup_sen':
      return Path()
        ..moveTo(w * 0.50, h * 0.08)
        ..cubicTo(w * 0.66, h * 0.22, w * 0.75, h * 0.36, w * 0.75, h * 0.52)
        ..quadraticBezierTo(w * 0.88, h * 0.42, w * 0.90, h * 0.56)
        ..cubicTo(w * 0.91, h * 0.80, w * 0.72, h * 0.91, w * 0.50, h * 0.91)
        ..cubicTo(w * 0.28, h * 0.91, w * 0.09, h * 0.80, w * 0.10, h * 0.56)
        ..quadraticBezierTo(w * 0.12, h * 0.42, w * 0.25, h * 0.52)
        ..cubicTo(w * 0.25, h * 0.36, w * 0.34, h * 0.22, w * 0.50, h * 0.08)
        ..close();

    case 'ech_suoi':
      return Path()
        // Left & right eye bumps
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.32, h * 0.25),
            width: w * 0.24,
            height: h * 0.22,
          ),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.68, h * 0.25),
            width: w * 0.24,
            height: h * 0.22,
          ),
        )
        // Cute side legs
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.20, h * 0.78),
            width: w * 0.24,
            height: h * 0.18,
          ),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.80, h * 0.78),
            width: w * 0.24,
            height: h * 0.18,
          ),
        )
        // Wide frog torso
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w * 0.50, h * 0.58),
              width: w * 0.76,
              height: h * 0.62,
            ),
            Radius.circular(w * 0.32),
          ),
        );

    case 'hai_cau_ro':
      return Path()
        // Plump seal head + neck
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.50, h * 0.27),
            width: w * 0.46,
            height: h * 0.36,
          ),
        )
        // Left & right flippers
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.19, h * 0.68),
            width: w * 0.24,
            height: h * 0.16,
          ),
        )
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.81, h * 0.68),
            width: w * 0.24,
            height: h * 0.16,
          ),
        )
        // Round chubby body
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w * 0.50, h * 0.63),
              width: w * 0.68,
              height: h * 0.54,
            ),
            Radius.circular(w * 0.32),
          ),
        );

    case 'giot_nuoc':
    default:
      return Path()
        ..moveTo(w * 0.50, h * 0.08)
        ..cubicTo(w * 0.66, h * 0.28, w * 0.87, h * 0.50, w * 0.87, h * 0.66)
        ..cubicTo(w * 0.87, h * 0.83, w * 0.71, h * 0.93, w * 0.50, h * 0.93)
        ..cubicTo(w * 0.29, h * 0.93, w * 0.13, h * 0.83, w * 0.13, h * 0.66)
        ..cubicTo(w * 0.13, h * 0.50, w * 0.34, h * 0.28, w * 0.50, h * 0.08)
        ..close();
  }
}

/// Paints subtle eyes and smile over the silhouette/liquid fill during 0%–99% progress
/// so the mascot looks alive even while filling up.
void paintMascotMinimalFace(
  Canvas canvas,
  Size size,
  String id, {
  Color inkColor = AppColors.navyInk,
  double opacity = 0.78,
}) {
  final w = size.width;
  final h = size.height;
  final eyePaint = Paint()..color = inkColor.withValues(alpha: opacity);
  final glossPaint = Paint()
    ..color = AppColors.pureWhite.withValues(alpha: opacity);
  final mouthPaint = Paint()
    ..color = inkColor.withValues(alpha: opacity)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(2.0, w * 0.022);

  double eyeLeftX = w * 0.38;
  double eyeRightX = w * 0.62;
  double eyeY = h * 0.63;
  double eyeR = w * 0.042;
  double mouthY = h * 0.70;

  switch (id) {
    case 'ca_voi_xanh':
      eyeLeftX = w * 0.29;
      eyeRightX = w * 0.54;
      eyeY = h * 0.52;
      mouthY = h * 0.60;
      break;
    case 'rua_bien':
      eyeLeftX = w * 0.44;
      eyeRightX = w * 0.56;
      eyeY = h * 0.19;
      eyeR = w * 0.026;
      mouthY = h * 0.24;
      break;
    case 'bup_sen':
      eyeLeftX = w * 0.41;
      eyeRightX = w * 0.59;
      eyeY = h * 0.62;
      eyeR = w * 0.036;
      mouthY = h * 0.69;
      break;
    case 'ech_suoi':
      eyeLeftX = w * 0.32;
      eyeRightX = w * 0.68;
      eyeY = h * 0.24;
      eyeR = w * 0.044;
      mouthY = h * 0.48;
      break;
    case 'hai_cau_ro':
      eyeLeftX = w * 0.41;
      eyeRightX = w * 0.59;
      eyeY = h * 0.26;
      eyeR = w * 0.036;
      mouthY = h * 0.34;
      break;
  }

  canvas.drawCircle(Offset(eyeLeftX, eyeY), eyeR, eyePaint);
  canvas.drawCircle(Offset(eyeRightX, eyeY), eyeR, eyePaint);
  canvas.drawCircle(
    Offset(eyeLeftX - eyeR * 0.28, eyeY - eyeR * 0.28),
    eyeR * 0.34,
    glossPaint,
  );
  canvas.drawCircle(
    Offset(eyeRightX - eyeR * 0.28, eyeY - eyeR * 0.28),
    eyeR * 0.34,
    glossPaint,
  );

  final midX = (eyeLeftX + eyeRightX) / 2;
  final span = (eyeRightX - eyeLeftX) * 0.34;
  final smile = Path()
    ..moveTo(midX - span, mouthY)
    ..quadraticBezierTo(
      midX,
      mouthY + span * 0.72,
      midX + span,
      mouthY,
    );
  canvas.drawPath(smile, mouthPaint);
}

/// Paints the full-color lineless vector mascot illustration for 100% completion,
/// collection previews, onboarding cards, and AquaKids!
void paintFullMascot(
  Canvas canvas,
  Size size,
  String id, {
  String? accessoryName,
}) {
  final w = size.width;
  final h = size.height;
  final spec = AquaMascotCatalog.byId(id);

  switch (id) {
    case 'ca_voi_xanh':
      _paintWhaleFull(canvas, w, h, spec);
      break;
    case 'rua_bien':
      _paintTurtleFull(canvas, w, h, spec);
      break;
    case 'bup_sen':
      _paintLotusFull(canvas, w, h, spec);
      break;
    case 'ech_suoi':
      _paintFrogFull(canvas, w, h, spec);
      break;
    case 'hai_cau_ro':
      _paintSealFull(canvas, w, h, spec);
      break;
    case 'giot_nuoc':
    default:
      _paintDropFull(canvas, w, h, spec);
      break;
  }

  if (accessoryName != null && accessoryName.isNotEmpty) {
    _paintKidsAccessory(canvas, size, id, accessoryName);
  }
}

void _paintDropFull(Canvas canvas, double w, double h, AquaMascotSpec spec) {
  final path = buildMascotSilhouettePath('giot_nuoc', Size(w, h));
  final grad = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [spec.secondaryColor, spec.accentColor, AppColors.oceanBlue],
  ).createShader(Rect.fromLTWH(0, 0, w, h));
  canvas.drawPath(path, Paint()..shader = grad);

  // Soft glossy highlight on left shoulder
  canvas.save();
  canvas.translate(w * 0.33, h * 0.49);
  canvas.rotate(-0.35);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: w * 0.09, height: h * 0.22),
    Paint()..color = AppColors.pureWhite.withValues(alpha: 0.48),
  );
  canvas.restore();

  // SDG 6 Green Leaf Sprout on top-right crown
  final leaf = Path()
    ..moveTo(w * 0.51, h * 0.16)
    ..quadraticBezierTo(w * 0.64, h * 0.04, w * 0.72, h * 0.11)
    ..quadraticBezierTo(w * 0.64, h * 0.20, w * 0.51, h * 0.16)
    ..close();
  canvas.drawPath(leaf, Paint()..color = AppColors.freshMint);

  // Blush cheeks
  final blush = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.55);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.29, h * 0.69),
      width: w * 0.11,
      height: h * 0.055,
    ),
    blush,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.71, h * 0.69),
      width: w * 0.11,
      height: h * 0.055,
    ),
    blush,
  );

  paintMascotMinimalFace(canvas, Size(w, h), 'giot_nuoc', opacity: 0.95);
}

void _paintWhaleFull(Canvas canvas, double w, double h, AquaMascotSpec spec) {
  // Tiny water spout curl above whale
  final spoutPaint = Paint()
    ..color = AppColors.skyCyan
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = math.max(2.2, w * 0.025);
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(w * 0.38, h * 0.14),
      width: w * 0.12,
      height: h * 0.12,
    ),
    math.pi,
    math.pi * 0.9,
    false,
    spoutPaint,
  );
  canvas.drawArc(
    Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.14),
      width: w * 0.12,
      height: h * 0.12,
    ),
    0,
    -math.pi * 0.9,
    false,
    spoutPaint,
  );

  final path = buildMascotSilhouettePath('ca_voi_xanh', Size(w, h));
  final grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [spec.secondaryColor, spec.accentColor],
  ).createShader(Rect.fromLTWH(0, 0, w, h));
  canvas.drawPath(path, Paint()..shader = grad);

  // Creamy whale belly clipped inside silhouette
  canvas.save();
  canvas.clipPath(path);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.42, h * 0.84),
      width: w * 0.60,
      height: h * 0.28,
    ),
    Paint()..color = const Color(0xFFE6F8FD),
  );
  canvas.restore();

  // Cheek blush
  final blush = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.48);
  canvas.drawCircle(Offset(w * 0.23, h * 0.58), w * 0.045, blush);
  canvas.drawCircle(Offset(w * 0.59, h * 0.58), w * 0.045, blush);

  paintMascotMinimalFace(canvas, Size(w, h), 'ca_voi_xanh', opacity: 0.95);
}

void _paintTurtleFull(Canvas canvas, double w, double h, AquaMascotSpec spec) {
  final flipperPaint = Paint()..color = const Color(0xFF34D399);
  // Head & flippers
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.21),
      width: w * 0.28,
      height: h * 0.26,
    ),
    flipperPaint,
  );
  for (final (cx, cy, rw, rh) in [
    (0.16, 0.44, 0.20, 0.16),
    (0.84, 0.44, 0.20, 0.16),
    (0.22, 0.78, 0.18, 0.16),
    (0.78, 0.78, 0.18, 0.16),
  ]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * cx, h * cy),
        width: w * rw,
        height: h * rh,
      ),
      flipperPaint,
    );
  }

  // Rim & Shell
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.56),
        width: w * 0.66,
        height: h * 0.62,
      ),
      Radius.circular(w * 0.31),
    ),
    Paint()..color = const Color(0xFF059669),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.56),
        width: w * 0.54,
        height: h * 0.50,
      ),
      Radius.circular(w * 0.25),
    ),
    Paint()..color = spec.accentColor,
  );

  // Cute shell pattern hexagons/circles
  final spotPaint = Paint()..color = const Color(0xFFA7F3D0).withValues(alpha: 0.55);
  canvas.drawCircle(Offset(w * 0.50, h * 0.52), w * 0.10, spotPaint);
  canvas.drawCircle(Offset(w * 0.36, h * 0.64), w * 0.065, spotPaint);
  canvas.drawCircle(Offset(w * 0.64, h * 0.64), w * 0.065, spotPaint);

  paintMascotMinimalFace(canvas, Size(w, h), 'rua_bien', opacity: 0.95);
}

void _paintLotusFull(Canvas canvas, double w, double h, AquaMascotSpec spec) {
  // Side petals
  final outerPetalPaint = Paint()..color = const Color(0xFFF9A8D4);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.26, h * 0.68),
      width: w * 0.34,
      height: h * 0.44,
    ),
    outerPetalPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.74, h * 0.68),
      width: w * 0.34,
      height: h * 0.44,
    ),
    outerPetalPaint,
  );

  // Center plump lotus petal
  final centerPetal = Path()
    ..moveTo(w * 0.50, h * 0.08)
    ..cubicTo(w * 0.72, h * 0.28, w * 0.76, h * 0.58, w * 0.72, h * 0.88)
    ..quadraticBezierTo(w * 0.50, h * 0.93, w * 0.28, h * 0.88)
    ..cubicTo(w * 0.24, h * 0.58, w * 0.28, h * 0.28, w * 0.50, h * 0.08)
    ..close();
  final grad = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBCFE8), Color(0xFFF472B6)],
  ).createShader(Rect.fromLTWH(0, 0, w, h));
  canvas.drawPath(centerPetal, Paint()..shader = grad);

  // Pure dewdrop jewel on forehead
  canvas.drawCircle(
    Offset(w * 0.50, h * 0.38),
    w * 0.045,
    Paint()..color = AppColors.cyanVivid,
  );

  // Blush
  final blush = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.45);
  canvas.drawCircle(Offset(w * 0.32, h * 0.69), w * 0.048, blush);
  canvas.drawCircle(Offset(w * 0.68, h * 0.69), w * 0.048, blush);

  paintMascotMinimalFace(canvas, Size(w, h), 'bup_sen', opacity: 0.95);
}

void _paintFrogFull(Canvas canvas, double w, double h, AquaMascotSpec spec) {
  final frogPaint = Paint()..color = spec.accentColor;
  // Side feet
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.20, h * 0.78),
      width: w * 0.24,
      height: h * 0.18,
    ),
    Paint()..color = const Color(0xFF2EA95E),
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.80, h * 0.78),
      width: w * 0.24,
      height: h * 0.18,
    ),
    Paint()..color = const Color(0xFF2EA95E),
  );

  // Body
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.58),
        width: w * 0.76,
        height: h * 0.62,
      ),
      Radius.circular(w * 0.32),
    ),
    frogPaint,
  );
  // Eye bumps
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.32, h * 0.25),
      width: w * 0.24,
      height: h * 0.22,
    ),
    frogPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.68, h * 0.25),
      width: w * 0.24,
      height: h * 0.22,
    ),
    frogPaint,
  );

  // Soft cream frog belly
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.69),
      width: w * 0.50,
      height: h * 0.34,
    ),
    Paint()..color = const Color(0xFFECFDF5),
  );

  // White sclera behind eyes
  canvas.drawCircle(
    Offset(w * 0.32, h * 0.24),
    w * 0.082,
    Paint()..color = AppColors.pureWhite,
  );
  canvas.drawCircle(
    Offset(w * 0.68, h * 0.24),
    w * 0.082,
    Paint()..color = AppColors.pureWhite,
  );

  // Cheek blush
  final blush = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.45);
  canvas.drawCircle(Offset(w * 0.25, h * 0.44), w * 0.05, blush);
  canvas.drawCircle(Offset(w * 0.75, h * 0.44), w * 0.05, blush);

  paintMascotMinimalFace(canvas, Size(w, h), 'ech_suoi', opacity: 0.95);
}

void _paintSealFull(Canvas canvas, double w, double h, AquaMascotSpec spec) {
  final bodyPaint = Paint()..color = spec.secondaryColor;
  final flipperPaint = Paint()..color = spec.accentColor;

  // Flippers
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.19, h * 0.68),
      width: w * 0.24,
      height: h * 0.16,
    ),
    flipperPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.81, h * 0.68),
      width: w * 0.24,
      height: h * 0.16,
    ),
    flipperPaint,
  );

  // Chubby body & head
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.63),
        width: w * 0.68,
        height: h * 0.54,
      ),
      Radius.circular(w * 0.32),
    ),
    bodyPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.27),
      width: w * 0.46,
      height: h * 0.36,
    ),
    bodyPaint,
  );

  // Belly sheen
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.68),
      width: w * 0.44,
      height: h * 0.36,
    ),
    Paint()..color = AppColors.pureWhite.withValues(alpha: 0.65),
  );

  // Crystal gem on forehead
  final gem = Path()
    ..moveTo(w * 0.50, h * 0.12)
    ..lineTo(w * 0.55, h * 0.17)
    ..lineTo(w * 0.50, h * 0.22)
    ..lineTo(w * 0.45, h * 0.17)
    ..close();
  canvas.drawPath(gem, Paint()..color = AppColors.cyanVivid);

  // Blush
  final blush = Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.45);
  canvas.drawCircle(Offset(w * 0.33, h * 0.32), w * 0.04, blush);
  canvas.drawCircle(Offset(w * 0.67, h * 0.32), w * 0.04, blush);

  paintMascotMinimalFace(canvas, Size(w, h), 'hai_cau_ro', opacity: 0.95);
}

void _paintKidsAccessory(
  Canvas canvas,
  Size size,
  String mascotId,
  String accessoryName,
) {
  final w = size.width;
  final h = size.height;
  final lower = accessoryName.toLowerCase();

  if (lower.contains('vương miện') || lower.contains('crown')) {
    final crown = Path()
      ..moveTo(w * 0.36, h * 0.14)
      ..lineTo(w * 0.39, h * 0.03)
      ..lineTo(w * 0.45, h * 0.09)
      ..lineTo(w * 0.50, h * 0.01)
      ..lineTo(w * 0.55, h * 0.09)
      ..lineTo(w * 0.61, h * 0.03)
      ..lineTo(w * 0.64, h * 0.14)
      ..close();
    canvas.drawPath(crown, Paint()..color = AppColors.sunnyButter);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.08),
      w * 0.022,
      Paint()..color = AppColors.softCoral,
    );
  } else if (lower.contains('kính') || lower.contains('goggles')) {
    final framePaint = Paint()
      ..color = AppColors.navyInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.025);
    final lensPaint = Paint()
      ..color = AppColors.cyanVivid.withValues(alpha: 0.35);
    final y = mascotId == 'giot_nuoc' ? h * 0.63 : h * 0.52;
    for (final cx in [w * 0.38, w * 0.62]) {
      final rect = Rect.fromCenter(
        center: Offset(cx, y),
        width: w * 0.19,
        height: h * 0.11,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.05)),
        lensPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.05)),
        framePaint,
      );
    }
  } else if (lower.contains('áo choàng') || lower.contains('cape')) {
    final cape = Path()
      ..moveTo(w * 0.24, h * 0.72)
      ..quadraticBezierTo(w * 0.06, h * 0.82, w * 0.14, h * 0.94)
      ..quadraticBezierTo(w * 0.30, h * 0.90, w * 0.36, h * 0.84)
      ..close();
    canvas.drawPath(cape, Paint()..color = const Color(0xFFFF2469));
    final capeR = Path()
      ..moveTo(w * 0.76, h * 0.72)
      ..quadraticBezierTo(w * 0.94, h * 0.82, w * 0.86, h * 0.94)
      ..quadraticBezierTo(w * 0.70, h * 0.90, w * 0.64, h * 0.84)
      ..close();
    canvas.drawPath(capeR, Paint()..color = const Color(0xFFFF2469));
  } else if (lower.contains('chong chóng') || lower.contains('bamboo')) {
    canvas.drawLine(
      Offset(w * 0.50, h * 0.09),
      Offset(w * 0.50, h * 0.02),
      Paint()
        ..color = AppColors.emerald
        ..strokeWidth = math.max(2.0, w * 0.024)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.025),
        width: w * 0.32,
        height: h * 0.04,
      ),
      Paint()..color = AppColors.sunnyButter,
    );
  }
}

/// Renders an AquaCare Mascot in full-color, filled silhouette, or locked outline mode.
class AquaMascotVectorArt extends StatelessWidget {
  const AquaMascotVectorArt({
    super.key,
    required this.mascotId,
    this.size = 64,
    this.locked = false,
    this.accessoryName,
  });

  final String mascotId;
  final double size;
  final bool locked;
  final String? accessoryName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: CustomPaint(
        painter: _MascotArtPainter(
          mascotId: mascotId,
          locked: locked,
          accessoryName: accessoryName,
        ),
      ),
    );
  }
}

class _MascotArtPainter extends CustomPainter {
  const _MascotArtPainter({
    required this.mascotId,
    required this.locked,
    this.accessoryName,
  });

  final String mascotId;
  final bool locked;
  final String? accessoryName;

  @override
  void paint(Canvas canvas, Size size) {
    if (locked) {
      final path = buildMascotSilhouettePath(mascotId, size);
      canvas.drawPath(path, Paint()..color = AppColors.silhouetteGrey);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFC8D5DF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      return;
    }
    paintFullMascot(canvas, size, mascotId, accessoryName: accessoryName);
  }

  @override
  bool shouldRepaint(covariant _MascotArtPainter oldDelegate) =>
      oldDelegate.mascotId != mascotId ||
      oldDelegate.locked != locked ||
      oldDelegate.accessoryName != accessoryName;
}
