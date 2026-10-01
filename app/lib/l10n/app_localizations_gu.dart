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
}
