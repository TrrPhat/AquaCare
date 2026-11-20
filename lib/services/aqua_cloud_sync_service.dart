import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../firebase_options.dart';
import '../models/aqua_models.dart';
import '../widgets/animations/aqua_motion.dart';

class AquaAuthResult {
  const AquaAuthResult({
    required this.success,
    required this.isCloudAccount,
    this.uid = 'local_user',
    this.displayName,
    this.errorMessage,
  });

  final bool success;
  final bool isCloudAccount;
  final String uid;
  final String? displayName;
  final String? errorMessage;
}

/// Fault-tolerant Firebase Auth + Cloud Firestore synchronization service (`1C`).
///
/// Automatically activates Cloud Sync when valid keys are configured in
/// `lib/firebase_options.dart`; seamlessly operates in Offline-First mode otherwise.
class AquaCloudSyncService {
  AquaCloudSyncService();

  bool _initialized = false;

  bool get isConfigured => AquaFirebaseOptions.isConfigured;

  bool get isCloudReady =>
      !AquaMotion.isTestEnvironment && isConfigured && _initialized;

  String? get currentCloudUid {
    if (!isCloudReady) return null;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<bool> initializeIfConfigured() async {
    if (AquaMotion.isTestEnvironment || !isConfigured) {
      return false;
    }
    if (_initialized) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: AquaFirebaseOptions.currentPlatform,
        );
      }
      _initialized = true;
      return true;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  Future<AquaAuthResult> signInWithEmail({
    required String email,
    required String password,
    String? fallbackName,
  }) async {
    await initializeIfConfigured();
    if (!isCloudReady) {
      return AquaAuthResult(
        success: true,
        isCloudAccount: false,
        uid: 'local_${email.trim().hashCode.abs()}',
        displayName: fallbackName,
      );
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AquaAuthResult(
        success: true,
        isCloudAccount: true,
        uid: cred.user?.uid ?? 'local_user',
        displayName: cred.user?.displayName ?? fallbackName,
      );
    } on FirebaseAuthException catch (e) {
      return AquaAuthResult(
        success: false,
        isCloudAccount: true,
        errorMessage: _vietnameseAuthError(e),
      );
    } catch (e) {
      return AquaAuthResult(
        success: false,
        isCloudAccount: true,
        errorMessage: 'Không thể đăng nhập Firebase lúc này ($e).',
      );
    }
  }

  Future<AquaAuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await initializeIfConfigured();
    if (!isCloudReady) {
      return AquaAuthResult(
        success: true,
        isCloudAccount: false,
        uid: 'local_${email.trim().hashCode.abs()}',
        displayName: displayName.trim(),
      );
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName.trim().isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      return AquaAuthResult(
        success: true,
        isCloudAccount: true,
        uid: cred.user?.uid ?? 'local_user',
        displayName: displayName.trim(),
      );
    } on FirebaseAuthException catch (e) {
      return AquaAuthResult(
        success: false,
        isCloudAccount: true,
        errorMessage: _vietnameseAuthError(e),
      );
    } catch (e) {
      return AquaAuthResult(
        success: false,
        isCloudAccount: true,
        errorMessage: 'Không thể tạo tài khoản Firebase lúc này ($e).',
      );
    }
  }

  Future<AquaAuthResult> signInWithGoogle({String? fallbackName}) async {
    await initializeIfConfigured();
    if (!isCloudReady) {
      return AquaAuthResult(
        success: true,
        isCloudAccount: false,
        uid: 'local_google',
        displayName: fallbackName,
      );
    }

    try {
      final provider = GoogleAuthProvider();
      final cred = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);
      return AquaAuthResult(
        success: true,
        isCloudAccount: true,
        uid: cred.user?.uid ?? 'local_google',
        displayName: cred.user?.displayName ?? fallbackName,
      );
    } on FirebaseAuthException catch (e) {
      return AquaAuthResult(
        success: false,
        isCloudAccount: true,
        errorMessage: _vietnameseAuthError(e),
      );
    } catch (e) {
      return AquaAuthResult(
        success: false,
        isCloudAccount: true,
        errorMessage: 'Đăng nhập Google chưa hoàn tất ($e).',
      );
    }
  }

  Future<void> signOut() async {
    if (!isCloudReady) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Safe fallback.
    }
  }

  Future<bool> pushUserState(String uid, Map<String, dynamic> payload) async {
    if (!isCloudReady) return false;
    final authUid = currentCloudUid ?? uid;
    if (authUid.startsWith('local_')) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(authUid).set(
        {
          ...payload,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> pullUserState(String uid) async {
    if (!isCloudReady) return null;
    final authUid = currentCloudUid ?? uid;
    if (authUid.startsWith('local_')) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUid)
          .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> pushCommunityStation(AquaRefillStation station) async {
    if (!isCloudReady) return;
    final uid = currentCloudUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('community_stations')
          .doc('station_${station.id}')
          .set({
        'createdBy': uid,
        'id': station.id,
        'name': station.name,
        'tdsPpm': station.tdsPpm,
        'latitude': station.latitude,
        'longitude': station.longitude,
        'isFree': station.isFree,
        'hasHotCold': station.hasHotCold,
        'isOpen24h': station.isOpen24h,
        'distanceMeters': station.distanceMeters,
        'xFactor': station.xFactor,
        'yFactor': station.yFactor,
        if (station.hasHandwashSanitation)
          'notes': 'Có điểm rửa tay / vệ sinh sạch',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Kept locally in Offline-First storage.
    }
  }

  Future<void> pushIncidentReport(AquaIncidentReport report) async {
    if (!isCloudReady) return;
    final uid = currentCloudUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(report.id)
          .set({
        'createdBy': uid,
        'title': report.title,
        'severity': report.severity,
        'stationName': report.stationName,
        'upvotes': report.upvotes,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Kept locally in Offline-First storage.
    }
  }

  String _vietnameseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Địa chỉ Email chưa đúng định dạng.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu chưa chính xác.';
      case 'wrong-password':
        return 'Mật khẩu chưa chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký trước đó.';
      case 'weak-password':
        return 'Mật khẩu cần tối thiểu 6 ký tự.';
      case 'unauthorized-domain':
        return 'Domain chưa được cấp quyền trong Firebase Auth.';
      default:
        return e.message ?? 'Lỗi xác thực Firebase (${e.code}).';
    }
  }
}
