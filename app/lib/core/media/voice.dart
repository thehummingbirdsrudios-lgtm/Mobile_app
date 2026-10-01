import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../util/ids.dart';

@immutable
class RecordedAudio {
  const RecordedAudio({required this.bytes, required this.mimeType, required this.duration});

  final Uint8List bytes;
  final String mimeType;
  final Duration duration;
}

/// Records a short voice note. Behind a port so screens are testable.
abstract interface class VoiceRecorder {
  /// Asks for the microphone if needed. False when the user refused.
  Future<bool> ensurePermission();

  Future<void> start();

  /// Stops and returns the recording (null if nothing was captured).
  Future<RecordedAudio?> stop();

  Future<void> cancel();
}

/// AAC in an .m4a container: small, and plays everywhere.
class DeviceVoiceRecorder implements VoiceRecorder {
  DeviceVoiceRecorder();

  final _recorder = AudioRecorder();
  String? _path;
  DateTime? _startedAt;

  @override
  Future<bool> ensurePermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/vaat-${newUuid()}.m4a';
    await _recorder.start(const RecordConfig(bitRate: 64000, sampleRate: 22050, numChannels: 1), path: path);
    _path = path;
    _startedAt = DateTime.now();
  }

  @override
  Future<RecordedAudio?> stop() async {
    final path = await _recorder.stop() ?? _path;
    final started = _startedAt;
    _path = null;
    _startedAt = null;
    if (path == null || started == null) return null;
    final file = File(path);
    try {
      return RecordedAudio(
        bytes: await file.readAsBytes(),
        mimeType: 'audio/mp4',
        duration: DateTime.now().difference(started),
      );
    } finally {
      // The temp copy is deleted at once; only the uploaded note remains.
      if (file.existsSync()) await file.delete();
    }
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    _path = null;
    _startedAt = null;
  }
}

/// Plays one voice note at a time.
abstract interface class VoicePlayer {
  Stream<String?> get nowPlaying;

  Future<void> play(String id, String url);

  Future<void> stop();
}

class DeviceVoicePlayer implements VoicePlayer {
  DeviceVoicePlayer() {
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) unawaited(stop());
    });
  }

  final _player = AudioPlayer();
  final _current = StreamController<String?>.broadcast();

  @override
  Stream<String?> get nowPlaying => _current.stream;

  @override
  Future<void> play(String id, String url) async {
    await _player.stop();
    _current.add(id);
    await _player.setUrl(url);
    unawaited(_player.play());
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _current.add(null);
  }
}

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) => DeviceVoiceRecorder());

final voicePlayerProvider = Provider<VoicePlayer>((ref) => DeviceVoicePlayer());
