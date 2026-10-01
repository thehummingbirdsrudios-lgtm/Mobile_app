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
}
