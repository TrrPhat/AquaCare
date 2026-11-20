import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/animations/aqua_motion.dart';

enum AquaScannedKind {
  waterBottle,
  refillStation,
  roFilterCartridge,
  mineralOrTdsCheck,
  genericText,
}

class AquaScannedCodeResult {
  const AquaScannedCodeResult({
    required this.rawCode,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.brand = '',
    this.recommendedMl = 500,
    this.estimatedTdsPpm,
    this.estimatedPh,
    this.stationName,
    this.filterSlotIndex,
    this.sourceLabel = 'Mã QR / Vạch',
    this.isVerifiedMatch = false,
  });

  final String rawCode;
  final AquaScannedKind kind;
  final String title;
  final String subtitle;
  final String brand;
  final int recommendedMl;
  final int? estimatedTdsPpm;
  final double? estimatedPh;
  final String? stationName;
  final int? filterSlotIndex;
  final String sourceLabel;
  final bool isVerifiedMatch;

  AquaScannedCodeResult copyWith({
    int? recommendedMl,
  }) {
    return AquaScannedCodeResult(
      rawCode: rawCode,
      kind: kind,
      title: title,
      subtitle: subtitle,
      brand: brand,
      recommendedMl: recommendedMl ?? this.recommendedMl,
      estimatedTdsPpm: estimatedTdsPpm,
      estimatedPh: estimatedPh,
      stationName: stationName,
      filterSlotIndex: filterSlotIndex,
      sourceLabel: sourceLabel,
      isVerifiedMatch: isVerifiedMatch,
    );
  }
}

class _VnWaterCatalogEntry {
  const _VnWaterCatalogEntry({
    required this.brand,
    required this.productTitle,
    required this.defaultMl,
    required this.tdsPpm,
    required this.ph,
    required this.note,
  });

  final String brand;
  final String productTitle;
  final int defaultMl;
  final int tdsPpm;
  final double ph;
  final String note;
}

class AquaBarcodeLookupService {
  AquaBarcodeLookupService._();

  static final RegExp _numericBarcodePattern = RegExp(r'^\d{8,14}$');

  static const Map<String, _VnWaterCatalogEntry> _exactSkuCatalog = {
    '8935012011340': _VnWaterCatalogEntry(
      brand: 'La Vie',
      productTitle: 'Nước khoáng thiên nhiên La Vie 500ml',
      defaultMl: 500,
      tdsPpm: 155,
      ph: 7.7,
      note: 'Bổ sung khoáng Canxi, Magie, Natri, Kali tự nhiên',
    ),
    '8935012011357': _VnWaterCatalogEntry(
      brand: 'La Vie',
      productTitle: 'Nước khoáng thiên nhiên La Vie 350ml',
      defaultMl: 350,
      tdsPpm: 155,
      ph: 7.7,
      note: 'Chai gọn cho học sinh, văn phòng',
    ),
    '8935012011364': _VnWaterCatalogEntry(
      brand: 'La Vie',
      productTitle: 'Nước khoáng thiên nhiên La Vie 1.5L',
      defaultMl: 500,
      tdsPpm: 155,
      ph: 7.7,
      note: 'Chai dung tích lớn — mặc định cộng 500 ml mỗi lần uống',
    ),
    '8934588013058': _VnWaterCatalogEntry(
      brand: 'Aquafina',
      productTitle: 'Nước tinh khiết Aquafina 500ml',
      defaultMl: 500,
      tdsPpm: 15,
      ph: 6.8,
      note: 'Công nghệ lọc Hydro-7 tinh khiết',
    ),
    '8934588012112': _VnWaterCatalogEntry(
      brand: 'Aquafina',
      productTitle: 'Nước tinh khiết Aquafina 1.5L',
      defaultMl: 500,
      tdsPpm: 15,
      ph: 6.8,
      note: 'Chai lớn 1.5L — ghi nhận nhanh 500 ml/lần uống',
    ),
  };

