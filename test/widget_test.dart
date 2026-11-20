import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aquacare/core/theme/app_theme.dart';
import 'package:aquacare/main.dart';
import 'package:aquacare/services/aqua_barcode_lookup_service.dart';
import 'package:aquacare/services/aquabot_ai_client.dart';
import 'package:aquacare/state/aqua_ui_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Real app flow: Splash -> Onboarding -> Auth -> Home Tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AquaCareApp());
    await tester.pump();

    // Splash Screen
    expect(find.text('AquaCare'), findsOneWidget);
    expect(find.text('AquaCare UI Studio'), findsNothing);
    expect(find.text('1.01'), findsNothing);

    await tester.tap(find.text('Bắt đầu ngay'));
    await tester.pumpAndSettle();

    // Onboarding PageView
    expect(
      find.text('Cấp ẩm thông minh theo ca học & làm việc'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    // Auth Screen (production clean, no demo quick-fill badge)
    expect(find.text('Chào mừng đến AquaCare'), findsOneWidget);
    expect(find.text('Điền tài khoản mẫu'), findsNothing);
    await tester.tap(find.text('Đăng nhập ngay'));
    await tester.pumpAndSettle();

    // Main App Shell - Tab 0 Home
    expect(find.text('Xin chào, Minh Nguyễn'), findsOneWidget);
    expect(find.text('1500 / 2100 ml'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Role-adaptive tabs, live scanner flow & Kid-Locked Parent Gate work cleanly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AquaCareApp(initialStage: AppFlowStage.main),
      );
      await tester.pumpAndSettle();

      // Default Student / Worker mode hides Kids & RO tabs
      expect(find.text('AquaKids'), findsNothing);
      expect(find.text('Chất lượng'), findsNothing);
      expect(find.text('Sống xanh'), findsOneWidget);
      expect(find.text('Quét mã'), findsOneWidget);

      // Tab 0: Quick drink +250 ml
      await tester.tap(find.widgetWithText(FilledButton, '+250 ml'));
      await tester.pumpAndSettle();
      expect(find.text('1750 / 2100 ml'), findsOneWidget);

      // Tab 1 (Student/Worker): Green Living, WASH & Caffeine Stats
      await tester.tap(find.text('Sống xanh'));
      await tester.pumpAndSettle();
      expect(find.text('Sống xanh & vệ sinh'), findsOneWidget);
      expect(find.text('Vệ sinh bình nước & rửa tay (WASH)'), findsOneWidget);
      expect(find.text('Theo dõi Caffeine & bù nước'), findsOneWidget);
      expect(find.text('Nhắc uống nước theo ca (25 phút)'), findsOneWidget);

      // Center Scanner CTA: Scan VN bottled water EAN & apply +500 ml (shows SDG 6 eco-nudge)
      await tester.tap(find.text('Quét mã'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '8935012011340');
      await tester.tap(find.text('Tra cứu mã này'));
      await tester.pumpAndSettle();
      expect(find.text('Nước khoáng thiên nhiên La Vie 500ml'), findsOneWidget);
      expect(find.textContaining('Mẹo SDG 6'), findsOneWidget);
      await tester.tap(find.text('Xác nhận (+500 ml)'));
      await tester.pumpAndSettle();

      // Return to Tab 0 & verify scanned intake added
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      expect(find.text('2250 / 2100 ml'), findsOneWidget);

      // Tab 3: Refill & Sanitation Map
      await tester.tap(find.text('Trạm nước'));
      await tester.pumpAndSettle();
      expect(find.text('Trạm Thư viện Thành phố').first, findsOneWidget);
      expect(find.text('Rửa tay & vệ sinh'), findsOneWidget);

      // Tab 4: Profile -> Verify clean App Info section & Switch role to Household
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      expect(find.text('Thống kê cấp ẩm 7 ngày'), findsOneWidget);
      expect(find.text('Thông tin ứng dụng & dữ liệu'), findsOneWidget);
      expect(
        find.text('Kho 100 màn hình Figma (Đối chiếu Đồ án)'),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Hộ gia đình'));
      await tester.tap(find.text('Hộ gia đình'));
      await tester.pumpAndSettle();

      // Household home & AI assistant
      expect(find.text('An toàn uống trực tiếp ✓'), findsOneWidget);
      await tester.tap(find.text('AI'));
      await tester.pumpAndSettle();
      expect(find.text('Trợ lý AI AquaBot'), findsOneWidget);
      await tester.tap(find.text('TDS bao nhiêu là tốt?'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Household Tab 1: Clean Water Safety & WASH Sanitation
      await tester.tap(find.text('Nước & vệ sinh'));
      await tester.pumpAndSettle();
      expect(find.text('Nước sạch & vệ sinh'), findsOneWidget);
      await tester.tap(find.text('Vệ sinh & lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Checklist vệ sinh nước sạch (WASH)'), findsOneWidget);
      await tester.ensureVisible(find.text('Bộ lọc thô cặn bẩn (Cấp 1)'));
      expect(find.text('Bộ lọc thô cặn bẩn (Cấp 1)'), findsOneWidget);

      // Return to Household Home -> Enter Kid-Locked Fullscreen Mode
      await tester.tap(find.text('Gia đình'));
      await tester.pumpAndSettle();
      final kidsBtn = find.text('Giao máy cho bé (khóa chế độ trẻ em) →');
      await tester.ensureVisible(kidsBtn);
      await tester.tap(kidsBtn);
      await tester.pumpAndSettle();

      // Kid-Locked Fullscreen: adult tab bar is completely hidden
      expect(find.text('Hành tinh Bé An'), findsOneWidget);
      expect(find.text('Cá nhân'), findsNothing);
      expect(find.text('Nước & vệ sinh'), findsNothing);

      await tester.tap(find.text('+ Cho Giọt Nước uống 1 cốc (+10 ★)'));
      await tester.pumpAndSettle();
      expect(find.text('★ 130 sao'), findsOneWidget);

      // Parental Gate PIN (no answer leak, requires full 4-digit PIN 1234) -> Exit back to Household
      await tester.tap(find.text('Phụ huynh'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nhập đáp án 12'), findsNothing);
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      expect(find.text('Góc phụ huynh (đã mở khóa)'), findsOneWidget);
      await tester.tap(
        find.text('Thoát chế độ trẻ em → Về giao diện phụ huynh'),
      );
      await tester.pumpAndSettle();
      expect(find.text('An toàn uống trực tiếp ✓'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Desktop viewport shows centered clean app without prototype sidebar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AquaCareApp(initialStage: AppFlowStage.main),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xin chào, Minh Nguyễn'), findsOneWidget);
      expect(find.text('AquaCare UI Studio'), findsNothing);
      expect(find.textContaining('Công cụ Đồ án'), findsNothing);
      expect(find.textContaining('100 màn hình'), findsNothing);

      // Open App Info section in Profile Settings & verify local reset option
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Thông tin ứng dụng & dữ liệu'));
      await tester.tap(find.text('Thông tin ứng dụng & dữ liệu'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt lại dữ liệu trên thiết bị'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Animations: mid-flight reward bursts, quiz shake and tab transitions settle cleanly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AquaCareApp(initialStage: AppFlowStage.main),
      );
      await tester.pumpAndSettle();

      // Trigger +250 ml splash + FloatingRewardHost mid-flight check
      await tester.tap(find.widgetWithText(FilledButton, '+250 ml'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('+250 ml 💧'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('1750 / 2100 ml'), findsOneWidget);

      // Enter Kid-Locked mode from Profile & check Mascot floating reward burst
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Giao máy cho bé'));
      await tester.tap(find.text('Giao máy cho bé'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Cho Giọt Nước uống 1 cốc (+10 ★)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.text('+10 ★ ✨'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('★ 130 sao'), findsOneWidget);

      // Open Quiz sheet & trigger wrong-answer shake then correct answer
      await tester.ensureVisible(find.text('Đố vui nước sạch'));
      await tester.tap(find.text('Đố vui nước sạch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B. Nước mưa hứng trực tiếp chưa lọc'));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('A. Nước đã lọc sạch qua máy RO hoặc đun sôi'),
      );
      await tester.pumpAndSettle();
      expect(find.text('★ 150 sao'), findsOneWidget);
      Navigator.of(tester.element(find.text('Đố vui nước sạch (+20 ★)'))).pop();
      await tester.pumpAndSettle();

      // Exit Kid-Locked via Parent Gate to Household & switch RO sub-tabs
      await tester.ensureVisible(find.text('Phụ huynh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Phụ huynh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.tap(find.text('3'));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Thoát chế độ trẻ em → Về giao diện phụ huynh'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nước & vệ sinh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vệ sinh & lọc'));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test('Offline-First persistence (1A) and midnight daily rollover work accurately', () async {
    final first = AquaUiController();
    await first.initialize();
    first.completeAuth(isNewUser: false, userName: 'Phát Lại');
    first.addWater(300); // 1500 -> 1800
    first.saveWaterTestRecord(tds: 24, ph: 7.4, sourceNote: 'Test Persistence');
    first.equipMascotItem('Áo choàng Hiệp sĩ', 40); // 120 -> 80 stars
    await Future<void>.delayed(const Duration(milliseconds: 20));
    first.dispose();

    // Second controller instance simulates cold app restart
    final relaunched = AquaUiController(initialStage: AppFlowStage.splash);
    await relaunched.initialize(autoRedirectAuthenticated: true);
    expect(relaunched.stage, AppFlowStage.main);
    expect(relaunched.userName, 'Phát Lại');
    expect(relaunched.intakeMl, 1800);
    expect(relaunched.waterTestRecords.first.tdsPpm, 24);
    expect(relaunched.equippedMascotItem, 'Áo choàng Hiệp sĩ');
    expect(relaunched.kidsStars, 80);
    relaunched.dispose();

    // Midnight rollover clears active day intake while preserving yesterday in 7-day history
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextDayCtrl = AquaUiController(initialStage: AppFlowStage.splash);
    await nextDayCtrl.initialize(
      autoRedirectAuthenticated: true,
      nowOverride: tomorrow,
    );
    expect(nextDayCtrl.intakeMl, 0);
    expect(nextDayCtrl.drinkLogs, isEmpty);
    nextDayCtrl.dispose();
  });

  testWidgets(
    'Deep 5-Tab CRUD: beverage factor, delete log, bill/leak, Mascot shop, Map search & station proposal',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = AquaUiController(initialStage: AppFlowStage.main);
      await controller.initialize();
      addTearDown(controller.dispose);

      // Verify Coffee factor (80% of 250ml = +200ml & +80mg caffeine) + delete log undo
      controller.selectDrink('Cà phê');
      controller.addWater(250);
      expect(controller.intakeMl, 1700);
      expect(controller.caffeineMg, 175);
      controller.removeDrinkLogAt(0);
      expect(controller.intakeMl, 1500);
      expect(controller.caffeineMg, 95);

      // Verify progressive water bill & leak warning threshold (> 18 m3)
      controller.updateMonthlyWaterMeter(22.0);
      expect(controller.isLeakSuspected, isTrue);
      expect(controller.currentWaterBillVnd, greaterThan(180000));

      // Verify 10-question quiz rotation & station proposal + incident report
      expect(AquaKidsQuizQuestion.bank.length, 10);
      controller.nextQuizQuestion();
      expect(controller.kidsQuizIndex, 1);

      controller.proposeStation(name: 'Trạm Ký túc xá C', tdsPpm: 25);
      controller.setSearchQuery('Ký túc xá');
      expect(controller.filteredStations.length, 1);
      expect(controller.filteredStations.first.name, 'Trạm Ký túc xá C');
      controller.setSearchQuery('');

      controller.submitIncidentReport(
        description: 'Vòi chảy yếu khu Gamma',
        severity: 2,
      );
      expect(controller.incidentReports.first.title, 'Vòi chảy yếu khu Gamma');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.buildLightTheme(),
          home: Scaffold(
            body: Builder(builder: (_) => const SizedBox.shrink()),
          ),
        ),
      );
    },
  );

  test('Custom AI API Client Hook sends context telemetry and parses custom API JSON', () async {
    const householdSnapshot = AquaBotContextSnapshot(
      userName: 'Minh Nguyễn',
      roleLabel: 'Hộ gia đình',
      role: AquaRole.household,
      intakeMl: 1500,
      dailyGoalMl: 2100,
      caffeineMg: 95,
      streakDays: 14,
      tdsPpm: 36,
      phLevel: 7.3,
      roFilterHealth: [15, 78, 82, 90],
      kidsCups: 5,
      kidsGoalCups: 6,
      kidsStars: 120,
      selectedStationName: 'Trạm Thư viện Thành phố',
    );

    const snapshot = AquaBotContextSnapshot(
      userName: 'Minh Nguyễn',
      roleLabel: 'SV / Đi làm',
      role: AquaRole.studentWorker,
      intakeMl: 1500,
      dailyGoalMl: 2100,
      caffeineMg: 95,
      streakDays: 14,
      tdsPpm: 36,
      phLevel: 7.3,
      roFilterHealth: [15, 78, 82, 90],
      kidsCups: 5,
      kidsGoalCups: 6,
      kidsStars: 120,
      selectedStationName: 'Trạm Thư viện Thành phố',
    );

    // 0. Ensure no live API key or endpoint secret is hardcoded in defaults
    expect(AquaBotAiClient.customApiKey, isEmpty);
    expect(AquaBotAiClient.customApiEndpoint, isEmpty);
    expect(AquaBotAiClient().isCustomApiConfigured, isFalse);

    // 1. Default unconfigured local smart fallback (role-aware)
    final localClient = AquaBotAiClient(endpointOverride: '');
    expect(localClient.isCustomApiConfigured, isFalse);
    final studentTdsReply = await localClient.generateReply(
      userMessage: 'TDS bao nhiêu?',
      history: const [],
      snapshot: snapshot,
    );
    expect(studentTdsReply, isNot(contains('Bộ lọc thô cấp 1')));

    final localReply = await localClient.generateReply(
      userMessage: 'TDS bao nhiêu?',
      history: const [],
      snapshot: householdSnapshot,
    );
    expect(localReply, contains('36 ppm'));
    expect(localReply, contains('Bộ lọc thô cấp 1'));

    // 2. Custom API endpoint configured with Mock HTTP Client (Webhook / OpenAI)
    late Map<String, dynamic> capturedBody;
    final mockHttp = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer demo-secret-key');
      capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({'reply': 'Phản hồi trực tiếp từ Custom AI Server!'}),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final customClient = AquaBotAiClient(
      httpClient: mockHttp,
      endpointOverride: 'https://custom-ai.example.com/chat',
      apiKeyOverride: 'demo-secret-key',
      modelOverride: 'gemini-2.5-flash',
    );
    expect(customClient.isCustomApiConfigured, isTrue);
    expect(customClient.effectiveModel, 'gemini-2.5-flash');

    final customReply = await customClient.generateReply(
      userMessage: 'Hôm nay uống đủ nước chưa?',
      history: const [],
      snapshot: snapshot,
    );
    expect(customReply, 'Phản hồi trực tiếp từ Custom AI Server!');
    expect(capturedBody['model'], 'gemini-2.5-flash');
    expect(capturedBody['telemetry']['intakeMl'], 1500);
    expect(capturedBody['message'], 'Hôm nay uống đủ nước chưa?');

    // 3. Anthropic Messages API (`/v1/messages` / `sk-ant-...`) auto-rewrite & content block parsing
    late http.Request capturedAnthropicReq;
    final anthropicMock = MockClient((request) async {
      capturedAnthropicReq = request;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'type': 'message',
            'role': 'assistant',
            'content': [
              {'type': 'thinking', 'thinking': 'Analyzing TDS...'},
              {
                'type': 'text',
                'text':
                    'TDS 36 ppm của nhà Minh rất sạch, nhớ thay lõi số 1 nhé!',
              },
            ],
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final anthropicClient = AquaBotAiClient(
      httpClient: anthropicMock,
      endpointOverride: 'https://1gw.gwai.cloud/v1/chat/completions',
      apiKeyOverride: 'sk-ant-api03-test',
      modelOverride: 'deepseek-v4.1-flash-1017',
    );
    expect(
      anthropicClient.effectiveEndpoint,
      'https://1gw.gwai.cloud/v1/messages',
    );
    final anthropicReply = await anthropicClient.generateReply(
      userMessage: 'TDS bao nhiêu là tốt?',
      history: const [
        AquaBotMessage(isUser: false, text: 'Chào Minh!'),
        AquaBotMessage(isUser: true, text: 'TDS bao nhiêu là tốt?'),
      ],
      snapshot: snapshot,
    );
    expect(
      anthropicReply,
      'TDS 36 ppm của nhà Minh rất sạch, nhớ thay lõi số 1 nhé!',
    );
    expect(capturedAnthropicReq.headers['x-api-key'], 'sk-ant-api03-test');
    expect(capturedAnthropicReq.headers['anthropic-version'], '2023-06-01');
    final sentPayload =
        jsonDecode(capturedAnthropicReq.body) as Map<String, dynamic>;
    final sentMsgs = sentPayload['messages'] as List;
    expect(sentMsgs.length, 1);
    expect(sentMsgs.first['role'], 'user');

    // 4. Structured HTTP 403 handling keeps reply bubble clean while surfacing diagnostic status
    final forbiddenClient = AquaBotAiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"error":"forbidden"}', 403),
      ),
      endpointOverride: 'https://1gw.gwai.cloud/v1/messages',
      apiKeyOverride: 'sk-ant-expired',
      modelOverride: 'deepseek-v4.1-flash-1017',
    );
    final forbiddenRes = await forbiddenClient.generateStructuredReply(
      userMessage: 'TDS bao nhiêu?',
      history: const [],
      snapshot: householdSnapshot,
    );
    expect(forbiddenRes.usedLocalFallback, isTrue);
    expect(forbiddenRes.text, isNot(contains('403')));
    expect(forbiddenRes.diagnosticStatus, contains('403'));
  });

  test('Barcode & QR Lookup Service decodes VN bottles, OpenFoodFacts live JSON, Station QR & RO cartridges', () async {
    // 1. VN bottled water EAN offline catalog fallback
    final lavie = await AquaBarcodeLookupService.lookup('8935012011340');
    expect(lavie.kind, AquaScannedKind.waterBottle);
    expect(lavie.brand, 'La Vie');
    expect(lavie.recommendedMl, 500);
    expect(lavie.estimatedTdsPpm, 155);

    // 2. OpenFoodFacts live JSON parsing via MockClient
    final offMock = MockClient((req) async {
      expect(req.url.host, 'world.openfoodfacts.org');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name_vi': 'Nước khoáng Lavie Chai 350ml',
              'brands': 'La Vie',
              'quantity': '350 ml',
            },
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final offRes = await AquaBarcodeLookupService.lookup(
      '8935012011357',
      client: offMock,
    );
    expect(offRes.kind, AquaScannedKind.waterBottle);
    expect(offRes.recommendedMl, 350);
    expect(offRes.sourceLabel, 'OpenFoodFacts Live API');

    // 3. Station QR JSON payload
    final stationRes = await AquaBarcodeLookupService.lookup(
      '{"type":"station","name":"Trạm Sảnh Beta","ml":450,"tds":19}',
    );
    expect(stationRes.kind, AquaScannedKind.refillStation);
    expect(stationRes.stationName, 'Trạm Sảnh Beta');
    expect(stationRes.recommendedMl, 450);
    expect(stationRes.estimatedTdsPpm, 19);

    // 4. RO Filter Cartridge text code
    final filterRes = await AquaBarcodeLookupService.lookup('RO-FILTER-2');
    expect(filterRes.kind, AquaScannedKind.roFilterCartridge);
    expect(filterRes.filterSlotIndex, 1);
  });

  testWidgets(
    'Waterllama UI & Motion: Giant Cup Modal, 100% Confetti, Mascot Collection & 3D Flip History',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AquaCareApp(initialStage: AppFlowStage.main),
      );
      await tester.pumpAndSettle();

      // 1. Open Giant Draggable Cup Modal, pick 500 ml preset & log drink
      await tester.tap(find.textContaining('Kéo cốc nước khổng lồ'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn đồ uống & thể tích'), findsOneWidget);
      await tester.tap(find.text('500 ml'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ GHI NHẬN 500 ML NƯỚC LỌC'));
      await tester.pumpAndSettle();
      expect(find.text('2000 / 2100 ml'), findsOneWidget);

      // 2. Cross 100% hydration goal -> triggers confetti & goal completion pill
      await tester.tap(find.widgetWithText(FilledButton, '+250 ml'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('2250 / 2100 ml'), findsOneWidget);
      expect(find.text('Đã đạt mục tiêu! 🎉'), findsOneWidget);

      // 3. Open Mascot Collection Modal -> verify 6/6 unlocked at 100% & switch to Cá Voi Xanh
      await tester.tap(find.text('BÉ GIỌT NƯỚC'));
      await tester.pumpAndSettle();
      expect(find.text('Bộ sưu tập Hộ vệ Nước sạch'), findsOneWidget);
      expect(find.text('6/6'), findsOneWidget);
      await tester.tap(find.text('Cá Voi Xanh').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('CÁ VOI XANH'), findsOneWidget);

      // 4. Open History Modal & flip 3D stat badge
      await tester.tap(find.text('LỊCH SỬ'));
      await tester.pumpAndSettle();
      expect(find.text('Nhịp cấp ẩm 7 ngày'), findsOneWidget);
      expect(find.text('CHUỖI\nNGÀY'), findsOneWidget);
      await tester.tap(find.text('CHUỖI\nNGÀY'));
      await tester.pump(const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(find.text('TRUNG BÌNH\nML/NGÀY'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  test('SDG 6 Alignment: WHO/QCVN water thresholds, WASH checklists, bottle eco-nudge & map sanitation filter', () async {
    // 1. Scientific WHO / QCVN evaluation per water source type
    final roSafe = AquaWaterSafetyAssessment.evaluate(
      tdsPpm: 36,
      phLevel: 7.3,
      sourceType: AquaWaterSourceType.roPurified,
    );
    expect(roSafe.status, AquaWaterSafetyStatus.safe);
    expect(roSafe.isTdsOk, isTrue);

    final roCaution = AquaWaterSafetyAssessment.evaluate(
      tdsPpm: 85,
      phLevel: 7.3,
      sourceType: AquaWaterSourceType.roPurified,
    );
    expect(roCaution.status, AquaWaterSafetyStatus.caution);
    expect(roCaution.isTdsOk, isFalse);

    final lavieSafe = AquaWaterSafetyAssessment.evaluate(
      tdsPpm: 155,
      phLevel: 7.7,
      sourceType: AquaWaterSourceType.mineralNatural,
    );
    expect(lavieSafe.status, AquaWaterSafetyStatus.safe);
    expect(lavieSafe.isTdsOk, isTrue);
    expect(lavieSafe.isPhOk, isTrue);

    final ionLifeSafe = AquaWaterSafetyAssessment.evaluate(
      tdsPpm: 95,
      phLevel: 8.8,
      sourceType: AquaWaterSourceType.mineralNatural,
    );
    expect(ionLifeSafe.status, AquaWaterSafetyStatus.safe);
    expect(ionLifeSafe.isPhOk, isTrue);

    final tapSafe = AquaWaterSafetyAssessment.evaluate(
      tdsPpm: 210,
      phLevel: 7.2,
      sourceType: AquaWaterSourceType.tapSafe,
    );
    expect(tapSafe.status, AquaWaterSafetyStatus.safe);
    expect(tapSafe.isChlorineOk, isTrue);

    final tapWarning = AquaWaterSafetyAssessment.evaluate(
      tdsPpm: 360,
      phLevel: 7.2,
      sourceType: AquaWaterSourceType.tapSafe,
    );
    expect(tapWarning.status, AquaWaterSafetyStatus.warning);
    expect(tapWarning.isTdsOk, isFalse);
    expect(tapWarning.isChlorineOk, isFalse);
    expect(tapWarning.isTurbidityOk, isFalse);

    // 2. WASH sanitation checklist persistence & water source persistence
    final controller = AquaUiController();
    await controller.initialize();
    controller.setWaterSourceType(AquaWaterSourceType.mineralNatural);
    controller.toggleSanitationTask('hh_faucet');
    controller.toggleSanitationTask('st_bottle');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    controller.dispose();

    final relaunched = AquaUiController();
    await relaunched.initialize();
    expect(relaunched.waterSourceType, AquaWaterSourceType.mineralNatural);
    expect(
      relaunched.householdSanitationTasks
          .firstWhere((t) => t.id == 'hh_faucet')
          .completed,
      isTrue,
    );
    expect(
      relaunched.personalSanitationTasks
          .firstWhere((t) => t.id == 'st_bottle')
          .completed,
      isTrue,
    );

    // 3. Single-use bottle scan shows SDG 6 eco-nudge without adding plasticSaved; Refill adds plasticSaved
    final initialPlastic = relaunched.plasticSaved;
    final bottleMsg = relaunched.applyScannedCodeResult(
      const AquaScannedCodeResult(
        rawCode: '8935012011340',
        kind: AquaScannedKind.waterBottle,
        title: 'Nước khoáng thiên nhiên La Vie 500ml',
        subtitle: 'La Vie',
        brand: 'La Vie',
        recommendedMl: 500,
      ),
    );
    expect(bottleMsg, contains('SDG 6'));
    expect(relaunched.plasticSaved, initialPlastic);

    final refillMsg = relaunched.applyScannedCodeResult(
      const AquaScannedCodeResult(
        rawCode: 'AQUACARE_VERIFIED_QR',
        kind: AquaScannedKind.refillStation,
        title: 'Trạm Refill Thư viện Thành phố',
        subtitle: 'Refill',
        stationName: 'Trạm Thư viện Thành phố',
        recommendedMl: 350,
      ),
    );
    expect(refillMsg, contains('+1 chai nhựa tiết kiệm'));
    expect(relaunched.plasticSaved, initialPlastic + 1);

    // 4. Map sanitation filter & station proposal with handwashing sanitation
    relaunched.toggleStationFilter(sanitationOnly: true);
    expect(
      relaunched.filteredStations.every((s) => s.hasHandwashSanitation),
      isTrue,
    );
    final beforeCount = relaunched.filteredStations.length;
    relaunched.proposeStation(
      name: 'Điểm rửa tay Sảnh B',
      tdsPpm: 25,
      hasHandwashSanitation: true,
    );
    expect(relaunched.filteredStations.length, beforeCount + 1);
    expect(relaunched.filteredStations.first.hasHandwashSanitation, isTrue);
    relaunched.dispose();
  });

  testWidgets(
    'Smart Reminders & Hydration Goal Calculator flow: Gender/Weight/Activity/Climate calculation & 3-bar animation',
    (WidgetTester tester) async {
      // 1. Unit verification of formula across gender, pregnancy/breastfeeding, activity & climate
      final maleGoal = AquaHydrationCalculator.calculateRecommendedMl(
        bodyWeightKg: 70,
        gender: AquaGenderProfile.male,
        activity: AquaActivityLevel.moderate,
        climate: AquaClimateLevel.temperate,
      );
      final femaleGoal = AquaHydrationCalculator.calculateRecommendedMl(
        bodyWeightKg: 55,
        gender: AquaGenderProfile.female,
        activity: AquaActivityLevel.light,
        climate: AquaClimateLevel.cool,
      );
      final pregnantGoal = AquaHydrationCalculator.calculateRecommendedMl(
        bodyWeightKg: 58,
        gender: AquaGenderProfile.pregnant,
        activity: AquaActivityLevel.moderate,
        climate: AquaClimateLevel.humidWarm,
      );
      expect(maleGoal, greaterThan(femaleGoal));
      expect(pregnantGoal, greaterThan(femaleGoal));

      // 2. End-to-end unified setup (Role -> Schedule -> 4-stage Personalizer) inside Onboarding (before Login screen)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const AquaCareApp(initialStage: AppFlowStage.onboarding),
      );
      await tester.pumpAndSettle();

      // Advance across the 3 intro onboarding slides into unified Setup + Personalizer
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thiết lập hồ sơ ngay →'));
      await tester.pumpAndSettle();

      // Step 1/2: Role selection (Sinh viên & người đi làm selected by default)
      expect(
        find.text('Bạn muốn dùng AquaCare với vai trò nào?'),
        findsOneWidget,
      );
      expect(find.text('Bước 1/2'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      // Step 2/2: Shift schedule (no duplicate weight/water-source steps)
      expect(find.text('Lịch học tập & làm việc'), findsOneWidget);
      expect(find.text('Bước 2/2'), findsOneWidget);
      expect(find.text('Hồ sơ & chỉ số cơ thể'), findsNothing);
      await tester.tap(find.text('Tiếp tục tính mục tiêu →'));
      await tester.pumpAndSettle();
      expect(find.text('Lời nhắc thông minh'), findsOneWidget);

      // Tap 'Nhắc tôi uống nước' -> rising cyan wave wipe -> Calculator stage
      await tester.tap(find.text('Nhắc tôi uống nước'));
      await tester.pumpAndSettle();
      expect(find.text('Tính mục tiêu của bạn'), findsOneWidget);
      expect(find.text('2000ml'), findsOneWidget);

      // Pick Gender: Nam giới -> updates to Mục tiêu khuyến nghị
      await tester.tap(find.text('Giới tính'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nam giới'));
      await tester.pumpAndSettle();
      expect(find.text('Mục tiêu khuyến nghị'), findsOneWidget);

      // Open Weight wheel modal & confirm
      await tester.tap(find.text('Cân nặng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xong').last);
      await tester.pumpAndSettle();
      expect(find.text('62 kg'), findsOneWidget);

      // Pick Activity: Vận động nhiều
      await tester.tap(find.text('Hoạt động tương đối'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vận động nhiều'));
      await tester.pumpAndSettle();

      // Pick Climate: Nóng ẩm
      await tester.tap(find.text('Ôn hòa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nóng ẩm'));
      await tester.pumpAndSettle();

      final expectedMl = AquaHydrationCalculator.calculateRecommendedMl(
        bodyWeightKg: 62,
        gender: AquaGenderProfile.male,
        activity: AquaActivityLevel.active,
        climate: AquaClimateLevel.humidWarm,
      );
      expect(find.text('${expectedMl}ml'), findsOneWidget);

      // Tap 'Xong' -> SDG 6 Benefits Comparison Stage & Topic Switcher
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.text('Cảm thấy tuyệt nhất\nmỗi ngày'), findsOneWidget);
      expect(find.textContaining('WHO/QCVN'), findsWidgets);
      expect(find.text('Nước sạch & WASH'), findsOneWidget);

      await tester.tap(find.text('Nước sạch & WASH'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Checklist WASH'), findsOneWidget);

      // Tap 'Cảm thấy tuyệt nhất!' -> 3-bar Animated Calculation Stage
      await tester.tap(find.text('Cảm thấy tuyệt nhất!'));
      await tester.pumpAndSettle();
      expect(find.text('Phân tích dữ liệu của bạn'), findsOneWidget);
      expect(find.text('Cá nhân hóa các mục tiêu'), findsOneWidget);
      expect(find.text('Chuẩn bị lộ trình nước sạch SDG 6'), findsOneWidget);
      expect(
        find.text('Mục tiêu của bạn: $expectedMl ml / ngày'),
        findsOneWidget,
      );

      // Complete onboarding setup -> AuthScreen displays unified Role + Goal badge
      await tester.tap(find.text('Tiếp tục đến đăng nhập ✓'));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng đến AquaCare'), findsOneWidget);
      expect(
        find.text('${AquaRole.studentWorker.label} • $expectedMl ml/ngày ✓'),
        findsOneWidget,
      );

      // Guest CTA skips duplicate SetupWizardScreen and goes straight to Home Tab
      await tester.tap(find.text('Tiếp tục không cần đăng nhập →'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn muốn dùng AquaCare với vai trò nào?'),
        findsNothing,
      );
      expect(find.text('1500 / $expectedMl ml'), findsOneWidget);

      // Verify Profile quick access card renders cleanly
      await tester.tap(find.text('Cá nhân'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tính mục tiêu uống nước cá nhân'));
      expect(find.text('Tính mục tiêu uống nước cá nhân'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Post-onboarding Sign Up bypasses duplicate setup & Household completes 4-step flow before login',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Verify controller contract: once initial setup is done, new Sign Up routes straight to main
      final controller = AquaUiController();
      await controller.initialize();
      controller.markOnboardingSetupDone();
      controller.completeAuth(isNewUser: true, userName: 'Lan Anh');
      expect(controller.hasCompletedInitialSetup, isTrue);
      expect(controller.stage, AppFlowStage.main);
      expect(controller.userName, 'Lan Anh');
      controller.dispose();

      // Verify Household 4-step flow inside Onboarding -> Auth badge -> Guest to Home
      await tester.pumpWidget(
        const AquaCareApp(initialStage: AppFlowStage.onboarding),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thiết lập hồ sơ ngay →'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hộ gia đình'));
      await tester.pumpAndSettle();
      expect(find.text('Bước 1/4'), findsOneWidget);

      // Advance Steps 1 -> 2 -> 3 -> 4
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bước 2/4'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bước 3/4'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(find.text('Bước 4/4'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục tính mục tiêu →'));
      await tester.pumpAndSettle();
      expect(find.text('Phân tích dữ liệu của bạn'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục đến đăng nhập ✓'));
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng đến AquaCare'), findsOneWidget);
      expect(find.text('Hộ gia đình • 2100 ml/ngày ✓'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Real Android phone viewports (360x720 compact & 412x915 tall) fit without overflow',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final viewport in const [Size(360, 720), Size(412, 915)]) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          AquaCareApp(
            key: ValueKey<Size>(viewport),
            initialStage: AppFlowStage.onboarding,
            enablePersistence: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Thiết lập hồ sơ ngay →'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiếp tục tính mục tiêu →'));
        await tester.pumpAndSettle();

        expect(find.text('Lời nhắc thông minh'), findsOneWidget);
        await tester.tap(find.text('Nhắc tôi uống nước'));
        await tester.pumpAndSettle();

        expect(find.text('Tính mục tiêu của bạn'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục →'));
        await tester.pumpAndSettle();

        expect(find.text('Cảm thấy tuyệt nhất\nmỗi ngày'), findsOneWidget);
        await tester.tap(find.text('Cảm thấy tuyệt nhất!'));
        await tester.pumpAndSettle();

        expect(find.text('Tiếp tục đến đăng nhập ✓'), findsOneWidget);
        await tester.tap(find.text('Tiếp tục đến đăng nhập ✓'));
        await tester.pumpAndSettle();
        expect(find.text('Chào mừng đến AquaCare'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
