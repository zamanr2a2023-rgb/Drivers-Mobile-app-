import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:yjeek_driver/core/constants/api_endpoints.dart';
import 'package:yjeek_driver/firebase_options.dart';
import 'package:yjeek_driver/routes/app_navigator.dart';
import 'package:yjeek_driver/routes/route_names.dart';
import 'package:yjeek_driver/services/api_service.dart';

const _jobsChannelId = 'yjeek_driver_jobs';
const _jobsChannelName = 'Job offers';
const _defaultChannelId = 'yjeek_driver_default';
const _defaultChannelName = 'Yjeek Champ notifications';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const _jobsChannel = AndroidNotificationChannel(
  _jobsChannelId,
  _jobsChannelName,
  description: 'New delivery requests and route updates',
  importance: Importance.high,
);

const _defaultChannel = AndroidNotificationChannel(
  _defaultChannelId,
  _defaultChannelName,
  description: 'Account, performance, and other Champ alerts',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await showDriverTrayNotification(message);
}

String _channelIdFor(RemoteMessage message) {
  final type = (message.data['type'] ?? message.data['screen'] ?? '')
      .toString()
      .toUpperCase();
  if (type == 'ORDER_OFFER' || type == 'ORDER_CONFIRMATION' || type == 'JOB') {
    return _jobsChannelId;
  }
  return _defaultChannelId;
}

String _channelNameFor(String channelId) {
  return channelId == _jobsChannelId ? _jobsChannelName : _defaultChannelName;
}

Future<void> showDriverTrayNotification(RemoteMessage message) async {
  final title = message.notification?.title ??
      message.data['title']?.toString() ??
      'Yjeek Champ';
  final body =
      message.notification?.body ?? message.data['body']?.toString() ?? '';
  if (title.isEmpty && body.isEmpty) return;

  await _localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_yjeek'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_jobsChannel);
  await androidPlugin?.createNotificationChannel(_defaultChannel);

  final channelId = _channelIdFor(message);
  await _localNotifications.show(
    id: message.hashCode & 0x7fffffff,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelNameFor(channelId),
        channelDescription: channelId == _jobsChannelId
            ? 'New delivery requests and route updates'
            : 'Account, performance, and other Champ alerts',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_yjeek',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _started = false;
  Map<String, String>? _pendingOpen;

  bool get _hasSession {
    final token = ApiService.instance.accessToken;
    return token != null && token.isNotEmpty;
  }

  Future<void> start() async {
    if (_started) {
      await syncToken();
      return;
    }
    _started = true;

    try {
      await _initLocalNotifications();
    } catch (error, stack) {
      debugPrint('Local notifications init failed: $error\n$stack');
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission=${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
        'Notification permission denied — enable it in device settings for Yjeek Champ',
      );
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_register(token));
    });
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _pendingOpen = _asStringMap(initial.data);
    }

    await syncToken();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      Future<void>.delayed(const Duration(seconds: 2), syncToken);
    }
  }

  Future<void> syncToken() async {
    if (!_hasSession) return;
    try {
      final token = await _readFcmToken();
      if (token != null && token.isNotEmpty) {
        await _register(token);
      }
    } catch (error, stack) {
      debugPrint('FCM getToken failed: $error\n$stack');
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_hasSession) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await ApiService.instance.delete(ApiEndpoints.device(token));
    } catch (error, stack) {
      debugPrint('FCM unregister failed: $error\n$stack');
    }
  }

  void consumePendingOpen() {
    final pending = _pendingOpen;
    if (pending == null) return;
    _pendingOpen = null;
    openFromData(pending);
  }

  void openFromData(Map<String, String> data) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      _pendingOpen = data;
      return;
    }

    final type = (data['type'] ?? data['screen'] ?? '').toUpperCase();
    if (type == 'ACCOUNT_SUSPENDED' || type == 'ACCOUNT') {
      navigator.pushNamed(RouteNames.profile);
      return;
    }
    if (type == 'ORDER_OFFER' ||
        type == 'ORDER_CONFIRMATION' ||
        type == 'JOB' ||
        (data['jobId'] ?? '').trim().isNotEmpty ||
        (data['orderId'] ?? '').trim().isNotEmpty) {
      navigator.pushNamed(RouteNames.newRequest);
      return;
    }
    navigator.pushNamed(RouteNames.notifications);
  }

  Future<void> _initLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_yjeek'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onLocalResponse,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_jobsChannel);
    await androidPlugin?.createNotificationChannel(_defaultChannel);
    final granted = await androidPlugin?.requestNotificationsPermission();
    if (granted == false) {
      debugPrint('POST_NOTIFICATIONS not granted');
    }
  }

  void _onLocalResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        openFromData(
          decoded.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ),
        );
        return;
      }
    } catch (_) {}
    openFromData(const {'screen': 'notifications'});
  }

  Future<String?> _readFcmToken() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      String? apns;
      for (var attempt = 0; attempt < 12; attempt++) {
        apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (apns == null || apns.isEmpty) {
        debugPrint('FCM skipped — APNs token not ready yet');
        return null;
      }
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> _register(String token) async {
    if (!_hasSession) return;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : 'web';
    try {
      await ApiService.instance.post(
        ApiEndpoints.devices,
        body: {
          'token': token,
          'platform': platform,
          'provider': 'FCM',
        },
      );
      debugPrint('FCM device registered platform=$platform');
    } catch (error, stack) {
      debugPrint('FCM register device failed: $error\n$stack');
    }
  }

  void _onForeground(RemoteMessage message) {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        message.notification != null) {
      return;
    }
    unawaited(
      showDriverTrayNotification(message).catchError((error, stack) {
        debugPrint('Local notification failed: $error\n$stack');
      }),
    );
  }

  void _onOpened(RemoteMessage message) {
    openFromData(_asStringMap(message.data));
  }

  Map<String, String> _asStringMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }
}
