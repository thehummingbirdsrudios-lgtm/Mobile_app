// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vepari';

  @override
  String get navHome => 'Home';

  @override
  String get navMaal => 'Maal';

  @override
  String get navOrder => 'Order';

  @override
  String get navCustomer => 'Customer';

  @override
  String get navHisaab => 'Hisaab';

  @override
  String get navMore => 'More';

  @override
  String get loginGreeting => 'Namaskar 👋';

  @override
  String get loginSubtitle => 'Login to your business';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginNoAccountHint => 'No account? Ask your business owner.';

  @override
  String get validationUsernameRequired => 'Enter your username';

  @override
  String get validationUsernameInvalid => 'Use only a–z, 0–9, dot and underscore';

  @override
  String get validationPasswordRequired => 'Enter your password';

  @override
  String get errorInvalidCredentials => 'Username or password is wrong.';

  @override
  String get errorAccountDisabled => 'This account is not active. Contact your owner.';

  @override
  String get errorNetwork => 'Check your internet connection.';

  @override
  String get errorTimeout => 'Server is slow to respond. Try again.';

  @override
  String get errorServerUnavailable => 'Server is not reachable right now. Try again shortly.';

  @override
  String get errorPermission => 'You don\'t have permission for this.';

  @override
  String get errorNotFound => 'This record was not found.';

  @override
  String get errorAlreadyExists => 'This record already exists.';

  @override
  String get errorProductUnavailable => 'This maal is not available now.';

  @override
  String get errorRateChanged => 'The rate has changed. Check the new rate and confirm again.';

  @override
  String get errorInvalidInput => 'Some details are not right. Please check.';

  @override
  String get errorSessionExpired => 'Your session has ended. Please login again.';

  @override
  String get errorMaintenance => 'Some maintenance is going on. Please try again in a little while.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get retry => 'Try again';

  @override
  String get notConfiguredTitle => 'Server not set up';

  @override
  String get notConfiguredBody => 'This build has no server configuration. Please contact the admin.';

  @override
  String greeting(String name) {
    return 'Namaskar $name 👋';
  }

  @override
  String get homeTodayQuestion => 'What\'s happening today?';

  @override
  String get statSalesToday => 'Today\'s sale';

  @override
  String get statPaymentsToday => 'Payment';

  @override
  String get statTotalBaki => 'Total Baki';

  @override
  String get statPendingOrders => 'Orders pending';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get actionOrder => 'Order';

  @override
  String get actionPayment => 'Payment';

  @override
  String get actionNewMaal => 'Navo Maal';

  @override
  String get actionHisaab => 'Hisaab';

  @override
  String newMaalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new designs',
      one: '1 new design',
      zero: 'No new designs',
    );
    return '$_temp0';
  }

  @override
  String get comingSoonTitle => 'This section is being built';

  @override
  String get comingSoonBody => 'It will arrive in an upcoming update.';

  @override
  String get searchHint => 'Search design, customer, order';

  @override
  String get moreLanguage => 'Language';

  @override
  String get moreBusiness => 'Business';

  @override
  String get morePrivacy => 'Privacy Policy';

  @override
  String get moreTerms => 'Terms & Conditions';

  @override
  String get moreLogout => 'Logout';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleStaff => 'Staff';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get legalDraftNotice => 'Draft — under legal review before publication.';

  @override
  String get unsavedTitle => 'There is unsaved work.';

  @override
  String get unsavedBody => 'If you leave now, it will be lost.';

  @override
  String get unsavedKeepEditing => 'Continue editing';

  @override
  String get unsavedDiscard => 'Discard';

  @override
  String get feedbackOrderSaved => 'Order placed';

  @override
  String get feedbackPaymentSaved => 'Payment saved';

  @override
  String get feedbackBillReady => 'Bill ready';

  @override
  String pieces(int count) {
    return '$count pcs';
  }

  @override
  String get loading => 'Loading';
}
