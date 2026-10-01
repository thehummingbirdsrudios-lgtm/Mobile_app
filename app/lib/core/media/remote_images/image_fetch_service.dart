import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ImageFetchFailure { blockedUrl, timeout, network, notFound, httpError, redirect, notAnImage, tooLarge }

class ImageFetchException implements Exception {
  const ImageFetchException(this.reason, {this.status});

  final ImageFetchFailure reason;
  final int? status;

  /// Worth one more try (the next attempt can reasonably succeed).
  bool get isTransient => switch (reason) {
    ImageFetchFailure.timeout || ImageFetchFailure.network => true,
    ImageFetchFailure.httpError => status != null && (status! >= 500 || status == 429 || status == 408),
    _ => false,
  };

  @override
  String toString() => 'ImageFetchException($reason${status == null ? '' : ', $status'})';
}

/// Safety limits for downloading images.
@immutable
class ImageFetchPolicy {
  const ImageFetchPolicy({
    this.allowedHosts,
    this.maxBytes = 10 * 1024 * 1024,
    this.timeout = const Duration(seconds: 15),
    this.retries = 1,
    this.retryDelay = const Duration(milliseconds: 400),
  });

  /// Hosts the app may download from (our storage host). Null allows any
  /// HTTPS host — only for tests.
  final Set<String>? allowedHosts;
  final int maxBytes;

  /// Applies to the connection and to every gap while the body streams in.
  final Duration timeout;
  final int retries;
  final Duration retryDelay;
}

/// Downloads image bytes over HTTPS with hard limits: allow-listed host,
/// no redirects, timeout, byte cap enforced while streaming (a huge or
/// endless response is cut off, never buffered), content-type check, and
/// one retry for transient failures.
class ImageFetchService {
  ImageFetchService(this._client, {this.policy = const ImageFetchPolicy(), Future<void> Function(Duration)? delay})
    : _delay = delay ?? Future<void>.delayed;

  final http.Client _client;
  final ImageFetchPolicy policy;
  final Future<void> Function(Duration) _delay;

  Future<Uint8List> fetch(Uri uri) async {
    _checkUrl(uri);
    for (var attempt = 0; ; attempt++) {
      try {
        return await _once(uri);
      } on ImageFetchException catch (e) {
        if (!e.isTransient || attempt >= policy.retries) rethrow;
        await _delay(policy.retryDelay * (attempt + 1));
      }
    }
  }

  void _checkUrl(Uri uri) {
    final hosts = policy.allowedHosts;
    if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const ImageFetchException(ImageFetchFailure.blockedUrl);
    }
    if (hosts != null && !hosts.contains(uri.host.toLowerCase())) {
      throw const ImageFetchException(ImageFetchFailure.blockedUrl);
    }
  }

  Future<Uint8List> _once(Uri uri) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Accept'] = 'image/jpeg, image/png, image/webp, image/*;q=0.8';
    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(policy.timeout);
    } on TimeoutException {
      throw const ImageFetchException(ImageFetchFailure.timeout);
    } on http.ClientException {
      throw const ImageFetchException(ImageFetchFailure.network);
    }

    final status = response.statusCode;
    Never fail(ImageFetchFailure reason) {
      unawaited(response.stream.listen(null).cancel());
      throw ImageFetchException(reason, status: status);
    }

    if (status == 404 || status == 410) fail(ImageFetchFailure.notFound);
    if (status >= 300 && status < 400) fail(ImageFetchFailure.redirect);
    if (status != 200) fail(ImageFetchFailure.httpError);
    final type = (response.headers['content-type'] ?? '').toLowerCase();
    if (type.isNotEmpty && !type.startsWith('image/') && !type.startsWith('application/octet-stream')) {
      fail(ImageFetchFailure.notAnImage);
    }
    final declared = response.contentLength;
    if (declared != null && declared > policy.maxBytes) fail(ImageFetchFailure.tooLarge);

    final body = await _readBody(response.stream);
    if (body.isEmpty) throw const ImageFetchException(ImageFetchFailure.notAnImage);
    return body;
  }

  /// Reads the body with an idle timeout (reset by every chunk) and a hard
  /// byte cap: the download is cancelled the moment it would exceed the cap,
  /// so an oversized or endless response is never buffered.
  Future<Uint8List> _readBody(Stream<List<int>> stream) {
    final result = Completer<Uint8List>();
    final bytes = BytesBuilder(copy: false);
    late final StreamSubscription<List<int>> subscription;
    Timer? idle;

    void fail(ImageFetchFailure reason) {
      idle?.cancel();
      unawaited(subscription.cancel());
      if (!result.isCompleted) result.completeError(ImageFetchException(reason));
    }

    void arm() {
      idle?.cancel();
      idle = Timer(policy.timeout, () => fail(ImageFetchFailure.timeout));
    }

    subscription = stream.listen(
      (chunk) {
        if (bytes.length + chunk.length > policy.maxBytes) return fail(ImageFetchFailure.tooLarge);
        bytes.add(chunk);
        arm();
      },
      onError: (Object error) => fail(ImageFetchFailure.network),
      onDone: () {
        idle?.cancel();
        if (!result.isCompleted) result.complete(bytes.takeBytes());
      },
      cancelOnError: true,
    );
    arm();
    return result.future;
  }
}
