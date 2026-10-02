import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_status.dart';

class _NoStatus implements AppStatusRepository {
  const _NoStatus();

  @override
  Future<AppStatus?> fetch() async => null;
}

/// Overridden at the composition root; unconfigured builds and tests that
/// do not care get "unknown" (no gate).
final appStatusRepositoryProvider = Provider<AppStatusRepository>((ref) => const _NoStatus());

final appStatusProvider = FutureProvider<AppStatus?>((ref) => ref.watch(appStatusRepositoryProvider).fetch());
