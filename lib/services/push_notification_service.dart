import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yjeek_driver/app_navigator.dart';
import 'package:yjeek_driver/core/constants/storage_keys.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/storage_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || !Platform.isIOS) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !Platform.isIOS) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      String? apnsToken = await messaging.getAPNSToken();
      if (apnsToken == null) {
        await Future<void>.delayed(const Duration(seconds: 2));
        apnsToken = await messaging.getAPNSToken();
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
        debugPrint('FCM token: $token');
      }

      messaging.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessageOpenedApp.listen(_openNotificationsInbox);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openNotificationsInbox(initial);
        });
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize iOS push notifications: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final storage = await StorageService.getInstance();
    await storage.saveString(StorageKeys.fcmToken, token);
  }

  void _openNotificationsInbox(RemoteMessage message) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    final route = message.data['route']?.toString().trim();
    navigator.pushNamed(
      route != null && route.isNotEmpty ? route : RouteNames.notifications,
    );
  }
}
