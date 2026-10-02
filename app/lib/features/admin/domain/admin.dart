import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../../core/format/phone.dart';
import '../../../core/state/paged.dart';
import '../../auth/auth.dart' show MemberRole, Permission, Username, UsernameIssue;

/// The business details printed on bills, receipts and shares.
@immutable
class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    this.phone,
    this.whatsappPhone,
    this.address,
    this.gstin,
    this.billFooter,
    this.logoPath,
    this.watermarkEnabled = true,
    this.defaultLocale = 'gu',
  });

  final String businessName;
  final String? phone;
  final String? whatsappPhone;
  final String? address;
  final String? gstin;
  final String? billFooter;

  /// Storage key in the private `branding` bucket.
  final String? logoPath;
  final bool watermarkEnabled;

  /// 'gu' | 'hi' | 'en' — the language new staff devices start in.
  final String defaultLocale;
}

enum ProfileIssue {
  nameRequired,
  nameTooLong,
  phoneInvalid,
  whatsappInvalid,
  gstinInvalid,
  addressTooLong,
  footerTooLong,
}

/// What the owner typed. [validate] mirrors the database CHECK constraints so
/// mistakes are shown on the field instead of as a server error.
@immutable
class BusinessProfileDraft {
  const BusinessProfileDraft({
    required this.businessName,
    this.phone = '',
    this.whatsappPhone = '',
    this.address = '',
    this.gstin = '',
    this.billFooter = '',
    this.watermarkEnabled = true,
    this.defaultLocale = 'gu',
  });

  final String businessName;
  final String phone;
  final String whatsappPhone;
  final String address;
  final String gstin;
  final String billFooter;
  final bool watermarkEnabled;
  final String defaultLocale;

  static const supportedLocales = {'gu', 'hi', 'en'};
  static final _gstinPattern = RegExp(r'^[0-9A-Z]{15}$');

  /// "24abcde 1234f1z5" → "24ABCDE1234F1Z5"; null when empty.
  static String? normaliseGstin(String input) {
    final value = input.replaceAll(RegExp(r'\s'), '').toUpperCase();
    return value.isEmpty ? null : value;
  }

  static bool isValidGstin(String input) {
    final value = normaliseGstin(input);
    return value == null || _gstinPattern.hasMatch(value);
  }

  Set<ProfileIssue> validate() => {
    if (businessName.trim().isEmpty) ProfileIssue.nameRequired,
    if (businessName.trim().length > 120) ProfileIssue.nameTooLong,
    if (!PhoneNumbers.isValid(PhoneNumbers.normalise(phone))) ProfileIssue.phoneInvalid,
    if (!PhoneNumbers.isValid(PhoneNumbers.normalise(whatsappPhone))) ProfileIssue.whatsappInvalid,
    if (!isValidGstin(gstin)) ProfileIssue.gstinInvalid,
    if (address.trim().length > 400) ProfileIssue.addressTooLong,
    if (billFooter.trim().length > 400) ProfileIssue.footerTooLong,
  };
}

/// A member of the business as the owner sees it.
@immutable
class StaffMember {
  const StaffMember({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.permissions,
  });

  final String userId;
  final String username;
  final String displayName;
  final MemberRole role;
  final bool isActive;
  final Set<Permission> permissions;

  bool get isOwner => role == MemberRole.owner;
}

enum PasswordIssue { tooShort, tooLong, sameAsUsername }

enum NewStaffIssue { usernameEmpty, usernameInvalid, nameRequired, nameTooLong }

/// A staff login the owner is creating. The server re-checks every rule.
@immutable
class NewStaff {
  const NewStaff({
    required this.username,
    required this.displayName,
    required this.password,
    this.permissions = const {},
  });

  final String username;
  final String displayName;
  final String password;
  final Set<Permission> permissions;

  /// Passwords are 8–72 UTF-8 bytes: the hashing (bcrypt) ignores anything
  /// after 72 bytes, so a longer one would silently not be what was typed.
  static PasswordIssue? passwordIssue(String password, {String? username}) {
    final bytes = utf8.encode(password).length;
    if (bytes < 8 || password.trim().isEmpty) return PasswordIssue.tooShort;
    if (bytes > 72) return PasswordIssue.tooLong;
    if (username != null && password.toLowerCase() == Username.normalize(username)) {
      return PasswordIssue.sameAsUsername;
    }
    return null;
  }

  Set<NewStaffIssue> validate() => {
    if (Username.validate(username) == UsernameIssue.empty) NewStaffIssue.usernameEmpty,
    if (Username.validate(username) == UsernameIssue.invalid) NewStaffIssue.usernameInvalid,
    if (displayName.trim().isEmpty) NewStaffIssue.nameRequired,
    if (displayName.trim().length > 80) NewStaffIssue.nameTooLong,
  };
}

/// One audit-log row. [data] holds what changed (owner-only commercial
/// fields arrive as "changed", never their values).
@immutable
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.entityId,
    this.data = const {},
    this.actorName,
    this.subject,
  });

  final int id;
  final String action;
  final String entity;
  final String? entityId;
  final Map<String, Object?> data;
  final String? actorName;
  final DateTime createdAt;

  /// What the row is about, e.g. "1024 · Kundan Set", "Rajeshbhai", "#1045".
  final String? subject;

  /// Names of the fields that changed (row-change entries only).
  List<String> get changedFields => switch (action) {
    'insert' || 'update' || 'delete' => [for (final key in data.keys) key],
    _ => const [],
  };
}

/// Owner administration port. Implementations throw `AppFailure`.
abstract interface class AdminRepository {
  Future<BusinessProfile> profile();
  Future<void> saveProfile(BusinessProfileDraft draft, {required String tenantId});

  /// Stores a processed logo (JPEG) and points the profile at it.
  Future<String> replaceLogo(Uint8List jpeg, {required String tenantId, required String sha256});
  Future<void> removeLogo({required String tenantId});

  Future<List<StaffMember>> members();
  Future<void> setPermissions(String userId, Set<Permission> permissions);
  Future<void> setActive(String userId, {required bool active});

  /// Creates the login and the membership (server side, Edge Function).
  /// Returns the new member's user id.
  Future<String> createStaff(NewStaff staff);
  Future<void> resetPassword(String userId, String password);

  Future<PageResult<AuditEntry, int>> audit({int? before, int limit});
}
