import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HelaService'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'On-Demand Home & Emergency Services in Sri Lanka'**
  String get tagline;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @preferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get preferredLanguage;

  /// No description provided for @chooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your primary language for the app'**
  String get chooseLanguageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @sinhala.
  ///
  /// In en, this message translates to:
  /// **'සිංහල'**
  String get sinhala;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get tamil;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @changeTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changeTheme;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleProvider.
  ///
  /// In en, this message translates to:
  /// **'Technician / Artisan'**
  String get roleProvider;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Operations Admin'**
  String get roleAdmin;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch Role'**
  String get switchRole;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// No description provided for @navTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get navTracking;

  /// No description provided for @navPostJob.
  ///
  /// In en, this message translates to:
  /// **'Post Job'**
  String get navPostJob;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get navLeads;

  /// No description provided for @navOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get navOngoing;

  /// No description provided for @navEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// No description provided for @navJobsRadar.
  ///
  /// In en, this message translates to:
  /// **'Jobs Radar'**
  String get navJobsRadar;

  /// No description provided for @navMyQuotes.
  ///
  /// In en, this message translates to:
  /// **'My Quotes'**
  String get navMyQuotes;

  /// No description provided for @navOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get navOperations;

  /// No description provided for @navLiveMap.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get navLiveMap;

  /// No description provided for @navVerifications.
  ///
  /// In en, this message translates to:
  /// **'Verifications'**
  String get navVerifications;

  /// No description provided for @navVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get navVerification;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get navVerify;

  /// No description provided for @navCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get navCoverage;

  /// No description provided for @navTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HelaService'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find verified home service professionals or manage your service jobs across Sri Lanka.'**
  String get loginSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started with HelaService.'**
  String get createAccountSubtitle;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @newToHelaService.
  ///
  /// In en, this message translates to:
  /// **'New to HelaService?'**
  String get newToHelaService;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we will send a password reset link to your inbox.'**
  String get resetPasswordDesc;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @enterEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmailError;

  /// No description provided for @enterPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPasswordError;

  /// No description provided for @passwordLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordLengthError;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatchError;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP Code'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP Code'**
  String get verifyOtp;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit verification code'**
  String get enterOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendOtp;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @exploreAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Explore Services as Guest'**
  String get exploreAsGuest;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @orSignUpWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or sign up with email'**
  String get orSignUpWithEmail;

  /// No description provided for @smsNotice.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a 6-digit OTP code to verify your phone number.'**
  String get smsNotice;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Role & Profile'**
  String get completeProfileTitle;

  /// No description provided for @completeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself to get started'**
  String get completeProfileSubtitle;

  /// No description provided for @selectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Select Account Type'**
  String get selectAccountType;

  /// No description provided for @customerRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Post jobs & hire local technicians'**
  String get customerRoleDesc;

  /// No description provided for @providerRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Bid on jobs & offer expert services'**
  String get providerRoleDesc;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullNameAsNic.
  ///
  /// In en, this message translates to:
  /// **'Full name (as on NIC)'**
  String get fullNameAsNic;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Home / Dispatch Address'**
  String get address;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @primaryDistrict.
  ///
  /// In en, this message translates to:
  /// **'Primary Service District'**
  String get primaryDistrict;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Service Category'**
  String get category;

  /// No description provided for @primaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Primary Service Category'**
  String get primaryCategory;

  /// No description provided for @nicNumber.
  ///
  /// In en, this message translates to:
  /// **'National Identity Card (NIC) number'**
  String get nicNumber;

  /// No description provided for @nicFront.
  ///
  /// In en, this message translates to:
  /// **'NIC Front Photo'**
  String get nicFront;

  /// No description provided for @nicBack.
  ///
  /// In en, this message translates to:
  /// **'NIC Back Photo'**
  String get nicBack;

  /// No description provided for @detectGps.
  ///
  /// In en, this message translates to:
  /// **'Auto-Detect Current GPS'**
  String get detectGps;

  /// No description provided for @refreshGps.
  ///
  /// In en, this message translates to:
  /// **'Refresh GPS Location'**
  String get refreshGps;

  /// No description provided for @gpsDetected.
  ///
  /// In en, this message translates to:
  /// **'GPS Location Detected'**
  String get gpsDetected;

  /// No description provided for @gpsHint.
  ///
  /// In en, this message translates to:
  /// **'Used for live dispatch & nearest artisan routing across Sri Lanka'**
  String get gpsHint;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the HelaService Terms & Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @completeRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration & Continue'**
  String get completeRegistration;

  /// No description provided for @accountVerified.
  ///
  /// In en, this message translates to:
  /// **'Account verified'**
  String get accountVerified;

  /// No description provided for @postJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a Job Request'**
  String get postJobTitle;

  /// No description provided for @postJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect with verified artisans near your home across Sri Lanka'**
  String get postJobSubtitle;

  /// No description provided for @postJobGetQuotes.
  ///
  /// In en, this message translates to:
  /// **'Post Job & Get Quotes'**
  String get postJobGetQuotes;

  /// No description provided for @describeJobOrRepair.
  ///
  /// In en, this message translates to:
  /// **'Describe your job or repair'**
  String get describeJobOrRepair;

  /// No description provided for @describeJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add photos and your location. Nearby providers will send you price quotes.'**
  String get describeJobSubtitle;

  /// No description provided for @selectTradeCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a trade category'**
  String get selectTradeCategory;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @jobTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Kitchen pipe leaking under sink'**
  String get jobTitleHint;

  /// No description provided for @jobDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get jobDescription;

  /// No description provided for @jobDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem or what needs to be done in detail...'**
  String get jobDescriptionHint;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Estimated Budget (LKR)'**
  String get budget;

  /// No description provided for @budgetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2500'**
  String get budgetHint;

  /// No description provided for @jobLocationGps.
  ///
  /// In en, this message translates to:
  /// **'Job Location & GPS'**
  String get jobLocationGps;

  /// No description provided for @photosOfIssue.
  ///
  /// In en, this message translates to:
  /// **'Photos of the Issue'**
  String get photosOfIssue;

  /// No description provided for @jobPhotos.
  ///
  /// In en, this message translates to:
  /// **'Job Site Photos (Optional)'**
  String get jobPhotos;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @maxPhotosAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 4 photos allowed'**
  String get maxPhotosAllowed;

  /// No description provided for @yourExactLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Exact Location'**
  String get yourExactLocation;

  /// No description provided for @gpsCoordinatesLocked.
  ///
  /// In en, this message translates to:
  /// **'GPS Coordinates Locked'**
  String get gpsCoordinatesLocked;

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting your exact location...'**
  String get detectingLocation;

  /// No description provided for @tapToDetectGps.
  ///
  /// In en, this message translates to:
  /// **'Tap to detect your exact GPS location'**
  String get tapToDetectGps;

  /// No description provided for @streetAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Street address or landmark (optional)'**
  String get streetAddressOptional;

  /// No description provided for @submitJobRequest.
  ///
  /// In en, this message translates to:
  /// **'Post Job Request'**
  String get submitJobRequest;

  /// No description provided for @jobPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job request posted successfully!'**
  String get jobPostedSuccess;

  /// No description provided for @quotesAlert.
  ///
  /// In en, this message translates to:
  /// **'You will receive quotes from nearby verified artisans shortly.'**
  String get quotesAlert;

  /// No description provided for @enterJobTitleError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a job title'**
  String get enterJobTitleError;

  /// No description provided for @addDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Please add a description'**
  String get addDescriptionError;

  /// No description provided for @selectCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Please select a service category'**
  String get selectCategoryError;

  /// No description provided for @quotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Artisan Quotes & Bids'**
  String get quotesTitle;

  /// No description provided for @quotesReceived.
  ///
  /// In en, this message translates to:
  /// **'QUOTES RECEIVED'**
  String get quotesReceived;

  /// No description provided for @noQuotes.
  ///
  /// In en, this message translates to:
  /// **'No quotes received yet. Artisans in your area are reviewing your request.'**
  String get noQuotes;

  /// No description provided for @waitingForQuotes.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Quotes'**
  String get waitingForQuotes;

  /// No description provided for @waitingForQuotesDesc.
  ///
  /// In en, this message translates to:
  /// **'Your job has been posted. Nearby service providers will send you their price quotes shortly.'**
  String get waitingForQuotesDesc;

  /// No description provided for @providerHired.
  ///
  /// In en, this message translates to:
  /// **'{providerName} Hired!'**
  String providerHired(String providerName);

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @acceptQuoteHire.
  ///
  /// In en, this message translates to:
  /// **'Accept Quote & Hire?'**
  String get acceptQuoteHire;

  /// No description provided for @acceptHire.
  ///
  /// In en, this message translates to:
  /// **'Accept & Hire'**
  String get acceptHire;

  /// No description provided for @hiredSuccess.
  ///
  /// In en, this message translates to:
  /// **'has been hired successfully!'**
  String get hiredSuccess;

  /// No description provided for @sendQuote.
  ///
  /// In en, this message translates to:
  /// **'Send Quote / Estimate'**
  String get sendQuote;

  /// No description provided for @quoteAmount.
  ///
  /// In en, this message translates to:
  /// **'Quote Amount (LKR)'**
  String get quoteAmount;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time / Duration'**
  String get estimatedTime;

  /// No description provided for @estimatedTimeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 45 mins - 1 hour'**
  String get estimatedTimeHint;

  /// No description provided for @quoteNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes to Customer (Optional)'**
  String get quoteNotes;

  /// No description provided for @quoteNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Explain your approach, included materials, or warranty...'**
  String get quoteNotesHint;

  /// No description provided for @submitQuote.
  ///
  /// In en, this message translates to:
  /// **'Submit Quote to Customer'**
  String get submitQuote;

  /// No description provided for @submitPriceQuote.
  ///
  /// In en, this message translates to:
  /// **'Submit Your Price Quote'**
  String get submitPriceQuote;

  /// No description provided for @submitPriceQuoteSub.
  ///
  /// In en, this message translates to:
  /// **'Review the job details and send your quote to the customer.'**
  String get submitPriceQuoteSub;

  /// No description provided for @customerPhotos.
  ///
  /// In en, this message translates to:
  /// **'Customer Photos'**
  String get customerPhotos;

  /// No description provided for @yourQuotedPrice.
  ///
  /// In en, this message translates to:
  /// **'Your Quoted Price (LKR)'**
  String get yourQuotedPrice;

  /// No description provided for @estimatedArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival Time'**
  String get estimatedArrivalTime;

  /// No description provided for @messageToCustomerOptional.
  ///
  /// In en, this message translates to:
  /// **'Message to Customer (Optional)'**
  String get messageToCustomerOptional;

  /// No description provided for @sendPriceQuote.
  ///
  /// In en, this message translates to:
  /// **'Send Price Quote'**
  String get sendPriceQuote;

  /// No description provided for @quoteSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Quote submitted successfully!'**
  String get quoteSubmittedSuccess;

  /// No description provided for @acceptQuote.
  ///
  /// In en, this message translates to:
  /// **'Accept Quote'**
  String get acceptQuote;

  /// No description provided for @declineQuote.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineQuote;

  /// No description provided for @enterQuotedPriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your quoted price'**
  String get enterQuotedPriceError;

  /// No description provided for @enterValidPriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get enterValidPriceError;

  /// No description provided for @greetingAyubowan.
  ///
  /// In en, this message translates to:
  /// **'Ayubowan'**
  String get greetingAyubowan;

  /// No description provided for @findCertifiedArtisans.
  ///
  /// In en, this message translates to:
  /// **'Find certified local artisans ready to help today.'**
  String get findCertifiedArtisans;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search plumbers, electricians, carpenters...'**
  String get searchHint;

  /// No description provided for @searchServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Search plumbing, AC repair, electricians...'**
  String get searchServiceHint;

  /// No description provided for @haveRepairOrJob.
  ///
  /// In en, this message translates to:
  /// **'Have a Repair or Job?'**
  String get haveRepairOrJob;

  /// No description provided for @postDetailsBannerSub.
  ///
  /// In en, this message translates to:
  /// **'Post details & photos. Get price quotes from nearby providers.'**
  String get postDetailsBannerSub;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @artisansOnDuty.
  ///
  /// In en, this message translates to:
  /// **'Artisans on Duty'**
  String get artisansOnDuty;

  /// No description provided for @activeNearby.
  ///
  /// In en, this message translates to:
  /// **'Active Nearby'**
  String get activeNearby;

  /// No description provided for @radarActive.
  ///
  /// In en, this message translates to:
  /// **'Instant Dispatch Radar Active'**
  String get radarActive;

  /// No description provided for @avgArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Average arrival time: 14 mins in Colombo 03'**
  String get avgArrivalTime;

  /// No description provided for @topRatedTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Technicians'**
  String get topRatedTechnicians;

  /// No description provided for @verifiedChecksRatings.
  ///
  /// In en, this message translates to:
  /// **'Verified background checks & island-wide ratings'**
  String get verifiedChecksRatings;

  /// No description provided for @noTechniciansYet.
  ///
  /// In en, this message translates to:
  /// **'No technicians registered yet'**
  String get noTechniciansYet;

  /// No description provided for @emergencyHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need Immediate Emergency Service?'**
  String get emergencyHelpTitle;

  /// No description provided for @emergencyHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 Priority Auto-Dispatch active in your area'**
  String get emergencyHelpSubtitle;

  /// No description provided for @requestEmergency.
  ///
  /// In en, this message translates to:
  /// **'Request 24/7 Dispatch'**
  String get requestEmergency;

  /// No description provided for @topCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Services'**
  String get topCategories;

  /// No description provided for @viewAllServices.
  ///
  /// In en, this message translates to:
  /// **'View All Services'**
  String get viewAllServices;

  /// No description provided for @nearbyArtisans.
  ///
  /// In en, this message translates to:
  /// **'Nearby Verified Artisans'**
  String get nearbyArtisans;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviewsCount;

  /// No description provided for @startingFrom.
  ///
  /// In en, this message translates to:
  /// **'Starting from'**
  String get startingFrom;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Profile & Hire'**
  String get viewDetails;

  /// No description provided for @helaCareGuarantee.
  ///
  /// In en, this message translates to:
  /// **'HelaCare Guarantee'**
  String get helaCareGuarantee;

  /// No description provided for @helaCareDesc.
  ///
  /// In en, this message translates to:
  /// **'All booked visits include complimentary property damage coverage up to LKR 100,000.'**
  String get helaCareDesc;

  /// No description provided for @initialInspectionRate.
  ///
  /// In en, this message translates to:
  /// **'Initial Inspection Rate'**
  String get initialInspectionRate;

  /// No description provided for @quickBook.
  ///
  /// In en, this message translates to:
  /// **'Quick Book'**
  String get quickBook;

  /// No description provided for @serviceDetail.
  ///
  /// In en, this message translates to:
  /// **'Service Detail'**
  String get serviceDetail;

  /// No description provided for @transparentPricing.
  ///
  /// In en, this message translates to:
  /// **'Transparent Pricing'**
  String get transparentPricing;

  /// No description provided for @baseInspectionFee.
  ///
  /// In en, this message translates to:
  /// **'Base Inspection & Visit Fee'**
  String get baseInspectionFee;

  /// No description provided for @baseInspectionSub.
  ///
  /// In en, this message translates to:
  /// **'Covers doorstep diagnosis & transit costs'**
  String get baseInspectionSub;

  /// No description provided for @standardHourlyLabour.
  ///
  /// In en, this message translates to:
  /// **'Standard Hourly Labour'**
  String get standardHourlyLabour;

  /// No description provided for @emergencyRate.
  ///
  /// In en, this message translates to:
  /// **'Emergency / After-hours Rate'**
  String get emergencyRate;

  /// No description provided for @materialsBilledSeparately.
  ///
  /// In en, this message translates to:
  /// **'• Materials & replacement parts billed separately with store receipts.'**
  String get materialsBilledSeparately;

  /// No description provided for @aboutTechnician.
  ///
  /// In en, this message translates to:
  /// **'About the Technician'**
  String get aboutTechnician;

  /// No description provided for @recentWorkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recent Work Completed'**
  String get recentWorkCompleted;

  /// No description provided for @customerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// No description provided for @requestService.
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get requestService;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @noActiveDispatch.
  ///
  /// In en, this message translates to:
  /// **'No Active Dispatch'**
  String get noActiveDispatch;

  /// No description provided for @noActiveDispatchSub.
  ///
  /// In en, this message translates to:
  /// **'When you request a service, live GPS tracking appears here.'**
  String get noActiveDispatchSub;

  /// No description provided for @techOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Technician on the way • Live GPS'**
  String get techOnTheWay;

  /// No description provided for @estimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get estimatedArrival;

  /// No description provided for @arrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in'**
  String get arrivingIn;

  /// No description provided for @directPayCash.
  ///
  /// In en, this message translates to:
  /// **'Direct Pay at Site (Cash)'**
  String get directPayCash;

  /// No description provided for @inspectionFeeNotice.
  ///
  /// In en, this message translates to:
  /// **'standard inspection fee. No hidden platform charges.'**
  String get inspectionFeeNotice;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @shareTrip.
  ///
  /// In en, this message translates to:
  /// **'Share Trip'**
  String get shareTrip;

  /// No description provided for @jobFinishedRatePay.
  ///
  /// In en, this message translates to:
  /// **'Job Finished · Rate & Pay'**
  String get jobFinishedRatePay;

  /// No description provided for @callTech.
  ///
  /// In en, this message translates to:
  /// **'Call Tech'**
  String get callTech;

  /// No description provided for @checkoutBooking.
  ///
  /// In en, this message translates to:
  /// **'Checkout Booking'**
  String get checkoutBooking;

  /// No description provided for @serviceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service Completed!'**
  String get serviceCompleted;

  /// No description provided for @costBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cost Breakdown'**
  String get costBreakdown;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'PAID'**
  String get paid;

  /// No description provided for @baseDiagnosticVisit.
  ///
  /// In en, this message translates to:
  /// **'Base diagnostic & visit'**
  String get baseDiagnosticVisit;

  /// No description provided for @partsAndLabor.
  ///
  /// In en, this message translates to:
  /// **'Parts & labor'**
  String get partsAndLabor;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @settledDirectlyCash.
  ///
  /// In en, this message translates to:
  /// **'Settled directly (Cash on site)'**
  String get settledDirectlyCash;

  /// No description provided for @rateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your overall repair experience'**
  String get rateExperience;

  /// No description provided for @whatWentWell.
  ///
  /// In en, this message translates to:
  /// **'What went especially well?'**
  String get whatWentWell;

  /// No description provided for @leaveReviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Leave a detailed review (optional)'**
  String get leaveReviewOptional;

  /// No description provided for @tipProvider.
  ///
  /// In en, this message translates to:
  /// **'Tip Provider — 100% goes to provider'**
  String get tipProvider;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @needHelpOrder.
  ///
  /// In en, this message translates to:
  /// **'Need help with this order?'**
  String get needHelpOrder;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @verifiedArtisan.
  ///
  /// In en, this message translates to:
  /// **'NIC Verified'**
  String get verifiedArtisan;

  /// No description provided for @activeFleet.
  ///
  /// In en, this message translates to:
  /// **'Active Fleet'**
  String get activeFleet;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNow;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'km away'**
  String get kmAway;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @activeBookings.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBookings;

  /// No description provided for @pastBookings.
  ///
  /// In en, this message translates to:
  /// **'Past History'**
  String get pastBookings;

  /// No description provided for @activeServiceVisit.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE SERVICE VISIT'**
  String get activeServiceVisit;

  /// No description provided for @pastCompletedServices.
  ///
  /// In en, this message translates to:
  /// **'Past Completed Services'**
  String get pastCompletedServices;

  /// No description provided for @openLiveGpsTracking.
  ///
  /// In en, this message translates to:
  /// **'Open Live GPS Tracking'**
  String get openLiveGpsTracking;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No job ledger records found'**
  String get noBookingsFound;

  /// No description provided for @noBookingsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No bookings recorded yet'**
  String get noBookingsRecorded;

  /// No description provided for @browseArtisansExplore.
  ///
  /// In en, this message translates to:
  /// **'Browse certified artisans on the Explore tab.'**
  String get browseArtisansExplore;

  /// No description provided for @bookTechnician.
  ///
  /// In en, this message translates to:
  /// **'Book an Artisan'**
  String get bookTechnician;

  /// No description provided for @callArtisan.
  ///
  /// In en, this message translates to:
  /// **'Call Artisan'**
  String get callArtisan;

  /// No description provided for @trackLocation.
  ///
  /// In en, this message translates to:
  /// **'Track Location'**
  String get trackLocation;

  /// No description provided for @leaveReview.
  ///
  /// In en, this message translates to:
  /// **'Rate & Review'**
  String get leaveReview;

  /// No description provided for @rateJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Completion & Rating'**
  String get rateJobTitle;

  /// No description provided for @rateJobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How was your service experience with'**
  String get rateJobSubtitle;

  /// No description provided for @ratingFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share feedback on quality, punctuality, and craftsmanship...'**
  String get ratingFeedbackHint;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Review & Finish'**
  String get submitRating;

  /// No description provided for @providerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Artisan Operations Hub'**
  String get providerDashboardTitle;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online & Accepting Leads'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline / Paused'**
  String get statusOffline;

  /// No description provided for @youAreOnline.
  ///
  /// In en, this message translates to:
  /// **'You are ONLINE'**
  String get youAreOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are OFFLINE'**
  String get youAreOffline;

  /// No description provided for @activeDispatchSub.
  ///
  /// In en, this message translates to:
  /// **'Active Dispatch — Receiving job requests from nearby customers'**
  String get activeDispatchSub;

  /// No description provided for @openJobRequests.
  ///
  /// In en, this message translates to:
  /// **'Open Job Requests'**
  String get openJobRequests;

  /// No description provided for @fromCustomers.
  ///
  /// In en, this message translates to:
  /// **'From Customers'**
  String get fromCustomers;

  /// No description provided for @noOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'No open requests right now'**
  String get noOpenRequests;

  /// No description provided for @customerRequestsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Customer requests in your trade category will appear here.'**
  String get customerRequestsAppearHere;

  /// No description provided for @scheduledBookings.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Bookings'**
  String get scheduledBookings;

  /// No description provided for @noActiveBookings.
  ///
  /// In en, this message translates to:
  /// **'No active bookings right now'**
  String get noActiveBookings;

  /// No description provided for @todayEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todayEarnings;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobs;

  /// No description provided for @activeLeads.
  ///
  /// In en, this message translates to:
  /// **'Active Job Leads'**
  String get activeLeads;

  /// No description provided for @noLeadsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No new job leads in your area right now. Keep your status online to receive alerts.'**
  String get noLeadsAvailable;

  /// No description provided for @noQuotesYet.
  ///
  /// In en, this message translates to:
  /// **'No quotes submitted yet'**
  String get noQuotesYet;

  /// No description provided for @browseRadarDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse the Jobs Radar and send price quotes to customers.'**
  String get browseRadarDesc;

  /// No description provided for @acceptedCaps.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get acceptedCaps;

  /// No description provided for @pendingResponseCaps.
  ///
  /// In en, this message translates to:
  /// **'PENDING RESPONSE'**
  String get pendingResponseCaps;

  /// No description provided for @declinedCaps.
  ///
  /// In en, this message translates to:
  /// **'DECLINED'**
  String get declinedCaps;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from HelaService?'**
  String get logoutConfirm;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support Hotline'**
  String get contactSupport;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Settings'**
  String get appSettings;

  /// No description provided for @editProfileAndPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile & Photo'**
  String get editProfileAndPhoto;

  /// No description provided for @editContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact Info'**
  String get editContactInfo;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @profilePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo (Required)'**
  String get profilePhotoRequired;

  /// No description provided for @profilePhotoRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear face photo for your service provider profile.'**
  String get profilePhotoRequiredHint;

  /// No description provided for @profilePhotoRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Profile photo is required for Service Providers'**
  String get profilePhotoRequiredError;

  /// No description provided for @addPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhotoAction;

  /// No description provided for @changePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhotoAction;

  /// No description provided for @dispatchAndContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Dispatch & Contact Info'**
  String get dispatchAndContactInfo;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @verifiedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Verified Customer'**
  String get verifiedCustomer;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @paymentMethodsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct cash settlement at service site'**
  String get paymentMethodsSubtitle;

  /// No description provided for @islandCustomerHelpline.
  ///
  /// In en, this message translates to:
  /// **'24/7 Island Customer Helpline'**
  String get islandCustomerHelpline;

  /// No description provided for @islandCustomerHelplineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hotline: 011 234 5678 (Toll Free)'**
  String get islandCustomerHelplineSubtitle;

  /// No description provided for @appearanceAndTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get appearanceAndTheme;

  /// No description provided for @chooseAppearance.
  ///
  /// In en, this message translates to:
  /// **'Choose Appearance'**
  String get chooseAppearance;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @switchOperationalView.
  ///
  /// In en, this message translates to:
  /// **'Switch Operational View'**
  String get switchOperationalView;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @logoutModalTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutModalTitle;

  /// No description provided for @logoutModalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of HelaService?'**
  String get logoutModalConfirm;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Profile Details'**
  String get profileDetails;

  /// No description provided for @serviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Service Location'**
  String get serviceLocation;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get selectDistrict;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @addressOrAreaOptional.
  ///
  /// In en, this message translates to:
  /// **'Address / Area Details (Optional)'**
  String get addressOrAreaOptional;

  /// No description provided for @addressOrAreaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12/A, High Level Road, Colombo 06'**
  String get addressOrAreaHint;

  /// No description provided for @useExactLiveGps.
  ///
  /// In en, this message translates to:
  /// **'Optional: Use exact live GPS'**
  String get useExactLiveGps;

  /// No description provided for @gpsLocationSet.
  ///
  /// In en, this message translates to:
  /// **'GPS Location set (Tap to refresh)'**
  String get gpsLocationSet;

  /// No description provided for @detectingGps.
  ///
  /// In en, this message translates to:
  /// **'Detecting GPS...'**
  String get detectingGps;

  /// No description provided for @expressDispatchRoute.
  ///
  /// In en, this message translates to:
  /// **'EXPRESS DISPATCH ROUTE'**
  String get expressDispatchRoute;

  /// No description provided for @autoPassesIn.
  ///
  /// In en, this message translates to:
  /// **'Auto-passes in'**
  String get autoPassesIn;

  /// No description provided for @newJobRequest.
  ///
  /// In en, this message translates to:
  /// **'New Job Request'**
  String get newJobRequest;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgent;

  /// No description provided for @guaranteedBasePayout.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed Base Payout'**
  String get guaranteedBasePayout;

  /// No description provided for @directSettlementCashAtSite.
  ///
  /// In en, this message translates to:
  /// **'Direct Settlement\nCash at Service Site'**
  String get directSettlementCashAtSite;

  /// No description provided for @serviceNote.
  ///
  /// In en, this message translates to:
  /// **'Service Note'**
  String get serviceNote;

  /// No description provided for @pullOverSafelyNote.
  ///
  /// In en, this message translates to:
  /// **'Pull over safely before confirming arrival navigation'**
  String get pullOverSafelyNote;

  /// No description provided for @reportEnRouteDelay.
  ///
  /// In en, this message translates to:
  /// **'Report En-Route Delay'**
  String get reportEnRouteDelay;

  /// No description provided for @enRouteNavigation.
  ///
  /// In en, this message translates to:
  /// **'En Route Navigation'**
  String get enRouteNavigation;

  /// No description provided for @turnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn Left'**
  String get turnLeft;

  /// No description provided for @turnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn Right'**
  String get turnRight;

  /// No description provided for @googleMapsOrWaze.
  ///
  /// In en, this message translates to:
  /// **'Google Maps / Waze'**
  String get googleMapsOrWaze;

  /// No description provided for @customerNotifiedOfArrival.
  ///
  /// In en, this message translates to:
  /// **'Customer notified of your arrival'**
  String get customerNotifiedOfArrival;

  /// No description provided for @nationalIdVerification.
  ///
  /// In en, this message translates to:
  /// **'National ID (NIC) Verification'**
  String get nationalIdVerification;

  /// No description provided for @verifiedArtisanNetworkSriLanka.
  ///
  /// In en, this message translates to:
  /// **'Verified Artisan Network — Sri Lanka'**
  String get verifiedArtisanNetworkSriLanka;

  /// No description provided for @fastTrackVerificationChecklist.
  ///
  /// In en, this message translates to:
  /// **'Fast-Track Verification Checklist'**
  String get fastTrackVerificationChecklist;

  /// No description provided for @callPartnerSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Partner Support 1340 (Toll Free)'**
  String get callPartnerSupport;

  /// No description provided for @endToEndEncryptedVault.
  ///
  /// In en, this message translates to:
  /// **'Photos stored securely • Only seen by HelaService admins'**
  String get endToEndEncryptedVault;

  /// No description provided for @nicUploadFileLimitHint.
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG or HEIC (Max 600 KB)'**
  String get nicUploadFileLimitHint;

  /// No description provided for @nicSecureStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'Photos are stored securely and only seen by HelaService admins.'**
  String get nicSecureStorageDesc;

  /// No description provided for @uploadingToVault.
  ///
  /// In en, this message translates to:
  /// **'Uploading securely...'**
  String get uploadingToVault;

  /// No description provided for @emergencyAvailable247.
  ///
  /// In en, this message translates to:
  /// **'24/7 Emergency Dispatch Available'**
  String get emergencyAvailable247;

  /// No description provided for @emergencyAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive urgent priority service requests anytime'**
  String get emergencyAvailableDesc;

  /// No description provided for @operationalDistrict.
  ///
  /// In en, this message translates to:
  /// **'Operational District'**
  String get operationalDistrict;

  /// No description provided for @primaryTradeCategory.
  ///
  /// In en, this message translates to:
  /// **'Primary Trade Category'**
  String get primaryTradeCategory;

  /// No description provided for @quotesCount.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get quotesCount;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'HelaService Operations Admin'**
  String get adminDashboardTitle;

  /// No description provided for @platformOverview.
  ///
  /// In en, this message translates to:
  /// **'Platform Overview'**
  String get platformOverview;

  /// No description provided for @activeTechnicians.
  ///
  /// In en, this message translates to:
  /// **'Active Technicians'**
  String get activeTechnicians;

  /// No description provided for @pendingVerifications.
  ///
  /// In en, this message translates to:
  /// **'Pending Verifications'**
  String get pendingVerifications;

  /// No description provided for @totalDispatchedJobs.
  ///
  /// In en, this message translates to:
  /// **'Total Jobs Dispatched'**
  String get totalDispatchedJobs;

  /// No description provided for @grossBookingValue.
  ///
  /// In en, this message translates to:
  /// **'Gross Booking Value'**
  String get grossBookingValue;

  /// No description provided for @systemHealth.
  ///
  /// In en, this message translates to:
  /// **'System Health: Optimal'**
  String get systemHealth;

  /// No description provided for @pendingTechnicianApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Technician Approvals'**
  String get pendingTechnicianApprovals;

  /// No description provided for @disputeResolutionCenter.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution Center'**
  String get disputeResolutionCenter;

  /// No description provided for @platformAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Platform Analytics & Revenue'**
  String get platformAnalytics;

  /// No description provided for @superAdminPrivileges.
  ///
  /// In en, this message translates to:
  /// **'Super Admin Privileges Active'**
  String get superAdminPrivileges;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'System Audit Logs'**
  String get auditLogs;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @failedToPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick photo'**
  String get failedToPickPhoto;

  /// No description provided for @pleaseAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service to continue.'**
  String get pleaseAcceptTerms;

  /// No description provided for @pleaseUploadNicFront.
  ///
  /// In en, this message translates to:
  /// **'Please upload a photo of the front of your NIC'**
  String get pleaseUploadNicFront;

  /// No description provided for @pleaseUploadNicBack.
  ///
  /// In en, this message translates to:
  /// **'Please upload a photo of the back of your NIC'**
  String get pleaseUploadNicBack;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit'**
  String get failedToSubmit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @sec.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get sec;

  /// No description provided for @uploadProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Photo'**
  String get uploadProfilePhoto;

  /// No description provided for @uploadNicFront.
  ///
  /// In en, this message translates to:
  /// **'Upload NIC Front'**
  String get uploadNicFront;

  /// No description provided for @uploadNicBack.
  ///
  /// In en, this message translates to:
  /// **'Upload NIC Back'**
  String get uploadNicBack;

  /// No description provided for @nicFrontRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload a photo of the front of your NIC'**
  String get nicFrontRequired;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required *'**
  String get requiredField;

  /// No description provided for @uploadClearFacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear face photo for your service provider profile.'**
  String get uploadClearFacePhoto;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @onTimeArrival.
  ///
  /// In en, this message translates to:
  /// **'On-Time'**
  String get onTimeArrival;

  /// No description provided for @artisanProfile.
  ///
  /// In en, this message translates to:
  /// **'Artisan Profile'**
  String get artisanProfile;

  /// No description provided for @jobsDone.
  ///
  /// In en, this message translates to:
  /// **'Jobs Done'**
  String get jobsDone;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @promptArrival.
  ///
  /// In en, this message translates to:
  /// **'Prompt Arrival'**
  String get promptArrival;

  /// No description provided for @operatingDistrict.
  ///
  /// In en, this message translates to:
  /// **'Operating District'**
  String get operatingDistrict;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @nicUploaded.
  ///
  /// In en, this message translates to:
  /// **'NIC front & back uploaded at registration'**
  String get nicUploaded;

  /// No description provided for @baseLocation.
  ///
  /// In en, this message translates to:
  /// **'Workshop / Base GPS Location'**
  String get baseLocation;

  /// No description provided for @noGpsSet.
  ///
  /// In en, this message translates to:
  /// **'No exact GPS coordinates set'**
  String get noGpsSet;

  /// No description provided for @distanceCalcHint.
  ///
  /// In en, this message translates to:
  /// **'Calculates real-time distance to open customer jobs'**
  String get distanceCalcHint;

  /// No description provided for @autoDetectGps.
  ///
  /// In en, this message translates to:
  /// **'Auto-Detect & Update Current GPS'**
  String get autoDetectGps;

  /// No description provided for @jobDispatchSettings.
  ///
  /// In en, this message translates to:
  /// **'Job Dispatch Settings'**
  String get jobDispatchSettings;

  /// No description provided for @emergencyCallout.
  ///
  /// In en, this message translates to:
  /// **'Emergency Night Callout'**
  String get emergencyCallout;

  /// No description provided for @emergencyCalloutDesc.
  ///
  /// In en, this message translates to:
  /// **'Accept urgent visits between 8 PM - 6 AM at 1.5x surge rate'**
  String get emergencyCalloutDesc;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Preferences & Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Theme'**
  String get themeMode;

  /// No description provided for @currentTheme.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentTheme;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language / භාෂාව / மொழி'**
  String get appLanguage;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLanguage;

  /// No description provided for @switchToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Switch to Customer Mode'**
  String get switchToCustomer;

  /// No description provided for @switchToCustomerDesc.
  ///
  /// In en, this message translates to:
  /// **'Book technicians for your own home or office'**
  String get switchToCustomerDesc;

  /// No description provided for @broadcastAlert.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Alert'**
  String get broadcastAlert;

  /// No description provided for @broadcastAlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Send high-priority notification to all verified artisans currently online across Sri Lanka.'**
  String get broadcastAlertDesc;

  /// No description provided for @sendBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Send Broadcast'**
  String get sendBroadcast;

  /// No description provided for @adminConsole.
  ///
  /// In en, this message translates to:
  /// **'Admin Console Settings'**
  String get adminConsole;

  /// No description provided for @platformHealth.
  ///
  /// In en, this message translates to:
  /// **'Island Platform Health & Telematics'**
  String get platformHealth;

  /// No description provided for @coreServices.
  ///
  /// In en, this message translates to:
  /// **'Core Services'**
  String get coreServices;

  /// No description provided for @pendingKyc.
  ///
  /// In en, this message translates to:
  /// **'Pending KYC'**
  String get pendingKyc;

  /// No description provided for @operationsControls.
  ///
  /// In en, this message translates to:
  /// **'Operations Controls'**
  String get operationsControls;

  /// No description provided for @adminTeamGovernance.
  ///
  /// In en, this message translates to:
  /// **'Admin Team & Access Governance'**
  String get adminTeamGovernance;

  /// No description provided for @adminTeamGovernanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage team, invite admins & configure permissions'**
  String get adminTeamGovernanceDesc;

  /// No description provided for @emergencyBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Emergency Island Broadcast'**
  String get emergencyBroadcast;

  /// No description provided for @emergencyBroadcastDesc.
  ///
  /// In en, this message translates to:
  /// **'Send alerts to active artisans across districts'**
  String get emergencyBroadcastDesc;

  /// No description provided for @switchOperationalViewDesc.
  ///
  /// In en, this message translates to:
  /// **'Test user-facing customer or technician flows'**
  String get switchOperationalViewDesc;

  /// No description provided for @jobLedger.
  ///
  /// In en, this message translates to:
  /// **'Job Bid & Tracking Ledger'**
  String get jobLedger;

  /// No description provided for @jobLedgerNav.
  ///
  /// In en, this message translates to:
  /// **'Job Ledger'**
  String get jobLedgerNav;

  /// No description provided for @jobLedgerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Historical audit of service bids, tracking, dispatch outcomes & customer satisfaction'**
  String get jobLedgerSubtitle;

  /// No description provided for @totalCompletedJobs.
  ///
  /// In en, this message translates to:
  /// **'Total Completed Jobs'**
  String get totalCompletedJobs;

  /// No description provided for @totalInProgressJobs.
  ///
  /// In en, this message translates to:
  /// **'Total In-Progress Jobs'**
  String get totalInProgressJobs;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get filterInProgress;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @wonBy.
  ///
  /// In en, this message translates to:
  /// **'Won By'**
  String get wonBy;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @bidAmount.
  ///
  /// In en, this message translates to:
  /// **'Bid Amount'**
  String get bidAmount;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// No description provided for @noBookingsMatchingFilter.
  ///
  /// In en, this message translates to:
  /// **'No bookings match the selected status filter.'**
  String get noBookingsMatchingFilter;

  /// No description provided for @delayReported.
  ///
  /// In en, this message translates to:
  /// **'Delay Reported'**
  String get delayReported;

  /// No description provided for @trackingOutcome.
  ///
  /// In en, this message translates to:
  /// **'Tracking Outcome'**
  String get trackingOutcome;

  /// No description provided for @customerSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Customer Satisfaction'**
  String get customerSatisfaction;

  /// No description provided for @manualReview.
  ///
  /// In en, this message translates to:
  /// **'Manual Review'**
  String get manualReview;

  /// No description provided for @cloudStoragePath.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage Path'**
  String get cloudStoragePath;

  /// No description provided for @manualNicReview.
  ///
  /// In en, this message translates to:
  /// **'Manual NIC Review'**
  String get manualNicReview;

  /// No description provided for @ocrAuditConcordant.
  ///
  /// In en, this message translates to:
  /// **'OCR Audit — All 4 Fields Concordant'**
  String get ocrAuditConcordant;

  /// No description provided for @ocrAuditFlagged.
  ///
  /// In en, this message translates to:
  /// **'OCR Audit — Discrepancy Flagged'**
  String get ocrAuditFlagged;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterFullName;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @enterNicError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your National Identity Card (NIC) number'**
  String get enterNicError;

  /// No description provided for @createCustomerAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Customer Account'**
  String get createCustomerAccount;

  /// No description provided for @customerRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book trusted home services in a few taps across Sri Lanka'**
  String get customerRegisterSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddressLabel;

  /// No description provided for @accountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Account email'**
  String get accountEmailLabel;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @customerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone number (for artisan dispatch)'**
  String get customerPhoneLabel;

  /// No description provided for @providerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact mobile number (for customer dispatch)'**
  String get providerPhoneLabel;

  /// No description provided for @homeAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Home address'**
  String get homeAddressLabel;

  /// No description provided for @becomeProvider.
  ///
  /// In en, this message translates to:
  /// **'Become a Service Provider'**
  String get becomeProvider;

  /// No description provided for @providerRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn island-wide by taking verified jobs near you across Sri Lanka'**
  String get providerRegisterSubtitle;

  /// No description provided for @agreeProviderTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Provider Terms, platform commission rates, and NIC verification process'**
  String get agreeProviderTerms;

  /// No description provided for @createAccountVerifyNic.
  ///
  /// In en, this message translates to:
  /// **'Create Account & Verify NIC'**
  String get createAccountVerifyNic;

  /// No description provided for @selectDelayReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason to adjust the customer ETA by +10 mins:'**
  String get selectDelayReason;

  /// No description provided for @heavyTraffic.
  ///
  /// In en, this message translates to:
  /// **'Heavy Traffic'**
  String get heavyTraffic;

  /// No description provided for @monsoonRain.
  ///
  /// In en, this message translates to:
  /// **'Monsoon Rain'**
  String get monsoonRain;

  /// No description provided for @roadDetour.
  ///
  /// In en, this message translates to:
  /// **'Road Detour'**
  String get roadDetour;

  /// No description provided for @refuelingStop.
  ///
  /// In en, this message translates to:
  /// **'Refueling Stop'**
  String get refuelingStop;

  /// No description provided for @chatWithCustomer.
  ///
  /// In en, this message translates to:
  /// **'Chat with Customer'**
  String get chatWithCustomer;

  /// No description provided for @callCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'Call Customer Phone'**
  String get callCustomerPhone;

  /// No description provided for @customerPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Customer phone number not available'**
  String get customerPhoneNotAvailable;

  /// No description provided for @entryInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry Instructions: '**
  String get entryInstructionsLabel;

  /// No description provided for @noSpecialEntryInstructions.
  ///
  /// In en, this message translates to:
  /// **'No special entry instructions provided.'**
  String get noSpecialEntryInstructions;

  /// No description provided for @arrivedAtLocation.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Location'**
  String get arrivedAtLocation;

  /// No description provided for @slideToConfirmArrival.
  ///
  /// In en, this message translates to:
  /// **'Slide to Confirm Arrival'**
  String get slideToConfirmArrival;

  /// No description provided for @arrivalConfirmedNotified.
  ///
  /// In en, this message translates to:
  /// **'Arrival confirmed! Customer notified.'**
  String get arrivalConfirmedNotified;

  /// No description provided for @arrivalRecordedReady.
  ///
  /// In en, this message translates to:
  /// **'Arrival recorded — ready to commence service'**
  String get arrivalRecordedReady;

  /// No description provided for @customerWillBeNotified.
  ///
  /// In en, this message translates to:
  /// **'Customer will be notified of your immediate arrival'**
  String get customerWillBeNotified;

  /// No description provided for @reportTrafficDelay.
  ///
  /// In en, this message translates to:
  /// **'Report Traffic / Delay'**
  String get reportTrafficDelay;

  /// No description provided for @gpsActiveDevice.
  ///
  /// In en, this message translates to:
  /// **'GPS Active (Real-Time Device Position)'**
  String get gpsActiveDevice;

  /// No description provided for @gpsActivePrecision.
  ///
  /// In en, this message translates to:
  /// **'GPS Active (High Precision)'**
  String get gpsActivePrecision;

  /// No description provided for @orderPaymentSupport.
  ///
  /// In en, this message translates to:
  /// **'Order & Payment Support'**
  String get orderPaymentSupport;

  /// No description provided for @orderSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Have an issue with this job or fee dispute? Our 24/7 support line is ready to assist.'**
  String get orderSupportDesc;

  /// No description provided for @callSupportHotline.
  ///
  /// In en, this message translates to:
  /// **'Call Support Hotline 1340'**
  String get callSupportHotline;

  /// No description provided for @tollFreeCare.
  ///
  /// In en, this message translates to:
  /// **'Toll-free 24/7 customer care'**
  String get tollFreeCare;

  /// No description provided for @savingProgress.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingProgress;

  /// No description provided for @ratingExceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional! 5.0'**
  String get ratingExceptional;

  /// No description provided for @ratingGreat.
  ///
  /// In en, this message translates to:
  /// **'Great, 4.0'**
  String get ratingGreat;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good, 3.0'**
  String get ratingGood;

  /// No description provided for @ratingOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay, 2.0'**
  String get ratingOkay;

  /// No description provided for @ratingNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs work, 1.0'**
  String get ratingNeedsWork;

  /// No description provided for @tagPunctual.
  ///
  /// In en, this message translates to:
  /// **'Punctual'**
  String get tagPunctual;

  /// No description provided for @tagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get tagPolite;

  /// No description provided for @tagCleanWork.
  ///
  /// In en, this message translates to:
  /// **'Clean Work'**
  String get tagCleanWork;

  /// No description provided for @tagFairPrice.
  ///
  /// In en, this message translates to:
  /// **'Fair Price'**
  String get tagFairPrice;

  /// No description provided for @tipSmallTea.
  ///
  /// In en, this message translates to:
  /// **'Small Tea'**
  String get tipSmallTea;

  /// No description provided for @tipGenerous.
  ///
  /// In en, this message translates to:
  /// **'Generous'**
  String get tipGenerous;

  /// No description provided for @tipCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get tipCustom;

  /// No description provided for @tipEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get tipEnterAmount;

  /// No description provided for @roleSwitchDesc.
  ///
  /// In en, this message translates to:
  /// **'Same account, different way of using HelaService'**
  String get roleSwitchDesc;

  /// No description provided for @roleCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book and track home services'**
  String get roleCustomerSubtitle;

  /// No description provided for @roleProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go online and take job requests'**
  String get roleProviderSubtitle;

  /// No description provided for @roleAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform back-office tools'**
  String get roleAdminSubtitle;

  /// No description provided for @nicVerificationDeskTitle.
  ///
  /// In en, this message translates to:
  /// **'Technician Identity Verification Desk'**
  String get nicVerificationDeskTitle;

  /// No description provided for @statPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get statPendingReview;

  /// No description provided for @statApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statApproved;

  /// No description provided for @statNeedsResubmission.
  ///
  /// In en, this message translates to:
  /// **'Needs Resubmission'**
  String get statNeedsResubmission;

  /// No description provided for @statFlaggedRejected.
  ///
  /// In en, this message translates to:
  /// **'Flagged / Rejected'**
  String get statFlaggedRejected;

  /// No description provided for @verificationQueueClear.
  ///
  /// In en, this message translates to:
  /// **'Verification Queue Clear'**
  String get verificationQueueClear;

  /// No description provided for @incomingVerificationStream.
  ///
  /// In en, this message translates to:
  /// **'Incoming Verification Stream'**
  String get incomingVerificationStream;

  /// No description provided for @selectArtisanAudit.
  ///
  /// In en, this message translates to:
  /// **'Select an artisan to audit documents'**
  String get selectArtisanAudit;

  /// No description provided for @reviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Review Required'**
  String get reviewRequired;

  /// No description provided for @activeAndVerified.
  ///
  /// In en, this message translates to:
  /// **'Active & Verified'**
  String get activeAndVerified;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @pendingVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerificationStatus;

  /// No description provided for @approveAndActivateArtisan.
  ///
  /// In en, this message translates to:
  /// **'Approve & Activate Artisan'**
  String get approveAndActivateArtisan;

  /// No description provided for @artisanActivated.
  ///
  /// In en, this message translates to:
  /// **'Artisan Activated'**
  String get artisanActivated;

  /// No description provided for @rejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectAction;

  /// No description provided for @requestClearerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Request Clearer Photo'**
  String get requestClearerPhoto;

  /// No description provided for @ocrDataField.
  ///
  /// In en, this message translates to:
  /// **'Data Field'**
  String get ocrDataField;

  /// No description provided for @ocrExtracted.
  ///
  /// In en, this message translates to:
  /// **'OCR Extracted'**
  String get ocrExtracted;

  /// No description provided for @ocrRegistry.
  ///
  /// In en, this message translates to:
  /// **'Registry'**
  String get ocrRegistry;

  /// No description provided for @ocrStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ocrStatus;

  /// No description provided for @ocrFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get ocrFullName;

  /// No description provided for @ocrNicNumber.
  ///
  /// In en, this message translates to:
  /// **'NIC Number'**
  String get ocrNicNumber;

  /// No description provided for @ocrLocation.
  ///
  /// In en, this message translates to:
  /// **'Electoral Address / Location'**
  String get ocrLocation;

  /// No description provided for @ocrTradeNote.
  ///
  /// In en, this message translates to:
  /// **'Trade / Document Note'**
  String get ocrTradeNote;

  /// No description provided for @docNicFront.
  ///
  /// In en, this message translates to:
  /// **'NIC Front'**
  String get docNicFront;

  /// No description provided for @docNicBack.
  ///
  /// In en, this message translates to:
  /// **'NIC Back'**
  String get docNicBack;

  /// No description provided for @docLiveness.
  ///
  /// In en, this message translates to:
  /// **'Liveness'**
  String get docLiveness;

  /// No description provided for @navCoverageAndCategories.
  ///
  /// In en, this message translates to:
  /// **'Coverage & Categories'**
  String get navCoverageAndCategories;

  /// No description provided for @navAdminsAndTeam.
  ///
  /// In en, this message translates to:
  /// **'Admins & Team'**
  String get navAdminsAndTeam;

  /// No description provided for @navArtisans.
  ///
  /// In en, this message translates to:
  /// **'Artisans'**
  String get navArtisans;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navServiceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Service Metrics'**
  String get navServiceMetrics;

  /// No description provided for @navPlatformSettings.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get navPlatformSettings;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @opsPortal.
  ///
  /// In en, this message translates to:
  /// **'Ops Portal'**
  String get opsPortal;

  /// No description provided for @operationsCore.
  ///
  /// In en, this message translates to:
  /// **'OPERATIONS CORE'**
  String get operationsCore;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @fullNameNicLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name (as in NIC)'**
  String get fullNameNicLabel;

  /// No description provided for @nicNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'National Identity Card (NIC) number'**
  String get nicNumberLabel;

  /// No description provided for @opsCoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Island Operations Core'**
  String get opsCoreSubtitle;

  /// No description provided for @islandOperationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Island Operations'**
  String get islandOperationsTitle;

  /// No description provided for @activeProvidersTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Providers'**
  String get activeProvidersTitle;

  /// No description provided for @liveBadge.
  ///
  /// In en, this message translates to:
  /// **'+2 Live'**
  String get liveBadge;

  /// No description provided for @onlineFleetSummary.
  ///
  /// In en, this message translates to:
  /// **'{online} Online • {verified} Verified Fleet'**
  String onlineFleetSummary(String online, String verified);

  /// No description provided for @totalBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Total Bookings'**
  String get totalBookingsTitle;

  /// No description provided for @completedInProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{completed} Completed • {inProgress} In Progress'**
  String completedInProgressSummary(String completed, String inProgress);

  /// No description provided for @nicScreeningTitle.
  ///
  /// In en, this message translates to:
  /// **'NIC Screening'**
  String get nicScreeningTitle;

  /// No description provided for @clearStatusBadge.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearStatusBadge;

  /// No description provided for @verificationDossiersLogged.
  ///
  /// In en, this message translates to:
  /// **'{count} Verification Dossiers Logged'**
  String verificationDossiersLogged(String count);

  /// No description provided for @allSriLankaLiveTraffic.
  ///
  /// In en, this message translates to:
  /// **'Live Traffic'**
  String get allSriLankaLiveTraffic;

  /// No description provided for @heatmapBadge.
  ///
  /// In en, this message translates to:
  /// **'Heatmap'**
  String get heatmapBadge;

  /// No description provided for @activeArtisanFleetLive.
  ///
  /// In en, this message translates to:
  /// **'Live Top Roster'**
  String get activeArtisanFleetLive;

  /// No description provided for @districtCapacityRealtime.
  ///
  /// In en, this message translates to:
  /// **'District Capacity — Real-time Load'**
  String get districtCapacityRealtime;

  /// No description provided for @noActiveArtisansFleet.
  ///
  /// In en, this message translates to:
  /// **'No active artisans found in fleet'**
  String get noActiveArtisansFleet;

  /// No description provided for @tradeAndZone.
  ///
  /// In en, this message translates to:
  /// **'Trade: {trade} • Zone: {zone}'**
  String tradeAndZone(String trade, String zone);

  /// No description provided for @selectOpenJobRequest.
  ///
  /// In en, this message translates to:
  /// **'Select Open Job Request to Dispatch:'**
  String get selectOpenJobRequest;

  /// No description provided for @noOpenCustomerRequests.
  ///
  /// In en, this message translates to:
  /// **'No open customer requests awaiting dispatch.'**
  String get noOpenCustomerRequests;

  /// No description provided for @assignAction.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignAction;

  /// No description provided for @dispatchedArtisanToJob.
  ///
  /// In en, this message translates to:
  /// **'Dispatched {artisan} to {job}'**
  String dispatchedArtisanToJob(String artisan, String job);

  /// No description provided for @navDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get navDisputes;

  /// No description provided for @tradeCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade Service Categories'**
  String get tradeCategoriesTitle;

  /// No description provided for @addNewCategoryAction.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addNewCategoryAction;

  /// No description provided for @catalogDensityTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog Density'**
  String get catalogDensityTitle;

  /// No description provided for @viewingBadge.
  ///
  /// In en, this message translates to:
  /// **'VIEWING'**
  String get viewingBadge;

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Categories'**
  String categoriesCount(String count);

  /// No description provided for @activeTradeServicesPublished.
  ///
  /// In en, this message translates to:
  /// **'{count} active trade services published'**
  String activeTradeServicesPublished(String count);

  /// No description provided for @activeArtisanFleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Artisan Fleet'**
  String get activeArtisanFleetTitle;

  /// No description provided for @artisansCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Artisans'**
  String artisansCount(String count);

  /// No description provided for @vettedTechniciansAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} vetted technicians available'**
  String vettedTechniciansAvailable(String count);

  /// No description provided for @publishedTradeCategories.
  ///
  /// In en, this message translates to:
  /// **'Published Trade Categories'**
  String get publishedTradeCategories;

  /// No description provided for @registeredOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'{registered} Registered • {online} Online Now'**
  String registeredOnlineCount(String registered, String online);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @dynamicBiddingBadge.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Bidding'**
  String get dynamicBiddingBadge;

  /// No description provided for @islandWideBadge.
  ///
  /// In en, this message translates to:
  /// **'Island-wide'**
  String get islandWideBadge;

  /// No description provided for @districtsAndFleetCoverage.
  ///
  /// In en, this message translates to:
  /// **'Districts & Fleet Coverage'**
  String get districtsAndFleetCoverage;

  /// No description provided for @searchFleetHint.
  ///
  /// In en, this message translates to:
  /// **'Search fleet by name, trade, district, phone...'**
  String get searchFleetHint;

  /// No description provided for @addServiceCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Service Category'**
  String get addServiceCategory;

  /// No description provided for @categoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category Title'**
  String get categoryTitle;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Service Description'**
  String get serviceDescription;

  /// No description provided for @selectTradeIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Trade Icon'**
  String get selectTradeIcon;

  /// No description provided for @savePublishCategory.
  ///
  /// In en, this message translates to:
  /// **'Save & Publish Category'**
  String get savePublishCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get deleteCategoryConfirm;

  /// No description provided for @suspendArtisan.
  ///
  /// In en, this message translates to:
  /// **'Suspend Artisan'**
  String get suspendArtisan;

  /// No description provided for @readOnlyOpsGovernance.
  ///
  /// In en, this message translates to:
  /// **'Read-Only Mode: Ops Governance permission required to manage categories or fleet.'**
  String get readOnlyOpsGovernance;

  /// No description provided for @noCategoriesInDb.
  ///
  /// In en, this message translates to:
  /// **'No Categories in Database'**
  String get noCategoriesInDb;

  /// No description provided for @addFirstCategory.
  ///
  /// In en, this message translates to:
  /// **'Add First Category'**
  String get addFirstCategory;

  /// No description provided for @adminTeamGovernanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Team & Access Governance'**
  String get adminTeamGovernanceTitle;

  /// No description provided for @addNewAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Add New Admin'**
  String get addNewAdminAction;

  /// No description provided for @totalAdminsCount.
  ///
  /// In en, this message translates to:
  /// **'Total Admins'**
  String get totalAdminsCount;

  /// No description provided for @registeredPlatformAccounts.
  ///
  /// In en, this message translates to:
  /// **'Registered platform accounts'**
  String get registeredPlatformAccounts;

  /// No description provided for @superAdminsCount.
  ///
  /// In en, this message translates to:
  /// **'Super Admins'**
  String get superAdminsCount;

  /// No description provided for @rootGovernanceLeads.
  ///
  /// In en, this message translates to:
  /// **'Root governance leads'**
  String get rootGovernanceLeads;

  /// No description provided for @activeOperatorsCount.
  ///
  /// In en, this message translates to:
  /// **'Active Operators'**
  String get activeOperatorsCount;

  /// No description provided for @dispatchKycDuty.
  ///
  /// In en, this message translates to:
  /// **'Dispatch & KYC duty'**
  String get dispatchKycDuty;

  /// No description provided for @pendingInvitesCount.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get pendingInvitesCount;

  /// No description provided for @awaitingFirstSignIn.
  ///
  /// In en, this message translates to:
  /// **'Awaiting first sign-in'**
  String get awaitingFirstSignIn;

  /// No description provided for @searchAdminPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by admin name or email...'**
  String get searchAdminPlaceholder;

  /// No description provided for @roleFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get roleFilterLabel;

  /// No description provided for @allRolesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRolesFilter;

  /// No description provided for @roleSuperAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdminBadge;

  /// No description provided for @roleOpsAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'Operations Admin'**
  String get roleOpsAdminBadge;

  /// No description provided for @roleSupportAdminBadge.
  ///
  /// In en, this message translates to:
  /// **'Support Admin'**
  String get roleSupportAdminBadge;

  /// No description provided for @youBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youBadge;

  /// No description provided for @fullRootGovernanceBadge.
  ///
  /// In en, this message translates to:
  /// **'• Full Root Governance (All Modules Granted)'**
  String get fullRootGovernanceBadge;

  /// No description provided for @revokeAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke Administrator Access?'**
  String get revokeAdminAccess;

  /// No description provided for @revokeAccessConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revoke back-office administrative access for {name} ({email})? This action cannot be undone.'**
  String revokeAccessConfirm(String name, String email);

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke Access'**
  String get revokeAccess;

  /// No description provided for @adminAccessRevoked.
  ///
  /// In en, this message translates to:
  /// **'Administrative access revoked for {name}.'**
  String adminAccessRevoked(String name);

  /// No description provided for @searchTechniciansNicJobs.
  ///
  /// In en, this message translates to:
  /// **'Search technicians, NIC, jobs...'**
  String get searchTechniciansNicJobs;

  /// No description provided for @islandNetworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Island Network: 99.8% Online • Colombo / Kandy / Galle active'**
  String get islandNetworkStatus;

  /// No description provided for @operationsAlertsBroadcasts.
  ///
  /// In en, this message translates to:
  /// **'Operations Alerts & Broadcasts'**
  String get operationsAlertsBroadcasts;

  /// No description provided for @noActiveSystemAlerts.
  ///
  /// In en, this message translates to:
  /// **'No active system alerts or broadcasts logged.'**
  String get noActiveSystemAlerts;

  /// No description provided for @disputeComplaintCenter.
  ///
  /// In en, this message translates to:
  /// **'Dispute & Complaint Center'**
  String get disputeComplaintCenter;

  /// No description provided for @reviewUserReports.
  ///
  /// In en, this message translates to:
  /// **'Review user reports, audit quality disputes, and enforce moderation'**
  String get reviewUserReports;

  /// No description provided for @totalReports.
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get totalReports;

  /// No description provided for @pendingAction.
  ///
  /// In en, this message translates to:
  /// **'Pending Action'**
  String get pendingAction;

  /// No description provided for @resolvedCases.
  ///
  /// In en, this message translates to:
  /// **'Resolved Cases'**
  String get resolvedCases;

  /// No description provided for @searchDisputesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search disputes by customer, provider, reason...'**
  String get searchDisputesPlaceholder;

  /// No description provided for @resolveComplaint.
  ///
  /// In en, this message translates to:
  /// **'Resolve Complaint'**
  String get resolveComplaint;

  /// No description provided for @dismissComplaint.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Complaint'**
  String get dismissComplaint;

  /// No description provided for @suspendServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Suspend Service Provider'**
  String get suspendServiceProvider;

  /// No description provided for @reasonForBan.
  ///
  /// In en, this message translates to:
  /// **'Reason for Ban (Visible to Provider):'**
  String get reasonForBan;

  /// No description provided for @filterAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllFilter;

  /// No description provided for @expandMap.
  ///
  /// In en, this message translates to:
  /// **'Expand map'**
  String get expandMap;

  /// No description provided for @closeMap.
  ///
  /// In en, this message translates to:
  /// **'Close map'**
  String get closeMap;

  /// No description provided for @adminAccessSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your admin access is suspended.'**
  String get adminAccessSuspended;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}. Please check your inbox.'**
  String passwordResetSent(String email);

  /// No description provided for @atLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Characters;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterPassword;

  /// No description provided for @gpsLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not obtain GPS location. Please ensure location is enabled.'**
  String get gpsLocationError;

  /// No description provided for @searchChatsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search chats by name or message...'**
  String get searchChatsPlaceholder;

  /// No description provided for @signInToViewMessages.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your messages'**
  String get signInToViewMessages;

  /// No description provided for @failedToLoadConversations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load conversations'**
  String get failedToLoadConversations;

  /// No description provided for @noMatchingConversations.
  ///
  /// In en, this message translates to:
  /// **'No matching conversations'**
  String get noMatchingConversations;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @conversationsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct messages with service providers or customers will appear here.'**
  String get conversationsEmptyDesc;

  /// No description provided for @trySearchingAnotherKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try searching with another name or keyword.'**
  String get trySearchingAnotherKeyword;

  /// No description provided for @tapToStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Tap to start conversation'**
  String get tapToStartConversation;

  /// No description provided for @unauthorizedAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized: Admin access required.'**
  String get unauthorizedAdminAccess;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully!'**
  String get profilePictureUpdated;

  /// No description provided for @profilePictureRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile picture removed.'**
  String get profilePictureRemoved;

  /// No description provided for @failedToRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove photo'**
  String get failedToRemovePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @chooseDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your primary display language'**
  String get chooseDisplayLanguage;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @arrivalConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Arrival Confirmed'**
  String get arrivalConfirmed;

  /// No description provided for @languageSwitchedTo.
  ///
  /// In en, this message translates to:
  /// **'Language switched to'**
  String get languageSwitchedTo;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. No. 12, Lake Road'**
  String get addressHint;

  /// No description provided for @needQuickService.
  ///
  /// In en, this message translates to:
  /// **'Need Quick Service?'**
  String get needQuickService;

  /// No description provided for @postJobBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Post your job in 60s & receive instant competitive bids from verified nearby artisans.'**
  String get postJobBannerDesc;

  /// No description provided for @postJobAndGetQuotes.
  ///
  /// In en, this message translates to:
  /// **'Post Job & Get Quotes'**
  String get postJobAndGetQuotes;

  /// No description provided for @noArtisansMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No artisans match your filters'**
  String get noArtisansMatchFilters;

  /// No description provided for @tryClearingSearchOrFilters.
  ///
  /// In en, this message translates to:
  /// **'Try clearing your search query or adjusting your filters'**
  String get tryClearingSearchOrFilters;

  /// No description provided for @resetAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset All Filters'**
  String get resetAllFilters;

  /// No description provided for @filterArtisans.
  ///
  /// In en, this message translates to:
  /// **'Filter Artisans'**
  String get filterArtisans;

  /// No description provided for @onlineReadyToBid.
  ///
  /// In en, this message translates to:
  /// **'Online & Ready to Bid'**
  String get onlineReadyToBid;

  /// No description provided for @onlineReadyToBidSub.
  ///
  /// In en, this message translates to:
  /// **'Show active artisans ready for instant booking'**
  String get onlineReadyToBidSub;

  /// No description provided for @emergencyDispatch.
  ///
  /// In en, this message translates to:
  /// **'Emergency Dispatch'**
  String get emergencyDispatch;

  /// No description provided for @customerRating.
  ///
  /// In en, this message translates to:
  /// **'Customer Rating'**
  String get customerRating;

  /// No description provided for @allRatings.
  ///
  /// In en, this message translates to:
  /// **'All Ratings'**
  String get allRatings;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @topArtisans.
  ///
  /// In en, this message translates to:
  /// **'Top Artisans'**
  String get topArtisans;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @quickReplyWhereAreYou.
  ///
  /// In en, this message translates to:
  /// **'Where are you now?'**
  String get quickReplyWhereAreYou;

  /// No description provided for @quickReplyWaitingMainGate.
  ///
  /// In en, this message translates to:
  /// **'I am waiting at the main gate.'**
  String get quickReplyWaitingMainGate;

  /// No description provided for @quickReplyCallWhenArrive.
  ///
  /// In en, this message translates to:
  /// **'Please call me when you arrive.'**
  String get quickReplyCallWhenArrive;

  /// No description provided for @quickReplyParkingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Parking is available on premise.'**
  String get quickReplyParkingAvailable;

  /// No description provided for @quickReplyOnMyWay.
  ///
  /// In en, this message translates to:
  /// **'On my way, will be there soon.'**
  String get quickReplyOnMyWay;

  /// No description provided for @couldNotConnectChat.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to chat'**
  String get couldNotConnectChat;

  /// No description provided for @couldNotLoadChat.
  ///
  /// In en, this message translates to:
  /// **'Could not load chat'**
  String get couldNotLoadChat;

  /// No description provided for @sendMsgToStartChat.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start chatting'**
  String get sendMsgToStartChat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeMessage;

  /// No description provided for @bookingConfirmedChatStarted.
  ///
  /// In en, this message translates to:
  /// **'Your service booking is confirmed. A direct conversation has been started with {providerName} to coordinate timing and location.'**
  String bookingConfirmedChatStarted(String providerName);

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// No description provided for @failedToAcceptQuote.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept quote'**
  String get failedToAcceptQuote;

  /// No description provided for @etaDelayNotice.
  ///
  /// In en, this message translates to:
  /// **'ETA Adjusted: +{minutes} Mins Delay'**
  String etaDelayNotice(int minutes);

  /// No description provided for @artisanReportedDelay.
  ///
  /// In en, this message translates to:
  /// **'Artisan reported: {reason}'**
  String artisanReportedDelay(String reason);

  /// No description provided for @providerPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Provider phone not available'**
  String get providerPhoneNotAvailable;

  /// No description provided for @cancelBookingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking request?'**
  String get cancelBookingConfirm;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @serviceRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Service request cancelled.'**
  String get serviceRequestCancelled;

  /// No description provided for @liveTrackingCopied.
  ///
  /// In en, this message translates to:
  /// **'Live tracking link copied to clipboard!'**
  String get liveTrackingCopied;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @liveGpsOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Live GPS • On the way'**
  String get liveGpsOnTheWay;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services on your device'**
  String get enableLocationServices;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Enable in settings.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @failedToDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect location'**
  String get failedToDetectLocation;

  /// No description provided for @failedToSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get failedToSubmitRequest;

  /// No description provided for @reportProvider.
  ///
  /// In en, this message translates to:
  /// **'Report Provider'**
  String get reportProvider;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @noCustomerReviews.
  ///
  /// In en, this message translates to:
  /// **'No customer reviews recorded yet'**
  String get noCustomerReviews;

  /// No description provided for @complaintUnprofessionalConduct.
  ///
  /// In en, this message translates to:
  /// **'Unprofessional Conduct'**
  String get complaintUnprofessionalConduct;

  /// No description provided for @complaintLateNoShow.
  ///
  /// In en, this message translates to:
  /// **'Late or No-Show'**
  String get complaintLateNoShow;

  /// No description provided for @complaintPoorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor Quality of Work'**
  String get complaintPoorQuality;

  /// No description provided for @complaintSafetyConcern.
  ///
  /// In en, this message translates to:
  /// **'Safety or Harassment Concern'**
  String get complaintSafetyConcern;

  /// No description provided for @complaintFraudIssue.
  ///
  /// In en, this message translates to:
  /// **'Fraud or Identity Issue'**
  String get complaintFraudIssue;

  /// No description provided for @complaintOtherIssue.
  ///
  /// In en, this message translates to:
  /// **'Other Issue'**
  String get complaintOtherIssue;

  /// No description provided for @reportServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Report Service Provider'**
  String get reportServiceProvider;

  /// No description provided for @reportingTechnician.
  ///
  /// In en, this message translates to:
  /// **'Reporting {name} ({title})'**
  String reportingTechnician(String name, String title);

  /// No description provided for @selectComplaintReason.
  ///
  /// In en, this message translates to:
  /// **'Select Complaint Reason'**
  String get selectComplaintReason;

  /// No description provided for @explainIncidentDetails.
  ///
  /// In en, this message translates to:
  /// **'Explain Incident Details'**
  String get explainIncidentDetails;

  /// No description provided for @explainIncidentHint.
  ///
  /// In en, this message translates to:
  /// **'Please detail what happened, including any agreed fees or work that was not completed...'**
  String get explainIncidentHint;

  /// No description provided for @describeIssueBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue before submitting.'**
  String get describeIssueBeforeSubmitting;

  /// No description provided for @signInToSubmitComplaint.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to submit a complaint.'**
  String get signInToSubmitComplaint;

  /// No description provided for @complaintSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Complaint submitted to Admin Support for review.'**
  String get complaintSubmittedSuccess;

  /// No description provided for @submitOfficialReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Official Report'**
  String get submitOfficialReport;

  /// No description provided for @jobIdNumber.
  ///
  /// In en, this message translates to:
  /// **'Job #{id}'**
  String jobIdNumber(String id);

  /// No description provided for @settledDirectly.
  ///
  /// In en, this message translates to:
  /// **'Settled directly'**
  String get settledDirectly;

  /// No description provided for @tip200.
  ///
  /// In en, this message translates to:
  /// **'+LKR 200'**
  String get tip200;

  /// No description provided for @tip500.
  ///
  /// In en, this message translates to:
  /// **'+LKR 500'**
  String get tip500;

  /// No description provided for @serviceDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Service Diagnostic'**
  String get serviceDiagnostic;

  /// No description provided for @technician.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get technician;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @byTechnician.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String byTechnician(String name);

  /// No description provided for @accountAndServices.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT & SERVICES'**
  String get accountAndServices;

  /// No description provided for @homeServiceGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Home / Service GPS Location'**
  String get homeServiceGpsLocation;

  /// No description provided for @tapToAutoDetectGps.
  ///
  /// In en, this message translates to:
  /// **'Tap to auto-detect current GPS coordinates'**
  String get tapToAutoDetectGps;

  /// No description provided for @gpsLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'GPS Location updated: {lat}, {lng}'**
  String gpsLocationUpdated(String lat, String lng);

  /// No description provided for @couldNotObtainGps.
  ///
  /// In en, this message translates to:
  /// **'Could not obtain GPS location. Please check location permissions.'**
  String get couldNotObtainGps;

  /// No description provided for @currentMode.
  ///
  /// In en, this message translates to:
  /// **'Current: {mode} (Tap to change)'**
  String currentMode(String mode);

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get failedToPickImage;

  /// No description provided for @complaintPriceDispute.
  ///
  /// In en, this message translates to:
  /// **'Overcharging / Price Dispute'**
  String get complaintPriceDispute;

  /// No description provided for @failedToSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report'**
  String get failedToSubmitReport;

  /// No description provided for @expressDispatchCaps.
  ///
  /// In en, this message translates to:
  /// **'EXPRESS DISPATCH'**
  String get expressDispatchCaps;

  /// No description provided for @autoPassesInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Auto-passes in {seconds} s'**
  String autoPassesInSeconds(int seconds);

  /// No description provided for @urgentCaps.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgentCaps;

  /// No description provided for @secondsUnit.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondsUnit;

  /// No description provided for @guaranteedBasePayoutCaps.
  ///
  /// In en, this message translates to:
  /// **'GUARANTEED BASE PAYOUT'**
  String get guaranteedBasePayoutCaps;

  /// No description provided for @cashAtServiceSite.
  ///
  /// In en, this message translates to:
  /// **'Cash at service site'**
  String get cashAtServiceSite;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @acceptJob.
  ///
  /// In en, this message translates to:
  /// **'Accept Job'**
  String get acceptJob;

  /// No description provided for @passToNextArtisan.
  ///
  /// In en, this message translates to:
  /// **'Pass to next artisan'**
  String get passToNextArtisan;

  /// No description provided for @pullOverSafelyWarning.
  ///
  /// In en, this message translates to:
  /// **'Pull over safely before accepting.'**
  String get pullOverSafelyWarning;

  /// No description provided for @serviceRequest.
  ///
  /// In en, this message translates to:
  /// **'Service Request'**
  String get serviceRequest;

  /// No description provided for @clientAddress.
  ///
  /// In en, this message translates to:
  /// **'Client Address'**
  String get clientAddress;

  /// No description provided for @durationMins.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMins(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr'**
  String durationHours(int hours);

  /// No description provided for @durationOneAndHalfHours.
  ///
  /// In en, this message translates to:
  /// **'1.5 hr'**
  String get durationOneAndHalfHours;

  /// No description provided for @failedToSubmitQuote.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit quote: {error}'**
  String failedToSubmitQuote(String error);

  /// No description provided for @delayReportedNotice.
  ///
  /// In en, this message translates to:
  /// **'Reported delay: {reason} (+10 min ETA adjustment broadcasted)'**
  String delayReportedNotice(String reason);

  /// No description provided for @customerLocation.
  ///
  /// In en, this message translates to:
  /// **'Customer Location'**
  String get customerLocation;

  /// No description provided for @customerLocationNamed.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Location'**
  String customerLocationNamed(String name);

  /// No description provided for @youEnRoute.
  ///
  /// In en, this message translates to:
  /// **'You (En Route)'**
  String get youEnRoute;

  /// No description provided for @inDistance.
  ///
  /// In en, this message translates to:
  /// **'In {distance}'**
  String inDistance(String distance);

  /// No description provided for @navigatingTo.
  ///
  /// In en, this message translates to:
  /// **'Navigating to {target}'**
  String navigatingTo(String target);

  /// No description provided for @failedToUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo: {error}'**
  String failedToUploadPhoto(String error);

  /// No description provided for @failedToSubmitVerification.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit verification: {error}'**
  String failedToSubmitVerification(String error);

  /// No description provided for @step2Of3.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 3'**
  String get step2Of3;

  /// No description provided for @navJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// No description provided for @verificationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Verification Under Review'**
  String get verificationUnderReview;

  /// No description provided for @statusPendingReviewCaps.
  ///
  /// In en, this message translates to:
  /// **'STATUS: PENDING REVIEW'**
  String get statusPendingReviewCaps;

  /// No description provided for @nicUnderReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Your National ID (NIC) documents and biometric selfie have been securely stored in our encrypted credential vault. Our admin verification desk is validating your record with e-DLS & Sri Lanka Police databases.'**
  String get nicUnderReviewDesc;

  /// No description provided for @returnToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get returnToDashboard;

  /// No description provided for @verifyIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to start receiving jobs island-wide across Sri Lanka.'**
  String get verifyIdentitySubtitle;

  /// No description provided for @nicFrontSide.
  ///
  /// In en, this message translates to:
  /// **'NIC Front Side'**
  String get nicFrontSide;

  /// No description provided for @nicFrontSideDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear photo of the front side showing your portrait and NIC number.'**
  String get nicFrontSideDesc;

  /// No description provided for @captureOrUploadFront.
  ///
  /// In en, this message translates to:
  /// **'Capture or Upload Front'**
  String get captureOrUploadFront;

  /// No description provided for @nicFrontTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: Lay flat on a contrasting surface, avoid phone shadow.'**
  String get nicFrontTip;

  /// No description provided for @nicBackSide.
  ///
  /// In en, this message translates to:
  /// **'NIC Back Side'**
  String get nicBackSide;

  /// No description provided for @nicBackSideDesc.
  ///
  /// In en, this message translates to:
  /// **'Back side showing your registered residential address and clear barcode.'**
  String get nicBackSideDesc;

  /// No description provided for @captureOrUploadBack.
  ///
  /// In en, this message translates to:
  /// **'Capture or Upload Back'**
  String get captureOrUploadBack;

  /// No description provided for @nicBackTip.
  ///
  /// In en, this message translates to:
  /// **'Ensure all 4 card corners are in frame'**
  String get nicBackTip;

  /// No description provided for @selfieHoldingNic.
  ///
  /// In en, this message translates to:
  /// **'Selfie Holding Your NIC'**
  String get selfieHoldingNic;

  /// No description provided for @selfieHoldingNicDesc.
  ///
  /// In en, this message translates to:
  /// **'Hold your National ID card next to your face, both equally in focus.'**
  String get selfieHoldingNicDesc;

  /// No description provided for @openCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get openCamera;

  /// No description provided for @livePortraitTest.
  ///
  /// In en, this message translates to:
  /// **'Live portrait test'**
  String get livePortraitTest;

  /// No description provided for @selfieTip.
  ///
  /// In en, this message translates to:
  /// **'Do not wear sunglasses, caps, or masks. Do not cover your name or photo.'**
  String get selfieTip;

  /// No description provided for @fastTurnaroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast turnaround:'**
  String get fastTurnaroundTitle;

  /// No description provided for @fastTurnaroundBody.
  ///
  /// In en, this message translates to:
  /// **'Approvals take less than 2 hours (Mon-Sat, 8 AM - 6 PM).'**
  String get fastTurnaroundBody;

  /// No description provided for @smsAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'SMS alert:'**
  String get smsAlertTitle;

  /// No description provided for @smsAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Instant approval message to your registered mobile number.'**
  String get smsAlertBody;

  /// No description provided for @qualityStandardTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality standard:'**
  String get qualityStandardTitle;

  /// No description provided for @qualityStandardBody.
  ///
  /// In en, this message translates to:
  /// **'Natural daylight photos get accepted first try.'**
  String get qualityStandardBody;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// No description provided for @attachedStatus.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get attachedStatus;

  /// No description provided for @requiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredStatus;

  /// No description provided for @photoAttachedTapReplace.
  ///
  /// In en, this message translates to:
  /// **'Photo attached · tap to replace'**
  String get photoAttachedTapReplace;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @nReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String nReviews(int count);

  /// No description provided for @nJobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs'**
  String nJobsCompleted(int count);

  /// No description provided for @fleetActive.
  ///
  /// In en, this message translates to:
  /// **'Fleet Active'**
  String get fleetActive;

  /// No description provided for @categorySpecialist.
  ///
  /// In en, this message translates to:
  /// **'{category} Specialist'**
  String categorySpecialist(String category);

  /// No description provided for @instantMatchActive.
  ///
  /// In en, this message translates to:
  /// **'Instant Match active'**
  String get instantMatchActive;

  /// No description provided for @offlineSwitchOnDesc.
  ///
  /// In en, this message translates to:
  /// **'Offline · Switch on to receive jobs'**
  String get offlineSwitchOnDesc;

  /// No description provided for @nNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String nNew(int count);

  /// No description provided for @acceptDirectBooking.
  ///
  /// In en, this message translates to:
  /// **'Accept Direct Booking'**
  String get acceptDirectBooking;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get etaLabel;

  /// No description provided for @minsUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minsUnit;

  /// No description provided for @certifiedArtisan.
  ///
  /// In en, this message translates to:
  /// **'Certified Artisan'**
  String get certifiedArtisan;

  /// No description provided for @addAdminGrantOnePermission.
  ///
  /// In en, this message translates to:
  /// **'Please grant at least one permission flag for this admin.'**
  String get addAdminGrantOnePermission;

  /// No description provided for @addAdminFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add admin: {error}'**
  String addAdminFailed(String error);

  /// No description provided for @addAdminAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Admin Account Created'**
  String get addAdminAccountCreated;

  /// No description provided for @addAdminSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The user has been successfully granted {role} privileges. The next time they sign in with this email, the administrative console will be accessible.'**
  String addAdminSuccessBody(String role);

  /// No description provided for @addAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Platform Administrator'**
  String get addAdminTitle;

  /// No description provided for @addAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign role and permissions; invite links will be generated'**
  String get addAdminSubtitle;

  /// No description provided for @addAdminEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the administrator full name'**
  String get addAdminEnterFullName;

  /// No description provided for @addAdminWorkEmail.
  ///
  /// In en, this message translates to:
  /// **'Official Work Email'**
  String get addAdminWorkEmail;

  /// No description provided for @addAdminEnterWorkEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid work email'**
  String get addAdminEnterWorkEmail;

  /// No description provided for @addAdminMobileOptional.
  ///
  /// In en, this message translates to:
  /// **'Mobile Phone (Optional)'**
  String get addAdminMobileOptional;

  /// No description provided for @addAdminTier.
  ///
  /// In en, this message translates to:
  /// **'Administrative Tier'**
  String get addAdminTier;

  /// No description provided for @addAdminOperationalPermissions.
  ///
  /// In en, this message translates to:
  /// **'Operational Permissions'**
  String get addAdminOperationalPermissions;

  /// No description provided for @addAdminAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get addAdminAdding;

  /// No description provided for @addAdminGrantRole.
  ///
  /// In en, this message translates to:
  /// **'Grant Admin Role'**
  String get addAdminGrantRole;

  /// No description provided for @editPermSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one permission flag.'**
  String get editPermSelectOne;

  /// No description provided for @editPermUpdatedFor.
  ///
  /// In en, this message translates to:
  /// **'Permissions updated for {name}.'**
  String editPermUpdatedFor(String name);

  /// No description provided for @editPermFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update permissions: {error}'**
  String editPermFailed(String error);

  /// No description provided for @editPermChangeTier.
  ///
  /// In en, this message translates to:
  /// **'Change Administrative Tier'**
  String get editPermChangeTier;

  /// No description provided for @editPermAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned Operational Permissions'**
  String get editPermAssigned;

  /// No description provided for @editPermUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get editPermUpdating;

  /// No description provided for @editPermSave.
  ///
  /// In en, this message translates to:
  /// **'Save Permissions'**
  String get editPermSave;

  /// No description provided for @sidebarOnlySuperAdmins.
  ///
  /// In en, this message translates to:
  /// **'Only Super Admins can access Administrator Management.'**
  String get sidebarOnlySuperAdmins;

  /// No description provided for @sidebarNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this section.'**
  String get sidebarNoPermission;

  /// No description provided for @sidebarColomboCentralHub.
  ///
  /// In en, this message translates to:
  /// **'Colombo Central Hub'**
  String get sidebarColomboCentralHub;

  /// No description provided for @topBarSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get topBarSearch;

  /// No description provided for @topBarSupportMessages.
  ///
  /// In en, this message translates to:
  /// **'Support & Mediation Messages'**
  String get topBarSupportMessages;

  /// No description provided for @topBarAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get topBarAdministrator;

  /// No description provided for @cdmPublishedCategoriesInfo.
  ///
  /// In en, this message translates to:
  /// **'Published categories are available island-wide. Pricing is dynamic — nearby verified technicians quote custom bids based on distance and job details.'**
  String get cdmPublishedCategoriesInfo;

  /// No description provided for @cdmCategoryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Solar PV Maintenance'**
  String get cdmCategoryTitleHint;

  /// No description provided for @cdmServiceDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of the trade services offered...'**
  String get cdmServiceDescriptionHint;

  /// No description provided for @cdmEnterCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category title'**
  String get cdmEnterCategoryTitle;

  /// No description provided for @cdmCategorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category \"{title}\" saved and published successfully'**
  String cdmCategorySaved(String title);

  /// No description provided for @cdmDeleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This will disable dispatch for this category island-wide.'**
  String cdmDeleteCategoryConfirm(String name);

  /// No description provided for @cdmCategoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" deleted'**
  String cdmCategoryDeleted(String name);

  /// No description provided for @cdmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get cdmDelete;

  /// No description provided for @cdmReadOnlyModeOpsGovernance.
  ///
  /// In en, this message translates to:
  /// **'Read-Only Mode (Ops Governance)'**
  String get cdmReadOnlyModeOpsGovernance;

  /// No description provided for @cdmFleetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Audit verified service technicians, moderate access, and enforce suspensions'**
  String get cdmFleetSubtitle;

  /// No description provided for @cdmNoCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your service trades to publish them to Firebase so customers can discover and book technicians.'**
  String get cdmNoCategoriesDesc;

  /// No description provided for @cdmDynamicQuotes.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Quotes'**
  String get cdmDynamicQuotes;

  /// No description provided for @cdmArtisansBidPerJob.
  ///
  /// In en, this message translates to:
  /// **'Artisans Bid Per Job'**
  String get cdmArtisansBidPerJob;

  /// No description provided for @cdmPauseCategory.
  ///
  /// In en, this message translates to:
  /// **'Pause Category'**
  String get cdmPauseCategory;

  /// No description provided for @cdmActivateCategory.
  ///
  /// In en, this message translates to:
  /// **'Activate Category'**
  String get cdmActivateCategory;

  /// No description provided for @cdmFilterAllCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String cdmFilterAllCount(String count);

  /// No description provided for @cdmFilterOnlineCount.
  ///
  /// In en, this message translates to:
  /// **'Online ({count})'**
  String cdmFilterOnlineCount(String count);

  /// No description provided for @cdmFilterSuspendedCount.
  ///
  /// In en, this message translates to:
  /// **'Suspended ({count})'**
  String cdmFilterSuspendedCount(String count);

  /// No description provided for @cdmFilterOfflineCount.
  ///
  /// In en, this message translates to:
  /// **'Offline ({count})'**
  String cdmFilterOfflineCount(String count);

  /// No description provided for @cdmNoArtisansMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No artisans match the search criteria'**
  String get cdmNoArtisansMatchSearch;

  /// No description provided for @cdmNoArtisansInFilter.
  ///
  /// In en, this message translates to:
  /// **'No artisans registered in this filter view'**
  String get cdmNoArtisansInFilter;

  /// No description provided for @cdmBadgeSuspended.
  ///
  /// In en, this message translates to:
  /// **'SUSPENDED'**
  String get cdmBadgeSuspended;

  /// No description provided for @cdmBadgeOnline.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get cdmBadgeOnline;

  /// No description provided for @cdmBadgeOffline.
  ///
  /// In en, this message translates to:
  /// **'OFFLINE'**
  String get cdmBadgeOffline;

  /// No description provided for @cdmSriLanka.
  ///
  /// In en, this message translates to:
  /// **'Sri Lanka'**
  String get cdmSriLanka;

  /// No description provided for @cdmBaseRate.
  ///
  /// In en, this message translates to:
  /// **'Base: LKR {amount}'**
  String cdmBaseRate(String amount);

  /// No description provided for @cdmSuspensionReason.
  ///
  /// In en, this message translates to:
  /// **'Suspension Reason: \"{reason}\"'**
  String cdmSuspensionReason(String reason);

  /// No description provided for @cdmComplaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get cdmComplaints;

  /// No description provided for @cdmSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get cdmSuspend;

  /// No description provided for @cdmRestoreUnban.
  ///
  /// In en, this message translates to:
  /// **'Restore / Unban'**
  String get cdmRestoreUnban;

  /// No description provided for @cdmDeleteArtisanPermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Artisan Permanently'**
  String get cdmDeleteArtisanPermanently;

  /// No description provided for @cdmSuspendName.
  ///
  /// In en, this message translates to:
  /// **'Suspend {name}'**
  String cdmSuspendName(String name);

  /// No description provided for @cdmSuspendConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend this artisan? They will be locked offline, hidden from customer searches, and prevented from submitting quotes.'**
  String get cdmSuspendConfirmBody;

  /// No description provided for @cdmReasonForSuspension.
  ///
  /// In en, this message translates to:
  /// **'Reason for Suspension:'**
  String get cdmReasonForSuspension;

  /// No description provided for @cdmArtisanSuspended.
  ///
  /// In en, this message translates to:
  /// **'{name} has been suspended.'**
  String cdmArtisanSuspended(String name);

  /// No description provided for @cdmConfirmSuspension.
  ///
  /// In en, this message translates to:
  /// **'Confirm Suspension'**
  String get cdmConfirmSuspension;

  /// No description provided for @cdmRestoreName.
  ///
  /// In en, this message translates to:
  /// **'Restore {name}'**
  String cdmRestoreName(String name);

  /// No description provided for @cdmRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Reactivate this artisan\'s profile? They will be allowed to go online and accept customer service requests.'**
  String get cdmRestoreConfirmBody;

  /// No description provided for @cdmArtisanRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} has been restored to active status.'**
  String cdmArtisanRestored(String name);

  /// No description provided for @cdmRestoreAccess.
  ///
  /// In en, this message translates to:
  /// **'Restore Access'**
  String get cdmRestoreAccess;

  /// No description provided for @cdmDeleteArtisan.
  ///
  /// In en, this message translates to:
  /// **'Delete Artisan'**
  String get cdmDeleteArtisan;

  /// No description provided for @cdmDeleteArtisanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{name}\" from the technician database? This operation cannot be reversed.'**
  String cdmDeleteArtisanConfirm(String name);

  /// No description provided for @cdmArtisanDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted from database.'**
  String cdmArtisanDeleted(String name);

  /// No description provided for @cdmDeletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get cdmDeletePermanently;

  /// No description provided for @cdmComplaintsFor.
  ///
  /// In en, this message translates to:
  /// **'Complaints for {name}'**
  String cdmComplaintsFor(String name);

  /// No description provided for @cdmNoComplaintsFiled.
  ///
  /// In en, this message translates to:
  /// **'No complaints filed'**
  String get cdmNoComplaintsFiled;

  /// No description provided for @cdmNoComplaintsDesc.
  ///
  /// In en, this message translates to:
  /// **'This service provider has no recorded customer disputes.'**
  String get cdmNoComplaintsDesc;

  /// No description provided for @cdmByCustomer.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String cdmByCustomer(String name);

  /// No description provided for @ledgerStatusEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get ledgerStatusEnRoute;

  /// No description provided for @ledgerJobsResolvedIsland.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs resolved across island'**
  String ledgerJobsResolvedIsland(String count);

  /// No description provided for @ledgerDispatchesActive.
  ///
  /// In en, this message translates to:
  /// **'{count} dispatches active in field'**
  String ledgerDispatchesActive(String count);

  /// No description provided for @ledgerBasedOnReviews.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} verified reviews'**
  String ledgerBasedOnReviews(String count);

  /// No description provided for @ledgerAwaitingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Awaiting customer feedback'**
  String get ledgerAwaitingFeedback;

  /// No description provided for @ledgerServiceBooking.
  ///
  /// In en, this message translates to:
  /// **'Service Booking'**
  String get ledgerServiceBooking;

  /// No description provided for @ledgerDelayMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m delay'**
  String ledgerDelayMinutes(String minutes);

  /// No description provided for @adminRoleDescSuper.
  ///
  /// In en, this message translates to:
  /// **'Root operational lead with team administration & full platform governance.'**
  String get adminRoleDescSuper;

  /// No description provided for @adminRoleDescOps.
  ///
  /// In en, this message translates to:
  /// **'Operational dispatch, artisan verifications, category & district hub management.'**
  String get adminRoleDescOps;

  /// No description provided for @adminRoleDescSupport.
  ///
  /// In en, this message translates to:
  /// **'Support queue handler with KYC review and provider inquiry access.'**
  String get adminRoleDescSupport;

  /// No description provided for @permManageAdminsLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Team Governance'**
  String get permManageAdminsLabel;

  /// No description provided for @permVerifyNicLabel.
  ///
  /// In en, this message translates to:
  /// **'Artisan NIC & KYC Verification'**
  String get permVerifyNicLabel;

  /// No description provided for @permManageCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories & District Hubs'**
  String get permManageCategoriesLabel;

  /// No description provided for @permBroadcastAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Island-wide Emergency Alerts'**
  String get permBroadcastAlertsLabel;

  /// No description provided for @permViewFinancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Service & Financial Logs'**
  String get permViewFinancesLabel;

  /// No description provided for @permManageAdminsDesc.
  ///
  /// In en, this message translates to:
  /// **'Invite, configure, demote, and deactivate administrators.'**
  String get permManageAdminsDesc;

  /// No description provided for @permVerifyNicDesc.
  ///
  /// In en, this message translates to:
  /// **'Review smart NICs, police reports, and approve/reject artisan registrations.'**
  String get permVerifyNicDesc;

  /// No description provided for @permManageCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure trade categories, base rates, and provincial hub thresholds.'**
  String get permManageCategoriesDesc;

  /// No description provided for @permBroadcastAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Send push alerts and critical warnings to active island artisans.'**
  String get permBroadcastAlertsDesc;

  /// No description provided for @permViewFinancesDesc.
  ///
  /// In en, this message translates to:
  /// **'Inspect service metrics, provider earnings, and completed job records.'**
  String get permViewFinancesDesc;

  /// No description provided for @adminStatusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get adminStatusInvited;

  /// No description provided for @adminStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get adminStatusSuspended;

  /// No description provided for @custArtisanLabel.
  ///
  /// In en, this message translates to:
  /// **'Artisan'**
  String get custArtisanLabel;

  /// No description provided for @custDefaultSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default system language'**
  String get custDefaultSystemLanguage;

  /// No description provided for @custMetresAway.
  ///
  /// In en, this message translates to:
  /// **'{metres} m away'**
  String custMetresAway(int metres);

  /// No description provided for @custKmAwayValue.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String custKmAwayValue(String km);

  /// No description provided for @custFallbackAreaColombo03.
  ///
  /// In en, this message translates to:
  /// **'Colombo 03'**
  String get custFallbackAreaColombo03;

  /// No description provided for @custFallbackWesternProvince.
  ///
  /// In en, this message translates to:
  /// **'Western Province'**
  String get custFallbackWesternProvince;

  /// No description provided for @custFallbackColombo.
  ///
  /// In en, this message translates to:
  /// **'Colombo'**
  String get custFallbackColombo;

  /// No description provided for @custShareTrackingText.
  ///
  /// In en, this message translates to:
  /// **'Track my HelaService artisan live here: {link}'**
  String custShareTrackingText(String link);

  /// No description provided for @custRatePerHour.
  ///
  /// In en, this message translates to:
  /// **'LKR {amount} / hr'**
  String custRatePerHour(String amount);

  /// No description provided for @custGpsTapToUpdate.
  ///
  /// In en, this message translates to:
  /// **'GPS: {lat}, {lng} (Tap to update)'**
  String custGpsTapToUpdate(String lat, String lng);

  /// No description provided for @custInspectionSuffix.
  ///
  /// In en, this message translates to:
  /// **'inspection'**
  String get custInspectionSuffix;

  /// No description provided for @custServiceProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get custServiceProviderLabel;

  /// No description provided for @liveMapColArtisan.
  ///
  /// In en, this message translates to:
  /// **'Artisan'**
  String get liveMapColArtisan;

  /// No description provided for @liveMapColAssignedZone.
  ///
  /// In en, this message translates to:
  /// **'Assigned Zone'**
  String get liveMapColAssignedZone;

  /// No description provided for @liveMapColPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get liveMapColPayout;

  /// No description provided for @liveMapColQuickDispatch.
  ///
  /// In en, this message translates to:
  /// **'Quick Dispatch'**
  String get liveMapColQuickDispatch;

  /// No description provided for @liveMapStatusAvailableIdle.
  ///
  /// In en, this message translates to:
  /// **'Available / Idle'**
  String get liveMapStatusAvailableIdle;

  /// No description provided for @liveMapStatusActiveVerified.
  ///
  /// In en, this message translates to:
  /// **'Active Verified'**
  String get liveMapStatusActiveVerified;

  /// No description provided for @liveMapNicVerified.
  ///
  /// In en, this message translates to:
  /// **'NIC: Verified'**
  String get liveMapNicVerified;

  /// No description provided for @liveMapNicPending.
  ///
  /// In en, this message translates to:
  /// **'NIC: Pending'**
  String get liveMapNicPending;

  /// No description provided for @liveMapZoneColomboMetro.
  ///
  /// In en, this message translates to:
  /// **'Colombo Metro'**
  String get liveMapZoneColomboMetro;

  /// No description provided for @liveMapPayoutToday.
  ///
  /// In en, this message translates to:
  /// **'{amount} (Today)'**
  String liveMapPayoutToday(String amount);

  /// No description provided for @liveMapTodayParen.
  ///
  /// In en, this message translates to:
  /// **'(Today)'**
  String get liveMapTodayParen;

  /// No description provided for @liveMapActionDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get liveMapActionDispatch;

  /// No description provided for @liveMapActionReassign.
  ///
  /// In en, this message translates to:
  /// **'Re-assign'**
  String get liveMapActionReassign;

  /// No description provided for @liveMapDispatchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'{action}: {name}'**
  String liveMapDispatchDialogTitle(String action, String name);

  /// No description provided for @liveMapQuotesReceived.
  ///
  /// In en, this message translates to:
  /// **'{count} quotes received'**
  String liveMapQuotesReceived(int count);

  /// No description provided for @liveMapLiveCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} Live'**
  String liveMapLiveCount(int count);

  /// No description provided for @liveMapActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String liveMapActiveCount(int count);

  /// No description provided for @liveMapActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Req'**
  String get liveMapActionRequired;

  /// No description provided for @liveMapShowAllDistricts.
  ///
  /// In en, this message translates to:
  /// **'Show all districts'**
  String get liveMapShowAllDistricts;

  /// No description provided for @liveMapUnmappedProviderOne.
  ///
  /// In en, this message translates to:
  /// **'{count} active provider in unmapped/unknown zones'**
  String liveMapUnmappedProviderOne(int count);

  /// No description provided for @liveMapUnmappedProviderMany.
  ///
  /// In en, this message translates to:
  /// **'{count} active providers in unmapped/unknown zones'**
  String liveMapUnmappedProviderMany(int count);

  /// No description provided for @disputesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get disputesNotAvailable;

  /// No description provided for @disputesResolveNotesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add resolution notes detailing the outcome of the investigation or customer compensation.'**
  String get disputesResolveNotesPrompt;

  /// No description provided for @disputesDismissNotesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add notes explaining why this dispute is dismissed.'**
  String get disputesDismissNotesPrompt;

  /// No description provided for @disputesResolutionSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter internal admin resolution summary...'**
  String get disputesResolutionSummaryHint;

  /// No description provided for @disputesMarkedResolvedSnack.
  ///
  /// In en, this message translates to:
  /// **'Complaint marked as Resolved.'**
  String get disputesMarkedResolvedSnack;

  /// No description provided for @disputesDismissedSnack.
  ///
  /// In en, this message translates to:
  /// **'Complaint dismissed.'**
  String get disputesDismissedSnack;

  /// No description provided for @disputesMarkResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark Resolved'**
  String get disputesMarkResolved;

  /// No description provided for @disputesConfirmDismiss.
  ///
  /// In en, this message translates to:
  /// **'Confirm Dismiss'**
  String get disputesConfirmDismiss;

  /// No description provided for @disputesBanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to ban {name} ({trade})? They will be locked offline and hidden from customer discovery.'**
  String disputesBanConfirm(String name, String trade);

  /// No description provided for @disputesSuspendProvider.
  ///
  /// In en, this message translates to:
  /// **'Suspend Provider'**
  String get disputesSuspendProvider;

  /// No description provided for @disputesProviderSuspendedSnack.
  ///
  /// In en, this message translates to:
  /// **'Provider {name} has been suspended.'**
  String disputesProviderSuspendedSnack(String name);

  /// No description provided for @disputesErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading complaints: {error}'**
  String disputesErrorLoading(String error);

  /// No description provided for @disputesFilterAllCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String disputesFilterAllCount(int count);

  /// No description provided for @disputesFilterPendingCount.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String disputesFilterPendingCount(int count);

  /// No description provided for @disputesFilterResolvedCount.
  ///
  /// In en, this message translates to:
  /// **'Resolved ({count})'**
  String disputesFilterResolvedCount(int count);

  /// No description provided for @disputesFilterDismissedCount.
  ///
  /// In en, this message translates to:
  /// **'Dismissed ({count})'**
  String disputesFilterDismissedCount(int count);

  /// No description provided for @disputesNoMatching.
  ///
  /// In en, this message translates to:
  /// **'No matching complaints found'**
  String get disputesNoMatching;

  /// No description provided for @disputesNoneRecorded.
  ///
  /// In en, this message translates to:
  /// **'No complaints recorded'**
  String get disputesNoneRecorded;

  /// No description provided for @disputesTryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search criteria.'**
  String get disputesTryAdjustingSearch;

  /// No description provided for @disputesAllDisputeFree.
  ///
  /// In en, this message translates to:
  /// **'All service transactions are currently dispute-free.'**
  String get disputesAllDisputeFree;

  /// No description provided for @disputesStatusResolvedCaps.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get disputesStatusResolvedCaps;

  /// No description provided for @disputesStatusDismissedCaps.
  ///
  /// In en, this message translates to:
  /// **'DISMISSED'**
  String get disputesStatusDismissedCaps;

  /// No description provided for @disputesStatusPendingCaps.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get disputesStatusPendingCaps;

  /// No description provided for @disputesFiledAgo.
  ///
  /// In en, this message translates to:
  /// **'Filed {time}'**
  String disputesFiledAgo(String time);

  /// No description provided for @disputesCustomerCaps.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER'**
  String get disputesCustomerCaps;

  /// No description provided for @disputesReportedCaps.
  ///
  /// In en, this message translates to:
  /// **'REPORTED'**
  String get disputesReportedCaps;

  /// No description provided for @disputesAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note: {note}'**
  String disputesAdminNote(String note);

  /// No description provided for @disputesReopenCase.
  ///
  /// In en, this message translates to:
  /// **'Reopen Case'**
  String get disputesReopenCase;

  /// No description provided for @disputesCaseReopenedSnack.
  ///
  /// In en, this message translates to:
  /// **'Dispute case reopened.'**
  String get disputesCaseReopenedSnack;

  /// No description provided for @shellSuperAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Only Super Admins can access Administrator Management.'**
  String get shellSuperAdminOnly;

  /// No description provided for @provLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get provLocationNotSet;

  /// No description provided for @provDirectPay.
  ///
  /// In en, this message translates to:
  /// **'Direct Pay'**
  String get provDirectPay;

  /// No description provided for @provSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get provSpecialist;

  /// No description provided for @provNicImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image size is too large ({sizeKb} KB). Maximum allowed size is 600 KB. Please choose or capture a compressed photo.'**
  String provNicImageTooLarge(int sizeKb);

  /// No description provided for @provNicDecodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to decode the captured document.'**
  String get provNicDecodeFailed;

  /// No description provided for @provNicTooLargeAfterCompression.
  ///
  /// In en, this message translates to:
  /// **'NIC image is too large even after compression. Please retake the photo.'**
  String get provNicTooLargeAfterCompression;

  /// No description provided for @provUserNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get provUserNotAuthenticated;

  /// No description provided for @provNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get provNotLoggedIn;

  /// No description provided for @provNicHintExample.
  ///
  /// In en, this message translates to:
  /// **'200012345678 or 881234567V'**
  String get provNicHintExample;

  /// No description provided for @provDurationHoursMins.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String provDurationHoursMins(int hours, int minutes);

  /// No description provided for @authGpsLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'GPS Location detected: {lat}, {lng}'**
  String authGpsLocationDetected(String lat, String lng);

  /// No description provided for @authFailedToPickProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick profile photo: {error}'**
  String authFailedToPickProfilePhoto(String error);

  /// No description provided for @authErrUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Please check your spelling or register.'**
  String get authErrUserNotFound;

  /// No description provided for @authErrWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password or email. Please check your credentials.'**
  String get authErrWrongCredentials;

  /// No description provided for @authErrEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email address.'**
  String get authErrEmailInUse;

  /// No description provided for @authErrWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Please use at least 6 characters.'**
  String get authErrWeakPassword;

  /// No description provided for @authErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get authErrInvalidEmail;

  /// No description provided for @authErrUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Please contact support.'**
  String get authErrUserDisabled;

  /// No description provided for @authErrTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment before trying again.'**
  String get authErrTooManyRequests;

  /// No description provided for @authErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network connection issue. Please check your internet connection.'**
  String get authErrNetwork;

  /// No description provided for @authErrSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled by user.'**
  String get authErrSignInCancelled;

  /// No description provided for @authErrUserDataUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Firebase user data is not available.'**
  String get authErrUserDataUnavailable;

  /// No description provided for @authErrAlreadyAdmin.
  ///
  /// In en, this message translates to:
  /// **'User is already registered as an administrator.'**
  String get authErrAlreadyAdmin;

  /// No description provided for @authErrAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed for {email}'**
  String authErrAuthenticationFailed(String email);

  /// No description provided for @authErrRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed for {email}'**
  String authErrRegistrationFailed(String email);

  /// No description provided for @authErrNoRegisteredUser.
  ///
  /// In en, this message translates to:
  /// **'No registered user found with email \"{email}\". The person must first register an account in the app before they can be promoted to an administrator.'**
  String authErrNoRegisteredUser(String email);

  /// No description provided for @nicDeskApprovedActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} approved & activated on HelaService!'**
  String nicDeskApprovedActivated(String name);

  /// No description provided for @nicDeskErrorApproving.
  ///
  /// In en, this message translates to:
  /// **'Error approving verification: {error}'**
  String nicDeskErrorApproving(String error);

  /// No description provided for @nicDeskVerificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification for {name} rejected.'**
  String nicDeskVerificationRejected(String name);

  /// No description provided for @nicDeskErrorRejecting.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting verification: {error}'**
  String nicDeskErrorRejecting(String error);

  /// No description provided for @nicDeskRequestedClearerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Requested clearer photo from {name}.'**
  String nicDeskRequestedClearerPhoto(String name);

  /// No description provided for @nicDeskErrorResubmission.
  ///
  /// In en, this message translates to:
  /// **'Error requesting resubmission: {error}'**
  String nicDeskErrorResubmission(String error);

  /// No description provided for @nicDeskPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Pending'**
  String nicDeskPendingCount(int count);

  /// No description provided for @nicDeskSortedMostRecent.
  ///
  /// In en, this message translates to:
  /// **'Sorted by Most Recent'**
  String get nicDeskSortedMostRecent;

  /// No description provided for @nicDeskDocsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Docs Uploaded'**
  String get nicDeskDocsUploaded;

  /// No description provided for @nicDeskStandardDoc.
  ///
  /// In en, this message translates to:
  /// **'Standard Doc'**
  String get nicDeskStandardDoc;

  /// No description provided for @nicDeskMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String nicDeskMatchPercent(int percent);

  /// No description provided for @nicDeskDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Western Province, Sri Lanka'**
  String get nicDeskDefaultLocation;

  /// No description provided for @nicDeskVerifiedGnDivision.
  ///
  /// In en, this message translates to:
  /// **'{location} (Verified GN Division)'**
  String nicDeskVerifiedGnDivision(String location);

  /// No description provided for @nicDeskOcrFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get nicDeskOcrFlagged;

  /// No description provided for @nicDeskOcrMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get nicDeskOcrMatch;

  /// No description provided for @nicDeskOcrValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get nicDeskOcrValid;

  /// No description provided for @nicDeskReadOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'Read-Only Mode: NIC Verification permission required to approve or reject artisan credentials.'**
  String get nicDeskReadOnlyMode;

  /// No description provided for @nicDeskNoId.
  ///
  /// In en, this message translates to:
  /// **'No ID'**
  String get nicDeskNoId;

  /// No description provided for @nicDeskNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get nicDeskNoImage;

  /// No description provided for @nicDeskTapToZoom.
  ///
  /// In en, this message translates to:
  /// **'Tap to zoom'**
  String get nicDeskTapToZoom;

  /// No description provided for @teamAdminNowStatus.
  ///
  /// In en, this message translates to:
  /// **'{name} is now {status}.'**
  String teamAdminNowStatus(String name, String status);

  /// No description provided for @teamFailedUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status: {error}'**
  String teamFailedUpdateStatus(String error);

  /// No description provided for @teamReadOnlyView.
  ///
  /// In en, this message translates to:
  /// **'Read-Only View: You are currently operating with Operations Admin privileges. Only Super Admins can add, reconfigure, or revoke administrative access.'**
  String get teamReadOnlyView;

  /// No description provided for @teamStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get teamStatusFilterLabel;

  /// No description provided for @teamAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get teamAllStatuses;

  /// No description provided for @teamNoAdminsFound.
  ///
  /// In en, this message translates to:
  /// **'No administrators found'**
  String get teamNoAdminsFound;

  /// No description provided for @teamNoAdminMatching.
  ///
  /// In en, this message translates to:
  /// **'No admin matching \"{query}\" was found.'**
  String teamNoAdminMatching(String query);

  /// No description provided for @teamTryChangingFilter.
  ///
  /// In en, this message translates to:
  /// **'Try changing your role or status filter.'**
  String get teamTryChangingFilter;

  /// No description provided for @teamColAdministrator.
  ///
  /// In en, this message translates to:
  /// **'ADMINISTRATOR'**
  String get teamColAdministrator;

  /// No description provided for @teamColTierRole.
  ///
  /// In en, this message translates to:
  /// **'TIER & ROLE'**
  String get teamColTierRole;

  /// No description provided for @teamColGrantedPermissions.
  ///
  /// In en, this message translates to:
  /// **'GRANTED PERMISSIONS'**
  String get teamColGrantedPermissions;

  /// No description provided for @teamColStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get teamColStatus;

  /// No description provided for @teamColActions.
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get teamColActions;

  /// No description provided for @teamManagedInFirebase.
  ///
  /// In en, this message translates to:
  /// **'Managed in Firebase Console'**
  String get teamManagedInFirebase;

  /// No description provided for @teamManageAdmin.
  ///
  /// In en, this message translates to:
  /// **'Manage Admin'**
  String get teamManageAdmin;

  /// No description provided for @teamEditPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit Permissions'**
  String get teamEditPermissions;

  /// No description provided for @teamProtected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get teamProtected;

  /// No description provided for @teamActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active:'**
  String get teamActiveLabel;

  /// No description provided for @adminSetBroadcastHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weather warning: Heavy rain alert in Western Province...'**
  String get adminSetBroadcastHint;

  /// No description provided for @adminSetEnterAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter an alert message.'**
  String get adminSetEnterAlertMessage;

  /// No description provided for @adminSetBroadcastDispatched.
  ///
  /// In en, this message translates to:
  /// **'Broadcast alert dispatched and recorded in live operations feed.'**
  String get adminSetBroadcastDispatched;

  /// No description provided for @adminSetBroadcastFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to dispatch broadcast: {error}'**
  String adminSetBroadcastFailed(String error);

  /// No description provided for @adminSetRecentRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} Recent Governance & Dispatch Records'**
  String adminSetRecentRecords(int count);

  /// No description provided for @adminSetExportAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Export Audit Log (JSON)'**
  String get adminSetExportAuditLog;

  /// No description provided for @adminSetAuditExported.
  ///
  /// In en, this message translates to:
  /// **'Audit log exported to clipboard as JSON.'**
  String get adminSetAuditExported;

  /// No description provided for @adminSetNoAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'No platform audit logs recorded yet.'**
  String get adminSetNoAuditLogs;

  /// No description provided for @adminSetSystemAction.
  ///
  /// In en, this message translates to:
  /// **'System Action'**
  String get adminSetSystemAction;

  /// No description provided for @adminSetAuditTag.
  ///
  /// In en, this message translates to:
  /// **'AUDIT'**
  String get adminSetAuditTag;

  /// No description provided for @adminSetRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get adminSetRecent;

  /// No description provided for @adminSetAdministratorFallback.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get adminSetAdministratorFallback;

  /// No description provided for @adminSetPlatformGovernance.
  ///
  /// In en, this message translates to:
  /// **'Platform Governance'**
  String get adminSetPlatformGovernance;

  /// No description provided for @adminSetAssignedPermissions.
  ///
  /// In en, this message translates to:
  /// **'Assigned Permissions:'**
  String get adminSetAssignedPermissions;

  /// No description provided for @adminSetAuditLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'Review administrator actions & access history'**
  String get adminSetAuditLogsDesc;

  /// No description provided for @adminSetAuditAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied: Platform audit logs are restricted to Super Admins.'**
  String get adminSetAuditAccessDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
