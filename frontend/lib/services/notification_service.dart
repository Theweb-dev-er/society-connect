import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/api/visitor_service.dart';
import '../features/home/presentation/widgets/visitor_notification_dialog.dart';

import 'notification_stub.dart'
    if (dart.library.html) 'dart:html' as html;

import '../core/api/api_client.dart';
import '../features/auth/data/models/current_user.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('[FCM Background] Message received: ${message.messageId}');
  }
}

class NotificationService {
  static const String _vapidKey = String.fromEnvironment(
    'FCM_VAPID_KEY',
    defaultValue: 'BNIgnI6M1OMKpiaJz0lD7NTXnJpTbdSL9_kaaJhhtroXnosVE0g91ioEpnRtBCOuGwklmFgrBW5bjkaRz8gnUo0',
  );

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _dio = ApiClient().dio;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize Firebase Cloud Messaging and Local Notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        if (!kIsWeb) {
          await Firebase.initializeApp();
        }
      }

      // 2. Request Notification Permissions
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          print('[FCM] User granted permission');
        }
        
        // 3. Initialize Local Notifications (for showing foreground banners on Mobile)
        if (!kIsWeb) {
          await _initLocalNotifications();
        }

        // 4. Setup foreground message handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Setup background message handler (Mobile only)
        if (!kIsWeb) {
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        }

        // 5. Setup message click handlers
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
        
        // Check if app was opened from terminated state via notification
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationClick(initialMessage);
        }

        // 6. Retrieve and register token
        await registerDeviceToken();

        // 7. Monitor token refresh
        messaging.onTokenRefresh.listen((token) {
          _sendTokenToBackend(token);
        });

        _initialized = true;
      } else {
        if (kDebugMode) {
          print('[FCM] User declined or has not accepted notification permission');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error initializing notifications: $e');
      }
    }
  }

  /// Send current FCM token to backend (call after login)
  Future<void> registerDeviceToken() async {
    try {
      final String? token;
      if (kIsWeb) {
        token = await FirebaseMessaging.instance.getToken(
          vapidKey: _vapidKey == 'YOUR_PUBLIC_VAPID_KEY_HERE' ? null : _vapidKey,
        );
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error fetching token: $e');
      }
    }
  }

  /// Remove FCM token from backend (call on logout)
  Future<void> deleteDeviceToken() async {
    try {
      final String? token;
      if (kIsWeb) {
        token = await FirebaseMessaging.instance.getToken(
          vapidKey: _vapidKey == 'YOUR_PUBLIC_VAPID_KEY_HERE' ? null : _vapidKey,
        );
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token != null) {
        // Only attempt backend delete if user is logged in
        if (CurrentUser.accessToken != null && CurrentUser.accessToken!.isNotEmpty) {
          await _dio.delete(
            '/auth/device-tokens/',
            data: {'token': token},
          );
          if (kDebugMode) {
            print('[FCM] Token deleted from backend successfully.');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error deleting token from backend: $e');
      }
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    // Only send if the user is authenticated
    if (CurrentUser.accessToken == null || CurrentUser.accessToken!.isEmpty) {
      if (kDebugMode) {
        print('[FCM] Skipping token sync: User not authenticated');
      }
      return;
    }

    try {
      final String deviceType;
      if (kIsWeb) {
        deviceType = 'web';
      } else {
        deviceType = Platform.isIOS ? 'ios' : 'android';
      }
      await _dio.post(
        '/auth/device-tokens/',
        data: {
          'token': token,
          'device_type': deviceType,
        },
      );
      if (kDebugMode) {
        print('[FCM] Token synced to backend successfully: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Error syncing token to backend: $e');
      }
    }
  }


  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click when app is in foreground
        if (kDebugMode) {
          print('[FCM Local] Notification click: ${response.payload}');
        }
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Foreground message received: ${message.data}');
    }

    final data = message.data;
    final isVisitorRequest = data['type'] == 'visitor_approval_request';
    final visitorId = data['visitor_id']?.toString();

    if (isVisitorRequest && visitorId != null) {
      // For visitor approvals in the foreground, immediately display the custom dialog!
      _showForegroundVisitorDialog(visitorId);
      return;
    }

    final notification = message.notification;
    final title = notification?.title ??
        (message.data['title'] as String?) ??
        'Society Connect';
    final body = notification?.body ??
        (message.data['body'] as String?) ??
        '';

    if (kIsWeb) {
      _showWebNotification(title, body, visitorId: visitorId);
    } else {
      // On Mobile: use flutter_local_notifications
      final android = notification?.android;
      _localNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _showForegroundVisitorDialog(String visitorId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      final visitor = await VisitorService().getVisitor(visitorId);
      if (context.mounted) {
        VisitorNotificationDialog.show(
          context,
          visitor: visitor,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Failed to fetch visitor details for foreground dialog: $e');
      }
    }
  }

  void _showWebNotification(String title, String body, {String? visitorId}) {
    // Use dart:html to show a native browser notification
    try {
      if (html.Notification.supported) {
        final notification = html.Notification(title, body: body, icon: '/favicon.png');
        if (visitorId != null) {
          notification.onClick.listen((event) {
            navigatorKey.currentContext?.go('/visitors?visitorId=$visitorId');
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Could not show web notification: $e');
      }
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (kDebugMode) {
      print('[FCM] Notification clicked: ${message.data}');
    }
    final data = message.data;
    if (data['type'] == 'visitor_approval_request') {
      final visitorId = data['visitor_id']?.toString();
      if (visitorId != null) {
        Future.microtask(() {
          navigatorKey.currentContext?.go('/visitors?visitorId=$visitorId');
        });
      }
    }
  }
}
