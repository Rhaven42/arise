import 'package:arise/features/planning/domain/planning_repositories.dart';
import 'package:arise/features/planning/domain/schedule.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Textes d'une notification de rappel.
typedef ReminderTexts = ({String title, String body});

/// Rappels programmés avec les notifications locales du téléphone.
///
/// Aucune donnée ne quitte l'appareil : les notifications sont planifiées
/// par le système, sans serveur.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderTexts Function(String programName) texts,
    required String channelName,
    required String channelDescription,
  }) : _plugin = plugin,
       _texts = texts,
       _channelName = channelName,
       _channelDescription = channelDescription;

  static const _channelId = 'planned_sessions';

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderTexts Function(String programName) _texts;
  final String _channelName;
  final String _channelDescription;
  Future<void>? _initialization;

  Future<void> _ensureInitialized() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      // Fuseau inconnu de la base : on garde l'UTC plutôt que d'échouer.
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(alert: true, sound: true) ?? false;
      case TargetPlatform.fuchsia ||
          TargetPlatform.linux ||
          TargetPlatform.macOS ||
          TargetPlatform.windows:
        return false;
    }
  }

  @override
  Future<void> replaceAll(List<ReminderRequest> reminders) async {
    await _ensureInitialized();
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final reminder in reminders) {
      final texts = _texts(reminder.programName);
      final (date, match) = switch (reminder.time) {
        WeeklyReminderTime(:final weekday, :final minuteOfDay) => (
          _nextWeekly(now, weekday, minuteOfDay),
          DateTimeComponents.dayOfWeekAndTime,
        ),
        OneOffReminderTime(:final at) => (
          tz.TZDateTime(
            tz.local,
            at.year,
            at.month,
            at.day,
            at.hour,
            at.minute,
          ),
          null,
        ),
      };
      if (!date.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: reminder.notificationId,
        scheduledDate: date,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: texts.title,
        body: texts.body,
        matchDateTimeComponents: match,
      );
    }
  }

  /// Prochaine date (après [now]) du jour [weekday] à [minuteOfDay].
  static tz.TZDateTime _nextWeekly(
    tz.TZDateTime now,
    int weekday,
    int minuteOfDay,
  ) {
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day + 1,
        date.hour,
        date.minute,
      );
    }
    return date;
  }
}
