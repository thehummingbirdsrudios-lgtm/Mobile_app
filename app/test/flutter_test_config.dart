import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Suite-wide test policy: a tap that would not reach its widget fails the
/// test instead of printing a warning and silently doing nothing.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await testMain();
}
