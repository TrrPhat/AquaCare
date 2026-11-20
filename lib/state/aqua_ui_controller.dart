import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../models/aqua_models.dart';
import '../services/aqua_barcode_lookup_service.dart';
import '../services/aqua_cloud_sync_service.dart';
import '../services/aqua_hardware_service.dart';
import '../services/aqua_local_storage.dart';
import '../services/aqua_notification_service.dart';
import '../services/aquabot_ai_client.dart';

export '../models/aqua_models.dart';

/// Persistent Offline-First + Cloud-Sync UI & business state controller for AquaCare.
class AquaUiController extends ChangeNotifier {
  AquaUiController({
    AppFlowStage initialStage = AppFlowStage.splash,
    AquaLocalStorage? localStorage,
    AquaCloudSyncService? cloudSync,
    AquaBotAiClient? aiClient,
    this.enablePersistence = true,
  })  : _stage = initialStage,
        _localStorage = localStorage ?? AquaLocalStorage(),
        _cloudSync = cloudSync ?? AquaCloudSyncService(),
        _aiClient = aiClient ?? AquaBotAiClient() {
    _seedDefaultsForDate(DateTime.now());
  }

  final AquaLocalStorage _localStorage;
  final AquaCloudSyncService _cloudSync;
  final AquaBotAiClient _aiClient;
  final bool enablePersistence;

  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _isCloudAccount = false;
  bool _isSyncing = false;
  bool _isBotTyping = false;
  bool _isLocatingGps = false;
  String _userUid = 'local_user';
  String _lastSyncLabel = 'Đã lưu trên máy';

  AppFlowStage _stage;
  int _activeTabIndex = 0;
  String _userName = 'Minh Nguyễn';
  String _kidsName = 'Bé An';
  String _weatherLabel = '';
  String? _aiDiagnosticBanner;
  String _runtimeAiEndpoint = '';
  String _runtimeAiModel = '';
  String _runtimeAiKey = '';
  int _unreadNotifications = 3;

  String _activeDateKey = aquaDayKey(DateTime.now());
  final Map<String, int> _dailyHistory = {};

  final List<AquaDrinkLogEntry> _drinkLogs = [];

  // Role & Onboarding state
  AquaRole _role = AquaRole.studentWorker;
  double _bodyWeightKg = 62;
  AquaGenderProfile? _genderProfile;
  AquaActivityLevel _activityLevel = AquaActivityLevel.moderate;
  AquaClimateLevel _climateLevel = AquaClimateLevel.temperate;
  AquaWeightUnit _weightUnit = AquaWeightUnit.kg;
  bool _smartRemindersEnabled = true;
  bool _hasCompletedInitialSetup = false;
  String _selectedShift = 'Ca sáng & chiều (08:00 - 17:30)';
  String _waterSource = 'Máy lọc RO gia đình';
  String _otpCode = '4829';

  // Module 2 Hydration state
  int _intakeMl = 1500;
  int _dailyGoalMl = 2100;
  String _selectedDrink = 'Nước lọc';
  String _selectedMascotId = 'giot_nuoc';
  double _cupVolumeMl = 250;
  int _caffeineMg = 95;
  int _plasticSaved = 14;
  bool _morningReminder = true;
  bool _afternoonReminder = true;
  bool _eveningReminder = false;
  bool _watchSyncEnabled = true;

  // Pomodoro timer state
  int _pomodoroSeconds = 25 * 60;
  bool _pomodoroRunning = false;
  Timer? _pomodoroTimer;

  // Module 3 Map & Incident state
  int _selectedStationId = 1;
  bool _filterFreeOnly = true;
  bool _filterHotCold = false;
  bool _filterOpen24h = false;
  bool _filterSanitationOnly = false;
  double _searchRadiusKm = 1.5;
  int _stationRating = 5;
  int _incidentSeverity = 1;
  int _communityUpvotes = 24;
  double _userLat = AquaHardwareService.defaultLat;
  double _userLng = AquaHardwareService.defaultLng;
  String _gpsStatusLabel = 'Khu vực Trung tâm Đà Nẵng';
  int _gpsFixRevision = 0;
  final List<AquaRefillStation> _nearbyDynamicStations = [];
  final List<AquaRefillStation> _customStations = [];
  final List<AquaIncidentReport> _incidentReports = [];

  // Module 4 Household Water, Sanitation (WASH), Filter Safety & Water Bills state
  AquaWaterSourceType _waterSourceType = AquaWaterSourceType.roPurified;
  int _tdsPpm = 36;
  double _phLevel = 7.3;
  final List<int> _roFilterHealth = [15, 78, 82, 90];
  final Set<String> _completedSanitationIds = {'hh_handwash', 'st_refill'};
  int _selectedTechSlot = 1;
  bool _tankCleanReminder = true;
  double _monthlyCubicMeters = 14.0;
  final List<AquaWaterTestRecord> _waterTestRecords = [];
  final List<AquaTechBooking> _techBookings = [];

  // Module 5 AquaKids state
  int _kidsCups = 5;
  int _kidsGoalCups = 6;
  int _kidsStars = 120;
  int _kidsQuizIndex = 0;
  int _kidsSelectedQuizOption = -1;
  bool _quizRewardClaimed = false;
  int _comicPageIndex = 0;
  String _equippedMascotItem = 'Vương miện Giọt Nước';
  final Set<String> _unlockedMascotItems = {'Vương miện Giọt Nước'};
  final Set<int> _bottleStickers = {0, 2};
  String _parentPin = '1234';
  String _pinInput = '';
  bool _parentGateUnlocked = false;
  int _brushSecondsLeft = 120;
  Timer? _brushTimer;
  bool _brushRunning = false;
  final List<bool> _handwashSteps = [true, true, true, false, false, false];

  // Search & AquaBot chat
  String _searchQuery = '';
  final List<AquaBotMessage> _chatMessages = [];

  static const List<AquaRefillStation> stations = [
    AquaRefillStation(
      id: 1,
      name: 'Trạm Thư viện Thành phố',
      distanceMeters: 120,
      tdsPpm: 28,
      isFree: true,
      hasHotCold: true,
      isOpen24h: false,
      xFactor: 0.62,
      yFactor: 0.34,
      latitude: 15.9694,
      longitude: 108.2607,
      hasHandwashSanitation: true,
    ),
    AquaRefillStation(
      id: 2,
      name: 'Trạm Sảnh Trung tâm Hành chính',
      distanceMeters: 240,
      tdsPpm: 32,
      isFree: true,
      hasHotCold: true,
      isOpen24h: false,
      xFactor: 0.34,
      yFactor: 0.56,
      latitude: 15.9682,
      longitude: 108.2591,
      hasHandwashSanitation: true,
    ),
    AquaRefillStation(
      id: 3,
      name: 'Trạm Công viên Trung tâm',
      distanceMeters: 410,
      tdsPpm: 35,
      isFree: true,
      hasHotCold: false,
      isOpen24h: true,
      xFactor: 0.78,
      yFactor: 0.64,
      latitude: 15.9673,
      longitude: 108.2624,
      hasHandwashSanitation: true,
    ),
    AquaRefillStation(
      id: 4,
      name: 'Trạm Nhà Văn hóa Thanh niên',
      distanceMeters: 620,
      tdsPpm: 39,
      isFree: true,
      hasHotCold: true,
      isOpen24h: true,
      xFactor: 0.22,
      yFactor: 0.26,
      latitude: 15.9708,
      longitude: 108.2584,
    ),
  ];

