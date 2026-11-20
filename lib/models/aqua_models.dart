import 'dart:convert';

enum AppFlowStage {
  splash,
  onboarding,
  auth,
  setup,
  main,
}

enum AquaRole {
  studentWorker,
  household,
  kids,
}

extension AquaRoleDetails on AquaRole {
  String get label {
    switch (this) {
      case AquaRole.studentWorker:
        return 'SV / Đi làm';
      case AquaRole.household:
        return 'Hộ gia đình';
      case AquaRole.kids:
        return 'Bé AquaKids';
    }
  }
}

enum AquaGenderProfile {
  male,
  female,
  pregnant,
  breastfeeding,
  preferNotToSay,
}

extension AquaGenderProfileDetails on AquaGenderProfile {
  String get label => switch (this) {
        AquaGenderProfile.male => 'Nam giới',
        AquaGenderProfile.female => 'Nữ giới',
        AquaGenderProfile.pregnant => 'Đang mang thai',
        AquaGenderProfile.breastfeeding => 'Đang cho con bú',
        AquaGenderProfile.preferNotToSay => 'Không muốn nói',
      };

  double get mlPerKg => switch (this) {
        AquaGenderProfile.male => 35.0,
        AquaGenderProfile.female => 31.0,
        AquaGenderProfile.pregnant => 31.0,
        AquaGenderProfile.breastfeeding => 31.0,
        AquaGenderProfile.preferNotToSay => 33.0,
      };

  int get extraMl => switch (this) {
        AquaGenderProfile.pregnant => 300,
        AquaGenderProfile.breastfeeding => 650,
        _ => 0,
      };
}

enum AquaActivityLevel {
  light,
  moderate,
  active,
  intense,
}

extension AquaActivityLevelDetails on AquaActivityLevel {
  String get label => switch (this) {
        AquaActivityLevel.light => 'Ít vận động',
        AquaActivityLevel.moderate => 'Hoạt động tương đối',
        AquaActivityLevel.active => 'Vận động nhiều',
        AquaActivityLevel.intense => 'Tập luyện cường độ cao',
      };

  String get subtitle => switch (this) {
        AquaActivityLevel.light => 'Ngồi học / văn phòng nhiều',
        AquaActivityLevel.moderate => 'Đi bộ, sinh hoạt thường ngày',
        AquaActivityLevel.active => 'Thể dục 30–60 phút/ngày',
        AquaActivityLevel.intense => 'Vận động mạnh hoặc làm ngoài trời',
      };

  int get extraMl => switch (this) {
        AquaActivityLevel.light => 0,
        AquaActivityLevel.moderate => 180,
        AquaActivityLevel.active => 380,
        AquaActivityLevel.intense => 650,
      };
}

enum AquaClimateLevel {
  cool,
  temperate,
  humidWarm,
  veryHot,
}

extension AquaClimateLevelDetails on AquaClimateLevel {
  String get label => switch (this) {
        AquaClimateLevel.cool => 'Lạnh / mát mẻ',
        AquaClimateLevel.temperate => 'Ôn hòa',
        AquaClimateLevel.humidWarm => 'Nóng ẩm',
        AquaClimateLevel.veryHot => 'Nắng nóng gay gắt',
      };

  String get subtitle => switch (this) {
        AquaClimateLevel.cool => 'Dưới 20°C hoặc vùng mát',
        AquaClimateLevel.temperate => '20–28°C, thời tiết dễ chịu',
        AquaClimateLevel.humidWarm => '28–34°C, khí hậu nhiệt đới',
        AquaClimateLevel.veryHot => 'Trên 34°C, ra mồ hôi nhiều',
      };

  int get extraMl => switch (this) {
        AquaClimateLevel.cool => 0,
        AquaClimateLevel.temperate => 100,
        AquaClimateLevel.humidWarm => 280,
        AquaClimateLevel.veryHot => 500,
      };
}

enum AquaWeightUnit {
  kg,
  lbs,
}

class AquaHydrationBreakdown {
  const AquaHydrationBreakdown({
    required this.baseMl,
    required this.genderExtraMl,
    required this.activityExtraMl,
    required this.climateExtraMl,
    required this.totalMl,
  });

  final int baseMl;
  final int genderExtraMl;
  final int activityExtraMl;
  final int climateExtraMl;
  final int totalMl;
}

class AquaHydrationCalculator {
  AquaHydrationCalculator._();

