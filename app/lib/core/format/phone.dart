/// Phone number rules shared by customers and the business profile. They
/// mirror the database CHECK `^\+?[0-9]{10,15}$`.
abstract final class PhoneNumbers {
  /// Keeps digits and a leading +; Indian numbers are stored as 10 digits
  /// ("+91 98250 12345" → "9825012345"). Null when empty.
  static String? normalise(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return trimmed; // fails validation
    if (digits.length == 12 && digits.startsWith('91')) return digits.substring(2);
    if (!trimmed.startsWith('+') && digits.length == 11 && digits.startsWith('0')) return digits.substring(1);
    return trimmed.startsWith('+') ? '+$digits' : digits;
  }

  static final _pattern = RegExp(r'^\+?[0-9]{10,15}$');

  /// Null (no number) is valid; anything else must match the stored format.
  static bool isValid(String? normalised) => normalised == null || _pattern.hasMatch(normalised);
}
