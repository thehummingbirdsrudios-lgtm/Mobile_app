import 'dart:async';

import 'package:vepari/core/core.dart';
import 'package:vepari/features/auth/auth.dart';
import 'package:vepari/features/dashboard/dashboard.dart';
import 'package:vepari/features/settings/settings.dart';

const ownerSession = UserSession(
  userId: 'u-owner',
  tenantId: 't-a',
  username: 'rajesh',
  displayName: 'Rajeshbhai',
  businessName: 'Shree Jewels',
  role: MemberRole.owner,
  permissions: {},
);

const staffSession = UserSession(
  userId: 'u-staff',
  tenantId: 't-a',
  username: 'mahesh',
  displayName: 'Maheshbhai',
  businessName: 'Shree Jewels',
  role: MemberRole.staff,
  permissions: {Permission.ordersCreate},
);

/// Scriptable [AuthRepository] that records calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restored, this.signInResult, this.signInError, this.restoreError});

  UserSession? restored;
  UserSession? signInResult;
  AppFailure? signInError;
  AppFailure? restoreError;
  Completer<void>? signInGate;
  int signInCalls = 0;
  int signOutCalls = 0;
  String? lastUsername;
  final _ended = StreamController<void>.broadcast();

  void endSession() => _ended.add(null);

  @override
  Stream<void> get sessionEnded => _ended.stream;

  @override
  Future<UserSession?> restore() async {
    if (restoreError != null) throw restoreError!;
    return restored;
  }

  @override
  Future<UserSession> signIn({required String username, required String password}) async {
    signInCalls++;
    lastUsername = username;
    if (signInGate != null) await signInGate!.future;
    if (signInError != null) throw signInError!;
    return signInResult!;
  }

  @override
  Future<void> signOut() async => signOutCalls++;

  Future<void> dispose() => _ended.close();
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({this.summary, this.error});

  DashboardSummary? summary;
  AppFailure? error;
  int calls = 0;

  @override
  Future<DashboardSummary> fetchSummary() async {
    calls++;
    if (error != null) throw error!;
    return summary!;
  }
}

class MemoryPreferenceStore implements PreferenceStore {
  final values = <String, String>{};

  @override
  String? getString(String key) => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

const sampleSummary = DashboardSummary(
  salesToday: Money.paise(3850000),
  paymentsToday: Money.paise(2200000),
  totalBaki: Money.paise(48200000),
  ordersToday: 7,
  pendingOrders: 3,
  newMaalLast7Days: 12,
);
