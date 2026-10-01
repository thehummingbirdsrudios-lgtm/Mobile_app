/// Reusable remote-image pipeline: stored key → signed URL → safe download →
/// validation → optimisation → cache. Used by bill PDFs; usable anywhere a
/// right-sized copy of a stored photo is needed.
library;

export 'image_cache_service.dart';
export 'image_fetch_service.dart';
export 'image_models.dart';
export 'image_optimization_service.dart';
export 'image_source_service.dart';
export 'image_validation_service.dart';
export 'optimized_image_loader.dart';
