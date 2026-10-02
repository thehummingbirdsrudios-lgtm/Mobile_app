// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'Vepari';

  @override
  String get navHome => 'હોમ';

  @override
  String get navMaal => 'માલ';

  @override
  String get navOrder => 'ઓર્ડર';

  @override
  String get navCustomer => 'ગ્રાહક';

  @override
  String get navHisaab => 'હિસાબ';

  @override
  String get navMore => 'વધુ';

  @override
  String get loginGreeting => 'નમસ્કાર 👋';

  @override
  String get loginSubtitle => 'તમારા બિઝનેસમાં લોગિન કરો';

  @override
  String get loginUsername => 'યુઝરનેમ';

  @override
  String get loginPassword => 'પાસવર્ડ';

  @override
  String get loginButton => 'લોગિન';

  @override
  String get loginShowPassword => 'પાસવર્ડ બતાવો';

  @override
  String get loginHidePassword => 'પાસવર્ડ છુપાવો';

  @override
  String get loginNoAccountHint => 'એકાઉન્ટ નથી? તમારા માલિકને પૂછો.';

  @override
  String get validationUsernameRequired => 'યુઝરનેમ લખો';

  @override
  String get validationUsernameInvalid => 'ફક્ત a–z, 0–9, ડોટ અને અન્ડરસ્કોર ચાલે';

  @override
  String get validationPasswordRequired => 'પાસવર્ડ લખો';

  @override
  String get errorInvalidCredentials => 'યુઝરનેમ અથવા પાસવર્ડ ખોટો છે.';

  @override
  String get errorAccountDisabled => 'આ એકાઉન્ટ ચાલુ નથી. માલિકનો સંપર્ક કરો.';

  @override
  String get errorNetwork => 'ઇન્ટરનેટ કનેક્શન ચેક કરો.';

  @override
  String get errorTimeout => 'સર્વર જવાબ આપવામાં વાર લગાડે છે. ફરી ટ્રાય કરો.';

  @override
  String get errorServerUnavailable => 'હમણાં સર્વર મળતું નથી. થોડી વાર પછી ટ્રાય કરો.';

  @override
  String get errorPermission => 'આ કામ માટે પરમિશન નથી.';

  @override
  String get errorNotFound => 'આ રેકોર્ડ મળ્યો નથી.';

  @override
  String get errorAlreadyExists => 'આ રેકોર્ડ પહેલેથી છે.';

  @override
  String get errorProductUnavailable => 'આ માલ હવે ઉપલબ્ધ નથી.';

  @override
  String get errorRateChanged => 'રેટ બદલાયો છે. નવો રેટ જોઈને ફરી કન્ફર્મ કરો.';

  @override
  String get errorInvalidInput => 'અમુક માહિતી બરાબર નથી. ચેક કરો.';

  @override
  String get errorSessionExpired => 'સેશન પૂરું થયું. ફરી લોગિન કરો.';

  @override
  String get errorMaintenance => 'થોડું મેન્ટેનન્સ ચાલુ છે. થોડી વાર પછી ફરી ટ્રાય કરો.';

  @override
  String get errorGeneric => 'કંઈક પ્રોબ્લેમ થયો. ફરી ટ્રાય કરો.';

  @override
  String get retry => 'ફરી ટ્રાય કરો';

  @override
  String get notConfiguredTitle => 'સર્વર સેટ નથી';

  @override
  String get notConfiguredBody => 'આ બિલ્ડમાં સર્વરની માહિતી નથી. એડમિનનો સંપર્ક કરો.';

  @override
  String greeting(String name) {
    return 'નમસ્કાર $name 👋';
  }

  @override
  String get homeTodayQuestion => 'આજે શું છે?';

  @override
  String get statSalesToday => 'આજનું વેચાણ';

  @override
  String get statPaymentsToday => 'પેમેન્ટ';

  @override
  String get statTotalBaki => 'કુલ બાકી';

  @override
  String get statPendingOrders => 'બાકી ઓર્ડર';

  @override
  String get quickActions => 'ઝડપી કામ';

  @override
  String get actionOrder => 'ઓર્ડર';

  @override
  String get actionPayment => 'પેમેન્ટ';

  @override
  String get actionNewMaal => 'નવો માલ';

  @override
  String get actionHisaab => 'હિસાબ';

  @override
  String newMaalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count નવી ડિઝાઇન',
      one: '1 નવી ડિઝાઇન',
      zero: 'નવી ડિઝાઇન નથી',
    );
    return '$_temp0';
  }

  @override
  String get comingSoonTitle => 'આ ભાગ તૈયાર થઈ રહ્યો છે';

  @override
  String get comingSoonBody => 'આવતા અપડેટમાં આવશે.';

  @override
  String get searchHint => 'ડિઝાઇન, ગ્રાહક, ઓર્ડર શોધો';

  @override
  String get moreLanguage => 'ભાષા';

  @override
  String get moreBusiness => 'બિઝનેસ';

  @override
  String get morePrivacy => 'પ્રાઇવસી પોલિસી';

  @override
  String get moreTerms => 'નિયમો અને શરતો';

  @override
  String get moreLogout => 'લોગઆઉટ';

  @override
  String get roleOwner => 'માલિક';

  @override
  String get roleStaff => 'સ્ટાફ';

  @override
  String appVersion(String version) {
    return 'વર્ઝન $version';
  }

  @override
  String get legalDraftNotice => 'ડ્રાફ્ટ — પ્રકાશિત કરતાં પહેલાં કાનૂની ચકાસણી બાકી.';

  @override
  String get unsavedTitle => 'સેવ ન થયેલું કામ છે.';

  @override
  String get unsavedBody => 'હમણાં બહાર જશો તો આ કામ જતું રહેશે.';

  @override
  String get unsavedKeepEditing => 'કામ ચાલુ રાખો';

  @override
  String get unsavedDiscard => 'છોડી દો';

  @override
  String get feedbackOrderSaved => 'ઓર્ડર થઈ ગયો';

  @override
  String get feedbackPaymentSaved => 'પેમેન્ટ સેવ થયું';

  @override
  String get feedbackBillReady => 'બિલ તૈયાર';

  @override
  String pieces(int count) {
    return '$count નંગ';
  }

  @override
  String get loading => 'લોડ થાય છે';

  @override
  String get commonSave => 'સેવ કરો';

  @override
  String get commonSaved => 'સેવ થયું';

  @override
  String get commonCancel => 'રદ કરો';

  @override
  String get commonEdit => 'બદલો';

  @override
  String get commonAdd => 'ઉમેરો';

  @override
  String get commonDone => 'થઈ ગયું';

  @override
  String get commonClose => 'બંધ કરો';

  @override
  String get commonRemove => 'કાઢી નાખો';

  @override
  String get commonConfirm => 'કન્ફર્મ કરો';

  @override
  String get commonShare => 'શેર';

  @override
  String get commonWhatsapp => 'WhatsApp';

  @override
  String get commonVaat => 'વાત';

  @override
  String get commonOrderKaro => 'ઓર્ડર કરો';

  @override
  String get commonNotFound => 'આ રેકોર્ડ મળ્યો નથી.';

  @override
  String get commonPageNotFound => 'આ પેજ નથી.';

  @override
  String get commonGoHome => 'હોમ પર જાઓ';

  @override
  String get validationRequired => 'જરૂરી છે';

  @override
  String get validationAmount => 'સાચી રકમ લખો';

  @override
  String get validationWeight => 'ગ્રામમાં સાચું વજન લખો';

  @override
  String get validationPhone => '10 આંકડાનો મોબાઇલ નંબર લખો';

  @override
  String get validationTooLong => 'બહુ લાંબું છે';

  @override
  String get productAdd => 'નવી ડિઝાઇન ઉમેરો';

  @override
  String get productEdit => 'ડિઝાઇન બદલો';

  @override
  String get productAvailable => 'ઉપલબ્ધ';

  @override
  String get productNotAvailable => 'ઉપલબ્ધ નથી';

  @override
  String get productArchived => 'આર્કાઇવ';

  @override
  String get catalogueEmpty => 'હજુ માલ નથી.';

  @override
  String get catalogueEmptyOwnerAction => 'ડિઝાઇન ઉમેરો';

  @override
  String get fieldDesignNo => 'ડિઝાઇન નં.';

  @override
  String get fieldName => 'નામ';

  @override
  String get fieldRate => 'રેટ (₹ પ્રતિ નંગ)';

  @override
  String get fieldWeight => 'વજન (ગ્રામ)';

  @override
  String get fieldCategory => 'કેટેગરી';

  @override
  String get fieldNoCategory => 'કેટેગરી નથી';

  @override
  String get fieldDescription => 'વિગત';

  @override
  String get fieldAvailable => 'ઓર્ડર માટે ઉપલબ્ધ';

  @override
  String get ownerOnlySection => 'આ ફક્ત તમે જોઈ શકો છો';

  @override
  String get fieldCost => 'પડતર (₹)';

  @override
  String get fieldSupplier => 'સપ્લાયર';

  @override
  String get fieldInternalNote => 'અંદરની નોંધ';

  @override
  String get weightLabel => 'વજન';

  @override
  String get perPiece => 'પ્રતિ નંગ';

  @override
  String get photosTitle => 'ફોટા';

  @override
  String get photoCamera => 'કેમેરા';

  @override
  String get photoGallery => 'ગેલેરી';

  @override
  String get photoPreparing => 'ફોટો તૈયાર થાય છે…';

  @override
  String get photoRejected => 'આ ફાઇલ ફોટો તરીકે ચાલે એમ નથી.';

  @override
  String get photoTooLarge => 'ફોટો બહુ મોટો છે (વધુમાં વધુ 25 MB).';

  @override
  String get photoDuplicate => 'આ ફોટો પહેલેથી છે.';

  @override
  String get photoAdded => 'ફોટો ઉમેરાયો';

  @override
  String get photoSaveFirst => 'પહેલાં ડિઝાઇન સેવ કરો, પછી ફોટા ઉમેરો.';

  @override
  String get designNoTaken => 'આ ડિઝાઇન નંબર પહેલેથી છે.';

  @override
  String get validationDesignNo => 'અક્ષર, આંકડા, - / . _ વાપરો (વધુમાં વધુ 24)';

  @override
  String get archiveDesign => 'ડિઝાઇન આર્કાઇવ કરો';

  @override
  String archiveDesignBody(String designNo) {
    return 'ડિઝાઇન $designNo માલ અને નવા ઓર્ડરમાંથી છુપાઈ જશે. જૂના ઓર્ડર અને બિલ સલામત રહેશે.';
  }

  @override
  String get unarchiveDesign => 'માલમાં પાછી લાવો';

  @override
  String get rateNeedsPermission => 'રેટ બદલવાની પરમિશન વાળા જ રેટ બદલી શકે.';

  @override
  String get catalogueAll => 'બધું';

  @override
  String get categoryNew => 'નવી કેટેગરી';

  @override
  String get searchRecent => 'તાજેતરની શોધ';

  @override
  String get searchClearRecent => 'સાફ કરો';

  @override
  String get searchStartHint => 'ડિઝાઇન નંબર, ગ્રાહકનું નામ કે મોબાઇલ, અથવા ઓર્ડર નંબરથી શોધો';

  @override
  String searchNoMatch(String query) {
    return '“$query” માટે કંઈ મળ્યું નથી';
  }

  @override
  String get searchNoMatchBody => 'સ્પેલિંગ તપાસો, અથવા ડિઝાઇન નંબર કે મોબાઇલ નંબરથી શોધો.';

  @override
  String get searchSectionDesigns => 'ડિઝાઇન';

  @override
  String get searchSectionCustomers => 'ગ્રાહકો';

  @override
  String get searchSectionOrders => 'ઓર્ડર';

  @override
  String orderNumberTitle(String orderNo) {
    return 'ઓર્ડર #$orderNo';
  }

  @override
  String get navoMaalSubtitle => 'છેલ્લા 7 દિવસમાં આવેલો';

  @override
  String get navoMaalEmpty => 'છેલ્લા 7 દિવસમાં કોઈ નવી ડિઝાઇન નથી.';

  @override
  String get selectToShare => 'પસંદ કરીને મોકલો';

  @override
  String shareSelected(int count) {
    return '$count મોકલો';
  }

  @override
  String selectionLimit(int max) {
    return 'એક સાથે વધુમાં વધુ $max ડિઝાઇન મોકલી શકાય.';
  }

  @override
  String selectionCount(int count) {
    return '$count પસંદ કરી';
  }

  @override
  String get customerAdd => 'ગ્રાહક ઉમેરો';

  @override
  String get customerEdit => 'ગ્રાહક બદલો';

  @override
  String get customersEmpty => 'હજી કોઈ ગ્રાહક નથી.';

  @override
  String customersNoMatch(String query) {
    return '“$query” નામનો કોઈ ગ્રાહક નથી';
  }

  @override
  String get customerSearchHint => 'નામ કે મોબાઇલથી શોધો';

  @override
  String get sortAZ => 'A–Z';

  @override
  String get sortBaki => 'બાકી પહેલા';

  @override
  String get fieldCustomerName => 'ગ્રાહકનું નામ';

  @override
  String get fieldShopName => 'દુકાનનું નામ';

  @override
  String get fieldCity => 'શહેર';

  @override
  String get fieldMobile => 'મોબાઇલ';

  @override
  String get fieldWhatsapp => 'વોટ્સએપ નંબર';

  @override
  String get whatsappSameAsMobile => 'વોટ્સએપ આ જ નંબર પર';

  @override
  String get fieldNotes => 'નોંધ';

  @override
  String get fieldOpeningBaki => 'શરૂઆતની બાકી';

  @override
  String get openingBakiHelp => 'આ ગ્રાહક પાસે પહેલેથી લેવાના પૈસા. ફક્ત એક જ વાર નાખી શકાય.';

  @override
  String get openingBakiFailed => 'ગ્રાહક સેવ થયો, પણ શરૂઆતની બાકી નહીં. હિસાબમાંથી ઉમેરો.';

  @override
  String get actionCall => 'કૉલ';

  @override
  String get bakiLabel => 'બાકી';

  @override
  String get openOrdersLabel => 'ચાલુ ઓર્ડર';

  @override
  String get totalOrdersLabel => 'ઓર્ડર';

  @override
  String get lastOrderLabel => 'છેલ્લો ઓર્ડર';

  @override
  String get regularMaalTitle => 'રેગ્યુલર માલ';

  @override
  String get regularMaalEmpty => 'આ ગ્રાહક જે ડિઝાઇન મંગાવે તે અહીં દેખાશે.';

  @override
  String regularMaalMeta(int times, int qty) {
    return '$times× · છેલ્લે $qty નંગ';
  }

  @override
  String get specialRatesTitle => 'ખાસ ભાવ';

  @override
  String specialRatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ડિઝાઇન',
      one: '1 ડિઝાઇન',
      zero: 'કોઈ નહીં',
    );
    return '$_temp0';
  }

  @override
  String get specialRatesEmpty => 'કોઈ ખાસ ભાવ નથી. આ ગ્રાહક સામાન્ય ભાવ ચૂકવે છે.';

  @override
  String get specialRateAdd => 'ખાસ ભાવ ઉમેરો';

  @override
  String specialRateNormal(String rate) {
    return 'સામાન્ય $rate';
  }

  @override
  String get specialRateRemove => 'ખાસ ભાવ કાઢો';

  @override
  String get designNotFound => 'આ નંબરની કોઈ ડિઝાઇન નથી.';

  @override
  String get archiveCustomer => 'ગ્રાહક આર્કાઇવ કરો';

  @override
  String archiveCustomerBody(String name) {
    return '$name લિસ્ટ અને નવા ઓર્ડરમાંથી છુપાશે. હિસાબ અને જૂના ઓર્ડર સુરક્ષિત રહેશે.';
  }

  @override
  String get unarchiveCustomer => 'ગ્રાહક પાછો લાવો';

  @override
  String get whatsappUnavailable => 'આ ફોનમાં વોટ્સએપ ખૂલ્યું નહીં.';

  @override
  String get callUnavailable => 'આ ડિવાઇસ પર કૉલ થઈ શકતો નથી.';

  @override
  String get statusArchived => 'આર્કાઇવ';

  @override
  String get neverLabel => '—';

  @override
  String get orderNew => 'નવો ઓર્ડર';

  @override
  String get quickOrder => 'ઝડપી ઓર્ડર';

  @override
  String get ordersPending => 'બાકી';

  @override
  String get ordersAll => 'બધા';

  @override
  String get ordersEmpty => 'હજી કોઈ ઓર્ડર નથી.';

  @override
  String get ordersPendingEmpty => 'કોઈ બાકી ઓર્ડર નથી. બધું પૂરું!';

  @override
  String piecesCount(int count) {
    return '$count નંગ';
  }

  @override
  String get cartChooseCustomer => 'ગ્રાહક પસંદ કરો';

  @override
  String get cartChangeCustomer => 'બદલો';

  @override
  String get cartEmpty => 'માલ, રેગ્યુલર માલ કે ડિઝાઇન નંબરથી ડિઝાઇન ઉમેરો.';

  @override
  String get quickAddQty => 'નંગ';

  @override
  String quickAddNotFound(String designNo) {
    return '$designNo નંબરની ડિઝાઇન નથી';
  }

  @override
  String quickAddUnavailable(String designNo) {
    return '$designNo હાલ મળતી નથી';
  }

  @override
  String quickAddAdded(String designNo) {
    return '$designNo ઉમેરાઈ';
  }

  @override
  String get cartTotal => 'કુલ';

  @override
  String get fieldOrderNote => 'આ ઓર્ડર માટે નોંધ';

  @override
  String get paymentNow => 'હમણાં પેમેન્ટ મળ્યું';

  @override
  String get fieldAmount => 'રકમ';

  @override
  String get paymentModeCash => 'રોકડ';

  @override
  String get paymentModeUpi => 'UPI';

  @override
  String get paymentModeBank => 'બેંક';

  @override
  String get paymentModeCheque => 'ચેક';

  @override
  String get fieldReference => 'રેફરન્સ (UPI / ચેક નંબર)';

  @override
  String get placeOrder => 'ઓર્ડર કરો';

  @override
  String orderPlacedTitle(String orderNo) {
    return 'ઓર્ડર #$orderNo થઈ ગયો';
  }

  @override
  String get orderAlreadyPlaced => 'આ ઓર્ડર પહેલેથી થઈ ગયો હતો — કંઈ બે વાર ઉમેરાયું નથી.';

  @override
  String get viewOrder => 'ઓર્ડર જુઓ';

  @override
  String get ratesChangedTitle => 'ભાવ બદલાયા';

  @override
  String get ratesChangedBody => 'તમે ઉમેર્યા પછી કેટલાક ભાવ બદલાયા છે. કાર્ટમાં આજના ભાવ છે — તપાસીને ફરી ઓર્ડર કરો.';

  @override
  String get unavailableInCart => 'કેટલીક ડિઝાઇન હાલ મળતી નથી. ઓર્ડર માટે તેને કાઢો.';

  @override
  String get cartNeedsCustomer => 'પહેલા ગ્રાહક પસંદ કરો.';

  @override
  String get specialRateBadge => 'ખાસ ભાવ';

  @override
  String get statusConfirmed => 'કન્ફર્મ';

  @override
  String get statusProcessing => 'બની રહ્યો છે';

  @override
  String get statusReady => 'તૈયાર';

  @override
  String get statusCompleted => 'પૂરો';

  @override
  String get statusCancelled => 'રદ';

  @override
  String markAs(String status) {
    return '$status કરો';
  }

  @override
  String get cancelOrder => 'ઓર્ડર રદ કરો';

  @override
  String get cancelOrderBody => 'ઓર્ડરની રકમ બાકીમાંથી ઓછી થશે. મળેલું પેમેન્ટ ગ્રાહકની જમા રહેશે.';

  @override
  String get cancelReason => 'કારણ (વૈકલ્પિક)';

  @override
  String get keepOrder => 'ઓર્ડર રાખો';

  @override
  String orderCreatedBy(String name) {
    return '$name દ્વારા';
  }

  @override
  String get orderPayments => 'પેમેન્ટ';

  @override
  String receiptNumber(String paymentNo) {
    return 'રસીદ #$paymentNo';
  }

  @override
  String orderCancelledReason(String reason) {
    return 'રદ: $reason';
  }

  @override
  String get reorderAction => 'ફરી ઓર્ડર';

  @override
  String billNumber(String billNo) {
    return 'બિલ #$billNo';
  }

  @override
  String get customerPickerTitle => 'ગ્રાહક પસંદ કરો';

  @override
  String get addedToCart => 'ઓર્ડરમાં ઉમેર્યું';

  @override
  String get goToCart => 'ઓર્ડર ખોલો';

  @override
  String get fieldPaymentMode => 'રીત';

  @override
  String get qtyLess => 'એક ઓછું';

  @override
  String get qtyMore => 'એક વધારે';

  @override
  String get cartOtherCustomerTitle => 'અધૂરો ઓર્ડર';

  @override
  String cartOtherCustomerBody(String name, int count) {
    return '$name નો $count ડિઝાઇનનો અધૂરો ઓર્ડર છે. તેના બદલે નવો ઓર્ડર શરૂ કરવો છે?';
  }

  @override
  String get cartKeepOld => 'એ રાખો';

  @override
  String get cartStartNew => 'નવો શરૂ કરો';

  @override
  String get cartClear => 'ઓર્ડર ખાલી કરો';

  @override
  String get hisaabNoPermission => 'તમને હિસાબ જોવાની પરવાનગી નથી. માલિકને પૂછો.';

  @override
  String get hisaabTotalBaki => 'કુલ બાકી';

  @override
  String get hisaabAllClear => 'કોઈ બાકી નથી. બધાએ ચૂકવી દીધું.';

  @override
  String get advanceLabel => 'એડવાન્સ';

  @override
  String get ledgerOpening => 'શરૂઆતની બાકી';

  @override
  String ledgerOrder(String orderNo) {
    return 'ઓર્ડર #$orderNo';
  }

  @override
  String ledgerPayment(String mode) {
    return 'પેમેન્ટ · $mode';
  }

  @override
  String get ledgerAdjustment => 'સુધારો';

  @override
  String ledgerReversal(String orderNo) {
    return 'ઓર્ડર #$orderNo રદ';
  }

  @override
  String get ledgerReversalPlain => 'રદ';

  @override
  String get ledgerEmpty => 'હજી કોઈ એન્ટ્રી નથી.';

  @override
  String balanceAfter(String amount) {
    return 'બાકી $amount';
  }

  @override
  String get paymentRecord => 'પેમેન્ટ નોંધો';

  @override
  String paymentFullBaki(String amount) {
    return 'પૂરી બાકી $amount';
  }

  @override
  String paymentBakiAfter(String amount) {
    return 'આ પછી બાકી: $amount';
  }

  @override
  String paymentAdvanceAfter(String amount) {
    return 'આ પછી એડવાન્સ: $amount';
  }

  @override
  String get paymentSave => 'પેમેન્ટ સેવ કરો';

  @override
  String receiptTitle(String paymentNo) {
    return 'રસીદ #$paymentNo';
  }

  @override
  String get receiptReceivedFrom => 'આમની પાસેથી મળ્યા';

  @override
  String get receiptMode => 'રીત';

  @override
  String get receiptReference => 'રેફરન્સ';

  @override
  String get receiptDate => 'તારીખ';

  @override
  String get receiptBakiBefore => 'પહેલાની બાકી';

  @override
  String get receiptBakiNow => 'હવેની બાકી';

  @override
  String get receiptSend => 'વોટ્સએપ પર મોકલો';

  @override
  String receiptMessage(String amount, String mode, String date, String paymentNo, String baki, String business) {
    return '$date ના રોજ $mode થી $amount મળ્યા. રસીદ #$paymentNo. હવે બાકી $baki. — $business';
  }

  @override
  String hisaabMessage(String name, String business, String baki, String date) {
    return 'નમસ્તે $name, $business માં $date સુધી તમારી બાકી $baki છે.';
  }

  @override
  String get hisaabSend => 'હિસાબ મોકલો';

  @override
  String get adjustAction => 'સુધારો';

  @override
  String get adjustTitle => 'બાકી સુધારો';

  @override
  String get adjustAdd => 'બાકીમાં ઉમેરો';

  @override
  String get adjustReduce => 'બાકી ઓછી કરો';

  @override
  String get adjustNoteRequired => 'કારણ લખો (હિસાબમાં દેખાશે)';

  @override
  String get openingAlreadySet => 'આ ગ્રાહકની શરૂઆતની બાકી પહેલેથી છે.';

  @override
  String get openingSet => 'શરૂઆતની બાકી નાખો';

  @override
  String get paymentAlreadySaved => 'આ પેમેન્ટ પહેલેથી સેવ હતું — કંઈ બે વાર ઉમેરાયું નથી.';

  @override
  String get billMake => 'બિલ બનાવો';

  @override
  String get billView => 'બિલ જુઓ';

  @override
  String get billTitle => 'બિલ';

  @override
  String get billSendPhoto => 'બિલનો ફોટો મોકલો';

  @override
  String get billSharePdf => 'PDF મોકલો';

  @override
  String get billPreparing => 'બિલ તૈયાર થાય છે…';

  @override
  String get billTo => 'ગ્રાહક';

  @override
  String get billDate => 'તારીખ';

  @override
  String billOrderRef(String orderNo) {
    return 'ઓર્ડર #$orderNo';
  }

  @override
  String get billColDesign => 'ડિઝાઇન';

  @override
  String get billColQty => 'નંગ';

  @override
  String get billColRate => 'ભાવ';

  @override
  String get billColAmount => 'રકમ';

  @override
  String get billTotal => 'કુલ';

  @override
  String get billPaid => 'આ ઓર્ડરમાં ચૂકવ્યા';

  @override
  String get billBakiAfter => 'આ બિલ પછી બાકી';

  @override
  String get billWeight => 'કુલ વજન';

  @override
  String billShareText(String billNo, String business) {
    return '$business તરફથી બિલ #$billNo';
  }

  @override
  String get billCancelledOrder => 'રદ ઓર્ડરનું બિલ ન બને.';

  @override
  String get shareFailed => 'આ ફોનમાં શેર ખૂલ્યું નહીં.';

  @override
  String get shareDesignsTitle => 'ડિઝાઇન મોકલો';

  @override
  String get shareShowRate => 'ભાવ બતાવો';

  @override
  String get shareAddWatermark => 'ફોટા પર દુકાનનું નામ';

  @override
  String sharePreparing(int count) {
    return '$count ફોટા તૈયાર થાય છે…';
  }

  @override
  String shareRateLine(String rate) {
    return '$rate પ્રતિ નંગ';
  }

  @override
  String shareContactLine(String phone) {
    return 'વોટ્સએપ $phone';
  }

  @override
  String get shareNoPhotos => 'આ ડિઝાઇનના ફોટા નથી; ફક્ત લખાણ મોકલાશે.';

  @override
  String get receiptSharePhoto => 'રસીદનો ફોટો મોકલો';

  @override
  String orderShareHeader(String orderNo, String date) {
    return 'ઓર્ડર #$orderNo · $date';
  }

  @override
  String get vaatHint => 'નોંધ લખો…';

  @override
  String get vaatEmpty => 'હજી કોઈ વાત નથી. નોંધ, અવાજ કે ફોટો ઉમેરો.';

  @override
  String get vaatSend => 'મોકલો';

  @override
  String get vaatRecord => 'અવાજ રેકોર્ડ કરો';

  @override
  String vaatRecording(String time) {
    return 'રેકોર્ડિંગ $time';
  }

  @override
  String get vaatTooShort => 'બહુ ટૂંકું. થોડું વધુ બોલો.';

  @override
  String get vaatMicDenied => 'અવાજ રેકોર્ડ કરવા માઇક્રોફોનની પરવાનગી આપો.';

  @override
  String get vaatAddPhoto => 'ફોટો ઉમેરો';

  @override
  String get vaatYou => 'તમે';

  @override
  String get vaatPlay => 'વગાડો';

  @override
  String get vaatStop => 'બંધ કરો';

  @override
  String get vaatRemove => 'નોંધ કાઢો';

  @override
  String get billColPhoto => 'ફોટો';

  @override
  String get billContinued => 'ચાલુ';

  @override
  String billPdfPreparing(int count) {
    return '$count ફોટા સાથે PDF તૈયાર થાય છે…';
  }

  @override
  String get billColItem => 'વસ્તુ';

  @override
  String get adminSection => 'ધંધાનું સેટિંગ';

  @override
  String get adminBusinessProfile => 'ધંધાની માહિતી';

  @override
  String get adminBusinessProfileHint => 'નામ, ફોન, GSTIN, લોગો, બિલ નોંધ';

  @override
  String get adminStaff => 'સ્ટાફ';

  @override
  String get adminStaffHint => 'લોગિન અને પરવાનગી';

  @override
  String get adminAudit => 'પ્રવૃત્તિ લોગ';

  @override
  String get adminAuditHint => 'કોણે શું ક્યારે બદલ્યું';

  @override
  String get adminOwnerOnly => 'આ ફક્ત માલિક ખોલી શકે.';

  @override
  String get fieldBusinessName => 'ધંધાનું નામ';

  @override
  String get fieldAddress => 'સરનામું';

  @override
  String get fieldGstin => 'GSTIN (વૈકલ્પિક)';

  @override
  String get fieldBillFooter => 'બિલની નીચે નોંધ';

  @override
  String get validationGstin => 'GSTIN માં 15 અક્ષર-અંક હોય છે';

  @override
  String get profileWatermark => 'શેર કરેલા ફોટા પર વોટરમાર્ક';

  @override
  String get profileWatermarkHint => 'મોકલેલા ફોટા પર તમારા ધંધાનું નામ';

  @override
  String get profileDefaultLanguage => 'નવા સ્ટાફના ફોનની ભાષા';

  @override
  String get profileLogo => 'લોગો';

  @override
  String get profileLogoHint => 'બિલ પર છપાય છે';

  @override
  String get profileLogoAdd => 'લોગો ઉમેરો';

  @override
  String get profileLogoChange => 'લોગો બદલો';

  @override
  String get profileLogoRemove => 'લોગો કાઢો';

  @override
  String get profileLogoSaved => 'લોગો બદલાયો';

  @override
  String get profileLogoRemoved => 'લોગો કાઢ્યો';

  @override
  String get staffAdd => 'સ્ટાફ ઉમેરો';

  @override
  String get staffEmpty => 'હજી કોઈ સ્ટાફ નથી';

  @override
  String get staffEmptyBody => 'તમારી સાથે કામ કરતી દરેક વ્યક્તિ માટે લોગિન બનાવો.';

  @override
  String get staffActive => 'ચાલુ';

  @override
  String get staffInactive => 'બંધ';

  @override
  String staffPermissionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count પરવાનગી',
      zero: 'કોઈ વધારાની પરવાનગી નથી',
    );
    return '$_temp0';
  }

  @override
  String get staffAccess => 'લોગિન કરી શકે';

  @override
  String get staffAccessHint => 'બંધ કરશો તો તરત જ ઍક્સેસ બંધ થશે';

  @override
  String staffDeactivateTitle(String name) {
    return '$nameનું ઍક્સેસ બંધ કરવું છે?';
  }

  @override
  String get staffDeactivateBody =>
      'તેમની આગળની કોઈ પણ ક્રિયા પર તેઓ લોગઆઉટ થશે અને તમે ફરી ચાલુ ન કરો ત્યાં સુધી લોગિન નહીં કરી શકે. તેમનું જૂનું કામ રહેશે.';

  @override
  String get staffDeactivate => 'ઍક્સેસ બંધ કરો';

  @override
  String get staffAccessStopped => 'ઍક્સેસ બંધ કર્યું';

  @override
  String get staffAccessRestored => 'ઍક્સેસ ફરી ચાલુ કર્યું';

  @override
  String get staffPermissions => 'પરવાનગી';

  @override
  String get staffPermissionsHint => 'બધા માલ, ગ્રાહક અને ઓર્ડર જોઈ શકે. દરેકને જરૂર હોય એટલું જ આપો.';

  @override
  String get staffSavePermissions => 'પરવાનગી સાચવો';

  @override
  String get staffOwnerHasAll => 'માલિક પાસે બધી પરવાનગી છે.';

  @override
  String get staffResetPassword => 'નવો પાસવર્ડ રાખો';

  @override
  String staffResetPasswordBody(String name) {
    return '$name માટે નવો પાસવર્ડ રાખો, પછી તેમને રૂબરૂ જણાવો.';
  }

  @override
  String get staffPasswordChanged => 'પાસવર્ડ બદલાયો';

  @override
  String get fieldNewPassword => 'નવો પાસવર્ડ';

  @override
  String get fieldPersonName => 'પૂરું નામ';

  @override
  String get validationPasswordShort => 'ઓછામાં ઓછા 8 અક્ષર';

  @override
  String get validationPasswordLong => 'બહુ લાંબો — ટૂંકો પાસવર્ડ રાખો';

  @override
  String get validationPasswordSameAsUsername => 'યુઝરનેમ જેવો ન હોવો જોઈએ';

  @override
  String get staffNewTitle => 'નવું સ્ટાફ લોગિન';

  @override
  String get staffUsernameHint => 'નાના અક્ષર, અંક, ડોટ કે અંડરસ્કોર. આનાથી લોગિન કરશે.';

  @override
  String get staffPasswordHint => 'આ પાસવર્ડ તેમને રૂબરૂ જણાવો. ગમે ત્યારે નવો રાખી શકાય.';

  @override
  String get staffCreate => 'લોગિન બનાવો';

  @override
  String staffCreated(String name) {
    return '$name હવે લોગિન કરી શકે છે';
  }

  @override
  String get staffUsernameTaken => 'આ યુઝરનેમ લેવાઈ ગયું છે. બીજું અજમાવો.';

  @override
  String get permCatalogueManage => 'માલ ઉમેરો અને બદલો';

  @override
  String get permRatesManage => 'ભાવ બદલો';

  @override
  String get permCustomersManage => 'ગ્રાહક ઉમેરો અને બદલો';

  @override
  String get permOrdersCreate => 'ઓર્ડર લો';

  @override
  String get permOrdersManage => 'ઓર્ડર આગળ વધારો અને રદ કરો';

  @override
  String get permPaymentsRecord => 'પેમેન્ટ નોંધો';

  @override
  String get permHisaabView => 'હિસાબ અને બાકી જુઓ';

  @override
  String get permHisaabAdjust => 'શરૂઆતની બાકી અને સુધારા';

  @override
  String get permBillsIssue => 'બિલ બનાવો';

  @override
  String get permReportsView => 'રિપોર્ટ જુઓ';

  @override
  String get auditEmpty => 'હજી કોઈ પ્રવૃત્તિ નથી';

  @override
  String get auditSystem => 'સિસ્ટમ';

  @override
  String get auditOrderCreated => 'ઓર્ડર લીધો';

  @override
  String get auditOrderStatus => 'ઓર્ડર આગળ વધ્યો';

  @override
  String get auditOrderCancelled => 'ઓર્ડર રદ થયો';

  @override
  String get auditPaymentRecorded => 'પેમેન્ટ નોંધાયું';

  @override
  String get auditBillIssued => 'બિલ બન્યું';

  @override
  String get auditLedgerOpening => 'શરૂઆતની બાકી નોંધાઈ';

  @override
  String get auditLedgerAdjustment => 'હિસાબ સુધાર્યો';

  @override
  String get auditStaffCreated => 'સ્ટાફ લોગિન બન્યું';

  @override
  String get auditStaffPasswordReset => 'સ્ટાફનો પાસવર્ડ બદલાયો';

  @override
  String auditPermissionGranted(String permission) {
    return 'પરવાનગી આપી: $permission';
  }

  @override
  String auditPermissionRevoked(String permission) {
    return 'પરવાનગી પાછી લીધી: $permission';
  }

  @override
  String auditRateChanged(String from, String to) {
    return 'ભાવ બદલાયો $from → $to';
  }

  @override
  String auditAdded(String thing) {
    return '$thing ઉમેર્યું';
  }

  @override
  String auditChanged(String thing) {
    return '$thing બદલાયું';
  }

  @override
  String auditRemoved(String thing) {
    return '$thing કાઢ્યું';
  }

  @override
  String get auditEntityProduct => 'ડિઝાઇન';

  @override
  String get auditEntityCost => 'ખર્ચની વિગત';

  @override
  String get auditEntityCustomer => 'ગ્રાહક';

  @override
  String get auditEntityCustomerRate => 'ગ્રાહકનો ભાવ';

  @override
  String get auditEntityMember => 'સ્ટાફ સભ્ય';

  @override
  String get auditEntityRecord => 'રેકોર્ડ';

  @override
  String get notificationsTitle => 'સૂચનાઓ';

  @override
  String get notificationsEmpty => 'બધું જોઈ લીધું છે';

  @override
  String get notificationsEmptyBody => 'તમારા માટે નવો માલ, ઓર્ડર અને પેમેન્ટ અહીં દેખાશે.';

  @override
  String get notificationsMarkAll => 'બધું વાંચ્યું';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count નવી સૂચના');
    return '$_temp0';
  }

  @override
  String notifNewMaal(String design) {
    return 'નવો માલ: $design';
  }

  @override
  String notifOrderCreated(String orderNo, String customer) {
    return 'નવો ઓર્ડર #$orderNo · $customer';
  }

  @override
  String notifOrderStatus(String orderNo, String status) {
    return 'ઓર્ડર #$orderNo: $status';
  }

  @override
  String notifPayment(String amount, String customer) {
    return '$customer તરફથી $amount પેમેન્ટ';
  }

  @override
  String get notifOther => 'અપડેટ';

  @override
  String get adminExport => 'ડેટા એક્સપોર્ટ';

  @override
  String get adminExportHint => 'ગ્રાહક, હિસાબ, ઓર્ડર અને ડિઝાઇન સ્પ્રેડશીટમાં';

  @override
  String get exportWhat => 'શું એક્સપોર્ટ કરવું';

  @override
  String get exportPeriod => 'સમયગાળો';

  @override
  String get exportKindCustomers => 'ગ્રાહક અને બાકી';

  @override
  String get exportKindDesigns => 'ખર્ચ સાથે ડિઝાઇન';

  @override
  String get exportKindLedger => 'હિસાબની એન્ટ્રી';

  @override
  String get exportKindOrders => 'ઓર્ડર';

  @override
  String get exportKindOrderLines => 'ઓર્ડરની લાઇન (દરેક ડિઝાઇન)';

  @override
  String get exportPeriodThisMonth => 'આ મહિનો';

  @override
  String get exportPeriodLastMonth => 'ગયો મહિનો';

  @override
  String get exportPeriodLast3Months => 'છેલ્લા 3 મહિના';

  @override
  String get exportPeriodThisYear => 'આ વર્ષ';

  @override
  String get exportPeriodCustom => 'તારીખ પસંદ કરો';

  @override
  String exportPeriodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get exportCostWarning => 'આ ફાઇલમાં તમારા ખર્ચના ભાવ અને સપ્લાયર છે. ફક્ત વિશ્વાસુ લોકો સાથે જ શેર કરો.';

  @override
  String get exportButton => 'CSV એક્સપોર્ટ કરો';

  @override
  String exportReading(String count) {
    return 'વાંચે છે… $count લાઇન';
  }

  @override
  String exportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count લાઇન એક્સપોર્ટ થઈ',
      zero: 'આ સમયગાળામાં કંઈ નથી',
    );
    return '$_temp0';
  }

  @override
  String get exportTooLarge => 'એક ફાઇલ માટે બહુ વધારે. ટૂંકો સમયગાળો પસંદ કરો.';

  @override
  String get exportShareFailed => 'આ ફોન પર શેર થઈ શકતું નથી.';

  @override
  String get exportYes => 'હા';

  @override
  String get exportNo => 'ના';

  @override
  String get exportEntryOrder => 'ઓર્ડર';

  @override
  String get exportEntryPayment => 'પેમેન્ટ';

  @override
  String get colCustomer => 'ગ્રાહક';

  @override
  String get colShop => 'દુકાન';

  @override
  String get colCity => 'શહેર';

  @override
  String get colPhone => 'મોબાઇલ';

  @override
  String get colWhatsapp => 'વોટ્સએપ';

  @override
  String get colBaki => 'બાકી (₹)';

  @override
  String get colArchived => 'આર્કાઇવ';

  @override
  String get colCreatedAt => 'ઉમેર્યાની તારીખ';

  @override
  String get colDesignNo => 'ડિઝાઇન નં.';

  @override
  String get colProduct => 'નામ';

  @override
  String get colCategory => 'કેટેગરી';

  @override
  String get colRate => 'ભાવ (₹)';

  @override
  String get colWeight => 'વજન (ગ્રામ)';

  @override
  String get colAvailable => 'ઉપલબ્ધ';

  @override
  String get colPublishedAt => 'મૂક્યાની તારીખ';

  @override
  String get colCost => 'ખર્ચ (₹, ફક્ત માલિક)';

  @override
  String get colSupplier => 'સપ્લાયર (ફક્ત માલિક)';

  @override
  String get colDate => 'તારીખ';

  @override
  String get colEntryKind => 'એન્ટ્રી';

  @override
  String get colAmount => 'રકમ (₹)';

  @override
  String get colBalanceAfter => 'પછીની બાકી (₹)';

  @override
  String get colOrderNo => 'ઓર્ડર નં.';

  @override
  String get colPaymentMode => 'રીત';

  @override
  String get colReference => 'રેફરન્સ';

  @override
  String get colNote => 'નોંધ';

  @override
  String get colStatus => 'સ્થિતિ';

  @override
  String get colTotalQty => 'નંગ';

  @override
  String get colTotal => 'કુલ (₹)';

  @override
  String get colLineNo => 'લાઇન';

  @override
  String get colQty => 'નંગ';

  @override
  String get updateRequiredTitle => 'આગળ વધવા Vepari અપડેટ કરો';

  @override
  String updateRequiredBody(String version) {
    return 'આ વર્ઝન ($version) હવે ચાલતું નથી. જ્યાંથી એપ લીધી હતી ત્યાંથી નવું Vepari ઇન્સ્ટોલ કરો, પછી ફરી ખોલો. તમારો ડેટા સર્વર પર સુરક્ષિત છે.';
  }

  @override
  String get updateCheckAgain => 'ફરી તપાસો';

  @override
  String get maintenanceBanner => 'Vepari અપડેટ થઈ રહ્યું છે. તમે જોઈ શકો છો; થોડી મિનિટ માટે સેવ નહીં થાય.';
}
