import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer or a WhatsApp chat. Behind a port so screens stay
/// testable and the URL rules live in one place.
abstract interface class ContactLauncher {
  /// Returns false when no app can handle it (e.g. WhatsApp not installed).
  Future<bool> call(String phone);

  Future<bool> whatsapp(String phone, {String? text});
}

/// wa.me needs the country code; Indian 10-digit numbers get 91.
String whatsappNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length == 10 ? '91$digits' : digits;
}

Uri whatsappUri(String phone, {String? text}) =>
    Uri.https('wa.me', '/${whatsappNumber(phone)}', text == null || text.isEmpty ? null : {'text': text});

class UrlContactLauncher implements ContactLauncher {
  const UrlContactLauncher();

  @override
  Future<bool> call(String phone) => _open(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  @override
  Future<bool> whatsapp(String phone, {String? text}) => _open(whatsappUri(phone, text: text));

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

final contactLauncherProvider = Provider<ContactLauncher>((ref) => const UrlContactLauncher());
