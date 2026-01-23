import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToDatabase);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved: $token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Message clicked!');
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) {
        debugPrint('User does not have FCM token');
        return;
      }

      // Save notification to Firestore (for history)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Note: Actual FCM sending requires Cloud Functions or server-side code
      // For MVP, we just save notification to Firestore
      debugPrint('Notification saved for user: $userId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  static Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title = 'Update Pesanan';
    String body = '';

    switch (status) {
      case 'diproses':
        title = 'Pesanan Diproses';
        body = 'Pesanan Anda sedang dikemas';
        break;
      case 'dikirim':
        title = 'Pesanan Dikirim';
        body = 'Pesanan Anda dalam perjalanan';
        break;
      case 'selesai':
        title = 'Pesanan Selesai';
        body = 'Pesanan Anda telah selesai. Berikan review Anda!';
        break;
      case 'dibatalkan':
        title = 'Pesanan Dibatalkan';
        body = 'Pesanan Anda telah dibatalkan';
        break;
      case 'payment_confirmed':
        title = 'Pembayaran Dikonfirmasi';
        body = 'Pembayaran transfer Anda telah dikonfirmasi admin';
        break;
      case 'payment_rejected':
        title = 'Pembayaran Ditolak';
        body = 'Pembayaran Anda ditolak. Hubungi admin untuk info lebih lanjut';
        break;
    }

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': {
          'orderId': orderId,
          'status': status,
          'type': 'order_status',
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}
