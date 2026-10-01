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

  /// Navo Maal screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Added in the last 7 days'**
  String get navoMaalSubtitle;

  /// Navo Maal empty state
  ///
  /// In en, this message translates to:
  /// **'No new designs in the last 7 days.'**
  String get navoMaalEmpty;

  /// Starts multi-select for sharing
  ///
  /// In en, this message translates to:
  /// **'Select to share'**
  String get selectToShare;

  /// Share the selected designs
  ///
  /// In en, this message translates to:
  /// **'Share {count}'**
  String shareSelected(int count);

  /// Shown when selecting too many designs
  ///
  /// In en, this message translates to:
  /// **'You can share up to {max} designs at once.'**
  String selectionLimit(int max);

  /// Number of selected designs
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionCount(int count);

  /// Create customer action
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get customerAdd;

  /// Edit customer title
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customerEdit;

  /// Empty customer list
  ///
  /// In en, this message translates to:
  /// **'No customers yet.'**
  String get customersEmpty;

  /// Customer search no result
  ///
  /// In en, this message translates to:
  /// **'No customer matches “{query}”'**
  String customersNoMatch(String query);

  /// Customer list search
  ///
  /// In en, this message translates to:
  /// **'Search name or mobile'**
  String get customerSearchHint;

  /// Sort customers by name
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get sortAZ;

  /// Sort customers by highest Baki
  ///
  /// In en, this message translates to:
  /// **'Baki first'**
  String get sortBaki;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get fieldCustomerName;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get fieldShopName;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get fieldMobile;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get fieldWhatsapp;

  /// Switch in customer form
  ///
  /// In en, this message translates to:
  /// **'WhatsApp on the same number'**
  String get whatsappSameAsMobile;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// Form field: amount owed when the customer is added
  ///
  /// In en, this message translates to:
  /// **'Opening Baki'**
  String get fieldOpeningBaki;

  /// Help under opening Baki
  ///
  /// In en, this message translates to:
  /// **'Amount this customer already owes you. Can be set only once.'**
  String get openingBakiHelp;

  /// Partial save message
  ///
  /// In en, this message translates to:
  /// **'Customer saved, but the opening Baki was not. Add it from Hisaab.'**
  String get openingBakiFailed;

  /// Call customer
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get actionCall;

  /// Outstanding amount label
  ///
  /// In en, this message translates to:
  /// **'Baki'**
  String get bakiLabel;

  /// Count of orders not completed
  ///
  /// In en, this message translates to:
  /// **'Open orders'**
  String get openOrdersLabel;

  /// Total order count
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get totalOrdersLabel;

  /// Date of last order
  ///
  /// In en, this message translates to:
  /// **'Last order'**
  String get lastOrderLabel;

  /// Designs a customer orders often
  ///
  /// In en, this message translates to:
  /// **'Regular Maal'**
  String get regularMaalTitle;

  /// Empty Regular Maal
  ///
  /// In en, this message translates to:
  /// **'Designs this customer orders will appear here.'**
  String get regularMaalEmpty;

  /// Times ordered and last quantity
  ///
  /// In en, this message translates to:
  /// **'{times}× · last {qty} pcs'**
  String regularMaalMeta(int times, int qty);

  /// Per-customer rates
  ///
  /// In en, this message translates to:
  /// **'Special rates'**
  String get specialRatesTitle;

  /// Number of special rates
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None} =1{1 design} other{{count} designs}}'**
  String specialRatesCount(int count);

  /// Empty special rates
  ///
  /// In en, this message translates to:
  /// **'No special rates. This customer pays the normal rate.'**
  String get specialRatesEmpty;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Add special rate'**
  String get specialRateAdd;

  /// Default rate shown next to special rate
  ///
  /// In en, this message translates to:
  /// **'Normal {rate}'**
  String specialRateNormal(String rate);

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Remove special rate'**
  String get specialRateRemove;

  /// Design lookup failed
  ///
  /// In en, this message translates to:
  /// **'No design with this number.'**
  String get designNotFound;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Archive customer'**
  String get archiveCustomer;

  /// Archive confirmation
  ///
  /// In en, this message translates to:
  /// **'{name} will be hidden from lists and new orders. Hisaab and old orders stay safe.'**
  String archiveCustomerBody(String name);

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Restore customer'**
  String get unarchiveCustomer;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'WhatsApp could not be opened on this phone.'**
  String get whatsappUnavailable;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Calling is not available on this device.'**
  String get callUnavailable;

  /// Badge
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// Placeholder when there is no date
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get neverLabel;

  /// Start an order
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get orderNew;

  /// Order by typing design numbers
  ///
  /// In en, this message translates to:
  /// **'Quick order'**
  String get quickOrder;

  /// Filter: open orders
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersPending;

  /// Filter: all orders
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersAll;

  /// Empty orders
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get ordersEmpty;

  /// Empty pending orders
  ///
  /// In en, this message translates to:
  /// **'No pending orders. All caught up!'**
  String get ordersPendingEmpty;

  /// Number of pieces
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pc} other{{count} pcs}}'**
  String piecesCount(int count);

  /// Cart: pick customer
  ///
  /// In en, this message translates to:
  /// **'Choose customer'**
  String get cartChooseCustomer;

  /// Cart: change customer
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get cartChangeCustomer;

  /// Empty cart
  ///
  /// In en, this message translates to:
  /// **'Add designs from Maal, Regular Maal or by design number.'**
  String get cartEmpty;

  /// Quantity field
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quickAddQty;

  /// Quick add: unknown design
  ///
  /// In en, this message translates to:
  /// **'No design {designNo}'**
  String quickAddNotFound(String designNo);

  /// Quick add: unavailable
  ///
  /// In en, this message translates to:
  /// **'{designNo} is not available'**
  String quickAddUnavailable(String designNo);

  /// Quick add: done
  ///
  /// In en, this message translates to:
  /// **'{designNo} added'**
  String quickAddAdded(String designNo);

  /// Order total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// Order note
  ///
  /// In en, this message translates to:
  /// **'Note for this order'**
  String get fieldOrderNote;

  /// Take payment with order
  ///
  /// In en, this message translates to:
  /// **'Payment received now'**
  String get paymentNow;

  /// Amount field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// Payment mode
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentModeCash;

  /// Payment mode
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get paymentModeUpi;

  /// Payment mode
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get paymentModeBank;

  /// Payment mode
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get paymentModeCheque;

  /// Payment reference
  ///
  /// In en, this message translates to:
  /// **'Reference (UPI / cheque no.)'**
  String get fieldReference;

  /// Submit order
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrder;

  /// Success
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo} placed'**
  String orderPlacedTitle(String orderNo);

  /// Idempotent replay message
  ///
  /// In en, this message translates to:
  /// **'This order was already placed — nothing was added twice.'**
  String get orderAlreadyPlaced;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get viewOrder;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Rates changed'**
  String get ratesChangedTitle;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'Some rates changed since you added them. The cart now shows today\'s rates — check and place the order again.'**
  String get ratesChangedBody;

  /// Cart warning
  ///
  /// In en, this message translates to:
  /// **'Some designs are not available now. Remove them to place the order.'**
  String get unavailableInCart;

  /// Cart validation
  ///
  /// In en, this message translates to:
  /// **'Choose a customer first.'**
  String get cartNeedsCustomer;

  /// Badge on a line with a customer rate
  ///
  /// In en, this message translates to:
  /// **'Special rate'**
  String get specialRateBadge;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'In process'**
  String get statusProcessing;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Order status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Change order status
  ///
  /// In en, this message translates to:
  /// **'Mark {status}'**
  String markAs(String status);

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// Cancel confirmation
  ///
  /// In en, this message translates to:
  /// **'The order amount will be removed from Baki. Payments already received stay as the customer\'s credit.'**
  String get cancelOrderBody;

  /// Field
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get cancelReason;

  /// Dismiss cancel dialog
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get keepOrder;

  /// Who placed the order
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String orderCreatedBy(String name);

  /// Section header
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get orderPayments;

  /// Payment receipt number
  ///
  /// In en, this message translates to:
  /// **'Receipt #{paymentNo}'**
  String receiptNumber(String paymentNo);

  /// Cancel reason
  ///
  /// In en, this message translates to:
  /// **'Cancelled: {reason}'**
  String orderCancelledReason(String reason);

  /// Repeat an earlier order
  ///
  /// In en, this message translates to:
  /// **'Fari Order'**
  String get reorderAction;

  /// Bill number
  ///
  /// In en, this message translates to:
  /// **'Bill #{billNo}'**
  String billNumber(String billNo);

  /// Sheet title
  ///
  /// In en, this message translates to:
  /// **'Choose customer'**
  String get customerPickerTitle;

  /// Feedback after +
  ///
  /// In en, this message translates to:
  /// **'Added to order'**
  String get addedToCart;

  /// Snackbar action
  ///
  /// In en, this message translates to:
  /// **'Open order'**
  String get goToCart;

  /// Payment mode label
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get fieldPaymentMode;

  /// Stepper decrease
  ///
  /// In en, this message translates to:
  /// **'One less'**
  String get qtyLess;

  /// Stepper increase
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get qtyMore;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Unfinished order'**
  String get cartOtherCustomerTitle;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'There is an unfinished order for {name} with {count} designs. Start a new order instead?'**
  String cartOtherCustomerBody(String name, int count);

  /// Keep unfinished order
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get cartKeepOld;

  /// Discard and start new
  ///
  /// In en, this message translates to:
  /// **'Start new'**
  String get cartStartNew;

  /// Remove all lines
  ///
  /// In en, this message translates to:
  /// **'Clear order'**
  String get cartClear;

  /// Hisaab tab without permission
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to Hisaab. Ask the owner.'**
  String get hisaabNoPermission;

  /// Sum of all customer Baki
  ///
  /// In en, this message translates to:
  /// **'Total Baki'**
  String get hisaabTotalBaki;

  /// Empty Baki list
  ///
  /// In en, this message translates to:
  /// **'No Baki. Everyone has paid.'**
  String get hisaabAllClear;

  /// Customer has paid more than owed
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advanceLabel;

  /// Ledger entry
  ///
  /// In en, this message translates to:
  /// **'Opening Baki'**
  String get ledgerOpening;

  /// Ledger entry
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo}'**
  String ledgerOrder(String orderNo);

  /// Ledger entry
  ///
  /// In en, this message translates to:
  /// **'Payment · {mode}'**
  String ledgerPayment(String mode);

  /// Ledger entry
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get ledgerAdjustment;

  /// Ledger entry
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo} cancelled'**
  String ledgerReversal(String orderNo);

  /// Ledger reversal without order no
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ledgerReversalPlain;

  /// Empty ledger
  ///
  /// In en, this message translates to:
  /// **'No entries yet.'**
  String get ledgerEmpty;

  /// Running balance
  ///
  /// In en, this message translates to:
  /// **'Baki {amount}'**
  String balanceAfter(String amount);

  /// Screen title
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get paymentRecord;

  /// Quick amount chip
  ///
  /// In en, this message translates to:
  /// **'Full Baki {amount}'**
  String paymentFullBaki(String amount);

  /// Live preview
  ///
  /// In en, this message translates to:
  /// **'Baki after this: {amount}'**
  String paymentBakiAfter(String amount);

  /// Live preview when overpaid
  ///
  /// In en, this message translates to:
  /// **'Advance after this: {amount}'**
  String paymentAdvanceAfter(String amount);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Save payment'**
  String get paymentSave;

  /// Receipt screen title
  ///
  /// In en, this message translates to:
  /// **'Receipt #{paymentNo}'**
  String receiptTitle(String paymentNo);

  /// Receipt label
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get receiptReceivedFrom;

  /// Receipt label
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get receiptMode;

  /// Receipt label
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get receiptReference;

  /// Receipt label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptDate;

  /// Receipt label
  ///
  /// In en, this message translates to:
  /// **'Baki before'**
  String get receiptBakiBefore;

  /// Receipt label
  ///
  /// In en, this message translates to:
  /// **'Baki now'**
  String get receiptBakiNow;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Send on WhatsApp'**
  String get receiptSend;

  /// WhatsApp receipt text
  ///
  /// In en, this message translates to:
  /// **'Received {amount} by {mode} on {date}. Receipt #{paymentNo}. Baki now {baki}. — {business}'**
  String receiptMessage(String amount, String mode, String date, String paymentNo, String baki, String business);

  /// WhatsApp Hisaab text
  ///
  /// In en, this message translates to:
  /// **'Namaste {name}, your Baki with {business} is {baki} as of {date}.'**
  String hisaabMessage(String name, String business, String baki, String date);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Send Hisaab'**
  String get hisaabSend;

  /// Button: correct the ledger
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjustAction;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Adjust Baki'**
  String get adjustTitle;

  /// Adjustment direction
  ///
  /// In en, this message translates to:
  /// **'Add to Baki'**
  String get adjustAdd;

  /// Adjustment direction
  ///
  /// In en, this message translates to:
  /// **'Reduce Baki'**
  String get adjustReduce;

  /// Note field
  ///
  /// In en, this message translates to:
  /// **'Write why (shown in Hisaab)'**
  String get adjustNoteRequired;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Opening Baki is already set for this customer.'**
  String get openingAlreadySet;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Set opening Baki'**
  String get openingSet;

  /// Idempotent replay
  ///
  /// In en, this message translates to:
  /// **'This payment was already saved — nothing was added twice.'**
  String get paymentAlreadySaved;

  /// Issue a bill for an order
  ///
  /// In en, this message translates to:
  /// **'Make bill'**
  String get billMake;

  /// Open the bill
  ///
  /// In en, this message translates to:
  /// **'View bill'**
  String get billView;

  /// Section/screen title
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get billTitle;

  /// Share the bill as an image
  ///
  /// In en, this message translates to:
  /// **'Send bill photo'**
  String get billSendPhoto;

  /// Share the bill as a PDF
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get billSharePdf;

  /// Progress
  ///
  /// In en, this message translates to:
  /// **'Preparing bill…'**
  String get billPreparing;

  /// Bill label
  ///
  /// In en, this message translates to:
  /// **'Bill to'**
  String get billTo;

  /// Bill label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get billDate;

  /// Bill label
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo}'**
  String billOrderRef(String orderNo);

  /// Bill column
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get billColDesign;

  /// Bill column
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get billColQty;

  /// Bill column
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get billColRate;

  /// Bill column
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get billColAmount;

  /// Bill total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get billTotal;

  /// Bill paid
  ///
  /// In en, this message translates to:
  /// **'Paid with this order'**
  String get billPaid;

  /// Bill balance
  ///
  /// In en, this message translates to:
  /// **'Baki after this bill'**
  String get billBakiAfter;

  /// Bill weight
  ///
  /// In en, this message translates to:
  /// **'Total weight'**
  String get billWeight;

  /// Text sent with the bill
  ///
  /// In en, this message translates to:
  /// **'Bill #{billNo} from {business}'**
  String billShareText(String billNo, String business);

  /// Error
  ///
  /// In en, this message translates to:
  /// **'A cancelled order cannot be billed.'**
  String get billCancelledOrder;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Could not open sharing on this phone.'**
  String get shareFailed;

  /// Share sheet title
  ///
  /// In en, this message translates to:
  /// **'Share designs'**
  String get shareDesignsTitle;

  /// Include rate in caption
  ///
  /// In en, this message translates to:
  /// **'Show rate'**
  String get shareShowRate;

  /// Watermark toggle
  ///
  /// In en, this message translates to:
  /// **'Business name on photos'**
  String get shareAddWatermark;

  /// Progress
  ///
  /// In en, this message translates to:
  /// **'Preparing {count, plural, =1{photo} other{{count} photos}}…'**
  String sharePreparing(int count);

  /// Caption rate
  ///
  /// In en, this message translates to:
  /// **'{rate} per piece'**
  String shareRateLine(String rate);

  /// Caption contact
  ///
  /// In en, this message translates to:
  /// **'WhatsApp {phone}'**
  String shareContactLine(String phone);

  /// Warning
  ///
  /// In en, this message translates to:
  /// **'These designs have no photos yet; sending text only.'**
  String get shareNoPhotos;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Share receipt photo'**
  String get receiptSharePhoto;

  /// Shared order text header
  ///
  /// In en, this message translates to:
  /// **'Order #{orderNo} · {date}'**
  String orderShareHeader(String orderNo, String date);

  /// Remark composer hint
  ///
  /// In en, this message translates to:
  /// **'Write a note…'**
  String get vaatHint;

  /// Empty remarks
  ///
  /// In en, this message translates to:
  /// **'No Vaat yet. Add a note, voice or photo.'**
  String get vaatEmpty;

  /// Send remark
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get vaatSend;

  /// Mic button
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get vaatRecord;

  /// While recording
  ///
  /// In en, this message translates to:
  /// **'Recording {time}'**
  String vaatRecording(String time);

  /// Voice note too short
  ///
  /// In en, this message translates to:
  /// **'Too short. Speak a little longer.'**
  String get vaatTooShort;

  /// Permission denied
  ///
  /// In en, this message translates to:
  /// **'Allow the microphone to record voice notes.'**
  String get vaatMicDenied;

  /// Photo remark button
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get vaatAddPhoto;

  /// Author is the current user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get vaatYou;

  /// Play voice note
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get vaatPlay;

  /// Stop voice note
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get vaatStop;

  /// Archive remark
  ///
  /// In en, this message translates to:
  /// **'Remove note'**
  String get vaatRemove;

  /// Bill PDF column
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get billColPhoto;

  /// Header on later bill pages
  ///
  /// In en, this message translates to:
  /// **'continued'**
  String get billContinued;

  /// Progress while building the bill PDF
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF with {count, plural, =1{1 photo} other{{count} photos}}…'**
  String billPdfPreparing(int count);
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
