import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Background message handler – must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by main() before this is called.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Singleton service that wires up Firebase Cloud Messaging for the app.
///
/// Call [FcmService.init] once in `main()` after Firebase.initializeApp().
/// Call [FcmService.saveTokenForUser] whenever the signed-in user changes.
class FcmService {
  FcmService._();
  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialise FCM: request permission, register background handler,
  /// and start listening for foreground messages.
  Future<void> init() async {
    // Register the top-level background handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permission (Android 13+ / iOS).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages by writing them to the Firestore inbox.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle tap on a notification when the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);

    // Check if app was launched from a terminated-state notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationTapped(initialMessage);
    }
  }

  /// Persist the FCM token for [uid] in:
  ///   • `users/{uid}`  (passengers)
  ///   • `operators/{uid}`  (operators)
  ///
  /// Pass [role] as `'operator'` or `'passenger'` so only the relevant
  /// collection is updated.
  Future<void> saveTokenForUser(String uid, {String role = 'passenger'}) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || uid.isEmpty) return;

      final data = {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'operator') {
        await _db.collection('operators').doc(uid).set(data, SetOptions(merge: true));
      } else {
        await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      }

      // Refresh token whenever it rotates.
      _messaging.onTokenRefresh.listen((newToken) async {
        final updated = {'fcmToken': newToken, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()};
        if (role == 'operator') {
          await _db.collection('operators').doc(uid).set(updated, SetOptions(merge: true));
        } else {
          await _db.collection('users').doc(uid).set(updated, SetOptions(merge: true));
        }
      });
    } catch (e) {
      debugPrint('[FCM] saveTokenForUser error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Write a foreground RemoteMessage to the Firestore notification inbox
  /// so the existing [NotificationTab] widget picks it up automatically.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    final uid = message.data['targetUserId'] as String?;
    if (uid == null || uid.isEmpty) return;
    await _writeToInbox(uid, message);
  }

  Future<void> _onNotificationTapped(RemoteMessage message) async {
    debugPrint('[FCM] Tapped: ${message.notification?.title}');
    // Additional deep-link navigation can be added here in the future.
  }

  /// Writes a push notification to `notifications/{uid}/items` so the
  /// existing [NotificationTab] stream shows it instantly.
  Future<void> _writeToInbox(String uid, RemoteMessage message) async {
    try {
      await _db
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .add({
        'title': message.notification?.title ?? 'Notification',
        'body': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'alert',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': message.data,
      });
    } catch (e) {
      debugPrint('[FCM] _writeToInbox error: $e');
    }
  }
}