  static AquaHydrationBreakdown breakdown({
    required double bodyWeightKg,
    required AquaGenderProfile gender,
    required AquaActivityLevel activity,
    required AquaClimateLevel climate,
  }) {
    final safeKg = bodyWeightKg.clamp(30.0, 160.0);
    final baseMl = (safeKg * gender.mlPerKg).round();
    final genderExtra = gender.extraMl;
    final activityExtra = activity.extraMl;
    final climateExtra = climate.extraMl;
    final rawTotal = baseMl + genderExtra + activityExtra + climateExtra;
    final totalMl = ((rawTotal / 10).round() * 10).clamp(1200, 4800);
    return AquaHydrationBreakdown(
      baseMl: baseMl,
      genderExtraMl: genderExtra,
      activityExtraMl: activityExtra,
      climateExtraMl: climateExtra,
      totalMl: totalMl,
    );
  }

  static int calculateRecommendedMl({
    required double bodyWeightKg,
    required AquaGenderProfile gender,
    required AquaActivityLevel activity,
    required AquaClimateLevel climate,
  }) {
    return breakdown(
      bodyWeightKg: bodyWeightKg,
      gender: gender,
      activity: activity,
      climate: climate,
    ).totalMl;
  }
}

enum AquaWaterSourceType {
  roPurified,
  tapSafe,
  mineralNatural,
}

extension AquaWaterSourceTypeDetails on AquaWaterSourceType {
  String get label => switch (this) {
        AquaWaterSourceType.roPurified => 'Lọc RO',
        AquaWaterSourceType.tapSafe => 'Nước máy / Đun sôi',
        AquaWaterSourceType.mineralNatural => 'Nước khoáng',
      };

  String get fullLabel => switch (this) {
        AquaWaterSourceType.roPurified => 'Nước lọc RO gia đình',
        AquaWaterSourceType.tapSafe => 'Nước máy đô thị / Đun sôi',
        AquaWaterSourceType.mineralNatural => 'Nước khoáng thiên nhiên',
      };

  String get standardRangeLabel => switch (this) {
        AquaWaterSourceType.roPurified => 'Chuẩn RO < 50 ppm',
        AquaWaterSourceType.tapSafe => 'QCVN ≤ 300 ppm',
        AquaWaterSourceType.mineralNatural => 'Khoáng WHO ≤ 300 ppm',
      };

  static AquaWaterSourceType fromSourceString(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.contains('ro') || lower.contains('máy lọc')) {
      return AquaWaterSourceType.roPurified;
    }
    if (lower.contains('khoáng') ||
        lower.contains('lavie') ||
        lower.contains('la vie') ||
        lower.contains('i-on') ||
        lower.contains('vĩnh hảo')) {
      return AquaWaterSourceType.mineralNatural;
    }
    return AquaWaterSourceType.tapSafe;
  }
}

enum AquaWaterSafetyStatus {
  safe,
  caution,
  warning,
}

/// Evaluates water safety against WHO & QCVN 01-1:2018/BYT thresholds per water source type.
class AquaWaterSafetyAssessment {
  const AquaWaterSafetyAssessment({
    required this.status,
    required this.headline,
    required this.detail,
    required this.standardNote,
    required this.isTdsOk,
    required this.isPhOk,
    required this.isChlorineOk,
    required this.isTurbidityOk,
    required this.estimatedChlorineMgL,
    required this.estimatedTurbidityNtu,
  });

  final AquaWaterSafetyStatus status;
  final String headline;
  final String detail;
  final String standardNote;
  final bool isTdsOk;
  final bool isPhOk;
  final bool isChlorineOk;
  final bool isTurbidityOk;
  final double estimatedChlorineMgL;
  final double estimatedTurbidityNtu;

