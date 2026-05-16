import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps `flutter_local_notifications` for the rest-timer.
/// For now we use a Future.delayed-driven `show` (good for foreground/lock-screen
/// when the OS lets it fire). If we later need guaranteed background delivery on
/// iOS, swap to `zonedSchedule` with the `timezone` package wired up in main().
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Timer? _pendingRest;

  static const _restCompleteId = 9001;

  Future<void> init() async {
    if (_ready) return;
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(iOS: ios, android: android),
    );
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
    } catch (e) {
      debugPrint('iOS notification perms: $e');
    }
    _ready = true;
  }

  int scheduleRestComplete(int seconds) {
    if (!_ready || seconds <= 0) return -1;
    _pendingRest?.cancel();
    _pendingRest = Timer(Duration(seconds: seconds), () {
      _plugin.show(
        _restCompleteId,
        'Rest complete',
        'Get the next set.',
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentSound: true),
          android: AndroidNotificationDetails(
            'peak_rest',
            'Rest timer',
            channelDescription: 'Notifies when the rest timer expires.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
    return _restCompleteId;
  }

  Future<void> cancelRestComplete() async {
    _pendingRest?.cancel();
    _pendingRest = null;
    if (_ready) await _plugin.cancel(_restCompleteId);
  }
}
