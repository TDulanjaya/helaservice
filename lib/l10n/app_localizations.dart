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
  /// **'Provider Hired!'**
  String get providerHired;

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
