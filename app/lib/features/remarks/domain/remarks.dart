import 'dart:typed_data';

import 'package:meta/meta.dart';

enum RemarkKind {
  text,
  voice,
  photo;

  static RemarkKind parse(String value) =>
      values.firstWhere((k) => k.name == value, orElse: () => throw FormatException('unknown kind', value));
}

/// What a Vaat is about. Exactly one target per remark (a database CHECK).
enum RemarkTargetKind {
  customer('customer_id'),
  order('order_id'),
  product('product_id');

  const RemarkTargetKind(this.column);

  final String column;
}

@immutable
class RemarkTarget {
  const RemarkTarget(this.kind, this.id);

  const RemarkTarget.customer(this.id) : kind = RemarkTargetKind.customer;
  const RemarkTarget.order(this.id) : kind = RemarkTargetKind.order;
  const RemarkTarget.product(this.id) : kind = RemarkTargetKind.product;

  final RemarkTargetKind kind;
  final String id;

  @override
  bool operator ==(Object other) => other is RemarkTarget && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// An internal note. Vaat never leaves the business: no share payload
/// includes it.
@immutable
class Remark {
  const Remark({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.text,
    this.mediaPath,
    this.duration,
    this.authorId,
    this.authorName,
  });

  final String id;
  final RemarkKind kind;
  final DateTime createdAt;
  final String? text;
  final String? mediaPath;
  final Duration? duration;
  final String? authorId;
  final String? authorName;
}

/// Limits mirrored from the database.
abstract final class RemarkLimits {
  static const maxText = 2000;
  static const minVoice = Duration(milliseconds: 500);
  static const maxVoice = Duration(minutes: 5);
}

/// Remarks port. Implementations throw `AppFailure`.
abstract interface class RemarksRepository {
  Future<List<Remark>> list(RemarkTarget target, {int limit});

  Future<void> addText(RemarkTarget target, String text);

  Future<void> addVoice(
    RemarkTarget target, {
    required String tenantId,
    required Uint8List audio,
    required String mimeType,
    required Duration duration,
  });

  Future<void> addPhoto(RemarkTarget target, {required String tenantId, required Uint8List jpeg});

  /// Hides a remark (author or owner only; enforced by RLS).
  Future<void> archive(String remarkId);
}
