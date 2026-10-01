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

  @override
  String get commonSave => 'सेव करें';

  @override
  String get commonSaved => 'सेव हुआ';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonEdit => 'बदलें';

  @override
  String get commonAdd => 'जोड़ें';

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonClose => 'बंद करें';

  @override
  String get commonRemove => 'हटाएँ';

  @override
  String get commonConfirm => 'कन्फ़र्म करें';

  @override
  String get commonShare => 'शेयर';

  @override
  String get commonWhatsapp => 'WhatsApp';

  @override
  String get commonVaat => 'बात';

  @override
  String get commonOrderKaro => 'ऑर्डर करें';

  @override
  String get commonNotFound => 'यह रिकॉर्ड नहीं मिला।';

  @override
  String get commonPageNotFound => 'यह पेज नहीं है।';

  @override
  String get commonGoHome => 'होम पर जाएँ';

  @override
  String get validationRequired => 'ज़रूरी है';

  @override
  String get validationAmount => 'सही रकम लिखें';

  @override
  String get validationWeight => 'ग्राम में सही वज़न लिखें';

  @override
  String get validationPhone => '10 अंकों का मोबाइल नंबर लिखें';

  @override
  String get validationTooLong => 'बहुत लंबा है';

  @override
  String get productAdd => 'नई डिज़ाइन जोड़ें';

  @override
  String get productEdit => 'डिज़ाइन बदलें';

  @override
  String get productAvailable => 'उपलब्ध';

  @override
  String get productNotAvailable => 'उपलब्ध नहीं';

  @override
  String get productArchived => 'आर्काइव';

  @override
  String get catalogueEmpty => 'अभी माल नहीं है।';

  @override
  String get catalogueEmptyOwnerAction => 'डिज़ाइन जोड़ें';

  @override
  String get fieldDesignNo => 'डिज़ाइन नं.';

  @override
  String get fieldName => 'नाम';

  @override
  String get fieldRate => 'रेट (₹ प्रति नग)';

  @override
  String get fieldWeight => 'वज़न (ग्राम)';

  @override
  String get fieldCategory => 'कैटेगरी';

  @override
  String get fieldNoCategory => 'कोई कैटेगरी नहीं';

  @override
  String get fieldDescription => 'विवरण';

  @override
  String get fieldAvailable => 'ऑर्डर के लिए उपलब्ध';

  @override
  String get ownerOnlySection => 'यह सिर्फ़ आप देख सकते हैं';

  @override
  String get fieldCost => 'लागत (₹)';

  @override
  String get fieldSupplier => 'सप्लायर';

  @override
  String get fieldInternalNote => 'अंदरूनी नोट';

  @override
  String get weightLabel => 'वज़न';

  @override
  String get perPiece => 'प्रति नग';

  @override
  String get photosTitle => 'फ़ोटो';

  @override
  String get photoCamera => 'कैमरा';

  @override
  String get photoGallery => 'गैलरी';

  @override
  String get photoPreparing => 'फ़ोटो तैयार हो रही है…';

  @override
  String get photoRejected => 'यह फ़ाइल फ़ोटो के रूप में नहीं चलेगी।';

  @override
  String get photoTooLarge => 'फ़ोटो बहुत बड़ी है (अधिकतम 25 MB)।';

  @override
  String get photoDuplicate => 'यह फ़ोटो पहले से है।';

  @override
  String get photoAdded => 'फ़ोटो जुड़ गई';

  @override
  String get photoSaveFirst => 'पहले डिज़ाइन सेव करें, फिर फ़ोटो जोड़ें।';

  @override
  String get designNoTaken => 'यह डिज़ाइन नंबर पहले से है।';

  @override
  String get validationDesignNo => 'अक्षर, अंक, - / . _ इस्तेमाल करें (अधिकतम 24)';

  @override
  String get archiveDesign => 'डिज़ाइन आर्काइव करें';

  @override
  String archiveDesignBody(String designNo) {
    return 'डिज़ाइन $designNo माल और नए ऑर्डर से छुप जाएगी। पुराने ऑर्डर और बिल सुरक्षित रहेंगे।';
  }

  @override
  String get unarchiveDesign => 'माल में वापस लाएँ';

  @override
  String get rateNeedsPermission => 'रेट बदलने की अनुमति वाले ही रेट बदल सकते हैं।';

  @override
  String get catalogueAll => 'सब';

  @override
  String get categoryNew => 'नई कैटेगरी';

  @override
  String get searchRecent => 'हाल की खोज';

  @override
  String get searchClearRecent => 'साफ़ करें';

  @override
  String get searchStartHint => 'डिज़ाइन नंबर, ग्राहक का नाम या मोबाइल, या ऑर्डर नंबर से खोजें';

  @override
  String searchNoMatch(String query) {
    return '“$query” के लिए कुछ नहीं मिला';
  }

  @override
  String get searchNoMatchBody => 'स्पेलिंग जाँचें, या डिज़ाइन नंबर या मोबाइल नंबर से खोजें।';

  @override
  String get searchSectionDesigns => 'डिज़ाइन';

  @override
  String get searchSectionCustomers => 'ग्राहक';

  @override
  String get searchSectionOrders => 'ऑर्डर';

  @override
  String orderNumberTitle(String orderNo) {
    return 'ऑर्डर #$orderNo';
  }

  @override
  String get navoMaalSubtitle => 'पिछले 7 दिनों में आया';

  @override
  String get navoMaalEmpty => 'पिछले 7 दिनों में कोई नई डिज़ाइन नहीं।';

  @override
  String get selectToShare => 'चुनकर भेजें';

  @override
  String shareSelected(int count) {
    return '$count भेजें';
  }

  @override
  String selectionLimit(int max) {
    return 'एक साथ अधिकतम $max डिज़ाइन भेज सकते हैं।';
  }

  @override
  String selectionCount(int count) {
    return '$count चुनी गईं';
  }

  @override
  String get customerAdd => 'ग्राहक जोड़ें';

  @override
  String get customerEdit => 'ग्राहक बदलें';

  @override
  String get customersEmpty => 'अभी कोई ग्राहक नहीं।';

  @override
  String customersNoMatch(String query) {
    return '“$query” से कोई ग्राहक नहीं मिला';
  }

  @override
  String get customerSearchHint => 'नाम या मोबाइल से खोजें';

  @override
  String get sortAZ => 'A–Z';

  @override
  String get sortBaki => 'बाकी पहले';

  @override
  String get fieldCustomerName => 'ग्राहक का नाम';

  @override
  String get fieldShopName => 'दुकान का नाम';

  @override
  String get fieldCity => 'शहर';

  @override
  String get fieldMobile => 'मोबाइल';

  @override
  String get fieldWhatsapp => 'व्हाट्सऐप नंबर';

  @override
  String get whatsappSameAsMobile => 'व्हाट्सऐप इसी नंबर पर';

  @override
  String get fieldNotes => 'नोट';

  @override
  String get fieldOpeningBaki => 'शुरुआती बाकी';

  @override
  String get openingBakiHelp => 'इस ग्राहक से पहले से लेने वाले पैसे। केवल एक बार डाल सकते हैं।';

  @override
  String get openingBakiFailed => 'ग्राहक सेव हुआ, पर शुरुआती बाकी नहीं। हिसाब से जोड़ें।';

  @override
  String get actionCall => 'कॉल';

  @override
  String get bakiLabel => 'बाकी';

  @override
  String get openOrdersLabel => 'चालू ऑर्डर';

  @override
  String get totalOrdersLabel => 'ऑर्डर';

  @override
  String get lastOrderLabel => 'आखिरी ऑर्डर';

  @override
  String get regularMaalTitle => 'रेगुलर माल';

  @override
  String get regularMaalEmpty => 'यह ग्राहक जो डिज़ाइन मंगाए, वे यहाँ दिखेंगी।';

  @override
  String regularMaalMeta(int times, int qty) {
    return '$times× · पिछली बार $qty पीस';
  }

  @override
  String get specialRatesTitle => 'खास भाव';

  @override
  String specialRatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count डिज़ाइन',
      one: '1 डिज़ाइन',
      zero: 'कोई नहीं',
    );
    return '$_temp0';
  }

  @override
  String get specialRatesEmpty => 'कोई खास भाव नहीं। यह ग्राहक सामान्य भाव देता है।';

  @override
  String get specialRateAdd => 'खास भाव जोड़ें';

  @override
  String specialRateNormal(String rate) {
    return 'सामान्य $rate';
  }

  @override
  String get specialRateRemove => 'खास भाव हटाएँ';

  @override
  String get designNotFound => 'इस नंबर की कोई डिज़ाइन नहीं।';

  @override
  String get archiveCustomer => 'ग्राहक आर्काइव करें';

  @override
  String archiveCustomerBody(String name) {
    return '$name लिस्ट और नए ऑर्डर से छिप जाएगा। हिसाब और पुराने ऑर्डर सुरक्षित रहेंगे।';
  }

  @override
  String get unarchiveCustomer => 'ग्राहक वापस लाएँ';

  @override
  String get whatsappUnavailable => 'इस फ़ोन पर व्हाट्सऐप नहीं खुला।';

  @override
  String get callUnavailable => 'इस डिवाइस पर कॉल नहीं हो सकता।';

  @override
  String get statusArchived => 'आर्काइव';

  @override
  String get neverLabel => '—';
}
