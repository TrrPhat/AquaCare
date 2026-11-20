import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/aqua_models.dart';
import '../widgets/animations/aqua_motion.dart';

/// Ảnh chụp trạng thái thực tế của người dùng được truyền vào Custom AI API.
class AquaBotContextSnapshot {
  const AquaBotContextSnapshot({
    required this.userName,
    required this.roleLabel,
    this.role = AquaRole.studentWorker,
    required this.intakeMl,
    required this.dailyGoalMl,
    required this.caffeineMg,
    required this.streakDays,
    required this.tdsPpm,
    required this.phLevel,
    required this.roFilterHealth,
    required this.kidsCups,
    required this.kidsGoalCups,
    required this.kidsStars,
    required this.selectedStationName,
    this.waterSource = 'Máy lọc RO gia đình',
  });

  final String userName;
  final String roleLabel;
  final AquaRole role;
  final int intakeMl;
  final int dailyGoalMl;
  final int caffeineMg;
  final int streakDays;
  final int tdsPpm;
  final double phLevel;
  final List<int> roFilterHealth;
  final int kidsCups;
  final int kidsGoalCups;
  final int kidsStars;
  final String selectedStationName;
  final String waterSource;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'role': roleLabel,
        'roleId': role.name,
        'intakeMl': intakeMl,
        'dailyGoalMl': dailyGoalMl,
        'caffeineMg': caffeineMg,
        'streakDays': streakDays,
        'tdsPpm': tdsPpm,
        'phLevel': phLevel,
        'roFilterHealth': roFilterHealth,
        'kidsCups': kidsCups,
        'kidsGoalCups': kidsGoalCups,
        'kidsStars': kidsStars,
        'selectedStationName': selectedStationName,
        'waterSource': waterSource,
      };
}

class AquaBotReplyResult {
  const AquaBotReplyResult({
    required this.text,
    this.usedLocalFallback = false,
    this.diagnosticStatus,
  });

  final String text;
  final bool usedLocalFallback;
  final String? diagnosticStatus;
}

/// ============================================================================
/// CỔNG KẾT NỐI API AI CUSTOM RIÊNG CỦA BẠN (AquaBot AI Client)
/// ============================================================================
///
/// Hỗ trợ tự động cả 3 chuẩn API phổ biến:
/// 1. Anthropic Messages API (`/v1/messages` hoặc key `sk-ant-...`).
/// 2. OpenAI Chat Completions (`/v1/chat/completions`).
/// 3. Custom Webhook JSON riêng.
class AquaBotAiClient {
  AquaBotAiClient({
    http.Client? httpClient,
    this.endpointOverride,
    this.apiKeyOverride,
    this.modelOverride,
  }) : _httpClient = httpClient ?? http.Client();

  // --------------------------------------------------------------------------
  // [CUSTOM AI] Cấu hình qua `--dart-define` lúc build hoặc qua UI thiết lập AI.
  // Không lưu khóa API thật trực tiếp trong mã nguồn.
  // --------------------------------------------------------------------------
  static const String customApiEndpoint = String.fromEnvironment(
    'AQUABOT_API_URL',
    defaultValue: '',
  );

  static const String customModelName = String.fromEnvironment(
    'AQUABOT_MODEL',
    defaultValue: '',
  );

  static const String customApiKey = String.fromEnvironment(
    'AQUABOT_API_KEY',
    defaultValue: '',
  );

  static const double customTemperature = 0.7;
  static const int customMaxTokens = 1024;
  static const bool strictOpenAiPayload = false;

  static const Map<String, String> customExtraHeaders = {
    // 'X-Custom-Source': 'aquacare-mobile',
  };
  // --------------------------------------------------------------------------

  final http.Client _httpClient;
  final String? endpointOverride;
  final String? apiKeyOverride;
  final String? modelOverride;

  String? _runtimeEndpoint;
  String? _runtimeApiKey;
  String? _runtimeModel;

  void updateRuntimeConfig({
    String? endpoint,
    String? model,
    String? apiKey,
  }) {
    _runtimeEndpoint = endpoint?.trim();
    _runtimeModel = model?.trim();
    _runtimeApiKey = apiKey?.trim();
  }

  String get effectiveApiKey {
    if (apiKeyOverride != null) return apiKeyOverride!.trim();
    if (_runtimeApiKey != null && _runtimeApiKey!.isNotEmpty) {
      return _runtimeApiKey!;
    }
    return customApiKey.trim();
  }

  String get effectiveModel {
    if (modelOverride != null) return modelOverride!.trim();
    if (_runtimeModel != null && _runtimeModel!.isNotEmpty) {
      return _runtimeModel!;
    }
    return customModelName.trim();
  }