  static AquaWaterSafetyAssessment evaluate({
    required int tdsPpm,
    required double phLevel,
    required AquaWaterSourceType sourceType,
  }) {
    final isPhOk = sourceType == AquaWaterSourceType.mineralNatural
        ? (phLevel >= 6.5 && phLevel <= 9.0)
        : (phLevel >= 6.5 && phLevel <= 8.5);

    final estimatedChlorineMgL = switch (sourceType) {
      AquaWaterSourceType.roPurified =>
        tdsPpm <= 50 ? 0.05 : ((tdsPpm / 260.0) * 0.45).clamp(0.10, 1.20),
      AquaWaterSourceType.tapSafe => tdsPpm <= 300
          ? (0.20 + tdsPpm / 1200.0).clamp(0.20, 0.45)
          : (0.55 + (tdsPpm - 300) / 400.0).clamp(0.55, 1.50),
      AquaWaterSourceType.mineralNatural => 0.0,
    };
    final isChlorineOk = estimatedChlorineMgL <= 0.5;

    final estimatedTurbidityNtu = switch (sourceType) {
      AquaWaterSourceType.roPurified =>
        (0.15 + (tdsPpm / 150.0)).clamp(0.15, 3.8),
      AquaWaterSourceType.tapSafe =>
        (0.35 + (tdsPpm / 180.0)).clamp(0.35, 4.2),
      AquaWaterSourceType.mineralNatural =>
        (0.20 + (tdsPpm / 380.0)).clamp(0.20, 2.8),
    };
    final isTurbidityOk = estimatedTurbidityNtu <= 2.0;

    if (tdsPpm > 300 || phLevel < 6.0 || phLevel > 9.2) {
      return AquaWaterSafetyAssessment(
        status: AquaWaterSafetyStatus.warning,
        headline: 'Cảnh báo vượt ngưỡng an toàn QCVN!',
        detail:
            'TDS > 300 ppm hoặc độ pH bất thường — nên kiểm tra lại nguồn nước / đun sôi trước khi dùng.',
        standardNote: 'Vượt ngưỡng QCVN 01-1:2018 (≤ 300 ppm)',
        isTdsOk: tdsPpm <= 300,
        isPhOk: isPhOk,
        isChlorineOk: isChlorineOk,
        isTurbidityOk: isTurbidityOk,
        estimatedChlorineMgL: estimatedChlorineMgL,
        estimatedTurbidityNtu: estimatedTurbidityNtu,
      );
    }

    if (sourceType == AquaWaterSourceType.roPurified && tdsPpm > 50) {
      return AquaWaterSafetyAssessment(
        status: AquaWaterSafetyStatus.caution,
        headline: 'TDS cao hơn mức chuẩn lọc RO',
        detail:
            'Nước vẫn dưới ngưỡng QCVN (300 ppm), nhưng bạn nên kiểm tra vệ sinh bộ lọc / màng RO.',
        standardNote: 'Nên giữ RO < 50 ppm',
        isTdsOk: false,
        isPhOk: isPhOk,
        isChlorineOk: isChlorineOk,
        isTurbidityOk: isTurbidityOk,
        estimatedChlorineMgL: estimatedChlorineMgL,
        estimatedTurbidityNtu: estimatedTurbidityNtu,
      );
    }

    if (!isPhOk) {
      return AquaWaterSafetyAssessment(
        status: AquaWaterSafetyStatus.caution,
        headline: 'Độ pH lệch khỏi khoảng khuyến nghị',
        detail:
            'Độ pH lý tưởng cho nước uống hằng ngày là 6.5 – 8.5 theo chuẩn WHO / QCVN.',
        standardNote: 'Khuyến nghị pH 6.5 – 8.5',
        isTdsOk: true,
        isPhOk: false,
        isChlorineOk: isChlorineOk,
        isTurbidityOk: isTurbidityOk,
        estimatedChlorineMgL: estimatedChlorineMgL,
        estimatedTurbidityNtu: estimatedTurbidityNtu,
      );
    }

    return switch (sourceType) {
      AquaWaterSourceType.roPurified => AquaWaterSafetyAssessment(
          status: AquaWaterSafetyStatus.safe,
          headline: 'An toàn uống trực tiếp ✓',
          detail:
              'Nước lọc tinh khiết đạt chuẩn uống trực tiếp (WHO / QCVN 01-1:2018).',
          standardNote: 'Chuẩn RO (< 50 ppm)',
          isTdsOk: true,
          isPhOk: true,
          isChlorineOk: isChlorineOk,
          isTurbidityOk: isTurbidityOk,
          estimatedChlorineMgL: estimatedChlorineMgL,
          estimatedTurbidityNtu: estimatedTurbidityNtu,
        ),
      AquaWaterSourceType.tapSafe => AquaWaterSafetyAssessment(
          status: AquaWaterSafetyStatus.safe,
          headline: 'Đạt chuẩn nước sinh hoạt QCVN ✓',
          detail:
              'Chỉ số nằm trong ngưỡng an toàn ≤ 300 ppm; nên đun sôi hoặc lọc trước khi uống trực tiếp.',
          standardNote: 'Chuẩn QCVN (≤ 300 ppm)',
          isTdsOk: true,
          isPhOk: true,
          isChlorineOk: isChlorineOk,
          isTurbidityOk: isTurbidityOk,
          estimatedChlorineMgL: estimatedChlorineMgL,
          estimatedTurbidityNtu: estimatedTurbidityNtu,
        ),
      AquaWaterSourceType.mineralNatural => AquaWaterSafetyAssessment(
          status: AquaWaterSafetyStatus.safe,
          headline: 'Nước khoáng an toàn (WHO/QCVN) ✓',
          detail:
              'Hàm lượng khoáng hòa tan tự nhiên phù hợp bù điện giải hằng ngày.',
          standardNote: 'Khoáng an toàn (≤ 300 ppm)',
          isTdsOk: true,
          isPhOk: true,
          isChlorineOk: isChlorineOk,
          isTurbidityOk: isTurbidityOk,
          estimatedChlorineMgL: estimatedChlorineMgL,
          estimatedTurbidityNtu: estimatedTurbidityNtu,
        ),
    };
  }
}

