import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/app_failure.dart';

enum PhotoOrigin { camera, gallery }

/// Picks a photo. Returns null when the user cancels. Throws
/// [AppFailure] (permissionDenied) when camera/photo access is refused.
abstract interface class PhotoPicker {
  Future<Uint8List?> pick(PhotoOrigin origin);
}

class DevicePhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<Uint8List?> pick(PhotoOrigin origin) async {
    try {
      final file = await _picker.pickImage(
        source: origin == PhotoOrigin.camera ? ImageSource.camera : ImageSource.gallery,
        requestFullMetadata: false,
      );
      return file == null ? null : await file.readAsBytes();
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied') || e.code.contains('permission')) {
        throw AppFailure(FailureKind.permissionDenied, code: 'device_permission', diagnostic: e.code);
      }
      throw AppFailure(FailureKind.unknown, diagnostic: 'picker:${e.code}');
    }
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => DevicePhotoPicker());
