import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped after any write that changes orders or money (order placed or
/// cancelled, payment, adjustment). Read models in other modules watch it
/// and refetch, so writers never import readers.
final businessRevisionProvider = NotifierProvider<BusinessRevision, int>(BusinessRevision.new);

class BusinessRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}