  static const Map<String, _VnWaterCatalogEntry> _prefixCatalog = {
    '8935012': _VnWaterCatalogEntry(
      brand: 'La Vie',
      productTitle: 'Nước khoáng thiên nhiên La Vie',
      defaultMl: 500,
      tdsPpm: 155,
      ph: 7.7,
      note: 'Thương hiệu nước khoáng Việt Nam (GS1 8935012)',
    ),
    '8934588': _VnWaterCatalogEntry(
      brand: 'Aquafina',
      productTitle: 'Nước tinh khiết Aquafina',
      defaultMl: 500,
      tdsPpm: 15,
      ph: 6.8,
      note: 'Nước uống đóng chai tinh khiết (GS1 8934588)',
    ),
    '8935049': _VnWaterCatalogEntry(
      brand: 'Dasani',
      productTitle: 'Nước tinh khiết Dasani',
      defaultMl: 500,
      tdsPpm: 22,
      ph: 6.9,
      note: 'Nước uống tinh khiết Coca-Cola VN (GS1 8935049)',
    ),
    '8936073': _VnWaterCatalogEntry(
      brand: 'i-on Life',
      productTitle: 'Nước uống ion kiềm i-on Life',
      defaultMl: 450,
      tdsPpm: 95,
      ph: 8.8,
      note: 'Nước kiềm tính tự nhiên pH 8.5–9.5',
    ),
    '8935001': _VnWaterCatalogEntry(
      brand: 'Vĩnh Hảo',
      productTitle: 'Nước khoáng thiên nhiên Vĩnh Hảo',
      defaultMl: 500,
      tdsPpm: 180,
      ph: 7.4,
      note: 'Giàu Bicarbonate hỗ trợ tiêu hóa',
    ),
    '8935015': _VnWaterCatalogEntry(
      brand: 'Vĩnh Hảo',
      productTitle: 'Nước khoáng thiên nhiên Vĩnh Hảo',
      defaultMl: 500,
      tdsPpm: 180,
      ph: 7.4,
      note: 'Giàu Bicarbonate hỗ trợ tiêu hóa',
    ),
    '8935217': _VnWaterCatalogEntry(
      brand: 'TH true WATER',
      productTitle: 'Nước tinh khiết TH true WATER',
      defaultMl: 500,
      tdsPpm: 18,
      ph: 7.0,
      note: 'Nguồn nước ngầm núi lửa tự nhiên',
    ),
    '893850': _VnWaterCatalogEntry(
      brand: 'Satori',
      productTitle: 'Nước hoàn lưu khoáng Satori',
      defaultMl: 500,
      tdsPpm: 55,
      ph: 7.2,
      note: 'Công nghệ hoàn lưu khoáng sRO',
    ),
    '8936027': _VnWaterCatalogEntry(
      brand: 'Satori',
      productTitle: 'Nước hoàn lưu khoáng Satori',
      defaultMl: 500,
      tdsPpm: 55,
      ph: 7.2,
      note: 'Công nghệ hoàn lưu khoáng sRO',
    ),
    '4987035': _VnWaterCatalogEntry(
      brand: 'Pocari Sweat',
      productTitle: 'Thức uống bổ sung ion Pocari Sweat',
      defaultMl: 500,
      tdsPpm: 240,
      ph: 6.5,
      note: 'Bù nước & điện giải nhanh sau vận động',
    ),
    '8936036': _VnWaterCatalogEntry(
      brand: 'Pocari Sweat',
      productTitle: 'Thức uống bổ sung ion Pocari Sweat',
      defaultMl: 500,
      tdsPpm: 240,
      ph: 6.5,
      note: 'Bù nước & điện giải nhanh sau vận động',
    ),
  };