  String get _rawConfiguredEndpoint {
    if (endpointOverride != null) return endpointOverride!.trim();
    if (_runtimeEndpoint != null && _runtimeEndpoint!.isNotEmpty) {
      return _runtimeEndpoint!;
    }
    return customApiEndpoint.trim();
  }

  bool get isAnthropicProtocol {
    final rawUrl = _rawConfiguredEndpoint.toLowerCase();
    return rawUrl.endsWith('/messages') || effectiveApiKey.startsWith('sk-ant-');
  }

  String get effectiveEndpoint {
    final raw = _rawConfiguredEndpoint;
    if (raw.isEmpty) return '';
    // Nếu dùng key chuẩn Anthropic (`sk-ant-...`) mà lỡ để đuôi `/v1/chat/completions`
    // (như trên gateway 1gw.gwai.cloud chặn `/v1/chat/completions` trả mã 403),
    // tự động chuyển sang `/v1/messages`.
    if (effectiveApiKey.startsWith('sk-ant-') &&
        raw.toLowerCase().endsWith('/chat/completions')) {
      return '${raw.substring(0, raw.length - '/chat/completions'.length)}/messages';
    }
    return raw;
  }

  bool get isCustomApiConfigured => effectiveEndpoint.isNotEmpty;

  /// Chuẩn hóa lịch sử hội thoại đảm bảo bắt đầu bằng `user`, xen kẽ `user`/`assistant`
  /// và không lặp đúp câu hỏi hiện tại ở cuối mảng.
  List<Map<String, String>> _buildNormalizedMessages(
    List<AquaBotMessage> history,
    String userMessage,
  ) {
    final recent = history.length > 8
        ? history.sublist(history.length - 8)
        : List<AquaBotMessage>.from(history);

    // Nếu phần tử cuối trong `history` đã chính là câu vừa gửi của user thì bỏ ra để ghép chuẩn ở cuối.
    if (recent.isNotEmpty &&
        recent.last.isUser &&
        recent.last.text.trim() == userMessage.trim()) {
      recent.removeLast();
    }

    final normalized = <Map<String, String>>[];
    for (final m in recent) {
      final text = m.text.trim();
      if (text.isEmpty) continue;
      final role = m.isUser ? 'user' : 'assistant';
      // Bỏ các câu mở đầu của bot ở đầu danh sách (Anthropic yêu cầu message đầu tiên phải là `user`)
      if (normalized.isEmpty && role == 'assistant') continue;

      if (normalized.isNotEmpty && normalized.last['role'] == role) {
        normalized.last['content'] = '${normalized.last['content']}\n$text';
      } else {
        normalized.add({'role': role, 'content': text});
      }
    }

    if (normalized.isNotEmpty && normalized.last['role'] == 'user') {
      normalized.last['content'] =
          '${normalized.last['content']}\n$userMessage';
    } else {
      normalized.add({'role': 'user', 'content': userMessage});
    }
    return normalized;
  }

  /// [CUSTOM AI] Chỉnh cấu trúc body JSON gửi lên server API riêng của bạn tại đây.
  Map<String, dynamic> buildCustomPayload({
    required String userMessage,
    required List<AquaBotMessage> history,
    required AquaBotContextSnapshot snapshot,
  }) {
    final roleContext = switch (snapshot.role) {
      AquaRole.studentWorker =>
        'đã uống ${snapshot.intakeMl}/${snapshot.dailyGoalMl} ml, caffeine ${snapshot.caffeineMg} mg, '
            'chuỗi ${snapshot.streakDays} ngày, trạm nước đang chọn: ${snapshot.selectedStationName}. '
            'Chỉ tập trung tư vấn uống nước cá nhân, học tập/làm việc, caffeine và trạm refill quanh bạn.',
      AquaRole.household =>
        'đã uống ${snapshot.intakeMl}/${snapshot.dailyGoalMl} ml, '
            'nguồn nước ${snapshot.waterSource}, TDS ${snapshot.tdsPpm} ppm, pH ${snapshot.phLevel.toStringAsFixed(1)}, '
            'tình trạng bộ lọc nước ${snapshot.roFilterHealth.join("/")}, vệ sinh nguồn nước gia đình, '
            'Bé AquaKids ${snapshot.kidsCups}/${snapshot.kidsGoalCups} cốc (${snapshot.kidsStars} sao).',
      AquaRole.kids =>
        'Bé đang ở chế độ AquaKids: đã uống ${snapshot.kidsCups}/${snapshot.kidsGoalCups} cốc và có ${snapshot.kidsStars} Sao Vàng! '
            'Trả lời vui nhộn, tích cực, phù hợp cho trẻ nhỏ.',
    };

    final systemPrompt =
        'Bạn là AquaBot, trợ lý sức khỏe nước sạch SDG 6 của AquaCare. '
        'Dữ liệu người dùng hiện tại: Tên ${snapshot.userName} (${snapshot.roleLabel}), '
        '$roleContext '
        'Trả lời ngắn gọn, thân thiện bằng tiếng Việt.';

    final turnMessages = _buildNormalizedMessages(history, userMessage);

    // 1. Chuẩn Anthropic Messages API (`/v1/messages`)
    if (isAnthropicProtocol) {
      return {
        if (effectiveModel.isNotEmpty) 'model': effectiveModel,
        'max_tokens': customMaxTokens,
        'temperature': customTemperature,
        'system': systemPrompt,
        'messages': turnMessages,
      };
    }

    final openAiMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...turnMessages,
    ];

