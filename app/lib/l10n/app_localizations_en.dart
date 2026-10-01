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

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDone => 'Done';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonShare => 'Share';

  @override
  String get commonWhatsapp => 'WhatsApp';

  @override
  String get commonVaat => 'Vaat';

  @override
  String get commonOrderKaro => 'Order Karo';

  @override
  String get commonNotFound => 'This record was not found.';

  @override
  String get commonPageNotFound => 'This page does not exist.';

  @override
  String get commonGoHome => 'Go to Home';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationAmount => 'Enter a valid amount';

  @override
  String get validationWeight => 'Enter a valid weight in grams';

  @override
  String get validationPhone => 'Enter a 10-digit mobile number';

  @override
  String get validationTooLong => 'Too long';

  @override
  String get productAdd => 'Add design';

  @override
  String get productEdit => 'Edit design';

  @override
  String get productAvailable => 'Available';

  @override
  String get productNotAvailable => 'Not available';

  @override
  String get productArchived => 'Archived';

  @override
  String get catalogueEmpty => 'No maal yet.';

  @override
  String get catalogueEmptyOwnerAction => 'Add design';

  @override
  String get fieldDesignNo => 'Design no.';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldRate => 'Rate (₹ per piece)';

  @override
  String get fieldWeight => 'Weight (g)';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldNoCategory => 'No category';

  @override
  String get fieldDescription => 'Details';

  @override
  String get fieldAvailable => 'Available for order';

  @override
  String get ownerOnlySection => 'Only you can see this';

  @override
  String get fieldCost => 'Cost (₹)';

  @override
  String get fieldSupplier => 'Supplier';

  @override
  String get fieldInternalNote => 'Internal note';

  @override
  String get weightLabel => 'Weight';

  @override
  String get perPiece => 'per piece';

  @override
  String get photosTitle => 'Photos';

  @override
  String get photoCamera => 'Camera';

  @override
  String get photoGallery => 'Gallery';

  @override
  String get photoPreparing => 'Preparing photo…';

  @override
  String get photoRejected => 'This file is not a usable photo.';

  @override
  String get photoTooLarge => 'Photo is too large (max 25 MB).';

  @override
  String get photoDuplicate => 'This photo is already added.';

  @override
  String get photoAdded => 'Photo added';

  @override
  String get photoSaveFirst => 'Save the design first, then add photos.';

  @override
  String get designNoTaken => 'This design number already exists.';

  @override
  String get validationDesignNo => 'Use letters, numbers, - / . _ (max 24)';

  @override
  String get archiveDesign => 'Archive design';

  @override
  String archiveDesignBody(String designNo) {
    return 'Design $designNo will be hidden from Maal and new orders. Existing orders and bills stay safe.';
  }

  @override
  String get unarchiveDesign => 'Bring back to Maal';

  @override
  String get rateNeedsPermission => 'Only staff with rate permission can change rates.';

  @override
  String get catalogueAll => 'All';

  @override
  String get categoryNew => 'New category';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchClearRecent => 'Clear';

  @override
  String get searchStartHint => 'Search by design no., customer name or mobile, or order no.';

  @override
  String searchNoMatch(String query) {
    return 'No match for “$query”';
  }

  @override
  String get searchNoMatchBody => 'Check the spelling, or try a design number or mobile number.';

  @override
  String get searchSectionDesigns => 'Designs';

  @override
  String get searchSectionCustomers => 'Customers';

  @override
  String get searchSectionOrders => 'Orders';

  @override
  String orderNumberTitle(String orderNo) {
    return 'Order #$orderNo';
  }

  @override
  String get navoMaalSubtitle => 'Added in the last 7 days';

  @override
  String get navoMaalEmpty => 'No new designs in the last 7 days.';

  @override
  String get selectToShare => 'Select to share';

  @override
  String shareSelected(int count) {
    return 'Share $count';
  }

  @override
  String selectionLimit(int max) {
    return 'You can share up to $max designs at once.';
  }

  @override
  String selectionCount(int count) {
    return '$count selected';
  }

  @override
  String get customerAdd => 'Add customer';

  @override
  String get customerEdit => 'Edit customer';

  @override
  String get customersEmpty => 'No customers yet.';

  @override
  String customersNoMatch(String query) {
    return 'No customer matches “$query”';
  }

  @override
  String get customerSearchHint => 'Search name or mobile';

  @override
  String get sortAZ => 'A–Z';

  @override
  String get sortBaki => 'Baki first';

  @override
  String get fieldCustomerName => 'Customer name';

  @override
  String get fieldShopName => 'Shop name';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldMobile => 'Mobile';

  @override
  String get fieldWhatsapp => 'WhatsApp number';

  @override
  String get whatsappSameAsMobile => 'WhatsApp on the same number';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldOpeningBaki => 'Opening Baki';

  @override
  String get openingBakiHelp => 'Amount this customer already owes you. Can be set only once.';

  @override
  String get openingBakiFailed => 'Customer saved, but the opening Baki was not. Add it from Hisaab.';

  @override
  String get actionCall => 'Call';

  @override
  String get bakiLabel => 'Baki';

  @override
  String get openOrdersLabel => 'Open orders';

  @override
  String get totalOrdersLabel => 'Orders';

  @override
  String get lastOrderLabel => 'Last order';

  @override
  String get regularMaalTitle => 'Regular Maal';

  @override
  String get regularMaalEmpty => 'Designs this customer orders will appear here.';

  @override
  String regularMaalMeta(int times, int qty) {
    return '$times× · last $qty pcs';
  }

  @override
  String get specialRatesTitle => 'Special rates';

  @override
  String specialRatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count designs',
      one: '1 design',
      zero: 'None',
    );
    return '$_temp0';
  }

  @override
  String get specialRatesEmpty => 'No special rates. This customer pays the normal rate.';

  @override
  String get specialRateAdd => 'Add special rate';

  @override
  String specialRateNormal(String rate) {
    return 'Normal $rate';
  }

  @override
  String get specialRateRemove => 'Remove special rate';

  @override
  String get designNotFound => 'No design with this number.';

  @override
  String get archiveCustomer => 'Archive customer';

  @override
  String archiveCustomerBody(String name) {
    return '$name will be hidden from lists and new orders. Hisaab and old orders stay safe.';
  }

  @override
  String get unarchiveCustomer => 'Restore customer';

  @override
  String get whatsappUnavailable => 'WhatsApp could not be opened on this phone.';

  @override
  String get callUnavailable => 'Calling is not available on this device.';

  @override
  String get statusArchived => 'Archived';

  @override
  String get neverLabel => '—';
}