  static Future<AquaScannedCodeResult> lookup(
    String rawCode, {
    http.Client? client,
  }) async {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      return const AquaScannedCodeResult(
        rawCode: '',
        kind: AquaScannedKind.genericText,
        title: 'Chưa nhận diện được mã',
        subtitle: 'Vui lòng đưa mã QR hoặc mã vạch vào giữa khung quét.',
        recommendedMl: 250,
      );
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final jsonMatch = _tryParseJsonPayload(trimmed);
      if (jsonMatch != null) return jsonMatch;
    }

    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('aquacare://')) {
      final urlMatch = _tryParseUrlPayload(trimmed);
      if (urlMatch != null) return urlMatch;
    }

    if (_numericBarcodePattern.hasMatch(trimmed)) {
      return _lookupNumericBarcode(trimmed, client: client);
    }

    return _parseStructuredTextCode(trimmed);
  }

  static AquaScannedCodeResult? _tryParseJsonPayload(String rawCode) {
    try {
      final decoded = jsonDecode(rawCode);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final type = (map['type'] ?? map['kind'] ?? '').toString().toLowerCase();
      final name = (map['name'] ?? map['title'] ?? map['station'] ?? '')
          .toString()
          .trim();
      final brand = (map['brand'] ?? '').toString().trim();
      final ml = _asInt(map['ml'] ?? map['volumeMl'] ?? map['volume']) ?? 500;
      final tds = _asInt(map['tds'] ?? map['tdsPpm']);
      final ph = _asDouble(map['ph'] ?? map['phLevel']);
      final slot = _asInt(map['slot'] ?? map['filterSlot'] ?? map['cartridge']);

      if (type == 'station' || type == 'refill' || map.containsKey('station')) {
        final station = name.isEmpty ? 'Trạm Refill AquaCare' : name;
        return AquaScannedCodeResult(
          rawCode: rawCode,
          kind: AquaScannedKind.refillStation,
          title: 'Trạm Refill: $station',
          subtitle: tds != null
              ? 'Nước uống đạt chuẩn (TDS $tds ppm) · Tích điểm bình cá nhân'
              : 'Xác thực lấy nước từ Trạm Refill cộng đồng',
          stationName: station,
          recommendedMl: ml.clamp(100, 2000),
          estimatedTdsPpm: tds ?? 20,
          estimatedPh: ph ?? 7.3,
          sourceLabel: 'QR Trạm AquaCare',
          isVerifiedMatch: true,
        );
      }

      if (type == 'ro' || type == 'filter' || slot != null) {
        final slotIdx = ((slot ?? 1) - 1).clamp(0, 3);
        return AquaScannedCodeResult(
          rawCode: rawCode,
          kind: AquaScannedKind.roFilterCartridge,
          title: name.isEmpty ? 'Lõi lọc RO chính hãng #${slotIdx + 1}' : name,
          subtitle: 'Đặt lại tuổi thọ lõi lọc số ${slotIdx + 1} lên 100%',
          brand: brand,
          filterSlotIndex: slotIdx,
          recommendedMl: 250,
          sourceLabel: 'QR Lõi lọc RO',
          isVerifiedMatch: true,
        );
      }

      if (type == 'tds' || (tds != null && ml == 500 && name.isEmpty)) {
        return AquaScannedCodeResult(
          rawCode: rawCode,
          kind: AquaScannedKind.mineralOrTdsCheck,
          title: 'Kiểm tra chất lượng nước',
          subtitle:
              'Cập nhật cảm biến TDS ${tds ?? 32} ppm${ph != null ? ' · pH ${ph.toStringAsFixed(1)}' : ''}',
          estimatedTdsPpm: tds ?? 32,
          estimatedPh: ph ?? 7.3,
          recommendedMl: 250,
          sourceLabel: 'QR Cảm biến nước',
          isVerifiedMatch: true,
        );
      }

      return AquaScannedCodeResult(
        rawCode: rawCode,
        kind: AquaScannedKind.waterBottle,
        title: name.isEmpty ? 'Đồ uống đã xác thực QR' : name,
        subtitle: brand.isEmpty
            ? 'Ghi nhận $ml ml vào nhật ký hôm nay'
            : '$brand · Ghi nhận $ml ml',
        brand: brand,
        recommendedMl: ml.clamp(50, 3000),
        estimatedTdsPpm: tds,
        estimatedPh: ph,
        sourceLabel: 'QR Sản phẩm',
        isVerifiedMatch: true,
      );
    } catch (_) {
      return null;
    }
  }

  static AquaScannedCodeResult? _tryParseUrlPayload(String rawCode) {
    final uri = Uri.tryParse(rawCode);
    if (uri == null) return null;
    final lower = rawCode.toLowerCase();
    final qp = uri.queryParameters;
    final ml = _asInt(qp['ml'] ?? qp['volume']) ?? 500;
    final tds = _asInt(qp['tds']);
    final slot = _asInt(qp['slot'] ?? qp['filter']);
    final station = (qp['station'] ?? qp['name'] ?? '').trim();

    if (lower.contains('filter') || lower.contains('ro') || slot != null) {
      final slotIdx = ((slot ?? 1) - 1).clamp(0, 3);
      return AquaScannedCodeResult(
        rawCode: rawCode,
        kind: AquaScannedKind.roFilterCartridge,
        title: 'Lõi lọc RO chính hãng #${slotIdx + 1}',
        subtitle: 'Xác thực thay mới lõi lọc từ mã QR nhà sản xuất',
        filterSlotIndex: slotIdx,
        recommendedMl: 250,
        sourceLabel: 'QR Link Lõi lọc',
        isVerifiedMatch: true,
      );
    }

    if (lower.contains('station') ||
        lower.contains('refill') ||
        lower.contains('aquacare')) {
      final stationLabel =
          station.isNotEmpty ? station : 'Trạm nước Refill (${uri.host})';
      return AquaScannedCodeResult(
        rawCode: rawCode,
        kind: AquaScannedKind.refillStation,
        title: stationLabel,
        subtitle: 'Xác thực lấy nước sạch tại trạm Refill · Cộng 5 điểm xanh',
        stationName: stationLabel,
        recommendedMl: ml.clamp(100, 2000),
        estimatedTdsPpm: tds ?? 22,
        sourceLabel: 'QR Link Trạm nước',
        isVerifiedMatch: true,
      );
    }

    return AquaScannedCodeResult(
      rawCode: rawCode,
      kind: AquaScannedKind.genericText,
      title: 'Liên kết QR: ${uri.host.isEmpty ? rawCode : uri.host}',
      subtitle: 'Nhấn xác nhận nếu bạn vừa uống nước tại đây ($ml ml)',
      recommendedMl: ml.clamp(50, 2000),
      sourceLabel: 'QR URL',
      isVerifiedMatch: false,
    );
  }

  static AquaScannedCodeResult _parseStructuredTextCode(String rawCode) {
    final upper = rawCode.toUpperCase();

    if (upper.startsWith('RO-') ||
        upper.startsWith('LOI-') ||
        upper.contains('FILTER') ||
        upper.contains('KANGAROO') ||
        upper.contains('KAROFI')) {
      final slotMatch = RegExp(r'[1-4]').firstMatch(upper);
      final slotNumber = int.tryParse(slotMatch?.group(0) ?? '1') ?? 1;
      final slotIdx = (slotNumber - 1).clamp(0, 3);
      return AquaScannedCodeResult(
        rawCode: rawCode,
        kind: AquaScannedKind.roFilterCartridge,
        title: 'Lõi lọc RO #$slotNumber ($rawCode)',
        subtitle: 'Xác nhận lắp mới lõi lọc số $slotNumber lên 100% tuổi thọ',
        filterSlotIndex: slotIdx,
        recommendedMl: 250,
        sourceLabel: 'Mã Lõi lọc RO',
        isVerifiedMatch: true,
      );
    }

    if (upper.startsWith('AQUACARE') ||
        upper.startsWith('TRAM') ||
        upper.contains('STATION') ||
        upper.contains('REFILL')) {
      final stationName = rawCode == 'AQUACARE_VERIFIED_QR'
          ? 'Trạm Thư viện Thành phố'
          : 'Trạm Refill ($rawCode)';
      return AquaScannedCodeResult(
        rawCode: rawCode,
        kind: AquaScannedKind.refillStation,
        title: stationName,
        subtitle: 'Trạm Refill nước uống trực tiếp · TDS chuẩn < 30 ppm',
        stationName: stationName,
        recommendedMl: 500,
        estimatedTdsPpm: 20,
        estimatedPh: 7.3,
        sourceLabel: 'QR Trạm Refill',
        isVerifiedMatch: true,
      );
    }

    if (upper.startsWith('TDS:') || upper.contains('PPM')) {
      final numMatch = RegExp(r'\d{1,4}').firstMatch(upper);
      final tds = int.tryParse(numMatch?.group(0) ?? '34') ?? 34;
      return AquaScannedCodeResult(
        rawCode: rawCode,
        kind: AquaScannedKind.mineralOrTdsCheck,
        title: 'Kết quả đo chất lượng nước',
        subtitle: 'Chỉ số TDS: $tds ppm — Cập nhật lên biểu đồ thiết bị',
        estimatedTdsPpm: tds.clamp(1, 2000),
        recommendedMl: 250,
        sourceLabel: 'QR Kiểm định nước',
        isVerifiedMatch: true,
      );
    }

    return AquaScannedCodeResult(
      rawCode: rawCode,
      kind: AquaScannedKind.genericText,
      title: 'Đã đọc mã: ${rawCode.length > 36 ? '${rawCode.substring(0, 36)}…' : rawCode}',
      subtitle: 'Chọn dung tích chai / ly vừa uống để ghi nhận nhanh vào nhật ký',
      recommendedMl: 350,
      sourceLabel: 'QR / Mã vạch',
      isVerifiedMatch: false,
    );
  }

  static Future<AquaScannedCodeResult> _lookupNumericBarcode(
    String barcode, {
    http.Client? client,
  }) async {
    final catalogMatch = _matchVnCatalog(barcode);

    final canCallNetwork = client != null || !AquaMotion.isTestEnvironment;
    if (canCallNetwork) {
      final live = await _queryOpenFoodFacts(
        barcode,
        catalogFallback: catalogMatch,
        client: client,
      );
      if (live != null) {
        return live;
      }
    }

    if (catalogMatch != null) {
      return AquaScannedCodeResult(
        rawCode: barcode,
        kind: AquaScannedKind.waterBottle,
        title: catalogMatch.productTitle,
        subtitle:
            '${catalogMatch.note} · TDS ~${catalogMatch.tdsPpm} ppm · pH ${catalogMatch.ph}',
        brand: catalogMatch.brand,
        recommendedMl: catalogMatch.defaultMl,
        estimatedTdsPpm: catalogMatch.tdsPpm,
        estimatedPh: catalogMatch.ph,
        sourceLabel: 'Danh mục nước VN',
        isVerifiedMatch: true,
      );
    }

    return AquaScannedCodeResult(
      rawCode: barcode,
      kind: AquaScannedKind.waterBottle,
      title: 'Chai đồ uống mã vạch #$barcode',
      subtitle:
          'Chưa có trên OpenFoodFacts — bạn có thể chọn nhanh dung tích bên dưới',
      recommendedMl: 500,
      sourceLabel: 'Mã vạch EAN/UPC',
      isVerifiedMatch: false,
    );
  }

  static _VnWaterCatalogEntry? _matchVnCatalog(String barcode) {
    final exact = _exactSkuCatalog[barcode];
    if (exact != null) return exact;
    for (final entry in _prefixCatalog.entries) {
      if (barcode.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static Future<AquaScannedCodeResult?> _queryOpenFoodFacts(
    String barcode, {
    _VnWaterCatalogEntry? catalogFallback,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldClose = client == null;
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json'
        '?fields=product_name,product_name_vi,brands,quantity,serving_size,categories_tags',
      );
      final response = await httpClient.get(
        uri,
        headers: const {'User-Agent': 'AquaCare-VN/1.0 (Flutter Mobile App)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['status'] != 1) return null;

      final product = decoded['product'];
      if (product is! Map<String, dynamic>) return null;

      final rawNameVi = (product['product_name_vi'] as String? ?? '').trim();
      final rawName = (product['product_name'] as String? ?? '').trim();
      final brands = (product['brands'] as String? ?? '').trim();
      final quantity = (product['quantity'] as String? ??
              product['serving_size'] as String? ??
              '')
          .trim();

      final displayName = rawNameVi.isNotEmpty
          ? rawNameVi
          : (rawName.isNotEmpty
              ? rawName
              : (catalogFallback?.productTitle ?? 'Đồ uống mã $barcode'));

      final parsedMl = _parseVolumeMl(quantity) ??
          catalogFallback?.defaultMl ??
          500;
      final brandText =
          brands.isNotEmpty ? brands : (catalogFallback?.brand ?? '');
      final title = brandText.isNotEmpty &&
              !displayName.toLowerCase().contains(brandText.toLowerCase())
          ? '$brandText — $displayName'
          : displayName;

      final details = <String>[
        if (quantity.isNotEmpty) 'Dung tích $quantity',
        if (catalogFallback != null)
          'TDS ~${catalogFallback.tdsPpm} ppm · pH ${catalogFallback.ph}',
        if (quantity.isEmpty && catalogFallback == null)
          'Đã tra cứu trực tuyến OpenFoodFacts',
      ];

      return AquaScannedCodeResult(
        rawCode: barcode,
        kind: AquaScannedKind.waterBottle,
        title: title,
        subtitle: details.join(' · '),
        brand: brandText,
        recommendedMl: parsedMl.clamp(50, 2000),
        estimatedTdsPpm: catalogFallback?.tdsPpm,
        estimatedPh: catalogFallback?.ph,
        sourceLabel: 'OpenFoodFacts Live API',
        isVerifiedMatch: true,
      );
    } catch (_) {
      return null;
    } finally {
      if (shouldClose) {
        httpClient.close();
      }
    }
  }

  static int? _parseVolumeMl(String raw) {
    if (raw.isEmpty) return null;
    final lower = raw.toLowerCase().replaceAll(',', '.');
    final mlMatch = RegExp(r'(\d+(?:\.\d+)?)\s*ml').firstMatch(lower);
    if (mlMatch != null) {
      final value = double.tryParse(mlMatch.group(1) ?? '');
      if (value != null && value > 0) return value.round();
    }
    final clMatch = RegExp(r'(\d+(?:\.\d+)?)\s*cl').firstMatch(lower);
    if (clMatch != null) {
      final value = double.tryParse(clMatch.group(1) ?? '');
      if (value != null && value > 0) return (value * 10).round();
    }
    final literMatch = RegExp(r'(\d+(?:\.\d+)?)\s*l\b').firstMatch(lower);
    if (literMatch != null) {
      final value = double.tryParse(literMatch.group(1) ?? '');
      if (value != null && value > 0) {
        // Cap a single recording at 500 ml if bottle is large (>= 1.5L) so log stays realistic
        final ml = (value * 1000).round();
        return ml >= 1500 ? 500 : ml;
      }
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }
    return null;
  }
}
