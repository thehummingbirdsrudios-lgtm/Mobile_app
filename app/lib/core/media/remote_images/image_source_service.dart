import '../../widgets/remote_image.dart' show SignedUrlCache;
import 'image_models.dart';

/// Turns a stored image key into a URL that can be fetched right now. The
/// buckets are private, so this is a short-lived signed HTTPS URL.
abstract interface class ImageSourceService {
  Future<Uri> resolve(ImageRef ref);
}

class SignedImageSource implements ImageSourceService {
  const SignedImageSource(this._urls);

  final SignedUrlCache _urls;

  @override
  Future<Uri> resolve(ImageRef ref) async => Uri.parse(await _urls.get((bucket: ref.bucket, path: ref.path)));
}
