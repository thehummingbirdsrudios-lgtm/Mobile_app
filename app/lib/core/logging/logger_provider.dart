import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

/// The app's logger. main.dart overrides it with the instance it configured.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.forBuild());
