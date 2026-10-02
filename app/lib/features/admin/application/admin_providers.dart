import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../../auth/auth.dart';
import '../domain/admin.dart';

/// Overridden at the composition root and in tests.
final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => throw UnimplementedError('adminRepositoryProvider must be overridden'),
);

final businessProfileProvider = FutureProvider.autoDispose<BusinessProfile>((ref) {
  ref
    ..watch(currentSessionProvider.select((s) => s?.tenantId))
    ..watch(businessRevisionProvider);
  return ref.watch(adminRepositoryProvider).profile();
});

final staffMembersProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) {
  ref.watch(currentSessionProvider.select((s) => s?.tenantId));
  return ref.watch(adminRepositoryProvider).members();
});

/// One member, read from the owner's member list (null when not found).
final staffMemberProvider = FutureProvider.autoDispose.family<StaffMember?, String>((ref, userId) async {
  final members = await ref.watch(staffMembersProvider.future);
  return members.where((m) => m.userId == userId).firstOrNull;
});

typedef AuditState = PagedState<AuditEntry, int>;

/// The owner's audit log, newest first.
final auditLogProvider = NotifierProvider.autoDispose<AuditLog, AuditState>(AuditLog.new);

class AuditLog extends Notifier<AuditState> {
  Paginator<AuditEntry, int>? _paginator;

  @override
  AuditState build() {
    ref.watch(currentSessionProvider.select((s) => s?.tenantId));
    final paginator = Paginator<AuditEntry, int>((cursor) => ref.read(adminRepositoryProvider).audit(before: cursor), (
      s,
    ) {
      if (ref.mounted) state = s;
    });
    _paginator = paginator;
    unawaited(Future.microtask(paginator.refresh));
    return const AuditState();
  }

  Future<void> refresh() => _paginator?.refresh() ?? Future.value();
  Future<void> loadMore() => _paginator?.loadMore() ?? Future.value();
  Future<void> retry() => _paginator?.retry() ?? Future.value();
}

/// Owner actions. Each one reports success only after the server committed,
/// then refreshes whatever reads depend on it.
final adminActionsProvider = Provider<AdminActions>(AdminActions.new);

class AdminActions {
  AdminActions(this._ref);

  final Ref _ref;

  AdminRepository get _repo => _ref.read(adminRepositoryProvider);

  /// The owner's tenant; refuses non-owners before any request is made.
  String _requireOwner() {
    final session = _ref.read(currentSessionProvider);
    if (session == null || !session.isOwner) throw const AppFailure(FailureKind.permissionDenied);
    return session.tenantId;
  }

  void _profileChanged() {
    _ref.read(businessRevisionProvider.notifier).bump();
    // The business name in the session (More, shares) comes from the server.
    unawaited(_ref.read(sessionControllerProvider.notifier).refresh());
  }

  Future<void> saveProfile(BusinessProfileDraft draft) async {
    await _repo.saveProfile(draft, tenantId: _requireOwner());
    _profileChanged();
  }

  /// Validates and processes the picked photo off the UI isolate, then
  /// uploads it. Throws [ImageRejectedException] for unusable files.
  Future<void> replaceLogo(Uint8List picked) async {
    final tenantId = _requireOwner();
    final derivatives = await _ref.read(imageProcessorProvider)(picked);
    await _repo.replaceLogo(Uint8List.fromList(derivatives.catalogue), tenantId: tenantId, sha256: derivatives.sha256);
    _profileChanged();
  }

  Future<void> removeLogo() async {
    await _repo.removeLogo(tenantId: _requireOwner());
    _profileChanged();
  }

  Future<void> setPermissions(String userId, Set<Permission> permissions) async {
    _requireOwner();
    await _repo.setPermissions(userId, permissions);
    _ref.invalidate(staffMembersProvider);
  }

  Future<void> setActive(String userId, {required bool active}) async {
    _requireOwner();
    await _repo.setActive(userId, active: active);
    _ref.invalidate(staffMembersProvider);
  }

  Future<String> createStaff(NewStaff staff) async {
    _requireOwner();
    final id = await _repo.createStaff(staff);
    _ref.invalidate(staffMembersProvider);
    return id;
  }

  Future<void> resetPassword(String userId, String password) async {
    _requireOwner();
    await _repo.resetPassword(userId, password);
  }
}
