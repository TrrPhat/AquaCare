import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// ============================================================================
/// CẤU HÌNH FIREBASE CHÍNH THỨC CHO AQUACARE (Project: aquacare-24)
/// ============================================================================
///
/// Đã kết nối tự động với cả 3 ứng dụng trên Firebase Project `aquacare-24`:
/// - Web / PWA: 1:68874362987:web:90cb72a5546fe36a40512e
/// - Android  : 1:68874362987:android:9a5538fb3f26704940512e (android/app/google-services.json)
/// - iOS      : 1:68874362987:ios:cfc08fcf7e207ef240512e (ios/Runner/GoogleService-Info.plist)
class AquaFirebaseOptions {
  AquaFirebaseOptions._();

  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'aquacare-24',
  );
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '68874362987',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'aquacare-24.firebasestorage.app',
  );

  // Cấu hình Web / Windows / iPhone Safari PWA
  static const String webApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
    defaultValue: 'AIzaSyDh6K3jjKdmQ1KOXqZCwDKX6dvfJPNedak',
  );
  static const String webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: '1:68874362987:web:90cb72a5546fe36a40512e',
  );
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'aquacare-24.firebaseapp.com',
  );

  // Cấu hình Android (com.example.aquacare)
  static const String androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
    defaultValue: 'AIzaSyAd0NFCtdfbuTjYZH59hdiKZ77PxVTAL8s',
  );
  static const String androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:68874362987:android:9a5538fb3f26704940512e',
  );

  // Cấu hình iOS (com.example.aquacare)
  static const String iosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
    defaultValue: 'AIzaSyD2IviCiub3IllafbG6_NhNcJD5zCFxjEU',
  );
  static const String iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:68874362987:ios:cfc08fcf7e207ef240512e',
  );
  static const String iosBundleId = 'com.example.aquacare';

  /// Trả về true khi khóa Firebase hợp lệ cho nền tảng hiện tại.
  static bool get isConfigured {
    if (projectId.trim().isEmpty || messagingSenderId.trim().isEmpty) {
      return false;
    }
    if (kIsWeb) {
      return webApiKey.trim().isNotEmpty && webAppId.trim().isNotEmpty;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidApiKey.trim().isNotEmpty &&
            androidAppId.trim().isNotEmpty;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosApiKey.trim().isNotEmpty && iosAppId.trim().isNotEmpty;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return webApiKey.trim().isNotEmpty && webAppId.trim().isNotEmpty;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: webApiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isNotEmpty
            ? authDomain
            : '$projectId.firebaseapp.com',
        storageBucket: storageBucket.isNotEmpty
            ? storageBucket
            : '$projectId.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: androidApiKey,
          appId: androidAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket.isNotEmpty
              ? storageBucket
              : '$projectId.firebasestorage.app',
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: iosApiKey,
          appId: iosAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: storageBucket.isNotEmpty
              ? storageBucket
              : '$projectId.firebasestorage.app',
          iosBundleId: iosBundleId,
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return FirebaseOptions(
          apiKey: webApiKey,
          appId: webAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          authDomain: authDomain.isNotEmpty
              ? authDomain
              : '$projectId.firebaseapp.com',
          storageBucket: storageBucket.isNotEmpty
              ? storageBucket
              : '$projectId.firebasestorage.app',
        );
    }
  }
}