class AquaSanitationTask {
  const AquaSanitationTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cadenceLabel,
    required this.isDaily,
    this.completed = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String cadenceLabel;
  final bool isDaily;
  final bool completed;

  AquaSanitationTask copyWith({bool? completed}) {
    return AquaSanitationTask(
      id: id,
      title: title,
      subtitle: subtitle,
      cadenceLabel: cadenceLabel,
      isDaily: isDaily,
      completed: completed ?? this.completed,
    );
  }

  static const List<AquaSanitationTask> householdDefaults = [
    AquaSanitationTask(
      id: 'hh_faucet',
      title: 'Khử khuẩn vòi rót & bình đựng nước',
      subtitle: 'Lau sạch đầu vòi lấy nước uống và tráng bình chứa bằng nước sôi',
      cadenceLabel: 'Mỗi tuần',
      isDaily: false,
    ),
    AquaSanitationTask(
      id: 'hh_handwash',
      title: 'Đủ xà phòng tại bồn rửa tay gia đình',
      subtitle: 'Duy trì thói quen rửa tay 6 bước 20 giây cho cả nhà',
      cadenceLabel: 'Mỗi ngày',
      isDaily: true,
    ),
    AquaSanitationTask(
      id: 'hh_tank',
      title: 'Kiểm tra nắp đậy & độ sạch bồn chứa',
      subtitle: 'Đảm bảo bồn nước kín côn trùng và không đóng cặn rêu',
      cadenceLabel: 'Định kỳ',
      isDaily: false,
    ),
    AquaSanitationTask(
      id: 'hh_leak',
      title: 'Kiểm tra van khóa & đường ống chống rò rỉ',
      subtitle: 'Ngắt giọt rò rỉ tại bồn rửa, vòi sen để tiết kiệm nước sạch',
      cadenceLabel: 'Mỗi tuần',
      isDaily: false,
    ),
  ];

  static const List<AquaSanitationTask> personalDefaults = [
    AquaSanitationTask(
      id: 'st_bottle',
      title: 'Rửa bình nước cá nhân bằng nước ấm & xà phòng',
      subtitle: 'Ngăn màng sinh học & vi khuẩn tích tụ trong bình tái sử dụng',
      cadenceLabel: 'Mỗi ngày',
      isDaily: true,
    ),
    AquaSanitationTask(
      id: 'st_handwash',
      title: 'Rửa tay 20 giây trước khi ăn & sau vệ sinh',
      subtitle: 'Thực hành vệ sinh cá nhân chuẩn Bộ Y tế & WHO (WASH)',
      cadenceLabel: 'Mỗi ngày',
      isDaily: true,
    ),
    AquaSanitationTask(
      id: 'st_refill',
      title: 'Mang bình cá nhân & ưu tiên Refill giảm nhựa',
      subtitle: 'Tránh chai nhựa dùng 1 lần để bảo vệ nguồn nước SDG 6',
      cadenceLabel: 'Mỗi ngày',
      isDaily: true,
    ),
  ];
}

class AquaBotMessage {
  const AquaBotMessage({
    required this.isUser,
    required this.text,
    this.timestamp = '',
  });

  final bool isUser;
  final String text;
  final String timestamp;

  Map<String, dynamic> toJson() => {
        'isUser': isUser,
        'text': text,
        'timestamp': timestamp,
      };

