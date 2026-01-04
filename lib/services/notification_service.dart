import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz; // Ensure this is available
import 'package:flutter/material.dart';

import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:permission_handler/permission_handler.dart';

import 'dart:typed_data'; // Added for Int32List

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
  debugPrint('notificationTapBackground: ${notificationResponse.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    debugPrint("[NotificationService] Detected Timezone: $timeZoneName");
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        debugPrint("[NotificationService] Notification Tapped. Payload: $payload");
        
        if (payload != null && navigatorKey != null) {
          if (payload.contains(':')) {
             navigatorKey!.currentState?.pushNamed('/meds');
          } else {
             navigatorKey!.currentState?.pushNamed('/food');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
     
    // Explicitly Request Permissions using permission_handler
    debugPrint("[NotificationService] Requesting Permissions...");
    
    // 1. Notification Permission
    var notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      notifStatus = await Permission.notification.request();
    }
    debugPrint("[NotificationService] Notification Permission Status: $notifStatus");

    // 2. Exact Alarm Permission (Android 12+)
    var alarmStatus = await Permission.scheduleExactAlarm.status;
    if (alarmStatus.isDenied || alarmStatus.isRestricted) { // On Android 13+, it might be denied by default
       debugPrint("[NotificationService] Exact Alarm Permission denied. Requesting...");
       alarmStatus = await Permission.scheduleExactAlarm.request();
    }
    debugPrint("[NotificationService] Exact Alarm Permission Status: $alarmStatus");
  }

  // Modified to accept a list of medications and schedule by TIME
  Future<void> scheduleMedicationGroup(String timeStr, List<String> medNames) async {
    debugPrint("[NotificationService] Scheduling Group for $timeStr: $medNames");
    
    // Parse time (HH:mm)
    final parts = timeStr.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // If time passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final String bodyText = medNames.join(', ');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        timeStr.hashCode, // Unique ID based on TIME (e.g. "09:00" -> ID)
        'İlaç Vakti! 💊',
        'İçilecekler: $bodyText',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_alarm_channel_v3', // Fresh channel
            'İlaç Alarmları',
            channelDescription: 'Sürekli çalan ilaç alarmları',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'İlaç Vakti',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            playSound: true,
            enableVibration: true,
            // Critical for "Alarm-like" behavior. 
            // 'insistent' param missing in this version, using additionalFlags (4 = FLAG_INSISTENT)
            additionalFlags: Int32List.fromList(<int>[4]),
            audioAttributesUsage: AudioAttributesUsage.alarm,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false, // Don't disappear on tap
            ongoing: true, // Can't be swiped away
            // fullScreenIntent: true, // DISABLED: Suspected cause of background crash
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Re-enabled for daily repeat
        payload: timeStr, // Pass timeStr as payload to cancel on tap
      );
      debugPrint("[NotificationService] Scheduled Group ID: ${timeStr.hashCode}");
    } catch (e) {
      debugPrint("[NotificationService] ERROR: $e");
    }
  }
  
  Future<void> showTestNotification() async {
    debugPrint("[NotificationService] Sending Test Notification NOW");
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Bildirimi',
      'Bildirimler çalışıyor! 🎉',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_alert_v2', // Changed ID to force update
          'İlaç Alarmları',
          channelDescription: 'Yüksek öncelikli ilaç hatırlatıcıları',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  Future<void> scheduleMealNotification(String id, String mealName, String timeStr) async {
    debugPrint("[NotificationService] Scheduling Meal: $mealName at $timeStr");
    
    // Parse time (HH:mm)
    final parts = timeStr.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // If time passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id.hashCode, // Use hash of Meal ID (e.g. "101")
        'Yemek Vakti: $mealName 🍽️', // Title now includes Meal Name
        'Afiyet olsun! Yemeğini yemeyi unutma.',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'meal_alarm_channel_v2', // FRESH Channel ID to reset settings
            'Yemek Alarmları',
            channelDescription: 'Yemek vakti hatırlatıcıları',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'Yemek Vakti',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            playSound: true,
            enableVibration: true,
            // ALARM BEHAVIOR FLAGS (Matching Medication Alarm)
            additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
            audioAttributesUsage: AudioAttributesUsage.alarm,
            category: AndroidNotificationCategory.alarm,
            autoCancel: false,
            ongoing: true,
            // fullScreenIntent: true, // DISABLED: Suspected cause of background crash
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Daily Repeat
        payload: id, // Pass Meal ID
      );
      debugPrint("[NotificationService] Scheduled Meal ID: ${id.hashCode} ($mealName)");
    } catch (e) {
      debugPrint("[NotificationService] ERROR Meal Schedule: $e");
    }
  }

  Future<void> cancelNotification(String id) async {
    await flutterLocalNotificationsPlugin.cancel(id.hashCode);
  }

  Future<void> cancelMyNotification(String timeStr) async {
    await flutterLocalNotificationsPlugin.cancel(timeStr.hashCode);
  }
}
