// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Vepari';

  @override
  String get navHome => 'होम';

  @override
  String get navMaal => 'माल';

  @override
  String get navOrder => 'ऑर्डर';

  @override
  String get navCustomer => 'ग्राहक';

  @override
  String get navHisaab => 'हिसाब';

  @override
  String get navMore => 'और';

  @override
  String get loginGreeting => 'नमस्ते 👋';

  @override
  String get loginSubtitle => 'अपने बिज़नेस में लॉगिन करें';

  @override
  String get loginUsername => 'यूज़रनेम';

  @override
  String get loginPassword => 'पासवर्ड';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get loginShowPassword => 'पासवर्ड दिखाएँ';

  @override
  String get loginHidePassword => 'पासवर्ड छुपाएँ';

  @override
  String get loginNoAccountHint => 'अकाउंट नहीं है? अपने मालिक से पूछें।';

  @override
  String get validationUsernameRequired => 'यूज़रनेम लिखें';

  @override
  String get validationUsernameInvalid => 'सिर्फ़ a–z, 0–9, डॉट और अंडरस्कोर चलेगा';

  @override
  String get validationPasswordRequired => 'पासवर्ड लिखें';

  @override
  String get errorInvalidCredentials => 'यूज़रनेम या पासवर्ड गलत है।';

  @override
  String get errorAccountDisabled => 'यह अकाउंट चालू नहीं है। मालिक से संपर्क करें।';

  @override
  String get errorNetwork => 'इंटरनेट कनेक्शन चेक करें।';

  @override
  String get errorTimeout => 'सर्वर जवाब देने में देर कर रहा है। फिर से कोशिश करें।';

  @override
  String get errorServerUnavailable => 'अभी सर्वर नहीं मिल रहा। थोड़ी देर बाद कोशिश करें।';

  @override
  String get errorPermission => 'इस काम की अनुमति नहीं है।';

  @override
  String get errorNotFound => 'यह रिकॉर्ड नहीं मिला।';

  @override
  String get errorAlreadyExists => 'यह रिकॉर्ड पहले से है।';

  @override
  String get errorProductUnavailable => 'यह माल अभी उपलब्ध नहीं है।';

  @override
  String get errorRateChanged => 'रेट बदल गया है। नया रेट देखकर फिर से कन्फ़र्म करें।';

  @override
  String get errorInvalidInput => 'कुछ जानकारी सही नहीं है। चेक करें।';

  @override
  String get errorSessionExpired => 'सेशन खत्म हो गया। फिर से लॉगिन करें।';

  @override
  String get errorMaintenance => 'थोड़ा मेंटेनेंस चल रहा है। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get errorGeneric => 'कुछ गड़बड़ हो गई। फिर से कोशिश करें।';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get notConfiguredTitle => 'सर्वर सेट नहीं है';

  @override
  String get notConfiguredBody => 'इस बिल्ड में सर्वर की जानकारी नहीं है। एडमिन से संपर्क करें।';

  @override
  String greeting(String name) {
    return 'नमस्ते $name 👋';
  }

  @override
  String get homeTodayQuestion => 'आज क्या है?';

  @override
  String get statSalesToday => 'आज की बिक्री';

  @override
  String get statPaymentsToday => 'पेमेंट';

  @override
  String get statTotalBaki => 'कुल बाकी';

  @override
  String get statPendingOrders => 'बाकी ऑर्डर';

  @override
  String get quickActions => 'जल्दी के काम';

  @override
  String get actionOrder => 'ऑर्डर';

  @override
  String get actionPayment => 'पेमेंट';

  @override
  String get actionNewMaal => 'नया माल';

  @override
  String get actionHisaab => 'हिसाब';

  @override
  String newMaalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count नई डिज़ाइन',
      one: '1 नई डिज़ाइन',
      zero: 'कोई नई डिज़ाइन नहीं',
    );
    return '$_temp0';
  }

  @override
  String get comingSoonTitle => 'यह हिस्सा तैयार हो रहा है';

  @override
  String get comingSoonBody => 'आने वाले अपडेट में आएगा।';

  @override
  String get searchHint => 'डिज़ाइन, ग्राहक, ऑर्डर खोजें';

  @override
  String get moreLanguage => 'भाषा';

  @override
  String get moreBusiness => 'बिज़नेस';

  @override
  String get morePrivacy => 'प्राइवेसी पॉलिसी';

  @override
  String get moreTerms => 'नियम और शर्तें';

  @override
  String get moreLogout => 'लॉगआउट';

  @override
  String get roleOwner => 'मालिक';

  @override
  String get roleStaff => 'स्टाफ़';

  @override
  String appVersion(String version) {
    return 'वर्ज़न $version';
  }

  @override
  String get legalDraftNotice => 'ड्राफ़्ट — प्रकाशन से पहले कानूनी जाँच बाकी।';

  @override
  String get unsavedTitle => 'बिना सेव किया काम है।';

  @override
  String get unsavedBody => 'अभी बाहर गए तो यह काम चला जाएगा।';

  @override
  String get unsavedKeepEditing => 'काम जारी रखें';

  @override
  String get unsavedDiscard => 'छोड़ दें';

  @override
  String get feedbackOrderSaved => 'ऑर्डर हो गया';

  @override
  String get feedbackPaymentSaved => 'पेमेंट सेव हुआ';

  @override
  String get feedbackBillReady => 'बिल तैयार';

  @override
  String pieces(int count) {
    return '$count नग';
  }

  @override
  String get loading => 'लोड हो रहा है';
}