  factory AquaBotMessage.fromJson(Map<String, dynamic> json) {
    return AquaBotMessage(
      isUser: json['isUser'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class AquaBeverageSpec {
  const AquaBeverageSpec({
    required this.name,
    required this.hydrationFactor,
    required this.caffeinePer250Ml,
    this.colorValue = 0xFF00C2EC,
    this.iconKind = 'water',
  });

  final String name;
  final double hydrationFactor;
  final int caffeinePer250Ml;
  final int colorValue;
  final String iconKind;

  static const List<AquaBeverageSpec> catalog = [
    AquaBeverageSpec(
      name: 'Nước lọc',
      hydrationFactor: 1.0,
      caffeinePer250Ml: 0,
      colorValue: 0xFF00C2EC,
      iconKind: 'water',
    ),
    AquaBeverageSpec(
      name: 'Nước ấm',
      hydrationFactor: 1.0,
      caffeinePer250Ml: 0,
      colorValue: 0xFF4ED8F5,
      iconKind: 'warm_water',
    ),
    AquaBeverageSpec(
      name: 'Trà xanh',
      hydrationFactor: 0.95,
      caffeinePer250Ml: 30,
      colorValue: 0xFF7BC138,
      iconKind: 'green_tea',
    ),
    AquaBeverageSpec(
      name: 'Cà phê',
      hydrationFactor: 0.80,
      caffeinePer250Ml: 80,
      colorValue: 0xFF6B4837,
      iconKind: 'coffee',
    ),
    AquaBeverageSpec(
      name: 'Cà phê sữa',
      hydrationFactor: 0.80,
      caffeinePer250Ml: 65,
      colorValue: 0xFFB57C4F,
      iconKind: 'milk_coffee',
    ),
    AquaBeverageSpec(
      name: 'Nước dừa',
      hydrationFactor: 1.05,
      caffeinePer250Ml: 0,
      colorValue: 0xFF2CC8AE,
      iconKind: 'coconut',
    ),
    AquaBeverageSpec(
      name: 'Sữa hạt',
      hydrationFactor: 0.90,
      caffeinePer250Ml: 0,
      colorValue: 0xFFD9B991,
      iconKind: 'nut_milk',
    ),
    AquaBeverageSpec(
      name: 'Nước ép',
      hydrationFactor: 0.85,
      caffeinePer250Ml: 0,
      colorValue: 0xFFFFA31A,
      iconKind: 'juice',
    ),
  ];

  static AquaBeverageSpec of(String drinkName) {
    final normalized = drinkName.trim().toLowerCase();
    for (final spec in catalog) {
      if (spec.name.toLowerCase() == normalized) {
        return spec;
      }
    }
    return catalog.first;
  }

  static int colorValueForName(String name) {
    final lower = name.trim().toLowerCase();
    for (final spec in catalog) {
      if (spec.name.toLowerCase() == lower) {
        return spec.colorValue;
      }
    }
    if (lower.contains('cà phê sữa') || lower.contains('bạc xỉu')) {
      return 0xFFB57C4F;
    }
    if (lower.contains('cà phê') || lower.contains('coffee')) {
      return 0xFF6B4837;
    }
    if (lower.contains('trà') || lower.contains('matcha')) {
      return 0xFF7BC138;
    }
    if (lower.contains('dừa')) return 0xFF2CC8AE;
    if (lower.contains('sữa')) return 0xFFD9B991;
    if (lower.contains('ép') || lower.contains('cam')) return 0xFFFFA31A;
    if (lower.contains('ấm')) return 0xFF4ED8F5;
    if (lower.contains('refill')) return 0xFF10B981;
    return 0xFF00C2EC;
  }

  static String iconKindForName(String name) {
    final lower = name.trim().toLowerCase();
    for (final spec in catalog) {
      if (spec.name.toLowerCase() == lower) {
        return spec.iconKind;
      }
    }
    if (lower.contains('cà phê sữa') || lower.contains('bạc xỉu')) {
      return 'milk_coffee';
    }
    if (lower.contains('cà phê') || lower.contains('coffee')) {
      return 'coffee';
    }
    if (lower.contains('trà') || lower.contains('matcha')) {
      return 'green_tea';
    }
    if (lower.contains('dừa')) return 'coconut';
    if (lower.contains('sữa')) return 'nut_milk';
    if (lower.contains('ép') || lower.contains('cam')) return 'juice';
    if (lower.contains('ấm')) return 'warm_water';
    return 'water';
  }

  int computeEffectiveMl(int rawMl) => (rawMl * hydrationFactor).round();

  int computeCaffeineMg(int rawMl) {
    if (caffeinePer250Ml == 0) return 0;
    return ((rawMl / 250.0) * caffeinePer250Ml).round();
  }
}

class AquaDrinkLogEntry {
  const AquaDrinkLogEntry({
    required this.time,
    required this.drink,
    required this.ml,
    this.id = '',
    int? rawMl,
    this.caffeineMg = 0,
  }) : rawMl = rawMl ?? ml;

  final String id;
  final String time;
  final String drink;
  final int ml;
  final int rawMl;
  final int caffeineMg;

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'drink': drink,
        'ml': ml,
        'rawMl': rawMl,
        'caffeineMg': caffeineMg,
      };

  factory AquaDrinkLogEntry.fromJson(Map<String, dynamic> json) {
    final effective = json['ml'] as int? ?? 250;
    return AquaDrinkLogEntry(
      id: json['id'] as String? ?? '',
      time: json['time'] as String? ?? '08:00',
      drink: json['drink'] as String? ?? 'Nước lọc',
      ml: effective,
      rawMl: json['rawMl'] as int? ?? effective,
      caffeineMg: json['caffeineMg'] as int? ?? 0,
    );
  }
}

class AquaRefillStation {
  const AquaRefillStation({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.tdsPpm,
    required this.isFree,
    required this.hasHotCold,
    required this.isOpen24h,
    required this.xFactor,
    required this.yFactor,
    this.latitude = 15.9686,
    this.longitude = 108.2605,
    this.isUserProposed = false,
    this.hasHandwashSanitation = false,
  });

  final int id;
  final String name;
  final int distanceMeters;
  final int tdsPpm;
  final bool isFree;
  final bool hasHotCold;
  final bool isOpen24h;
  final double xFactor;
  final double yFactor;
  final double latitude;
  final double longitude;
  final bool isUserProposed;
  final bool hasHandwashSanitation;

  AquaRefillStation copyWith({
    int? distanceMeters,
    int? tdsPpm,
    bool? hasHandwashSanitation,
  }) {
    return AquaRefillStation(
      id: id,
      name: name,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      tdsPpm: tdsPpm ?? this.tdsPpm,
      isFree: isFree,
      hasHotCold: hasHotCold,
      isOpen24h: isOpen24h,
      xFactor: xFactor,
      yFactor: yFactor,
      latitude: latitude,
      longitude: longitude,
      isUserProposed: isUserProposed,
      hasHandwashSanitation:
          hasHandwashSanitation ?? this.hasHandwashSanitation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'distanceMeters': distanceMeters,
        'tdsPpm': tdsPpm,
        'isFree': isFree,
        'hasHotCold': hasHotCold,
        'isOpen24h': isOpen24h,
        'xFactor': xFactor,
        'yFactor': yFactor,
        'latitude': latitude,
        'longitude': longitude,
        'isUserProposed': isUserProposed,
        'hasHandwashSanitation': hasHandwashSanitation,
      };

  factory AquaRefillStation.fromJson(Map<String, dynamic> json) {
    return AquaRefillStation(
      id: json['id'] as int? ?? 100,
      name: json['name'] as String? ?? 'Trạm Refill Cộng đồng',
      distanceMeters: json['distanceMeters'] as int? ?? 300,
      tdsPpm: json['tdsPpm'] as int? ?? 35,
      isFree: json['isFree'] as bool? ?? true,
      hasHotCold: json['hasHotCold'] as bool? ?? false,
      isOpen24h: json['isOpen24h'] as bool? ?? false,
      xFactor: (json['xFactor'] as num?)?.toDouble() ?? 0.5,
      yFactor: (json['yFactor'] as num?)?.toDouble() ?? 0.5,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 15.9686,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 108.2605,
      isUserProposed: json['isUserProposed'] as bool? ?? true,
      hasHandwashSanitation: json['hasHandwashSanitation'] as bool? ?? false,
    );
  }
}

class AquaWaterTestRecord {
  const AquaWaterTestRecord({
    required this.id,
    required this.dateLabel,
    required this.tdsPpm,
    required this.phLevel,
    required this.sourceNote,
  });

  final String id;
  final String dateLabel;
  final int tdsPpm;
  final double phLevel;
  final String sourceNote;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateLabel': dateLabel,
        'tdsPpm': tdsPpm,
        'phLevel': phLevel,
        'sourceNote': sourceNote,
      };

  factory AquaWaterTestRecord.fromJson(Map<String, dynamic> json) {
    return AquaWaterTestRecord(
      id: json['id'] as String? ?? 't0',
      dateLabel: json['dateLabel'] as String? ?? 'Hôm nay',
      tdsPpm: json['tdsPpm'] as int? ?? 36,
      phLevel: (json['phLevel'] as num?)?.toDouble() ?? 7.3,
      sourceNote: json['sourceNote'] as String? ?? 'Máy lọc RO gia đình',
    );
  }
}

class AquaTechBooking {
  const AquaTechBooking({
    required this.id,
    required this.slotLabel,
    required this.createdAtLabel,
    this.completed = false,
  });

  final String id;
  final String slotLabel;
  final String createdAtLabel;
  final bool completed;

  AquaTechBooking copyWith({bool? completed}) {
    return AquaTechBooking(
      id: id,
      slotLabel: slotLabel,
      createdAtLabel: createdAtLabel,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slotLabel': slotLabel,
        'createdAtLabel': createdAtLabel,
        'completed': completed,
      };

  factory AquaTechBooking.fromJson(Map<String, dynamic> json) {
    return AquaTechBooking(
      id: json['id'] as String? ?? 'b0',
      slotLabel: json['slotLabel'] as String? ?? '09:00 Sáng mai',
      createdAtLabel: json['createdAtLabel'] as String? ?? 'Hôm nay',
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class AquaWaterBillEntry {
  const AquaWaterBillEntry({
    required this.monthLabel,
    required this.cubicMeters,
    required this.amountVnd,
    required this.isLeakSuspected,
  });

  final String monthLabel;
  final double cubicMeters;
  final int amountVnd;
  final bool isLeakSuspected;

  /// Calculates tiered Vietnamese household water tariff + 10% VAT/BVMT.
  static int calculateVnd(double m3) {
    if (m3 <= 0) return 0;
    double subtotal = 0;
    double rem = m3;
    final tier1 = rem.clamp(0.0, 10.0);
    subtotal += tier1 * 6800;
    rem -= tier1;
    if (rem > 0) {
      final tier2 = rem.clamp(0.0, 10.0);
      subtotal += tier2 * 8100;
      rem -= tier2;
    }
    if (rem > 0) {
      final tier3 = rem.clamp(0.0, 10.0);
      subtotal += tier3 * 10200;
      rem -= tier3;
    }
    if (rem > 0) {
      subtotal += rem * 13800;
    }
    return (subtotal * 1.1).round();
  }

  static String formatVnd(int vnd) {
    final s = vnd.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final reverseIndex = s.length - i;
      buf.write(s[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buf.write('.');
      }
    }
    return '${buf.toString()}đ';
  }
}

class AquaIncidentReport {
  const AquaIncidentReport({
    required this.id,
    required this.title,
    required this.severity,
    required this.stationName,
    required this.createdAtLabel,
    this.status = 'Đang tiếp nhận',
    this.upvotes = 1,
  });

  final String id;
  final String title;
  final int severity;
  final String stationName;
  final String createdAtLabel;
  final String status;
  final int upvotes;

  AquaIncidentReport copyWith({int? upvotes, String? status}) {
    return AquaIncidentReport(
      id: id,
      title: title,
      severity: severity,
      stationName: stationName,
      createdAtLabel: createdAtLabel,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'severity': severity,
        'stationName': stationName,
        'createdAtLabel': createdAtLabel,
        'status': status,
        'upvotes': upvotes,
      };

  factory AquaIncidentReport.fromJson(Map<String, dynamic> json) {
    return AquaIncidentReport(
      id: json['id'] as String? ?? 'inc0',
      title: json['title'] as String? ?? 'Sự cố nguồn nước',
      severity: json['severity'] as int? ?? 1,
      stationName: json['stationName'] as String? ?? 'Khu vực chung',
      createdAtLabel: json['createdAtLabel'] as String? ?? 'Vừa xong',
      status: json['status'] as String? ?? 'Đang tiếp nhận',
      upvotes: json['upvotes'] as int? ?? 1,
    );
  }
}

class AquaKidsQuizQuestion {
  const AquaKidsQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  static const List<AquaKidsQuizQuestion> bank = [
    AquaKidsQuizQuestion(
      question: 'Nguồn nước nào an toàn nhất để Bé uống trực tiếp mỗi ngày?',
      options: [
        'A. Nước đã lọc sạch qua máy RO hoặc đun sôi',
        'B. Nước mưa hứng trực tiếp chưa lọc',
        'C. Nước ngọt có ga nhiều đường',
        'D. Nước hồ bơi trong xanh',
      ],
      correctIndex: 0,
      explanation: 'Nước RO sạch hoặc nước đun sôi để nguội giúp cơ thể khỏe mạnh!',
    ),
    AquaKidsQuizQuestion(
      question: 'Khi đang chải xà phòng đánh răng hoặc rửa tay, Bé nên làm gì với vòi nước?',
      options: [
        'A. Để vòi chảy mạnh cho vui',
        'B. Khóa chặt vòi để tiết kiệm từng giọt nước',
        'C. Mở cả 2 vòi cùng lúc',
        'D. Xả đầy chậu rồi đổ đi',
      ],
      correctIndex: 1,
      explanation: 'Khóa vòi lúc xà phòng giúp tiết kiệm hàng chục lít nước sạch mỗi ngày!',
    ),
    AquaKidsQuizQuestion(
      question: 'Bé nên mang theo gì khi đi học để bảo vệ đại dương giảm rác thải nhựa?',
      options: [
        'A. Mua 3 chai nhựa dùng 1 lần',
        'B. Dùng ly nhựa mỏng',
        'C. Mang bình nước cá nhân tái sử dụng để Refill',
        'D. Không uống nước cả ngày',
      ],
      correctIndex: 2,
      explanation: 'Bình nước cá nhân giúp cứu hàng trăm chai nhựa khỏi trôi ra biển!',
    ),
    AquaKidsQuizQuestion(
      question: 'Rửa tay đúng cách với xà phòng gồm mấy bước theo chuẩn Bộ Y tế?',
      options: [
        'A. 2 bước nhanh',
        'B. 6 bước sạch khuẩn trong ít nhất 20 giây',
        'C. Chỉ rửa mỗi đầu ngón tay',
        'D. Không cần dùng xà phòng',
      ],
      correctIndex: 1,
      explanation: '6 bước rửa tay với xà phòng giúp đánh bay vi khuẩn bảo vệ sức khỏe!',
    ),
    AquaKidsQuizQuestion(
      question: 'Mục tiêu phát triển bền vững Liên Hợp Quốc số 6 (SDG 6) nói về điều gì?',
      options: [
        'A. Nước sạch và Vệ sinh cho mọi người',
        'B. Trò chơi điện tử miễn phí',
        'C. Ăn thật nhiều bánh kẹo',
        'D. Xây thật nhiều nhà cao tầng',
      ],
      correctIndex: 0,
      explanation: 'SDG 6 bảo đảm nguồn nước sạch và vệ sinh an toàn cho mọi bạn nhỏ trên Trái Đất!',
    ),
    AquaKidsQuizQuestion(
      question: 'Chỉ số TDS của nước uống trực tiếp qua máy RO thường đạt chuẩn ở mức nào?',
      options: [
        'A. Trên 500 ppm',
        'B. Từ 300 đến 400 ppm',
        'C. Dưới 50 ppm',
        'D. Bằng 1000 ppm',
      ],
      correctIndex: 2,
      explanation: 'Nước lọc tinh khiết chuẩn uống trực tiếp thường có TDS dưới 50 ppm!',
    ),
    AquaKidsQuizQuestion(
      question: 'Bé thấy bạn quên khóa vòi nước ở trường thì Bé nên làm gì?',
      options: [
        'A. Chạy đi luôn không quan tâm',
        'B. Vặn khóa vòi ngay và nhắc bạn cùng tiết kiệm nước',
        'C. Mở to hơn nữa',
        'D. Hắt nước tung tóe',
      ],
      correctIndex: 1,
      explanation: 'Bạn nhỏ văn minh luôn giúp khóa vòi nước rò rỉ ngay khi nhìn thấy!',
    ),
    AquaKidsQuizQuestion(
      question: 'Thời điểm nào trong ngày Bé rất cần uống 1 cốc nước ấm nhỏ để khởi động cơ thể?',
      options: [
        'A. Ngay sau khi thức dậy buổi sáng',
        'B. Chỉ uống lúc nửa đêm',
        'C. Chỉ uống khi thấy khát khô cổ',
        'D. Không cần uống vào buổi sáng',
      ],
      correctIndex: 0,
      explanation: 'Uống 1 cốc nước sau khi thức dậy giúp não bộ tỉnh táo và học bài giỏi hơn!',
    ),
    AquaKidsQuizQuestion(
      question: 'Nước thừa sau khi rửa rau ở nhà có thể tận dụng để làm gì cho xanh?',
      options: [
        'A. Đổ thẳng xuống cống',
        'B. Tưới cây xanh hoặc chậu hoa ban công',
        'C. Để bốc mùi trong bếp',
        'D. Đổ vào bình nước uống',
      ],
      correctIndex: 1,
      explanation: 'Tái sử dụng nước rửa rau để tưới cây giúp gia đình tiết kiệm nước thông minh!',
    ),
    AquaKidsQuizQuestion(
      question: 'Khi chạy nhảy ra nhiều mồ hôi, loại đồ uống nào tốt nhất cho Bé?',
      options: [
        'A. Nước tăng lực người lớn',
        'B. Trà đặc có caffeine',
        'C. Nước ngọt phẩm màu',
        'D. Nước lọc sạch mát hoặc nước khoáng nhẹ',
      ],
      correctIndex: 3,
      explanation: 'Nước lọc tinh khiết bù nước nhanh nhất và an toàn tuyệt đối cho Bé!',
    ),
  ];
}

class AquaMascotAccessory {
  const AquaMascotAccessory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.costStars,
  });

  final String id;
  final String name;
  final String emoji;
  final int costStars;

  static const List<AquaMascotAccessory> shopItems = [
    AquaMascotAccessory(
      id: 'crown',
      name: 'Vương miện Giọt Nước',
      emoji: '👑',
      costStars: 0,
    ),
    AquaMascotAccessory(
      id: 'cape',
      name: 'Áo choàng Hiệp sĩ',
      emoji: '🦸',
      costStars: 40,
    ),
    AquaMascotAccessory(
      id: 'goggles',
      name: 'Kính lặn Đại dương',
      emoji: '🥽',
      costStars: 60,
    ),
    AquaMascotAccessory(
      id: 'bamboo',
      name: 'Chong chóng Tre Xanh',
      emoji: '🌿',
      costStars: 80,
    ),
  ];

  static String badgeDisplayFor(String name) {
    for (final item in shopItems) {
      if (item.name == name) return '${item.emoji} ${item.name}';
    }
    return '👑 $name';
  }
}

String aquaDayKey(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String aquaWeekdayShort(DateTime dt) {
  switch (dt.weekday) {
    case DateTime.monday:
      return 'T2';
    case DateTime.tuesday:
      return 'T3';
    case DateTime.wednesday:
      return 'T4';
    case DateTime.thursday:
      return 'T5';
    case DateTime.friday:
      return 'T6';
    case DateTime.saturday:
      return 'T7';
    default:
      return 'CN';
  }
}

String encodeAquaJson(Map<String, dynamic> data) => jsonEncode(data);
