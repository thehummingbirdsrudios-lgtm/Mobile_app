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

  @override
  String get orderNew => 'New order';

  @override
  String get quickOrder => 'Quick order';

  @override
  String get ordersPending => 'Pending';

  @override
  String get ordersAll => 'All';

  @override
  String get ordersEmpty => 'No orders yet.';

  @override
  String get ordersPendingEmpty => 'No pending orders. All caught up!';

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pcs', one: '1 pc');
    return '$_temp0';
  }

  @override
  String get cartChooseCustomer => 'Choose customer';

  @override
  String get cartChangeCustomer => 'Change';

  @override
  String get cartEmpty => 'Add designs from Maal, Regular Maal or by design number.';

  @override
  String get quickAddQty => 'Qty';

  @override
  String quickAddNotFound(String designNo) {
    return 'No design $designNo';
  }

  @override
  String quickAddUnavailable(String designNo) {
    return '$designNo is not available';
  }

  @override
  String quickAddAdded(String designNo) {
    return '$designNo added';
  }

  @override
  String get cartTotal => 'Total';

  @override
  String get fieldOrderNote => 'Note for this order';

  @override
  String get paymentNow => 'Payment received now';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get paymentModeCash => 'Cash';

  @override
  String get paymentModeUpi => 'UPI';

  @override
  String get paymentModeBank => 'Bank';

  @override
  String get paymentModeCheque => 'Cheque';

  @override
  String get fieldReference => 'Reference (UPI / cheque no.)';

  @override
  String get placeOrder => 'Place order';

  @override
  String orderPlacedTitle(String orderNo) {
    return 'Order #$orderNo placed';
  }

  @override
  String get orderAlreadyPlaced => 'This order was already placed — nothing was added twice.';

  @override
  String get viewOrder => 'View order';

  @override
  String get ratesChangedTitle => 'Rates changed';

  @override
  String get ratesChangedBody =>
      'Some rates changed since you added them. The cart now shows today\'s rates — check and place the order again.';

  @override
  String get unavailableInCart => 'Some designs are not available now. Remove them to place the order.';

  @override
  String get cartNeedsCustomer => 'Choose a customer first.';

  @override
  String get specialRateBadge => 'Special rate';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusProcessing => 'In process';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String markAs(String status) {
    return 'Mark $status';
  }

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderBody =>
      'The order amount will be removed from Baki. Payments already received stay as the customer\'s credit.';

  @override
  String get cancelReason => 'Reason (optional)';

  @override
  String get keepOrder => 'Keep order';

  @override
  String orderCreatedBy(String name) {
    return 'By $name';
  }

  @override
  String get orderPayments => 'Payments';

  @override
  String receiptNumber(String paymentNo) {
    return 'Receipt #$paymentNo';
  }

  @override
  String orderCancelledReason(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get reorderAction => 'Fari Order';

  @override
  String billNumber(String billNo) {
    return 'Bill #$billNo';
  }

  @override
  String get customerPickerTitle => 'Choose customer';

  @override
  String get addedToCart => 'Added to order';

  @override
  String get goToCart => 'Open order';

  @override
  String get fieldPaymentMode => 'Mode';

  @override
  String get qtyLess => 'One less';

  @override
  String get qtyMore => 'One more';

  @override
  String get cartOtherCustomerTitle => 'Unfinished order';

  @override
  String cartOtherCustomerBody(String name, int count) {
    return 'There is an unfinished order for $name with $count designs. Start a new order instead?';
  }

  @override
  String get cartKeepOld => 'Keep it';

  @override
  String get cartStartNew => 'Start new';

  @override
  String get cartClear => 'Clear order';

  @override
  String get hisaabNoPermission => 'You don\'t have access to Hisaab. Ask the owner.';

  @override
  String get hisaabTotalBaki => 'Total Baki';

  @override
  String get hisaabAllClear => 'No Baki. Everyone has paid.';

  @override
  String get advanceLabel => 'Advance';

  @override
  String get ledgerOpening => 'Opening Baki';

  @override
  String ledgerOrder(String orderNo) {
    return 'Order #$orderNo';
  }

  @override
  String ledgerPayment(String mode) {
    return 'Payment · $mode';
  }

  @override
  String get ledgerAdjustment => 'Adjustment';

  @override
  String ledgerReversal(String orderNo) {
    return 'Order #$orderNo cancelled';
  }

  @override
  String get ledgerReversalPlain => 'Cancelled';

  @override
  String get ledgerEmpty => 'No entries yet.';

  @override
  String balanceAfter(String amount) {
    return 'Baki $amount';
  }

  @override
  String get paymentRecord => 'Record payment';

  @override
  String paymentFullBaki(String amount) {
    return 'Full Baki $amount';
  }

  @override
  String paymentBakiAfter(String amount) {
    return 'Baki after this: $amount';
  }

  @override
  String paymentAdvanceAfter(String amount) {
    return 'Advance after this: $amount';
  }

  @override
  String get paymentSave => 'Save payment';

  @override
  String receiptTitle(String paymentNo) {
    return 'Receipt #$paymentNo';
  }

  @override
  String get receiptReceivedFrom => 'Received from';

  @override
  String get receiptMode => 'Mode';

  @override
  String get receiptReference => 'Reference';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptBakiBefore => 'Baki before';

  @override
  String get receiptBakiNow => 'Baki now';

  @override
  String get receiptSend => 'Send on WhatsApp';

  @override
  String receiptMessage(String amount, String mode, String date, String paymentNo, String baki, String business) {
    return 'Received $amount by $mode on $date. Receipt #$paymentNo. Baki now $baki. — $business';
  }

  @override
  String hisaabMessage(String name, String business, String baki, String date) {
    return 'Namaste $name, your Baki with $business is $baki as of $date.';
  }

  @override
  String get hisaabSend => 'Send Hisaab';

  @override
  String get adjustAction => 'Adjust';

  @override
  String get adjustTitle => 'Adjust Baki';

  @override
  String get adjustAdd => 'Add to Baki';

  @override
  String get adjustReduce => 'Reduce Baki';

  @override
  String get adjustNoteRequired => 'Write why (shown in Hisaab)';

  @override
  String get openingAlreadySet => 'Opening Baki is already set for this customer.';

  @override
  String get openingSet => 'Set opening Baki';

  @override
  String get paymentAlreadySaved => 'This payment was already saved — nothing was added twice.';

  @override
  String get billMake => 'Make bill';

  @override
  String get billView => 'View bill';

  @override
  String get billTitle => 'Bill';

  @override
  String get billSendPhoto => 'Send bill photo';

  @override
  String get billSharePdf => 'Share PDF';

  @override
  String get billPreparing => 'Preparing bill…';

  @override
  String get billTo => 'Bill to';

  @override
  String get billDate => 'Date';

  @override
  String billOrderRef(String orderNo) {
    return 'Order #$orderNo';
  }

  @override
  String get billColDesign => 'Design';

  @override
  String get billColQty => 'Qty';

  @override
  String get billColRate => 'Rate';

  @override
  String get billColAmount => 'Amount';

  @override
  String get billTotal => 'Total';

  @override
  String get billPaid => 'Paid with this order';

  @override
  String get billBakiAfter => 'Baki after this bill';

  @override
  String get billWeight => 'Total weight';

  @override
  String billShareText(String billNo, String business) {
    return 'Bill #$billNo from $business';
  }

  @override
  String get billCancelledOrder => 'A cancelled order cannot be billed.';

  @override
  String get shareFailed => 'Could not open sharing on this phone.';

  @override
  String get shareDesignsTitle => 'Share designs';

  @override
  String get shareShowRate => 'Show rate';

  @override
  String get shareAddWatermark => 'Business name on photos';

  @override
  String sharePreparing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count photos', one: 'photo');
    return 'Preparing $_temp0…';
  }

  @override
  String shareRateLine(String rate) {
    return '$rate per piece';
  }

  @override
  String shareContactLine(String phone) {
    return 'WhatsApp $phone';
  }

  @override
  String get shareNoPhotos => 'These designs have no photos yet; sending text only.';

  @override
  String get receiptSharePhoto => 'Share receipt photo';

  @override
  String orderShareHeader(String orderNo, String date) {
    return 'Order #$orderNo · $date';
  }

  @override
  String get vaatHint => 'Write a note…';

  @override
  String get vaatEmpty => 'No Vaat yet. Add a note, voice or photo.';

  @override
  String get vaatSend => 'Send';

  @override
  String get vaatRecord => 'Record voice';

  @override
  String vaatRecording(String time) {
    return 'Recording $time';
  }

  @override
  String get vaatTooShort => 'Too short. Speak a little longer.';

  @override
  String get vaatMicDenied => 'Allow the microphone to record voice notes.';

  @override
  String get vaatAddPhoto => 'Add photo';

  @override
  String get vaatYou => 'You';

  @override
  String get vaatPlay => 'Play';

  @override
  String get vaatStop => 'Stop';

  @override
  String get vaatRemove => 'Remove note';

  @override
  String get billColPhoto => 'Photo';

  @override
  String get billContinued => 'continued';

  @override
  String billPdfPreparing(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count photos', one: '1 photo');
    return 'Preparing PDF with $_temp0…';
  }

  @override
  String get billColItem => 'Product / item';

  @override
  String get adminSection => 'Business settings';

  @override
  String get adminBusinessProfile => 'Business details';

  @override
  String get adminBusinessProfileHint => 'Name, phone, GSTIN, logo, bill note';

  @override
  String get adminStaff => 'Staff';

  @override
  String get adminStaffHint => 'Logins and permissions';

  @override
  String get adminAudit => 'Activity log';

  @override
  String get adminAuditHint => 'Who changed what, and when';

  @override
  String get adminOwnerOnly => 'Only the owner can open this.';

  @override
  String get fieldBusinessName => 'Business name';

  @override
  String get fieldAddress => 'Address';

  @override
  String get fieldGstin => 'GSTIN (optional)';

  @override
  String get fieldBillFooter => 'Note at the bottom of bills';

  @override
  String get validationGstin => 'GSTIN has 15 letters and numbers';

  @override
  String get profileWatermark => 'Watermark on shared photos';

  @override
  String get profileWatermarkHint => 'Your business name on photos you send';

  @override
  String get profileDefaultLanguage => 'Language for new staff phones';

  @override
  String get profileLogo => 'Logo';

  @override
  String get profileLogoHint => 'Printed on bills';

  @override
  String get profileLogoAdd => 'Add logo';

  @override
  String get profileLogoChange => 'Change logo';

  @override
  String get profileLogoRemove => 'Remove logo';

  @override
  String get profileLogoSaved => 'Logo updated';

  @override
  String get profileLogoRemoved => 'Logo removed';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffEmpty => 'No staff yet';

  @override
  String get staffEmptyBody => 'Make a login for each person who works with you.';

  @override
  String get staffActive => 'Active';

  @override
  String get staffInactive => 'Stopped';

  @override
  String staffPermissionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permissions',
      one: '1 permission',
      zero: 'No extra permissions',
    );
    return '$_temp0';
  }

  @override
  String get staffAccess => 'Can log in';

  @override
  String get staffAccessHint => 'Turn off to stop access at once';

  @override
  String staffDeactivateTitle(String name) {
    return 'Stop $name\'s access?';
  }

  @override
  String get staffDeactivateBody =>
      'They are signed out at their next action and cannot log in until you turn this back on. Their past work stays.';

  @override
  String get staffDeactivate => 'Stop access';

  @override
  String get staffAccessStopped => 'Access stopped';

  @override
  String get staffAccessRestored => 'Access restored';

  @override
  String get staffPermissions => 'Permissions';

  @override
  String get staffPermissionsHint => 'Everyone can see Maal, customers and orders. Give only what each person needs.';

  @override
  String get staffSavePermissions => 'Save permissions';

  @override
  String get staffOwnerHasAll => 'The owner has every permission.';

  @override
  String get staffResetPassword => 'Set new password';

  @override
  String staffResetPasswordBody(String name) {
    return 'Set a new password for $name, then tell them in person.';
  }

  @override
  String get staffPasswordChanged => 'Password changed';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldPersonName => 'Full name';

  @override
  String get validationPasswordShort => 'At least 8 characters';

  @override
  String get validationPasswordLong => 'Too long — use a shorter password';

  @override
  String get validationPasswordSameAsUsername => 'Must not be the same as the username';

  @override
  String get staffNewTitle => 'New staff login';

  @override
  String get staffUsernameHint => 'Small letters, numbers, dot or underscore. They log in with this.';

  @override
  String get staffPasswordHint => 'Tell this password to them in person. You can set a new one any time.';

  @override
  String get staffCreate => 'Create login';

  @override
  String staffCreated(String name) {
    return '$name can log in now';
  }

  @override
  String get staffUsernameTaken => 'This username is taken. Try another.';

  @override
  String get permCatalogueManage => 'Add and edit Maal';

  @override
  String get permRatesManage => 'Change rates';

  @override
  String get permCustomersManage => 'Add and edit customers';

  @override
  String get permOrdersCreate => 'Take orders';

  @override
  String get permOrdersManage => 'Move and cancel orders';

  @override
  String get permPaymentsRecord => 'Record payments';

  @override
  String get permHisaabView => 'See Hisaab and Baki';

  @override
  String get permHisaabAdjust => 'Opening Baki and corrections';

  @override
  String get permBillsIssue => 'Make bills';

  @override
  String get permReportsView => 'See reports';

  @override
  String get auditEmpty => 'No activity yet';

  @override
  String get auditSystem => 'System';

  @override
  String get auditOrderCreated => 'Order taken';

  @override
  String get auditOrderStatus => 'Order moved forward';

  @override
  String get auditOrderCancelled => 'Order cancelled';

  @override
  String get auditPaymentRecorded => 'Payment recorded';

  @override
  String get auditBillIssued => 'Bill made';

  @override
  String get auditLedgerOpening => 'Opening Baki set';

  @override
  String get auditLedgerAdjustment => 'Hisaab corrected';

  @override
  String get auditStaffCreated => 'Staff login created';

  @override
  String get auditStaffPasswordReset => 'Staff password changed';

  @override
  String auditPermissionGranted(String permission) {
    return 'Permission given: $permission';
  }

  @override
  String auditPermissionRevoked(String permission) {
    return 'Permission taken back: $permission';
  }

  @override
  String auditRateChanged(String from, String to) {
    return 'Rate changed from $from to $to';
  }

  @override
  String auditAdded(String thing) {
    return '$thing added';
  }

  @override
  String auditChanged(String thing) {
    return '$thing changed';
  }

  @override
  String auditRemoved(String thing) {
    return '$thing removed';
  }

  @override
  String get auditEntityProduct => 'Design';

  @override
  String get auditEntityCost => 'Cost details';

  @override
  String get auditEntityCustomer => 'Customer';

  @override
  String get auditEntityCustomerRate => 'Customer rate';

  @override
  String get auditEntityMember => 'Staff member';

  @override
  String get auditEntityRecord => 'Record';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up';

  @override
  String get notificationsEmptyBody => 'New Maal, orders and payments for you show up here.';

  @override
  String get notificationsMarkAll => 'Mark all read';

  @override
  String notificationsUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String notifNewMaal(String design) {
    return 'New Maal: $design';
  }

  @override
  String notifOrderCreated(String orderNo, String customer) {
    return 'New order #$orderNo · $customer';
  }

  @override
  String notifOrderStatus(String orderNo, String status) {
    return 'Order #$orderNo: $status';
  }

  @override
  String notifPayment(String amount, String customer) {
    return 'Payment $amount from $customer';
  }

  @override
  String get notifOther => 'Update';

  @override
  String get adminExport => 'Export data';

  @override
  String get adminExportHint => 'Customers, Hisaab, orders and designs as a spreadsheet';

  @override
  String get exportWhat => 'What to export';

  @override
  String get exportPeriod => 'Period';

  @override
  String get exportKindCustomers => 'Customers and Baki';

  @override
  String get exportKindDesigns => 'Designs with cost';

  @override
  String get exportKindLedger => 'Hisaab entries';

  @override
  String get exportKindOrders => 'Orders';

  @override
  String get exportKindOrderLines => 'Order lines (each design)';

  @override
  String get exportPeriodThisMonth => 'This month';

  @override
  String get exportPeriodLastMonth => 'Last month';

  @override
  String get exportPeriodLast3Months => 'Last 3 months';

  @override
  String get exportPeriodThisYear => 'This year';

  @override
  String get exportPeriodCustom => 'Pick dates';

  @override
  String exportPeriodRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get exportCostWarning => 'This file has your cost prices and suppliers. Share it only with people you trust.';

  @override
  String get exportButton => 'Export CSV';

  @override
  String exportReading(String count) {
    return 'Reading… $count rows';
  }

  @override
  String exportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows exported',
      one: '1 row exported',
      zero: 'Nothing to export for this period',
    );
    return '$_temp0';
  }

  @override
  String get exportTooLarge => 'Too much for one file. Choose a shorter period.';

  @override
  String get exportShareFailed => 'Sharing isn\'t available on this device.';

  @override
  String get exportYes => 'Yes';

  @override
  String get exportNo => 'No';

  @override
  String get exportEntryOrder => 'Order';

  @override
  String get exportEntryPayment => 'Payment';

  @override
  String get colCustomer => 'Customer';

  @override
  String get colShop => 'Shop';

  @override
  String get colCity => 'City';

  @override
  String get colPhone => 'Mobile';

  @override
  String get colWhatsapp => 'WhatsApp';

  @override
  String get colBaki => 'Baki (₹)';

  @override
  String get colArchived => 'Archived';

  @override
  String get colCreatedAt => 'Added on';

  @override
  String get colDesignNo => 'Design no.';

  @override
  String get colProduct => 'Name';

  @override
  String get colCategory => 'Category';

  @override
  String get colRate => 'Rate (₹)';

  @override
  String get colWeight => 'Weight (g)';

  @override
  String get colAvailable => 'Available';

  @override
  String get colPublishedAt => 'Published on';

  @override
  String get colCost => 'Cost (₹, owner only)';

  @override
  String get colSupplier => 'Supplier (owner only)';

  @override
  String get colDate => 'Date';

  @override
  String get colEntryKind => 'Entry';

  @override
  String get colAmount => 'Amount (₹)';

  @override
  String get colBalanceAfter => 'Baki after (₹)';

  @override
  String get colOrderNo => 'Order no.';

  @override
  String get colPaymentMode => 'Mode';

  @override
  String get colReference => 'Reference';

  @override
  String get colNote => 'Note';

  @override
  String get colStatus => 'Status';

  @override
  String get colTotalQty => 'Pieces';

  @override
  String get colTotal => 'Total (₹)';

  @override
  String get colLineNo => 'Line';

  @override
  String get colQty => 'Qty';

  @override
  String get updateRequiredTitle => 'Update Vepari to continue';

  @override
  String updateRequiredBody(String version) {
    return 'This version ($version) is no longer supported. Install the latest Vepari from where you got the app, then open it again. Your data is safe on the server.';
  }

  @override
  String get updateCheckAgain => 'Check again';

  @override
  String get maintenanceBanner => 'Vepari is being updated. You can look around; saving is paused for a few minutes.';
}
