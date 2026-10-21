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

  /// No description provided for @googleSignInExisting.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get googleSignInExisting;

  /// No description provided for @googleNoAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'No account found'**
  String get googleNoAccountTitle;

  /// No description provided for @googleNoAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no HelaService account for this Google email. Create one first.'**
  String get googleNoAccountMessage;

  /// No description provided for @splashNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your account. Check your internet connection and try again.'**
  String get splashNoConnection;

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
  /// **'Job Photos & Proof of Work'**
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
  /// **'Available now'**
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
  /// **'Contact Support'**
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
  /// **'I agree to the Provider Terms and the NIC verification process'**
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

  /// No description provided for @customerLocationNotAvailableCall.
  ///
  /// In en, this message translates to:
  /// **'Customer location not available. Call the customer.'**
  String get customerLocationNotAvailableCall;

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
  /// **'Your NIC photos and selfie are stored securely. Our team is checking your details.'**
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
  /// **'Review NIC documents and approve or reject provider registrations.'**
  String get permVerifyNicDesc;

  /// No description provided for @permManageCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure trade categories and provincial hub thresholds.'**
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

  /// No description provided for @disputesSuspendCustomer.
  ///
  /// In en, this message translates to:
  /// **'Suspend Customer'**
  String get disputesSuspendCustomer;

  /// No description provided for @disputesCustomerSuspendedSnack.
  ///
  /// In en, this message translates to:
  /// **'Customer {name} has been suspended.'**
  String disputesCustomerSuspendedSnack(String name);

  /// No description provided for @accountSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspendedTitle;

  /// No description provided for @accountSuspendedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended by administration. If you believe this is an error, please contact customer support.'**
  String get accountSuspendedDesc;

  /// No description provided for @contactHelpline.
  ///
  /// In en, this message translates to:
  /// **'Call Support Helpline'**
  String get contactHelpline;

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

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit verification code to {email}'**
  String verifyEmailSubtitle(String email);

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification code expired. Please request a new one.'**
  String get codeExpired;

  /// No description provided for @codeIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect verification code. Please check and try again.'**
  String get codeIncorrect;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// No description provided for @myJobPosts.
  ///
  /// In en, this message translates to:
  /// **'My Job Posts'**
  String get myJobPosts;

  /// No description provided for @yourPostedJobs.
  ///
  /// In en, this message translates to:
  /// **'Your Posted Jobs ({count})'**
  String yourPostedJobs(int count);

  /// No description provided for @postNewJob.
  ///
  /// In en, this message translates to:
  /// **'Post New Job'**
  String get postNewJob;

  /// No description provided for @noJobPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No Job Posts Yet'**
  String get noJobPostsYet;

  /// No description provided for @noJobPostsDesc.
  ///
  /// In en, this message translates to:
  /// **'Post a service request to receive quotes and proposals from verified technicians in your area.'**
  String get noJobPostsDesc;

  /// No description provided for @reviewQuotesCount.
  ///
  /// In en, this message translates to:
  /// **'Review Quotes ({count})'**
  String reviewQuotesCount(int count);

  /// No description provided for @locationNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Location not specified'**
  String get locationNotSpecified;

  /// No description provided for @permissionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access?'**
  String get permissionLocationTitle;

  /// No description provided for @permissionLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'HelaService uses your location to connect you with verified tradespeople nearby and calculate accurate, transparent travel costs.'**
  String get permissionLocationDesc;

  /// No description provided for @permissionLocationBullet1.
  ///
  /// In en, this message translates to:
  /// **'Find available technicians closest to your exact location.'**
  String get permissionLocationBullet1;

  /// No description provided for @permissionLocationBullet2.
  ///
  /// In en, this message translates to:
  /// **'Accurate en-route arrival tracking directly to your doorstep.'**
  String get permissionLocationBullet2;

  /// No description provided for @permissionLocationBullet3.
  ///
  /// In en, this message translates to:
  /// **'Fair, distance-based travel rates without hidden costs.'**
  String get permissionLocationBullet3;

  /// No description provided for @permissionAllowAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Allow & Continue'**
  String get permissionAllowAndContinue;

  /// No description provided for @permissionSelectDistrictManually.
  ///
  /// In en, this message translates to:
  /// **'Select District Manually'**
  String get permissionSelectDistrictManually;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Camera Access?'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'Take photos of the issue to receive accurate, transparent quotes from verified artisans.'**
  String get permissionCameraDesc;

  /// No description provided for @permissionCameraBullet1.
  ///
  /// In en, this message translates to:
  /// **'Capture clear photos of the defect, wiring, or plumbing issue.'**
  String get permissionCameraBullet1;

  /// No description provided for @permissionCameraBullet2.
  ///
  /// In en, this message translates to:
  /// **'Help artisans inspect the repair requirements before quoting.'**
  String get permissionCameraBullet2;

  /// No description provided for @permissionCameraBullet3.
  ///
  /// In en, this message translates to:
  /// **'Stored securely in cloud storage for your job history.'**
  String get permissionCameraBullet3;

  /// No description provided for @permissionOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get permissionOpenCamera;

  /// No description provided for @permissionGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select from Photos & Files?'**
  String get permissionGalleryTitle;

  /// No description provided for @permissionGalleryDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload existing photos or certificates to help verify your credentials or job details.'**
  String get permissionGalleryDesc;

  /// No description provided for @permissionGalleryBullet1.
  ///
  /// In en, this message translates to:
  /// **'Select clear certificates, NVQ licenses, or damage photos.'**
  String get permissionGalleryBullet1;

  /// No description provided for @permissionGalleryBullet2.
  ///
  /// In en, this message translates to:
  /// **'Used for profile verification and accurate job estimation.'**
  String get permissionGalleryBullet2;

  /// No description provided for @permissionGalleryBullet3.
  ///
  /// In en, this message translates to:
  /// **'Stored securely and never shared with unauthorized parties.'**
  String get permissionGalleryBullet3;

  /// No description provided for @permissionChoosePhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose Photos'**
  String get permissionChoosePhotos;

  /// No description provided for @permissionLocationPermanentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently disabled. Please enable it in system settings to detect your exact address.'**
  String get permissionLocationPermanentlyDisabled;

  /// No description provided for @permissionLocationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Needed'**
  String get permissionLocationNeeded;

  /// No description provided for @navUserManagement.
  ///
  /// In en, this message translates to:
  /// **'Users & Bans'**
  String get navUserManagement;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, phone, or NIC...'**
  String get searchUsersHint;

  /// No description provided for @filterByRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get filterByRole;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All Districts'**
  String get allDistricts;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterByStatus;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @suspendAccount.
  ///
  /// In en, this message translates to:
  /// **'Suspend Account'**
  String get suspendAccount;

  /// No description provided for @unbanAccount.
  ///
  /// In en, this message translates to:
  /// **'Lift Suspension'**
  String get unbanAccount;

  /// No description provided for @enterBanReason.
  ///
  /// In en, this message translates to:
  /// **'Enter Reason for Suspension'**
  String get enterBanReason;

  /// No description provided for @banReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Repeated fraud, abusive conduct, or policy violation'**
  String get banReasonHint;

  /// No description provided for @confirmUnbanDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to lift the suspension for this account? The user will immediately regain access to the platform.'**
  String get confirmUnbanDesc;

  /// No description provided for @userSuspendedSnack.
  ///
  /// In en, this message translates to:
  /// **'Account has been suspended.'**
  String get userSuspendedSnack;

  /// No description provided for @userRestoredSnack.
  ///
  /// In en, this message translates to:
  /// **'Account access has been restored.'**
  String get userRestoredSnack;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @activeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get activeCustomers;

  /// No description provided for @activeProviders.
  ///
  /// In en, this message translates to:
  /// **'Active Providers'**
  String get activeProviders;

  /// No description provided for @suspendedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Suspended Accounts'**
  String get suspendedAccounts;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found matching your filters'**
  String get noUsersFound;

  /// No description provided for @navUserManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, filter, and moderate customers and service providers across Sri Lanka.'**
  String get navUserManagementSubtitle;

  /// No description provided for @filterCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get filterCustomers;

  /// No description provided for @filterProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get filterProviders;

  /// No description provided for @filterAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get filterAdmins;

  /// No description provided for @filterByDistrictTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by District'**
  String get filterByDistrictTitle;

  /// No description provided for @searchDistrictHintText.
  ///
  /// In en, this message translates to:
  /// **'Search district...'**
  String get searchDistrictHintText;

  /// No description provided for @suspendUserConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend this user? The user will be immediately logged out and blocked from logging in.'**
  String get suspendUserConfirmDesc;

  /// No description provided for @pleaseEnterSuspensionReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a suspension reason.'**
  String get pleaseEnterSuspensionReason;

  /// No description provided for @presetAbusiveComm.
  ///
  /// In en, this message translates to:
  /// **'Abusive communication'**
  String get presetAbusiveComm;

  /// No description provided for @presetFraudActivity.
  ///
  /// In en, this message translates to:
  /// **'Fraudulent activity'**
  String get presetFraudActivity;

  /// No description provided for @presetFailedDispute.
  ///
  /// In en, this message translates to:
  /// **'Failed dispute resolution'**
  String get presetFailedDispute;

  /// No description provided for @presetPolicyViolation.
  ///
  /// In en, this message translates to:
  /// **'Policy violation'**
  String get presetPolicyViolation;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get reasonLabel;

  /// No description provided for @suspendedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Suspended by Administrator'**
  String get suspendedByAdmin;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @recenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter Map'**
  String get recenterMap;

  /// No description provided for @superAdminCannotBeSuspended.
  ///
  /// In en, this message translates to:
  /// **'Super Admin accounts cannot be suspended.'**
  String get superAdminCannotBeSuspended;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @permissionCameraPermanentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Camera access is permanently disabled. Please enable it in Settings to capture photos.'**
  String get permissionCameraPermanentlyDisabled;

  /// No description provided for @permissionCameraDisabled.
  ///
  /// In en, this message translates to:
  /// **'Camera access is disabled. Please enable it in App Settings.'**
  String get permissionCameraDisabled;

  /// No description provided for @permissionGalleryPermanentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Gallery access is permanently disabled. Please enable it in Settings.'**
  String get permissionGalleryPermanentlyDisabled;

  /// No description provided for @permissionGalleryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Photo access is disabled. Please enable it in App Settings.'**
  String get permissionGalleryDisabled;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Live Service Notifications?'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get real-time alerts when technicians accept your jobs, send quotes, or arrive at your location.'**
  String get permissionNotificationDesc;

  /// No description provided for @permissionNotificationBullet1.
  ///
  /// In en, this message translates to:
  /// **'Immediate alerts when an artisan accepts your job or submits a quote.'**
  String get permissionNotificationBullet1;

  /// No description provided for @permissionNotificationBullet2.
  ///
  /// In en, this message translates to:
  /// **'Live tracking updates when your technician is en-route.'**
  String get permissionNotificationBullet2;

  /// No description provided for @permissionNotificationBullet3.
  ///
  /// In en, this message translates to:
  /// **'Direct chat and urgent service dispatch alerts.'**
  String get permissionNotificationBullet3;

  /// No description provided for @permissionEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get permissionEnableNotifications;

  /// No description provided for @permissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get permissionNotNow;

  /// No description provided for @permissionNotificationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission Needed'**
  String get permissionNotificationNeeded;

  /// No description provided for @permissionNotificationPermanentlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled in device settings. Please enable them to receive job alerts.'**
  String get permissionNotificationPermanentlyDisabled;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select Option'**
  String get selectOption;

  /// No description provided for @proApprovalRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Approval Required'**
  String get proApprovalRequiredTitle;

  /// No description provided for @proApprovalRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your service provider account is awaiting administrative verification. To ensure safety and trust, job alerts and active bidding will be unlocked once approved.'**
  String get proApprovalRequiredDesc;

  /// No description provided for @proVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get proVerificationStatus;

  /// No description provided for @proStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Under Administrative Review'**
  String get proStatusPendingReview;

  /// No description provided for @proStatusActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required: Submit Verification'**
  String get proStatusActionRequired;

  /// No description provided for @proStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification Rejected'**
  String get proStatusRejected;

  /// No description provided for @proSubmitNicAction.
  ///
  /// In en, this message translates to:
  /// **'Complete NIC Verification'**
  String get proSubmitNicAction;

  /// No description provided for @proRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get proRefreshStatus;

  /// No description provided for @proCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking status...'**
  String get proCheckingStatus;

  /// No description provided for @proApprovalGrantedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Granted!'**
  String get proApprovalGrantedTitle;

  /// No description provided for @proApprovalGrantedDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your account has been approved by Admin. You now have full access to accept jobs, submit quotes, and manage your services.'**
  String get proApprovalGrantedDesc;

  /// No description provided for @proGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Enter Dashboard'**
  String get proGetStarted;

  /// No description provided for @proNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider Alerts'**
  String get proNotificationsTitle;

  /// No description provided for @proNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications at this time'**
  String get proNoNotifications;

  /// No description provided for @proMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get proMarkAllRead;

  /// No description provided for @reportToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Report to Admin'**
  String get reportToAdmin;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report / File Dispute'**
  String get reportIssueTitle;

  /// No description provided for @reportIssueDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit an official complaint about this conversation or user. Our administrative team will review the chat and take appropriate action.'**
  String get reportIssueDesc;

  /// No description provided for @reportReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a Reason'**
  String get reportReasonPrompt;

  /// No description provided for @reportNotesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Describe the incident or reason in detail...'**
  String get reportNotesPrompt;

  /// No description provided for @reportSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Complaint to Admin'**
  String get reportSubmitButton;

  /// No description provided for @reportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get reportSubmitting;

  /// No description provided for @reportSuccessSnack.
  ///
  /// In en, this message translates to:
  /// **'Complaint successfully submitted to Admin.'**
  String get reportSuccessSnack;

  /// No description provided for @adminSupportChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Support & Help Desk'**
  String get adminSupportChannelTitle;

  /// No description provided for @adminSupportChannelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Direct live support, dispute mediation & assistance'**
  String get adminSupportChannelSubtitle;

  /// No description provided for @fileFormalTicket.
  ///
  /// In en, this message translates to:
  /// **'File Formal Ticket'**
  String get fileFormalTicket;

  /// No description provided for @cancelBookingOrQuote.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking / Quote'**
  String get cancelBookingOrQuote;

  /// No description provided for @cancelBookingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking/quote?'**
  String get cancelBookingPrompt;

  /// No description provided for @cancellationReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for cancellation'**
  String get cancellationReasonPrompt;

  /// No description provided for @cancelReasonCustomerRequest.
  ///
  /// In en, this message translates to:
  /// **'Customer requested cancellation'**
  String get cancelReasonCustomerRequest;

  /// No description provided for @cancelReasonProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Provider is unavailable'**
  String get cancelReasonProviderUnavailable;

  /// No description provided for @cancelReasonScheduleConflict.
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get cancelReasonScheduleConflict;

  /// No description provided for @cancelReasonPriceDispute.
  ///
  /// In en, this message translates to:
  /// **'Price or rate disagreement'**
  String get cancelReasonPriceDispute;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @confirmCancellation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellation;

  /// No description provided for @bookingCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled successfully'**
  String get bookingCancelledSuccess;

  /// No description provided for @repostJob.
  ///
  /// In en, this message translates to:
  /// **'Repost Job'**
  String get repostJob;

  /// No description provided for @repostJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to repost this job? It will be re-opened for new quotes from nearby providers.'**
  String get repostJobConfirm;

  /// No description provided for @repostJobSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job successfully reposted!'**
  String get repostJobSuccess;

  /// No description provided for @deleteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Job'**
  String get deleteJob;

  /// No description provided for @deleteJobConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this job request? This cannot be undone.'**
  String get deleteJobConfirm;

  /// No description provided for @deleteJobSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job request deleted'**
  String get deleteJobSuccess;

  /// No description provided for @chatWithProvider.
  ///
  /// In en, this message translates to:
  /// **'Chat with Provider'**
  String get chatWithProvider;

  /// No description provided for @otpCheckSpamHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get otpCheckSpamHintTitle;

  /// No description provided for @otpCheckSpamHintDesc.
  ///
  /// In en, this message translates to:
  /// **'Please check your Spam or Junk mail folder. Verification emails may occasionally be filtered there by your email service.'**
  String get otpCheckSpamHintDesc;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get loggingOut;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navMessages;

  /// No description provided for @closestFirst.
  ///
  /// In en, this message translates to:
  /// **'Closest First'**
  String get closestFirst;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @allDistances.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allDistances;

  /// No description provided for @within5Km.
  ///
  /// In en, this message translates to:
  /// **'< 5 km'**
  String get within5Km;

  /// No description provided for @within10Km.
  ///
  /// In en, this message translates to:
  /// **'< 10 km'**
  String get within10Km;

  /// No description provided for @within25Km.
  ///
  /// In en, this message translates to:
  /// **'< 25 km'**
  String get within25Km;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewOnMap;

  /// No description provided for @nearbyTag.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyTag;

  /// No description provided for @moderateTag.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderateTag;

  /// No description provided for @extendedTag.
  ///
  /// In en, this message translates to:
  /// **'Extended'**
  String get extendedTag;

  /// No description provided for @estTravelTime.
  ///
  /// In en, this message translates to:
  /// **'~{mins} mins drive'**
  String estTravelTime(int mins);

  /// No description provided for @noJobsInRadius.
  ///
  /// In en, this message translates to:
  /// **'No jobs found within selected radius'**
  String get noJobsInRadius;

  /// No description provided for @filterRoleAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Role & Status'**
  String get filterRoleAndStatus;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @roleAllAdmins.
  ///
  /// In en, this message translates to:
  /// **'All Admins'**
  String get roleAllAdmins;

  /// No description provided for @becomeServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Become a Service Provider'**
  String get becomeServiceProvider;

  /// No description provided for @backToCustomerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Customer Dashboard'**
  String get backToCustomerDashboard;

  /// No description provided for @cancelRegistration.
  ///
  /// In en, this message translates to:
  /// **'Cancel Registration'**
  String get cancelRegistration;

  /// No description provided for @roleSwitchAdminOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Platform Maintenance & Data Inspection Mode'**
  String get roleSwitchAdminOnlyDesc;

  /// No description provided for @adminProviderPreviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Admin Preview Mode · Viewing Service Provider Interface'**
  String get adminProviderPreviewNotice;

  /// No description provided for @resubmitVerification.
  ///
  /// In en, this message translates to:
  /// **'Resubmit Verification'**
  String get resubmitVerification;

  /// No description provided for @verificationNotApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Not Approved'**
  String get verificationNotApprovedTitle;

  /// No description provided for @verificationNotApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your verification was not approved by administration. Please review your documents and resubmit.'**
  String get verificationNotApprovedBody;

  /// No description provided for @proVerificationPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Verification Submitted · Under Review'**
  String get proVerificationPendingReview;

  /// No description provided for @chooseRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to use HelaService?'**
  String get chooseRoleTitle;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your account role to continue setting up your profile.'**
  String get chooseRoleSubtitle;

  /// No description provided for @roleCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'I need a service'**
  String get roleCustomerTitle;

  /// No description provided for @roleCustomerDesc.
  ///
  /// In en, this message translates to:
  /// **'Find trusted local technicians, post job requests, or request emergency assistance anywhere in Sri Lanka.'**
  String get roleCustomerDesc;

  /// No description provided for @roleCustomerBadge.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomerBadge;

  /// No description provided for @roleCustomerPerk1.
  ///
  /// In en, this message translates to:
  /// **'Transparent Rates'**
  String get roleCustomerPerk1;

  /// No description provided for @roleCustomerPerk2.
  ///
  /// In en, this message translates to:
  /// **'Live GPS Tracking'**
  String get roleCustomerPerk2;

  /// No description provided for @roleCustomerPerk3.
  ///
  /// In en, this message translates to:
  /// **'Direct Quotes'**
  String get roleCustomerPerk3;

  /// No description provided for @roleProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'I offer a service'**
  String get roleProviderTitle;

  /// No description provided for @roleProviderDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive nearby customer job requests, submit custom quotes, and expand your service business.'**
  String get roleProviderDesc;

  /// No description provided for @roleProviderBadge.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get roleProviderBadge;

  /// No description provided for @roleProviderPerk1.
  ///
  /// In en, this message translates to:
  /// **'Jobs Radar'**
  String get roleProviderPerk1;

  /// No description provided for @roleProviderPerk2.
  ///
  /// In en, this message translates to:
  /// **'Direct Leads'**
  String get roleProviderPerk2;

  /// No description provided for @roleProviderPerk3.
  ///
  /// In en, this message translates to:
  /// **'Secure Verification'**
  String get roleProviderPerk3;

  /// No description provided for @selectServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Service Location'**
  String get selectServiceLocation;

  /// No description provided for @useCurrentGpsLocation.
  ///
  /// In en, this message translates to:
  /// **'Use GPS Location'**
  String get useCurrentGpsLocation;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @serviceAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Address'**
  String get serviceAddressLabel;

  /// No description provided for @serviceAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full street address or location details'**
  String get serviceAddressHint;

  /// No description provided for @landmarkOrNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Landmark / Entry Instructions (Optional)'**
  String get landmarkOrNoteOptional;

  /// No description provided for @landmarkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Near yellow gate, second house on the left'**
  String get landmarkHint;

  /// No description provided for @saveAddressForFuture.
  ///
  /// In en, this message translates to:
  /// **'Save this address for future requests'**
  String get saveAddressForFuture;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @selectPinOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set Pin on Map to Confirm'**
  String get selectPinOnMap;

  /// No description provided for @genericService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get genericService;

  /// No description provided for @enterReasonForSuspension.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for suspension...'**
  String get enterReasonForSuspension;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language / භාෂාව / மொழி'**
  String get appLanguageLabel;

  /// No description provided for @profilePhotoApproved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo (DP) approved!'**
  String get profilePhotoApproved;

  /// No description provided for @errorApprovingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error approving profile photo: {error}'**
  String errorApprovingPhoto(String error);

  /// No description provided for @errorApprovingNic.
  ///
  /// In en, this message translates to:
  /// **'Error approving NIC: {error}'**
  String errorApprovingNic(String error);

  /// No description provided for @tradeCertificationsApproved.
  ///
  /// In en, this message translates to:
  /// **'Trade certifications approved!'**
  String get tradeCertificationsApproved;

  /// No description provided for @errorApprovingCertifications.
  ///
  /// In en, this message translates to:
  /// **'Error approving certifications: {error}'**
  String errorApprovingCertifications(String error);

  /// No description provided for @approveDp.
  ///
  /// In en, this message translates to:
  /// **'Approve DP'**
  String get approveDp;

  /// No description provided for @dpApproved.
  ///
  /// In en, this message translates to:
  /// **'DP Approved'**
  String get dpApproved;

  /// No description provided for @approveNicBoth.
  ///
  /// In en, this message translates to:
  /// **'Approve NIC (Front+Back)'**
  String get approveNicBoth;

  /// No description provided for @approveCerts.
  ///
  /// In en, this message translates to:
  /// **'Approve Certs'**
  String get approveCerts;

  /// No description provided for @takeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Profile Photo'**
  String get takeProfilePhoto;

  /// No description provided for @selectProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Profile Photo'**
  String get selectProfilePhoto;

  /// No description provided for @failedToCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete profile: {error}'**
  String failedToCompleteProfile(String error);

  /// No description provided for @serviceCategory.
  ///
  /// In en, this message translates to:
  /// **'Service Category'**
  String get serviceCategory;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @failedToSetRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to set role: {error}'**
  String failedToSetRole(String error);

  /// No description provided for @savedAddressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label (e.g. Home, Work, Villa)'**
  String get savedAddressLabelHint;

  /// No description provided for @landmarkNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Landmark / Note (Optional)'**
  String get landmarkNoteOptional;

  /// No description provided for @deleteSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Saved Address'**
  String get deleteSavedAddress;

  /// No description provided for @confirmDeleteSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get confirmDeleteSavedAddress;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @setServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Service Location'**
  String get setServiceLocation;

  /// No description provided for @failedToUpdateJobLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to update job location: {error}'**
  String failedToUpdateJobLocation(String error);

  /// No description provided for @pleaseSelectServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a service location before posting.'**
  String get pleaseSelectServiceLocation;

  /// No description provided for @confirmServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Service Location'**
  String get confirmServiceLocation;

  /// No description provided for @pinAttemptsResetZero.
  ///
  /// In en, this message translates to:
  /// **'PIN attempts reset to 0.'**
  String get pinAttemptsResetZero;

  /// No description provided for @cannotCancelInProgressBooking.
  ///
  /// In en, this message translates to:
  /// **'Cannot cancel booking in progress. Please contact support.'**
  String get cannotCancelInProgressBooking;

  /// No description provided for @serviceVerification.
  ///
  /// In en, this message translates to:
  /// **'Service Verification'**
  String get serviceVerification;

  /// No description provided for @rateServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Rate Service Provider'**
  String get rateServiceProvider;

  /// No description provided for @jobCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Job completed successfully!'**
  String get jobCompletedSuccessfully;

  /// No description provided for @verifyAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Verify & Finish'**
  String get verifyAndFinish;

  /// No description provided for @callCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call Customer'**
  String get callCustomer;

  /// No description provided for @directServiceBooking.
  ///
  /// In en, this message translates to:
  /// **'Direct Service Booking'**
  String get directServiceBooking;

  /// No description provided for @signInCancelledByUser.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled by user.'**
  String get signInCancelledByUser;

  /// No description provided for @couldNotDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not detect location: {error}'**
  String couldNotDetectLocation(String error);

  /// No description provided for @unauthorizedRoleSwitch.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized role switch.'**
  String get unauthorizedRoleSwitch;

  /// No description provided for @givePinHint.
  ///
  /// In en, this message translates to:
  /// **'Give this 6-digit PIN to the provider once service is completed.'**
  String get givePinHint;

  /// No description provided for @directBookingWith.
  ///
  /// In en, this message translates to:
  /// **'Direct booking with {providerName}'**
  String directBookingWith(String providerName);

  /// No description provided for @directBookingWithNote.
  ///
  /// In en, this message translates to:
  /// **'Direct booking with {providerName}. Note: {note}'**
  String directBookingWithNote(String providerName, String note);

  /// No description provided for @nicVerified.
  ///
  /// In en, this message translates to:
  /// **'NIC Approved'**
  String get nicVerified;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @useGps.
  ///
  /// In en, this message translates to:
  /// **'Use GPS'**
  String get useGps;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Service Date'**
  String get serviceDate;

  /// No description provided for @agreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed Price'**
  String get agreedPrice;

  /// No description provided for @pinVerified.
  ///
  /// In en, this message translates to:
  /// **'PIN Verified on Site'**
  String get pinVerified;

  /// No description provided for @providerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Provider Details'**
  String get providerDetailsTitle;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @didYouPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Did you pay {amount} to {name}?'**
  String didYouPayAmount(String amount, String name);

  /// No description provided for @yesPaid.
  ///
  /// In en, this message translates to:
  /// **'Yes, paid'**
  String get yesPaid;

  /// No description provided for @reportPaymentProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportPaymentProblem;

  /// No description provided for @cashPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cash payment confirmed'**
  String get cashPaymentConfirmed;

  /// No description provided for @paymentDisputedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Payment disputed: {reason}'**
  String paymentDisputedWithReason(String reason);

  /// No description provided for @disputePaymentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the reason for payment dispute:'**
  String get disputePaymentPrompt;

  /// No description provided for @disputePaymentReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Overcharged, work incomplete, wrong amount'**
  String get disputePaymentReasonHint;

  /// No description provided for @submitDispute.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitDispute;

  /// No description provided for @payProviderDirectlyTip.
  ///
  /// In en, this message translates to:
  /// **'Pay the provider directly in cash after the job is completed.'**
  String get payProviderDirectlyTip;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get cashReceived;

  /// No description provided for @paymentNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Payment note (optional)'**
  String get paymentNoteOptional;

  /// No description provided for @paymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Materials, extra work'**
  String get paymentNoteHint;

  /// No description provided for @finalAmountExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed 5x agreed price'**
  String get finalAmountExceedsLimit;

  /// No description provided for @paymentWaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting confirmation'**
  String get paymentWaitingConfirmation;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentDisputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get paymentDisputed;

  /// No description provided for @earningsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get earningsToday;

  /// No description provided for @earningsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get earningsThisWeek;

  /// No description provided for @earningsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get earningsThisMonth;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @csvExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'CSV exported successfully'**
  String get csvExportSuccess;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'Completion PIN'**
  String get pinCode;

  /// No description provided for @didYouReachPerson.
  ///
  /// In en, this message translates to:
  /// **'Did you reach {name}?'**
  String didYouReachPerson(String name);

  /// No description provided for @callOutcomeAnswered.
  ///
  /// In en, this message translates to:
  /// **'Connected / Answered'**
  String get callOutcomeAnswered;

  /// No description provided for @callOutcomeNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No Answer / Busy'**
  String get callOutcomeNoAnswer;

  /// No description provided for @callOutcomeWrongNumber.
  ///
  /// In en, this message translates to:
  /// **'Wrong Number'**
  String get callOutcomeWrongNumber;

  /// No description provided for @callRequiresAcceptedQuote.
  ///
  /// In en, this message translates to:
  /// **'Phone calls become available once a quote is accepted.'**
  String get callRequiresAcceptedQuote;

  /// No description provided for @callLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Call Audit Logs'**
  String get callLogsTitle;

  /// No description provided for @callLogCaller.
  ///
  /// In en, this message translates to:
  /// **'Caller'**
  String get callLogCaller;

  /// No description provided for @callLogCallee.
  ///
  /// In en, this message translates to:
  /// **'Callee'**
  String get callLogCallee;

  /// No description provided for @callLogOutcome.
  ///
  /// In en, this message translates to:
  /// **'Call Outcome'**
  String get callLogOutcome;

  /// No description provided for @bookingTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Timeline'**
  String get bookingTimelineTitle;

  /// No description provided for @noTimelineEvents.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet'**
  String get noTimelineEvents;

  /// No description provided for @viewTimeline.
  ///
  /// In en, this message translates to:
  /// **'View Timeline'**
  String get viewTimeline;

  /// No description provided for @adminActionLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Action Logs'**
  String get adminActionLogsTitle;

  /// No description provided for @adminAuditTrailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Immutable audit trail of administrator actions'**
  String get adminAuditTrailSubtitle;

  /// No description provided for @noAdminLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No admin audit logs recorded yet'**
  String get noAdminLogsFound;

  /// No description provided for @filterUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get filterUsers;

  /// No description provided for @filterBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get filterBookings;

  /// No description provided for @filterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get filterSystem;

  /// No description provided for @noEntriesToExport.
  ///
  /// In en, this message translates to:
  /// **'No entries to export'**
  String get noEntriesToExport;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? All your personal profile data, active requests, and history will be permanently erased. This cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get deleteAccountConfirmAction;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @sendPhoto.
  ///
  /// In en, this message translates to:
  /// **'Send Photo'**
  String get sendPhoto;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View Photo'**
  String get viewPhoto;

  /// No description provided for @bookingTypeAsap.
  ///
  /// In en, this message translates to:
  /// **'ASAP / Emergency'**
  String get bookingTypeAsap;

  /// No description provided for @bookingTypeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Slot'**
  String get bookingTypeScheduled;

  /// No description provided for @selectScheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectScheduledDate;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select Time Slot'**
  String get selectTimeSlot;

  /// No description provided for @slotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning (8:00 AM - 12:00 PM)'**
  String get slotMorning;

  /// No description provided for @slotAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon (12:00 PM - 4:00 PM)'**
  String get slotAfternoon;

  /// No description provided for @slotEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening (4:00 PM - 8:00 PM)'**
  String get slotEvening;

  /// No description provided for @rescheduleBooking.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Booking'**
  String get rescheduleBooking;

  /// No description provided for @proposeNewTime.
  ///
  /// In en, this message translates to:
  /// **'Propose New Time'**
  String get proposeNewTime;

  /// No description provided for @rescheduleReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Reason for reschedule'**
  String get rescheduleReasonPrompt;

  /// No description provided for @rescheduleReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Traffic delay, customer requested later time'**
  String get rescheduleReasonHint;

  /// No description provided for @submitRescheduleRequest.
  ///
  /// In en, this message translates to:
  /// **'Request Reschedule'**
  String get submitRescheduleRequest;

  /// No description provided for @rescheduleProposalBanner.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Proposed'**
  String get rescheduleProposalBanner;

  /// No description provided for @acceptReschedule.
  ///
  /// In en, this message translates to:
  /// **'Accept Reschedule'**
  String get acceptReschedule;

  /// No description provided for @declineReschedule.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineReschedule;

  /// No description provided for @cancelRescheduleProposal.
  ///
  /// In en, this message translates to:
  /// **'Cancel Proposal'**
  String get cancelRescheduleProposal;

  /// No description provided for @expiredPill.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredPill;

  /// No description provided for @workingHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Working Hours & Schedule'**
  String get workingHoursTitle;

  /// No description provided for @serviceRadiusTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Coverage Radius'**
  String get serviceRadiusTitle;

  /// No description provided for @serviceRadiusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance you will travel for jobs'**
  String get serviceRadiusSubtitle;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @openTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get openTime;

  /// No description provided for @closeTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get closeTime;

  /// No description provided for @closedDay.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedDay;

  /// No description provided for @presetWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays (8 AM - 6 PM)'**
  String get presetWeekdays;

  /// No description provided for @presetAllDays.
  ///
  /// In en, this message translates to:
  /// **'All 7 Days (8 AM - 8 PM)'**
  String get presetAllDays;

  /// No description provided for @preset247.
  ///
  /// In en, this message translates to:
  /// **'Open 24/7'**
  String get preset247;

  /// No description provided for @unavailableNow.
  ///
  /// In en, this message translates to:
  /// **'Unavailable now'**
  String get unavailableNow;

  /// No description provided for @outsideWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Outside working hours'**
  String get outsideWorkingHours;

  /// No description provided for @savedScheduleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Working hours updated successfully'**
  String get savedScheduleSuccess;

  /// No description provided for @savedRadiusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Service radius updated'**
  String get savedRadiusSuccess;

  /// No description provided for @serviceRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'{radius} km radius'**
  String serviceRadiusKm(int radius);

  /// No description provided for @rescheduleRequestedNotice.
  ///
  /// In en, this message translates to:
  /// **'Reschedule proposal pending response'**
  String get rescheduleRequestedNotice;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @jobPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Before and after service inspection photos'**
  String get jobPhotosSubtitle;

  /// No description provided for @beforePhotos.
  ///
  /// In en, this message translates to:
  /// **'Before Service'**
  String get beforePhotos;

  /// No description provided for @afterPhotos.
  ///
  /// In en, this message translates to:
  /// **'After Service'**
  String get afterPhotos;

  /// No description provided for @addBeforePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Before Photo'**
  String get addBeforePhoto;

  /// No description provided for @addAfterPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add After Photo'**
  String get addAfterPhoto;

  /// No description provided for @noBeforePhotos.
  ///
  /// In en, this message translates to:
  /// **'No before photos uploaded yet'**
  String get noBeforePhotos;

  /// No description provided for @noAfterPhotos.
  ///
  /// In en, this message translates to:
  /// **'No after photos uploaded yet'**
  String get noAfterPhotos;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio & Past Work'**
  String get portfolioTitle;

  /// No description provided for @portfolioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showcase your completed projects to customers'**
  String get portfolioSubtitle;

  /// No description provided for @addPortfolioItem.
  ///
  /// In en, this message translates to:
  /// **'Add Showcase Item'**
  String get addPortfolioItem;

  /// No description provided for @portfolioItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Title'**
  String get portfolioItemTitle;

  /// No description provided for @portfolioItemTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Living room full rewiring'**
  String get portfolioItemTitleHint;

  /// No description provided for @portfolioItemDesc.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get portfolioItemDesc;

  /// No description provided for @portfolioItemDescHint.
  ///
  /// In en, this message translates to:
  /// **'Brief details about the work done'**
  String get portfolioItemDescHint;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @photoUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Photo uploaded successfully'**
  String get photoUploadedSuccess;

  /// No description provided for @portfolioItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Showcase item added successfully'**
  String get portfolioItemAdded;

  /// No description provided for @deletePortfolioConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this portfolio item?'**
  String get deletePortfolioConfirm;

  /// No description provided for @noPortfolioItems.
  ///
  /// In en, this message translates to:
  /// **'No portfolio items added yet'**
  String get noPortfolioItems;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @selectCategoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategoryPrompt;

  /// No description provided for @newProviderBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newProviderBadge;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUserTitle;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user? They will not be able to send you requests or message you.'**
  String get blockUserConfirm;

  /// No description provided for @blockUserAction.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUserAction;

  /// No description provided for @unblockUserAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUserAction;

  /// No description provided for @userBlockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User has been blocked'**
  String get userBlockedSuccess;

  /// No description provided for @userUnblockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User has been unblocked'**
  String get userUnblockedSuccess;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUserTitle;

  /// No description provided for @reportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for Report'**
  String get reportReasonLabel;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate or abusive behavior'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or unwanted advertising'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud, overcharging, or scam'**
  String get reportReasonFraud;

  /// No description provided for @reportReasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show or abandoned service'**
  String get reportReasonNoShow;

  /// No description provided for @reportReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety or trust concern'**
  String get reportReasonSafety;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other violation'**
  String get reportReasonOther;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened in detail...'**
  String get reportDetailsHint;

  /// No description provided for @reportAlsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Also block this user'**
  String get reportAlsoBlock;

  /// No description provided for @reportSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Our support team will review this shortly.'**
  String get reportSubmittedSuccess;

  /// No description provided for @offlineBannerText.
  ///
  /// In en, this message translates to:
  /// **'You are currently offline. Check your connection.'**
  String get offlineBannerText;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer version of HelaService with critical improvements is required to continue.'**
  String get forceUpdateMessage;

  /// No description provided for @updateNowAction.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNowAction;

  /// No description provided for @emergencyDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent Help & Emergency Dispatch'**
  String get emergencyDispatchTitle;

  /// No description provided for @emergencyDispatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and call out verified artisans within 15km right now'**
  String get emergencyDispatchSubtitle;

  /// No description provided for @scanningNearbyProviders.
  ///
  /// In en, this message translates to:
  /// **'Scanning nearby emergency artisans...'**
  String get scanningNearbyProviders;

  /// No description provided for @dispatchTimerLabel.
  ///
  /// In en, this message translates to:
  /// **'Dispatch search window'**
  String get dispatchTimerLabel;

  /// No description provided for @noEmergencyProvidersFound.
  ///
  /// In en, this message translates to:
  /// **'No emergency artisans found within 15km right now'**
  String get noEmergencyProvidersFound;

  /// No description provided for @noEmergencyProvidersDesc.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different trade category or post an urgent job request.'**
  String get noEmergencyProvidersDesc;

  /// No description provided for @emergencyCalloutRate.
  ///
  /// In en, this message translates to:
  /// **'Emergency / Callout Rate'**
  String get emergencyCalloutRate;

  /// No description provided for @emergencyEtaApprox.
  ///
  /// In en, this message translates to:
  /// **'approx {mins} mins away'**
  String emergencyEtaApprox(int mins);

  /// No description provided for @distanceKmAway.
  ///
  /// In en, this message translates to:
  /// **'{dist} km away'**
  String distanceKmAway(String dist);

  /// No description provided for @requestEmergencyCallout.
  ///
  /// In en, this message translates to:
  /// **'Dispatch Now'**
  String get requestEmergencyCallout;

  /// No description provided for @confirmEmergencyBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Emergency Callout'**
  String get confirmEmergencyBookingTitle;

  /// No description provided for @confirmEmergencyBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'An emergency dispatch request will be sent to {name} immediately. Rate: LKR {rate}.'**
  String confirmEmergencyBookingDesc(String name, String rate);

  /// No description provided for @emergencyAddressPrompt.
  ///
  /// In en, this message translates to:
  /// **'Emergency Service Location'**
  String get emergencyAddressPrompt;

  /// No description provided for @emergencyNotesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Emergency details (optional)'**
  String get emergencyNotesPrompt;

  /// No description provided for @emergencyNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Water pipe burst in kitchen, power outage in main circuit'**
  String get emergencyNotesHint;

  /// No description provided for @emergencyHotlinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sri Lanka Emergency Hotlines'**
  String get emergencyHotlinesTitle;

  /// No description provided for @hotlinePolice.
  ///
  /// In en, this message translates to:
  /// **'Police Emergency (119)'**
  String get hotlinePolice;

  /// No description provided for @hotlineAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Suwa Seriya Ambulance (1990)'**
  String get hotlineAmbulance;

  /// No description provided for @hotlineFire.
  ///
  /// In en, this message translates to:
  /// **'Fire & Rescue (110)'**
  String get hotlineFire;

  /// No description provided for @urgentHelpBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent Repair or Breakdown?'**
  String get urgentHelpBannerTitle;

  /// No description provided for @urgentHelpBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Instant 15km artisan dispatch for water leaks, power failures, or locksmith emergencies.'**
  String get urgentHelpBannerDesc;

  /// No description provided for @urgentHelpBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Get Urgent Help'**
  String get urgentHelpBannerAction;

  /// No description provided for @myRates.
  ///
  /// In en, this message translates to:
  /// **'My Rates'**
  String get myRates;

  /// No description provided for @rateCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Standard Service Rates'**
  String get rateCardTitle;

  /// No description provided for @dailyRate.
  ///
  /// In en, this message translates to:
  /// **'Daily Rate'**
  String get dailyRate;

  /// No description provided for @perKmTravelRate.
  ///
  /// In en, this message translates to:
  /// **'Per Km Travel Rate'**
  String get perKmTravelRate;

  /// No description provided for @standardVisitFee.
  ///
  /// In en, this message translates to:
  /// **'Inspection / Visit Fee'**
  String get standardVisitFee;

  /// No description provided for @quoteTypeFirm.
  ///
  /// In en, this message translates to:
  /// **'Firm Price'**
  String get quoteTypeFirm;

  /// No description provided for @quoteTypeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated Range'**
  String get quoteTypeEstimate;

  /// No description provided for @quoteTypeInspect.
  ///
  /// In en, this message translates to:
  /// **'Inspection / Visit Only'**
  String get quoteTypeInspect;

  /// No description provided for @priceRevisionProposed.
  ///
  /// In en, this message translates to:
  /// **'Price Revision Proposed'**
  String get priceRevisionProposed;

  /// No description provided for @extraWorkRequested.
  ///
  /// In en, this message translates to:
  /// **'Extra Work / Materials'**
  String get extraWorkRequested;

  /// No description provided for @visitOnlyCompletedNote.
  ///
  /// In en, this message translates to:
  /// **'This booking was completed as an Inspection / Visit only. Standard reviews are disabled.'**
  String get visitOnlyCompletedNote;

  /// No description provided for @completionTypeNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal Job Completion'**
  String get completionTypeNormal;

  /// No description provided for @completionTypeVisitOnly.
  ///
  /// In en, this message translates to:
  /// **'Inspection / Visit Only'**
  String get completionTypeVisitOnly;

  /// No description provided for @hourlyRate.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRate;

  /// No description provided for @yourUsualRates.
  ///
  /// In en, this message translates to:
  /// **'Your Usual Rates'**
  String get yourUsualRates;

  /// No description provided for @yourUsualRatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'At least one rate is required. Used when customers request quotes.'**
  String get yourUsualRatesSubtitle;

  /// No description provided for @dailyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3500 (1 - 100,000)'**
  String get dailyRateHint;

  /// No description provided for @hourlyRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500 (1 - 20,000)'**
  String get hourlyRateHint;

  /// No description provided for @perKmRateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 80 (1 - 1,000)'**
  String get perKmRateHint;

  /// No description provided for @visitFeeOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional, e.g. 1000 (0 - 20,000)'**
  String get visitFeeOptionalHint;

  /// No description provided for @atLeastOneRateRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one rate (daily, hourly, or per km) is required.'**
  String get atLeastOneRateRequired;

  /// No description provided for @dailyRateRangeError.
  ///
  /// In en, this message translates to:
  /// **'Daily rate must be between LKR 1 and 100,000'**
  String get dailyRateRangeError;

  /// No description provided for @hourlyRateRangeError.
  ///
  /// In en, this message translates to:
  /// **'Hourly rate must be between LKR 1 and 20,000'**
  String get hourlyRateRangeError;

  /// No description provided for @perKmRateRangeError.
  ///
  /// In en, this message translates to:
  /// **'Per km rate must be between LKR 1 and 1,000'**
  String get perKmRateRangeError;

  /// No description provided for @visitFeeRangeError.
  ///
  /// In en, this message translates to:
  /// **'Visit fee must be between LKR 0 and 20,000'**
  String get visitFeeRangeError;

  /// No description provided for @withinAgreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Within agreed price'**
  String get withinAgreedPrice;

  /// No description provided for @visitFeeOnly.
  ///
  /// In en, this message translates to:
  /// **'Visit fee only'**
  String get visitFeeOnly;

  /// No description provided for @approvedExtrasBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Approved Extras'**
  String get approvedExtrasBreakdown;

  /// No description provided for @initialEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Initial Quoted / Estimated Price'**
  String get initialEstimateLabel;

  /// No description provided for @revisedAgreedPrice.
  ///
  /// In en, this message translates to:
  /// **'Agreed Price'**
  String get revisedAgreedPrice;

  /// No description provided for @finalAmountToPay.
  ///
  /// In en, this message translates to:
  /// **'Final Amount to Pay'**
  String get finalAmountToPay;

  /// No description provided for @priceMatchesQuote.
  ///
  /// In en, this message translates to:
  /// **'Price Matches Quote'**
  String get priceMatchesQuote;

  /// No description provided for @proposeNewPrice.
  ///
  /// In en, this message translates to:
  /// **'Propose New Price'**
  String get proposeNewPrice;

  /// No description provided for @proposeRevisedPrice.
  ///
  /// In en, this message translates to:
  /// **'Propose Revised Price'**
  String get proposeRevisedPrice;

  /// No description provided for @billingUnit.
  ///
  /// In en, this message translates to:
  /// **'Billing Unit'**
  String get billingUnit;

  /// No description provided for @billingUnitFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Job'**
  String get billingUnitFixed;

  /// No description provided for @billingUnitHour.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get billingUnitHour;

  /// No description provided for @billingUnitDay.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get billingUnitDay;

  /// No description provided for @unitRateLkr.
  ///
  /// In en, this message translates to:
  /// **'Unit Rate (LKR)'**
  String get unitRateLkr;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @priceChangeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for Price Change'**
  String get priceChangeReason;

  /// No description provided for @priceChangeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Additional concealed pipeline damage discovered'**
  String get priceChangeReasonHint;

  /// No description provided for @totalRevisedPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Revised Price'**
  String get totalRevisedPrice;

  /// No description provided for @submitProposal.
  ///
  /// In en, this message translates to:
  /// **'Submit Proposal'**
  String get submitProposal;

  /// No description provided for @addExtraWorkItem.
  ///
  /// In en, this message translates to:
  /// **'Add Extra Work / Item'**
  String get addExtraWorkItem;

  /// No description provided for @extraDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get extraDescription;

  /// No description provided for @extraDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Extra 2m PVC pipe & joint fitting'**
  String get extraDescriptionHint;

  /// No description provided for @extraAmountLkr.
  ///
  /// In en, this message translates to:
  /// **'Amount (LKR)'**
  String get extraAmountLkr;

  /// No description provided for @proposeExtra.
  ///
  /// In en, this message translates to:
  /// **'Propose Extra'**
  String get proposeExtra;

  /// No description provided for @awaitingCustomerApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for customer approval'**
  String get awaitingCustomerApproval;

  /// No description provided for @priceProposalSent.
  ///
  /// In en, this message translates to:
  /// **'Price proposal sent to customer for approval'**
  String get priceProposalSent;

  /// No description provided for @extraProposalSent.
  ///
  /// In en, this message translates to:
  /// **'Extra work proposal sent to customer'**
  String get extraProposalSent;

  /// No description provided for @priceConfirmedMatches.
  ///
  /// In en, this message translates to:
  /// **'Price confirmed matches original quote'**
  String get priceConfirmedMatches;

  /// No description provided for @priceProposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Price proposal rejected'**
  String get priceProposalRejected;

  /// No description provided for @priceProposalApproved.
  ///
  /// In en, this message translates to:
  /// **'Price proposal approved'**
  String get priceProposalApproved;

  /// No description provided for @myRateCard.
  ///
  /// In en, this message translates to:
  /// **'My Rate Card'**
  String get myRateCard;

  /// No description provided for @rateCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your standard rates shown to customers and used in quotes.'**
  String get rateCardSubtitle;

  /// No description provided for @saveRates.
  ///
  /// In en, this message translates to:
  /// **'Save Rates'**
  String get saveRates;

  /// No description provided for @rateCardUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rate card updated successfully'**
  String get rateCardUpdatedSuccess;

  /// No description provided for @travelRate.
  ///
  /// In en, this message translates to:
  /// **'Travel Rate'**
  String get travelRate;

  /// No description provided for @pricingStandardRates.
  ///
  /// In en, this message translates to:
  /// **'Pricing & Standard Rates'**
  String get pricingStandardRates;

  /// No description provided for @uploadRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry Upload'**
  String get uploadRetry;

  /// No description provided for @largeMediaWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Large File Warning'**
  String get largeMediaWarningTitle;

  /// No description provided for @largeMediaWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'File is large (>20MB). Uploading over mobile data may take time and consume data. Proceed?'**
  String get largeMediaWarningMessage;

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @customerDidNotAgreeVisitOnly.
  ///
  /// In en, this message translates to:
  /// **'Customer did not agree. Collect only the visit fee: LKR {amount}'**
  String customerDidNotAgreeVisitOnly(String amount);

  /// No description provided for @completeVisitOnly.
  ///
  /// In en, this message translates to:
  /// **'Complete Visit Only'**
  String get completeVisitOnly;

  /// No description provided for @priceRevisionReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for the price revision'**
  String get priceRevisionReasonRequired;

  /// No description provided for @checkRateAndQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please check rate and quantity values'**
  String get checkRateAndQuantity;

  /// No description provided for @extraDescriptionLimit.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description (max 300 characters)'**
  String get extraDescriptionLimit;

  /// No description provided for @extraAmountLimit.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount between LKR 1 and 1,000,000'**
  String get extraAmountLimit;

  /// No description provided for @notesLimit500.
  ///
  /// In en, this message translates to:
  /// **'Notes must be 500 characters or less'**
  String get notesLimit500;

  /// No description provided for @validVisitFeePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid visit fee (LKR 1 - 20,000)'**
  String get validVisitFeePrompt;

  /// No description provided for @validUnitRatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid unit rate (minimum LKR 1)'**
  String get validUnitRatePrompt;

  /// No description provided for @validQuantityPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity (0.5 to 60)'**
  String get validQuantityPrompt;

  /// No description provided for @materialsEstimateLimit.
  ///
  /// In en, this message translates to:
  /// **'Materials estimate must be between LKR 0 and 1,000,000'**
  String get materialsEstimateLimit;

  /// No description provided for @visitInspectionFee.
  ///
  /// In en, this message translates to:
  /// **'Visit / Inspection Fee:'**
  String get visitInspectionFee;

  /// No description provided for @materialsEstimateColon.
  ///
  /// In en, this message translates to:
  /// **'Materials Estimate:'**
  String get materialsEstimateColon;

  /// No description provided for @addIssueVideoMax.
  ///
  /// In en, this message translates to:
  /// **'Add Issue Video (Max 120s)'**
  String get addIssueVideoMax;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get recordVideo;

  /// No description provided for @errorPickingVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick video. Please try again.'**
  String get errorPickingVideo;

  /// No description provided for @videoOfIssueOptional.
  ///
  /// In en, this message translates to:
  /// **'Video of Issue (Optional)'**
  String get videoOfIssueOptional;

  /// No description provided for @jobVideo.
  ///
  /// In en, this message translates to:
  /// **'Job Video'**
  String get jobVideo;

  /// No description provided for @videoClip.
  ///
  /// In en, this message translates to:
  /// **'Video Clip'**
  String get videoClip;

  /// No description provided for @failedToPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to play video'**
  String get failedToPlayVideo;

  /// No description provided for @failedToUpdateRates.
  ///
  /// In en, this message translates to:
  /// **'Failed to update rates. Please try again.'**
  String get failedToUpdateRates;

  /// No description provided for @quoteOutdatedDeclined.
  ///
  /// In en, this message translates to:
  /// **'This quote is outdated, ask the provider to send a new one'**
  String get quoteOutdatedDeclined;

  /// No description provided for @youAreMetersAway.
  ///
  /// In en, this message translates to:
  /// **'You are about {distance} m away from the job location.'**
  String youAreMetersAway(String distance);

  /// No description provided for @imHereGpsWrong.
  ///
  /// In en, this message translates to:
  /// **'I\'m here, but GPS is wrong'**
  String get imHereGpsWrong;

  /// No description provided for @slideToClaimArrival.
  ///
  /// In en, this message translates to:
  /// **'Slide to claim arrival'**
  String get slideToClaimArrival;

  /// No description provided for @waitingCustomerConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Arrival claimed. Waiting for customer confirmation...'**
  String get waitingCustomerConfirmation;

  /// No description provided for @arrivalDeniedProviderNotice.
  ///
  /// In en, this message translates to:
  /// **'Customer says you have not arrived. Please check the location or call the customer.'**
  String get arrivalDeniedProviderNotice;

  /// No description provided for @claimAgainArrival.
  ///
  /// In en, this message translates to:
  /// **'Claim Arrival Again'**
  String get claimAgainArrival;

  /// No description provided for @maxClaimsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum arrival claims reached (3/3).'**
  String get maxClaimsReached;

  /// No description provided for @customerDidNotAnswer.
  ///
  /// In en, this message translates to:
  /// **'Customer has not responded after 10 minutes.'**
  String get customerDidNotAnswer;

  /// No description provided for @startJobVerifiedGps.
  ///
  /// In en, this message translates to:
  /// **'Start Job (GPS Verified)'**
  String get startJobVerifiedGps;

  /// No description provided for @callCustomerToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Call customer to confirm arrival'**
  String get callCustomerToConfirm;

  /// No description provided for @providerSaysArrived.
  ///
  /// In en, this message translates to:
  /// **'{providerName} says they have arrived. Are they with you?'**
  String providerSaysArrived(String providerName);

  /// No description provided for @providerGpsShowsAway.
  ///
  /// In en, this message translates to:
  /// **'Their GPS shows {distance} m away.'**
  String providerGpsShowsAway(String distance);

  /// No description provided for @yesTheyAreHere.
  ///
  /// In en, this message translates to:
  /// **'Yes, they\'re here'**
  String get yesTheyAreHere;

  /// No description provided for @noNotHere.
  ///
  /// In en, this message translates to:
  /// **'No, not here'**
  String get noNotHere;

  /// No description provided for @providerDidNotCome.
  ///
  /// In en, this message translates to:
  /// **'Provider didn\'t come'**
  String get providerDidNotCome;

  /// No description provided for @confirmNoShowTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Provider No-Show?'**
  String get confirmNoShowTitle;

  /// No description provided for @confirmNoShowMessage.
  ///
  /// In en, this message translates to:
  /// **'This will cancel the booking because the service provider did not arrive.'**
  String get confirmNoShowMessage;

  /// No description provided for @locationRequiredToBook.
  ///
  /// In en, this message translates to:
  /// **'Please select a location with GPS coordinates to book this service.'**
  String get locationRequiredToBook;

  /// No description provided for @arrivalMockedFlag.
  ///
  /// In en, this message translates to:
  /// **'Mocked GPS Detected'**
  String get arrivalMockedFlag;

  /// No description provided for @arrivalOutsideZoneFlag.
  ///
  /// In en, this message translates to:
  /// **'Claimed Outside Zone'**
  String get arrivalOutsideZoneFlag;

  /// No description provided for @arrivalDeniedFlag.
  ///
  /// In en, this message translates to:
  /// **'Customer Denied Arrival'**
  String get arrivalDeniedFlag;

  /// No description provided for @noShowFlag.
  ///
  /// In en, this message translates to:
  /// **'Provider No-Show'**
  String get noShowFlag;

  /// No description provided for @gpsOutsideZoneAlert.
  ///
  /// In en, this message translates to:
  /// **'GPS indicates you are outside the job zone ({distance} m away). Do you want to submit an arrival claim anyway?'**
  String gpsOutsideZoneAlert(String distance);

  /// No description provided for @proceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed Anyway'**
  String get proceedAnyway;

  /// No description provided for @claimSuccessNotified.
  ///
  /// In en, this message translates to:
  /// **'Arrival claim submitted. The customer has been notified.'**
  String get claimSuccessNotified;

  /// No description provided for @completeJobEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Complete Job (Enter Customer PIN)'**
  String get completeJobEnterPin;

  /// No description provided for @noShowReportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Provider no-show reported. Booking cancelled.'**
  String get noShowReportedSuccess;

  /// No description provided for @providerReliability90Days.
  ///
  /// In en, this message translates to:
  /// **'90-Day Reliability & Arrival Verification'**
  String get providerReliability90Days;

  /// No description provided for @providerNoShowsCount.
  ///
  /// In en, this message translates to:
  /// **'No-Shows'**
  String get providerNoShowsCount;

  /// No description provided for @providerArrivalDenialsCount.
  ///
  /// In en, this message translates to:
  /// **'Arrival Denials'**
  String get providerArrivalDenialsCount;

  /// No description provided for @providerMockedGpsCount.
  ///
  /// In en, this message translates to:
  /// **'Mocked GPS'**
  String get providerMockedGpsCount;

  /// No description provided for @providerOutsideZoneCount.
  ///
  /// In en, this message translates to:
  /// **'Outside Zone'**
  String get providerOutsideZoneCount;

  /// No description provided for @scheduledTimePassedPrompt.
  ///
  /// In en, this message translates to:
  /// **'The scheduled time has passed. Please choose a new date and time.'**
  String get scheduledTimePassedPrompt;

  /// No description provided for @chooseNewScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Scheduled Time'**
  String get chooseNewScheduleTitle;

  /// No description provided for @revisedEstimateDefault.
  ///
  /// In en, this message translates to:
  /// **'Revised on-site estimate'**
  String get revisedEstimateDefault;

  /// No description provided for @pleaseEnterSixDigits.
  ///
  /// In en, this message translates to:
  /// **'Please enter 6 digits'**
  String get pleaseEnterSixDigits;

  /// No description provided for @customerLocationNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer location not available'**
  String get customerLocationNotAvailableTitle;

  /// No description provided for @customerLocationNotAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Exact GPS coordinates were not provided for this job. Contact the customer below to coordinate arrival.'**
  String get customerLocationNotAvailableDesc;

  /// No description provided for @locationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get locationRequiredTitle;

  /// No description provided for @jobNoLocationRepost.
  ///
  /// In en, this message translates to:
  /// **'This job has no location. Please set the location and repost.'**
  String get jobNoLocationRepost;

  /// No description provided for @quoteAcceptedChatMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello {providerName}, I have accepted your quote (LKR {price}). Let\'s coordinate the job details!'**
  String quoteAcceptedChatMessage(String providerName, String price);

  /// No description provided for @pleaseEnterServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter service location address'**
  String get pleaseEnterServiceLocation;

  /// No description provided for @optimizingVideoNotice.
  ///
  /// In en, this message translates to:
  /// **'Optimizing video (max 120s)...'**
  String get optimizingVideoNotice;

  /// No description provided for @addShortVideo.
  ///
  /// In en, this message translates to:
  /// **'Add Short Video'**
  String get addShortVideo;

  /// No description provided for @addShortVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 120s explaining the repair or issue'**
  String get addShortVideoSubtitle;

  /// No description provided for @noServicesAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No services available yet'**
  String get noServicesAvailableYet;

  /// No description provided for @editSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Saved Address'**
  String get editSavedAddress;

  /// No description provided for @signInToManageSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage saved addresses.'**
  String get signInToManageSavedAddresses;

  /// No description provided for @noSavedAddressesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet. Add home or work addresses for one-tap booking.'**
  String get noSavedAddressesSubtitle;

  /// No description provided for @becomeProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer your trade skills, receive jobs, and earn more'**
  String get becomeProviderSubtitle;

  /// No description provided for @switchToProvider.
  ///
  /// In en, this message translates to:
  /// **'Switch to Provider Mode'**
  String get switchToProvider;

  /// No description provided for @switchToProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch back to your Service Provider workspace'**
  String get switchToProviderSubtitle;

  /// No description provided for @adminInspectionMode.
  ///
  /// In en, this message translates to:
  /// **'Admin Inspection Mode'**
  String get adminInspectionMode;

  /// No description provided for @adminInspectionModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Viewing provider workspace with administrative bypass.'**
  String get adminInspectionModeDesc;

  /// No description provided for @setStandardRatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set standard visit and hourly rates'**
  String get setStandardRatesSubtitle;

  /// No description provided for @quoteAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote Accepted!'**
  String get quoteAcceptedTitle;

  /// No description provided for @customerConfirmedBooking.
  ///
  /// In en, this message translates to:
  /// **'Customer confirmed this booking'**
  String get customerConfirmedBooking;

  /// No description provided for @enterProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a project title'**
  String get enterProjectTitle;

  /// No description provided for @selectPhotoForShowcase.
  ///
  /// In en, this message translates to:
  /// **'Please select a photo for this showcase item'**
  String get selectPhotoForShowcase;

  /// No description provided for @failedToSaveShowcase.
  ///
  /// In en, this message translates to:
  /// **'Failed to save showcase item: {error}'**
  String failedToSaveShowcase(String error);

  /// No description provided for @quoteType.
  ///
  /// In en, this message translates to:
  /// **'Quote Type'**
  String get quoteType;

  /// No description provided for @inspectionQuoteNotice.
  ///
  /// In en, this message translates to:
  /// **'Inspection quote includes on-site visit fee and travel cost. Total job price will be agreed upon arrival.'**
  String get inspectionQuoteNotice;

  /// No description provided for @materialsEstimateOptional.
  ///
  /// In en, this message translates to:
  /// **'Materials Estimate (Optional)'**
  String get materialsEstimateOptional;

  /// No description provided for @estDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'Est. Distance (km)'**
  String get estDistanceKm;

  /// No description provided for @travelRateLkrKm.
  ///
  /// In en, this message translates to:
  /// **'Travel Rate (LKR/km)'**
  String get travelRateLkrKm;

  /// No description provided for @totalQuotedPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Quoted Price'**
  String get totalQuotedPrice;

  /// No description provided for @travelFee.
  ///
  /// In en, this message translates to:
  /// **'Travel Fee'**
  String get travelFee;

  /// No description provided for @statusSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get statusSelected;

  /// No description provided for @providerBaseLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Provider base location is required. Please set GPS/Map pin and address.'**
  String get providerBaseLocationRequired;

  /// No description provided for @baseWorkshopLocation.
  ///
  /// In en, this message translates to:
  /// **'Base Workshop / Service Location *'**
  String get baseWorkshopLocation;

  /// No description provided for @baseLocationDispatchNotice.
  ///
  /// In en, this message translates to:
  /// **'Required for nearest provider dispatch calculations'**
  String get baseLocationDispatchNotice;

  /// No description provided for @suspensionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Suspension Reason:'**
  String get suspensionReasonLabel;

  /// No description provided for @registerBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up in seconds to access verified roadside and home service experts across Sri Lanka.'**
  String get registerBannerSubtitle;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @isLive.
  ///
  /// In en, this message translates to:
  /// **'Is Live'**
  String get isLive;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @priceHistoryAudit.
  ///
  /// In en, this message translates to:
  /// **'Price History & Audit'**
  String get priceHistoryAudit;

  /// No description provided for @finalChargedAmount.
  ///
  /// In en, this message translates to:
  /// **'Final Charged Amount:'**
  String get finalChargedAmount;

  /// No description provided for @suspendCustomerConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend customer \"{name}\"? Their account will be locked and they will be barred from creating requests or accessing the platform.'**
  String suspendCustomerConfirmPrompt(String name);

  /// No description provided for @unableToLoadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Unable to load photo'**
  String get unableToLoadPhoto;

  /// No description provided for @newTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'New Time:'**
  String get newTimeLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get noteLabel;

  /// No description provided for @resetPinAttempts.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN attempts'**
  String get resetPinAttempts;

  /// No description provided for @noServiceHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No Service History Yet'**
  String get noServiceHistoryYet;

  /// No description provided for @noServiceHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed and past bookings will appear here.'**
  String get noServiceHistorySubtitle;

  /// No description provided for @yourRatingReview.
  ///
  /// In en, this message translates to:
  /// **'Your Rating & Review'**
  String get yourRatingReview;

  /// No description provided for @signInToViewBookings.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your bookings'**
  String get signInToViewBookings;

  /// No description provided for @pendingAdminApprovalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Pending Admin Approval · Unavailable for hire'**
  String get pendingAdminApprovalUnavailable;

  /// No description provided for @directContactFastQuotes.
  ///
  /// In en, this message translates to:
  /// **'Direct Contact & Fast Quotes'**
  String get directContactFastQuotes;

  /// No description provided for @verifiedPhoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'Verified phone available'**
  String get verifiedPhoneAvailable;

  /// No description provided for @officialSupport.
  ///
  /// In en, this message translates to:
  /// **'Official Support'**
  String get officialSupport;

  /// No description provided for @failedToSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule'**
  String get failedToSaveSchedule;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusEnRoute.
  ///
  /// In en, this message translates to:
  /// **'En Route'**
  String get statusEnRoute;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @completionPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion PIN:'**
  String get completionPinLabel;

  /// No description provided for @chatPhotoMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhotoMessage;

  /// No description provided for @hintFullName.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get hintFullName;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get hintEmail;

  /// No description provided for @hintPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get hintPhone;

  /// No description provided for @hintCategorySearch.
  ///
  /// In en, this message translates to:
  /// **'e.g. Electrician, Plumber'**
  String get hintCategorySearch;

  /// No description provided for @hintAmount.
  ///
  /// In en, this message translates to:
  /// **'e.g. 3500'**
  String get hintAmount;

  /// No description provided for @hintNicFormat.
  ///
  /// In en, this message translates to:
  /// **'12 digits, or 9 digits + V'**
  String get hintNicFormat;

  /// No description provided for @hintCustomerName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sanduni Perera'**
  String get hintCustomerName;

  /// No description provided for @hintProviderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get hintProviderEmail;

  /// No description provided for @hintAdminName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ruwan Jayasundara'**
  String get hintAdminName;

  /// No description provided for @priceStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Price Status:'**
  String get priceStatusLabel;

  /// No description provided for @proposedLabel.
  ///
  /// In en, this message translates to:
  /// **'Proposed:'**
  String get proposedLabel;

  /// No description provided for @roleServiceProvider.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get roleServiceProvider;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @roleSupportAdmin.
  ///
  /// In en, this message translates to:
  /// **'Support Admin'**
  String get roleSupportAdmin;

  /// No description provided for @roleOperationsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Operations Admin'**
  String get roleOperationsAdmin;

  /// No description provided for @generalDispute.
  ///
  /// In en, this message translates to:
  /// **'General Dispute'**
  String get generalDispute;

  /// No description provided for @nicApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your NIC identity has been approved by admin. You can receive all job bids.'**
  String get nicApprovedMessage;

  /// No description provided for @nicUnderReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification submission is being reviewed by HelaService administration.'**
  String get nicUnderReviewMessage;

  /// No description provided for @amountLkrLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: LKR {amount}'**
  String amountLkrLabel(Object amount);

  /// No description provided for @searchCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Search category...'**
  String get searchCategoryHint;

  /// No description provided for @searchDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'Search district...'**
  String get searchDistrictHint;

  /// No description provided for @visitFeeOnlyDescription.
  ///
  /// In en, this message translates to:
  /// **'Charge visit / inspection fee only. Job will be completed without full service.'**
  String get visitFeeOnlyDescription;

  /// No description provided for @providerVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Provider Verification Pending'**
  String get providerVerificationPending;

  /// No description provided for @sendQuoteLkr.
  ///
  /// In en, this message translates to:
  /// **'Send Quote · LKR {amount}'**
  String sendQuoteLkr(Object amount);

  /// No description provided for @customQuote.
  ///
  /// In en, this message translates to:
  /// **'Custom Quote'**
  String get customQuote;

  /// No description provided for @pastService.
  ///
  /// In en, this message translates to:
  /// **'Past service'**
  String get pastService;

  /// No description provided for @youEnRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'You (En Route)'**
  String get youEnRouteLabel;

  /// No description provided for @hintJobAddress.
  ///
  /// In en, this message translates to:
  /// **'House no., street, town'**
  String get hintJobAddress;

  /// No description provided for @hintCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get hintCategoryName;

  /// No description provided for @hintAmountLkr.
  ///
  /// In en, this message translates to:
  /// **'Amount in LKR'**
  String get hintAmountLkr;

  /// Provider suspended reason in complaint investigation dialog
  ///
  /// In en, this message translates to:
  /// **'Suspended following complaint investigation: \"{reason}\"'**
  String complaintInvestigationSuspended(String reason);

  /// No description provided for @adminSuspensionViolations.
  ///
  /// In en, this message translates to:
  /// **'Administrative suspension due to policy violations'**
  String get adminSuspensionViolations;

  /// Admin log category created
  ///
  /// In en, this message translates to:
  /// **'Created category {name} with sort order {order}'**
  String categoryCreatedWithSortOrder(String name, int order);

  /// Admin log category updated
  ///
  /// In en, this message translates to:
  /// **'Updated category {name} (sort order: {order}, isLive: {status})'**
  String categoryUpdatedWithSortOrder(String name, int order, bool status);

  /// Admin log category deleted
  ///
  /// In en, this message translates to:
  /// **'Deleted category {name}'**
  String categoryDeletedName(String name);

  /// Default description for category
  ///
  /// In en, this message translates to:
  /// **'Certified domestic {service} services across Sri Lanka.'**
  String categoryDescriptionDefault(String service);

  /// No description provided for @zeroRegistered.
  ///
  /// In en, this message translates to:
  /// **'0 Registered'**
  String get zeroRegistered;

  /// No description provided for @zeroOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'0 Online Now'**
  String get zeroOnlineNow;

  /// No description provided for @marketRate.
  ///
  /// In en, this message translates to:
  /// **'Market Rate'**
  String get marketRate;

  /// Snack bar category updated successfully
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" updated successfully.'**
  String categoryUpdatedSuccess(String name);

  /// No description provided for @manualDispatchAssigned.
  ///
  /// In en, this message translates to:
  /// **'Manual Dispatch Assigned'**
  String get manualDispatchAssigned;

  /// No description provided for @dispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatchTitle;

  /// No description provided for @reassignTitle.
  ///
  /// In en, this message translates to:
  /// **'Re-assign'**
  String get reassignTitle;

  /// Event detail for manual dispatch assignment
  ///
  /// In en, this message translates to:
  /// **'{provider} dispatched to \"{job}\" ({address})'**
  String manualDispatchAssignedDesc(
      String provider, String job, String address);

  /// Ledger price status label
  ///
  /// In en, this message translates to:
  /// **'Price Status: {status}'**
  String ledgerPriceStatus(String status);

  /// Ledger proposed LKR label
  ///
  /// In en, this message translates to:
  /// **'Proposed: LKR {amount}'**
  String ledgerProposedLkr(String amount);

  /// No description provided for @ledgerCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get ledgerCustomer;

  /// No description provided for @verificationFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get verificationFlagged;

  /// No description provided for @verificationMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get verificationMatch;

  /// No description provided for @verificationValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get verificationValid;

  /// No description provided for @profileTrustPhotoRationale.
  ///
  /// In en, this message translates to:
  /// **'A clear photo builds trust with customers.'**
  String get profileTrustPhotoRationale;

  /// No description provided for @profileChooseGalleryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo from your gallery.'**
  String get profileChooseGalleryPhoto;

  /// No description provided for @captureNicFront.
  ///
  /// In en, this message translates to:
  /// **'Capture NIC Front'**
  String get captureNicFront;

  /// No description provided for @captureNicBack.
  ///
  /// In en, this message translates to:
  /// **'Capture NIC Back'**
  String get captureNicBack;

  /// No description provided for @captureNicPrompt.
  ///
  /// In en, this message translates to:
  /// **'Take a clear, well-lit photo of your National ID.'**
  String get captureNicPrompt;

  /// No description provided for @selectNicFront.
  ///
  /// In en, this message translates to:
  /// **'Select NIC Front'**
  String get selectNicFront;

  /// No description provided for @selectNicBack.
  ///
  /// In en, this message translates to:
  /// **'Select NIC Back'**
  String get selectNicBack;

  /// No description provided for @selectNicGalleryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select your National Identity Card photo from gallery.'**
  String get selectNicGalleryPrompt;

  /// No description provided for @completeProviderProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Provider Profile'**
  String get completeProviderProfileTitle;

  /// No description provided for @providingServicesAcrossSriLanka.
  ///
  /// In en, this message translates to:
  /// **'Providing services across Sri Lanka'**
  String get providingServicesAcrossSriLanka;

  /// No description provided for @requestingDomesticServices.
  ///
  /// In en, this message translates to:
  /// **'Requesting home & domestic services'**
  String get requestingDomesticServices;

  /// No description provided for @phonePlaceholderPattern.
  ///
  /// In en, this message translates to:
  /// **'7X XXXXXXX'**
  String get phonePlaceholderPattern;

  /// No description provided for @selectServiceCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Service Category'**
  String get selectServiceCategory;

  /// No description provided for @updatePinButton.
  ///
  /// In en, this message translates to:
  /// **'Update Pin'**
  String get updatePinButton;

  /// No description provided for @pickOnMapButton.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMapButton;

  /// No description provided for @workshopAddressRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Workshop / Operating Address *'**
  String get workshopAddressRequiredLabel;

  /// No description provided for @operatingAddressRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Operating address is required'**
  String get operatingAddressRequiredError;

  /// No description provided for @completeProviderRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Provider Registration'**
  String get completeProviderRegistration;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @phoneNotSet.
  ///
  /// In en, this message translates to:
  /// **'Phone not set'**
  String get phoneNotSet;

  /// No description provided for @addressLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// No description provided for @addressLabelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addressLabelWork;

  /// No description provided for @addressLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressLabelOther;

  /// No description provided for @videoExceedsMax120s.
  ///
  /// In en, this message translates to:
  /// **'Video exceeds maximum allowed 120s (2 minutes)'**
  String get videoExceedsMax120s;

  /// Error processing video upload
  ///
  /// In en, this message translates to:
  /// **'Failed to process video: {error}'**
  String failedToProcessVideo(String error);

  /// No description provided for @jobLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Location'**
  String get jobLocationLabel;

  /// No description provided for @selectJobLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick via GPS, map pin, or saved addresses'**
  String get selectJobLocationSubtitle;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// No description provided for @setPinButton.
  ///
  /// In en, this message translates to:
  /// **'Set Pin'**
  String get setPinButton;

  /// No description provided for @setPinHereButton.
  ///
  /// In en, this message translates to:
  /// **'Set Pin Here'**
  String get setPinHereButton;

  /// No description provided for @uploadFailedAttempts.
  ///
  /// In en, this message translates to:
  /// **'Upload failed after 3 attempts.'**
  String get uploadFailedAttempts;

  /// No description provided for @bookingPastService.
  ///
  /// In en, this message translates to:
  /// **'Past service'**
  String get bookingPastService;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get bookingNotSpecified;

  /// No description provided for @bookingStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get bookingStatusScheduled;

  /// Quantity with unit label
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String quantityUnitLabel(String unit);

  /// No description provided for @rateHourlyUnit.
  ///
  /// In en, this message translates to:
  /// **'LKR / hr'**
  String get rateHourlyUnit;

  /// No description provided for @rateDailyUnit.
  ///
  /// In en, this message translates to:
  /// **'LKR / day'**
  String get rateDailyUnit;

  /// No description provided for @rateTravelUnit.
  ///
  /// In en, this message translates to:
  /// **'LKR / km'**
  String get rateTravelUnit;

  /// No description provided for @pickerTabForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get pickerTabForm;

  /// No description provided for @pickerTabMapPin.
  ///
  /// In en, this message translates to:
  /// **'Map Pin'**
  String get pickerTabMapPin;

  /// No description provided for @cameraPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'Camera access is required to take your profile photo.'**
  String get cameraPermissionRationale;

  /// No description provided for @photoLibraryPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'Photo library access is required to select your profile photo.'**
  String get photoLibraryPermissionRationale;

  /// No description provided for @privacyDataCollectionPoints.
  ///
  /// In en, this message translates to:
  /// **'• Profile name, phone number, and account credentials\n• Job descriptions, addresses, and service locations\n• Verification documents (NIC, business licenses)\n• Messages and communications through the platform'**
  String get privacyDataCollectionPoints;

  /// No description provided for @timelineBookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking Created'**
  String get timelineBookingCreated;

  /// No description provided for @timelineBookingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Booking Accepted'**
  String get timelineBookingAccepted;

  /// No description provided for @timelineArrivalClaimed.
  ///
  /// In en, this message translates to:
  /// **'Arrival Claimed'**
  String get timelineArrivalClaimed;

  /// No description provided for @timelineArrivalDenied.
  ///
  /// In en, this message translates to:
  /// **'Arrival Denied'**
  String get timelineArrivalDenied;

  /// No description provided for @timelineAutoStarted.
  ///
  /// In en, this message translates to:
  /// **'Auto-Started'**
  String get timelineAutoStarted;

  /// No description provided for @timelineVisitFeeOnly.
  ///
  /// In en, this message translates to:
  /// **'Visit Fee Only'**
  String get timelineVisitFeeOnly;

  /// No description provided for @timelinePriceProposed.
  ///
  /// In en, this message translates to:
  /// **'Price Proposed'**
  String get timelinePriceProposed;

  /// No description provided for @timelinePriceApproved.
  ///
  /// In en, this message translates to:
  /// **'Price Approved'**
  String get timelinePriceApproved;

  /// No description provided for @timelinePriceRejected.
  ///
  /// In en, this message translates to:
  /// **'Price Rejected'**
  String get timelinePriceRejected;

  /// No description provided for @timelineExtraRequested.
  ///
  /// In en, this message translates to:
  /// **'Extra Requested'**
  String get timelineExtraRequested;

  /// No description provided for @timelineExtraApproved.
  ///
  /// In en, this message translates to:
  /// **'Extra Approved'**
  String get timelineExtraApproved;

  /// No description provided for @timelineExtraRejected.
  ///
  /// In en, this message translates to:
  /// **'Extra Rejected'**
  String get timelineExtraRejected;

  /// No description provided for @timelinePaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed'**
  String get timelinePaymentConfirmed;

  /// No description provided for @timelinePaymentDisputed.
  ///
  /// In en, this message translates to:
  /// **'Payment Disputed'**
  String get timelinePaymentDisputed;

  /// No description provided for @timelineNoShowReported.
  ///
  /// In en, this message translates to:
  /// **'No Show Reported'**
  String get timelineNoShowReported;

  /// No description provided for @timelineBeforePhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Before Photo Added'**
  String get timelineBeforePhotoAdded;

  /// No description provided for @timelineAfterPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'After Photo Added'**
  String get timelineAfterPhotoAdded;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open for Quotes'**
  String get statusOpen;

  /// No description provided for @statusDispatched.
  ///
  /// In en, this message translates to:
  /// **'Dispatched'**
  String get statusDispatched;

  /// No description provided for @selectJobLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Job Location'**
  String get selectJobLocation;

  /// No description provided for @tapToPickLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick via GPS, map pin, or saved addresses'**
  String get tapToPickLocationDesc;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set Pin'**
  String get setPin;

  /// No description provided for @rateCardSummary.
  ///
  /// In en, this message translates to:
  /// **'Visit Fee: LKR {visitFee} · Hourly: LKR {hourlyRate}'**
  String rateCardSummary(Object visitFee, Object hourlyRate);

  /// No description provided for @standardVisitFeeWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'Standard Visit Fee (LKR)'**
  String get standardVisitFeeWithCurrency;

  /// No description provided for @hourlyRateWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate (LKR / hr)'**
  String get hourlyRateWithUnit;

  /// No description provided for @dailyRateWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Daily Rate (LKR / day)'**
  String get dailyRateWithUnit;

  /// No description provided for @travelRateWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Travel Rate (LKR / km)'**
  String get travelRateWithUnit;

  /// No description provided for @priceMatchesQuoteAmount.
  ///
  /// In en, this message translates to:
  /// **'Does price match quote? (LKR {amount})'**
  String priceMatchesQuoteAmount(Object amount);

  /// No description provided for @quantityWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String quantityWithUnit(String unit);

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get unitHours;

  /// No description provided for @unitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get unitDays;

  /// No description provided for @unitJobs.
  ///
  /// In en, this message translates to:
  /// **'jobs'**
  String get unitJobs;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get languageSinhala;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get languageTamil;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location access is required to verify arrival at customer location.'**
  String get locationPermissionRequired;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @errorProviderCategoryMissing.
  ///
  /// In en, this message translates to:
  /// **'This service provider does not have an active service category.'**
  String get errorProviderCategoryMissing;

  /// No description provided for @permManageUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get permManageUsersLabel;

  /// No description provided for @permManageUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Ban or unban users and providers, and handle account security actions.'**
  String get permManageUsersDesc;

  /// No description provided for @permHandleSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Support & Tickets'**
  String get permHandleSupportLabel;

  /// No description provided for @permHandleSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Review and respond to customer and provider support tickets.'**
  String get permHandleSupportDesc;

  /// No description provided for @noPermissionForAction.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission for this.'**
  String get noPermissionForAction;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAProblem;

  /// No description provided for @ticketReplyPrompt.
  ///
  /// In en, this message translates to:
  /// **'We usually reply within 24 hours'**
  String get ticketReplyPrompt;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get ticketStatusInProgress;

  /// No description provided for @ticketStatusWaitingUser.
  ///
  /// In en, this message translates to:
  /// **'Waiting on You'**
  String get ticketStatusWaitingUser;

  /// No description provided for @ticketStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ticketStatusResolved;

  /// No description provided for @ticketStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticketStatusClosed;

  /// No description provided for @typeHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get typeHelp;

  /// No description provided for @typeReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get typeReportUser;

  /// No description provided for @typeBookingProblem.
  ///
  /// In en, this message translates to:
  /// **'Booking Problem'**
  String get typeBookingProblem;

  /// No description provided for @typePaymentDispute.
  ///
  /// In en, this message translates to:
  /// **'Payment Dispute'**
  String get typePaymentDispute;

  /// No description provided for @typeAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get typeAccount;

  /// No description provided for @typeAppProblem.
  ///
  /// In en, this message translates to:
  /// **'App Problem'**
  String get typeAppProblem;

  /// No description provided for @typeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Suggestions'**
  String get typeFeedback;

  /// No description provided for @ticketSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get ticketSubject;

  /// No description provided for @ticketDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ticketDescription;

  /// No description provided for @ticketSend.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get ticketSend;

  /// No description provided for @ticketAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach Photo'**
  String get ticketAttachPhoto;

  /// No description provided for @ticketReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get ticketReplyHint;

  /// No description provided for @ticketCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close Ticket'**
  String get ticketCloseConfirm;

  /// No description provided for @ticketResolvedNote.
  ///
  /// In en, this message translates to:
  /// **'Resolution Note'**
  String get ticketResolvedNote;

  /// No description provided for @ticketAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to me'**
  String get ticketAssignToMe;

  /// No description provided for @warnUser.
  ///
  /// In en, this message translates to:
  /// **'Warn User'**
  String get warnUser;

  /// No description provided for @banUser.
  ///
  /// In en, this message translates to:
  /// **'Ban User'**
  String get banUser;

  /// No description provided for @supportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support Phone'**
  String get supportPhone;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get supportEmail;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get callSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @noTicketsYet.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get noTicketsYet;

  /// No description provided for @ticketCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Support ticket created successfully'**
  String get ticketCreatedSuccess;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get assistance, FAQs, or submit a ticket'**
  String get helpSupportSubtitle;

  /// No description provided for @reportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblemTitle;

  /// No description provided for @exactCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my exact current location'**
  String get exactCurrentLocation;

  /// No description provided for @locationAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: ±{meters} m'**
  String locationAccuracy(int meters);

  /// No description provided for @locationAccuracyLowWarning.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy is low (±{meters} m). Please drag the map pin to your exact gate or house.'**
  String locationAccuracyLowWarning(int meters);

  /// No description provided for @fineTunePinInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag pin to your exact gate or house'**
  String get fineTunePinInstruction;

  /// No description provided for @houseAptNo.
  ///
  /// In en, this message translates to:
  /// **'House / Apartment No.'**
  String get houseAptNo;

  /// No description provided for @streetName.
  ///
  /// In en, this message translates to:
  /// **'Street / Road'**
  String get streetName;

  /// No description provided for @townCity.
  ///
  /// In en, this message translates to:
  /// **'Town / City'**
  String get townCity;

  /// No description provided for @landmarkOptional.
  ///
  /// In en, this message translates to:
  /// **'Landmark (e.g. near the blue gate)'**
  String get landmarkOptional;

  /// No description provided for @directionsForProvider.
  ///
  /// In en, this message translates to:
  /// **'Directions for provider'**
  String get directionsForProvider;

  /// No description provided for @saveThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Save this address'**
  String get saveThisAddress;

  /// No description provided for @locationRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Please choose a service location on the map before posting.'**
  String get locationRequiredHint;

  /// No description provided for @scheduleModeAsap.
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get scheduleModeAsap;

  /// No description provided for @scheduleModeDateOnly.
  ///
  /// In en, this message translates to:
  /// **'Pick a date only'**
  String get scheduleModeDateOnly;

  /// No description provided for @scheduleModeTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Pick a date & my own time range'**
  String get scheduleModeTimeRange;

  /// No description provided for @scheduleAnyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time that day'**
  String get scheduleAnyTime;

  /// No description provided for @scheduleFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get scheduleFrom;

  /// No description provided for @scheduleTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get scheduleTo;

  /// No description provided for @scheduleMinDurationError.
  ///
  /// In en, this message translates to:
  /// **'Time range must be at least 1 hour.'**
  String get scheduleMinDurationError;

  /// No description provided for @scheduleMaxDurationError.
  ///
  /// In en, this message translates to:
  /// **'Time range cannot exceed 12 hours.'**
  String get scheduleMaxDurationError;

  /// No description provided for @scheduleSameDayError.
  ///
  /// In en, this message translates to:
  /// **'Time range must be on the same day.'**
  String get scheduleSameDayError;

  /// No description provided for @schedulePastError.
  ///
  /// In en, this message translates to:
  /// **'Start time cannot be in the past.'**
  String get schedulePastError;

  /// No description provided for @scheduleTodayPastCutoff.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 hour remains before 20:00 today. Please select another date.'**
  String get scheduleTodayPastCutoff;

  /// No description provided for @outsideWorkingHoursWarning.
  ///
  /// In en, this message translates to:
  /// **'Outside your working hours'**
  String get outsideWorkingHoursWarning;

  /// No description provided for @admin2faTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Verification'**
  String get admin2faTitle;

  /// No description provided for @admin2faSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your admin email to authenticate your session.'**
  String get admin2faSubtitle;

  /// No description provided for @useDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get useDifferentAccount;

  /// No description provided for @continueAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Continue as Customer'**
  String get continueAsCustomer;

  /// No description provided for @otpNoSession.
  ///
  /// In en, this message translates to:
  /// **'No code sent yet — tap Resend'**
  String get otpNoSession;

  /// No description provided for @otpExpiredResend.
  ///
  /// In en, this message translates to:
  /// **'Code expired — tap Resend'**
  String get otpExpiredResend;

  /// No description provided for @otpMaxAttemptsResend.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tries — tap Resend'**
  String get otpMaxAttemptsResend;

  /// No description provided for @otpIncorrectTriesLeft.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. {count} tries left'**
  String otpIncorrectTriesLeft(int count);

  /// No description provided for @codeAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Code already sent'**
  String get codeAlreadySent;

  /// No description provided for @ticketSubmitPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your request. Please sign in again and try once more.'**
  String get ticketSubmitPermissionDenied;

  /// No description provided for @ticketSubmitErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your request. Please try again.'**
  String get ticketSubmitErrorGeneral;

  /// No description provided for @ticketCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get ticketCategory;

  /// No description provided for @pleaseFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillRequiredFields;

  /// No description provided for @ticketPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo. Try again or send without a photo.'**
  String get ticketPhotoUploadFailed;

  /// No description provided for @videoUploadMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Video upload works in the mobile app'**
  String get videoUploadMobileOnly;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and data'**
  String get deleteAccountSubtitle;

  /// No description provided for @movePinToGateHint.
  ///
  /// In en, this message translates to:
  /// **'Move the pin to your gate'**
  String get movePinToGateHint;

  /// No description provided for @notHereChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Not here? Choose another place'**
  String get notHereChooseAnother;

  /// No description provided for @couldNotGetLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location — choose a place or search the map'**
  String get couldNotGetLocationFallback;

  /// No description provided for @tryGpsAgain.
  ///
  /// In en, this message translates to:
  /// **'Try GPS again'**
  String get tryGpsAgain;

  /// No description provided for @addDetailsForProvider.
  ///
  /// In en, this message translates to:
  /// **'Add details for the provider'**
  String get addDetailsForProvider;

  /// No description provided for @providerNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for provider'**
  String get providerNoteLabel;

  /// No description provided for @providerNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. blue gate, white Toyota near the bus stop'**
  String get providerNoteHint;

  /// No description provided for @saveThisPlace.
  ///
  /// In en, this message translates to:
  /// **'Save this place'**
  String get saveThisPlace;

  /// No description provided for @searchOnMap.
  ///
  /// In en, this message translates to:
  /// **'Search on map'**
  String get searchOnMap;

  /// No description provided for @searchPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Search road, area or town...'**
  String get searchPlaceHint;

  /// No description provided for @accuracyBadge.
  ///
  /// In en, this message translates to:
  /// **'±{meters} m'**
  String accuracyBadge(int meters);

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @mediaUploadFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo/video — Retry'**
  String get mediaUploadFailedRetry;

  /// No description provided for @jobPostPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post your job. Please sign in again and try once more.'**
  String get jobPostPermissionDenied;

  /// No description provided for @jobPostErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post your job. Please try again.'**
  String get jobPostErrorGeneral;

  /// No description provided for @emergencyRateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This provider does not have an emergency rate set.'**
  String get emergencyRateUnavailable;

  /// No description provided for @nicUploadErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t upload your NIC right now. Please try again later.'**
  String get nicUploadErrorRetry;

  /// No description provided for @emailOtpRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first.'**
  String get emailOtpRequiredError;

  /// No description provided for @profileCompletionError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete your profile. Please try again.'**
  String get profileCompletionError;

  /// No description provided for @invalidNicFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid NIC format. Use 9 digits with V/X or 12 digits.'**
  String get invalidNicFormatError;

  /// No description provided for @providerPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Under Review'**
  String get providerPendingTitle;

  /// No description provided for @providerPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing your provider registration and NIC documents. You\'ll be notified once approved.'**
  String get providerPendingSubtitle;

  /// No description provided for @providerRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Needs Attention'**
  String get providerRejectedTitle;

  /// No description provided for @providerRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your provider application was not approved. Please review the reason below and submit updated details.'**
  String get providerRejectedSubtitle;

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get rejectionReasonLabel;

  /// No description provided for @submittedDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Submitted Details'**
  String get submittedDetailsTitle;

  /// No description provided for @submittedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted Date'**
  String get submittedDateLabel;

  /// No description provided for @serviceCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Category'**
  String get serviceCategoryLabel;

  /// No description provided for @applicantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Applicant Name'**
  String get applicantNameLabel;

  /// No description provided for @fixAndResubmit.
  ///
  /// In en, this message translates to:
  /// **'Fix & Resubmit'**
  String get fixAndResubmit;

  /// No description provided for @providerPendingCustomerToast.
  ///
  /// In en, this message translates to:
  /// **'Your provider application is under review. You can continue using customer features in the meantime.'**
  String get providerPendingCustomerToast;

  /// No description provided for @providerApprovedCelebration.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your provider account is now approved and active.'**
  String get providerApprovedCelebration;

  /// No description provided for @providerApplicationStatusBadge.
  ///
  /// In en, this message translates to:
  /// **'Provider Application'**
  String get providerApplicationStatusBadge;

  /// No description provided for @providerApplicationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get providerApplicationUnderReview;

  /// No description provided for @providerApplicationActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Action Needed'**
  String get providerApplicationActionNeeded;

  /// No description provided for @providerResubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Resubmission Requested'**
  String get providerResubmitTitle;

  /// No description provided for @providerResubmitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your application needs an updated document or clearer photo. Please review the note below and resubmit.'**
  String get providerResubmitSubtitle;

  /// No description provided for @autoChecksTitle.
  ///
  /// In en, this message translates to:
  /// **'Automated Security & Validity Checks'**
  String get autoChecksTitle;

  /// No description provided for @nicFormatValid.
  ///
  /// In en, this message translates to:
  /// **'NIC Format Valid'**
  String get nicFormatValid;

  /// No description provided for @nicFormatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid NIC Format'**
  String get nicFormatInvalid;

  /// No description provided for @nicDecodedBirthAndGender.
  ///
  /// In en, this message translates to:
  /// **'Decoded Details'**
  String get nicDecodedBirthAndGender;

  /// No description provided for @ageCheckValid.
  ///
  /// In en, this message translates to:
  /// **'Age 18+ (Eligible)'**
  String get ageCheckValid;

  /// No description provided for @ageCheckUnder18.
  ///
  /// In en, this message translates to:
  /// **'Under 18 Warning'**
  String get ageCheckUnder18;

  /// No description provided for @duplicateNicDetected.
  ///
  /// In en, this message translates to:
  /// **'Duplicate NIC Detected'**
  String get duplicateNicDetected;

  /// No description provided for @duplicatePhoneDetected.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Phone Detected'**
  String get duplicatePhoneDetected;

  /// No description provided for @noDuplicatesFound.
  ///
  /// In en, this message translates to:
  /// **'No duplicate NIC or phone detected'**
  String get noDuplicatesFound;

  /// No description provided for @duplicateWarningBanner.
  ///
  /// In en, this message translates to:
  /// **'Warning: duplicate account detected'**
  String get duplicateWarningBanner;

  /// No description provided for @approvalChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-Approval Verification Checklist'**
  String get approvalChecklistTitle;

  /// No description provided for @chkPhotoClear.
  ///
  /// In en, this message translates to:
  /// **'NIC photos are clear, legible, and uncropped'**
  String get chkPhotoClear;

  /// No description provided for @chkNameMatches.
  ///
  /// In en, this message translates to:
  /// **'Applicant name matches identity card exactly'**
  String get chkNameMatches;

  /// No description provided for @chkNicMatches.
  ///
  /// In en, this message translates to:
  /// **'NIC number matches identity card exactly'**
  String get chkNicMatches;

  /// No description provided for @chkFaceMatches.
  ///
  /// In en, this message translates to:
  /// **'Profile photo face matches NIC photo'**
  String get chkFaceMatches;

  /// No description provided for @chkCardNotEdited.
  ///
  /// In en, this message translates to:
  /// **'Identity card has no signs of digital editing or tampering'**
  String get chkCardNotEdited;

  /// No description provided for @allChecksRequired.
  ///
  /// In en, this message translates to:
  /// **'All 5 checks required to activate provider'**
  String get allChecksRequired;

  /// No description provided for @requestResubmission.
  ///
  /// In en, this message translates to:
  /// **'Request Resubmission'**
  String get requestResubmission;

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject Application'**
  String get rejectApplication;

  /// No description provided for @rejectionReasonDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Provide Review Decision'**
  String get rejectionReasonDialogTitle;

  /// No description provided for @selectPresetReason.
  ///
  /// In en, this message translates to:
  /// **'Select Reason'**
  String get selectPresetReason;

  /// No description provided for @reasonBlurryPhoto.
  ///
  /// In en, this message translates to:
  /// **'Blurry or unreadable photo'**
  String get reasonBlurryPhoto;

  /// No description provided for @reasonNameMismatch.
  ///
  /// In en, this message translates to:
  /// **'Name does not match identity card'**
  String get reasonNameMismatch;

  /// No description provided for @reasonNicMismatch.
  ///
  /// In en, this message translates to:
  /// **'NIC number does not match card'**
  String get reasonNicMismatch;

  /// No description provided for @reasonWrongSide.
  ///
  /// In en, this message translates to:
  /// **'Wrong side or missing back side'**
  String get reasonWrongSide;

  /// No description provided for @reasonFaceMismatch.
  ///
  /// In en, this message translates to:
  /// **'Profile photo does not match NIC face'**
  String get reasonFaceMismatch;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get reasonOther;

  /// No description provided for @optionalReviewerNote.
  ///
  /// In en, this message translates to:
  /// **'Additional instructions (optional, max 300 chars)'**
  String get optionalReviewerNote;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterResubmitted.
  ///
  /// In en, this message translates to:
  /// **'Resubmitted'**
  String get filterResubmitted;

  /// No description provided for @filterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get filterRejected;

  /// No description provided for @filterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterApproved;

  /// No description provided for @faceComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Face Comparison'**
  String get faceComparisonTitle;

  /// No description provided for @profilePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhotoLabel;

  /// No description provided for @nicFrontLabel.
  ///
  /// In en, this message translates to:
  /// **'NIC Front'**
  String get nicFrontLabel;

  /// No description provided for @nicBackLabel.
  ///
  /// In en, this message translates to:
  /// **'NIC Back'**
  String get nicBackLabel;

  /// No description provided for @rotatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90°'**
  String get rotatePhoto;

  /// No description provided for @zoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch or double tap to zoom'**
  String get zoomHint;

  /// No description provided for @auditHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Review & Submission History'**
  String get auditHistoryTitle;

  /// No description provided for @submissionAttempt.
  ///
  /// In en, this message translates to:
  /// **'Submission #{number}'**
  String submissionAttempt(String number);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noSearchResults;

  /// No description provided for @searchUnavailableFallback.
  ///
  /// In en, this message translates to:
  /// **'Search not available, move the map instead'**
  String get searchUnavailableFallback;

  /// No description provided for @recentPlaces.
  ///
  /// In en, this message translates to:
  /// **'Recent places'**
  String get recentPlaces;

  /// No description provided for @useMyCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyCurrentLocation;

  /// No description provided for @showingJobsNearYouNow.
  ///
  /// In en, this message translates to:
  /// **'Showing jobs near you now'**
  String get showingJobsNearYouNow;

  /// No description provided for @showingJobsNearBase.
  ///
  /// In en, this message translates to:
  /// **'Showing jobs near your base ({area})'**
  String showingJobsNearBase(String area);

  /// Notice showing jobs near provider base when area name is not known
  ///
  /// In en, this message translates to:
  /// **'Showing jobs near your base'**
  String get showingJobsNearBaseNoArea;

  /// No description provided for @setBaseLocationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Set your base location to see nearby jobs'**
  String get setBaseLocationPrompt;

  /// No description provided for @setBaseLocationBtn.
  ///
  /// In en, this message translates to:
  /// **'Set Base Location'**
  String get setBaseLocationBtn;

  /// No description provided for @awayNow.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away now'**
  String awayNow(String distance);

  /// No description provided for @basedAway.
  ///
  /// In en, this message translates to:
  /// **'Based {distance} km away'**
  String basedAway(String distance);

  /// No description provided for @locationLastUpdatedMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'Location last updated {minutes} min ago'**
  String locationLastUpdatedMinsAgo(String minutes);

  /// No description provided for @estimatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimatedLabel;

  /// No description provided for @baseLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Base Location'**
  String get baseLocationTitle;

  /// No description provided for @baseLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Where you normally start your workday'**
  String get baseLocationDesc;

  /// No description provided for @howDoYouChargeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your usual rates'**
  String get howDoYouChargeTitle;

  /// No description provided for @howDoYouChargeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customers see these on your profile. You can still choose a different price type for each job when you send a bid.'**
  String get howDoYouChargeSubtitle;

  /// No description provided for @pricingModePerHour.
  ///
  /// In en, this message translates to:
  /// **'Per hour'**
  String get pricingModePerHour;

  /// No description provided for @pricingModePerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get pricingModePerDay;

  /// No description provided for @pricingModePricePerJob.
  ///
  /// In en, this message translates to:
  /// **'Price per job (quote each job)'**
  String get pricingModePricePerJob;

  /// No description provided for @pricingModeVisitFee.
  ///
  /// In en, this message translates to:
  /// **'Visit / inspection fee'**
  String get pricingModeVisitFee;

  /// No description provided for @pricingModeTravelPerKm.
  ///
  /// In en, this message translates to:
  /// **'Travel charge per km'**
  String get pricingModeTravelPerKm;

  /// No description provided for @atLeastOneBasePricingModeRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one: Per hour, Per day, or Price per job.'**
  String get atLeastOneBasePricingModeRequired;

  /// No description provided for @travelIncluded.
  ///
  /// In en, this message translates to:
  /// **'Travel included'**
  String get travelIncluded;

  /// No description provided for @quoteEachJob.
  ///
  /// In en, this message translates to:
  /// **'Quoted per job'**
  String get quoteEachJob;

  /// No description provided for @travelTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelTitle;

  /// No description provided for @couldNotLoadExactLocationRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load exact job location. Please try again.'**
  String get couldNotLoadExactLocationRetry;

  /// No description provided for @gettingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get gettingYourLocation;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @customerLocationMissingCallCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer location missing, call the customer'**
  String get customerLocationMissingCallCustomer;

  /// No description provided for @locationSharingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'HelaService'**
  String get locationSharingNotificationTitle;

  /// No description provided for @locationSharingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Sharing your location with the customer'**
  String get locationSharingNotificationText;

  /// No description provided for @preparingMedia.
  ///
  /// In en, this message translates to:
  /// **'Preparing media...'**
  String get preparingMedia;

  /// No description provided for @uploadingPhotoProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo {current} of {total}...'**
  String uploadingPhotoProgress(int current, int total);

  /// No description provided for @uploadPhotoBytesProgress.
  ///
  /// In en, this message translates to:
  /// **'Photo {current}/{total}: {sentMb} MB / {totalMb} MB'**
  String uploadPhotoBytesProgress(
      int current, int total, String sentMb, String totalMb);

  /// No description provided for @uploadingVideoThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Uploading video thumbnail...'**
  String get uploadingVideoThumbnail;

  /// No description provided for @uploadingVideoFile.
  ///
  /// In en, this message translates to:
  /// **'Uploading video file...'**
  String get uploadingVideoFile;

  /// No description provided for @uploadVideoBytesProgress.
  ///
  /// In en, this message translates to:
  /// **'Video: {sentMb} MB / {totalMb} MB'**
  String uploadVideoBytesProgress(String sentMb, String totalMb);

  /// No description provided for @ticketAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Ticket assigned to you'**
  String get ticketAssignedToYou;

  /// No description provided for @openBookingTimeline.
  ///
  /// In en, this message translates to:
  /// **'Open Booking Timeline ({id})'**
  String openBookingTimeline(String id);

  /// No description provided for @markInReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Mark In Review'**
  String get markInReviewAction;

  /// No description provided for @resolveAction.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolveAction;

  /// No description provided for @dismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissAction;

  /// No description provided for @messageHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Message History'**
  String get messageHistoryTitle;

  /// No description provided for @noRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies in thread yet.'**
  String get noRepliesYet;

  /// No description provided for @replyAsSupportAdminHint.
  ///
  /// In en, this message translates to:
  /// **'Reply as Support Admin...'**
  String get replyAsSupportAdminHint;

  /// No description provided for @nicWarningUnder18.
  ///
  /// In en, this message translates to:
  /// **'Under 18 ({age} yrs) — Cannot be approved'**
  String nicWarningUnder18(int age);

  /// No description provided for @nicDuplicateCheckNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'duplicate check not available yet'**
  String get nicDuplicateCheckNotAvailable;

  /// No description provided for @nicDuplicateNicApproved.
  ///
  /// In en, this message translates to:
  /// **'Duplicate NIC: already approved for {name} ({id})'**
  String nicDuplicateNicApproved(String name, String id);

  /// No description provided for @nicDuplicateNicPending.
  ///
  /// In en, this message translates to:
  /// **'Duplicate NIC: pending for {name} ({id})'**
  String nicDuplicateNicPending(String name, String id);

  /// No description provided for @nicDuplicatePhone.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Phone: already registered to approved provider {name}'**
  String nicDuplicatePhone(String name);

  /// No description provided for @notificationIdentityApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification Approved'**
  String get notificationIdentityApprovedTitle;

  /// No description provided for @notificationIdentityApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your identity verification was approved. Your profile is now active.'**
  String get notificationIdentityApprovedBody;

  /// No description provided for @heroVerifiedArtisans.
  ///
  /// In en, this message translates to:
  /// **'Verified Service Artisans'**
  String get heroVerifiedArtisans;

  /// No description provided for @heroLiveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live tracking when your provider is on the way'**
  String get heroLiveTracking;

  /// No description provided for @heroTransparentQuotes.
  ///
  /// In en, this message translates to:
  /// **'Transparent Local Quotes'**
  String get heroTransparentQuotes;

  /// No description provided for @heroDirectQuoteRequests.
  ///
  /// In en, this message translates to:
  /// **'Direct quote requests in minutes'**
  String get heroDirectQuoteRequests;

  /// No description provided for @heroPrivateSecureChat.
  ///
  /// In en, this message translates to:
  /// **'Private, secure chat'**
  String get heroPrivateSecureChat;

  /// No description provided for @heroCommunityRated.
  ///
  /// In en, this message translates to:
  /// **'Community rated professionals'**
  String get heroCommunityRated;

  /// No description provided for @supportTicketCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close this ticket?'**
  String get supportTicketCloseConfirm;

  /// No description provided for @ticketClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Ticket closed.'**
  String get ticketClosedMessage;

  /// No description provided for @ticketNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ticket not found'**
  String get ticketNotFound;

  /// No description provided for @bookingTimelineWithId.
  ///
  /// In en, this message translates to:
  /// **'Booking Timeline ({id})'**
  String bookingTimelineWithId(String id);

  /// No description provided for @viewTicketAndThread.
  ///
  /// In en, this message translates to:
  /// **'View Ticket & Thread'**
  String get viewTicketAndThread;

  /// No description provided for @refreshImages.
  ///
  /// In en, this message translates to:
  /// **'Refresh Images'**
  String get refreshImages;

  /// No description provided for @quantityRangeMinMax.
  ///
  /// In en, this message translates to:
  /// **'({min} to {max})'**
  String quantityRangeMinMax(String min, String max);

  /// No description provided for @timelineDescCreated.
  ///
  /// In en, this message translates to:
  /// **'Customer created booking request'**
  String get timelineDescCreated;

  /// No description provided for @timelineDescAccepted.
  ///
  /// In en, this message translates to:
  /// **'Provider accepted the booking'**
  String get timelineDescAccepted;

  /// No description provided for @timelineDescDeclined.
  ///
  /// In en, this message translates to:
  /// **'Provider declined the booking'**
  String get timelineDescDeclined;

  /// No description provided for @timelineDescCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking was cancelled'**
  String get timelineDescCancelled;

  /// No description provided for @timelineDescEnRoute.
  ///
  /// In en, this message translates to:
  /// **'Provider started journey to location'**
  String get timelineDescEnRoute;

  /// No description provided for @timelineDescArrived.
  ///
  /// In en, this message translates to:
  /// **'Provider arrived at location'**
  String get timelineDescArrived;

  /// No description provided for @timelineDescArrivalClaimed.
  ///
  /// In en, this message translates to:
  /// **'Provider claimed arrival'**
  String get timelineDescArrivalClaimed;

  /// No description provided for @timelineDescArrivalConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Customer confirmed provider arrival'**
  String get timelineDescArrivalConfirmed;

  /// No description provided for @timelineDescArrivalDenied.
  ///
  /// In en, this message translates to:
  /// **'Customer reported provider has not arrived'**
  String get timelineDescArrivalDenied;

  /// No description provided for @timelineDescArrivalAutoStarted.
  ///
  /// In en, this message translates to:
  /// **'Started after customer timeout with verified GPS'**
  String get timelineDescArrivalAutoStarted;

  /// No description provided for @timelineDescCompleted.
  ///
  /// In en, this message translates to:
  /// **'Job completed'**
  String get timelineDescCompleted;

  /// No description provided for @timelineDescCompletedVisitOnly.
  ///
  /// In en, this message translates to:
  /// **'Completed with inspection/visit fee only'**
  String get timelineDescCompletedVisitOnly;

  /// No description provided for @timelineDescPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Customer confirmed payment'**
  String get timelineDescPaymentConfirmed;

  /// No description provided for @timelineDescPaymentDisputed.
  ///
  /// In en, this message translates to:
  /// **'Payment disputed'**
  String get timelineDescPaymentDisputed;

  /// No description provided for @timelineDescPriceProposed.
  ///
  /// In en, this message translates to:
  /// **'Provider proposed revised price'**
  String get timelineDescPriceProposed;

  /// No description provided for @timelineDescPriceApproved.
  ///
  /// In en, this message translates to:
  /// **'Customer approved revised price'**
  String get timelineDescPriceApproved;

  /// No description provided for @timelineDescPriceRejected.
  ///
  /// In en, this message translates to:
  /// **'Customer rejected revised price'**
  String get timelineDescPriceRejected;

  /// No description provided for @timelineDescPriceKept.
  ///
  /// In en, this message translates to:
  /// **'Provider confirmed initial quoted price'**
  String get timelineDescPriceKept;

  /// No description provided for @timelineDescExtraRequested.
  ///
  /// In en, this message translates to:
  /// **'Provider requested approval for extra work'**
  String get timelineDescExtraRequested;

  /// No description provided for @timelineDescExtraApproved.
  ///
  /// In en, this message translates to:
  /// **'Customer approved extra work'**
  String get timelineDescExtraApproved;

  /// No description provided for @timelineDescExtraRejected.
  ///
  /// In en, this message translates to:
  /// **'Customer rejected extra work'**
  String get timelineDescExtraRejected;

  /// No description provided for @timelineDescNoShowReported.
  ///
  /// In en, this message translates to:
  /// **'Customer reported provider no-show'**
  String get timelineDescNoShowReported;

  /// No description provided for @timelineDescBeforePhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Provider uploaded initial inspection photo'**
  String get timelineDescBeforePhotoAdded;

  /// No description provided for @timelineDescAfterPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Provider uploaded completed work photo'**
  String get timelineDescAfterPhotoAdded;

  /// No description provided for @timelineDescRescheduleRequested.
  ///
  /// In en, this message translates to:
  /// **'Reschedule requested'**
  String get timelineDescRescheduleRequested;

  /// No description provided for @timelineDescRescheduleAccepted.
  ///
  /// In en, this message translates to:
  /// **'Reschedule accepted'**
  String get timelineDescRescheduleAccepted;

  /// No description provided for @timelineDescRescheduleDeclined.
  ///
  /// In en, this message translates to:
  /// **'Reschedule declined'**
  String get timelineDescRescheduleDeclined;

  /// Friendly error message when setting user role fails
  ///
  /// In en, this message translates to:
  /// **'Failed to set role. Please try again.'**
  String get failedToSetRoleGeneric;

  /// Notice shown when a pending new provider tries to switch to customer mode
  ///
  /// In en, this message translates to:
  /// **'Customer mode is unavailable while your provider account is pending approval.'**
  String get roleSwitchLockedProviderBlocked;

  /// No description provided for @certUploadSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificates and documents (optional)'**
  String get certUploadSectionTitle;

  /// No description provided for @certUploadSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Add any certificates, licences or training letters. Photos or PDF.'**
  String get certUploadSectionHint;

  /// No description provided for @certUploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get certUploadButton;

  /// No description provided for @certUploadChooseFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get certUploadChooseFiles;

  /// No description provided for @certUploadMaxFilesError.
  ///
  /// In en, this message translates to:
  /// **'You can upload a maximum of 10 documents.'**
  String get certUploadMaxFilesError;

  /// No description provided for @certUploadFileTooLargeError.
  ///
  /// In en, this message translates to:
  /// **'{fileName} exceeds the 10 MB size limit.'**
  String certUploadFileTooLargeError(String fileName);

  /// No description provided for @certUploadUnsupportedTypeError.
  ///
  /// In en, this message translates to:
  /// **'{fileName} is not a supported file type. Allowed: JPG, PNG, WEBP, PDF.'**
  String certUploadUnsupportedTypeError(String fileName);

  /// No description provided for @certUploadTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Document title (e.g. NVQ Level 4)'**
  String get certUploadTitleHint;

  /// No description provided for @certDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certDefaultTitle;

  /// No description provided for @certCertifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get certCertifiedBadge;

  /// No description provided for @certApprovedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade Certifications & Licenses'**
  String get certApprovedSectionTitle;

  /// No description provided for @certAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add certificates'**
  String get certAddMore;

  /// No description provided for @certSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Certificates'**
  String get certSaveButton;

  /// No description provided for @certSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Certificates submitted for verification.'**
  String get certSubmittedSuccess;

  /// No description provided for @certTradeLicensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade Certifications & Licenses ({count})'**
  String certTradeLicensesTitle(int count);

  /// No description provided for @certNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate #{number}'**
  String certNumberTitle(int number);

  /// No description provided for @certApproveAll.
  ///
  /// In en, this message translates to:
  /// **'Approve all'**
  String get certApproveAll;

  /// No description provided for @certRejectReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Certificate'**
  String get certRejectReasonTitle;

  /// No description provided for @certRejectReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for rejecting this certificate'**
  String get certRejectReasonPrompt;

  /// No description provided for @certRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a rejection reason.'**
  String get certRejectReasonRequired;

  /// No description provided for @certApprovedNotice.
  ///
  /// In en, this message translates to:
  /// **'Certificate approved'**
  String get certApprovedNotice;

  /// No description provided for @certRejectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Certificate rejected'**
  String get certRejectedNotice;

  /// No description provided for @certAllApprovedNotice.
  ///
  /// In en, this message translates to:
  /// **'All certificates approved'**
  String get certAllApprovedNotice;

  /// No description provided for @quoteRateForJobHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your rate for this job'**
  String get quoteRateForJobHint;

  /// No description provided for @quoteInspectVisitFeePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter a visit fee for inspection'**
  String get quoteInspectVisitFeePrompt;

  /// No description provided for @quoteIncludeVisitCostHint.
  ///
  /// In en, this message translates to:
  /// **'Include any visit cost in your price.'**
  String get quoteIncludeVisitCostHint;

  /// No description provided for @quoteAddTravelCost.
  ///
  /// In en, this message translates to:
  /// **'Add travel cost'**
  String get quoteAddTravelCost;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Could not open map navigation application'**
  String get couldNotOpenMaps;

  /// No description provided for @locationSharingStopped.
  ///
  /// In en, this message translates to:
  /// **'Location sharing stopped'**
  String get locationSharingStopped;

  /// No description provided for @useCurrentLocationAction.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocationAction;

  /// No description provided for @searchPlaceAction.
  ///
  /// In en, this message translates to:
  /// **'Search a place'**
  String get searchPlaceAction;

  /// No description provided for @approximateLocationWarning.
  ///
  /// In en, this message translates to:
  /// **'Using approximate location from {minutes} min ago. Please verify pin on map.'**
  String approximateLocationWarning(String minutes);

  /// No description provided for @locationOutsideSriLanka.
  ///
  /// In en, this message translates to:
  /// **'Selected location is outside Sri Lanka. Please select a location within Sri Lanka.'**
  String get locationOutsideSriLanka;

  /// No description provided for @nearLabel.
  ///
  /// In en, this message translates to:
  /// **'Near'**
  String get nearLabel;

  /// No description provided for @setLocationToSeeNearby.
  ///
  /// In en, this message translates to:
  /// **'Set your location to see providers near you'**
  String get setLocationToSeeNearby;

  /// No description provided for @changeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAction;

  /// No description provided for @setAction.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get setAction;

  /// No description provided for @distanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceFilter;

  /// No description provided for @anyDistance.
  ///
  /// In en, this message translates to:
  /// **'Any distance'**
  String get anyDistance;

  /// No description provided for @onlyServesMyArea.
  ///
  /// In en, this message translates to:
  /// **'Only providers who serve my area'**
  String get onlyServesMyArea;

  /// No description provided for @sortByNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest first'**
  String get sortByNearest;

  /// No description provided for @sortByTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get sortByTopRated;

  /// No description provided for @showUpTo50Km.
  ///
  /// In en, this message translates to:
  /// **'Show up to 50 km'**
  String get showUpTo50Km;

  /// No description provided for @providersNearArea.
  ///
  /// In en, this message translates to:
  /// **'Providers near {area}'**
  String providersNearArea(String area);

  /// No description provided for @under1KmAway.
  ///
  /// In en, this message translates to:
  /// **'Under 1 km away'**
  String get under1KmAway;

  /// No description provided for @onlineNowBadge.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get onlineNowBadge;

  /// No description provided for @savedOfflineSyncLater.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will sync when you\'re back online.'**
  String get savedOfflineSyncLater;

  /// No description provided for @couldNotSaveCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Check your connection and try again.'**
  String get couldNotSaveCheckConnection;

  /// No description provided for @providerProfileNotSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Your provider profile is not set up yet. Complete your registration to manage these settings.'**
  String get providerProfileNotSetupDesc;

  /// No description provided for @completeRegistrationAction.
  ///
  /// In en, this message translates to:
  /// **'Complete Registration'**
  String get completeRegistrationAction;

  /// No description provided for @setYourUsualRates.
  ///
  /// In en, this message translates to:
  /// **'Set your usual rates'**
  String get setYourUsualRates;

  /// No description provided for @pricePerJobAmount.
  ///
  /// In en, this message translates to:
  /// **'Price per job LKR {amount}'**
  String pricePerJobAmount(String amount);

  /// No description provided for @ratePerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day LKR {amount}'**
  String ratePerDay(String amount);

  /// No description provided for @ratePerHour.
  ///
  /// In en, this message translates to:
  /// **'Per hour LKR {amount}'**
  String ratePerHour(String amount);

  /// No description provided for @rateVisitFee.
  ///
  /// In en, this message translates to:
  /// **'Visit LKR {amount}'**
  String rateVisitFee(String amount);

  /// No description provided for @ratePerKm.
  ///
  /// In en, this message translates to:
  /// **'LKR {amount}/km'**
  String ratePerKm(String amount);

  /// No description provided for @whenDoYouNeedThis.
  ///
  /// In en, this message translates to:
  /// **'When do you need this?'**
  String get whenDoYouNeedThis;

  /// No description provided for @scheduleModeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleModeToday;

  /// No description provided for @scheduleModeSpecificDay.
  ///
  /// In en, this message translates to:
  /// **'On a specific day'**
  String get scheduleModeSpecificDay;

  /// No description provided for @scheduleModeFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get scheduleModeFlexible;

  /// No description provided for @urgentHelpHint.
  ///
  /// In en, this message translates to:
  /// **'Emergency? Use Urgent help.'**
  String get urgentHelpHint;

  /// No description provided for @todayDisabledPast20.
  ///
  /// In en, this message translates to:
  /// **'After 20:00, please pick a specific day.'**
  String get todayDisabledPast20;

  /// No description provided for @slotAnytimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Anytime (08:00 - 20:00)'**
  String get slotAnytimeLabel;

  /// No description provided for @slotMorningShort.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get slotMorningShort;

  /// No description provided for @slotAfternoonShort.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get slotAfternoonShort;

  /// No description provided for @slotEveningShort.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get slotEveningShort;

  /// No description provided for @slotAnytimeShort.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get slotAnytimeShort;

  /// No description provided for @slotExactTime.
  ///
  /// In en, this message translates to:
  /// **'Exact time'**
  String get slotExactTime;

  /// No description provided for @flexibleWithin3Days.
  ///
  /// In en, this message translates to:
  /// **'Within 3 days'**
  String get flexibleWithin3Days;

  /// No description provided for @flexibleWithinWeek.
  ///
  /// In en, this message translates to:
  /// **'Within a week'**
  String get flexibleWithinWeek;

  /// No description provided for @flexibleWithin2Weeks.
  ///
  /// In en, this message translates to:
  /// **'Within 2 weeks'**
  String get flexibleWithin2Weeks;

  /// No description provided for @slotPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get slotPassed;

  /// No description provided for @cancelJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Job Request'**
  String get cancelJobTitle;

  /// No description provided for @cancelJobConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this job?'**
  String get cancelJobConfirmPrompt;

  /// No description provided for @cancelReasonFoundSomeone.
  ///
  /// In en, this message translates to:
  /// **'Found someone else'**
  String get cancelReasonFoundSomeone;

  /// No description provided for @cancelReasonNoLongerNeeded.
  ///
  /// In en, this message translates to:
  /// **'No longer needed'**
  String get cancelReasonNoLongerNeeded;

  /// No description provided for @cancelReasonTooExpensive.
  ///
  /// In en, this message translates to:
  /// **'Too expensive'**
  String get cancelReasonTooExpensive;

  /// No description provided for @withdrawBid.
  ///
  /// In en, this message translates to:
  /// **'Withdraw bid'**
  String get withdrawBid;

  /// No description provided for @withdrawBidConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw your bid?'**
  String get withdrawBidConfirmPrompt;

  /// No description provided for @bidWithdrawnSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bid withdrawn'**
  String get bidWithdrawnSuccess;

  /// No description provided for @quoteNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This quote is no longer available.'**
  String get quoteNoLongerAvailable;

  /// No description provided for @providerWithdrewQuoteNotice.
  ///
  /// In en, this message translates to:
  /// **'A provider withdrew their quote'**
  String get providerWithdrewQuoteNotice;

  /// No description provided for @clashWarningBidding.
  ///
  /// In en, this message translates to:
  /// **'You already have a job at this time.'**
  String get clashWarningBidding;

  /// No description provided for @clashWarningPostWin.
  ///
  /// In en, this message translates to:
  /// **'You have {count} other bids at this time. Withdraw them?'**
  String clashWarningPostWin(int count);

  /// No description provided for @reviewBidsButton.
  ///
  /// In en, this message translates to:
  /// **'Review Bids'**
  String get reviewBidsButton;

  /// No description provided for @coverageWarningCount.
  ///
  /// In en, this message translates to:
  /// **'{count} providers serve this area'**
  String coverageWarningCount(int count);

  /// No description provided for @coverageWarningZero.
  ///
  /// In en, this message translates to:
  /// **'No providers in this category cover this area yet. You can still post.'**
  String get coverageWarningZero;

  /// No description provided for @myBidsActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myBidsActiveTab;

  /// No description provided for @myBidsPastTab.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get myBidsPastTab;

  /// No description provided for @bidStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bidStatusPending;

  /// No description provided for @bidStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get bidStatusAccepted;

  /// No description provided for @bidStatusNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected'**
  String get bidStatusNotSelected;

  /// No description provided for @bidStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get bidStatusWithdrawn;

  /// No description provided for @bidStatusJobClosed.
  ///
  /// In en, this message translates to:
  /// **'Job no longer available'**
  String get bidStatusJobClosed;

  /// No description provided for @whenCanYouCome.
  ///
  /// In en, this message translates to:
  /// **'When can you come?'**
  String get whenCanYouCome;

  /// No description provided for @selectDayInsideWindow.
  ///
  /// In en, this message translates to:
  /// **'Select a day within the customer\'s window'**
  String get selectDayInsideWindow;

  /// No description provided for @pendingJobPostBanner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection, your job will post automatically'**
  String get pendingJobPostBanner;

  /// No description provided for @jobNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Job request not found'**
  String get jobNotFoundTitle;

  /// No description provided for @jobPostFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your job could not be posted. Please try again.'**
  String get jobPostFailedTitle;

  /// No description provided for @jobLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load job details. Please check your connection.'**
  String get jobLoadErrorTitle;

  /// No description provided for @cancelUpload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Upload'**
  String get cancelUpload;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get backAction;
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
