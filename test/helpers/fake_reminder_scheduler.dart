import 'package:arise/features/planning/domain/planning_repositories.dart';
import 'package:arise/features/planning/domain/schedule.dart';

/// Faux planificateur de rappels : mémorise ce qui a été demandé.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.grantPermission = true});

  final bool grantPermission;
  int permissionRequests = 0;
  List<ReminderRequest> scheduled = const [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<void> replaceAll(List<ReminderRequest> reminders) async {
    scheduled = reminders;
  }
}
