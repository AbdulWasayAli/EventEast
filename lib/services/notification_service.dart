import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important announcements and updates.',
    importance: Importance.max,
  );
  static Future<void> initializeNotifications() async {
    try {
      await _initializeLocalNotifications();
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await saveDeviceToken();
        _messaging.onTokenRefresh.listen((newToken) async {
          await saveDeviceToken(token: newToken);
        });
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('FCM DEBUG: Got a message whilst in the foreground!');
          print('FCM DEBUG: Message data: ${message.data}');
          _showForegroundNotification(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('FCM DEBUG: App opened from notification: ${message.messageId}');
        });
      }
    } catch (e) {
      print('FCM DEBUG ERROR (initializeNotifications): $e');
    }
  }
  static Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, 
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'];
    final body = notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
  static Future<void> saveDeviceToken({String? token}) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('FCM DEBUG: User is null, cannot save token');
      return;
    }

    try {
      final fcmToken = token ?? await _messaging.getToken();
      print('FCM DEBUG: Retrieved token = $fcmToken for User = ${user.uid}');
      if (fcmToken != null) {
        await _firestore.collection('Users').doc(user.uid).set({
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCM DEBUG: Successfully saved token to Firestore!');
      }
    } catch (e) {
      print('FCM DEBUG ERROR: $e');
    }
  }
  static Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String message,
    String? eventId,
    String? type,
  }) async {
    try {
      if (!await isPushNotificationsEnabled(recipientUserId)) {
        return;
      }

      final docRef = _firestore.collection('notifications').doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: recipientUserId,
        eventId: eventId,
        title: title,
        message: message,
        type: type ?? 'general',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(notification.toMap());
      final userDoc = await _firestore.collection('Users').doc(recipientUserId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
        final fcmToken = userDoc.data()!['fcmToken'];
        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          await sendPushNotification(fcmToken: fcmToken.toString(), title: title, body: message);
        }
      }
    } catch (e) {
    }
  }

  /// Defaults to enabled for existing accounts that do not yet have a saved
  /// preference. This controls both the in-app notification record and FCM.
  static Future<bool> isPushNotificationsEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      if (!userDoc.exists) return true;
      final Object? setting = userDoc.data()?['PushNotifications'];
      return setting is! bool || setting;
    } catch (_) {
      // Do not silently drop notifications if the preference cannot be read.
      return true;
    }
  }
  static Stream<List<NotificationModel>> getUserNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          }).toList();

          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
    }
  }
  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
    }
  }
  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/service-account.json');
      final Map<String, dynamic> accountCredentials = jsonDecode(jsonString);
      final String projectId = accountCredentials['project_id'];

      final credentials = ServiceAccountCredentials.fromJson(accountCredentials);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final String accessToken = client.credentials.accessToken.data;
      client.close();
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      
      final Map<String, dynamic> payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
          }
        }
      };

      await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      print("Push Notification Error: $e");
    }
  }
}
