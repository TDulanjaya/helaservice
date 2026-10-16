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

  /// HelaService
  String get appTitle;

  /// On-Demand Home & Emergency Services in Sri Lanka
  String get tagline;

  /// Language
  String get language;

  /// Select Language
  String get selectLanguage;

  /// Preferred Language
  String get preferredLanguage;

  /// Choose your primary language for the app
  String get chooseLanguageSubtitle;

  /// English
  String get english;

  /// සිංහල
  String get sinhala;

  /// தமிழ்
  String get tamil;

  /// Theme Mode
  String get theme;

  /// Light
  String get themeLight;

  /// Dark
  String get themeDark;

  /// System Default
  String get themeSystem;

  /// Change Theme
  String get changeTheme;

  /// Customer
  String get roleCustomer;

  /// Technician / Artisan
  String get roleProvider;

  /// Operations Admin
  String get roleAdmin;

  /// Switch Role
  String get switchRole;

  /// Home
  String get navHome;

  /// Explore
  String get navExplore;

  /// Bookings
  String get navBookings;

  /// Tracking
  String get navTracking;

  /// Post Job
  String get navPostJob;

  /// Profile
  String get navProfile;

  /// Leads
  String get navLeads;

  /// Ongoing
  String get navOngoing;

  /// Earnings
  String get navEarnings;

  /// Jobs Radar
  String get navJobsRadar;

  /// My Quotes
  String get navMyQuotes;

  /// Operations
  String get navOperations;

  /// Live Map
  String get navLiveMap;

  /// Verifications
  String get navVerifications;

  /// Verification
  String get navVerification;

  /// Overview
  String get navOverview;

  /// Verify
  String get navVerify;

  /// Coverage
  String get navCoverage;

  /// Team
  String get navTeam;

  /// Settings
  String get navSettings;

  /// Welcome to HelaService
  String get loginTitle;

  /// Find verified home service professionals or manage your service jobs across Sri Lanka.
  String get loginSubtitle;

  /// Email Address
  String get emailAddress;

  /// Password
  String get password;

  /// Confirm Password
  String get confirmPassword;

  /// Forgot Password?
  String get forgotPassword;

  /// Sign In
  String get signIn;

  /// Create Account
  String get createAccount;

  /// Sign up to get started with HelaService.
  String get createAccountSubtitle;

  /// Continue
  String get continueText;

  /// Already have an account?
  String get alreadyHaveAccount;

  /// Log In
  String get logIn;

  /// New to HelaService?
  String get newToHelaService;

  /// Reset Password
  String get resetPassword;

  /// Enter your account email and we will send a password reset link to your inbox.
  String get resetPasswordDesc;

  /// Send Reset Link
  String get sendResetLink;

  /// Please enter your email address
  String get enterEmailError;

  /// Please enter your password
  String get enterPasswordError;

  /// Password must be at least 6 characters long
  String get passwordLengthError;

  /// Passwords do not match
  String get passwordMismatchError;

  /// Phone Number
  String get phoneNumber;

  /// Send OTP Code
  String get sendOtp;

  /// Verify OTP Code
  String get verifyOtp;

  /// Enter 6-digit verification code
  String get enterOtp;

  /// Resend Code
  String get resendOtp;

  /// Continue with Google
  String get googleSignIn;

  /// Sign in with Google
  String get googleSignInExisting;

  /// No account found
  String get googleNoAccountTitle;

  /// There is no HelaService account for this Google email. Create one first.
  String get googleNoAccountMessage;

  /// Couldn\'t load your account. Check your internet connection and try again.
  String get splashNoConnection;

  /// Explore Services as Guest
  String get exploreAsGuest;

  /// or continue with
  String get orContinueWith;

  /// or sign up with email
  String get orSignUpWithEmail;

  /// We\'ll send a 6-digit OTP code to verify your phone number.
  String get smsNotice;

  /// Choose Role & Profile
  String get completeProfileTitle;

  /// Tell us a bit about yourself to get started
  String get completeProfileSubtitle;

  /// Select Account Type
  String get selectAccountType;

  /// Post jobs & hire local technicians
  String get customerRoleDesc;

  /// Bid on jobs & offer expert services
  String get providerRoleDesc;

  /// Full Name
  String get fullName;

  /// Full name (as on NIC)
  String get fullNameAsNic;

  /// Phone Number
  String get phoneLabel;

  /// Home / Dispatch Address
  String get address;

  /// District
  String get district;

  /// Primary Service District
  String get primaryDistrict;

  /// Service Category
  String get category;

  /// Primary Service Category
  String get primaryCategory;

  /// National Identity Card (NIC) number
  String get nicNumber;

  /// NIC Front Photo
  String get nicFront;

  /// NIC Back Photo
  String get nicBack;

  /// Auto-Detect Current GPS
  String get detectGps;

  /// Refresh GPS Location
  String get refreshGps;

  /// GPS Location Detected
  String get gpsDetected;

  /// Used for live dispatch & nearest artisan routing across Sri Lanka
  String get gpsHint;

  /// I agree to the HelaService Terms & Privacy Policy
  String get agreeTerms;

  /// Complete Registration & Continue
  String get completeRegistration;

  /// Account verified
  String get accountVerified;

  /// Post a Job Request
  String get postJobTitle;

  /// Connect with verified artisans near your home across Sri Lanka
  String get postJobSubtitle;

  /// Post Job & Get Quotes
  String get postJobGetQuotes;

  /// Describe your job or repair
  String get describeJobOrRepair;

  /// Add photos and your location. Nearby providers will send you price quotes.
  String get describeJobSubtitle;

  /// Select a trade category
  String get selectTradeCategory;

  /// Job Title
  String get jobTitle;

  /// e.g., Kitchen pipe leaking under sink
  String get jobTitleHint;

  /// Description
  String get jobDescription;

  /// Describe the problem or what needs to be done in detail...
  String get jobDescriptionHint;

  /// Estimated Budget (LKR)
  String get budget;

  /// e.g., 2500
  String get budgetHint;

  /// Job Location & GPS
  String get jobLocationGps;

  /// Photos of the Issue
  String get photosOfIssue;

  /// Job Photos & Proof of Work
  String get jobPhotos;

  /// Add
  String get add;

  /// Add Photo
  String get addPhoto;

  /// Take Photo
  String get takePhoto;

  /// Choose from Gallery
  String get chooseFromGallery;

  /// Maximum 4 photos allowed
  String get maxPhotosAllowed;

  /// Your Exact Location
  String get yourExactLocation;

  /// GPS Coordinates Locked
  String get gpsCoordinatesLocked;

  /// Detecting your exact location...
  String get detectingLocation;

  /// Tap to detect your exact GPS location
  String get tapToDetectGps;

  /// Street address or landmark (optional)
  String get streetAddressOptional;

  /// Post Job Request
  String get submitJobRequest;

  /// Job request posted successfully!
  String get jobPostedSuccess;

  /// You will receive quotes from nearby verified artisans shortly.
  String get quotesAlert;

  /// Please enter a job title
  String get enterJobTitleError;

  /// Please add a description
  String get addDescriptionError;

  /// Please select a service category
  String get selectCategoryError;

  /// Artisan Quotes & Bids
  String get quotesTitle;

  /// QUOTES RECEIVED
  String get quotesReceived;

  /// No quotes received yet. Artisans in your area are reviewing your request.
  String get noQuotes;

  /// Waiting for Quotes
  String get waitingForQuotes;

  /// Your job has been posted. Nearby service providers will send you their price quotes shortly.
  String get waitingForQuotesDesc;

  /// {providerName} Hired!
  String providerHired(String providerName);

  /// Back to Home
  String get backToHome;

  /// Accept Quote & Hire?
  String get acceptQuoteHire;

  /// Accept & Hire
  String get acceptHire;

  /// has been hired successfully!
  String get hiredSuccess;

  /// Send Quote / Estimate
  String get sendQuote;

  /// Quote Amount (LKR)
  String get quoteAmount;

  /// Estimated Time / Duration
  String get estimatedTime;

  /// e.g., 45 mins - 1 hour
  String get estimatedTimeHint;

  /// Notes to Customer (Optional)
  String get quoteNotes;

  /// Explain your approach, included materials, or warranty...
  String get quoteNotesHint;

  /// Submit Quote to Customer
  String get submitQuote;

  /// Submit Your Price Quote
  String get submitPriceQuote;

  /// Review the job details and send your quote to the customer.
  String get submitPriceQuoteSub;

  /// Customer Photos
  String get customerPhotos;

  /// Your Quoted Price (LKR)
  String get yourQuotedPrice;

  /// Estimated Arrival Time
  String get estimatedArrivalTime;

  /// Message to Customer (Optional)
  String get messageToCustomerOptional;

  /// Send Price Quote
  String get sendPriceQuote;

  /// Quote submitted successfully!
  String get quoteSubmittedSuccess;

  /// Accept Quote
  String get acceptQuote;

  /// Decline
  String get declineQuote;

  /// Please enter your quoted price
  String get enterQuotedPriceError;

  /// Please enter a valid price
  String get enterValidPriceError;

  /// Ayubowan
  String get greetingAyubowan;

  /// Find certified local artisans ready to help today.
  String get findCertifiedArtisans;

  /// Search plumbers, electricians, carpenters...
  String get searchHint;

  /// Search plumbing, AC repair, electricians...
  String get searchServiceHint;

  /// Have a Repair or Job?
  String get haveRepairOrJob;

  /// Post details & photos. Get price quotes from nearby providers.
  String get postDetailsBannerSub;

  /// Categories
  String get categories;

  /// View all
  String get viewAll;

  /// No categories available
  String get noCategoriesAvailable;

  /// Artisans on Duty
  String get artisansOnDuty;

  /// Active Nearby
  String get activeNearby;

  /// Instant Dispatch Radar Active
  String get radarActive;

  /// Average arrival time: 14 mins in Colombo 03
  String get avgArrivalTime;

  /// Top Rated Technicians
  String get topRatedTechnicians;

  /// Verified background checks & island-wide ratings
  String get verifiedChecksRatings;

  /// No technicians registered yet
  String get noTechniciansYet;

  /// Need Immediate Emergency Service?
  String get emergencyHelpTitle;

  /// 24/7 Priority Auto-Dispatch active in your area
  String get emergencyHelpSubtitle;

  /// Request 24/7 Dispatch
  String get requestEmergency;

  /// Popular Services
  String get topCategories;

  /// View All Services
  String get viewAllServices;

  /// Nearby Verified Artisans
  String get nearbyArtisans;

  /// All
  String get filterAll;

  /// reviews
  String get reviewsCount;

  /// Starting from
  String get startingFrom;

  /// View Profile & Hire
  String get viewDetails;

  /// HelaCare Guarantee
  String get helaCareGuarantee;

  /// All booked visits include complimentary property damage coverage up to LKR 100,000.
  String get helaCareDesc;

  /// Initial Inspection Rate
  String get initialInspectionRate;

  /// Quick Book
  String get quickBook;

  /// Service Detail
  String get serviceDetail;

  /// Transparent Pricing
  String get transparentPricing;

  /// Base Inspection & Visit Fee
  String get baseInspectionFee;

  /// Covers doorstep diagnosis & transit costs
  String get baseInspectionSub;

  /// Standard Hourly Labour
  String get standardHourlyLabour;

  /// Emergency / After-hours Rate
  String get emergencyRate;

  /// • Materials & replacement parts billed separately with store receipts.
  String get materialsBilledSeparately;

  /// About the Technician
  String get aboutTechnician;

  /// Recent Work Completed
  String get recentWorkCompleted;

  /// Customer Reviews
  String get customerReviews;

  /// Request Service
  String get requestService;

  /// Message
  String get message;

  /// Chat
  String get chat;

  /// Live Tracking
  String get liveTracking;

  /// No Active Dispatch
  String get noActiveDispatch;

  /// When you request a service, live GPS tracking appears here.
  String get noActiveDispatchSub;

  /// Technician on the way • Live GPS
  String get techOnTheWay;

  /// Estimated Arrival
  String get estimatedArrival;

  /// Arriving in
  String get arrivingIn;

  /// Direct Pay at Site (Cash)
  String get directPayCash;

  /// standard inspection fee. No hidden platform charges.
  String get inspectionFeeNotice;

  /// Cancel Request
  String get cancelRequest;

  /// Share Trip
  String get shareTrip;

  /// Job Finished · Rate & Pay
  String get jobFinishedRatePay;

  /// Call Tech
  String get callTech;

  /// Checkout Booking
  String get checkoutBooking;

  /// Service Completed!
  String get serviceCompleted;

  /// Cost Breakdown
  String get costBreakdown;

  /// PAID
  String get paid;

  /// Base diagnostic & visit
  String get baseDiagnosticVisit;

  /// Parts & labor
  String get partsAndLabor;

  /// Total Paid
  String get totalPaid;

  /// Settled directly (Cash on site)
  String get settledDirectlyCash;

  /// Rate your overall repair experience
  String get rateExperience;

  /// What went especially well?
  String get whatWentWell;

  /// Leave a detailed review (optional)
  String get leaveReviewOptional;

  /// Tip Provider — 100% goes to provider
  String get tipProvider;

  /// Done
  String get done;

  /// Need help with this order?
  String get needHelpOrder;

  /// Pending
  String get statusPending;

  /// Accepted
  String get statusAccepted;

  /// In Progress
  String get statusInProgress;

  /// Completed
  String get statusCompleted;

  /// Cancelled
  String get statusCancelled;

  /// NIC Verified
  String get verifiedArtisan;

  /// Active Fleet
  String get activeFleet;

  /// Available now
  String get availableNow;

  /// km away
  String get kmAway;

  /// Rating
  String get rating;

  /// Reviews
  String get reviews;

  /// My Bookings
  String get myBookings;

  /// Active
  String get activeBookings;

  /// Past History
  String get pastBookings;

  /// ACTIVE SERVICE VISIT
  String get activeServiceVisit;

  /// Past Completed Services
  String get pastCompletedServices;

  /// Open Live GPS Tracking
  String get openLiveGpsTracking;

  /// No job ledger records found
  String get noBookingsFound;

  /// No bookings recorded yet
  String get noBookingsRecorded;

  /// Browse certified artisans on the Explore tab.
  String get browseArtisansExplore;

  /// Book an Artisan
  String get bookTechnician;

  /// Call Artisan
  String get callArtisan;

  /// Track Location
  String get trackLocation;

  /// Rate & Review
  String get leaveReview;

  /// Job Completion & Rating
  String get rateJobTitle;

  /// How was your service experience with
  String get rateJobSubtitle;

  /// Share feedback on quality, punctuality, and craftsmanship...
  String get ratingFeedbackHint;

  /// Submit Review & Finish
  String get submitRating;

  /// Artisan Operations Hub
  String get providerDashboardTitle;

  /// Online & Accepting Leads
  String get statusOnline;

  /// Offline / Paused
  String get statusOffline;

  /// You are ONLINE
  String get youAreOnline;

  /// You are OFFLINE
  String get youAreOffline;

  /// Active Dispatch — Receiving job requests from nearby customers
  String get activeDispatchSub;

  /// Open Job Requests
  String get openJobRequests;

  /// From Customers
  String get fromCustomers;

  /// No open requests right now
  String get noOpenRequests;

  /// Customer requests in your trade category will appear here.
  String get customerRequestsAppearHere;

  /// Scheduled Bookings
  String get scheduledBookings;

  /// No active bookings right now
  String get noActiveBookings;

  /// Today\'s Earnings
  String get todayEarnings;

  /// Completed Jobs
  String get completedJobs;

  /// Active Job Leads
  String get activeLeads;

  /// No new job leads in your area right now. Keep your status online to receive alerts.
  String get noLeadsAvailable;

  /// No quotes submitted yet
  String get noQuotesYet;

  /// Browse the Jobs Radar and send price quotes to customers.
  String get browseRadarDesc;

  /// ACCEPTED
  String get acceptedCaps;

  /// PENDING RESPONSE
  String get pendingResponseCaps;

  /// DECLINED
  String get declinedCaps;

  /// Save Changes
  String get save;

  /// Cancel
  String get cancel;

  /// Confirm
  String get confirm;

  /// Log Out
  String get logout;

  /// Are you sure you want to log out from HelaService?
  String get logoutConfirm;

  /// Edit Profile
  String get editProfile;

  /// Contact Support
  String get contactSupport;

  /// Preferences & Settings
  String get appSettings;

  /// Edit Profile & Photo
  String get editProfileAndPhoto;

  /// Edit Contact Info
  String get editContactInfo;

  /// Profile Photo
  String get profilePhoto;

  /// Profile Photo (Required)
  String get profilePhotoRequired;

  /// Upload a clear face photo for your service provider profile.
  String get profilePhotoRequiredHint;

  /// Profile photo is required for Service Providers
  String get profilePhotoRequiredError;

  /// Add Photo
  String get addPhotoAction;

  /// Change Photo
  String get changePhotoAction;

  /// Dispatch & Contact Info
  String get dispatchAndContactInfo;

  /// Change
  String get change;

  /// Verified Customer
  String get verifiedCustomer;

  /// Payment Methods
  String get paymentMethods;

  /// Direct cash settlement at service site
  String get paymentMethodsSubtitle;

  /// 24/7 Island Customer Helpline
  String get islandCustomerHelpline;

  /// Hotline: 011 234 5678 (Toll Free)
  String get islandCustomerHelplineSubtitle;

  /// Appearance & Theme
  String get appearanceAndTheme;

  /// Choose Appearance
  String get chooseAppearance;

  /// Light Mode
  String get lightMode;

  /// Dark Mode
  String get darkMode;

  /// System Default
  String get systemDefault;

  /// Switch Operational View
  String get switchOperationalView;

  /// Profile updated successfully!
  String get profileUpdatedSuccess;

  /// Log Out
  String get logoutModalTitle;

  /// Are you sure you want to log out of HelaService?
  String get logoutModalConfirm;

  /// Profile Details
  String get profileDetails;

  /// Service Location
  String get serviceLocation;

  /// Select District
  String get selectDistrict;

  /// District
  String get districtLabel;

  /// Address / Area Details (Optional)
  String get addressOrAreaOptional;

  /// e.g. 12/A, High Level Road, Colombo 06
  String get addressOrAreaHint;

  /// Optional: Use exact live GPS
  String get useExactLiveGps;

  /// GPS Location set (Tap to refresh)
  String get gpsLocationSet;

  /// Detecting GPS...
  String get detectingGps;

  /// EXPRESS DISPATCH ROUTE
  String get expressDispatchRoute;

  /// Auto-passes in
  String get autoPassesIn;

  /// New Job Request
  String get newJobRequest;

  /// URGENT
  String get urgent;

  /// Guaranteed Base Payout
  String get guaranteedBasePayout;

  /// Direct Settlement\nCash at Service Site
  String get directSettlementCashAtSite;

  /// Service Note
  String get serviceNote;

  /// Pull over safely before confirming arrival navigation
  String get pullOverSafelyNote;

  /// Report En-Route Delay
  String get reportEnRouteDelay;

  /// En Route Navigation
  String get enRouteNavigation;

  /// Turn Left
  String get turnLeft;

  /// Turn Right
  String get turnRight;

  /// Google Maps / Waze
  String get googleMapsOrWaze;

  /// Customer notified of your arrival
  String get customerNotifiedOfArrival;

  /// National ID (NIC) Verification
  String get nationalIdVerification;

  /// Verified Artisan Network — Sri Lanka
  String get verifiedArtisanNetworkSriLanka;

  /// Fast-Track Verification Checklist
  String get fastTrackVerificationChecklist;

  /// Call Partner Support 1340 (Toll Free)
  String get callPartnerSupport;

  /// Photos stored securely • Only seen by HelaService admins
  String get endToEndEncryptedVault;

  /// JPEG, PNG or HEIC (Max 600 KB)
  String get nicUploadFileLimitHint;

  /// Photos are stored securely and only seen by HelaService admins.
  String get nicSecureStorageDesc;

  /// Uploading securely...
  String get uploadingToVault;

  /// 24/7 Emergency Dispatch Available
  String get emergencyAvailable247;

  /// Receive urgent priority service requests anytime
  String get emergencyAvailableDesc;

  /// Operational District
  String get operationalDistrict;

  /// Primary Trade Category
  String get primaryTradeCategory;

  /// Quotes
  String get quotesCount;

  /// HelaService Operations Admin
  String get adminDashboardTitle;

  /// Platform Overview
  String get platformOverview;

  /// Active Technicians
  String get activeTechnicians;

  /// Pending Verifications
  String get pendingVerifications;

  /// Total Jobs Dispatched
  String get totalDispatchedJobs;

  /// Gross Booking Value
  String get grossBookingValue;

  /// System Health: Optimal
  String get systemHealth;

  /// Pending Technician Approvals
  String get pendingTechnicianApprovals;

  /// Dispute Resolution Center
  String get disputeResolutionCenter;

  /// Platform Analytics & Revenue
  String get platformAnalytics;

  /// Super Admin Privileges Active
  String get superAdminPrivileges;

  /// System Audit Logs
  String get auditLogs;

  /// Approve
  String get approve;

  /// Reject
  String get reject;

  /// Failed to pick photo
  String get failedToPickPhoto;

  /// Please accept the Terms of Service to continue.
  String get pleaseAcceptTerms;

  /// Please upload a photo of the front of your NIC
  String get pleaseUploadNicFront;

  /// Please upload a photo of the back of your NIC
  String get pleaseUploadNicBack;

  /// Failed to submit
  String get failedToSubmit;

  /// Close
  String get close;

  /// sec
  String get sec;

  /// Upload Profile Photo
  String get uploadProfilePhoto;

  /// Upload NIC Front
  String get uploadNicFront;

  /// Upload NIC Back
  String get uploadNicBack;

  /// Please upload a photo of the front of your NIC
  String get nicFrontRequired;

  /// Required *
  String get requiredField;

  /// Upload a clear face photo for your service provider profile.
  String get uploadClearFacePhoto;

  /// Tap to change
  String get tapToChange;

  /// On-Time
  String get onTimeArrival;

  /// Artisan Profile
  String get artisanProfile;

  /// Jobs Done
  String get jobsDone;

  /// Completed
  String get completed;

  /// Prompt Arrival
  String get promptArrival;

  /// Operating District
  String get operatingDistrict;

  /// Phone
  String get phone;

  /// NIC front & back uploaded at registration
  String get nicUploaded;

  /// Workshop / Base GPS Location
  String get baseLocation;

  /// No exact GPS coordinates set
  String get noGpsSet;

  /// Calculates real-time distance to open customer jobs
  String get distanceCalcHint;

  /// Auto-Detect & Update Current GPS
  String get autoDetectGps;

  /// Job Dispatch Settings
  String get jobDispatchSettings;

  /// Emergency Night Callout
  String get emergencyCallout;

  /// Accept urgent visits between 8 PM - 6 AM at 1.5x surge rate
  String get emergencyCalloutDesc;

  /// Preferences & Appearance
  String get appearance;

  /// Appearance & Theme
  String get themeMode;

  /// Current
  String get currentTheme;

  /// App Language / භාෂාව / மொழி
  String get appLanguage;

  /// Current
  String get currentLanguage;

  /// Switch to Customer Mode
  String get switchToCustomer;

  /// Book technicians for your own home or office
  String get switchToCustomerDesc;

  /// Broadcast Alert
  String get broadcastAlert;

  /// Send high-priority notification to all verified artisans currently online across Sri Lanka.
  String get broadcastAlertDesc;

  /// Send Broadcast
  String get sendBroadcast;

  /// Admin Console Settings
  String get adminConsole;

  /// Island Platform Health & Telematics
  String get platformHealth;

  /// Core Services
  String get coreServices;

  /// Pending KYC
  String get pendingKyc;

  /// Operations Controls
  String get operationsControls;

  /// Admin Team & Access Governance
  String get adminTeamGovernance;

  /// Manage team, invite admins & configure permissions
  String get adminTeamGovernanceDesc;

  /// Emergency Island Broadcast
  String get emergencyBroadcast;

  /// Send alerts to active artisans across districts
  String get emergencyBroadcastDesc;

  /// Test user-facing customer or technician flows
  String get switchOperationalViewDesc;

  /// Job Bid & Tracking Ledger
  String get jobLedger;

  /// Job Ledger
  String get jobLedgerNav;

  /// Historical audit of service bids, tracking, dispatch outcomes & customer satisfaction
  String get jobLedgerSubtitle;

  /// Total Completed Jobs
  String get totalCompletedJobs;

  /// Total In-Progress Jobs
  String get totalInProgressJobs;

  /// Average Rating
  String get averageRating;

  /// Completed
  String get filterCompleted;

  /// In Progress
  String get filterInProgress;

  /// Cancelled
  String get filterCancelled;

  /// Won By
  String get wonBy;

  /// Customer
  String get customerLabel;

  /// Bid Amount
  String get bidAmount;

  /// Not recorded
  String get notRecorded;

  /// No bookings match the selected status filter.
  String get noBookingsMatchingFilter;

  /// Delay Reported
  String get delayReported;

  /// Tracking Outcome
  String get trackingOutcome;

  /// Customer Satisfaction
  String get customerSatisfaction;

  /// Manual Review
  String get manualReview;

  /// Cloud Storage Path
  String get cloudStoragePath;

  /// Manual NIC Review
  String get manualNicReview;

  /// OCR Audit — All 4 Fields Concordant
  String get ocrAuditConcordant;

  /// OCR Audit — Discrepancy Flagged
  String get ocrAuditFlagged;

  /// Not provided
  String get notProvided;

  /// Not specified
  String get notSpecified;

  /// Please enter your full name
  String get enterFullName;

  /// Please enter a valid email address
  String get enterValidEmail;

  /// Please enter your National Identity Card (NIC) number
  String get enterNicError;

  /// Create Customer Account
  String get createCustomerAccount;

  /// Book trusted home services in a few taps across Sri Lanka
  String get customerRegisterSubtitle;

  /// Full name
  String get fullNameLabel;

  /// Email address
  String get emailAddressLabel;

  /// Account email
  String get accountEmailLabel;

  /// At least 6 characters
  String get atLeast6Chars;

  /// Contact phone number (for artisan dispatch)
  String get customerPhoneLabel;

  /// Contact mobile number (for customer dispatch)
  String get providerPhoneLabel;

  /// Home address
  String get homeAddressLabel;

  /// Become a Service Provider
  String get becomeProvider;

  /// Earn island-wide by taking verified jobs near you across Sri Lanka
  String get providerRegisterSubtitle;

  /// I agree to the Provider Terms and the NIC verification process
  String get agreeProviderTerms;

  /// Create Account & Verify NIC
  String get createAccountVerifyNic;

  /// Select a reason to adjust the customer ETA by +10 mins:
  String get selectDelayReason;

  /// Heavy Traffic
  String get heavyTraffic;

  /// Monsoon Rain
  String get monsoonRain;

  /// Road Detour
  String get roadDetour;

  /// Refueling Stop
  String get refuelingStop;

  /// Chat with Customer
  String get chatWithCustomer;

  /// Call Customer Phone
  String get callCustomerPhone;

  /// Customer phone number not available
  String get customerPhoneNotAvailable;

  /// Entry Instructions:
  String get entryInstructionsLabel;

  /// No special entry instructions provided.
  String get noSpecialEntryInstructions;

  /// Arrived at Location
  String get arrivedAtLocation;

  /// Slide to Confirm Arrival
  String get slideToConfirmArrival;

  /// Arrival confirmed! Customer notified.
  String get arrivalConfirmedNotified;

  /// Arrival recorded — ready to commence service
  String get arrivalRecordedReady;

  /// Customer will be notified of your immediate arrival
  String get customerWillBeNotified;

  /// Report Traffic / Delay
  String get reportTrafficDelay;

  /// GPS Active (Real-Time Device Position)
  String get gpsActiveDevice;

  /// GPS Active (High Precision)
  String get gpsActivePrecision;

  /// Order & Payment Support
  String get orderPaymentSupport;

  /// Have an issue with this job or fee dispute? Our 24/7 support line is ready to assist.
  String get orderSupportDesc;

  /// Call Support Hotline 1340
  String get callSupportHotline;

  /// Toll-free 24/7 customer care
  String get tollFreeCare;

  /// Saving…
  String get savingProgress;

  /// Exceptional! 5.0
  String get ratingExceptional;

  /// Great, 4.0
  String get ratingGreat;

  /// Good, 3.0
  String get ratingGood;

  /// Okay, 2.0
  String get ratingOkay;

  /// Needs work, 1.0
  String get ratingNeedsWork;

  /// Punctual
  String get tagPunctual;

  /// Polite
  String get tagPolite;

  /// Clean Work
  String get tagCleanWork;

  /// Fair Price
  String get tagFairPrice;

  /// Small Tea
  String get tipSmallTea;

  /// Generous
  String get tipGenerous;

  /// Custom
  String get tipCustom;

  /// Enter amount
  String get tipEnterAmount;

  /// Same account, different way of using HelaService
  String get roleSwitchDesc;

  /// Book and track home services
  String get roleCustomerSubtitle;

  /// Go online and take job requests
  String get roleProviderSubtitle;

  /// Platform back-office tools
  String get roleAdminSubtitle;

  /// Technician Identity Verification Desk
  String get nicVerificationDeskTitle;

  /// Pending Review
  String get statPendingReview;

  /// Approved
  String get statApproved;

  /// Needs Resubmission
  String get statNeedsResubmission;

  /// Flagged / Rejected
  String get statFlaggedRejected;

  /// Verification Queue Clear
  String get verificationQueueClear;

  /// Incoming Verification Stream
  String get incomingVerificationStream;

  /// Select an artisan to audit documents
  String get selectArtisanAudit;

  /// Review Required
  String get reviewRequired;

  /// Active & Verified
  String get activeAndVerified;

  /// Rejected
  String get rejectedStatus;

  /// Pending Verification
  String get pendingVerificationStatus;

  /// Approve & Activate Artisan
  String get approveAndActivateArtisan;

  /// Artisan Activated
  String get artisanActivated;

  /// Reject
  String get rejectAction;

  /// Request Clearer Photo
  String get requestClearerPhoto;

  /// Data Field
  String get ocrDataField;

  /// OCR Extracted
  String get ocrExtracted;

  /// Registry
  String get ocrRegistry;

  /// Status
  String get ocrStatus;

  /// Full Name
  String get ocrFullName;

  /// NIC Number
  String get ocrNicNumber;

  /// Electoral Address / Location
  String get ocrLocation;

  /// Trade / Document Note
  String get ocrTradeNote;

  /// NIC Front
  String get docNicFront;

  /// NIC Back
  String get docNicBack;

  /// Liveness
  String get docLiveness;

  /// Coverage & Categories
  String get navCoverageAndCategories;

  /// Admins & Team
  String get navAdminsAndTeam;

  /// Artisans
  String get navArtisans;

  /// Customers
  String get navCustomers;

  /// Service Metrics
  String get navServiceMetrics;

  /// Platform Settings
  String get navPlatformSettings;

  /// Dashboard
  String get navDashboard;

  /// Ops Portal
  String get opsPortal;

  /// OPERATIONS CORE
  String get operationsCore;

  /// Password
  String get passwordLabel;

  /// Full name (as in NIC)
  String get fullNameNicLabel;

  /// National Identity Card (NIC) number
  String get nicNumberLabel;

  /// Island Operations Core
  String get opsCoreSubtitle;

  /// Island Operations
  String get islandOperationsTitle;

  /// Active Providers
  String get activeProvidersTitle;

  /// +2 Live
  String get liveBadge;

  /// {online} Online • {verified} Verified Fleet
  String onlineFleetSummary(String online, String verified);

  /// Total Bookings
  String get totalBookingsTitle;

  /// {completed} Completed • {inProgress} In Progress
  String completedInProgressSummary(String completed, String inProgress);

  /// NIC Screening
  String get nicScreeningTitle;

  /// Clear
  String get clearStatusBadge;

  /// {count} Verification Dossiers Logged
  String verificationDossiersLogged(String count);

  /// Live Traffic
  String get allSriLankaLiveTraffic;

  /// Heatmap
  String get heatmapBadge;

  /// Live Top Roster
  String get activeArtisanFleetLive;

  /// District Capacity — Real-time Load
  String get districtCapacityRealtime;

  /// No active artisans found in fleet
  String get noActiveArtisansFleet;

  /// Trade: {trade} • Zone: {zone}
  String tradeAndZone(String trade, String zone);

  /// Select Open Job Request to Dispatch:
  String get selectOpenJobRequest;

  /// No open customer requests awaiting dispatch.
  String get noOpenCustomerRequests;

  /// Assign
  String get assignAction;

  /// Dispatched {artisan} to {job}
  String dispatchedArtisanToJob(String artisan, String job);

  /// Disputes
  String get navDisputes;

  /// Trade Service Categories
  String get tradeCategoriesTitle;

  /// Add New Category
  String get addNewCategoryAction;

  /// Catalog Density
  String get catalogDensityTitle;

  /// VIEWING
  String get viewingBadge;

  /// {count} Categories
  String categoriesCount(String count);

  /// {count} active trade services published
  String activeTradeServicesPublished(String count);

  /// Active Artisan Fleet
  String get activeArtisanFleetTitle;

  /// {count} Artisans
  String artisansCount(String count);

  /// {count} vetted technicians available
  String vettedTechniciansAvailable(String count);

  /// Published Trade Categories
  String get publishedTradeCategories;

  /// {registered} Registered • {online} Online Now
  String registeredOnlineCount(String registered, String online);

  /// Active
  String get statusActive;

  /// Paused
  String get statusPaused;

  /// Dynamic Bidding
  String get dynamicBiddingBadge;

  /// Island-wide
  String get islandWideBadge;

  /// Districts & Fleet Coverage
  String get districtsAndFleetCoverage;

  /// Search fleet by name, trade, district, phone...
  String get searchFleetHint;

  /// Add Service Category
  String get addServiceCategory;

  /// Category Title
  String get categoryTitle;

  /// Service Description
  String get serviceDescription;

  /// Select Trade Icon
  String get selectTradeIcon;

  /// Save & Publish Category
  String get savePublishCategory;

  /// Delete Category
  String get deleteCategory;

  /// Are you sure you want to delete this category?
  String get deleteCategoryConfirm;

  /// Suspend Artisan
  String get suspendArtisan;

  /// Read-Only Mode: Ops Governance permission required to manage categories or fleet.
  String get readOnlyOpsGovernance;

  /// No Categories in Database
  String get noCategoriesInDb;

  /// Add First Category
  String get addFirstCategory;

  /// Admin Team & Access Governance
  String get adminTeamGovernanceTitle;

  /// Add New Admin
  String get addNewAdminAction;

  /// Total Admins
  String get totalAdminsCount;

  /// Registered platform accounts
  String get registeredPlatformAccounts;

  /// Super Admins
  String get superAdminsCount;

  /// Root governance leads
  String get rootGovernanceLeads;

  /// Active Operators
  String get activeOperatorsCount;

  /// Dispatch & KYC duty
  String get dispatchKycDuty;

  /// Pending Invites
  String get pendingInvitesCount;

  /// Awaiting first sign-in
  String get awaitingFirstSignIn;

  /// Search by admin name or email...
  String get searchAdminPlaceholder;

  /// Role:
  String get roleFilterLabel;

  /// All Roles
  String get allRolesFilter;

  /// Super Admin
  String get roleSuperAdminBadge;

  /// Operations Admin
  String get roleOpsAdminBadge;

  /// Support Admin
  String get roleSupportAdminBadge;

  /// You
  String get youBadge;

  /// • Full Root Governance (All Modules Granted)
  String get fullRootGovernanceBadge;

  /// Revoke Administrator Access?
  String get revokeAdminAccess;

  /// Are you sure you want to revoke back-office administrative access for {name} ({email})? This action cannot be undone.
  String revokeAccessConfirm(String name, String email);

  /// Revoke Access
  String get revokeAccess;

  /// Administrative access revoked for {name}.
  String adminAccessRevoked(String name);

  /// Search technicians, NIC, jobs...
  String get searchTechniciansNicJobs;

  /// Island Network: 99.8% Online • Colombo / Kandy / Galle active
  String get islandNetworkStatus;

  /// Operations Alerts & Broadcasts
  String get operationsAlertsBroadcasts;

  /// No active system alerts or broadcasts logged.
  String get noActiveSystemAlerts;

  /// Dispute & Complaint Center
  String get disputeComplaintCenter;

  /// Review user reports, audit quality disputes, and enforce moderation
  String get reviewUserReports;

  /// Total Reports
  String get totalReports;

  /// Pending Action
  String get pendingAction;

  /// Resolved Cases
  String get resolvedCases;

  /// Search disputes by customer, provider, reason...
  String get searchDisputesPlaceholder;

  /// Resolve Complaint
  String get resolveComplaint;

  /// Dismiss Complaint
  String get dismissComplaint;

  /// Suspend Service Provider
  String get suspendServiceProvider;

  /// Reason for Ban (Visible to Provider):
  String get reasonForBan;

  /// All
  String get filterAllFilter;

  /// Expand map
  String get expandMap;

  /// Close map
  String get closeMap;

  /// Your admin access is suspended.
  String get adminAccessSuspended;

  /// Password reset link sent to {email}. Please check your inbox.
  String passwordResetSent(String email);

  /// At least 6 characters
  String get atLeast6Characters;

  /// Re-enter your password
  String get reEnterPassword;

  /// Could not obtain GPS location. Please ensure location is enabled.
  String get gpsLocationError;

  /// Search chats by name or message...
  String get searchChatsPlaceholder;

  /// Please sign in to view your messages
  String get signInToViewMessages;

  /// Failed to load conversations
  String get failedToLoadConversations;

  /// No matching conversations
  String get noMatchingConversations;

  /// No conversations yet
  String get noConversationsYet;

  /// Direct messages with service providers or customers will appear here.
  String get conversationsEmptyDesc;

  /// Try searching with another name or keyword.
  String get trySearchingAnotherKeyword;

  /// Tap to start conversation
  String get tapToStartConversation;

  /// Unauthorized: Admin access required.
  String get unauthorizedAdminAccess;

  /// Profile picture updated successfully!
  String get profilePictureUpdated;

  /// Profile picture removed.
  String get profilePictureRemoved;

  /// Failed to remove photo
  String get failedToRemovePhoto;

  /// Remove photo
  String get removePhoto;

  /// Just now
  String get timeJustNow;

  /// {count}m ago
  String timeMinutesAgo(int count);

  /// {count}h ago
  String timeHoursAgo(int count);

  /// {count}d ago
  String timeDaysAgo(int count);

  /// Choose your primary display language
  String get chooseDisplayLanguage;

  /// Online
  String get online;

  /// Offline
  String get offline;

  /// You
  String get you;

  /// Messages
  String get messages;

  /// Arrival Confirmed
  String get arrivalConfirmed;

  /// Language switched to
  String get languageSwitchedTo;

  /// Call
  String get call;

  /// e.g. No. 12, Lake Road
  String get addressHint;

  /// Need Quick Service?
  String get needQuickService;

  /// Post your job in 60s & receive instant competitive bids from verified nearby artisans.
  String get postJobBannerDesc;

  /// Post Job & Get Quotes
  String get postJobAndGetQuotes;

  /// No artisans match your filters
  String get noArtisansMatchFilters;

  /// Try clearing your search query or adjusting your filters
  String get tryClearingSearchOrFilters;

  /// Reset All Filters
  String get resetAllFilters;

  /// Filter Artisans
  String get filterArtisans;

  /// Online & Ready to Bid
  String get onlineReadyToBid;

  /// Show active artisans ready for instant booking
  String get onlineReadyToBidSub;

  /// Emergency Dispatch
  String get emergencyDispatch;

  /// Customer Rating
  String get customerRating;

  /// All Ratings
  String get allRatings;

  /// Apply Filters
  String get applyFilters;

  /// Top Artisans
  String get topArtisans;

  /// Friend
  String get friend;

  /// Where are you now?
  String get quickReplyWhereAreYou;

  /// I am waiting at the main gate.
  String get quickReplyWaitingMainGate;

  /// Please call me when you arrive.
  String get quickReplyCallWhenArrive;

  /// Parking is available on premise.
  String get quickReplyParkingAvailable;

  /// On my way, will be there soon.
  String get quickReplyOnMyWay;

  /// Could not connect to chat
  String get couldNotConnectChat;

  /// Could not load chat
  String get couldNotLoadChat;

  /// Send a message to start chatting
  String get sendMsgToStartChat;

  /// Type a message…
  String get typeMessage;

  /// Your service booking is confirmed. A direct conversation has been started with {providerName} to coordinate timing and location.
  String bookingConfirmedChatStarted(String providerName);

  /// Later
  String get later;

  /// Open Chat
  String get openChat;

  /// Failed to accept quote
  String get failedToAcceptQuote;

  /// ETA Adjusted: +{minutes} Mins Delay
  String etaDelayNotice(int minutes);

  /// Artisan reported: {reason}
  String artisanReportedDelay(String reason);

  /// Provider phone not available
  String get providerPhoneNotAvailable;

  /// Are you sure you want to cancel this booking request?
  String get cancelBookingConfirm;

  /// Yes, Cancel
  String get yesCancel;

  /// Service request cancelled.
  String get serviceRequestCancelled;

  /// Live tracking link copied to clipboard!
  String get liveTrackingCopied;

  /// Destination
  String get destination;

  /// Live GPS • On the way
  String get liveGpsOnTheWay;

  /// Please enable location services on your device
  String get enableLocationServices;

  /// Location permission denied
  String get locationPermissionDenied;

  /// Location permission permanently denied. Enable in settings.
  String get locationPermissionPermanentlyDenied;

  /// Failed to detect location
  String get failedToDetectLocation;

  /// Failed to submit request
  String get failedToSubmitRequest;

  /// Report Provider
  String get reportProvider;

  /// Experience
  String get experience;

  /// No customer reviews recorded yet
  String get noCustomerReviews;

  /// Unprofessional Conduct
  String get complaintUnprofessionalConduct;

  /// Late or No-Show
  String get complaintLateNoShow;

  /// Poor Quality of Work
  String get complaintPoorQuality;

  /// Safety or Harassment Concern
  String get complaintSafetyConcern;

  /// Fraud or Identity Issue
  String get complaintFraudIssue;

  /// Other Issue
  String get complaintOtherIssue;

  /// Report Service Provider
  String get reportServiceProvider;

  /// Reporting {name} ({title})
  String reportingTechnician(String name, String title);

  /// Select Complaint Reason
  String get selectComplaintReason;

  /// Explain Incident Details
  String get explainIncidentDetails;

  /// Please detail what happened, including any agreed fees or work that was not completed...
  String get explainIncidentHint;

  /// Please describe the issue before submitting.
  String get describeIssueBeforeSubmitting;

  /// Please sign in to submit a complaint.
  String get signInToSubmitComplaint;

  /// Complaint submitted to Admin Support for review.
  String get complaintSubmittedSuccess;

  /// Submit Official Report
  String get submitOfficialReport;

  /// Job #{id}
  String jobIdNumber(String id);

  /// Settled directly
  String get settledDirectly;

  /// +LKR 200
  String get tip200;

  /// +LKR 500
  String get tip500;

  /// Service Diagnostic
  String get serviceDiagnostic;

  /// Technician
  String get technician;

  /// Today
  String get today;

  /// By {name}
  String byTechnician(String name);

  /// ACCOUNT & SERVICES
  String get accountAndServices;

  /// Home / Service GPS Location
  String get homeServiceGpsLocation;

  /// Tap to auto-detect current GPS coordinates
  String get tapToAutoDetectGps;

  /// GPS Location updated: {lat}, {lng}
  String gpsLocationUpdated(String lat, String lng);

  /// Could not obtain GPS location. Please check location permissions.
  String get couldNotObtainGps;

  /// Current: {mode} (Tap to change)
  String currentMode(String mode);

  /// Failed to pick image
  String get failedToPickImage;

  /// Overcharging / Price Dispute
  String get complaintPriceDispute;

  /// Failed to submit report
  String get failedToSubmitReport;

  /// EXPRESS DISPATCH
  String get expressDispatchCaps;

  /// Auto-passes in {seconds} s
  String autoPassesInSeconds(int seconds);

  /// URGENT
  String get urgentCaps;

  /// seconds
  String get secondsUnit;

  /// GUARANTEED BASE PAYOUT
  String get guaranteedBasePayoutCaps;

  /// Cash at service site
  String get cashAtServiceSite;

  /// Nearby
  String get nearby;

  /// Accept Job
  String get acceptJob;

  /// Pass to next artisan
  String get passToNextArtisan;

  /// Pull over safely before accepting.
  String get pullOverSafelyWarning;

  /// Service Request
  String get serviceRequest;

  /// Client Address
  String get clientAddress;

  /// {minutes} min
  String durationMins(int minutes);

  /// {hours} hr
  String durationHours(int hours);

  /// 1.5 hr
  String get durationOneAndHalfHours;

  /// Failed to submit quote: {error}
  String failedToSubmitQuote(String error);

  /// Reported delay: {reason} (+10 min ETA adjustment broadcasted)
  String delayReportedNotice(String reason);

  /// Customer Location
  String get customerLocation;

  /// Customer location not available. Call the customer.
  String get customerLocationNotAvailableCall;

  /// {name}\'s Location
  String customerLocationNamed(String name);

  /// You (En Route)
  String get youEnRoute;

  /// In {distance}
  String inDistance(String distance);

  /// Navigating to {target}
  String navigatingTo(String target);

  /// Failed to upload photo: {error}
  String failedToUploadPhoto(String error);

  /// Failed to submit verification: {error}
  String failedToSubmitVerification(String error);

  /// Step 2 of 3
  String get step2Of3;

  /// Jobs
  String get navJobs;

  /// Verification Under Review
  String get verificationUnderReview;

  /// STATUS: PENDING REVIEW
  String get statusPendingReviewCaps;

  /// Your NIC photos and selfie are stored securely. Our team is checking your details.
  String get nicUnderReviewDesc;

  /// Return to Dashboard
  String get returnToDashboard;

  /// Verify your identity to start receiving jobs island-wide across Sri Lanka.
  String get verifyIdentitySubtitle;

  /// NIC Front Side
  String get nicFrontSide;

  /// Clear photo of the front side showing your portrait and NIC number.
  String get nicFrontSideDesc;

  /// Capture or Upload Front
  String get captureOrUploadFront;

  /// Tip: Lay flat on a contrasting surface, avoid phone shadow.
  String get nicFrontTip;

  /// NIC Back Side
  String get nicBackSide;

  /// Back side showing your registered residential address and clear barcode.
  String get nicBackSideDesc;

  /// Capture or Upload Back
  String get captureOrUploadBack;

  /// Ensure all 4 card corners are in frame
  String get nicBackTip;

  /// Selfie Holding Your NIC
  String get selfieHoldingNic;

  /// Hold your National ID card next to your face, both equally in focus.
  String get selfieHoldingNicDesc;

  /// Open Camera
  String get openCamera;

  /// Live portrait test
  String get livePortraitTest;

  /// Do not wear sunglasses, caps, or masks. Do not cover your name or photo.
  String get selfieTip;

  /// Fast turnaround:
  String get fastTurnaroundTitle;

  /// Approvals take less than 2 hours (Mon-Sat, 8 AM - 6 PM).
  String get fastTurnaroundBody;

  /// SMS alert:
  String get smsAlertTitle;

  /// Instant approval message to your registered mobile number.
  String get smsAlertBody;

  /// Quality standard:
  String get qualityStandardTitle;

  /// Natural daylight photos get accepted first try.
  String get qualityStandardBody;

  /// Submit for Verification
  String get submitForVerification;

  /// Attached
  String get attachedStatus;

  /// Required
  String get requiredStatus;

  /// Photo attached · tap to replace
  String get photoAttachedTapReplace;

  /// New
  String get newLabel;

  /// {count} reviews
  String nReviews(int count);

  /// {count} jobs
  String nJobsCompleted(int count);

  /// Fleet Active
  String get fleetActive;

  /// {category} Specialist
  String categorySpecialist(String category);

  /// Instant Match active
  String get instantMatchActive;

  /// Offline · Switch on to receive jobs
  String get offlineSwitchOnDesc;

  /// {count} new
  String nNew(int count);

  /// Accept Direct Booking
  String get acceptDirectBooking;

  /// {distance} away
  String distanceAway(String distance);

  /// ETA
  String get etaLabel;

  /// min
  String get minsUnit;

  /// Certified Artisan
  String get certifiedArtisan;

  /// Please grant at least one permission flag for this admin.
  String get addAdminGrantOnePermission;

  /// Failed to add admin: {error}
  String addAdminFailed(String error);

  /// Admin Account Created
  String get addAdminAccountCreated;

  /// The user has been successfully granted {role} privileges. The next time they sign in with this email, the administrative console will be accessible.
  String addAdminSuccessBody(String role);

  /// Add Platform Administrator
  String get addAdminTitle;

  /// Assign role and permissions; invite links will be generated
  String get addAdminSubtitle;

  /// Please enter the administrator full name
  String get addAdminEnterFullName;

  /// Official Work Email
  String get addAdminWorkEmail;

  /// Please enter a valid work email
  String get addAdminEnterWorkEmail;

  /// Mobile Phone (Optional)
  String get addAdminMobileOptional;

  /// Administrative Tier
  String get addAdminTier;

  /// Operational Permissions
  String get addAdminOperationalPermissions;

  /// Adding...
  String get addAdminAdding;

  /// Grant Admin Role
  String get addAdminGrantRole;

  /// Please select at least one permission flag.
  String get editPermSelectOne;

  /// Permissions updated for {name}.
  String editPermUpdatedFor(String name);

  /// Failed to update permissions: {error}
  String editPermFailed(String error);

  /// Change Administrative Tier
  String get editPermChangeTier;

  /// Assigned Operational Permissions
  String get editPermAssigned;

  /// Updating...
  String get editPermUpdating;

  /// Save Permissions
  String get editPermSave;

  /// Only Super Admins can access Administrator Management.
  String get sidebarOnlySuperAdmins;

  /// You do not have permission to access this section.
  String get sidebarNoPermission;

  /// Colombo Central Hub
  String get sidebarColomboCentralHub;

  /// Search
  String get topBarSearch;

  /// Support & Mediation Messages
  String get topBarSupportMessages;

  /// Administrator
  String get topBarAdministrator;

  /// Published categories are available island-wide. Pricing is dynamic — nearby verified technicians quote custom bids based on distance and job details.
  String get cdmPublishedCategoriesInfo;

  /// e.g. Solar PV Maintenance
  String get cdmCategoryTitleHint;

  /// Brief summary of the trade services offered...
  String get cdmServiceDescriptionHint;

  /// Please enter a category title
  String get cdmEnterCategoryTitle;

  /// Category \"{title}\" saved and published successfully
  String cdmCategorySaved(String title);

  /// Are you sure you want to delete \"{name}\"? This will disable dispatch for this category island-wide.
  String cdmDeleteCategoryConfirm(String name);

  /// Category \"{name}\" deleted
  String cdmCategoryDeleted(String name);

  /// Delete
  String get cdmDelete;

  /// Read-Only Mode (Ops Governance)
  String get cdmReadOnlyModeOpsGovernance;

  /// Audit verified service technicians, moderate access, and enforce suspensions
  String get cdmFleetSubtitle;

  /// Add your service trades to publish them to Firebase so customers can discover and book technicians.
  String get cdmNoCategoriesDesc;

  /// Dynamic Quotes
  String get cdmDynamicQuotes;

  /// Artisans Bid Per Job
  String get cdmArtisansBidPerJob;

  /// Pause Category
  String get cdmPauseCategory;

  /// Activate Category
  String get cdmActivateCategory;

  /// All ({count})
  String cdmFilterAllCount(String count);

  /// Online ({count})
  String cdmFilterOnlineCount(String count);

  /// Suspended ({count})
  String cdmFilterSuspendedCount(String count);

  /// Offline ({count})
  String cdmFilterOfflineCount(String count);

  /// No artisans match the search criteria
  String get cdmNoArtisansMatchSearch;

  /// No artisans registered in this filter view
  String get cdmNoArtisansInFilter;

  /// SUSPENDED
  String get cdmBadgeSuspended;

  /// ONLINE
  String get cdmBadgeOnline;

  /// OFFLINE
  String get cdmBadgeOffline;

  /// Sri Lanka
  String get cdmSriLanka;

  /// Base: LKR {amount}
  String cdmBaseRate(String amount);

  /// Suspension Reason: \"{reason}\"
  String cdmSuspensionReason(String reason);

  /// Complaints
  String get cdmComplaints;

  /// Suspend
  String get cdmSuspend;

  /// Restore / Unban
  String get cdmRestoreUnban;

  /// Delete Artisan Permanently
  String get cdmDeleteArtisanPermanently;

  /// Suspend {name}
  String cdmSuspendName(String name);

  /// Are you sure you want to suspend this artisan? They will be locked offline, hidden from customer searches, and prevented from submitting quotes.
  String get cdmSuspendConfirmBody;

  /// Reason for Suspension:
  String get cdmReasonForSuspension;

  /// {name} has been suspended.
  String cdmArtisanSuspended(String name);

  /// Confirm Suspension
  String get cdmConfirmSuspension;

  /// Restore {name}
  String cdmRestoreName(String name);

  /// Reactivate this artisan\'s profile? They will be allowed to go online and accept customer service requests.
  String get cdmRestoreConfirmBody;

  /// {name} has been restored to active status.
  String cdmArtisanRestored(String name);

  /// Restore Access
  String get cdmRestoreAccess;

  /// Delete Artisan
  String get cdmDeleteArtisan;

  /// Are you sure you want to permanently delete \"{name}\" from the technician database? This operation cannot be reversed.
  String cdmDeleteArtisanConfirm(String name);

  /// {name} deleted from database.
  String cdmArtisanDeleted(String name);

  /// Delete Permanently
  String get cdmDeletePermanently;

  /// Complaints for {name}
  String cdmComplaintsFor(String name);

  /// No complaints filed
  String get cdmNoComplaintsFiled;

  /// This service provider has no recorded customer disputes.
  String get cdmNoComplaintsDesc;

  /// By {name}
  String cdmByCustomer(String name);

  /// En Route
  String get ledgerStatusEnRoute;

  /// {count} jobs resolved across island
  String ledgerJobsResolvedIsland(String count);

  /// {count} dispatches active in field
  String ledgerDispatchesActive(String count);

  /// Based on {count} verified reviews
  String ledgerBasedOnReviews(String count);

  /// Awaiting customer feedback
  String get ledgerAwaitingFeedback;

  /// Service Booking
  String get ledgerServiceBooking;

  /// {minutes}m delay
  String ledgerDelayMinutes(String minutes);

  /// Root operational lead with team administration & full platform governance.
  String get adminRoleDescSuper;

  /// Operational dispatch, artisan verifications, category & district hub management.
  String get adminRoleDescOps;

  /// Support queue handler with KYC review and provider inquiry access.
  String get adminRoleDescSupport;

  /// Admin Team Governance
  String get permManageAdminsLabel;

  /// Artisan NIC & KYC Verification
  String get permVerifyNicLabel;

  /// Categories & District Hubs
  String get permManageCategoriesLabel;

  /// Island-wide Emergency Alerts
  String get permBroadcastAlertsLabel;

  /// Service & Financial Logs
  String get permViewFinancesLabel;

  /// Invite, configure, demote, and deactivate administrators.
  String get permManageAdminsDesc;

  /// Review NIC documents and approve or reject provider registrations.
  String get permVerifyNicDesc;

  /// Configure trade categories and provincial hub thresholds.
  String get permManageCategoriesDesc;

  /// Send push alerts and critical warnings to active island artisans.
  String get permBroadcastAlertsDesc;

  /// Inspect service metrics, provider earnings, and completed job records.
  String get permViewFinancesDesc;

  /// Invited
  String get adminStatusInvited;

  /// Suspended
  String get adminStatusSuspended;

  /// Artisan
  String get custArtisanLabel;

  /// Default system language
  String get custDefaultSystemLanguage;

  /// {metres} m away
  String custMetresAway(int metres);

  /// {km} km away
  String custKmAwayValue(String km);

  /// Colombo 03
  String get custFallbackAreaColombo03;

  /// Western Province
  String get custFallbackWesternProvince;

  /// Colombo
  String get custFallbackColombo;

  /// Track my HelaService artisan live here: {link}
  String custShareTrackingText(String link);

  /// LKR {amount} / hr
  String custRatePerHour(String amount);

  /// GPS: {lat}, {lng} (Tap to update)
  String custGpsTapToUpdate(String lat, String lng);

  /// inspection
  String get custInspectionSuffix;

  /// Service Provider
  String get custServiceProviderLabel;

  /// Artisan
  String get liveMapColArtisan;

  /// Assigned Zone
  String get liveMapColAssignedZone;

  /// Payout
  String get liveMapColPayout;

  /// Quick Dispatch
  String get liveMapColQuickDispatch;

  /// Available / Idle
  String get liveMapStatusAvailableIdle;

  /// Active Verified
  String get liveMapStatusActiveVerified;

  /// NIC: Verified
  String get liveMapNicVerified;

  /// NIC: Pending
  String get liveMapNicPending;

  /// Colombo Metro
  String get liveMapZoneColomboMetro;

  /// {amount} (Today)
  String liveMapPayoutToday(String amount);

  /// (Today)
  String get liveMapTodayParen;

  /// Dispatch
  String get liveMapActionDispatch;

  /// Re-assign
  String get liveMapActionReassign;

  /// {action}: {name}
  String liveMapDispatchDialogTitle(String action, String name);

  /// {count} quotes received
  String liveMapQuotesReceived(int count);

  /// +{count} Live
  String liveMapLiveCount(int count);

  /// {count} Active
  String liveMapActiveCount(int count);

  /// Action Req
  String get liveMapActionRequired;

  /// Show all districts
  String get liveMapShowAllDistricts;

  /// {count} active provider in unmapped/unknown zones
  String liveMapUnmappedProviderOne(int count);

  /// {count} active providers in unmapped/unknown zones
  String liveMapUnmappedProviderMany(int count);

  /// N/A
  String get disputesNotAvailable;

  /// Add resolution notes detailing the outcome of the investigation or customer compensation.
  String get disputesResolveNotesPrompt;

  /// Add notes explaining why this dispute is dismissed.
  String get disputesDismissNotesPrompt;

  /// Enter internal admin resolution summary...
  String get disputesResolutionSummaryHint;

  /// Complaint marked as Resolved.
  String get disputesMarkedResolvedSnack;

  /// Complaint dismissed.
  String get disputesDismissedSnack;

  /// Mark Resolved
  String get disputesMarkResolved;

  /// Confirm Dismiss
  String get disputesConfirmDismiss;

  /// Are you sure you want to ban {name} ({trade})? They will be locked offline and hidden from customer discovery.
  String disputesBanConfirm(String name, String trade);

  /// Suspend Provider
  String get disputesSuspendProvider;

  /// Provider {name} has been suspended.
  String disputesProviderSuspendedSnack(String name);

  /// Suspend Customer
  String get disputesSuspendCustomer;

  /// Customer {name} has been suspended.
  String disputesCustomerSuspendedSnack(String name);

  /// Account Suspended
  String get accountSuspendedTitle;

  /// Your account has been suspended by administration. If you believe this is an error, please contact customer support.
  String get accountSuspendedDesc;

  /// Call Support Helpline
  String get contactHelpline;

  /// Error loading complaints: {error}
  String disputesErrorLoading(String error);

  /// All ({count})
  String disputesFilterAllCount(int count);

  /// Pending ({count})
  String disputesFilterPendingCount(int count);

  /// Resolved ({count})
  String disputesFilterResolvedCount(int count);

  /// Dismissed ({count})
  String disputesFilterDismissedCount(int count);

  /// No matching complaints found
  String get disputesNoMatching;

  /// No complaints recorded
  String get disputesNoneRecorded;

  /// Try adjusting your search criteria.
  String get disputesTryAdjustingSearch;

  /// All service transactions are currently dispute-free.
  String get disputesAllDisputeFree;

  /// RESOLVED
  String get disputesStatusResolvedCaps;

  /// DISMISSED
  String get disputesStatusDismissedCaps;

  /// PENDING
  String get disputesStatusPendingCaps;

  /// Filed {time}
  String disputesFiledAgo(String time);

  /// CUSTOMER
  String get disputesCustomerCaps;

  /// REPORTED
  String get disputesReportedCaps;

  /// Admin Note: {note}
  String disputesAdminNote(String note);

  /// Reopen Case
  String get disputesReopenCase;

  /// Dispute case reopened.
  String get disputesCaseReopenedSnack;

  /// Only Super Admins can access Administrator Management.
  String get shellSuperAdminOnly;

  /// Location not set
  String get provLocationNotSet;

  /// Direct Pay
  String get provDirectPay;

  /// Specialist
  String get provSpecialist;

  /// Image size is too large ({sizeKb} KB). Maximum allowed size is 600 KB. Please choose or capture a compressed photo.
  String provNicImageTooLarge(int sizeKb);

  /// Failed to decode the captured document.
  String get provNicDecodeFailed;

  /// NIC image is too large even after compression. Please retake the photo.
  String get provNicTooLargeAfterCompression;

  /// User not authenticated
  String get provUserNotAuthenticated;

  /// Not logged in
  String get provNotLoggedIn;

  /// 200012345678 or 881234567V
  String get provNicHintExample;

  /// {hours}h {minutes}m
  String provDurationHoursMins(int hours, int minutes);

  /// GPS Location detected: {lat}, {lng}
  String authGpsLocationDetected(String lat, String lng);

  /// Failed to pick profile photo: {error}
  String authFailedToPickProfilePhoto(String error);

  /// No account found with this email. Please check your spelling or register.
  String get authErrUserNotFound;

  /// Incorrect password or email. Please check your credentials.
  String get authErrWrongCredentials;

  /// An account already exists with this email address.
  String get authErrEmailInUse;

  /// The password is too weak. Please use at least 6 characters.
  String get authErrWeakPassword;

  /// Please enter a valid email address.
  String get authErrInvalidEmail;

  /// This account has been disabled. Please contact support.
  String get authErrUserDisabled;

  /// Too many attempts. Please wait a moment before trying again.
  String get authErrTooManyRequests;

  /// Network connection issue. Please check your internet connection.
  String get authErrNetwork;

  /// Sign-in cancelled by user.
  String get authErrSignInCancelled;

  /// Firebase user data is not available.
  String get authErrUserDataUnavailable;

  /// User is already registered as an administrator.
  String get authErrAlreadyAdmin;

  /// Authentication failed for {email}
  String authErrAuthenticationFailed(String email);

  /// Registration failed for {email}
  String authErrRegistrationFailed(String email);

  /// No registered user found with email \"{email}\". The person must first register an account in the app before they can be promoted to an administrator.
  String authErrNoRegisteredUser(String email);

  /// {name} approved & activated on HelaService!
  String nicDeskApprovedActivated(String name);

  /// Error approving verification: {error}
  String nicDeskErrorApproving(String error);

  /// Verification for {name} rejected.
  String nicDeskVerificationRejected(String name);

  /// Error rejecting verification: {error}
  String nicDeskErrorRejecting(String error);

  /// Requested clearer photo from {name}.
  String nicDeskRequestedClearerPhoto(String name);

  /// Error requesting resubmission: {error}
  String nicDeskErrorResubmission(String error);

  /// {count} Pending
  String nicDeskPendingCount(int count);

  /// Sorted by Most Recent
  String get nicDeskSortedMostRecent;

  /// Docs Uploaded
  String get nicDeskDocsUploaded;

  /// Standard Doc
  String get nicDeskStandardDoc;

  /// {percent}% Match
  String nicDeskMatchPercent(int percent);

  /// Western Province, Sri Lanka
  String get nicDeskDefaultLocation;

  /// {location} (Verified GN Division)
  String nicDeskVerifiedGnDivision(String location);

  /// Flagged
  String get nicDeskOcrFlagged;

  /// Match
  String get nicDeskOcrMatch;

  /// Valid
  String get nicDeskOcrValid;

  /// Read-Only Mode: NIC Verification permission required to approve or reject artisan credentials.
  String get nicDeskReadOnlyMode;

  /// No ID
  String get nicDeskNoId;

  /// No image
  String get nicDeskNoImage;

  /// Tap to zoom
  String get nicDeskTapToZoom;

  /// {name} is now {status}.
  String teamAdminNowStatus(String name, String status);

  /// Failed to update status: {error}
  String teamFailedUpdateStatus(String error);

  /// Read-Only View: You are currently operating with Operations Admin privileges. Only Super Admins can add, reconfigure, or revoke administrative access.
  String get teamReadOnlyView;

  /// Status:
  String get teamStatusFilterLabel;

  /// All Statuses
  String get teamAllStatuses;

  /// No administrators found
  String get teamNoAdminsFound;

  /// No admin matching \"{query}\" was found.
  String teamNoAdminMatching(String query);

  /// Try changing your role or status filter.
  String get teamTryChangingFilter;

  /// ADMINISTRATOR
  String get teamColAdministrator;

  /// TIER & ROLE
  String get teamColTierRole;

  /// GRANTED PERMISSIONS
  String get teamColGrantedPermissions;

  /// STATUS
  String get teamColStatus;

  /// ACTIONS
  String get teamColActions;

  /// Managed in Firebase Console
  String get teamManagedInFirebase;

  /// Manage Admin
  String get teamManageAdmin;

  /// Edit Permissions
  String get teamEditPermissions;

  /// Protected
  String get teamProtected;

  /// Active:
  String get teamActiveLabel;

  /// e.g. Weather warning: Heavy rain alert in Western Province...
  String get adminSetBroadcastHint;

  /// Please enter an alert message.
  String get adminSetEnterAlertMessage;

  /// Broadcast alert dispatched and recorded in live operations feed.
  String get adminSetBroadcastDispatched;

  /// Failed to dispatch broadcast: {error}
  String adminSetBroadcastFailed(String error);

  /// {count} Recent Governance & Dispatch Records
  String adminSetRecentRecords(int count);

  /// Export Audit Log (JSON)
  String get adminSetExportAuditLog;

  /// Audit log exported to clipboard as JSON.
  String get adminSetAuditExported;

  /// No platform audit logs recorded yet.
  String get adminSetNoAuditLogs;

  /// System Action
  String get adminSetSystemAction;

  /// AUDIT
  String get adminSetAuditTag;

  /// Recent
  String get adminSetRecent;

  /// Administrator
  String get adminSetAdministratorFallback;

  /// Platform Governance
  String get adminSetPlatformGovernance;

  /// Assigned Permissions:
  String get adminSetAssignedPermissions;

  /// Review administrator actions & access history
  String get adminSetAuditLogsDesc;

  /// Access Denied: Platform audit logs are restricted to Super Admins.
  String get adminSetAuditAccessDenied;

  /// Verify Your Email
  String get verifyYourEmail;

  /// We sent a 6-digit verification code to {email}
  String verifyEmailSubtitle(String email);

  /// Enter Verification Code
  String get enterVerificationCode;

  /// Resend Code
  String get resendCode;

  /// Resend code in {seconds}s
  String resendCodeIn(int seconds);

  /// Verify & Continue
  String get verifyAndContinue;

  /// Verification code expired. Please request a new one.
  String get codeExpired;

  /// Incorrect verification code. Please check and try again.
  String get codeIncorrect;

  /// Email verified successfully!
  String get emailVerifiedSuccess;

  /// My Job Posts
  String get myJobPosts;

  /// Your Posted Jobs ({count})
  String yourPostedJobs(int count);

  /// Post New Job
  String get postNewJob;

  /// No Job Posts Yet
  String get noJobPostsYet;

  /// Post a service request to receive quotes and proposals from verified technicians in your area.
  String get noJobPostsDesc;

  /// Review Quotes ({count})
  String reviewQuotesCount(int count);

  /// Location not specified
  String get locationNotSpecified;

  /// Allow Location Access?
  String get permissionLocationTitle;

  /// HelaService uses your location to connect you with verified tradespeople nearby and calculate accurate, transparent travel costs.
  String get permissionLocationDesc;

  /// Find available technicians closest to your exact location.
  String get permissionLocationBullet1;

  /// Accurate en-route arrival tracking directly to your doorstep.
  String get permissionLocationBullet2;

  /// Fair, distance-based travel rates without hidden costs.
  String get permissionLocationBullet3;

  /// Allow & Continue
  String get permissionAllowAndContinue;

  /// Select District Manually
  String get permissionSelectDistrictManually;

  /// Allow Camera Access?
  String get permissionCameraTitle;

  /// Take photos of the issue to receive accurate, transparent quotes from verified artisans.
  String get permissionCameraDesc;

  /// Capture clear photos of the defect, wiring, or plumbing issue.
  String get permissionCameraBullet1;

  /// Help artisans inspect the repair requirements before quoting.
  String get permissionCameraBullet2;

  /// Stored securely in cloud storage for your job history.
  String get permissionCameraBullet3;

  /// Open Camera
  String get permissionOpenCamera;

  /// Select from Photos & Files?
  String get permissionGalleryTitle;

  /// Upload existing photos or certificates to help verify your credentials or job details.
  String get permissionGalleryDesc;

  /// Select clear certificates, NVQ licenses, or damage photos.
  String get permissionGalleryBullet1;

  /// Used for profile verification and accurate job estimation.
  String get permissionGalleryBullet2;

  /// Stored securely and never shared with unauthorized parties.
  String get permissionGalleryBullet3;

  /// Choose Photos
  String get permissionChoosePhotos;

  /// Location permission is permanently disabled. Please enable it in system settings to detect your exact address.
  String get permissionLocationPermanentlyDisabled;

  /// Location Permission Needed
  String get permissionLocationNeeded;

  /// Users & Bans
  String get navUserManagement;

  /// Search by name, email, phone, or NIC...
  String get searchUsersHint;

  /// Role
  String get filterByRole;

  /// All Roles
  String get allRoles;

  /// All Districts
  String get allDistricts;

  /// Status
  String get filterByStatus;

  /// Suspended
  String get statusSuspended;

  /// Suspend Account
  String get suspendAccount;

  /// Lift Suspension
  String get unbanAccount;

  /// Enter Reason for Suspension
  String get enterBanReason;

  /// e.g. Repeated fraud, abusive conduct, or policy violation
  String get banReasonHint;

  /// Are you sure you want to lift the suspension for this account? The user will immediately regain access to the platform.
  String get confirmUnbanDesc;

  /// Account has been suspended.
  String get userSuspendedSnack;

  /// Account access has been restored.
  String get userRestoredSnack;

  /// Total Users
  String get totalUsers;

  /// Active Customers
  String get activeCustomers;

  /// Active Providers
  String get activeProviders;

  /// Suspended Accounts
  String get suspendedAccounts;

  /// No users found matching your filters
  String get noUsersFound;

  /// View, filter, and moderate customers and service providers across Sri Lanka.
  String get navUserManagementSubtitle;

  /// Customers
  String get filterCustomers;

  /// Providers
  String get filterProviders;

  /// Admins
  String get filterAdmins;

  /// Filter by District
  String get filterByDistrictTitle;

  /// Search district...
  String get searchDistrictHintText;

  /// Are you sure you want to suspend this user? The user will be immediately logged out and blocked from logging in.
  String get suspendUserConfirmDesc;

  /// Please enter a suspension reason.
  String get pleaseEnterSuspensionReason;

  /// Abusive communication
  String get presetAbusiveComm;

  /// Fraudulent activity
  String get presetFraudActivity;

  /// Failed dispute resolution
  String get presetFailedDispute;

  /// Policy violation
  String get presetPolicyViolation;

  /// Reason:
  String get reasonLabel;

  /// Suspended by Administrator
  String get suspendedByAdmin;

  /// Zoom In
  String get zoomIn;

  /// Zoom Out
  String get zoomOut;

  /// Recenter Map
  String get recenterMap;

  /// Super Admin accounts cannot be suspended.
  String get superAdminCannotBeSuspended;

  /// Open settings
  String get openSettings;

  /// OK
  String get ok;

  /// Camera access is permanently disabled. Please enable it in Settings to capture photos.
  String get permissionCameraPermanentlyDisabled;

  /// Camera access is disabled. Please enable it in App Settings.
  String get permissionCameraDisabled;

  /// Gallery access is permanently disabled. Please enable it in Settings.
  String get permissionGalleryPermanentlyDisabled;

  /// Photo access is disabled. Please enable it in App Settings.
  String get permissionGalleryDisabled;

  /// Enable Live Service Notifications?
  String get permissionNotificationTitle;

  /// Get real-time alerts when technicians accept your jobs, send quotes, or arrive at your location.
  String get permissionNotificationDesc;

  /// Immediate alerts when an artisan accepts your job or submits a quote.
  String get permissionNotificationBullet1;

  /// Live tracking updates when your technician is en-route.
  String get permissionNotificationBullet2;

  /// Direct chat and urgent service dispatch alerts.
  String get permissionNotificationBullet3;

  /// Enable Notifications
  String get permissionEnableNotifications;

  /// Not Now
  String get permissionNotNow;

  /// Notification Permission Needed
  String get permissionNotificationNeeded;

  /// Notifications are disabled in device settings. Please enable them to receive job alerts.
  String get permissionNotificationPermanentlyDisabled;

  /// No matches found
  String get noMatchesFound;

  /// Select Option
  String get selectOption;

  /// Admin Approval Required
  String get proApprovalRequiredTitle;

  /// Your service provider account is awaiting administrative verification. To ensure safety and trust, job alerts and active bidding will be unlocked once approved.
  String get proApprovalRequiredDesc;

  /// Verification Status
  String get proVerificationStatus;

  /// Under Administrative Review
  String get proStatusPendingReview;

  /// Action Required: Submit Verification
  String get proStatusActionRequired;

  /// Verification Rejected
  String get proStatusRejected;

  /// Complete NIC Verification
  String get proSubmitNicAction;

  /// Refresh Status
  String get proRefreshStatus;

  /// Checking status...
  String get proCheckingStatus;

  /// Access Granted!
  String get proApprovalGrantedTitle;

  /// Congratulations! Your account has been approved by Admin. You now have full access to accept jobs, submit quotes, and manage your services.
  String get proApprovalGrantedDesc;

  /// Enter Dashboard
  String get proGetStarted;

  /// Provider Alerts
  String get proNotificationsTitle;

  /// No notifications at this time
  String get proNoNotifications;

  /// Mark all as read
  String get proMarkAllRead;

  /// Report to Admin
  String get reportToAdmin;

  /// Report / File Dispute
  String get reportIssueTitle;

  /// Submit an official complaint about this conversation or user. Our administrative team will review the chat and take appropriate action.
  String get reportIssueDesc;

  /// Select a Reason
  String get reportReasonPrompt;

  /// Describe the incident or reason in detail...
  String get reportNotesPrompt;

  /// Submit Complaint to Admin
  String get reportSubmitButton;

  /// Submitting...
  String get reportSubmitting;

  /// Complaint successfully submitted to Admin.
  String get reportSuccessSnack;

  /// Admin Support & Help Desk
  String get adminSupportChannelTitle;

  /// Direct live support, dispute mediation & assistance
  String get adminSupportChannelSubtitle;

  /// File Formal Ticket
  String get fileFormalTicket;

  /// Cancel Booking / Quote
  String get cancelBookingOrQuote;

  /// Are you sure you want to cancel this booking/quote?
  String get cancelBookingPrompt;

  /// Please select a reason for cancellation
  String get cancellationReasonPrompt;

  /// Customer requested cancellation
  String get cancelReasonCustomerRequest;

  /// Provider is unavailable
  String get cancelReasonProviderUnavailable;

  /// Schedule conflict
  String get cancelReasonScheduleConflict;

  /// Price or rate disagreement
  String get cancelReasonPriceDispute;

  /// Other reason
  String get cancelReasonOther;

  /// Confirm Cancellation
  String get confirmCancellation;

  /// Booking cancelled successfully
  String get bookingCancelledSuccess;

  /// Repost Job
  String get repostJob;

  /// Are you sure you want to repost this job? It will be re-opened for new quotes from nearby providers.
  String get repostJobConfirm;

  /// Job successfully reposted!
  String get repostJobSuccess;

  /// Delete Job
  String get deleteJob;

  /// Are you sure you want to permanently delete this job request? This cannot be undone.
  String get deleteJobConfirm;

  /// Job request deleted
  String get deleteJobSuccess;

  /// Chat with Provider
  String get chatWithProvider;

  /// Didn\'t receive the email?
  String get otpCheckSpamHintTitle;

  /// Please check your Spam or Junk mail folder. Verification emails may occasionally be filtered there by your email service.
  String get otpCheckSpamHintDesc;

  /// Signing out...
  String get loggingOut;

  /// Chat
  String get navMessages;

  /// Closest First
  String get closestFirst;

  /// Newest First
  String get newestFirst;

  /// All
  String get allDistances;

  /// < 5 km
  String get within5Km;

  /// < 10 km
  String get within10Km;

  /// < 25 km
  String get within25Km;

  /// View Map
  String get viewOnMap;

  /// Nearby
  String get nearbyTag;

  /// Moderate
  String get moderateTag;

  /// Extended
  String get extendedTag;

  /// ~{mins} mins drive
  String estTravelTime(int mins);

  /// No jobs found within selected radius
  String get noJobsInRadius;

  /// Filter by Role & Status
  String get filterRoleAndStatus;

  /// All Statuses
  String get allStatuses;

  /// Clear Filters
  String get clearFilters;

  /// All Admins
  String get roleAllAdmins;

  /// Become a Service Provider
  String get becomeServiceProvider;

  /// Back to Customer Dashboard
  String get backToCustomerDashboard;

  /// Cancel Registration
  String get cancelRegistration;

  /// Platform Maintenance & Data Inspection Mode
  String get roleSwitchAdminOnlyDesc;

  /// Admin Preview Mode · Viewing Service Provider Interface
  String get adminProviderPreviewNotice;

  /// Resubmit Verification
  String get resubmitVerification;

  /// Verification Not Approved
  String get verificationNotApprovedTitle;

  /// Your verification was not approved by administration. Please review your documents and resubmit.
  String get verificationNotApprovedBody;

  /// Verification Submitted · Under Review
  String get proVerificationPendingReview;

  /// How do you want to use HelaService?
  String get chooseRoleTitle;

  /// Select your account role to continue setting up your profile.
  String get chooseRoleSubtitle;

  /// I need a service
  String get roleCustomerTitle;

  /// Find trusted local technicians, post job requests, or request emergency assistance anywhere in Sri Lanka.
  String get roleCustomerDesc;

  /// Customer
  String get roleCustomerBadge;

  /// Transparent Rates
  String get roleCustomerPerk1;

  /// Live GPS Tracking
  String get roleCustomerPerk2;

  /// Direct Quotes
  String get roleCustomerPerk3;

  /// I offer a service
  String get roleProviderTitle;

  /// Receive nearby customer job requests, submit custom quotes, and expand your service business.
  String get roleProviderDesc;

  /// Service Provider
  String get roleProviderBadge;

  /// Jobs Radar
  String get roleProviderPerk1;

  /// Direct Leads
  String get roleProviderPerk2;

  /// Secure Verification
  String get roleProviderPerk3;

  /// Select Service Location
  String get selectServiceLocation;

  /// Use GPS Location
  String get useCurrentGpsLocation;

  /// Saved Addresses
  String get savedAddresses;

  /// Service Address
  String get serviceAddressLabel;

  /// Enter full street address or location details
  String get serviceAddressHint;

  /// Landmark / Entry Instructions (Optional)
  String get landmarkOrNoteOptional;

  /// e.g. Near yellow gate, second house on the left
  String get landmarkHint;

  /// Save this address for future requests
  String get saveAddressForFuture;

  /// Confirm Location
  String get confirmLocation;

  /// Set Pin on Map to Confirm
  String get selectPinOnMap;

  /// Service
  String get genericService;

  /// Enter reason for suspension...
  String get enterReasonForSuspension;

  /// App Language / භාෂාව / மொழி
  String get appLanguageLabel;

  /// Profile photo (DP) approved!
  String get profilePhotoApproved;

  /// Error approving profile photo: {error}
  String errorApprovingPhoto(String error);

  /// Error approving NIC: {error}
  String errorApprovingNic(String error);

  /// Trade certifications approved!
  String get tradeCertificationsApproved;

  /// Error approving certifications: {error}
  String errorApprovingCertifications(String error);

  /// Approve DP
  String get approveDp;

  /// DP Approved
  String get dpApproved;

  /// Approve NIC (Front+Back)
  String get approveNicBoth;

  /// Approve Certs
  String get approveCerts;

  /// Take Profile Photo
  String get takeProfilePhoto;

  /// Select Profile Photo
  String get selectProfilePhoto;

  /// Failed to complete profile: {error}
  String failedToCompleteProfile(String error);

  /// Service Category
  String get serviceCategory;

  /// Please enter your full name
  String get pleaseEnterFullName;

  /// Failed to set role: {error}
  String failedToSetRole(String error);

  /// Label (e.g. Home, Work, Villa)
  String get savedAddressLabelHint;

  /// Landmark / Note (Optional)
  String get landmarkNoteOptional;

  /// Delete Saved Address
  String get deleteSavedAddress;

  /// Are you sure you want to delete this address?
  String get confirmDeleteSavedAddress;

  /// Add New
  String get addNew;

  /// Set Service Location
  String get setServiceLocation;

  /// Failed to update job location: {error}
  String failedToUpdateJobLocation(String error);

  /// Please select a service location before posting.
  String get pleaseSelectServiceLocation;

  /// Confirm Service Location
  String get confirmServiceLocation;

  /// PIN attempts reset to 0.
  String get pinAttemptsResetZero;

  /// Cannot cancel booking in progress. Please contact support.
  String get cannotCancelInProgressBooking;

  /// Service Verification
  String get serviceVerification;

  /// Rate Service Provider
  String get rateServiceProvider;

  /// Job completed successfully!
  String get jobCompletedSuccessfully;

  /// Verify & Finish
  String get verifyAndFinish;

  /// Call Customer
  String get callCustomer;

  /// Direct Service Booking
  String get directServiceBooking;

  /// Sign-in cancelled by user.
  String get signInCancelledByUser;

  /// Could not detect location: {error}
  String couldNotDetectLocation(String error);

  /// Unauthorized role switch.
  String get unauthorizedRoleSwitch;

  /// Give this 6-digit PIN to the provider once service is completed.
  String get givePinHint;

  /// Direct booking with {providerName}
  String directBookingWith(String providerName);

  /// Direct booking with {providerName}. Note: {note}
  String directBookingWithNote(String providerName, String note);

  /// NIC Approved
  String get nicVerified;

  /// Approved
  String get statusApproved;

  /// Use GPS
  String get useGps;

  /// Location
  String get location;

  /// Delete
  String get delete;

  /// Edit
  String get edit;

  /// Service Date
  String get serviceDate;

  /// Agreed Price
  String get agreedPrice;

  /// PIN Verified on Site
  String get pinVerified;

  /// Service Provider Details
  String get providerDetailsTitle;

  /// Decline
  String get decline;

  /// Did you pay {amount} to {name}?
  String didYouPayAmount(String amount, String name);

  /// Yes, paid
  String get yesPaid;

  /// Report a problem
  String get reportPaymentProblem;

  /// Cash payment confirmed
  String get cashPaymentConfirmed;

  /// Payment disputed: {reason}
  String paymentDisputedWithReason(String reason);

  /// Enter the reason for payment dispute:
  String get disputePaymentPrompt;

  /// e.g. Overcharged, work incomplete, wrong amount
  String get disputePaymentReasonHint;

  /// Submit report
  String get submitDispute;

  /// Pay the provider directly in cash after the job is completed.
  String get payProviderDirectlyTip;

  /// Cash received
  String get cashReceived;

  /// Payment note (optional)
  String get paymentNoteOptional;

  /// e.g. Materials, extra work
  String get paymentNoteHint;

  /// Amount cannot exceed 5x agreed price
  String get finalAmountExceedsLimit;

  /// Waiting confirmation
  String get paymentWaitingConfirmation;

  /// Confirmed
  String get paymentConfirmed;

  /// Disputed
  String get paymentDisputed;

  /// Today
  String get earningsToday;

  /// This Week
  String get earningsThisWeek;

  /// This Month
  String get earningsThisMonth;

  /// Total Earnings
  String get totalEarnings;

  /// Export CSV
  String get exportCsv;

  /// CSV exported successfully
  String get csvExportSuccess;

  /// Completion PIN
  String get pinCode;

  /// Did you reach {name}?
  String didYouReachPerson(String name);

  /// Connected / Answered
  String get callOutcomeAnswered;

  /// No Answer / Busy
  String get callOutcomeNoAnswer;

  /// Wrong Number
  String get callOutcomeWrongNumber;

  /// Phone calls become available once a quote is accepted.
  String get callRequiresAcceptedQuote;

  /// Phone Call Audit Logs
  String get callLogsTitle;

  /// Caller
  String get callLogCaller;

  /// Callee
  String get callLogCallee;

  /// Call Outcome
  String get callLogOutcome;

  /// Job Timeline
  String get bookingTimelineTitle;

  /// No events recorded yet
  String get noTimelineEvents;

  /// View Timeline
  String get viewTimeline;

  /// Admin Action Logs
  String get adminActionLogsTitle;

  /// Immutable audit trail of administrator actions
  String get adminAuditTrailSubtitle;

  /// No admin audit logs recorded yet
  String get noAdminLogsFound;

  /// Users
  String get filterUsers;

  /// Bookings
  String get filterBookings;

  /// System
  String get filterSystem;

  /// No entries to export
  String get noEntriesToExport;

  /// Delete Account
  String get deleteAccountTitle;

  /// Are you sure you want to delete your account? All your personal profile data, active requests, and history will be permanently erased. This cannot be undone.
  String get deleteAccountConfirmation;

  /// Permanently Delete
  String get deleteAccountConfirmAction;

  /// Privacy Policy
  String get privacyPolicy;

  /// Terms of Service
  String get termsOfService;

  /// Photo
  String get photo;

  /// Send Photo
  String get sendPhoto;

  /// Uploading image...
  String get uploadingImage;

  /// Failed to upload image
  String get failedToUploadImage;

  /// View Photo
  String get viewPhoto;

  /// ASAP / Emergency
  String get bookingTypeAsap;

  /// Scheduled Slot
  String get bookingTypeScheduled;

  /// Select Date
  String get selectScheduledDate;

  /// Select Time Slot
  String get selectTimeSlot;

  /// Morning (8:00 AM - 12:00 PM)
  String get slotMorning;

  /// Afternoon (12:00 PM - 4:00 PM)
  String get slotAfternoon;

  /// Evening (4:00 PM - 8:00 PM)
  String get slotEvening;

  /// Reschedule Booking
  String get rescheduleBooking;

  /// Propose New Time
  String get proposeNewTime;

  /// Reason for reschedule
  String get rescheduleReasonPrompt;

  /// e.g. Traffic delay, customer requested later time
  String get rescheduleReasonHint;

  /// Request Reschedule
  String get submitRescheduleRequest;

  /// Reschedule Proposed
  String get rescheduleProposalBanner;

  /// Accept Reschedule
  String get acceptReschedule;

  /// Decline
  String get declineReschedule;

  /// Cancel Proposal
  String get cancelRescheduleProposal;

  /// Expired
  String get expiredPill;

  /// Working Hours & Schedule
  String get workingHoursTitle;

  /// Service Coverage Radius
  String get serviceRadiusTitle;

  /// Maximum distance you will travel for jobs
  String get serviceRadiusSubtitle;

  /// Monday
  String get dayMonday;

  /// Tuesday
  String get dayTuesday;

  /// Wednesday
  String get dayWednesday;

  /// Thursday
  String get dayThursday;

  /// Friday
  String get dayFriday;

  /// Saturday
  String get daySaturday;

  /// Sunday
  String get daySunday;

  /// Start Time
  String get openTime;

  /// End Time
  String get closeTime;

  /// Closed
  String get closedDay;

  /// Weekdays (8 AM - 6 PM)
  String get presetWeekdays;

  /// All 7 Days (8 AM - 8 PM)
  String get presetAllDays;

  /// Open 24/7
  String get preset247;

  /// Unavailable now
  String get unavailableNow;

  /// Outside working hours
  String get outsideWorkingHours;

  /// Working hours updated successfully
  String get savedScheduleSuccess;

  /// Service radius updated
  String get savedRadiusSuccess;

  /// {radius} km radius
  String serviceRadiusKm(int radius);

  /// Reschedule proposal pending response
  String get rescheduleRequestedNotice;

  /// Save Changes
  String get saveChanges;

  /// Before and after service inspection photos
  String get jobPhotosSubtitle;

  /// Before Service
  String get beforePhotos;

  /// After Service
  String get afterPhotos;

  /// Add Before Photo
  String get addBeforePhoto;

  /// Add After Photo
  String get addAfterPhoto;

  /// No before photos uploaded yet
  String get noBeforePhotos;

  /// No after photos uploaded yet
  String get noAfterPhotos;

  /// Portfolio & Past Work
  String get portfolioTitle;

  /// Showcase your completed projects to customers
  String get portfolioSubtitle;

  /// Add Showcase Item
  String get addPortfolioItem;

  /// Project Title
  String get portfolioItemTitle;

  /// e.g. Living room full rewiring
  String get portfolioItemTitleHint;

  /// Description
  String get portfolioItemDesc;

  /// Brief details about the work done
  String get portfolioItemDescHint;

  /// Upload Photo
  String get uploadPhoto;

  /// Photo uploaded successfully
  String get photoUploadedSuccess;

  /// Showcase item added successfully
  String get portfolioItemAdded;

  /// Delete this portfolio item?
  String get deletePortfolioConfirm;

  /// No portfolio items added yet
  String get noPortfolioItems;

  /// Category
  String get categoryLabel;

  /// Select a category
  String get selectCategoryPrompt;

  /// NEW
  String get newProviderBadge;

  /// Block User
  String get blockUserTitle;

  /// Are you sure you want to block this user? They will not be able to send you requests or message you.
  String get blockUserConfirm;

  /// Block User
  String get blockUserAction;

  /// Unblock
  String get unblockUserAction;

  /// User has been blocked
  String get userBlockedSuccess;

  /// User has been unblocked
  String get userUnblockedSuccess;

  /// Report User
  String get reportUserTitle;

  /// Reason for Report
  String get reportReasonLabel;

  /// Inappropriate or abusive behavior
  String get reportReasonHarassment;

  /// Spam or unwanted advertising
  String get reportReasonSpam;

  /// Fraud, overcharging, or scam
  String get reportReasonFraud;

  /// No-show or abandoned service
  String get reportReasonNoShow;

  /// Safety or trust concern
  String get reportReasonSafety;

  /// Other violation
  String get reportReasonOther;

  /// Describe what happened in detail...
  String get reportDetailsHint;

  /// Also block this user
  String get reportAlsoBlock;

  /// Report submitted. Our support team will review this shortly.
  String get reportSubmittedSuccess;

  /// You are currently offline. Check your connection.
  String get offlineBannerText;

  /// Retry
  String get retryAction;

  /// Update Required
  String get forceUpdateTitle;

  /// A newer version of HelaService with critical improvements is required to continue.
  String get forceUpdateMessage;

  /// Update Now
  String get updateNowAction;

  /// Urgent Help & Emergency Dispatch
  String get emergencyDispatchTitle;

  /// Find and call out verified artisans within 15km right now
  String get emergencyDispatchSubtitle;

  /// Scanning nearby emergency artisans...
  String get scanningNearbyProviders;

  /// Dispatch search window
  String get dispatchTimerLabel;

  /// No emergency artisans found within 15km right now
  String get noEmergencyProvidersFound;

  /// Try selecting a different trade category or post an urgent job request.
  String get noEmergencyProvidersDesc;

  /// Emergency / Callout Rate
  String get emergencyCalloutRate;

  /// approx {mins} mins away
  String emergencyEtaApprox(int mins);

  /// {dist} km away
  String distanceKmAway(String dist);

  /// Dispatch Now
  String get requestEmergencyCallout;

  /// Confirm Emergency Callout
  String get confirmEmergencyBookingTitle;

  /// An emergency dispatch request will be sent to {name} immediately. Rate: LKR {rate}.
  String confirmEmergencyBookingDesc(String name, String rate);

  /// Emergency Service Location
  String get emergencyAddressPrompt;

  /// Emergency details (optional)
  String get emergencyNotesPrompt;

  /// e.g. Water pipe burst in kitchen, power outage in main circuit
  String get emergencyNotesHint;

  /// Sri Lanka Emergency Hotlines
  String get emergencyHotlinesTitle;

  /// Police Emergency (119)
  String get hotlinePolice;

  /// Suwa Seriya Ambulance (1990)
  String get hotlineAmbulance;

  /// Fire & Rescue (110)
  String get hotlineFire;

  /// Urgent Repair or Breakdown?
  String get urgentHelpBannerTitle;

  /// Instant 15km artisan dispatch for water leaks, power failures, or locksmith emergencies.
  String get urgentHelpBannerDesc;

  /// Get Urgent Help
  String get urgentHelpBannerAction;

  /// My Rates
  String get myRates;

  /// Standard Service Rates
  String get rateCardTitle;

  /// Daily Rate
  String get dailyRate;

  /// Per Km Travel Rate
  String get perKmTravelRate;

  /// Inspection / Visit Fee
  String get standardVisitFee;

  /// Firm Price
  String get quoteTypeFirm;

  /// Estimated Range
  String get quoteTypeEstimate;

  /// Inspection / Visit Only
  String get quoteTypeInspect;

  /// Price Revision Proposed
  String get priceRevisionProposed;

  /// Extra Work / Materials
  String get extraWorkRequested;

  /// This booking was completed as an Inspection / Visit only. Standard reviews are disabled.
  String get visitOnlyCompletedNote;

  /// Normal Job Completion
  String get completionTypeNormal;

  /// Inspection / Visit Only
  String get completionTypeVisitOnly;

  /// Hourly Rate
  String get hourlyRate;

  /// Your Usual Rates
  String get yourUsualRates;

  /// At least one rate is required. Used when customers request quotes.
  String get yourUsualRatesSubtitle;

  /// e.g. 3500 (1 - 100,000)
  String get dailyRateHint;

  /// e.g. 500 (1 - 20,000)
  String get hourlyRateHint;

  /// e.g. 80 (1 - 1,000)
  String get perKmRateHint;

  /// Optional, e.g. 1000 (0 - 20,000)
  String get visitFeeOptionalHint;

  /// At least one rate (daily, hourly, or per km) is required.
  String get atLeastOneRateRequired;

  /// Daily rate must be between LKR 1 and 100,000
  String get dailyRateRangeError;

  /// Hourly rate must be between LKR 1 and 20,000
  String get hourlyRateRangeError;

  /// Per km rate must be between LKR 1 and 1,000
  String get perKmRateRangeError;

  /// Visit fee must be between LKR 0 and 20,000
  String get visitFeeRangeError;

  /// Within agreed price
  String get withinAgreedPrice;

  /// Visit fee only
  String get visitFeeOnly;

  /// Approved Extras
  String get approvedExtrasBreakdown;

  /// Initial Quoted / Estimated Price
  String get initialEstimateLabel;

  /// Agreed Price
  String get revisedAgreedPrice;

  /// Final Amount to Pay
  String get finalAmountToPay;

  /// Price Matches Quote
  String get priceMatchesQuote;

  /// Propose New Price
  String get proposeNewPrice;

  /// Propose Revised Price
  String get proposeRevisedPrice;

  /// Billing Unit
  String get billingUnit;

  /// Fixed Job
  String get billingUnitFixed;

  /// Hourly
  String get billingUnitHour;

  /// Daily
  String get billingUnitDay;

  /// Unit Rate (LKR)
  String get unitRateLkr;

  /// Quantity
  String get quantityLabel;

  /// Reason for Price Change
  String get priceChangeReason;

  /// e.g. Additional concealed pipeline damage discovered
  String get priceChangeReasonHint;

  /// Total Revised Price
  String get totalRevisedPrice;

  /// Submit Proposal
  String get submitProposal;

  /// Add Extra Work / Item
  String get addExtraWorkItem;

  /// Description
  String get extraDescription;

  /// e.g. Extra 2m PVC pipe & joint fitting
  String get extraDescriptionHint;

  /// Amount (LKR)
  String get extraAmountLkr;

  /// Propose Extra
  String get proposeExtra;

  /// Waiting for customer approval
  String get awaitingCustomerApproval;

  /// Price proposal sent to customer for approval
  String get priceProposalSent;

  /// Extra work proposal sent to customer
  String get extraProposalSent;

  /// Price confirmed matches original quote
  String get priceConfirmedMatches;

  /// Price proposal rejected
  String get priceProposalRejected;

  /// Price proposal approved
  String get priceProposalApproved;

  /// My Rate Card
  String get myRateCard;

  /// Configure your standard rates shown to customers and used in quotes.
  String get rateCardSubtitle;

  /// Save Rates
  String get saveRates;

  /// Rate card updated successfully
  String get rateCardUpdatedSuccess;

  /// Travel Rate
  String get travelRate;

  /// Pricing & Standard Rates
  String get pricingStandardRates;

  /// Retry Upload
  String get uploadRetry;

  /// Large File Warning
  String get largeMediaWarningTitle;

  /// File is large (>20MB). Uploading over mobile data may take time and consume data. Proceed?
  String get largeMediaWarningMessage;

  /// Proceed
  String get proceed;

  /// Something went wrong. Please try again.
  String get somethingWentWrong;

  /// Customer did not agree. Collect only the visit fee: LKR {amount}
  String customerDidNotAgreeVisitOnly(String amount);

  /// Complete Visit Only
  String get completeVisitOnly;

  /// Please enter a reason for the price revision
  String get priceRevisionReasonRequired;

  /// Please check rate and quantity values
  String get checkRateAndQuantity;

  /// Please enter a description (max 300 characters)
  String get extraDescriptionLimit;

  /// Please enter an amount between LKR 1 and 1,000,000
  String get extraAmountLimit;

  /// Notes must be 500 characters or less
  String get notesLimit500;

  /// Please enter a valid visit fee (LKR 1 - 20,000)
  String get validVisitFeePrompt;

  /// Please enter a valid unit rate (minimum LKR 1)
  String get validUnitRatePrompt;

  /// Please enter a valid quantity (0.5 to 60)
  String get validQuantityPrompt;

  /// Materials estimate must be between LKR 0 and 1,000,000
  String get materialsEstimateLimit;

  /// Visit / Inspection Fee:
  String get visitInspectionFee;

  /// Materials Estimate:
  String get materialsEstimateColon;

  /// Add Issue Video (Max 120s)
  String get addIssueVideoMax;

  /// Record Video
  String get recordVideo;

  /// Failed to pick video. Please try again.
  String get errorPickingVideo;

  /// Video of Issue (Optional)
  String get videoOfIssueOptional;

  /// Job Video
  String get jobVideo;

  /// Video Clip
  String get videoClip;

  /// Failed to play video
  String get failedToPlayVideo;

  /// Failed to update rates. Please try again.
  String get failedToUpdateRates;

  /// This quote is outdated, ask the provider to send a new one
  String get quoteOutdatedDeclined;

  /// You are about {distance} m away from the job location.
  String youAreMetersAway(String distance);

  /// I\'m here, but GPS is wrong
  String get imHereGpsWrong;

  /// Slide to claim arrival
  String get slideToClaimArrival;

  /// Arrival claimed. Waiting for customer confirmation...
  String get waitingCustomerConfirmation;

  /// Customer says you have not arrived. Please check the location or call the customer.
  String get arrivalDeniedProviderNotice;

  /// Claim Arrival Again
  String get claimAgainArrival;

  /// Maximum arrival claims reached (3/3).
  String get maxClaimsReached;

  /// Customer has not responded after 10 minutes.
  String get customerDidNotAnswer;

  /// Start Job (GPS Verified)
  String get startJobVerifiedGps;

  /// Call customer to confirm arrival
  String get callCustomerToConfirm;

  /// {providerName} says they have arrived. Are they with you?
  String providerSaysArrived(String providerName);

  /// Their GPS shows {distance} m away.
  String providerGpsShowsAway(String distance);

  /// Yes, they\'re here
  String get yesTheyAreHere;

  /// No, not here
  String get noNotHere;

  /// Provider didn\'t come
  String get providerDidNotCome;

  /// Report Provider No-Show?
  String get confirmNoShowTitle;

  /// This will cancel the booking because the service provider did not arrive.
  String get confirmNoShowMessage;

  /// Please select a location with GPS coordinates to book this service.
  String get locationRequiredToBook;

  /// Mocked GPS Detected
  String get arrivalMockedFlag;

  /// Claimed Outside Zone
  String get arrivalOutsideZoneFlag;

  /// Customer Denied Arrival
  String get arrivalDeniedFlag;

  /// Provider No-Show
  String get noShowFlag;

  /// GPS indicates you are outside the job zone ({distance} m away). Do you want to submit an arrival claim anyway?
  String gpsOutsideZoneAlert(String distance);

  /// Proceed Anyway
  String get proceedAnyway;

  /// Arrival claim submitted. The customer has been notified.
  String get claimSuccessNotified;

  /// Complete Job (Enter Customer PIN)
  String get completeJobEnterPin;

  /// Provider no-show reported. Booking cancelled.
  String get noShowReportedSuccess;

  /// 90-Day Reliability & Arrival Verification
  String get providerReliability90Days;

  /// No-Shows
  String get providerNoShowsCount;

  /// Arrival Denials
  String get providerArrivalDenialsCount;

  /// Mocked GPS
  String get providerMockedGpsCount;

  /// Outside Zone
  String get providerOutsideZoneCount;

  /// The scheduled time has passed. Please choose a new date and time.
  String get scheduledTimePassedPrompt;

  /// Update Scheduled Time
  String get chooseNewScheduleTitle;

  /// Revised on-site estimate
  String get revisedEstimateDefault;

  /// Please enter 6 digits
  String get pleaseEnterSixDigits;

  /// Customer location not available
  String get customerLocationNotAvailableTitle;

  /// Exact GPS coordinates were not provided for this job. Contact the customer below to coordinate arrival.
  String get customerLocationNotAvailableDesc;

  /// Location Required
  String get locationRequiredTitle;

  /// This job has no location. Please set the location and repost.
  String get jobNoLocationRepost;

  /// Hello {providerName}, I have accepted your quote (LKR {price}). Let\'s coordinate the job details!
  String quoteAcceptedChatMessage(String providerName, String price);

  /// Please enter service location address
  String get pleaseEnterServiceLocation;

  /// Optimizing video (max 120s)...
  String get optimizingVideoNotice;

  /// Add Short Video
  String get addShortVideo;

  /// Up to 120s explaining the repair or issue
  String get addShortVideoSubtitle;

  /// No services available yet
  String get noServicesAvailableYet;

  /// Edit Saved Address
  String get editSavedAddress;

  /// Sign in to manage saved addresses.
  String get signInToManageSavedAddresses;

  /// No saved addresses yet. Add home or work addresses for one-tap booking.
  String get noSavedAddressesSubtitle;

  /// Offer your trade skills, receive jobs, and earn more
  String get becomeProviderSubtitle;

  /// Switch to Provider Mode
  String get switchToProvider;

  /// Switch back to your Service Provider workspace
  String get switchToProviderSubtitle;

  /// Admin Inspection Mode
  String get adminInspectionMode;

  /// Viewing provider workspace with administrative bypass.
  String get adminInspectionModeDesc;

  /// Set standard visit and hourly rates
  String get setStandardRatesSubtitle;

  /// Quote Accepted!
  String get quoteAcceptedTitle;

  /// Customer confirmed this booking
  String get customerConfirmedBooking;

  /// Please enter a project title
  String get enterProjectTitle;

  /// Please select a photo for this showcase item
  String get selectPhotoForShowcase;

  /// Failed to save showcase item: {error}
  String failedToSaveShowcase(String error);

  /// Quote Type
  String get quoteType;

  /// Inspection quote includes on-site visit fee and travel cost. Total job price will be agreed upon arrival.
  String get inspectionQuoteNotice;

  /// Materials Estimate (Optional)
  String get materialsEstimateOptional;

  /// Est. Distance (km)
  String get estDistanceKm;

  /// Travel Rate (LKR/km)
  String get travelRateLkrKm;

  /// Total Quoted Price
  String get totalQuotedPrice;

  /// Travel Fee
  String get travelFee;

  /// Selected
  String get statusSelected;

  /// Provider base location is required. Please set GPS/Map pin and address.
  String get providerBaseLocationRequired;

  /// Base Workshop / Service Location *
  String get baseWorkshopLocation;

  /// Required for nearest provider dispatch calculations
  String get baseLocationDispatchNotice;

  /// Suspension Reason:
  String get suspensionReasonLabel;

  /// Sign up in seconds to access verified roadside and home service experts across Sri Lanka.
  String get registerBannerSubtitle;

  /// Sort Order
  String get sortOrder;

  /// Is Live
  String get isLive;

  /// Edit Category
  String get editCategory;

  /// Price History & Audit
  String get priceHistoryAudit;

  /// Final Charged Amount:
  String get finalChargedAmount;

  /// Are you sure you want to suspend customer \"{name}\"? Their account will be locked and they will be barred from creating requests or accessing the platform.
  String suspendCustomerConfirmPrompt(String name);

  /// Unable to load photo
  String get unableToLoadPhoto;

  /// New Time:
  String get newTimeLabel;

  /// Note:
  String get noteLabel;

  /// Reset PIN attempts
  String get resetPinAttempts;

  /// No Service History Yet
  String get noServiceHistoryYet;

  /// Completed and past bookings will appear here.
  String get noServiceHistorySubtitle;

  /// Your Rating & Review
  String get yourRatingReview;

  /// Please sign in to view your bookings
  String get signInToViewBookings;

  /// Pending Admin Approval · Unavailable for hire
  String get pendingAdminApprovalUnavailable;

  /// Direct Contact & Fast Quotes
  String get directContactFastQuotes;

  /// Verified phone available
  String get verifiedPhoneAvailable;

  /// Official Support
  String get officialSupport;

  /// Failed to save schedule
  String get failedToSaveSchedule;

  /// Confirmed
  String get statusConfirmed;

  /// En Route
  String get statusEnRoute;

  /// Declined
  String get statusDeclined;

  /// Assigned
  String get statusAssigned;

  /// Scheduled
  String get statusScheduled;

  /// Completion PIN:
  String get completionPinLabel;

  /// Photo
  String get chatPhotoMessage;

  /// Your full name
  String get hintFullName;

  /// Email address
  String get hintEmail;

  /// Mobile number
  String get hintPhone;

  /// e.g. Electrician, Plumber
  String get hintCategorySearch;

  /// e.g. 3500
  String get hintAmount;

  /// 12 digits, or 9 digits + V
  String get hintNicFormat;

  /// e.g. Sanduni Perera
  String get hintCustomerName;

  /// Email address
  String get hintProviderEmail;

  /// e.g. Ruwan Jayasundara
  String get hintAdminName;

  /// Price Status:
  String get priceStatusLabel;

  /// Proposed:
  String get proposedLabel;

  /// Service Provider
  String get roleServiceProvider;

  /// Super Admin
  String get roleSuperAdmin;

  /// Support Admin
  String get roleSupportAdmin;

  /// Operations Admin
  String get roleOperationsAdmin;

  /// General Dispute
  String get generalDispute;

  /// Your NIC identity has been approved by admin. You can receive all job bids.
  String get nicApprovedMessage;

  /// Your verification submission is being reviewed by HelaService administration.
  String get nicUnderReviewMessage;

  /// Amount: LKR {amount}
  String amountLkrLabel(Object amount);

  /// Search category...
  String get searchCategoryHint;

  /// Search district...
  String get searchDistrictHint;

  /// Charge visit / inspection fee only. Job will be completed without full service.
  String get visitFeeOnlyDescription;

  /// Provider Verification Pending
  String get providerVerificationPending;

  /// Send Quote · LKR {amount}
  String sendQuoteLkr(Object amount);

  /// Custom Quote
  String get customQuote;

  /// Past service
  String get pastService;

  /// You (En Route)
  String get youEnRouteLabel;

  /// House no., street, town
  String get hintJobAddress;

  /// Category name
  String get hintCategoryName;

  /// Amount in LKR
  String get hintAmountLkr;

  /// Provider suspended reason in complaint investigation dialog
  ///
  /// In en, this message translates to:
  /// **'Suspended following complaint investigation: \"{reason}\"'**
  String complaintInvestigationSuspended(String reason);

  /// Administrative suspension due to policy violations
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

  /// 0 Registered
  String get zeroRegistered;

  /// 0 Online Now
  String get zeroOnlineNow;

  /// Market Rate
  String get marketRate;

  /// Snack bar category updated successfully
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" updated successfully.'**
  String categoryUpdatedSuccess(String name);

  /// Manual Dispatch Assigned
  String get manualDispatchAssigned;

  /// Dispatch
  String get dispatchTitle;

  /// Re-assign
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

  /// Customer
  String get ledgerCustomer;

  /// Flagged
  String get verificationFlagged;

  /// Match
  String get verificationMatch;

  /// Valid
  String get verificationValid;

  /// A clear photo builds trust with customers.
  String get profileTrustPhotoRationale;

  /// Choose a photo from your gallery.
  String get profileChooseGalleryPhoto;

  /// Capture NIC Front
  String get captureNicFront;

  /// Capture NIC Back
  String get captureNicBack;

  /// Take a clear, well-lit photo of your National ID.
  String get captureNicPrompt;

  /// Select NIC Front
  String get selectNicFront;

  /// Select NIC Back
  String get selectNicBack;

  /// Select your National Identity Card photo from gallery.
  String get selectNicGalleryPrompt;

  /// Complete Provider Profile
  String get completeProviderProfileTitle;

  /// Providing services across Sri Lanka
  String get providingServicesAcrossSriLanka;

  /// Requesting home & domestic services
  String get requestingDomesticServices;

  /// 7X XXXXXXX
  String get phonePlaceholderPattern;

  /// Select Service Category
  String get selectServiceCategory;

  /// Update Pin
  String get updatePinButton;

  /// Pick on Map
  String get pickOnMapButton;

  /// Workshop / Operating Address *
  String get workshopAddressRequiredLabel;

  /// Operating address is required
  String get operatingAddressRequiredError;

  /// Complete Provider Registration
  String get completeProviderRegistration;

  /// Save Profile
  String get saveProfile;

  /// Phone not set
  String get phoneNotSet;

  /// Home
  String get addressLabelHome;

  /// Work
  String get addressLabelWork;

  /// Other
  String get addressLabelOther;

  /// Video exceeds maximum allowed 120s (2 minutes)
  String get videoExceedsMax120s;

  /// Error processing video upload
  ///
  /// In en, this message translates to:
  /// **'Failed to process video: {error}'**
  String failedToProcessVideo(String error);

  /// Job Location
  String get jobLocationLabel;

  /// Tap to pick via GPS, map pin, or saved addresses
  String get selectJobLocationSubtitle;

  /// Change
  String get changeButton;

  /// Set Pin
  String get setPinButton;

  /// Set Pin Here
  String get setPinHereButton;

  /// Upload failed after 3 attempts.
  String get uploadFailedAttempts;

  /// Past service
  String get bookingPastService;

  /// Completed
  String get bookingStatusCompleted;

  /// Not specified
  String get bookingNotSpecified;

  /// Scheduled
  String get bookingStatusScheduled;

  /// Quantity with unit label
  ///
  /// In en, this message translates to:
  /// **'Quantity ({unit})'**
  String quantityUnitLabel(String unit);

  /// LKR / hr
  String get rateHourlyUnit;

  /// LKR / day
  String get rateDailyUnit;

  /// LKR / km
  String get rateTravelUnit;

  /// Form
  String get pickerTabForm;

  /// Map Pin
  String get pickerTabMapPin;

  /// Camera access is required to take your profile photo.
  String get cameraPermissionRationale;

  /// Photo library access is required to select your profile photo.
  String get photoLibraryPermissionRationale;

  /// • Profile name, phone number, and account credentials\n• Job descriptions, addresses, and service locations\n• Verification documents (NIC, business licenses)\n• Messages and communications through the platform
  String get privacyDataCollectionPoints;

  /// Booking Created
  String get timelineBookingCreated;

  /// Booking Accepted
  String get timelineBookingAccepted;

  /// Arrival Claimed
  String get timelineArrivalClaimed;

  /// Arrival Denied
  String get timelineArrivalDenied;

  /// Auto-Started
  String get timelineAutoStarted;

  /// Visit Fee Only
  String get timelineVisitFeeOnly;

  /// Price Proposed
  String get timelinePriceProposed;

  /// Price Approved
  String get timelinePriceApproved;

  /// Price Rejected
  String get timelinePriceRejected;

  /// Extra Requested
  String get timelineExtraRequested;

  /// Extra Approved
  String get timelineExtraApproved;

  /// Extra Rejected
  String get timelineExtraRejected;

  /// Payment Confirmed
  String get timelinePaymentConfirmed;

  /// Payment Disputed
  String get timelinePaymentDisputed;

  /// No Show Reported
  String get timelineNoShowReported;

  /// Before Photo Added
  String get timelineBeforePhotoAdded;

  /// After Photo Added
  String get timelineAfterPhotoAdded;

  /// Open for Quotes
  String get statusOpen;

  /// Dispatched
  String get statusDispatched;

  /// Select Job Location
  String get selectJobLocation;

  /// Tap to pick via GPS, map pin, or saved addresses
  String get tapToPickLocationDesc;

  /// Set Pin
  String get setPin;

  /// Visit Fee: LKR {visitFee} · Hourly: LKR {hourlyRate}
  String rateCardSummary(Object visitFee, Object hourlyRate);

  /// Standard Visit Fee (LKR)
  String get standardVisitFeeWithCurrency;

  /// Hourly Rate (LKR / hr)
  String get hourlyRateWithUnit;

  /// Daily Rate (LKR / day)
  String get dailyRateWithUnit;

  /// Travel Rate (LKR / km)
  String get travelRateWithUnit;

  /// Does price match quote? (LKR {amount})
  String priceMatchesQuoteAmount(Object amount);

  /// Quantity ({unit})
  String quantityWithUnit(String unit);

  /// hours
  String get unitHours;

  /// days
  String get unitDays;

  /// jobs
  String get unitJobs;

  /// English
  String get languageEnglish;

  /// Sinhala
  String get languageSinhala;

  /// Tamil
  String get languageTamil;

  /// Location access is required to verify arrival at customer location.
  String get locationPermissionRequired;

  /// None
  String get none;

  /// Optional
  String get optional;

  /// This service provider does not have an active service category.
  String get errorProviderCategoryMissing;

  /// Manage Users
  String get permManageUsersLabel;

  /// Ban or unban users and providers, and handle account security actions.
  String get permManageUsersDesc;

  /// Support & Tickets
  String get permHandleSupportLabel;

  /// Review and respond to customer and provider support tickets.
  String get permHandleSupportDesc;

  /// You don\'t have permission for this.
  String get noPermissionForAction;

  /// Help & Support
  String get helpAndSupport;

  /// My Tickets
  String get myTickets;

  /// Report a problem
  String get reportAProblem;

  /// We usually reply within 24 hours
  String get ticketReplyPrompt;

  /// Open
  String get ticketStatusOpen;

  /// In Progress
  String get ticketStatusInProgress;

  /// Waiting on You
  String get ticketStatusWaitingUser;

  /// Resolved
  String get ticketStatusResolved;

  /// Closed
  String get ticketStatusClosed;

  /// Help
  String get typeHelp;

  /// Report User
  String get typeReportUser;

  /// Booking Problem
  String get typeBookingProblem;

  /// Payment Dispute
  String get typePaymentDispute;

  /// Account
  String get typeAccount;

  /// App Problem
  String get typeAppProblem;

  /// Feedback & Suggestions
  String get typeFeedback;

  /// Subject
  String get ticketSubject;

  /// Description
  String get ticketDescription;

  /// Submit Ticket
  String get ticketSend;

  /// Attach Photo
  String get ticketAttachPhoto;

  /// Type a message...
  String get ticketReplyHint;

  /// Close Ticket
  String get ticketCloseConfirm;

  /// Resolution Note
  String get ticketResolvedNote;

  /// Assign to me
  String get ticketAssignToMe;

  /// Warn User
  String get warnUser;

  /// Ban User
  String get banUser;

  /// Support Phone
  String get supportPhone;

  /// Support Email
  String get supportEmail;

  /// Call Support
  String get callSupport;

  /// Email Support
  String get emailSupport;

  /// No support tickets yet
  String get noTicketsYet;

  /// Support ticket created successfully
  String get ticketCreatedSuccess;

  /// Help & Support
  String get helpSupportTitle;

  /// Get assistance, FAQs, or submit a ticket
  String get helpSupportSubtitle;

  /// Report a problem
  String get reportProblemTitle;

  /// Use my exact current location
  String get exactCurrentLocation;

  /// Accuracy: ±{meters} m
  String locationAccuracy(int meters);

  /// Location accuracy is low (±{meters} m). Please drag the map pin to your exact gate or house.
  String locationAccuracyLowWarning(int meters);

  /// Drag pin to your exact gate or house
  String get fineTunePinInstruction;

  /// House / Apartment No.
  String get houseAptNo;

  /// Street / Road
  String get streetName;

  /// Town / City
  String get townCity;

  /// Landmark (e.g. near the blue gate)
  String get landmarkOptional;

  /// Directions for provider
  String get directionsForProvider;

  /// Save this address
  String get saveThisAddress;

  /// Please choose a service location on the map before posting.
  String get locationRequiredHint;

  /// As soon as possible
  String get scheduleModeAsap;

  /// Pick a date only
  String get scheduleModeDateOnly;

  /// Pick a date & my own time range
  String get scheduleModeTimeRange;

  /// Any time that day
  String get scheduleAnyTime;

  /// From
  String get scheduleFrom;

  /// To
  String get scheduleTo;

  /// Time range must be at least 1 hour.
  String get scheduleMinDurationError;

  /// Time range cannot exceed 12 hours.
  String get scheduleMaxDurationError;

  /// Time range must be on the same day.
  String get scheduleSameDayError;

  /// Start time cannot be in the past.
  String get schedulePastError;

  /// Less than 1 hour remains before 20:00 today. Please select another date.
  String get scheduleTodayPastCutoff;

  /// Outside your working hours
  String get outsideWorkingHoursWarning;

  /// Admin Verification
  String get admin2faTitle;

  /// Enter the 6-digit code sent to your admin email to authenticate your session.
  String get admin2faSubtitle;

  /// Use a different account
  String get useDifferentAccount;

  /// Continue as Customer
  String get continueAsCustomer;

  /// No code sent yet — tap Resend
  String get otpNoSession;

  /// Code expired — tap Resend
  String get otpExpiredResend;

  /// Too many wrong tries — tap Resend
  String get otpMaxAttemptsResend;

  /// Incorrect code. {count} tries left
  String otpIncorrectTriesLeft(int count);

  /// Code already sent
  String get codeAlreadySent;

  /// Couldn\'t send your request. Please sign in again and try once more.
  String get ticketSubmitPermissionDenied;

  /// Couldn\'t send your request. Please try again.
  String get ticketSubmitErrorGeneral;

  /// Category
  String get ticketCategory;

  /// Please fill all required fields
  String get pleaseFillRequiredFields;

  /// Couldn\'t upload the photo. Try again or send without a photo.
  String get ticketPhotoUploadFailed;

  /// Video upload works in the mobile app
  String get videoUploadMobileOnly;

  /// Permanently remove your account and data
  String get deleteAccountSubtitle;

  /// Move the pin to your gate
  String get movePinToGateHint;

  /// Not here? Choose another place
  String get notHereChooseAnother;

  /// Couldn\'t get your location — choose a place or search the map
  String get couldNotGetLocationFallback;

  /// Try GPS again
  String get tryGpsAgain;

  /// Add details for the provider
  String get addDetailsForProvider;

  /// Note for provider
  String get providerNoteLabel;

  /// e.g. blue gate, white Toyota near the bus stop
  String get providerNoteHint;

  /// Save this place
  String get saveThisPlace;

  /// Search on map
  String get searchOnMap;

  /// Search road, area or town...
  String get searchPlaceHint;

  /// ±{meters} m
  String accuracyBadge(int meters);

  /// Saved
  String get saved;

  /// Couldn\'t upload the photo/video — Retry
  String get mediaUploadFailedRetry;

  /// Couldn\'t post your job. Please sign in again and try once more.
  String get jobPostPermissionDenied;

  /// Couldn\'t post your job. Please try again.
  String get jobPostErrorGeneral;

  /// This provider does not have an emergency rate set.
  String get emergencyRateUnavailable;

  /// We couldn\'t upload your NIC right now. Please try again later.
  String get nicUploadErrorRetry;

  /// Please verify your email first.
  String get emailOtpRequiredError;

  /// Couldn\'t complete your profile. Please try again.
  String get profileCompletionError;

  /// Invalid NIC format. Use 9 digits with V/X or 12 digits.
  String get invalidNicFormatError;

  /// Application Under Review
  String get providerPendingTitle;

  /// We\'re reviewing your provider registration and NIC documents. You\'ll be notified once approved.
  String get providerPendingSubtitle;

  /// Application Needs Attention
  String get providerRejectedTitle;

  /// Your provider application was not approved. Please review the reason below and submit updated details.
  String get providerRejectedSubtitle;

  /// Reason
  String get rejectionReasonLabel;

  /// Submitted Details
  String get submittedDetailsTitle;

  /// Submitted Date
  String get submittedDateLabel;

  /// Service Category
  String get serviceCategoryLabel;

  /// Applicant Name
  String get applicantNameLabel;

  /// Fix & Resubmit
  String get fixAndResubmit;

  /// Your provider application is under review. You can continue using customer features in the meantime.
  String get providerPendingCustomerToast;

  /// Congratulations! Your provider account is now approved and active.
  String get providerApprovedCelebration;

  /// Provider Application
  String get providerApplicationStatusBadge;

  /// Under Review
  String get providerApplicationUnderReview;

  /// Action Needed
  String get providerApplicationActionNeeded;

  /// Resubmission Requested
  String get providerResubmitTitle;

  /// Your application needs an updated document or clearer photo. Please review the note below and resubmit.
  String get providerResubmitSubtitle;

  /// Automated Security & Validity Checks
  String get autoChecksTitle;

  /// NIC Format Valid
  String get nicFormatValid;

  /// Invalid NIC Format
  String get nicFormatInvalid;

  /// Decoded Details
  String get nicDecodedBirthAndGender;

  /// Age 18+ (Eligible)
  String get ageCheckValid;

  /// Under 18 Warning
  String get ageCheckUnder18;

  /// Duplicate NIC Detected
  String get duplicateNicDetected;

  /// Duplicate Phone Detected
  String get duplicatePhoneDetected;

  /// No duplicate NIC or phone detected
  String get noDuplicatesFound;

  /// Warning: duplicate account detected
  String get duplicateWarningBanner;

  /// Pre-Approval Verification Checklist
  String get approvalChecklistTitle;

  /// NIC photos are clear, legible, and uncropped
  String get chkPhotoClear;

  /// Applicant name matches identity card exactly
  String get chkNameMatches;

  /// NIC number matches identity card exactly
  String get chkNicMatches;

  /// Profile photo face matches NIC photo
  String get chkFaceMatches;

  /// Identity card has no signs of digital editing or tampering
  String get chkCardNotEdited;

  /// All 5 checks required to activate provider
  String get allChecksRequired;

  /// Request Resubmission
  String get requestResubmission;

  /// Reject Application
  String get rejectApplication;

  /// Provide Review Decision
  String get rejectionReasonDialogTitle;

  /// Select Reason
  String get selectPresetReason;

  /// Blurry or unreadable photo
  String get reasonBlurryPhoto;

  /// Name does not match identity card
  String get reasonNameMismatch;

  /// NIC number does not match card
  String get reasonNicMismatch;

  /// Wrong side or missing back side
  String get reasonWrongSide;

  /// Profile photo does not match NIC face
  String get reasonFaceMismatch;

  /// Other reason
  String get reasonOther;

  /// Additional instructions (optional, max 300 chars)
  String get optionalReviewerNote;

  /// Pending
  String get filterPending;

  /// Resubmitted
  String get filterResubmitted;

  /// Rejected
  String get filterRejected;

  /// Approved
  String get filterApproved;

  /// Face Comparison
  String get faceComparisonTitle;

  /// Profile Photo
  String get profilePhotoLabel;

  /// NIC Front
  String get nicFrontLabel;

  /// NIC Back
  String get nicBackLabel;

  /// Rotate 90°
  String get rotatePhoto;

  /// Pinch or double tap to zoom
  String get zoomHint;

  /// Review & Submission History
  String get auditHistoryTitle;

  /// Submission #{number}
  String submissionAttempt(String number);

  /// No results found
  String get noSearchResults;

  /// Search not available, move the map instead
  String get searchUnavailableFallback;

  /// Recent places
  String get recentPlaces;

  /// Use my current location
  String get useMyCurrentLocation;

  /// Showing jobs near you now
  String get showingJobsNearYouNow;

  /// Showing jobs near your base ({area})
  String showingJobsNearBase(String area);

  /// Notice showing jobs near provider base when area name is not known
  ///
  /// In en, this message translates to:
  /// **'Showing jobs near your base'**
  String get showingJobsNearBaseNoArea;

  /// Set your base location to see nearby jobs
  String get setBaseLocationPrompt;

  /// Set Base Location
  String get setBaseLocationBtn;

  /// {distance} km away now
  String awayNow(String distance);

  /// Based {distance} km away
  String basedAway(String distance);

  /// Location last updated {minutes} min ago
  String locationLastUpdatedMinsAgo(String minutes);

  /// Estimated
  String get estimatedLabel;

  /// Base Location
  String get baseLocationTitle;

  /// Where you normally start your workday
  String get baseLocationDesc;

  /// How do you charge?
  String get howDoYouChargeTitle;

  /// Select at least one billing method (per hour, per day, or per job).
  String get howDoYouChargeSubtitle;

  /// Per hour
  String get pricingModePerHour;

  /// Per day
  String get pricingModePerDay;

  /// Price per job (quote each job)
  String get pricingModePricePerJob;

  /// Visit / inspection fee
  String get pricingModeVisitFee;

  /// Travel charge per km
  String get pricingModeTravelPerKm;

  /// Select at least one: Per hour, Per day, or Price per job.
  String get atLeastOneBasePricingModeRequired;

  /// Travel included
  String get travelIncluded;

  /// Quoted per job
  String get quoteEachJob;

  /// Travel
  String get travelTitle;

  /// Could not load exact job location. Please try again.
  String get couldNotLoadExactLocationRetry;

  /// Getting your location...
  String get gettingYourLocation;

  /// Try again
  String get tryAgain;

  /// Customer location missing, call the customer
  String get customerLocationMissingCallCustomer;

  /// HelaService
  String get locationSharingNotificationTitle;

  /// Sharing your location with the customer
  String get locationSharingNotificationText;

  /// Preparing media...
  String get preparingMedia;

  /// Uploading photo {current} of {total}...
  String uploadingPhotoProgress(int current, int total);

  /// Photo {current}/{total}: {sentMb} MB / {totalMb} MB
  String uploadPhotoBytesProgress(
      int current, int total, String sentMb, String totalMb);

  /// Uploading video thumbnail...
  String get uploadingVideoThumbnail;

  /// Uploading video file...
  String get uploadingVideoFile;

  /// Video: {sentMb} MB / {totalMb} MB
  String uploadVideoBytesProgress(String sentMb, String totalMb);

  /// Ticket assigned to you
  String get ticketAssignedToYou;

  /// Open Booking Timeline ({id})
  String openBookingTimeline(String id);

  /// Mark In Review
  String get markInReviewAction;

  /// Resolve
  String get resolveAction;

  /// Dismiss
  String get dismissAction;

  /// Message History
  String get messageHistoryTitle;

  /// No replies in thread yet.
  String get noRepliesYet;

  /// Reply as Support Admin...
  String get replyAsSupportAdminHint;

  /// Under 18 ({age} yrs) — Cannot be approved
  String nicWarningUnder18(int age);

  /// duplicate check not available yet
  String get nicDuplicateCheckNotAvailable;

  /// Duplicate NIC: already approved for {name} ({id})
  String nicDuplicateNicApproved(String name, String id);

  /// Duplicate NIC: pending for {name} ({id})
  String nicDuplicateNicPending(String name, String id);

  /// Duplicate Phone: already registered to approved provider {name}
  String nicDuplicatePhone(String name);

  /// Identity Verification Approved
  String get notificationIdentityApprovedTitle;

  /// Your identity verification was approved. Your profile is now active.
  String get notificationIdentityApprovedBody;

  /// Verified Service Artisans
  String get heroVerifiedArtisans;

  /// Live tracking when your provider is on the way
  String get heroLiveTracking;

  /// Transparent Local Quotes
  String get heroTransparentQuotes;

  /// Direct quote requests in minutes
  String get heroDirectQuoteRequests;

  /// Private, secure chat
  String get heroPrivateSecureChat;

  /// Community rated professionals
  String get heroCommunityRated;

  /// Are you sure you want to close this ticket?
  String get supportTicketCloseConfirm;

  /// Ticket closed.
  String get ticketClosedMessage;

  /// Ticket not found
  String get ticketNotFound;

  /// Booking Timeline ({id})
  String bookingTimelineWithId(String id);

  /// View Ticket & Thread
  String get viewTicketAndThread;

  /// Refresh Images
  String get refreshImages;

  /// ({min} to {max})
  String quantityRangeMinMax(String min, String max);

  /// Customer created booking request
  String get timelineDescCreated;

  /// Provider accepted the booking
  String get timelineDescAccepted;

  /// Provider declined the booking
  String get timelineDescDeclined;

  /// Booking was cancelled
  String get timelineDescCancelled;

  /// Provider started journey to location
  String get timelineDescEnRoute;

  /// Provider arrived at location
  String get timelineDescArrived;

  /// Provider claimed arrival
  String get timelineDescArrivalClaimed;

  /// Customer confirmed provider arrival
  String get timelineDescArrivalConfirmed;

  /// Customer reported provider has not arrived
  String get timelineDescArrivalDenied;

  /// Started after customer timeout with verified GPS
  String get timelineDescArrivalAutoStarted;

  /// Job completed
  String get timelineDescCompleted;

  /// Completed with inspection/visit fee only
  String get timelineDescCompletedVisitOnly;

  /// Customer confirmed payment
  String get timelineDescPaymentConfirmed;

  /// Payment disputed
  String get timelineDescPaymentDisputed;

  /// Provider proposed revised price
  String get timelineDescPriceProposed;

  /// Customer approved revised price
  String get timelineDescPriceApproved;

  /// Customer rejected revised price
  String get timelineDescPriceRejected;

  /// Provider confirmed initial quoted price
  String get timelineDescPriceKept;

  /// Provider requested approval for extra work
  String get timelineDescExtraRequested;

  /// Customer approved extra work
  String get timelineDescExtraApproved;

  /// Customer rejected extra work
  String get timelineDescExtraRejected;

  /// Customer reported provider no-show
  String get timelineDescNoShowReported;

  /// Provider uploaded initial inspection photo
  String get timelineDescBeforePhotoAdded;

  /// Provider uploaded completed work photo
  String get timelineDescAfterPhotoAdded;

  /// Reschedule requested
  String get timelineDescRescheduleRequested;

  /// Reschedule accepted
  String get timelineDescRescheduleAccepted;

  /// Reschedule declined
  String get timelineDescRescheduleDeclined;
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
