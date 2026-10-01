import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('gu'), Locale('hi')];

  /// Product name. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Vepari'**
  String get appName;

  /// Bottom navigation: home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation: catalogue of goods (maal)
  ///
  /// In en, this message translates to:
  /// **'Maal'**
  String get navMaal;

  /// Bottom navigation: orders tab
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get navOrder;

  /// Bottom navigation: customers tab
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get navCustomer;

  /// Bottom navigation: accounts / ledger (hisaab)
  ///
  /// In en, this message translates to:
  /// **'Hisaab'**
  String get navHisaab;

  /// Bottom navigation: settings and everything else
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Login screen headline
  ///
  /// In en, this message translates to:
  /// **'Namaskar 👋'**
  String get loginGreeting;

  /// Login screen sub-heading
  ///
  /// In en, this message translates to:
  /// **'Login to your business'**
  String get loginSubtitle;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsername;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// Accessibility label for the show-password toggle
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// Accessibility label for the hide-password toggle
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// Hint under login: accounts are created by the owner
  ///
  /// In en, this message translates to:
  /// **'No account? Ask your business owner.'**
  String get loginNoAccountHint;

  /// Validation: empty username
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get validationUsernameRequired;

  /// Validation: username has invalid characters
  ///
  /// In en, this message translates to:
  /// **'Use only a–z, 0–9, dot and underscore'**
  String get validationUsernameInvalid;

  /// Validation: empty password
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get validationPasswordRequired;

  /// Login failed
  ///
  /// In en, this message translates to:
  /// **'Username or password is wrong.'**
  String get errorInvalidCredentials;

  /// Login ok but membership inactive
  ///
  /// In en, this message translates to:
  /// **'This account is not active. Contact your owner.'**
  String get errorAccountDisabled;

  /// No network
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get errorNetwork;

  /// Request timed out
  ///
  /// In en, this message translates to:
  /// **'Server is slow to respond. Try again.'**
  String get errorTimeout;

  /// 5xx / server down
  ///
  /// In en, this message translates to:
  /// **'Server is not reachable right now. Try again shortly.'**
  String get errorServerUnavailable;

  /// Authorization failure
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this.'**
  String get errorPermission;

  /// Record missing or not visible
  ///
  /// In en, this message translates to:
  /// **'This record was not found.'**
  String get errorNotFound;

  /// Unique violation
  ///
  /// In en, this message translates to:
  /// **'This record already exists.'**
  String get errorAlreadyExists;

  /// Ordering an archived/unavailable design
  ///
  /// In en, this message translates to:
  /// **'This maal is not available now.'**
  String get errorProductUnavailable;

  /// Server rejected an order because a rate changed
  ///
  /// In en, this message translates to:
  /// **'The rate has changed. Check the new rate and confirm again.'**
  String get errorRateChanged;

  /// Validation failed on the server
  ///
  /// In en, this message translates to:
  /// **'Some details are not right. Please check.'**
  String get errorInvalidInput;

  /// Auth session expired or revoked
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please login again.'**
  String get errorSessionExpired;

  /// Maintenance mode
  ///
  /// In en, this message translates to:
  /// **'Some maintenance is going on. Please try again in a little while.'**
  String get errorMaintenance;

  /// Unknown error
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Build has no backend configuration
  ///
  /// In en, this message translates to:
  /// **'Server not set up'**
  String get notConfiguredTitle;

  /// Explanation for missing backend configuration
  ///
  /// In en, this message translates to:
  /// **'This build has no server configuration. Please contact the admin.'**
  String get notConfiguredBody;

  /// Home greeting with the user's display name
  ///
  /// In en, this message translates to:
  /// **'Namaskar {name} 👋'**
  String greeting(String name);

  /// Home sub-heading above today's numbers
  ///
  /// In en, this message translates to:
  /// **'What\'s happening today?'**
  String get homeTodayQuestion;

  /// Dashboard tile: sales today
  ///
  /// In en, this message translates to:
  /// **'Today\'s sale'**
  String get statSalesToday;

  /// Dashboard tile: payments received today
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get statPaymentsToday;

  /// Dashboard tile: total outstanding (baki)
  ///
  /// In en, this message translates to:
  /// **'Total Baki'**
  String get statTotalBaki;

  /// Dashboard tile: open orders
  ///
  /// In en, this message translates to:
  /// **'Orders pending'**
  String get statPendingOrders;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// Quick action: new order
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get actionOrder;

  /// Quick action: receive payment
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get actionPayment;

  /// Quick action: new arrivals
  ///
  /// In en, this message translates to:
  /// **'Navo Maal'**
  String get actionNewMaal;

  /// Quick action: accounts
  ///
  /// In en, this message translates to:
  /// **'Hisaab'**
  String get actionHisaab;

  /// Number of new designs in the last 7 days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new designs} =1{1 new design} other{{count} new designs}}'**
  String newMaalCount(int count);

  /// Honest state for a tab not yet implemented in this build
  ///
  /// In en, this message translates to:
  /// **'This section is being built'**
  String get comingSoonTitle;

  /// Body for not-yet-built section
  ///
  /// In en, this message translates to:
  /// **'It will arrive in an upcoming update.'**
  String get comingSoonBody;

  /// Universal search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search design, customer, order'**
  String get searchHint;

  /// Settings row: app language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get moreLanguage;

  /// Settings row: business profile
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get moreBusiness;

  /// Settings row: privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get morePrivacy;

  /// Settings row: terms
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get moreTerms;

  /// Settings row: sign out
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get moreLogout;

  /// Role label
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// Role label
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// App version line
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// Banner on unpublished legal documents
  ///
  /// In en, this message translates to:
  /// **'Draft — under legal review before publication.'**
  String get legalDraftNotice;

  /// Unsaved-changes dialog title
  ///
  /// In en, this message translates to:
  /// **'There is unsaved work.'**
  String get unsavedTitle;

  /// Unsaved-changes dialog body
  ///
  /// In en, this message translates to:
  /// **'If you leave now, it will be lost.'**
  String get unsavedBody;

  /// Unsaved-changes dialog: stay
  ///
  /// In en, this message translates to:
  /// **'Continue editing'**
  String get unsavedKeepEditing;

  /// Unsaved-changes dialog: leave and lose changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get unsavedDiscard;

  /// Success: order created on the server
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get feedbackOrderSaved;

  /// Success: payment committed
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get feedbackPaymentSaved;

  /// Success: bill generated
  ///
  /// In en, this message translates to:
  /// **'Bill ready'**
  String get feedbackBillReady;

  /// Quantity in pieces
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String pieces(int count);

  /// Accessibility label for loading states
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Saved confirmation
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Add action
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Close action
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Remove action
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// WhatsApp action
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get commonWhatsapp;

  /// Remarks (voice/text/photo) section
  ///
  /// In en, this message translates to:
  /// **'Vaat'**
  String get commonVaat;

  /// Primary order action
  ///
  /// In en, this message translates to:
  /// **'Order Karo'**
  String get commonOrderKaro;

  /// Detail screen when the id is unknown or not visible
  ///
  /// In en, this message translates to:
  /// **'This record was not found.'**
  String get commonNotFound;

  /// Unknown route / deep link
  ///
  /// In en, this message translates to:
  /// **'This page does not exist.'**
  String get commonPageNotFound;

  /// Button back to home
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get commonGoHome;

  /// Required field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// Invalid money input
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get validationAmount;

  /// Invalid weight
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight in grams'**
  String get validationWeight;

  /// Invalid phone
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number'**
  String get validationPhone;

  /// Text too long
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get validationTooLong;

  /// Create product
  ///
  /// In en, this message translates to:
  /// **'Add design'**
  String get productAdd;

  /// Edit product
  ///
  /// In en, this message translates to:
  /// **'Edit design'**
  String get productEdit;

  /// Availability chip
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get productAvailable;

  /// Availability chip
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get productNotAvailable;

  /// Archived chip
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get productArchived;

  /// Empty catalogue
  ///
  /// In en, this message translates to:
  /// **'No maal yet.'**
  String get catalogueEmpty;

  /// Empty catalogue action
  ///
  /// In en, this message translates to:
  /// **'Add design'**
  String get catalogueEmptyOwnerAction;

  /// Design number field
  ///
  /// In en, this message translates to:
  /// **'Design no.'**
  String get fieldDesignNo;

  /// Name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// Rate field
  ///
  /// In en, this message translates to:
  /// **'Rate (₹ per piece)'**
  String get fieldRate;

  /// Weight field
  ///
  /// In en, this message translates to:
  /// **'Weight (g)'**
  String get fieldWeight;

  /// Category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// Category none option
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get fieldNoCategory;

  /// Description field
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get fieldDescription;

  /// Availability switch
  ///
  /// In en, this message translates to:
  /// **'Available for order'**
  String get fieldAvailable;

  /// Owner-only private section header
  ///
  /// In en, this message translates to:
  /// **'Only you can see this'**
  String get ownerOnlySection;

  /// Owner cost field
  ///
  /// In en, this message translates to:
  /// **'Cost (₹)'**
  String get fieldCost;

  /// Supplier field
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get fieldSupplier;

  /// Internal note field
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get fieldInternalNote;

  /// Weight label on detail
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// Rate unit
  ///
  /// In en, this message translates to:
  /// **'per piece'**
  String get perPiece;

  /// Photos section
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosTitle;

  /// Take a photo
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get photoCamera;

  /// Pick from gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get photoGallery;

  /// Image processing/upload progress
  ///
  /// In en, this message translates to:
  /// **'Preparing photo…'**
  String get photoPreparing;

  /// Invalid image
  ///
  /// In en, this message translates to:
  /// **'This file is not a usable photo.'**
  String get photoRejected;

  /// Oversized image
  ///
  /// In en, this message translates to:
  /// **'Photo is too large (max 25 MB).'**
  String get photoTooLarge;

  /// Duplicate image
  ///
  /// In en, this message translates to:
  /// **'This photo is already added.'**
  String get photoDuplicate;

  /// Upload success
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get photoAdded;

  /// Photos need a saved product
  ///
  /// In en, this message translates to:
  /// **'Save the design first, then add photos.'**
  String get photoSaveFirst;

  /// Unique violation on design no
  ///
  /// In en, this message translates to:
  /// **'This design number already exists.'**
  String get designNoTaken;

  /// Invalid design number
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers, - / . _ (max 24)'**
  String get validationDesignNo;

  /// Archive action
  ///
  /// In en, this message translates to:
  /// **'Archive design'**
  String get archiveDesign;

  /// Archive confirmation
  ///
  /// In en, this message translates to:
  /// **'Design {designNo} will be hidden from Maal and new orders. Existing orders and bills stay safe.'**
  String archiveDesignBody(String designNo);

  /// Unarchive action
  ///
  /// In en, this message translates to:
  /// **'Bring back to Maal'**
  String get unarchiveDesign;

  /// Rate field locked hint
  ///
  /// In en, this message translates to:
  /// **'Only staff with rate permission can change rates.'**
  String get rateNeedsPermission;

  /// Catalogue filter: all categories
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get catalogueAll;

  /// Create category
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryNew;

  /// Header above recent search queries
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecent;

  /// Clears recent searches
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearRecent;

  /// Shown before the user types a search
  ///
  /// In en, this message translates to:
  /// **'Search by design no., customer name or mobile, or order no.'**
  String get searchStartHint;

  /// Search returned nothing
  ///
  /// In en, this message translates to:
  /// **'No match for “{query}”'**
  String searchNoMatch(String query);

  /// Help under no-match
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or try a design number or mobile number.'**
  String get searchNoMatchBody;

  /// Search result group header
  ///
  /// In en, this message translates to:
  /// **'Designs'**
  String get searchSectionDesigns;

  /// Search result group header
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get searchSectionCustomers;

  /// Search result group header
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get searchSectionOrders;

  /// Order title with its number
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo}'**
  String orderNumberTitle(String orderNo);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