  void _seedDefaultsForDate(DateTime now) {
    _activeDateKey = aquaDayKey(now);
    _drinkLogs
      ..clear()
      ..addAll(const [
        AquaDrinkLogEntry(
          id: 'seed_1',
          time: '08:00',
          drink: 'Nước ấm',
          ml: 250,
          rawMl: 250,
        ),
        AquaDrinkLogEntry(
          id: 'seed_2',
          time: '10:15',
          drink: 'Nước lọc',
          ml: 300,
          rawMl: 300,
        ),
        AquaDrinkLogEntry(
          id: 'seed_3',
          time: '13:30',
          drink: 'Trà xanh',
          ml: 200,
          rawMl: 210,
          caffeineMg: 25,
        ),
        AquaDrinkLogEntry(
          id: 'seed_4',
          time: '14:45',
          drink: 'Nước lọc',
          ml: 250,
          rawMl: 250,
        ),
        AquaDrinkLogEntry(
          id: 'seed_5',
          time: '16:20',
          drink: 'Nước lọc',
          ml: 500,
          rawMl: 500,
        ),
      ]);

    _dailyHistory.clear();
    const pastOffsets = [1780, 1930, 1640, 2100, 1980, 1850];
    for (int i = 6; i >= 1; i--) {
      final day = now.subtract(Duration(days: i));
      _dailyHistory[aquaDayKey(day)] = pastOffsets[6 - i];
    }
    _dailyHistory[_activeDateKey] = _intakeMl;

    _waterTestRecords
      ..clear()
      ..addAll(const [
        AquaWaterTestRecord(
          id: 'wt_1',
          dateLabel: 'Hôm nay • 07:45',
          tdsPpm: 36,
          phLevel: 7.3,
          sourceNote: 'Nước lọc RO gia đình',
        ),
        AquaWaterTestRecord(
          id: 'wt_2',
          dateLabel: '3 ngày trước',
          tdsPpm: 38,
          phLevel: 7.2,
          sourceNote: 'Kiểm tra định kỳ',
        ),
        AquaWaterTestRecord(
          id: 'wt_3',
          dateLabel: '1 tuần trước',
          tdsPpm: 35,
          phLevel: 7.3,
          sourceNote: 'Sau vệ sinh vòi rót',
        ),
        AquaWaterTestRecord(
          id: 'wt_4',
          dateLabel: '2 tuần trước',
          tdsPpm: 40,
          phLevel: 7.2,
          sourceNote: 'Kiểm định đầu tháng',
        ),
      ]);

    _techBookings.clear();

    _incidentReports
      ..clear()
      ..addAll(const [
        AquaIncidentReport(
          id: 'inc_seed_1',
          title: 'Áp lực nước yếu khu vực đường Nam Kỳ Khởi Nghĩa',
          severity: 1,
          stationName: 'Trạm Công viên Trung tâm',
          createdAtLabel: '2 giờ trước',
          status: 'Đang kiểm tra',
          upvotes: 24,
        ),
      ]);

    _chatMessages
      ..clear()
      ..addAll(_defaultMessagesForRole(_role));
  }

