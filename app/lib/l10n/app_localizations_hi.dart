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

  @override
  String get orderNew => 'नया ऑर्डर';

  @override
  String get quickOrder => 'जल्दी ऑर्डर';

  @override
  String get ordersPending => 'बाकी';

  @override
  String get ordersAll => 'सभी';

  @override
  String get ordersEmpty => 'अभी कोई ऑर्डर नहीं।';

  @override
  String get ordersPendingEmpty => 'कोई बाकी ऑर्डर नहीं। सब पूरा!';

  @override
  String piecesCount(int count) {
    return '$count पीस';
  }

  @override
  String get cartChooseCustomer => 'ग्राहक चुनें';

  @override
  String get cartChangeCustomer => 'बदलें';

  @override
  String get cartEmpty => 'माल, रेगुलर माल या डिज़ाइन नंबर से डिज़ाइन जोड़ें।';

  @override
  String get quickAddQty => 'पीस';

  @override
  String quickAddNotFound(String designNo) {
    return '$designNo नंबर की डिज़ाइन नहीं';
  }

  @override
  String quickAddUnavailable(String designNo) {
    return '$designNo अभी उपलब्ध नहीं';
  }

  @override
  String quickAddAdded(String designNo) {
    return '$designNo जुड़ गई';
  }

  @override
  String get cartTotal => 'कुल';

  @override
  String get fieldOrderNote => 'इस ऑर्डर के लिए नोट';

  @override
  String get paymentNow => 'अभी पेमेंट मिला';

  @override
  String get fieldAmount => 'रकम';

  @override
  String get paymentModeCash => 'नकद';

  @override
  String get paymentModeUpi => 'UPI';

  @override
  String get paymentModeBank => 'बैंक';

  @override
  String get paymentModeCheque => 'चेक';

  @override
  String get fieldReference => 'रेफ़रेंस (UPI / चेक नंबर)';

  @override
  String get placeOrder => 'ऑर्डर करें';

  @override
  String orderPlacedTitle(String orderNo) {
    return 'ऑर्डर #$orderNo हो गया';
  }

  @override
  String get orderAlreadyPlaced => 'यह ऑर्डर पहले ही हो गया था — कुछ दो बार नहीं जुड़ा।';

  @override
  String get viewOrder => 'ऑर्डर देखें';

  @override
  String get ratesChangedTitle => 'भाव बदल गए';

  @override
  String get ratesChangedBody => 'आपके जोड़ने के बाद कुछ भाव बदल गए। कार्ट में आज के भाव हैं — जाँचकर फिर ऑर्डर करें।';

  @override
  String get unavailableInCart => 'कुछ डिज़ाइन अभी उपलब्ध नहीं। ऑर्डर के लिए उन्हें हटाएँ।';

  @override
  String get cartNeedsCustomer => 'पहले ग्राहक चुनें।';

  @override
  String get specialRateBadge => 'खास भाव';

  @override
  String get statusConfirmed => 'कन्फ़र्म';

  @override
  String get statusProcessing => 'बन रहा है';

  @override
  String get statusReady => 'तैयार';

  @override
  String get statusCompleted => 'पूरा';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String markAs(String status) {
    return '$status करें';
  }

  @override
  String get cancelOrder => 'ऑर्डर रद्द करें';

  @override
  String get cancelOrderBody => 'ऑर्डर की रकम बाकी से घटेगी। मिला हुआ पेमेंट ग्राहक के जमा में रहेगा।';

  @override
  String get cancelReason => 'कारण (वैकल्पिक)';

  @override
  String get keepOrder => 'ऑर्डर रखें';

  @override
  String orderCreatedBy(String name) {
    return '$name द्वारा';
  }

  @override
  String get orderPayments => 'पेमेंट';

  @override
  String receiptNumber(String paymentNo) {
    return 'रसीद #$paymentNo';
  }

  @override
  String orderCancelledReason(String reason) {
    return 'रद्द: $reason';
  }

  @override
  String get reorderAction => 'फिर से ऑर्डर';

  @override
  String billNumber(String billNo) {
    return 'बिल #$billNo';
  }

  @override
  String get customerPickerTitle => 'ग्राहक चुनें';

  @override
  String get addedToCart => 'ऑर्डर में जोड़ा';

  @override
  String get goToCart => 'ऑर्डर खोलें';

  @override
  String get fieldPaymentMode => 'तरीका';

  @override
  String get qtyLess => 'एक कम';

  @override
  String get qtyMore => 'एक ज़्यादा';

  @override
  String get cartOtherCustomerTitle => 'अधूरा ऑर्डर';

  @override
  String cartOtherCustomerBody(String name, int count) {
    return '$name का $count डिज़ाइन का अधूरा ऑर्डर है। उसकी जगह नया ऑर्डर शुरू करें?';
  }

  @override
  String get cartKeepOld => 'वही रखें';

  @override
  String get cartStartNew => 'नया शुरू करें';

  @override
  String get cartClear => 'ऑर्डर खाली करें';

  @override
  String get hisaabNoPermission => 'आपको हिसाब देखने की अनुमति नहीं है। मालिक से पूछें।';

  @override
  String get hisaabTotalBaki => 'कुल बाकी';

  @override
  String get hisaabAllClear => 'कोई बाकी नहीं। सबने चुका दिया।';

  @override
  String get advanceLabel => 'एडवांस';

  @override
  String get ledgerOpening => 'शुरुआती बाकी';

  @override
  String ledgerOrder(String orderNo) {
    return 'ऑर्डर #$orderNo';
  }

  @override
  String ledgerPayment(String mode) {
    return 'पेमेंट · $mode';
  }

  @override
  String get ledgerAdjustment => 'सुधार';

  @override
  String ledgerReversal(String orderNo) {
    return 'ऑर्डर #$orderNo रद्द';
  }

  @override
  String get ledgerReversalPlain => 'रद्द';

  @override
  String get ledgerEmpty => 'अभी कोई एंट्री नहीं।';

  @override
  String balanceAfter(String amount) {
    return 'बाकी $amount';
  }

  @override
  String get paymentRecord => 'पेमेंट दर्ज करें';

  @override
  String paymentFullBaki(String amount) {
    return 'पूरी बाकी $amount';
  }

  @override
  String paymentBakiAfter(String amount) {
    return 'इसके बाद बाकी: $amount';
  }

  @override
  String paymentAdvanceAfter(String amount) {
    return 'इसके बाद एडवांस: $amount';
  }

  @override
  String get paymentSave => 'पेमेंट सेव करें';

  @override
  String receiptTitle(String paymentNo) {
    return 'रसीद #$paymentNo';
  }

  @override
  String get receiptReceivedFrom => 'इनसे मिले';

  @override
  String get receiptMode => 'तरीका';

  @override
  String get receiptReference => 'रेफ़रेंस';

  @override
  String get receiptDate => 'तारीख';

  @override
  String get receiptBakiBefore => 'पहले की बाकी';

  @override
  String get receiptBakiNow => 'अब की बाकी';

  @override
  String get receiptSend => 'व्हाट्सऐप पर भेजें';

  @override
  String receiptMessage(String amount, String mode, String date, String paymentNo, String baki, String business) {
    return '$date को $mode से $amount मिले। रसीद #$paymentNo। अब बाकी $baki। — $business';
  }

  @override
  String hisaabMessage(String name, String business, String baki, String date) {
    return 'नमस्ते $name, $business में $date तक आपकी बाकी $baki है।';
  }

  @override
  String get hisaabSend => 'हिसाब भेजें';

  @override
  String get adjustAction => 'सुधार';

  @override
  String get adjustTitle => 'बाकी सुधारें';

  @override
  String get adjustAdd => 'बाकी में जोड़ें';

  @override
  String get adjustReduce => 'बाकी कम करें';

  @override
  String get adjustNoteRequired => 'कारण लिखें (हिसाब में दिखेगा)';

  @override
  String get openingAlreadySet => 'इस ग्राहक की शुरुआती बाकी पहले से है।';

  @override
  String get openingSet => 'शुरुआती बाकी डालें';

  @override
  String get paymentAlreadySaved => 'यह पेमेंट पहले से सेव था — कुछ दो बार नहीं जुड़ा।';

  @override
  String get billMake => 'बिल बनाएँ';

  @override
  String get billView => 'बिल देखें';

  @override
  String get billTitle => 'बिल';

  @override
  String get billSendPhoto => 'बिल की फ़ोटो भेजें';

  @override
  String get billSharePdf => 'PDF भेजें';

  @override
  String get billPreparing => 'बिल तैयार हो रहा है…';

  @override
  String get billTo => 'ग्राहक';

  @override
  String get billDate => 'तारीख';

  @override
  String billOrderRef(String orderNo) {
    return 'ऑर्डर #$orderNo';
  }

  @override
  String get billColDesign => 'डिज़ाइन';

  @override
  String get billColQty => 'पीस';

  @override
  String get billColRate => 'भाव';

  @override
  String get billColAmount => 'रकम';

  @override
  String get billTotal => 'कुल';

  @override
  String get billPaid => 'इस ऑर्डर में चुकाए';

  @override
  String get billBakiAfter => 'इस बिल के बाद बाकी';

  @override
  String get billWeight => 'कुल वज़न';

  @override
  String billShareText(String billNo, String business) {
    return '$business की ओर से बिल #$billNo';
  }

  @override
  String get billCancelledOrder => 'रद्द ऑर्डर का बिल नहीं बनता।';

  @override
  String get shareFailed => 'इस फ़ोन पर शेयर नहीं खुला।';
}
