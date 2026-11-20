import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../widgets/animations/aqua_motion.dart';

/// Cross-platform local hydration reminder & alert notification service (`2B`).
class AquaNotificationService {
  AquaNotificationService._();

  static final AquaNotificationService instance = AquaNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || AquaMotion.isTestEnvironment || kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Mở AquaCare',
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'AquaCare',
        appUserModelId: 'vn.sdg6.aquacare.desktop',
        guid: '4d946f6a-81be-45e6-912c-8425e1e48d11',
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );

      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      // Never block app startup on unsupported desktops or missing permissions.
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 100,
  }) async {
    if (AquaMotion.isTestEnvironment || kIsWeb) return;
    await initialize();
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'aquacare_hydration_channel',
          'Nhắc uống nước & Cảnh báo RO',
          channelDescription:
              'Nhắc lịch cấp ẩm theo ca và cảnh báo thay lõi lọc RO',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      // Safe fallback when OS blocks system toast.
    }
  }

  Future<void> syncReminderSchedule({
    required bool morning,
    required bool afternoon,
    required bool evening,
  }) async {
    if (AquaMotion.isTestEnvironment || kIsWeb) return;
    await initialize();
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'aquacare_daily_reminders',
          'Lịch nhắc uống nước theo ca',
          channelDescription: 'Thông báo định kỳ giữ đủ nước mỗi ngày',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      );

      if (morning || afternoon || evening) {
        await _plugin.periodicallyShow(
          id: 201,
          title: '💧 Đến giờ uống nước cùng AquaCare!',
          body:
              'Hãy uống thêm 200–250 ml nước sạch để giữ năng lượng và sự tập trung.',
          repeatInterval: RepeatInterval.hourly,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        await _plugin.cancel(id: 201);
      }
    } catch (_) {
      // Keep UI state smooth if OS rejects alarm scheduling.
    }
  }
}