  List<AquaBotMessage> _defaultMessagesForRole(AquaRole targetRole) {
    return switch (targetRole) {
      AquaRole.studentWorker => [
          AquaBotMessage(
            isUser: false,
            text:
                'Chào $_userName! Mình là AquaBot. Hôm nay mục tiêu của bạn là $_dailyGoalMl ml — bạn cần gợi ý lịch uống nước theo ca hay tìm trạm Refill gần đây?',
          ),
        ],
      AquaRole.household => [
          AquaBotMessage(
            isUser: false,
            text:
                'Chào $_userName! Nguồn nước gia đình đang đạt TDS $_tdsPpm ppm (${waterSafetyAssessment.headline}). Hỏi mình về chuẩn nước sạch WHO/QCVN, lịch vệ sinh WASH hoặc chế độ uống nước của $_kidsName nhé!',
          ),
        ],
      AquaRole.kids => [
          AquaBotMessage(
            isUser: false,
            text:
                'Chào $_kidsName! Giọt Nước Vui Nhộn sẵn sàng cùng bạn uống đủ nước và sưu tầm Sao Vàng hôm nay nè!',
          ),
        ],
    };
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  bool get isCloudAccount => _isCloudAccount;
  bool get isSyncing => _isSyncing;
  bool get isBotTyping => _isBotTyping;
  bool get isLocatingGps => _isLocatingGps;
  int get gpsFixRevision => _gpsFixRevision;
  String get cloudStatusLabel => _cloudSync.isCloudReady
      ? 'Firebase Cloud Sync • Đang bật'
      : _lastSyncLabel;
  bool get isFirebaseConfigured => _cloudSync.isConfigured;
  bool get isCustomAiConfigured => _aiClient.isCustomApiConfigured;
  String get customAiModelName => _aiClient.effectiveModel;
  String get activeAiEndpoint => _aiClient.effectiveEndpoint;
  String get activeAiModel => _aiClient.effectiveModel;
  String get activeAiApiKey => _aiClient.effectiveApiKey;
  String? get aiDiagnosticBanner => _aiDiagnosticBanner;
  AquaCloudSyncService get cloudSync => _cloudSync;

  AppFlowStage get stage => _stage;
  int get activeTabIndex => _activeTabIndex;
  String get userName => _userName;
  String get kidsName => _kidsName;
  String get weatherLabel {
    if (_weatherLabel.isNotEmpty) return _weatherLabel;
    final h = DateTime.now().hour;
    if (h < 11) return 'Buổi sáng • Khởi động ngày mới đầy năng lượng';
    if (h < 18) return 'Buổi chiều • Nhớ uống nước đều giữ tập trung';
    return 'Buổi tối • Bổ sung nước nhẹ nhàng cho cơ thể';
  }
  String get greetingByTime {
    final h = DateTime.now().hour;
    if (h < 11) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
  int get unreadNotifications => _unreadNotifications;
  List<AquaDrinkLogEntry> get drinkLogs => List.unmodifiable(_drinkLogs);

  AquaRole get role => _role;
  double get bodyWeightKg => _bodyWeightKg;
  AquaGenderProfile? get genderProfile => _genderProfile;
  AquaActivityLevel get activityLevel => _activityLevel;
  AquaClimateLevel get climateLevel => _climateLevel;
  AquaWeightUnit get weightUnit => _weightUnit;
  bool get smartRemindersEnabled => _smartRemindersEnabled;
  bool get hasCompletedInitialSetup => _hasCompletedInitialSetup;
  AquaHydrationBreakdown get hydrationBreakdown => AquaHydrationCalculator.breakdown(
        bodyWeightKg: _bodyWeightKg,
        gender: _genderProfile ?? AquaGenderProfile.preferNotToSay,
        activity: _activityLevel,
        climate: _climateLevel,
      );
  int get recommendedGoalMl => hydrationBreakdown.totalMl;
  String get selectedShift => _selectedShift;
  String get waterSource => _waterSource;
  String get otpCode => _otpCode;

  int get intakeMl => _intakeMl;
  int get dailyGoalMl => _dailyGoalMl;
  double get intakeProgress => (_intakeMl / _dailyGoalMl).clamp(0.0, 1.0);
  int get intakePercent => (intakeProgress * 100).round();

  String get selectedDrink => _selectedDrink;
  String get selectedMascotId => _selectedMascotId;
  double get cupVolumeMl => _cupVolumeMl;
  int get caffeineMg => _caffeineMg;
  int get plasticSaved => _plasticSaved;
  bool get morningReminder => _morningReminder;
  bool get afternoonReminder => _afternoonReminder;
  bool get eveningReminder => _eveningReminder;
  bool get watchSyncEnabled => _watchSyncEnabled;

  List<(String label, int ml, double ratio)> get last7DaysStats {
    final now = DateTime.now();
    final todayKey = aquaDayKey(now);
    final goal = _dailyGoalMl > 0 ? _dailyGoalMl : 2100;
    final list = <(String, int, double)>[];
    for (int offset = 6; offset >= 0; offset--) {
      final dt = now.subtract(Duration(days: offset));
      final key = aquaDayKey(dt);
      final ml = key == todayKey ? _intakeMl : (_dailyHistory[key] ?? 0);
      final ratio = (ml / goal).clamp(0.0, 1.0);
      list.add((aquaWeekdayShort(dt), ml, ratio));
    }
    return list;
  }

  int get weeklyAverageMl {
    final stats = last7DaysStats;
    final nonZero = stats.where((e) => e.$2 > 0).toList();
    if (nonZero.isEmpty) return _intakeMl;
    final total = nonZero.fold<int>(0, (sum, e) => sum + e.$2);
    return (total / nonZero.length).round();
  }

  int get streakDays {
    final now = DateTime.now();
    final threshold = (_dailyGoalMl * 0.7).round();
    int consecutive = 0;
    for (int offset = 0; offset < 30; offset++) {
      final key = aquaDayKey(now.subtract(Duration(days: offset)));
      final val = key == _activeDateKey ? _intakeMl : (_dailyHistory[key] ?? 0);
      if (val >= threshold) {
        consecutive++;
      } else if (offset > 0) {
        break;
      }
    }
    // Include 8 historical baseline days if seeded week stays unbroken
    if (consecutive >= 7) return consecutive + 7;
    return consecutive;
  }

  int get pomodoroSeconds => _pomodoroSeconds;
  bool get pomodoroRunning => _pomodoroRunning;

  int get selectedStationId => _selectedStationId;
  List<AquaRefillStation> get allStations => [
        ..._customStations,
        ..._nearbyDynamicStations,
        ...stations,
      ];

  List<AquaRefillStation> get filteredStations {
    final q = _searchQuery.trim().toLowerCase();
    return allStations.where((s) {
      if (_filterFreeOnly && !s.isFree) return false;
      if (_filterHotCold && !s.hasHotCold) return false;
      if (_filterOpen24h && !s.isOpen24h) return false;
      if (_filterSanitationOnly && !s.hasHandwashSanitation) return false;
      if (q.isNotEmpty && !s.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  AquaRefillStation get selectedStation => allStations.firstWhere(
        (s) => s.id == _selectedStationId,
        orElse: () => stations.first,
      );

  bool get filterFreeOnly => _filterFreeOnly;
  bool get filterHotCold => _filterHotCold;
  bool get filterOpen24h => _filterOpen24h;
  bool get filterSanitationOnly => _filterSanitationOnly;
  double get searchRadiusKm => _searchRadiusKm;
  int get stationRating => _stationRating;
  int get incidentSeverity => _incidentSeverity;
  int get communityUpvotes => _communityUpvotes;
  double get userLat => _userLat;
  double get userLng => _userLng;
  String get gpsStatusLabel => _gpsStatusLabel;
  List<AquaIncidentReport> get incidentReports =>
      List.unmodifiable(_incidentReports);

  AquaWaterSourceType get waterSourceType => _waterSourceType;
  AquaWaterSafetyAssessment get waterSafetyAssessment =>
      AquaWaterSafetyAssessment.evaluate(
        tdsPpm: _tdsPpm,
        phLevel: _phLevel,
        sourceType: _waterSourceType,
      );

  List<AquaSanitationTask> get householdSanitationTasks =>
      AquaSanitationTask.householdDefaults
          .map((t) => t.copyWith(completed: _completedSanitationIds.contains(t.id)))
          .toList();

  List<AquaSanitationTask> get personalSanitationTasks =>
      AquaSanitationTask.personalDefaults
          .map((t) => t.copyWith(completed: _completedSanitationIds.contains(t.id)))
          .toList();

  double get householdSanitationProgress {
    final tasks = householdSanitationTasks;
    if (tasks.isEmpty) return 0.0;
    final done = tasks.where((t) => t.completed).length;
    return done / tasks.length;
  }

  double get personalSanitationProgress {
    final tasks = personalSanitationTasks;
    if (tasks.isEmpty) return 0.0;
    final done = tasks.where((t) => t.completed).length;
    return done / tasks.length;
  }

  int get tdsPpm => _tdsPpm;
  double get phLevel => _phLevel;
  List<int> get roFilterHealth => List.unmodifiable(_roFilterHealth);
  int get selectedTechSlot => _selectedTechSlot;
  bool get tankCleanReminder => _tankCleanReminder;
  double get monthlyCubicMeters => _monthlyCubicMeters;
  int get currentWaterBillVnd =>
      AquaWaterBillEntry.calculateVnd(_monthlyCubicMeters);
  bool get isLeakSuspected => _monthlyCubicMeters > 18.0;
  List<AquaWaterTestRecord> get waterTestRecords =>
      List.unmodifiable(_waterTestRecords);
  List<AquaTechBooking> get techBookings => List.unmodifiable(_techBookings);

  int get kidsCups => _kidsCups;
  int get kidsGoalCups => _kidsGoalCups;
  int get kidsStars => _kidsStars;
  int get kidsQuizIndex => _kidsQuizIndex;
  AquaKidsQuizQuestion get currentQuizQuestion =>
      AquaKidsQuizQuestion.bank[_kidsQuizIndex % AquaKidsQuizQuestion.bank.length];
  int get kidsSelectedQuizOption => _kidsSelectedQuizOption;
  int get comicPageIndex => _comicPageIndex;
  String get equippedMascotItem => _equippedMascotItem;
  Set<String> get unlockedMascotItems => Set.unmodifiable(_unlockedMascotItems);
  Set<int> get bottleStickers => Set.unmodifiable(_bottleStickers);
  String get parentPin => _parentPin;
  String get pinInput => _pinInput;
  bool get parentGateUnlocked => _parentGateUnlocked;
  int get brushSecondsLeft => _brushSecondsLeft;
  bool get brushRunning => _brushRunning;
  List<bool> get handwashSteps => List.unmodifiable(_handwashSteps);

  String get searchQuery => _searchQuery;
  List<AquaBotMessage> get chatMessages => List.unmodifiable(_chatMessages);

  /// Loads persisted offline-first state, checks daily midnight rollover, and initializes cloud/notifications.
  Future<void> initialize({
    bool autoRedirectAuthenticated = false,
    DateTime? nowOverride,
  }) async {
    if (!enablePersistence) {
      _isInitialized = true;
      return;
    }

    await _cloudSync.initializeIfConfigured();
    await AquaNotificationService.instance.initialize();

    final saved = await _localStorage.loadState();
    if (saved != null) {
      _applyJson(saved);
    }

    _applyDailyRollover(nowOverride ?? DateTime.now());

    if (autoRedirectAuthenticated && _isAuthenticated) {
      _stage = AppFlowStage.main;
      _activeTabIndex = 0;
    }

    _isInitialized = true;
    notifyListeners();
    unawaited(refreshWeather());
  }

  Future<void> refreshWeather() async {
    final summary = await AquaHardwareService.instance
        .fetchLiveWeatherSummary(_userLat, _userLng);
    if (summary != null && summary.isNotEmpty) {
      _weatherLabel = summary;
      notifyListeners();
    }
  }

  void _applyDailyRollover(DateTime now) {
    final todayKey = aquaDayKey(now);
    if (_activeDateKey == todayKey) {
      _dailyHistory[todayKey] = _intakeMl;
      return;
    }
    // Archive completed prior day before clearing today's active logs
    _dailyHistory[_activeDateKey] = _intakeMl;
    _activeDateKey = todayKey;
    _intakeMl = 0;
    _caffeineMg = 0;
    _drinkLogs.clear();
    _kidsCups = 0;
    _quizRewardClaimed = false;
    _kidsSelectedQuizOption = -1;
    _completedSanitationIds.removeAll(const [
      'hh_handwash',
      'st_bottle',
      'st_handwash',
      'st_refill',
    ]);
    _dailyHistory[todayKey] = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'isAuthenticated': _isAuthenticated,
      'isCloudAccount': _isCloudAccount,
      'userUid': _userUid,
      'userName': _userName,
      'kidsName': _kidsName,
      'runtimeAiEndpoint': _runtimeAiEndpoint,
      'runtimeAiModel': _runtimeAiModel,
      'runtimeAiKey': _runtimeAiKey,
      'role': _role.name,
      'bodyWeightKg': _bodyWeightKg,
      'genderProfile': _genderProfile?.name,
      'activityLevel': _activityLevel.name,
      'climateLevel': _climateLevel.name,
      'weightUnit': _weightUnit.name,
      'smartRemindersEnabled': _smartRemindersEnabled,
      'hasCompletedInitialSetup': _hasCompletedInitialSetup,
      'selectedShift': _selectedShift,
      'waterSource': _waterSource,
      'waterSourceType': _waterSourceType.name,
      'activeDateKey': _activeDateKey,
      'dailyGoalMl': _dailyGoalMl,
      'intakeMl': _intakeMl,
      'selectedDrink': _selectedDrink,
      'selectedMascotId': _selectedMascotId,
      'cupVolumeMl': _cupVolumeMl,
      'caffeineMg': _caffeineMg,
      'plasticSaved': _plasticSaved,
      'morningReminder': _morningReminder,
      'afternoonReminder': _afternoonReminder,
      'eveningReminder': _eveningReminder,
      'watchSyncEnabled': _watchSyncEnabled,
      'unreadNotifications': _unreadNotifications,
      'drinkLogs': _drinkLogs.map((e) => e.toJson()).toList(),
      'dailyHistory': _dailyHistory,
      'tdsPpm': _tdsPpm,
      'phLevel': _phLevel,
      'roFilterHealth': _roFilterHealth,
      'completedSanitationIds': _completedSanitationIds.toList(),
      'selectedTechSlot': _selectedTechSlot,
      'tankCleanReminder': _tankCleanReminder,
      'monthlyCubicMeters': _monthlyCubicMeters,
      'waterTestRecords': _waterTestRecords.map((e) => e.toJson()).toList(),
      'techBookings': _techBookings.map((e) => e.toJson()).toList(),
      'kidsCups': _kidsCups,
      'kidsGoalCups': _kidsGoalCups,
      'kidsStars': _kidsStars,
      'kidsQuizIndex': _kidsQuizIndex,
      'kidsSelectedQuizOption': _kidsSelectedQuizOption,
      'quizRewardClaimed': _quizRewardClaimed,
      'comicPageIndex': _comicPageIndex,
      'equippedMascotItem': _equippedMascotItem,
      'unlockedMascotItems': _unlockedMascotItems.toList(),
      'bottleStickers': _bottleStickers.toList(),
      'parentPin': _parentPin,
      'handwashSteps': _handwashSteps,
      'selectedStationId': _selectedStationId,
      'stationRating': _stationRating,
      'communityUpvotes': _communityUpvotes,
      'customStations': _customStations.map((e) => e.toJson()).toList(),
      'incidentReports': _incidentReports.map((e) => e.toJson()).toList(),
      'chatMessages': _chatMessages.map((e) => e.toJson()).toList(),
    };
  }

  /// Sanitized subset matching `firestore.rules` `isValidUserDocument` schema cleanly.
  Map<String, dynamic> toCloudPayload() {
    return {
      'userName': _userName,
      'role': _role.name,
      'bodyWeightKg': _bodyWeightKg,
      'genderProfile': _genderProfile?.name,
      'activityLevel': _activityLevel.name,
      'climateLevel': _climateLevel.name,
      'weightUnit': _weightUnit.name,
      'smartRemindersEnabled': _smartRemindersEnabled,
      'selectedShift': _selectedShift,
      'waterSource': _waterSource,
      'dailyGoalMl': _dailyGoalMl,
      'intakeMl': _intakeMl,
      'selectedDrink': _selectedDrink,
      'selectedMascotId': _selectedMascotId,
      'cupVolumeMl': _cupVolumeMl,
      'caffeineMg': _caffeineMg,
      'plasticSaved': _plasticSaved,
      'morningReminder': _morningReminder,
      'afternoonReminder': _afternoonReminder,
      'eveningReminder': _eveningReminder,
      'watchSyncEnabled': _watchSyncEnabled,
      'drinkLogs': _drinkLogs.take(50).map((e) => e.toJson()).toList(),
      'dailyHistory': _dailyHistory,
      'tdsPpm': _tdsPpm,
      'phLevel': _phLevel,
      'roFilterHealth': _roFilterHealth,
      'selectedTechSlot': _selectedTechSlot,
      'tankCleanReminder': _tankCleanReminder,
      'bookings': _techBookings.take(25).map((e) => e.toJson()).toList(),
      'kidsCups': _kidsCups,
      'kidsGoalCups': _kidsGoalCups,
      'kidsStars': _kidsStars,
      'kidsSelectedQuizOption': _kidsSelectedQuizOption,
      'quizRewardClaimed': _quizRewardClaimed,
      'comicPageIndex': _comicPageIndex,
      'equippedMascotItem': _equippedMascotItem,
      'bottleStickers': _bottleStickers.toList(),
      'handwashSteps': _handwashSteps,
    };
  }

  void _applyJson(Map<String, dynamic> json) {
    _isAuthenticated = json['isAuthenticated'] as bool? ?? _isAuthenticated;
    _isCloudAccount = json['isCloudAccount'] as bool? ?? _isCloudAccount;
    _userUid = json['userUid'] as String? ?? _userUid;
    final name = json['userName'] as String?;
    if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    final childName = json['kidsName'] as String?;
    if (childName != null && childName.trim().isNotEmpty) {
      _kidsName = childName.trim();
    }
    _runtimeAiEndpoint =
        (json['runtimeAiEndpoint'] as String? ?? _runtimeAiEndpoint).trim();
    _runtimeAiModel =
        (json['runtimeAiModel'] as String? ?? _runtimeAiModel).trim();
    _runtimeAiKey =
        (json['runtimeAiKey'] as String? ?? _runtimeAiKey).trim();
    if (_runtimeAiEndpoint.isNotEmpty ||
        _runtimeAiModel.isNotEmpty ||
        _runtimeAiKey.isNotEmpty) {
      _aiClient.updateRuntimeConfig(
        endpoint: _runtimeAiEndpoint.isEmpty ? null : _runtimeAiEndpoint,
        model: _runtimeAiModel.isEmpty ? null : _runtimeAiModel,
        apiKey: _runtimeAiKey.isEmpty ? null : _runtimeAiKey,
      );
    }

    final roleStr = json['role'] as String?;
    if (roleStr != null) {
      for (final r in AquaRole.values) {
        if (r.name == roleStr) {
          _role = r;
          break;
        }
      }
    }

    _bodyWeightKg = (json['bodyWeightKg'] as num?)?.toDouble() ?? _bodyWeightKg;
    final genderStr = json['genderProfile'] as String?;
    if (genderStr != null) {
      for (final g in AquaGenderProfile.values) {
        if (g.name == genderStr) {
          _genderProfile = g;
          break;
        }
      }
    }
    final actStr = json['activityLevel'] as String?;
    if (actStr != null) {
      _activityLevel = AquaActivityLevel.values.firstWhere(
        (a) => a.name == actStr,
        orElse: () => _activityLevel,
      );
    }
    final climStr = json['climateLevel'] as String?;
    if (climStr != null) {
      _climateLevel = AquaClimateLevel.values.firstWhere(
        (cl) => cl.name == climStr,
        orElse: () => _climateLevel,
      );
    }
    final unitStr = json['weightUnit'] as String?;
    if (unitStr != null) {
      _weightUnit = AquaWeightUnit.values.firstWhere(
        (u) => u.name == unitStr,
        orElse: () => _weightUnit,
      );
    }
    _smartRemindersEnabled =
        json['smartRemindersEnabled'] as bool? ?? _smartRemindersEnabled;
    _hasCompletedInitialSetup =
        json['hasCompletedInitialSetup'] as bool? ?? _hasCompletedInitialSetup;
    _selectedShift = json['selectedShift'] as String? ?? _selectedShift;
    _waterSource = json['waterSource'] as String? ?? _waterSource;
    final sourceTypeStr = json['waterSourceType'] as String?;
    if (sourceTypeStr != null) {
      _waterSourceType = AquaWaterSourceType.values.firstWhere(
        (t) => t.name == sourceTypeStr,
        orElse: () => AquaWaterSourceTypeDetails.fromSourceString(_waterSource),
      );
    } else {
      _waterSourceType = AquaWaterSourceTypeDetails.fromSourceString(_waterSource);
    }
    final rawSanitationIds = json['completedSanitationIds'];
    if (rawSanitationIds is List) {
      _completedSanitationIds
        ..clear()
        ..addAll(rawSanitationIds.whereType<String>());
    }
    _activeDateKey = json['activeDateKey'] as String? ?? _activeDateKey;
    _dailyGoalMl = (json['dailyGoalMl'] as int?) ?? _dailyGoalMl;
    _intakeMl = (json['intakeMl'] as int?) ?? _intakeMl;
    _selectedDrink = json['selectedDrink'] as String? ?? _selectedDrink;
    _selectedMascotId =
        json['selectedMascotId'] as String? ?? _selectedMascotId;
    _cupVolumeMl = (json['cupVolumeMl'] as num?)?.toDouble() ?? _cupVolumeMl;
    _caffeineMg = (json['caffeineMg'] as int?) ?? _caffeineMg;
    _plasticSaved = (json['plasticSaved'] as int?) ?? _plasticSaved;
    _morningReminder = json['morningReminder'] as bool? ?? _morningReminder;
    _afternoonReminder =
        json['afternoonReminder'] as bool? ?? _afternoonReminder;
    _eveningReminder = json['eveningReminder'] as bool? ?? _eveningReminder;
    _watchSyncEnabled = json['watchSyncEnabled'] as bool? ?? _watchSyncEnabled;
    _unreadNotifications =
        json['unreadNotifications'] as int? ?? _unreadNotifications;

    final rawHistory = json['dailyHistory'];
    if (rawHistory is Map) {
      rawHistory.forEach((k, v) {
        if (k is String && v is int) {
          _dailyHistory[k] = v;
        }
      });
    }

    final rawLogs = json['drinkLogs'];
    if (rawLogs is List) {
      _drinkLogs
        ..clear()
        ..addAll(
          rawLogs
              .whereType<Map>()
              .map((e) => AquaDrinkLogEntry.fromJson(Map<String, dynamic>.from(e))),
        );
    }

    _tdsPpm = (json['tdsPpm'] as int?) ?? _tdsPpm;
    _phLevel = (json['phLevel'] as num?)?.toDouble() ?? _phLevel;
    final rawRo = json['roFilterHealth'];
    if (rawRo is List && rawRo.length == 4) {
      for (int i = 0; i < 4; i++) {
        _roFilterHealth[i] = (rawRo[i] as num).toInt().clamp(0, 100);
      }
    }
    _selectedTechSlot = (json['selectedTechSlot'] as int?) ?? _selectedTechSlot;
    _tankCleanReminder =
        json['tankCleanReminder'] as bool? ?? _tankCleanReminder;
    _monthlyCubicMeters =
        (json['monthlyCubicMeters'] as num?)?.toDouble() ?? _monthlyCubicMeters;

    final rawTests = json['waterTestRecords'];
    if (rawTests is List) {
      _waterTestRecords
        ..clear()
        ..addAll(
          rawTests.whereType<Map>().map(
                (e) => AquaWaterTestRecord.fromJson(Map<String, dynamic>.from(e)),
              ),
        );
    }

    final rawBookings = json['techBookings'] ?? json['bookings'];
    if (rawBookings is List) {
      _techBookings
        ..clear()
        ..addAll(
          rawBookings.whereType<Map>().map(
                (e) => AquaTechBooking.fromJson(Map<String, dynamic>.from(e)),
              ),
        );
    }

    _kidsCups = (json['kidsCups'] as int?) ?? _kidsCups;
    _kidsGoalCups = (json['kidsGoalCups'] as int?) ?? _kidsGoalCups;
    _kidsStars = (json['kidsStars'] as int?) ?? _kidsStars;
    _kidsQuizIndex = (json['kidsQuizIndex'] as int?) ?? _kidsQuizIndex;
    _kidsSelectedQuizOption =
        (json['kidsSelectedQuizOption'] as int?) ?? _kidsSelectedQuizOption;
    _quizRewardClaimed =
        json['quizRewardClaimed'] as bool? ?? _quizRewardClaimed;
    _comicPageIndex = (json['comicPageIndex'] as int?) ?? _comicPageIndex;
    _equippedMascotItem =
        json['equippedMascotItem'] as String? ?? _equippedMascotItem;

    final rawUnlocked = json['unlockedMascotItems'];
    if (rawUnlocked is List) {
      _unlockedMascotItems
        ..clear()
        ..addAll(rawUnlocked.whereType<String>());
      _unlockedMascotItems.add('Vương miện Giọt Nước');
    }

    final rawStickers = json['bottleStickers'];
    if (rawStickers is List) {
      _bottleStickers
        ..clear()
        ..addAll(rawStickers.whereType<num>().map((e) => e.toInt()));
    }

    _parentPin = json['parentPin'] as String? ?? _parentPin;
    final rawSteps = json['handwashSteps'];
    if (rawSteps is List && rawSteps.length == 6) {
      for (int i = 0; i < 6; i++) {
        _handwashSteps[i] = rawSteps[i] == true;
      }
    }

    _selectedStationId =
        (json['selectedStationId'] as int?) ?? _selectedStationId;
    _stationRating = (json['stationRating'] as int?) ?? _stationRating;
    _communityUpvotes = (json['communityUpvotes'] as int?) ?? _communityUpvotes;

    final rawStations = json['customStations'];
    if (rawStations is List) {
      _customStations
        ..clear()
        ..addAll(
          rawStations.whereType<Map>().map(
                (e) => AquaRefillStation.fromJson(Map<String, dynamic>.from(e)),
              ),
        );
    }

    final rawIncidents = json['incidentReports'];
    if (rawIncidents is List) {
      _incidentReports
        ..clear()
        ..addAll(
          rawIncidents.whereType<Map>().map(
                (e) => AquaIncidentReport.fromJson(Map<String, dynamic>.from(e)),
              ),
        );
    }

    final rawChat = json['chatMessages'];
    if (rawChat is List && rawChat.isNotEmpty) {
      _chatMessages
        ..clear()
        ..addAll(
          rawChat.whereType<Map>().map(
                (e) => AquaBotMessage.fromJson(Map<String, dynamic>.from(e)),
              ),
        );
    }
  }

  Future<void> _persistAndSync() async {
    if (!enablePersistence) return;
    _lastSyncLabel = 'Đã lưu trên máy';
    await _localStorage.saveState(toJson());
    if (_cloudSync.isCloudReady && _isCloudAccount) {
      final ok = await _cloudSync.pushUserState(_userUid, toCloudPayload());
      if (ok) {
        _lastSyncLabel = 'Đã đồng bộ Firebase Cloud';
      }
    }
  }

  // Real app flow actions
  void setStage(AppFlowStage next) {
    if (_stage == next) return;
    _stage = next;
    notifyListeners();
  }

  void completeSplash() {
    if (_isAuthenticated) {
      setStage(AppFlowStage.main);
    } else {
      setStage(AppFlowStage.onboarding);
    }
  }

  void completeOnboarding() => setStage(AppFlowStage.auth);

  void markOnboardingSetupDone() {
    if (_hasCompletedInitialSetup) return;
    _hasCompletedInitialSetup = true;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void completeAuth({
    bool isNewUser = false,
    String? userName,
    String uid = 'local_user',
    bool isCloudAccount = false,
  }) {
    if (userName != null && userName.trim().isNotEmpty) {
      _userName = userName.trim();
    }
    _userUid = uid;
    _isCloudAccount = isCloudAccount;
    _isAuthenticated = true;
    _stage = (isNewUser && !_hasCompletedInitialSetup)
        ? AppFlowStage.setup
        : AppFlowStage.main;
    if (_stage == AppFlowStage.main) {
      _activeTabIndex = 0;
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void completeSetup() {
    _hasCompletedInitialSetup = true;
    _isAuthenticated = true;
    _stage = AppFlowStage.main;
    _activeTabIndex = 0;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setActiveTab(int index) {
    final clamped = index.clamp(0, 4);
    if (_activeTabIndex == clamped) return;
    _activeTabIndex = clamped;
    notifyListeners();
  }

  void signOut() {
    _isAuthenticated = false;
    _isCloudAccount = false;
    _stage = AppFlowStage.auth;
    notifyListeners();
    unawaited(_cloudSync.signOut());
    unawaited(_persistAndSync());
  }

  void markAllNotificationsRead() {
    _unreadNotifications = 0;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  // Interactive mutations
  void setRole(AquaRole newRole) {
    final changed = _role != newRole;
    _role = newRole;
    _activeTabIndex = 0;
    if (newRole == AquaRole.kids) {
      _pinInput = '';
      _parentGateUnlocked = false;
    }
    if (changed && _chatMessages.every((m) => !m.isUser)) {
      _chatMessages
        ..clear()
        ..addAll(_defaultMessagesForRole(newRole));
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  /// Chuyển máy sang chế độ khóa cho Bé AquaKids (ẩn toàn bộ thanh tab người lớn).
  void enterKidsMode() {
    _role = AquaRole.kids;
    _activeTabIndex = 0;
    _pinInput = '';
    _parentGateUnlocked = false;
    if (_chatMessages.every((m) => !m.isUser)) {
      _chatMessages
        ..clear()
        ..addAll(_defaultMessagesForRole(AquaRole.kids));
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setUserName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _userName = trimmed;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setKidsName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _kidsName = trimmed;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void updateProfileInfo({
    String? userName,
    String? kidsName,
    double? bodyWeightKg,
    String? parentPin,
  }) {
    if (userName != null && userName.trim().isNotEmpty) {
      _userName = userName.trim();
    }
    if (kidsName != null && kidsName.trim().isNotEmpty) {
      _kidsName = kidsName.trim();
    }
    if (bodyWeightKg != null) {
      _bodyWeightKg = bodyWeightKg.clamp(35, 130);
      _dailyGoalMl = ((_bodyWeightKg * 33) / 50).round() * 50;
    }
    if (parentPin != null &&
        parentPin.trim().length == 4 &&
        int.tryParse(parentPin.trim()) != null) {
      _parentPin = parentPin.trim();
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void updateAiConfig({
    required String endpoint,
    required String model,
    required String apiKey,
  }) {
    _runtimeAiEndpoint = endpoint.trim();
    _runtimeAiModel = model.trim();
    _runtimeAiKey = apiKey.trim();
    _aiClient.updateRuntimeConfig(
      endpoint: _runtimeAiEndpoint.isEmpty ? null : _runtimeAiEndpoint,
      model: _runtimeAiModel.isEmpty ? null : _runtimeAiModel,
      apiKey: _runtimeAiKey.isEmpty ? null : _runtimeAiKey,
    );
    _aiDiagnosticBanner = null;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void dismissAiDiagnostic() {
    _aiDiagnosticBanner = null;
    notifyListeners();
  }

  void setBodyWeight(double kg) {
    _bodyWeightKg = kg;
    _dailyGoalMl = ((kg * 33) / 50).round() * 50;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setDailyGoalMl(int ml) {
    _dailyGoalMl = ml.clamp(1200, 4500);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setShift(String shift) {
    _selectedShift = shift;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setWaterSource(String source) {
    _waterSource = source;
    _waterSourceType = AquaWaterSourceTypeDetails.fromSourceString(source);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setWaterSourceType(AquaWaterSourceType type) {
    _waterSourceType = type;
    _waterSource = type.fullLabel;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void toggleSanitationTask(String taskId) {
    if (_completedSanitationIds.contains(taskId)) {
      _completedSanitationIds.remove(taskId);
    } else {
      _completedSanitationIds.add(taskId);
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setOtpCode(String value) {
    _otpCode = value;
    notifyListeners();
  }

  void addScannedDrink({
    required int rawMl,
    required String drinkLabel,
    bool addPlasticSaved = false,
  }) {
    final safeMl = rawMl.clamp(50, 3000);
    _intakeMl = (_intakeMl + safeMl).clamp(0, 6000);
    _dailyHistory[_activeDateKey] = _intakeMl;
    if (addPlasticSaved) {
      _plasticSaved += 1;
    }

    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    _drinkLogs.insert(
      0,
      AquaDrinkLogEntry(
        id: 'scan_${DateTime.now().microsecondsSinceEpoch}',
        time: '$hh:$mm',
        drink: drinkLabel,
        ml: safeMl,
        rawMl: safeMl,
      ),
    );
    notifyListeners();
    unawaited(_persistAndSync());
  }

  String applyScannedCodeResult(AquaScannedCodeResult result) {
    switch (result.kind) {
      case AquaScannedKind.roFilterCartridge:
        final slot = (result.filterSlotIndex ?? 0).clamp(0, 3);
        resetRoFilter(slot);
        return 'Đã cập nhật vệ sinh / thay mới bộ lọc cấp ${slot + 1} lên 100%!';
      case AquaScannedKind.mineralOrTdsCheck:
        saveWaterTestRecord(
          tds: result.estimatedTdsPpm,
          ph: result.estimatedPh,
          sourceNote: 'Quét QR cảm biến nước',
        );
        return 'Đã lưu kết quả đo TDS ${result.estimatedTdsPpm ?? _tdsPpm} ppm!';
      case AquaScannedKind.refillStation:
        final stationLabel = result.stationName ?? result.title;
        addScannedDrink(
          rawMl: result.recommendedMl,
          drinkLabel: 'Refill • $stationLabel',
          addPlasticSaved: true,
        );
        return 'Đã Refill +${result.recommendedMl} ml tại $stationLabel (+1 chai nhựa tiết kiệm 🌱)';
      case AquaScannedKind.waterBottle:
        final name = result.brand.isNotEmpty ? result.brand : result.title;
        addScannedDrink(
          rawMl: result.recommendedMl,
          drinkLabel: name,
        );
        final nearest = selectedStation;
        return 'Đã ghi nhận +${result.recommendedMl} ml ($name). Mẹo SDG 6: Lần tới hãy Refill bình cá nhân tại ${nearest.name} (${distanceToStation(nearest)}m) để giảm chai nhựa dùng 1 lần 🌱';
      case AquaScannedKind.genericText:
        addScannedDrink(
          rawMl: result.recommendedMl,
          drinkLabel: 'Đồ uống (${result.rawCode})',
        );
        return 'Đã ghi nhận +${result.recommendedMl} ml từ mã vừa quét!';
    }
  }

  void addWater(int rawMl) {
    final spec = AquaBeverageSpec.of(_selectedDrink);
    final effectiveMl = spec.computeEffectiveMl(rawMl);
    final caffeineDelta = spec.computeCaffeineMg(rawMl);
    _intakeMl = (_intakeMl + effectiveMl).clamp(0, 6000);
    _dailyHistory[_activeDateKey] = _intakeMl;
    if (caffeineDelta > 0) {
      _caffeineMg = (_caffeineMg + caffeineDelta).clamp(0, 800);
    }

    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final entryId = 'log_${DateTime.now().microsecondsSinceEpoch}';
    _drinkLogs.insert(
      0,
      AquaDrinkLogEntry(
        id: entryId,
        time: '$hh:$mm',
        drink: _selectedDrink,
        ml: effectiveMl,
        rawMl: rawMl,
        caffeineMg: caffeineDelta,
      ),
    );
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void removeDrinkLogAt(int index) {
    if (index < 0 || index >= _drinkLogs.length) return;
    final removed = _drinkLogs.removeAt(index);
    _intakeMl = (_intakeMl - removed.ml).clamp(0, 6000);
    _caffeineMg = (_caffeineMg - removed.caffeineMg).clamp(0, 800);
    _dailyHistory[_activeDateKey] = _intakeMl;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void removeDrinkLog(String id) {
    final idx = _drinkLogs.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      removeDrinkLogAt(idx);
    }
  }

  void selectDrink(String drink) {
    _selectedDrink = drink;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void selectMascot(String id) {
    if (id.trim().isEmpty || _selectedMascotId == id) return;
    _selectedMascotId = id;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void pickRandomMascot(List<String> unlockedIds) {
    final pool = unlockedIds.where((id) => id != _selectedMascotId).toList();
    if (pool.isEmpty) return;
    final idx = DateTime.now().microsecondsSinceEpoch % pool.length;
    selectMascot(pool[idx]);
  }

  void setCupVolume(double ml) {
    _cupVolumeMl = ml;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void addCaffeine(int mg) {
    _caffeineMg = (_caffeineMg + mg).clamp(0, 800);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void checkInReusableBottle() {
    _plasticSaved += 1;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  Future<void> enableSmartReminders() async {
    _smartRemindersEnabled = true;
    _morningReminder = true;
    _afternoonReminder = true;
    notifyListeners();
    unawaited(
      AquaNotificationService.instance.syncReminderSchedule(
        morning: _morningReminder,
        afternoon: _afternoonReminder,
        evening: _eveningReminder,
      ),
    );
    unawaited(_persistAndSync());
  }

  void updateHydrationProfile({
    AquaGenderProfile? gender,
    double? bodyWeightKg,
    AquaActivityLevel? activity,
    AquaClimateLevel? climate,
    AquaWeightUnit? weightUnit,
    int? customGoalMl,
    bool recalculateGoal = true,
  }) {
    if (gender != null) _genderProfile = gender;
    if (bodyWeightKg != null) {
      _bodyWeightKg = bodyWeightKg.clamp(30.0, 160.0);
    }
    if (activity != null) _activityLevel = activity;
    if (climate != null) _climateLevel = climate;
    if (weightUnit != null) _weightUnit = weightUnit;
    if (customGoalMl != null) {
      _dailyGoalMl = customGoalMl.clamp(1200, 4800);
    } else if (recalculateGoal) {
      _dailyGoalMl = recommendedGoalMl;
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void toggleReminder(int slot, bool value) {
    if (slot == 0) _morningReminder = value;
    if (slot == 1) _afternoonReminder = value;
    if (slot == 2) _eveningReminder = value;
    notifyListeners();
    unawaited(
      AquaNotificationService.instance.syncReminderSchedule(
        morning: _morningReminder,
        afternoon: _afternoonReminder,
        evening: _eveningReminder,
      ),
    );
    unawaited(_persistAndSync());
  }

  Future<void> sendTestNotification() async {
    await AquaNotificationService.instance.showInstantNotification(
      title: '💧 AquaCare Nhắc uống nước',
      body:
          'Bạn đã uống $_intakeMl/$_dailyGoalMl ml hôm nay. Uống thêm 1 cốc 250 ml ngay nhé!',
    );
  }

  void toggleWatchSync(bool value) {
    _watchSyncEnabled = value;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void togglePomodoro() {
    if (_pomodoroRunning) {
      _pomodoroTimer?.cancel();
      _pomodoroRunning = false;
      notifyListeners();
      return;
    }
    _pomodoroRunning = true;
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_pomodoroSeconds > 0) {
        _pomodoroSeconds--;
      } else {
        _pomodoroTimer?.cancel();
        _pomodoroRunning = false;
        unawaited(
          AquaNotificationService.instance.showInstantNotification(
            title: '⏱ Hoàn thành phiên Pomodoro 25 phút!',
            body: 'Hãy đứng dậy thư giãn và uống 150 ml nước lọc nhé.',
            id: 101,
          ),
        );
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void resetPomodoro() {
    _pomodoroTimer?.cancel();
    _pomodoroRunning = false;
    _pomodoroSeconds = 25 * 60;
    notifyListeners();
  }

  void selectStation(int id) {
    _selectedStationId = id;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void toggleStationFilter({
    bool? freeOnly,
    bool? hotCold,
    bool? open24h,
    bool? sanitationOnly,
  }) {
    if (freeOnly != null) _filterFreeOnly = freeOnly;
    if (hotCold != null) _filterHotCold = hotCold;
    if (open24h != null) _filterOpen24h = open24h;
    if (sanitationOnly != null) _filterSanitationOnly = sanitationOnly;
    notifyListeners();
  }

  void setSearchRadius(double km) {
    _searchRadiusKm = km;
    notifyListeners();
  }

  void setStationRating(int rating) {
    _stationRating = rating;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setIncidentSeverity(int severity) {
    _incidentSeverity = severity;
    notifyListeners();
  }

  void upvoteIncident() {
    _communityUpvotes += 1;
    if (_incidentReports.isNotEmpty) {
      final first = _incidentReports.first;
      _incidentReports[0] = first.copyWith(upvotes: first.upvotes + 1);
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void upvoteIncidentItem(String id) {
    final idx = _incidentReports.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    _incidentReports[idx] = _incidentReports[idx].copyWith(
      upvotes: _incidentReports[idx].upvotes + 1,
    );
    if (idx == 0) _communityUpvotes = _incidentReports[idx].upvotes;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void proposeStation({
    required String name,
    required int tdsPpm,
    bool isFree = true,
    bool hasHotCold = false,
    bool isOpen24h = false,
    bool hasHandwashSanitation = false,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final nextId = 100 + _customStations.length + 1;
    final shift = (_customStations.length + 1) * 0.0009;
    final created = AquaRefillStation(
      id: nextId,
      name: cleanName,
      distanceMeters: 180 + _customStations.length * 90,
      tdsPpm: tdsPpm.clamp(5, 300),
      isFree: isFree,
      hasHotCold: hasHotCold,
      isOpen24h: isOpen24h,
      xFactor: (0.46 + (_customStations.length * 0.11)) % 0.8 + 0.1,
      yFactor: (0.38 + (_customStations.length * 0.13)) % 0.6 + 0.15,
      latitude: _userLat + shift,
      longitude: _userLng + shift * 1.2,
      isUserProposed: true,
      hasHandwashSanitation: hasHandwashSanitation,
    );
    _customStations.insert(0, created);
    _selectedStationId = created.id;
    notifyListeners();
    unawaited(_cloudSync.pushCommunityStation(created));
    unawaited(_persistAndSync());
  }

  void submitIncidentReport({
    required String description,
    required int severity,
    String? stationName,
  }) {
    final cleanDesc = description.trim().isEmpty
        ? 'Sự cố nguồn nước khu vực ${selectedStation.name}'
        : description.trim();
    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final report = AquaIncidentReport(
      id: 'inc_${DateTime.now().microsecondsSinceEpoch}',
      title: cleanDesc,
      severity: severity.clamp(0, 2),
      stationName: stationName ?? selectedStation.name,
      createdAtLabel: 'Hôm nay • $hh:$mm',
      status: 'Đã tiếp nhận',
      upvotes: 1,
    );
    _incidentSeverity = severity.clamp(0, 2);
    _incidentReports.insert(0, report);
    notifyListeners();
    unawaited(_cloudSync.pushIncidentReport(report));
    unawaited(_persistAndSync());
  }

  Future<void> refreshGpsLocation() async {
    _isLocatingGps = true;
    notifyListeners();

    final hw = AquaHardwareService.instance;
    final snap = await hw.getCurrentCoordinates();
    _userLat = snap.latitude;
    _userLng = snap.longitude;
    _gpsStatusLabel = snap.statusMessage;
    _gpsFixRevision++;
    notifyListeners();

    if (snap.isLiveGps) {
      final results = await Future.wait<dynamic>([
        hw.reverseGeocodeAddress(snap.latitude, snap.longitude),
        hw.fetchNearbyWaterPoints(snap.latitude, snap.longitude),
        hw.fetchLiveWeatherSummary(snap.latitude, snap.longitude),
      ]);
      final address = results[0] as String?;
      final nearby = results[1] as List<AquaRefillStation>;
      final weather = results[2] as String?;

      if (address != null && address.isNotEmpty) {
        _gpsStatusLabel = 'GPS trực tiếp • $address';
      }
      if (weather != null && weather.isNotEmpty) {
        _weatherLabel = weather;
      }
      if (nearby.isNotEmpty) {
        _nearbyDynamicStations
          ..clear()
          ..addAll(nearby);
        _selectedStationId = nearby.first.id;
      }
      _gpsFixRevision++;
    }

    _isLocatingGps = false;
    notifyListeners();
  }

  int distanceToStation(AquaRefillStation st) {
    if ((_userLat - AquaHardwareService.defaultLat).abs() < 0.0002 &&
        (_userLng - AquaHardwareService.defaultLng).abs() < 0.0002) {
      return st.distanceMeters;
    }
    return AquaHardwareService.instance.distanceMetersBetween(
      _userLat,
      _userLng,
      st.latitude,
      st.longitude,
    );
  }

  void setWaterMetrics({int? tds, double? ph}) {
    if (tds != null) _tdsPpm = tds;
    if (ph != null) _phLevel = ph;
    notifyListeners();
  }

  void saveWaterTestRecord({
    int? tds,
    double? ph,
    String sourceNote = 'Đo bằng bút TDS / Quét QR',
  }) {
    if (tds != null) _tdsPpm = tds;
    if (ph != null) _phLevel = ph;
    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    _waterTestRecords.insert(
      0,
      AquaWaterTestRecord(
        id: 'wt_${DateTime.now().microsecondsSinceEpoch}',
        dateLabel: 'Hôm nay • $hh:$mm',
        tdsPpm: _tdsPpm,
        phLevel: _phLevel,
        sourceNote: sourceNote,
      ),
    );
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void deleteWaterTestRecord(String id) {
    _waterTestRecords.removeWhere((r) => r.id == id);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void resetRoFilter(int index) {
    if (index >= 0 && index < _roFilterHealth.length) {
      _roFilterHealth[index] = 100;
      notifyListeners();
      unawaited(_persistAndSync());
    }
  }

  void setSelectedTechSlot(int slot) {
    _selectedTechSlot = slot;
    notifyListeners();
  }

  void addTechBooking(String slotLabel) {
    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    _techBookings.insert(
      0,
      AquaTechBooking(
        id: 'bk_${DateTime.now().microsecondsSinceEpoch}',
        slotLabel: slotLabel,
        createdAtLabel: 'Đặt lúc $hh:$mm hôm nay',
      ),
    );
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void completeTechBooking(String id) {
    final idx = _techBookings.indexWhere((b) => b.id == id);
    if (idx < 0) return;
    _techBookings[idx] = _techBookings[idx].copyWith(completed: true);
    int lowestIdx = 0;
    for (int i = 1; i < _roFilterHealth.length; i++) {
      if (_roFilterHealth[i] < _roFilterHealth[lowestIdx]) {
        lowestIdx = i;
      }
    }
    _roFilterHealth[lowestIdx] = 100;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void updateMonthlyWaterMeter(double cubicMeters) {
    _monthlyCubicMeters = cubicMeters.clamp(0.0, 80.0);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void toggleTankCleanReminder(bool val) {
    _tankCleanReminder = val;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void feedKidsMascot() {
    if (_kidsCups < _kidsGoalCups) {
      _kidsCups += 1;
    } else {
      _kidsCups = 1;
    }
    _kidsStars += 10;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void selectQuizOption(int option) {
    final correct = currentQuizQuestion.correctIndex;
    if (!_quizRewardClaimed && option == correct) {
      _quizRewardClaimed = true;
      _kidsStars += 20;
    }
    _kidsSelectedQuizOption = option;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void nextQuizQuestion() {
    _kidsQuizIndex = (_kidsQuizIndex + 1) % AquaKidsQuizQuestion.bank.length;
    _kidsSelectedQuizOption = -1;
    _quizRewardClaimed = false;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setComicPage(int page) {
    _comicPageIndex = page.clamp(0, 3);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void equipMascotItem(String item, int cost) {
    final alreadyUnlocked = _unlockedMascotItems.contains(item);
    if (alreadyUnlocked) {
      _equippedMascotItem = item;
      notifyListeners();
      unawaited(_persistAndSync());
      return;
    }
    if (_kidsStars >= cost) {
      _kidsStars -= cost;
      _unlockedMascotItems.add(item);
      _equippedMascotItem = item;
      notifyListeners();
      unawaited(_persistAndSync());
    }
  }

  void toggleBottleSticker(int id) {
    if (_bottleStickers.contains(id)) {
      _bottleStickers.remove(id);
    } else {
      _bottleStickers.add(id);
    }
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void setKidsGoalCups(int cups) {
    _kidsGoalCups = cups.clamp(4, 10);
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void updateParentPin(String newPin) {
    final clean = newPin.trim();
    if (clean.length == 4 && int.tryParse(clean) != null) {
      _parentPin = clean;
      notifyListeners();
      unawaited(_persistAndSync());
    }
  }

  void appendPinDigit(String digit, {String? expectedChallengeAnswer}) {
    if (_pinInput.length < 4) {
      _pinInput += digit;
      final matchesChallenge = expectedChallengeAnswer != null &&
          expectedChallengeAnswer.isNotEmpty &&
          _pinInput == expectedChallengeAnswer;
      if (matchesChallenge || _pinInput == _parentPin) {
        _parentGateUnlocked = true;
      }
      notifyListeners();
    }
  }

  void clearPin() {
    _pinInput = '';
    _parentGateUnlocked = false;
    notifyListeners();
  }

  void toggleBrushTimer() {
    if (_brushRunning) {
      _brushTimer?.cancel();
      _brushRunning = false;
      notifyListeners();
      return;
    }
    _brushRunning = true;
    _brushTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_brushSecondsLeft > 0) {
        _brushSecondsLeft--;
      } else {
        _brushTimer?.cancel();
        _brushRunning = false;
        _kidsStars += 15;
        unawaited(_persistAndSync());
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void resetBrushTimer() {
    _brushTimer?.cancel();
    _brushRunning = false;
    _brushSecondsLeft = 120;
    notifyListeners();
  }

  void toggleHandwashStep(int index) {
    if (index >= 0 && index < _handwashSteps.length) {
      _handwashSteps[index] = !_handwashSteps[index];
      notifyListeners();
      unawaited(_persistAndSync());
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> sendBotMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _chatMessages.add(AquaBotMessage(isUser: true, text: trimmed));
    _isBotTyping = _aiClient.isCustomApiConfigured;
    notifyListeners();

    final snapshot = AquaBotContextSnapshot(
      userName: _userName,
      roleLabel: _role.label,
      role: _role,
      intakeMl: _intakeMl,
      dailyGoalMl: _dailyGoalMl,
      caffeineMg: _caffeineMg,
      streakDays: streakDays,
      tdsPpm: _tdsPpm,
      phLevel: _phLevel,
      roFilterHealth: _roFilterHealth,
      kidsCups: _kidsCups,
      kidsGoalCups: _kidsGoalCups,
      kidsStars: _kidsStars,
      selectedStationName: selectedStation.name,
      waterSource: _waterSource,
    );

    final result = await _aiClient.generateStructuredReply(
      userMessage: trimmed,
      history: _chatMessages,
      snapshot: snapshot,
    );
    _chatMessages.add(AquaBotMessage(isUser: false, text: result.text));
    _aiDiagnosticBanner = result.diagnosticStatus;
    _isBotTyping = false;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  void clearBotChat() {
    _chatMessages
      ..clear()
      ..addAll(_defaultMessagesForRole(_role));
    _aiDiagnosticBanner = null;
    notifyListeners();
    unawaited(_persistAndSync());
  }

  Future<bool> triggerManualCloudSync() async {
    _isSyncing = true;
    notifyListeners();
    await _localStorage.saveState(toJson());
    await _cloudSync.initializeIfConfigured();
    bool pushed = false;
    if (_cloudSync.isCloudReady) {
      pushed = await _cloudSync.pushUserState(_userUid, toCloudPayload());
      _lastSyncLabel = pushed
          ? 'Đã đồng bộ Firebase Cloud'
          : 'Đã lưu máy (chưa đăng nhập Cloud)';
    } else {
      _lastSyncLabel = 'Đã lưu an toàn trên thiết bị (Chế độ ngoại tuyến)';
    }
    _isSyncing = false;
    notifyListeners();
    return pushed;
  }

  String buildWeeklyShareReport() {
    final buffer = StringBuffer()
      ..writeln('💧 BÁO CÁO AQUACARE – NƯỚC SẠCH & SỨC KHỎE (SDG 6)')
      ..writeln('• Người dùng: $_userName (${_role.label})')
      ..writeln('• Hôm nay: $_intakeMl / $_dailyGoalMl ml ($intakePercent%)')
      ..writeln(
        '• Chuỗi duy trì: $streakDays ngày • Trung bình 7 ngày: $weeklyAverageMl ml/ngày',
      )
      ..writeln('• Nhựa tiết kiệm: $_plasticSaved chai nhựa tái sử dụng 🌱');

    if (_role == AquaRole.household) {
      final formattedBill = AquaWaterBillEntry.formatVnd(currentWaterBillVnd);
      final washPct = (householdSanitationProgress * 100).round();
      buffer
        ..writeln(
          '• Nguồn nước (${_waterSourceType.label}): TDS $_tdsPpm ppm | pH ${_phLevel.toStringAsFixed(1)} | ${waterSafetyAssessment.headline}',
        )
        ..writeln(
          '• Vệ sinh WASH gia đình: $washPct% | Lượng nước tháng: ${_monthlyCubicMeters.toStringAsFixed(0)} m³ ($formattedBill)',
        )
        ..writeln(
          '• Bé AquaKids: $_kidsCups/$_kidsGoalCups cốc | $_kidsStars Sao Vàng ⭐',
        );
    }

    buffer.write('Cùng bảo vệ nguồn nước sạch với AquaCare!');
    return buffer.toString();
  }

  Future<void> resetAllUserData() async {
    _intakeMl = 1500;
    _dailyGoalMl = 2100;
    _bodyWeightKg = 62;
    _genderProfile = null;
    _activityLevel = AquaActivityLevel.moderate;
    _climateLevel = AquaClimateLevel.temperate;
    _weightUnit = AquaWeightUnit.kg;
    _smartRemindersEnabled = true;
    _hasCompletedInitialSetup = false;
    _caffeineMg = 95;
    _plasticSaved = 14;
    _waterSource = 'Máy lọc RO gia đình';
    _waterSourceType = AquaWaterSourceType.roPurified;
    _tdsPpm = 36;
    _phLevel = 7.3;
    _roFilterHealth
      ..clear()
      ..addAll([15, 78, 82, 90]);
    _completedSanitationIds
      ..clear()
      ..addAll(const ['hh_handwash', 'st_refill']);
    _filterSanitationOnly = false;
    _monthlyCubicMeters = 14.0;
    _kidsCups = 5;
    _kidsGoalCups = 6;
    _kidsStars = 120;
    _kidsQuizIndex = 0;
    _kidsSelectedQuizOption = -1;
    _quizRewardClaimed = false;
    _equippedMascotItem = 'Vương miện Giọt Nước';
    _unlockedMascotItems
      ..clear()
      ..add('Vương miện Giọt Nước');
    _parentPin = '1234';
    _unreadNotifications = 3;
    _customStations.clear();
    _seedDefaultsForDate(DateTime.now());
    notifyListeners();
    await _localStorage.clearState();
    await _persistAndSync();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _brushTimer?.cancel();
    super.dispose();
  }
}
