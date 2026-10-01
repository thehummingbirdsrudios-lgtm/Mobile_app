/// Shared kernel: the ONLY entry point feature modules use for core code.
/// Core never imports from features (enforced by tool/check_boundaries.dart).
library;

export 'config/app_config.dart';
export 'design/theme.dart';
export 'design/tokens.dart';
export 'errors/app_failure.dart';
export 'format/formatters.dart';
export 'logging/app_logger.dart';
export 'media/image_pipeline.dart';
export 'media/photo_picker.dart';
export 'money/money.dart';
export 'motion/motion.dart';
export 'navigation/app_navigator.dart';
export 'network/api_client.dart' show ApiClient, RpcTransport;
export 'network/json_reader.dart';
export 'network/storage_client.dart' show Buckets, StorageClient, storageClientProvider;
export 'platform/contact_launcher.dart';
export 'state/paged.dart';
export 'storage/tenant_cache.dart';
export 'util/ids.dart';
export 'widgets/app_button.dart';
export 'widgets/brand_mark.dart';
export 'widgets/display.dart';
export 'widgets/inputs.dart';
export 'widgets/paged_view.dart';
export 'widgets/remote_image.dart';
export 'widgets/states.dart';
export 'widgets/success_check.dart';
export 'widgets/unsaved_changes_guard.dart';
