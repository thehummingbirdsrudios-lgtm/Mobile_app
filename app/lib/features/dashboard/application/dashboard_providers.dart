import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/revision.dart';
import '../../auth/auth.dart';
import '../domain/dashboard.dart';

/// Overridden at the composition root and in tests.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => throw UnimplementedError('dashboardRepositoryProvider must be overridden'),
);

/// Today's summary, or null when the member may not see reports (the call
/// is not even made). Re-fetches automatically when the session changes, so
/// one tenant's numbers can never survive into another session.
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary?>((ref) async {
  final session = ref.watch(currentSessionProvider);
  ref.watch(businessRevisionProvider); // orders and payments change today's numbers
  if (session == null || !session.can(Permission.reportsView)) return null;
  return ref.watch(dashboardRepositoryProvider).fetchSummary();
});