    // 2. Chuẩn OpenAI Chat Completions (`/v1/chat/completions`)
    final isOpenAiChatEndpoint =
        strictOpenAiPayload ||
        effectiveEndpoint.toLowerCase().endsWith('/chat/completions');

    if (isOpenAiChatEndpoint) {
      return {
        if (effectiveModel.isNotEmpty) 'model': effectiveModel,
        'messages': openAiMessages,
        'temperature': customTemperature,
      };
    }

    // 3. Custom Webhook tổng quát
    return {
      if (effectiveModel.isNotEmpty) 'model': effectiveModel,
      'temperature': customTemperature,
      'message': userMessage,
      'systemPrompt': systemPrompt,
      'telemetry': snapshot.toJson(),
      'history': turnMessages,
      'messages': openAiMessages,
    };
  }

  /// [CUSTOM AI] Chỉnh cách đọc trường JSON trả về từ API riêng của bạn tại đây.
  String parseCustomResponse(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      // 1. Đọc chuẩn Anthropic Messages API: {"content": [{"type": "text", "text": "..."}]}
      final contentList = decoded['content'];
      if (contentList is List && contentList.isNotEmpty) {
        final buffer = <String>[];
        for (final block in contentList) {
          if (block is Map &&
              (block['type'] == 'text' || block['type'] == null)) {
            final t = block['text'];
            if (t is String && t.trim().isNotEmpty) {
              buffer.add(t.trim());
            }
          }
        }
        if (buffer.isNotEmpty) {
          return buffer.join('\n\n');
        }
      }

      // 2. Đọc các trường JSON đơn giản
      for (final key in const [
        'reply',
        'answer',
        'message',
        'output',
        'text',
      ]) {
        final v = decoded[key];
        if (v is String && v.trim().isNotEmpty) {
          return v.trim();
        }
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final nested = data['reply'] ?? data['answer'] ?? data['message'];
        if (nested is String && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }

      // 3. Đọc chuẩn OpenAI Chat Completions: {"choices": [{"message": {"content": "..."}}]}
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map && first['message'] is Map) {
          final content = first['message']['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded.trim();
    }
    return responseBody.trim();
  }

  Future<AquaBotReplyResult> generateStructuredReply({
    required String userMessage,
    required List<AquaBotMessage> history,
    required AquaBotContextSnapshot snapshot,
  }) async {
    if (!isCustomApiConfigured ||
        (AquaMotion.isTestEnvironment && endpointOverride == null)) {
      return AquaBotReplyResult(
        text: _buildLocalSmartFallback(userMessage, snapshot),
        usedLocalFallback: true,
      );
    }

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (effectiveApiKey.isNotEmpty) ...{
          'Authorization': 'Bearer $effectiveApiKey',
          if (isAnthropicProtocol) ...{
            'x-api-key': effectiveApiKey,
            'anthropic-version': '2023-06-01',
            'anthropic-dangerous-direct-browser-access': 'true',
          },
        },
        ...customExtraHeaders,
      };

      final payload = buildCustomPayload(
        userMessage: userMessage,
        history: history,
        snapshot: snapshot,
      );

      final response = await _httpClient
          .post(
            Uri.parse(effectiveEndpoint),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final parsed = parseCustomResponse(utf8Body);
        if (parsed.isNotEmpty) {
          return AquaBotReplyResult(text: parsed);
        }
      }

      return AquaBotReplyResult(
        text: _buildLocalSmartFallback(userMessage, snapshot),
        usedLocalFallback: true,
        diagnosticStatus:
            'Máy chủ AI trả về mã ${response.statusCode} • Đang trả lời bằng trợ lý nội bộ',
      );
    } catch (_) {
      return AquaBotReplyResult(
        text: _buildLocalSmartFallback(userMessage, snapshot),
        usedLocalFallback: true,
        diagnosticStatus:
            'Chưa kết nối được máy chủ AI • Đang trả lời bằng trợ lý nội bộ',
      );
    }
  }

  Future<String> generateReply({
    required String userMessage,
    required List<AquaBotMessage> history,
    required AquaBotContextSnapshot snapshot,
  }) async {
    final result = await generateStructuredReply(
      userMessage: userMessage,
      history: history,
      snapshot: snapshot,
    );
    return result.text;
  }

  String _buildLocalSmartFallback(
    String userMessage,
    AquaBotContextSnapshot s,
  ) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('vệ sinh') ||
        lower.contains('rửa tay') ||
        lower.contains('bình nước') ||
        lower.contains('sanitation') ||
        lower.contains('wash')) {
      return 'Gợi ý Vệ sinh Nước sạch (SDG 6 - WASH): (1) Rửa bình nước cá nhân mỗi ngày bằng nước ấm & xà phòng để tránh mảng bám; (2) Rửa tay 6 bước với xà phòng trong 20 giây trước khi ăn & sau vệ sinh; (3) Vệ sinh bồn chứa/vòi rót gia đình định kỳ 3–6 tháng.';
    }
    if (lower.contains('tds') ||
        lower.contains('lọc') ||
        lower.contains('ph') ||
        lower.contains('khoáng') ||
        lower.contains('nước máy')) {
      if (s.role == AquaRole.studentWorker) {
        return 'Nước uống tinh khiết đạt chuẩn thường có TDS < 50 ppm, nước khoáng thiên nhiên/ion kiềm đạt chuẩn WHO/QCVN thường nằm trong 50–300 ppm và pH 6.5–8.8. Trạm ${s.selectedStationName} hiện đạt chuẩn nước uống trực tiếp để bạn refill bình cá nhân!';
      }
      final sourceType =
          AquaWaterSourceTypeDetails.fromSourceString(s.waterSource);
      final assessment = AquaWaterSafetyAssessment.evaluate(
        tdsPpm: s.tdsPpm,
        phLevel: s.phLevel,
        sourceType: sourceType,
      );
      final roLow = s.roFilterHealth.isNotEmpty ? s.roFilterHealth[0] : 15;
      return 'Chỉ số nước (${sourceType.label}): TDS ${s.tdsPpm} ppm, pH ${s.phLevel.toStringAsFixed(1)} — ${assessment.headline} (${assessment.standardNote}). Bộ lọc thô cấp 1 còn $roLow%, bạn nhớ vệ sinh và theo dõi lịch thay nhé!';
    }
    if (s.role != AquaRole.studentWorker &&
        (lower.contains('bé') ||
            lower.contains('kids') ||
            lower.contains('sao'))) {
      return 'Bé AquaKids hôm nay đã uống ${s.kidsCups}/${s.kidsGoalCups} cốc và đang có ${s.kidsStars} Sao Vàng! Hoàn thành đủ cốc hoặc trả lời đố vui để mở khóa thêm phụ kiện cho Giọt Nước nhé.';
    }
    if (lower.contains('cà phê') ||
        lower.contains('caffeine') ||
        lower.contains('trà')) {
      return 'Hôm nay bạn đã nạp ${s.caffeineMg} mg Caffeine. Với mỗi ly cà phê, bạn nên uống bù thêm 200–250 ml nước lọc để giữ cơ thể cân bằng nhé!';
    }
    if (lower.contains('trạm') ||
        lower.contains('refill') ||
        lower.contains('bản đồ')) {
      return 'Trạm nước sạch gần nhất đang chọn là ${s.selectedStationName}. Bạn có thể mở Tab Trạm nước để xem chỉ đường GPS hoặc quét QR Refill miễn phí!';
    }
    final remaining = (s.dailyGoalMl - s.intakeMl).clamp(0, 5000);
    if (remaining == 0) {
      return 'Tuyệt vời ${s.userName}! Bạn đã hoàn thành ${s.intakeMl}/${s.dailyGoalMl} ml (100% mục tiêu hôm nay) và giữ vững chuỗi ${s.streakDays} ngày!';
    }
    return 'Mục tiêu nước hôm nay của ${s.userName} là ${s.dailyGoalMl} ml (đã uống ${s.intakeMl} ml, còn $remaining ml). Bạn nên uống thêm 1 cốc 250 ml trong 30 phút tới nhé!';
  }
}
