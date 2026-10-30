import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  // supported locales
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta')
  ];

  // app title
  String get appTitle;

  // tagline
  String get tagline;

  // language
  String get language;

  // select language
  String get selectLanguage;

  // preferred language
  String get preferredLanguage;

  // choose language subtitle
  String get chooseLanguageSubtitle;

  // english
  String get english;

  // sinhala
  String get sinhala;

  // tamil
  String get tamil;

  // theme
  String get theme;

  // theme light
  String get themeLight;

  // theme dark
  String get themeDark;

  // theme system
  String get themeSystem;

  // change theme
  String get changeTheme;

  // role customer
  String get roleCustomer;

  // role provider
  String get roleProvider;

  // role admin
  String get roleAdmin;

  // switch role
  String get switchRole;

  // nav home
  String get navHome;

  // nav explore
  String get navExplore;

  // nav bookings
  String get navBookings;

  // nav tracking
  String get navTracking;

  // nav post job
  String get navPostJob;

  // nav profile
  String get navProfile;

  // nav leads
  String get navLeads;

  // nav ongoing
  String get navOngoing;

  // nav earnings
  String get navEarnings;

  // nav jobs radar
  String get navJobsRadar;

  // nav my quotes
  String get navMyQuotes;

  // nav operations
  String get navOperations;

  // nav live map
  String get navLiveMap;

  // nav verifications
  String get navVerifications;

  // nav verification
  String get navVerification;

  // nav overview
  String get navOverview;

  // nav verify
  String get navVerify;

  // nav coverage
  String get navCoverage;

  // nav team
  String get navTeam;

  // nav settings
  String get navSettings;

  // login title
  String get loginTitle;

  // login subtitle
  String get loginSubtitle;

  // email address
  String get emailAddress;

  // password
  String get password;

  // confirm password
  String get confirmPassword;

  // forgot password
  String get forgotPassword;

  // sign in
  String get signIn;

  // create account
  String get createAccount;

  // create account subtitle
  String get createAccountSubtitle;

  // continue text
  String get continueText;

  // already have account
  String get alreadyHaveAccount;

  // log in
  String get logIn;

  // new to hela service
  String get newToHelaService;

  // reset password
  String get resetPassword;

  // reset password desc
  String get resetPasswordDesc;

  // send reset link
  String get sendResetLink;

  // enter email error
  String get enterEmailError;

  // enter password error
  String get enterPasswordError;

  // password length error
  String get passwordLengthError;

  // password mismatch error
  String get passwordMismatchError;

  // phone number
  String get phoneNumber;

  // send otp
  String get sendOtp;

  // verify otp
  String get verifyOtp;

  // enter otp
  String get enterOtp;

  // resend otp
  String get resendOtp;

  // google sign in
  String get googleSignIn;

  // google sign in existing
  String get googleSignInExisting;

  // google no account title
  String get googleNoAccountTitle;

  // google no account message
  String get googleNoAccountMessage;

  // splash no connection
  String get splashNoConnection;

  // explore as guest
  String get exploreAsGuest;

  // or continue with
  String get orContinueWith;

  // or sign up with email
  String get orSignUpWithEmail;

  // complete profile title
  String get completeProfileTitle;

  // complete profile subtitle
  String get completeProfileSubtitle;

  // select account type
  String get selectAccountType;

  // customer role desc
  String get customerRoleDesc;

  // provider role desc
  String get providerRoleDesc;

  // full name
  String get fullName;

  // full name as nic
  String get fullNameAsNic;

  // phone label
  String get phoneLabel;

  // address
  String get address;

  // district
  String get district;

  // primary district
  String get primaryDistrict;

  // category
  String get category;

  // primary category
  String get primaryCategory;

  // nic number
  String get nicNumber;

  // nic front
  String get nicFront;

  // nic back
  String get nicBack;

  // detect gps
  String get detectGps;

  // refresh gps
  String get refreshGps;

  // gps detected
  String get gpsDetected;

  // gps hint
  String get gpsHint;

  // agree terms
  String get agreeTerms;

  // complete registration
  String get completeRegistration;

  // account verified
  String get accountVerified;

  // post job title
  String get postJobTitle;

  // post job subtitle
  String get postJobSubtitle;

  // post job get quotes
  String get postJobGetQuotes;

  // describe job or repair
  String get describeJobOrRepair;

  // describe job subtitle
  String get describeJobSubtitle;

  // select trade category
  String get selectTradeCategory;

  // job title
  String get jobTitle;

  // job title hint
  String get jobTitleHint;

  // job description
  String get jobDescription;

  // job description hint
  String get jobDescriptionHint;

  // budget
  String get budget;

  // budget hint
  String get budgetHint;

  // job location gps
  String get jobLocationGps;

  // photos of issue
  String get photosOfIssue;

  // job photos
  String get jobPhotos;

  // add
  String get add;

  // add photo
  String get addPhoto;

  // take photo
  String get takePhoto;

  // choose from gallery
  String get chooseFromGallery;

  // max photos allowed
  String get maxPhotosAllowed;

  // your exact location
  String get yourExactLocation;

  // gps coordinates locked
  String get gpsCoordinatesLocked;

  // detecting location
  String get detectingLocation;

  // tap to detect gps
  String get tapToDetectGps;

  // street address optional
  String get streetAddressOptional;

  // submit job request
  String get submitJobRequest;

  // job posted success
  String get jobPostedSuccess;

  // quotes alert
  String get quotesAlert;

  // enter job title error
  String get enterJobTitleError;

  // add description error
  String get addDescriptionError;

  // select category error
  String get selectCategoryError;

  // quotes title
  String get quotesTitle;

  // quotes received
  String get quotesReceived;

  // no quotes
  String get noQuotes;

  // waiting for quotes
  String get waitingForQuotes;

  // waiting for quotes desc
  String get waitingForQuotesDesc;

  // provider hired
  String providerHired(String providerName);

  // back to home
  String get backToHome;

  // accept quote hire
  String get acceptQuoteHire;

  // accept hire
  String get acceptHire;

  // hired success
  String get hiredSuccess;

  // send quote
  String get sendQuote;

  // quote amount
  String get quoteAmount;

  // estimated time
  String get estimatedTime;

  // estimated time hint
  String get estimatedTimeHint;

  // quote notes
  String get quoteNotes;

  // quote notes hint
  String get quoteNotesHint;

  // submit quote
  String get submitQuote;

  // submit price quote
  String get submitPriceQuote;

  // submit price quote sub
  String get submitPriceQuoteSub;

  // customer photos
  String get customerPhotos;

  // your quoted price
  String get yourQuotedPrice;

  // estimated arrival time
  String get estimatedArrivalTime;

  // message to customer optional
  String get messageToCustomerOptional;

  // send price quote
  String get sendPriceQuote;

  // quote submitted success
  String get quoteSubmittedSuccess;

  // accept quote
  String get acceptQuote;

  // decline quote
  String get declineQuote;

  // enter quoted price error
  String get enterQuotedPriceError;

  // enter valid price error
  String get enterValidPriceError;

  // greeting ayubowan
  String get greetingAyubowan;

  // find certified artisans
  String get findCertifiedArtisans;

  // search hint
  String get searchHint;

  // search service hint
  String get searchServiceHint;

  // have repair or job
  String get haveRepairOrJob;

  // post details banner sub
  String get postDetailsBannerSub;

  // categories
  String get categories;

  // view all
  String get viewAll;

  // no categories available
  String get noCategoriesAvailable;

  // artisans on duty
  String get artisansOnDuty;

  // active nearby
  String get activeNearby;

  // radar active
  String get radarActive;

  // avg arrival time
  String get avgArrivalTime;

  // top rated technicians
  String get topRatedTechnicians;

  // verified checks ratings
  String get verifiedChecksRatings;

  // no technicians yet
  String get noTechniciansYet;

  // emergency help title
  String get emergencyHelpTitle;

  // emergency help subtitle
  String get emergencyHelpSubtitle;

  // request emergency
  String get requestEmergency;

  // top categories
  String get topCategories;

  // view all services
  String get viewAllServices;

  // nearby artisans
  String get nearbyArtisans;

  // filter all
  String get filterAll;

  // reviews count
  String get reviewsCount;

  // starting from
  String get startingFrom;

  // view details
  String get viewDetails;

  // hela care guarantee
  String get helaCareGuarantee;

  // hela care desc
  String get helaCareDesc;

  // initial inspection rate
  String get initialInspectionRate;

  // quick book
  String get quickBook;

  // service detail
  String get serviceDetail;

  // transparent pricing
  String get transparentPricing;

  // base inspection fee
  String get baseInspectionFee;

  // base inspection sub
  String get baseInspectionSub;

  // standard hourly labour
  String get standardHourlyLabour;

  // emergency rate
  String get emergencyRate;

  // materials billed separately
  String get materialsBilledSeparately;

  // about technician
  String get aboutTechnician;

  // recent work completed
  String get recentWorkCompleted;

  // customer reviews
  String get customerReviews;

  // request service
  String get requestService;

  // message
  String get message;

  // chat
  String get chat;

  // live tracking
  String get liveTracking;

  // no active dispatch
  String get noActiveDispatch;

  // no active dispatch sub
  String get noActiveDispatchSub;

  // tech on the way
  String get techOnTheWay;

  // estimated arrival
  String get estimatedArrival;

  // arriving in
  String get arrivingIn;

  // direct pay cash
  String get directPayCash;

  // inspection fee notice
  String get inspectionFeeNotice;

  // cancel request
  String get cancelRequest;

  // share trip
  String get shareTrip;

  // job finished rate pay
  String get jobFinishedRatePay;

  // call tech
  String get callTech;

  // checkout booking
  String get checkoutBooking;

  // service completed
  String get serviceCompleted;

  // cost breakdown
  String get costBreakdown;

  // paid
  String get paid;

  // base diagnostic visit
  String get baseDiagnosticVisit;

  // parts and labor
  String get partsAndLabor;

  // total paid
  String get totalPaid;

  // settled directly cash
  String get settledDirectlyCash;

  // rate experience
  String get rateExperience;

  // what went well
  String get whatWentWell;

  // leave review optional
  String get leaveReviewOptional;

  // tip provider
  String get tipProvider;

  // done
  String get done;

  // need help order
  String get needHelpOrder;

  // status pending
  String get statusPending;

  // status accepted
  String get statusAccepted;

  // status in progress
  String get statusInProgress;

  // status completed
  String get statusCompleted;

  // status cancelled
  String get statusCancelled;

  // verified artisan
  String get verifiedArtisan;

  // active fleet
  String get activeFleet;

  // available now
  String get availableNow;

  // km away
  String get kmAway;

  // rating
  String get rating;

  // reviews
  String get reviews;

  // my bookings
  String get myBookings;

  // active bookings
  String get activeBookings;

  // past bookings
  String get pastBookings;

  // active service visit
  String get activeServiceVisit;

  // past completed services
  String get pastCompletedServices;

  // open live gps tracking
  String get openLiveGpsTracking;

  // no bookings found
  String get noBookingsFound;

  // no bookings recorded
  String get noBookingsRecorded;

  // browse artisans explore
  String get browseArtisansExplore;

  // book technician
  String get bookTechnician;

  // call artisan
  String get callArtisan;

  // track location
  String get trackLocation;

  // leave review
  String get leaveReview;

  // rate job title
  String get rateJobTitle;

  // rate job subtitle
  String get rateJobSubtitle;

  // rating feedback hint
  String get ratingFeedbackHint;

  // submit rating
  String get submitRating;

  // provider dashboard title
  String get providerDashboardTitle;

  // status online
  String get statusOnline;

  // status offline
  String get statusOffline;

  // you are online
  String get youAreOnline;

  // you are offline
  String get youAreOffline;

  // active dispatch sub
  String get activeDispatchSub;

  // open job requests
  String get openJobRequests;

  // from customers
  String get fromCustomers;

  // no open requests
  String get noOpenRequests;

  // customer requests appear here
  String get customerRequestsAppearHere;

  // scheduled bookings
  String get scheduledBookings;

  // no active bookings
  String get noActiveBookings;

  // today earnings
  String get todayEarnings;

  // completed jobs
  String get completedJobs;

  // active leads
  String get activeLeads;

  // no leads available
  String get noLeadsAvailable;

  // no quotes yet
  String get noQuotesYet;

  // browse radar desc
  String get browseRadarDesc;

  // accepted caps
  String get acceptedCaps;

  // pending response caps
  String get pendingResponseCaps;

  // declined caps
  String get declinedCaps;

  // save
  String get save;

  // cancel
  String get cancel;

  // confirm
  String get confirm;

  // logout
  String get logout;

  // logout confirm
  String get logoutConfirm;

  // edit profile
  String get editProfile;

  // contact support
  String get contactSupport;

  // app settings
  String get appSettings;

  // edit profile and photo
  String get editProfileAndPhoto;

  // edit contact info
  String get editContactInfo;

  // profile photo
  String get profilePhoto;

  // profile photo required
  String get profilePhotoRequired;

  // profile photo required hint
  String get profilePhotoRequiredHint;

  // profile photo required error
  String get profilePhotoRequiredError;

  // add photo action
  String get addPhotoAction;

  // change photo action
  String get changePhotoAction;

  // dispatch and contact info
  String get dispatchAndContactInfo;

  // change
  String get change;

  // verified customer
  String get verifiedCustomer;

  // payment methods
  String get paymentMethods;

  // payment methods subtitle
  String get paymentMethodsSubtitle;

  // island customer helpline
  String get islandCustomerHelpline;

  // island customer helpline subtitle
  String get islandCustomerHelplineSubtitle;

  // appearance and theme
  String get appearanceAndTheme;

  // choose appearance
  String get chooseAppearance;

  // light mode
  String get lightMode;

  // dark mode
  String get darkMode;

  // system default
  String get systemDefault;

  // switch operational view
  String get switchOperationalView;

  // profile updated success
  String get profileUpdatedSuccess;

  // logout modal title
  String get logoutModalTitle;

  // logout modal confirm
  String get logoutModalConfirm;

  // profile details
  String get profileDetails;

  // service location
  String get serviceLocation;

  // select district
  String get selectDistrict;

  // district label
  String get districtLabel;

  // address or area optional
  String get addressOrAreaOptional;

  // address or area hint
  String get addressOrAreaHint;

  // use exact live gps
  String get useExactLiveGps;

  // gps location set
  String get gpsLocationSet;

  // detecting gps
  String get detectingGps;

  // express dispatch route
  String get expressDispatchRoute;

  // auto passes in
  String get autoPassesIn;

  // new job request
  String get newJobRequest;

  // urgent
  String get urgent;

  // guaranteed base payout
  String get guaranteedBasePayout;

  // direct settlement cash at site
  String get directSettlementCashAtSite;

  // service note
  String get serviceNote;

  // pull over safely note
  String get pullOverSafelyNote;

  // report en route delay
  String get reportEnRouteDelay;

  // en route navigation
  String get enRouteNavigation;

  // turn left
  String get turnLeft;

  // turn right
  String get turnRight;

  // google maps or waze
  String get googleMapsOrWaze;

  // customer notified of arrival
  String get customerNotifiedOfArrival;

  // national id verification
  String get nationalIdVerification;

  // verified artisan network sri lanka
  String get verifiedArtisanNetworkSriLanka;

  // fast track verification checklist
  String get fastTrackVerificationChecklist;

  // call partner support
  String get callPartnerSupport;

  // end to end encrypted vault
  String get endToEndEncryptedVault;

  // nic upload file limit hint
  String get nicUploadFileLimitHint;

  // nic secure storage desc
  String get nicSecureStorageDesc;

  // uploading to vault
  String get uploadingToVault;

  // emergency available247
  String get emergencyAvailable247;

  // emergency available desc
  String get emergencyAvailableDesc;

  // operational district
  String get operationalDistrict;

  // primary trade category
  String get primaryTradeCategory;

  // quotes count
  String get quotesCount;

  // admin dashboard title
  String get adminDashboardTitle;

  // platform overview
  String get platformOverview;

  // active technicians
  String get activeTechnicians;

  // pending verifications
  String get pendingVerifications;

  // total dispatched jobs
  String get totalDispatchedJobs;

  // gross booking value
  String get grossBookingValue;

  // system health
  String get systemHealth;

  // pending technician approvals
  String get pendingTechnicianApprovals;

  // dispute resolution center
  String get disputeResolutionCenter;

  // platform analytics
  String get platformAnalytics;

  // super admin privileges
  String get superAdminPrivileges;

  // audit logs
  String get auditLogs;

  // approve
  String get approve;

  // reject
  String get reject;

  // failed to pick photo
  String get failedToPickPhoto;

  // please accept terms
  String get pleaseAcceptTerms;

  // please upload nic front
  String get pleaseUploadNicFront;

  // please upload nic back
  String get pleaseUploadNicBack;

  // failed to submit
  String get failedToSubmit;

  // close
  String get close;

  // sec
  String get sec;

  // upload profile photo
  String get uploadProfilePhoto;

  // upload nic front
  String get uploadNicFront;

  // upload nic back
  String get uploadNicBack;

  // nic front required
  String get nicFrontRequired;

  // required field
  String get requiredField;

  // upload clear face photo
  String get uploadClearFacePhoto;

  // tap to change
  String get tapToChange;

  // on time arrival
  String get onTimeArrival;

  // artisan profile
  String get artisanProfile;

  // jobs done
  String get jobsDone;

  // completed
  String get completed;

  // prompt arrival
  String get promptArrival;

  // operating district
  String get operatingDistrict;

  // phone
  String get phone;

  // nic uploaded
  String get nicUploaded;

  // base location
  String get baseLocation;

  // no gps set
  String get noGpsSet;

  // distance calc hint
  String get distanceCalcHint;

  // auto detect gps
  String get autoDetectGps;

  // job dispatch settings
  String get jobDispatchSettings;

  // emergency callout
  String get emergencyCallout;

  // emergency callout desc
  String get emergencyCalloutDesc;

  // appearance
  String get appearance;

  // theme mode
  String get themeMode;

  // current theme
  String get currentTheme;

  // app language
  String get appLanguage;

  // current language
  String get currentLanguage;

  // switch to customer
  String get switchToCustomer;

  // switch to customer desc
  String get switchToCustomerDesc;

  // broadcast alert
  String get broadcastAlert;

  // broadcast alert desc
  String get broadcastAlertDesc;

  // send broadcast
  String get sendBroadcast;

  // admin console
  String get adminConsole;

  // platform health
  String get platformHealth;

  // core services
  String get coreServices;

  // pending kyc
  String get pendingKyc;

  // operations controls
  String get operationsControls;

  // admin team governance
  String get adminTeamGovernance;

  // admin team governance desc
  String get adminTeamGovernanceDesc;

  // emergency broadcast
  String get emergencyBroadcast;

  // emergency broadcast desc
  String get emergencyBroadcastDesc;

  // switch operational view desc
  String get switchOperationalViewDesc;

  // job ledger
  String get jobLedger;

  // job ledger nav
  String get jobLedgerNav;

  // job ledger subtitle
  String get jobLedgerSubtitle;

  // total completed jobs
  String get totalCompletedJobs;

  // total in progress jobs
  String get totalInProgressJobs;

  // average rating
  String get averageRating;

  // filter completed
  String get filterCompleted;

  // filter in progress
  String get filterInProgress;

  // filter cancelled
  String get filterCancelled;

  // won by
  String get wonBy;

  // customer label
  String get customerLabel;

  // bid amount
  String get bidAmount;

  // not recorded
  String get notRecorded;

  // no bookings matching filter
  String get noBookingsMatchingFilter;

  // delay reported
  String get delayReported;

  // tracking outcome
  String get trackingOutcome;

  // customer satisfaction
  String get customerSatisfaction;

  // manual review
  String get manualReview;

  // cloud storage path
  String get cloudStoragePath;

  // manual nic review
  String get manualNicReview;

  // ocr audit concordant
  String get ocrAuditConcordant;

  // ocr audit flagged
  String get ocrAuditFlagged;

  // not provided
  String get notProvided;

  // not specified
  String get notSpecified;

  // enter full name
  String get enterFullName;

  // enter valid email
  String get enterValidEmail;

  // enter nic error
  String get enterNicError;

  // create customer account
  String get createCustomerAccount;

  // customer register subtitle
  String get customerRegisterSubtitle;

  // full name label
  String get fullNameLabel;

  // email address label
  String get emailAddressLabel;

  // account email label
  String get accountEmailLabel;

  // at least6 chars
  String get atLeast6Chars;

  // customer phone label
  String get customerPhoneLabel;

  // provider phone label
  String get providerPhoneLabel;

  // home address label
  String get homeAddressLabel;

  // become provider
  String get becomeProvider;

  // provider register subtitle
  String get providerRegisterSubtitle;

  // agree provider terms
  String get agreeProviderTerms;

  // create account verify nic
  String get createAccountVerifyNic;

  // select delay reason
  String get selectDelayReason;

  // heavy traffic
  String get heavyTraffic;

  // monsoon rain
  String get monsoonRain;

  // road detour
  String get roadDetour;

  // refueling stop
  String get refuelingStop;

  // chat with customer
  String get chatWithCustomer;

  // call customer phone
  String get callCustomerPhone;

  // customer phone not available
  String get customerPhoneNotAvailable;

  // entry instructions label
  String get entryInstructionsLabel;

  // no special entry instructions
  String get noSpecialEntryInstructions;

  // arrived at location
  String get arrivedAtLocation;

  // slide to confirm arrival
  String get slideToConfirmArrival;

  // arrival confirmed notified
  String get arrivalConfirmedNotified;

  // arrival recorded ready
  String get arrivalRecordedReady;

  // customer will be notified
  String get customerWillBeNotified;

  // report traffic delay
  String get reportTrafficDelay;

  // gps active device
  String get gpsActiveDevice;

  // gps active precision
  String get gpsActivePrecision;

  // order payment support
  String get orderPaymentSupport;

  // order support desc
  String get orderSupportDesc;

  // call support hotline
  String get callSupportHotline;

  // toll free care
  String get tollFreeCare;

  // saving progress
  String get savingProgress;

  // rating exceptional
  String get ratingExceptional;

  // rating great
  String get ratingGreat;

  // rating good
  String get ratingGood;

  // rating okay
  String get ratingOkay;

  // rating needs work
  String get ratingNeedsWork;

  // tag punctual
  String get tagPunctual;

  // tag polite
  String get tagPolite;

  // tag clean work
  String get tagCleanWork;

  // tag fair price
  String get tagFairPrice;

  // tip small tea
  String get tipSmallTea;

  // tip generous
  String get tipGenerous;

  // tip custom
  String get tipCustom;

  // tip enter amount
  String get tipEnterAmount;

  // role switch desc
  String get roleSwitchDesc;

  // role customer subtitle
  String get roleCustomerSubtitle;

  // role provider subtitle
  String get roleProviderSubtitle;

  // role admin subtitle
  String get roleAdminSubtitle;

  // nic verification desk title
  String get nicVerificationDeskTitle;

  // stat pending review
  String get statPendingReview;

  // stat approved
  String get statApproved;

  // stat needs resubmission
  String get statNeedsResubmission;

  // stat flagged rejected
  String get statFlaggedRejected;

  // verification queue clear
  String get verificationQueueClear;

  // incoming verification stream
  String get incomingVerificationStream;

  // select artisan audit
  String get selectArtisanAudit;

  // review required
  String get reviewRequired;

  // active and verified
  String get activeAndVerified;

  // rejected status
  String get rejectedStatus;

  // pending verification status
  String get pendingVerificationStatus;

  // approve and activate artisan
  String get approveAndActivateArtisan;

  // artisan activated
  String get artisanActivated;

  // reject action
  String get rejectAction;

  // request clearer photo
  String get requestClearerPhoto;

  // ocr data field
  String get ocrDataField;

  // ocr extracted
  String get ocrExtracted;

  // ocr registry
  String get ocrRegistry;

  // ocr status
  String get ocrStatus;

  // ocr full name
  String get ocrFullName;

  // ocr nic number
  String get ocrNicNumber;

  // ocr location
  String get ocrLocation;

  // ocr trade note
  String get ocrTradeNote;

  // doc nic front
  String get docNicFront;

  // doc nic back
  String get docNicBack;

  // doc liveness
  String get docLiveness;

  // nav coverage and categories
  String get navCoverageAndCategories;

  // nav admins and team
  String get navAdminsAndTeam;

  // nav artisans
  String get navArtisans;

  // nav customers
  String get navCustomers;

  // nav service metrics
  String get navServiceMetrics;

  // nav platform settings
  String get navPlatformSettings;

  // nav dashboard
  String get navDashboard;

  // ops portal
  String get opsPortal;

  // operations core
  String get operationsCore;

  // password label
  String get passwordLabel;

  // full name nic label
  String get fullNameNicLabel;

  // nic number label
  String get nicNumberLabel;

  // ops core subtitle
  String get opsCoreSubtitle;

  // island operations title
  String get islandOperationsTitle;

  // active providers title
  String get activeProvidersTitle;

  // live badge
  String get liveBadge;

  // online fleet summary
  String onlineFleetSummary(String online, String verified);

  // total bookings title
  String get totalBookingsTitle;

  // completed in progress summary
  String completedInProgressSummary(String completed, String inProgress);

  // nic screening title
  String get nicScreeningTitle;

  // clear status badge
  String get clearStatusBadge;

  // verification dossiers logged
  String verificationDossiersLogged(String count);

  // all sri lanka live traffic
  String get allSriLankaLiveTraffic;

  // heatmap badge
  String get heatmapBadge;

  // active artisan fleet live
  String get activeArtisanFleetLive;

  // district capacity realtime
  String get districtCapacityRealtime;

  // no active artisans fleet
  String get noActiveArtisansFleet;

  // trade and zone
  String tradeAndZone(String trade, String zone);

  // select open job request
  String get selectOpenJobRequest;

  // no open customer requests
  String get noOpenCustomerRequests;

  // assign action
  String get assignAction;

  // dispatched artisan to job
  String dispatchedArtisanToJob(String artisan, String job);

  // nav disputes
  String get navDisputes;

  // trade categories title
  String get tradeCategoriesTitle;

  // add new category action
  String get addNewCategoryAction;

  // catalog density title
  String get catalogDensityTitle;

  // viewing badge
  String get viewingBadge;

  // categories count
  String categoriesCount(String count);

  // active trade services published
  String activeTradeServicesPublished(String count);

  // active artisan fleet title
  String get activeArtisanFleetTitle;

  // artisans count
  String artisansCount(String count);

  // vetted technicians available
  String vettedTechniciansAvailable(String count);

  // published trade categories
  String get publishedTradeCategories;

  // registered online count
  String registeredOnlineCount(String registered, String online);

  // status active
  String get statusActive;

  // status paused
  String get statusPaused;

  // dynamic bidding badge
  String get dynamicBiddingBadge;

  // island wide badge
  String get islandWideBadge;

  // districts and fleet coverage
  String get districtsAndFleetCoverage;

  // search fleet hint
  String get searchFleetHint;

  // add service category
  String get addServiceCategory;

  // category title
  String get categoryTitle;

  // service description
  String get serviceDescription;

  // select trade icon
  String get selectTradeIcon;

  // save publish category
  String get savePublishCategory;

  // delete category
  String get deleteCategory;

  // delete category confirm
  String get deleteCategoryConfirm;

  // suspend artisan
  String get suspendArtisan;

  // read only ops governance
  String get readOnlyOpsGovernance;

  // no categories in db
  String get noCategoriesInDb;

  // add first category
  String get addFirstCategory;

  // admin team governance title
  String get adminTeamGovernanceTitle;

  // add new admin action
  String get addNewAdminAction;

  // total admins count
  String get totalAdminsCount;

  // registered platform accounts
  String get registeredPlatformAccounts;

  // super admins count
  String get superAdminsCount;

  // root governance leads
  String get rootGovernanceLeads;

  // active operators count
  String get activeOperatorsCount;

  // dispatch kyc duty
  String get dispatchKycDuty;

  // pending invites count
  String get pendingInvitesCount;

  // awaiting first sign in
  String get awaitingFirstSignIn;

  // search admin placeholder
  String get searchAdminPlaceholder;

  // role filter label
  String get roleFilterLabel;

  // all roles filter
  String get allRolesFilter;

  // role super admin badge
  String get roleSuperAdminBadge;

  // role ops admin badge
  String get roleOpsAdminBadge;

  // role support admin badge
  String get roleSupportAdminBadge;

  // you badge
  String get youBadge;

  // full root governance badge
  String get fullRootGovernanceBadge;

  // revoke admin access
  String get revokeAdminAccess;

  // revoke access confirm
  String revokeAccessConfirm(String name, String email);

  // revoke access
  String get revokeAccess;

  // admin access revoked
  String adminAccessRevoked(String name);

  // search technicians nic jobs
  String get searchTechniciansNicJobs;

  // island network status
  String get islandNetworkStatus;

  // operations alerts broadcasts
  String get operationsAlertsBroadcasts;

  // no active system alerts
  String get noActiveSystemAlerts;

  // dispute complaint center
  String get disputeComplaintCenter;

  // review user reports
  String get reviewUserReports;

  // total reports
  String get totalReports;

  // pending action
  String get pendingAction;

  // resolved cases
  String get resolvedCases;

  // search disputes placeholder
  String get searchDisputesPlaceholder;

  // resolve complaint
  String get resolveComplaint;

  // dismiss complaint
  String get dismissComplaint;

  // suspend service provider
  String get suspendServiceProvider;

  // reason for ban
  String get reasonForBan;

  // filter all filter
  String get filterAllFilter;

  // expand map
  String get expandMap;

  // close map
  String get closeMap;

  // admin access suspended
  String get adminAccessSuspended;

  // password reset sent
  String passwordResetSent(String email);

  // at least6 characters
  String get atLeast6Characters;

  // re enter password
  String get reEnterPassword;

  // gps location error
  String get gpsLocationError;

  // search chats placeholder
  String get searchChatsPlaceholder;

  // sign in to view messages
  String get signInToViewMessages;

  // failed to load conversations
  String get failedToLoadConversations;

  // no matching conversations
  String get noMatchingConversations;

  // no conversations yet
  String get noConversationsYet;

  // conversations empty desc
  String get conversationsEmptyDesc;

  // try searching another keyword
  String get trySearchingAnotherKeyword;

  // tap to start conversation
  String get tapToStartConversation;

  // unauthorized admin access
  String get unauthorizedAdminAccess;

  // profile picture updated
  String get profilePictureUpdated;

  // profile picture removed
  String get profilePictureRemoved;

  // failed to remove photo
  String get failedToRemovePhoto;

  // remove photo
  String get removePhoto;

  // time just now
  String get timeJustNow;

  // time minutes ago
  String timeMinutesAgo(int count);

  // time hours ago
  String timeHoursAgo(int count);

  // time days ago
  String timeDaysAgo(int count);

  // choose display language
  String get chooseDisplayLanguage;

  // online
  String get online;

  // offline
  String get offline;

  // you
  String get you;

  // messages
  String get messages;

  // arrival confirmed
  String get arrivalConfirmed;

  // language switched to
  String get languageSwitchedTo;

  // call
  String get call;

  // address hint
  String get addressHint;

  // need quick service
  String get needQuickService;

  // post job banner desc
  String get postJobBannerDesc;

  // post job and get quotes
  String get postJobAndGetQuotes;

  // no artisans match filters
  String get noArtisansMatchFilters;

  // try clearing search or filters
  String get tryClearingSearchOrFilters;

  // reset all filters
  String get resetAllFilters;

  // filter artisans
  String get filterArtisans;

  // online ready to bid
  String get onlineReadyToBid;

  // online ready to bid sub
  String get onlineReadyToBidSub;

  // emergency dispatch
  String get emergencyDispatch;

  // customer rating
  String get customerRating;

  // all ratings
  String get allRatings;

  // apply filters
  String get applyFilters;

  // top artisans
  String get topArtisans;

  // friend
  String get friend;

  // quick reply where are you
  String get quickReplyWhereAreYou;

  // quick reply waiting main gate
  String get quickReplyWaitingMainGate;

  // quick reply call when arrive
  String get quickReplyCallWhenArrive;

  // quick reply parking available
  String get quickReplyParkingAvailable;

  // quick reply on my way
  String get quickReplyOnMyWay;

  // could not connect chat
  String get couldNotConnectChat;

  // could not load chat
  String get couldNotLoadChat;

  // could not open chat
  String get couldNotOpenChat;

  // send msg to start chat
  String get sendMsgToStartChat;

  // type message
  String get typeMessage;

  // booking confirmed chat started
  String bookingConfirmedChatStarted(String providerName);

  // later
  String get later;

  // open chat
  String get openChat;

  // failed to accept quote
  String get failedToAcceptQuote;

  // eta delay notice
  String etaDelayNotice(int minutes);

  // artisan reported delay
  String artisanReportedDelay(String reason);

  // provider phone not available
  String get providerPhoneNotAvailable;

  // cancel booking confirm
  String get cancelBookingConfirm;

  // yes cancel
  String get yesCancel;

  // service request cancelled
  String get serviceRequestCancelled;

  // live tracking copied
  String get liveTrackingCopied;

  // destination
  String get destination;

  // live gps on the way
  String get liveGpsOnTheWay;

  // enable location services
  String get enableLocationServices;

  // location permission denied
  String get locationPermissionDenied;

  // location permission permanently denied
  String get locationPermissionPermanentlyDenied;

  // failed to detect location
  String get failedToDetectLocation;

  // failed to submit request
  String get failedToSubmitRequest;

  // report provider
  String get reportProvider;

  // experience
  String get experience;

  // no customer reviews
  String get noCustomerReviews;

  // complaint unprofessional conduct
  String get complaintUnprofessionalConduct;

  // complaint late no show
  String get complaintLateNoShow;

  // complaint poor quality
  String get complaintPoorQuality;

  // complaint safety concern
  String get complaintSafetyConcern;

  // complaint fraud issue
  String get complaintFraudIssue;

  // complaint other issue
  String get complaintOtherIssue;

  // report service provider
  String get reportServiceProvider;

  // reporting technician
  String reportingTechnician(String name, String title);

  // select complaint reason
  String get selectComplaintReason;

  // explain incident details
  String get explainIncidentDetails;

  // explain incident hint
  String get explainIncidentHint;

  // describe issue before submitting
  String get describeIssueBeforeSubmitting;

  // sign in to submit complaint
  String get signInToSubmitComplaint;

  // complaint submitted success
  String get complaintSubmittedSuccess;

  // submit official report
  String get submitOfficialReport;

  // job id number
  String jobIdNumber(String id);

  // settled directly
  String get settledDirectly;

  // tip200
  String get tip200;

  // tip500
  String get tip500;

  // service diagnostic
  String get serviceDiagnostic;

  // technician
  String get technician;

  // today
  String get today;

  // by technician
  String byTechnician(String name);

  // account and services
  String get accountAndServices;

  // home service gps location
  String get homeServiceGpsLocation;

  // tap to auto detect gps
  String get tapToAutoDetectGps;

  // gps location updated
  String gpsLocationUpdated(String lat, String lng);

  // could not obtain gps
  String get couldNotObtainGps;

  // current mode
  String currentMode(String mode);

  // failed to pick image
  String get failedToPickImage;

  // complaint price dispute
  String get complaintPriceDispute;

  // failed to submit report
  String get failedToSubmitReport;

  // express dispatch caps
  String get expressDispatchCaps;

  // auto passes in seconds
  String autoPassesInSeconds(int seconds);

  // urgent caps
  String get urgentCaps;

  // seconds unit
  String get secondsUnit;

  // guaranteed base payout caps
  String get guaranteedBasePayoutCaps;

  // cash at service site
  String get cashAtServiceSite;

  // nearby
  String get nearby;

  // accept job
  String get acceptJob;

  // pass to next artisan
  String get passToNextArtisan;

  // pull over safely warning
  String get pullOverSafelyWarning;

  // service request
  String get serviceRequest;

  // client address
  String get clientAddress;

  // duration mins
  String durationMins(int minutes);

  // duration hours
  String durationHours(int hours);

  // duration one and half hours
  String get durationOneAndHalfHours;

  // failed to submit quote
  String failedToSubmitQuote(String error);

  // delay reported notice
  String delayReportedNotice(String reason);

  // customer location
  String get customerLocation;

  // customer location not available call
  String get customerLocationNotAvailableCall;

  // customer location named
  String customerLocationNamed(String name);

  // you en route
  String get youEnRoute;

  // in distance
  String inDistance(String distance);

  // navigating to
  String navigatingTo(String target);

  // failed to upload photo
  String failedToUploadPhoto(String error);

  // failed to submit verification
  String failedToSubmitVerification(String error);

  // step2 of3
  String get step2Of3;

  // nav jobs
  String get navJobs;

  // verification under review
  String get verificationUnderReview;

  // status pending review caps
  String get statusPendingReviewCaps;

  // nic under review desc
  String get nicUnderReviewDesc;

  // return to dashboard
  String get returnToDashboard;

  // verify identity subtitle
  String get verifyIdentitySubtitle;

  // nic front side
  String get nicFrontSide;

  // nic front side desc
  String get nicFrontSideDesc;

  // capture or upload front
  String get captureOrUploadFront;

  // nic front tip
  String get nicFrontTip;

  // nic back side
  String get nicBackSide;

  // nic back side desc
  String get nicBackSideDesc;

  // capture or upload back
  String get captureOrUploadBack;

  // nic back tip
  String get nicBackTip;

  // selfie holding nic
  String get selfieHoldingNic;

  // selfie holding nic desc
  String get selfieHoldingNicDesc;

  // open camera
  String get openCamera;

  // live portrait test
  String get livePortraitTest;

  // selfie tip
  String get selfieTip;

  // fast turnaround title
  String get fastTurnaroundTitle;

  // fast turnaround body
  String get fastTurnaroundBody;

  // sms alert title
  String get smsAlertTitle;

  // sms alert body
  String get smsAlertBody;

  // quality standard title
  String get qualityStandardTitle;

  // quality standard body
  String get qualityStandardBody;

  // submit for verification
  String get submitForVerification;

  // attached status
  String get attachedStatus;

  // required status
  String get requiredStatus;

  // photo attached tap replace
  String get photoAttachedTapReplace;

  // new label
  String get newLabel;

  // n reviews
  String nReviews(int count);

  // n jobs completed
  String nJobsCompleted(int count);

  // fleet active
  String get fleetActive;

  // category specialist
  String categorySpecialist(String category);

  // instant match active
  String get instantMatchActive;

  // offline switch on desc
  String get offlineSwitchOnDesc;

  // n new
  String nNew(int count);

  // accept direct booking
  String get acceptDirectBooking;

  // distance away
  String distanceAway(String distance);

  // eta label
  String get etaLabel;

  // mins unit
  String get minsUnit;

  // certified artisan
  String get certifiedArtisan;

  // add admin grant one permission
  String get addAdminGrantOnePermission;

  // add admin failed
  String addAdminFailed(String error);

  // add admin account created
  String get addAdminAccountCreated;

  // add admin success body
  String addAdminSuccessBody(String role);

  // add admin title
  String get addAdminTitle;

  // add admin subtitle
  String get addAdminSubtitle;

  // add admin enter full name
  String get addAdminEnterFullName;

  // add admin work email
  String get addAdminWorkEmail;

  // add admin enter work email
  String get addAdminEnterWorkEmail;

  // add admin mobile optional
  String get addAdminMobileOptional;

  // add admin tier
  String get addAdminTier;

  // add admin operational permissions
  String get addAdminOperationalPermissions;

  // add admin adding
  String get addAdminAdding;

  // add admin grant role
  String get addAdminGrantRole;

  // edit perm select one
  String get editPermSelectOne;

  // edit perm updated for
  String editPermUpdatedFor(String name);

  // edit perm failed
  String editPermFailed(String error);

  // edit perm change tier
  String get editPermChangeTier;

  // edit perm assigned
  String get editPermAssigned;

  // edit perm updating
  String get editPermUpdating;

  // edit perm save
  String get editPermSave;

  // sidebar only super admins
  String get sidebarOnlySuperAdmins;

  // sidebar no permission
  String get sidebarNoPermission;

  // sidebar colombo central hub
  String get sidebarColomboCentralHub;

  // top bar search
  String get topBarSearch;

  // top bar support messages
  String get topBarSupportMessages;

  // top bar administrator
  String get topBarAdministrator;

  // cdm published categories info
  String get cdmPublishedCategoriesInfo;

  // cdm category title hint
  String get cdmCategoryTitleHint;

  // cdm service description hint
  String get cdmServiceDescriptionHint;

  // cdm enter category title
  String get cdmEnterCategoryTitle;

  // cdm category saved
  String cdmCategorySaved(String title);

  // cdm delete category confirm
  String cdmDeleteCategoryConfirm(String name);

  // cdm category deleted
  String cdmCategoryDeleted(String name);

  // cdm delete
  String get cdmDelete;

  // cdm read only mode ops governance
  String get cdmReadOnlyModeOpsGovernance;

  // cdm fleet subtitle
  String get cdmFleetSubtitle;

  // cdm no categories desc
  String get cdmNoCategoriesDesc;

  // cdm dynamic quotes
  String get cdmDynamicQuotes;

  // cdm artisans bid per job
  String get cdmArtisansBidPerJob;

  // cdm pause category
  String get cdmPauseCategory;

  // cdm activate category
  String get cdmActivateCategory;

  // cdm filter all count
  String cdmFilterAllCount(String count);

  // cdm filter online count
  String cdmFilterOnlineCount(String count);

  // cdm filter suspended count
  String cdmFilterSuspendedCount(String count);

  // cdm filter offline count
  String cdmFilterOfflineCount(String count);

  // cdm no artisans match search
  String get cdmNoArtisansMatchSearch;

  // cdm no artisans in filter
  String get cdmNoArtisansInFilter;

  // cdm badge suspended
  String get cdmBadgeSuspended;

  // cdm badge online
  String get cdmBadgeOnline;

  // cdm badge offline
  String get cdmBadgeOffline;

  // cdm sri lanka
  String get cdmSriLanka;

  // cdm base rate
  String cdmBaseRate(String amount);

  // cdm suspension reason
  String cdmSuspensionReason(String reason);

  // cdm complaints
  String get cdmComplaints;

  // cdm suspend
  String get cdmSuspend;

  // cdm restore unban
  String get cdmRestoreUnban;

  // cdm delete artisan permanently
  String get cdmDeleteArtisanPermanently;

  // cdm suspend name
  String cdmSuspendName(String name);

  // cdm suspend confirm body
  String get cdmSuspendConfirmBody;

  // cdm reason for suspension
  String get cdmReasonForSuspension;

  // cdm artisan suspended
  String cdmArtisanSuspended(String name);

  // cdm confirm suspension
  String get cdmConfirmSuspension;

  // cdm restore name
  String cdmRestoreName(String name);

  // cdm restore confirm body
  String get cdmRestoreConfirmBody;

  // cdm artisan restored
  String cdmArtisanRestored(String name);

  // cdm restore access
  String get cdmRestoreAccess;

  // cdm delete artisan
  String get cdmDeleteArtisan;

  // cdm delete artisan confirm
  String cdmDeleteArtisanConfirm(String name);

  // cdm artisan deleted
  String cdmArtisanDeleted(String name);

  // cdm delete permanently
  String get cdmDeletePermanently;

  // cdm complaints for
  String cdmComplaintsFor(String name);

  // cdm no complaints filed
  String get cdmNoComplaintsFiled;

  // cdm no complaints desc
  String get cdmNoComplaintsDesc;

  // cdm by customer
  String cdmByCustomer(String name);

  // ledger status en route
  String get ledgerStatusEnRoute;

  // ledger jobs resolved island
  String ledgerJobsResolvedIsland(String count);

  // ledger dispatches active
  String ledgerDispatchesActive(String count);

  // ledger based on reviews
  String ledgerBasedOnReviews(String count);

  // ledger awaiting feedback
  String get ledgerAwaitingFeedback;

  // ledger service booking
  String get ledgerServiceBooking;

  // ledger delay minutes
  String ledgerDelayMinutes(String minutes);

  // admin role desc super
  String get adminRoleDescSuper;

  // admin role desc ops
  String get adminRoleDescOps;

  // admin role desc support
  String get adminRoleDescSupport;

  // perm manage admins label
  String get permManageAdminsLabel;

  // perm verify nic label
  String get permVerifyNicLabel;

  // perm manage categories label
  String get permManageCategoriesLabel;

  // perm broadcast alerts label
  String get permBroadcastAlertsLabel;

  // perm view finances label
  String get permViewFinancesLabel;

  // perm manage admins desc
  String get permManageAdminsDesc;

  // perm verify nic desc
  String get permVerifyNicDesc;

  // perm manage categories desc
  String get permManageCategoriesDesc;

  // perm broadcast alerts desc
  String get permBroadcastAlertsDesc;

  // perm view finances desc
  String get permViewFinancesDesc;

  // admin status invited
  String get adminStatusInvited;

  // admin status suspended
  String get adminStatusSuspended;

  // cust artisan label
  String get custArtisanLabel;

  // cust default system language
  String get custDefaultSystemLanguage;

  // cust metres away
  String custMetresAway(int metres);

  // cust km away value
  String custKmAwayValue(String km);

  // cust fallback area colombo03
  String get custFallbackAreaColombo03;

  // cust fallback western province
  String get custFallbackWesternProvince;

  // cust fallback colombo
  String get custFallbackColombo;

  // cust share tracking text
  String custShareTrackingText(String link);

  // cust rate per hour
  String custRatePerHour(String amount);

  // cust gps tap to update
  String custGpsTapToUpdate(String lat, String lng);

  // cust inspection suffix
  String get custInspectionSuffix;

  // cust service provider label
  String get custServiceProviderLabel;

  // live map col artisan
  String get liveMapColArtisan;

  // live map col assigned zone
  String get liveMapColAssignedZone;

  // live map col payout
  String get liveMapColPayout;

  // live map col quick dispatch
  String get liveMapColQuickDispatch;

  // live map status available idle
  String get liveMapStatusAvailableIdle;

  // live map status active verified
  String get liveMapStatusActiveVerified;

  // live map nic verified
  String get liveMapNicVerified;

  // live map nic pending
  String get liveMapNicPending;

  // live map zone colombo metro
  String get liveMapZoneColomboMetro;

  // live map payout today
  String liveMapPayoutToday(String amount);

  // live map today paren
  String get liveMapTodayParen;

  // live map action dispatch
  String get liveMapActionDispatch;

  // live map action reassign
  String get liveMapActionReassign;

  // live map dispatch dialog title
  String liveMapDispatchDialogTitle(String action, String name);

  // live map quotes received
  String liveMapQuotesReceived(int count);

  // live map live count
  String liveMapLiveCount(int count);

  // live map active count
  String liveMapActiveCount(int count);

  // live map action required
  String get liveMapActionRequired;

  // live map show all districts
  String get liveMapShowAllDistricts;

  // live map unmapped provider one
  String liveMapUnmappedProviderOne(int count);

  // live map unmapped provider many
  String liveMapUnmappedProviderMany(int count);

  // disputes not available
  String get disputesNotAvailable;

  // disputes resolve notes prompt
  String get disputesResolveNotesPrompt;

  // disputes dismiss notes prompt
  String get disputesDismissNotesPrompt;

  // disputes resolution summary hint
  String get disputesResolutionSummaryHint;

  // disputes marked resolved snack
  String get disputesMarkedResolvedSnack;

  // disputes dismissed snack
  String get disputesDismissedSnack;

  // disputes mark resolved
  String get disputesMarkResolved;

  // disputes confirm dismiss
  String get disputesConfirmDismiss;

  // disputes ban confirm
  String disputesBanConfirm(String name, String trade);

  // disputes suspend provider
  String get disputesSuspendProvider;

  // disputes provider suspended snack
  String disputesProviderSuspendedSnack(String name);

  // disputes suspend customer
  String get disputesSuspendCustomer;

  // disputes customer suspended snack
  String disputesCustomerSuspendedSnack(String name);

  // account suspended title
  String get accountSuspendedTitle;

  // account suspended desc
  String get accountSuspendedDesc;

  // contact helpline
  String get contactHelpline;

  // disputes error loading
  String disputesErrorLoading(String error);

  // disputes filter all count
  String disputesFilterAllCount(int count);

  // disputes filter pending count
  String disputesFilterPendingCount(int count);

  // disputes filter resolved count
  String disputesFilterResolvedCount(int count);

  // disputes filter dismissed count
  String disputesFilterDismissedCount(int count);

  // disputes no matching
  String get disputesNoMatching;

  // disputes none recorded
  String get disputesNoneRecorded;

  // disputes try adjusting search
  String get disputesTryAdjustingSearch;

  // disputes all dispute free
  String get disputesAllDisputeFree;

  // disputes status resolved caps
  String get disputesStatusResolvedCaps;

  // disputes status dismissed caps
  String get disputesStatusDismissedCaps;

  // disputes status pending caps
  String get disputesStatusPendingCaps;

  // disputes filed ago
  String disputesFiledAgo(String time);

  // disputes customer caps
  String get disputesCustomerCaps;

  // disputes reported caps
  String get disputesReportedCaps;

  // disputes admin note
  String disputesAdminNote(String note);

  // disputes reopen case
  String get disputesReopenCase;

  // disputes case reopened snack
  String get disputesCaseReopenedSnack;

  // shell super admin only
  String get shellSuperAdminOnly;

  // prov location not set
  String get provLocationNotSet;

  // prov direct pay
  String get provDirectPay;

  // prov specialist
  String get provSpecialist;

  // prov nic image too large
  String provNicImageTooLarge(int sizeKb);

  // prov nic decode failed
  String get provNicDecodeFailed;

  // prov nic too large after compression
  String get provNicTooLargeAfterCompression;

  // prov user not authenticated
  String get provUserNotAuthenticated;

  // prov not logged in
  String get provNotLoggedIn;

  // prov nic hint example
  String get provNicHintExample;

  // prov duration hours mins
  String provDurationHoursMins(int hours, int minutes);

  // auth gps location detected
  String authGpsLocationDetected(String lat, String lng);

  // auth failed to pick profile photo
  String authFailedToPickProfilePhoto(String error);

  // auth err user not found
  String get authErrUserNotFound;

  // auth err wrong credentials
  String get authErrWrongCredentials;

  // auth err email in use
  String get authErrEmailInUse;

  // auth err weak password
  String get authErrWeakPassword;

  // auth err invalid email
  String get authErrInvalidEmail;

  // auth err user disabled
  String get authErrUserDisabled;

  // auth err too many requests
  String get authErrTooManyRequests;

  // auth err network
  String get authErrNetwork;

  // auth err sign in cancelled
  String get authErrSignInCancelled;

  // auth err user data unavailable
  String get authErrUserDataUnavailable;

  // auth err already admin
  String get authErrAlreadyAdmin;

  // auth err authentication failed
  String authErrAuthenticationFailed(String email);

  // auth err registration failed
  String authErrRegistrationFailed(String email);

  // auth err no registered user
  String authErrNoRegisteredUser(String email);

  // nic desk approved activated
  String nicDeskApprovedActivated(String name);

  // nic desk error approving
  String nicDeskErrorApproving(String error);

  // nic desk verification rejected
  String nicDeskVerificationRejected(String name);

  // nic desk error rejecting
  String nicDeskErrorRejecting(String error);

  // nic desk requested clearer photo
  String nicDeskRequestedClearerPhoto(String name);

  // nic desk error resubmission
  String nicDeskErrorResubmission(String error);

  // nic desk pending count
  String nicDeskPendingCount(int count);

  // nic desk sorted most recent
  String get nicDeskSortedMostRecent;

  // nic desk docs uploaded
  String get nicDeskDocsUploaded;

  // nic desk standard doc
  String get nicDeskStandardDoc;

  // nic desk match percent
  String nicDeskMatchPercent(int percent);

  // nic desk default location
  String get nicDeskDefaultLocation;

  // nic desk verified gn division
  String nicDeskVerifiedGnDivision(String location);

  // nic desk ocr flagged
  String get nicDeskOcrFlagged;

  // nic desk ocr match
  String get nicDeskOcrMatch;

  // nic desk ocr valid
  String get nicDeskOcrValid;

  // nic desk read only mode
  String get nicDeskReadOnlyMode;

  // nic desk no id
  String get nicDeskNoId;

  // nic desk no image
  String get nicDeskNoImage;

  // nic desk tap to zoom
  String get nicDeskTapToZoom;

  // team admin now status
  String teamAdminNowStatus(String name, String status);

  // team failed update status
  String teamFailedUpdateStatus(String error);

  // team read only view
  String get teamReadOnlyView;

  // team status filter label
  String get teamStatusFilterLabel;

  // team all statuses
  String get teamAllStatuses;

  // team no admins found
  String get teamNoAdminsFound;

  // team no admin matching
  String teamNoAdminMatching(String query);

  // team try changing filter
  String get teamTryChangingFilter;

  // team col administrator
  String get teamColAdministrator;

  // team col tier role
  String get teamColTierRole;

  // team col granted permissions
  String get teamColGrantedPermissions;

  // team col status
  String get teamColStatus;

  // team col actions
  String get teamColActions;

  // team managed in firebase
  String get teamManagedInFirebase;

  // team manage admin
  String get teamManageAdmin;

  // team edit permissions
  String get teamEditPermissions;

  // team protected
  String get teamProtected;

  // team active label
  String get teamActiveLabel;

  // admin set broadcast hint
  String get adminSetBroadcastHint;

  // admin set enter alert message
  String get adminSetEnterAlertMessage;

  // admin set broadcast dispatched
  String get adminSetBroadcastDispatched;

  // admin set broadcast failed
  String adminSetBroadcastFailed(String error);

  // admin set recent records
  String adminSetRecentRecords(int count);

  // admin set export audit log
  String get adminSetExportAuditLog;

  // admin set audit exported
  String get adminSetAuditExported;

  // admin set no audit logs
  String get adminSetNoAuditLogs;

  // admin set system action
  String get adminSetSystemAction;

  // admin set audit tag
  String get adminSetAuditTag;

  // admin set recent
  String get adminSetRecent;

  // admin set administrator fallback
  String get adminSetAdministratorFallback;

  // admin set platform governance
  String get adminSetPlatformGovernance;

  // admin set assigned permissions
  String get adminSetAssignedPermissions;

  // admin set audit logs desc
  String get adminSetAuditLogsDesc;

  // admin set audit access denied
  String get adminSetAuditAccessDenied;

  // verify your email
  String get verifyYourEmail;

  // verify email subtitle
  String verifyEmailSubtitle(String email);

  // enter verification code
  String get enterVerificationCode;

  // resend code
  String get resendCode;

  // resend code in
  String resendCodeIn(int seconds);

  // verify and continue
  String get verifyAndContinue;

  // code expired
  String get codeExpired;

  // code incorrect
  String get codeIncorrect;

  // email verified success
  String get emailVerifiedSuccess;

  // my job posts
  String get myJobPosts;

  // your posted jobs
  String yourPostedJobs(int count);

  // post new job
  String get postNewJob;

  // no job posts yet
  String get noJobPostsYet;

  // no job posts desc
  String get noJobPostsDesc;

  // review quotes count
  String reviewQuotesCount(int count);

  // location not specified
  String get locationNotSpecified;

  // permission location title
  String get permissionLocationTitle;

  // permission location desc
  String get permissionLocationDesc;

  // permission location bullet1
  String get permissionLocationBullet1;

  // permission location bullet2
  String get permissionLocationBullet2;

  // permission location bullet3
  String get permissionLocationBullet3;

  // permission allow and continue
  String get permissionAllowAndContinue;

  // permission select district manually
  String get permissionSelectDistrictManually;

  // permission camera title
  String get permissionCameraTitle;

  // permission camera desc
  String get permissionCameraDesc;

  // permission camera bullet1
  String get permissionCameraBullet1;

  // permission camera bullet2
  String get permissionCameraBullet2;

  // permission camera bullet3
  String get permissionCameraBullet3;

  // permission open camera
  String get permissionOpenCamera;

  // permission gallery title
  String get permissionGalleryTitle;

  // permission gallery desc
  String get permissionGalleryDesc;

  // permission gallery bullet1
  String get permissionGalleryBullet1;

  // permission gallery bullet2
  String get permissionGalleryBullet2;

  // permission gallery bullet3
  String get permissionGalleryBullet3;

  // permission choose photos
  String get permissionChoosePhotos;

  // permission location permanently disabled
  String get permissionLocationPermanentlyDisabled;

  // permission location needed
  String get permissionLocationNeeded;

  // nav user management
  String get navUserManagement;

  // search users hint
  String get searchUsersHint;

  // filter by role
  String get filterByRole;

  // all roles
  String get allRoles;

  // all districts
  String get allDistricts;

  // filter by status
  String get filterByStatus;

  // status suspended
  String get statusSuspended;

  // suspend account
  String get suspendAccount;

  // unban account
  String get unbanAccount;

  // enter ban reason
  String get enterBanReason;

  // ban reason hint
  String get banReasonHint;

  // confirm unban desc
  String get confirmUnbanDesc;

  // user suspended snack
  String get userSuspendedSnack;

  // user restored snack
  String get userRestoredSnack;

  // total users
  String get totalUsers;

  // active customers
  String get activeCustomers;

  // active providers
  String get activeProviders;

  // suspended accounts
  String get suspendedAccounts;

  // no users found
  String get noUsersFound;

  // nav user management subtitle
  String get navUserManagementSubtitle;

  // filter customers
  String get filterCustomers;

  // filter providers
  String get filterProviders;

  // filter admins
  String get filterAdmins;

  // filter by district title
  String get filterByDistrictTitle;

  // search district hint text
  String get searchDistrictHintText;

  // suspend user confirm desc
  String get suspendUserConfirmDesc;

  // please enter suspension reason
  String get pleaseEnterSuspensionReason;

  // preset abusive comm
  String get presetAbusiveComm;

  // preset fraud activity
  String get presetFraudActivity;

  // preset failed dispute
  String get presetFailedDispute;

  // preset policy violation
  String get presetPolicyViolation;

  // reason label
  String get reasonLabel;

  // suspended by admin
  String get suspendedByAdmin;

  // zoom in
  String get zoomIn;

  // zoom out
  String get zoomOut;

  // recenter map
  String get recenterMap;

  // super admin cannot be suspended
  String get superAdminCannotBeSuspended;

  // open settings
  String get openSettings;

  // ok
  String get ok;

  // permission camera permanently disabled
  String get permissionCameraPermanentlyDisabled;

  // permission camera disabled
  String get permissionCameraDisabled;

  // permission gallery permanently disabled
  String get permissionGalleryPermanentlyDisabled;

  // permission gallery disabled
  String get permissionGalleryDisabled;

  // permission notification title
  String get permissionNotificationTitle;

  // permission notification desc
  String get permissionNotificationDesc;

  // permission notification bullet1
  String get permissionNotificationBullet1;

  // permission notification bullet2
  String get permissionNotificationBullet2;

  // permission notification bullet3
  String get permissionNotificationBullet3;

  // permission enable notifications
  String get permissionEnableNotifications;

  // permission not now
  String get permissionNotNow;

  // permission notification needed
  String get permissionNotificationNeeded;

  // permission notification permanently disabled
  String get permissionNotificationPermanentlyDisabled;

  // no matches found
  String get noMatchesFound;

  // select option
  String get selectOption;

  // pro approval required title
  String get proApprovalRequiredTitle;

  // pro approval required desc
  String get proApprovalRequiredDesc;

  // pro verification status
  String get proVerificationStatus;

  // pro status pending review
  String get proStatusPendingReview;

  // pro status action required
  String get proStatusActionRequired;

  // pro status rejected
  String get proStatusRejected;

  // pro submit nic action
  String get proSubmitNicAction;

  // pro refresh status
  String get proRefreshStatus;

  // pro checking status
  String get proCheckingStatus;

  // pro approval granted title
  String get proApprovalGrantedTitle;

  // pro approval granted desc
  String get proApprovalGrantedDesc;

  // pro get started
  String get proGetStarted;

  // pro notifications title
  String get proNotificationsTitle;

  // pro no notifications
  String get proNoNotifications;

  // pro mark all read
  String get proMarkAllRead;

  // report to admin
  String get reportToAdmin;

  // report issue title
  String get reportIssueTitle;

  // report issue desc
  String get reportIssueDesc;

  // report reason prompt
  String get reportReasonPrompt;

  // report notes prompt
  String get reportNotesPrompt;

  // report submit button
  String get reportSubmitButton;

  // report submitting
  String get reportSubmitting;

  // report success snack
  String get reportSuccessSnack;

  // admin support channel title
  String get adminSupportChannelTitle;

  // admin support channel subtitle
  String get adminSupportChannelSubtitle;

  // file formal ticket
  String get fileFormalTicket;

  // cancel booking or quote
  String get cancelBookingOrQuote;

  // cancel booking prompt
  String get cancelBookingPrompt;

  // cancellation reason prompt
  String get cancellationReasonPrompt;

  // cancel reason customer request
  String get cancelReasonCustomerRequest;

  // cancel reason provider unavailable
  String get cancelReasonProviderUnavailable;

  // cancel reason schedule conflict
  String get cancelReasonScheduleConflict;

  // cancel reason price dispute
  String get cancelReasonPriceDispute;

  // cancel reason other
  String get cancelReasonOther;

  // confirm cancellation
  String get confirmCancellation;

  // booking cancelled success
  String get bookingCancelledSuccess;

  // repost job
  String get repostJob;

  // repost job confirm
  String get repostJobConfirm;

  // repost job success
  String get repostJobSuccess;

  // delete job
  String get deleteJob;

  // delete job confirm
  String get deleteJobConfirm;

  // delete job success
  String get deleteJobSuccess;

  // chat with provider
  String get chatWithProvider;

  // otp check spam hint title
  String get otpCheckSpamHintTitle;

  // otp check spam hint desc
  String get otpCheckSpamHintDesc;

  // logging out
  String get loggingOut;

  // nav messages
  String get navMessages;

  // closest first
  String get closestFirst;

  // newest first
  String get newestFirst;

  // all distances
  String get allDistances;

  // within5 km
  String get within5Km;

  // within10 km
  String get within10Km;

  // within25 km
  String get within25Km;

  // view on map
  String get viewOnMap;

  // nearby tag
  String get nearbyTag;

  // moderate tag
  String get moderateTag;

  // extended tag
  String get extendedTag;

  // est travel time
  String estTravelTime(int mins);

  // no jobs in radius
  String get noJobsInRadius;

  // filter role and status
  String get filterRoleAndStatus;

  // all statuses
  String get allStatuses;

  // clear filters
  String get clearFilters;

  // role all admins
  String get roleAllAdmins;

  // become service provider
  String get becomeServiceProvider;

  // back to customer dashboard
  String get backToCustomerDashboard;

  // cancel registration
  String get cancelRegistration;

  // role switch admin only desc
  String get roleSwitchAdminOnlyDesc;

  // admin provider preview notice
  String get adminProviderPreviewNotice;

  // resubmit verification
  String get resubmitVerification;

  // verification not approved title
  String get verificationNotApprovedTitle;

  // verification not approved body
  String get verificationNotApprovedBody;

  // pro verification pending review
  String get proVerificationPendingReview;

  // choose role title
  String get chooseRoleTitle;

  // choose role subtitle
  String get chooseRoleSubtitle;

  // role customer title
  String get roleCustomerTitle;

  // role customer desc
  String get roleCustomerDesc;

  // role customer badge
  String get roleCustomerBadge;

  // role customer perk1
  String get roleCustomerPerk1;

  // role customer perk2
  String get roleCustomerPerk2;

  // role customer perk3
  String get roleCustomerPerk3;

  // role provider title
  String get roleProviderTitle;

  // role provider desc
  String get roleProviderDesc;

  // role provider badge
  String get roleProviderBadge;

  // role provider perk1
  String get roleProviderPerk1;

  // role provider perk2
  String get roleProviderPerk2;

  // role provider perk3
  String get roleProviderPerk3;

  // select service location
  String get selectServiceLocation;

  // use current gps location
  String get useCurrentGpsLocation;

  // saved addresses
  String get savedAddresses;

  // service address label
  String get serviceAddressLabel;

  // service address hint
  String get serviceAddressHint;

  // landmark or note optional
  String get landmarkOrNoteOptional;

  // landmark hint
  String get landmarkHint;

  // save address for future
  String get saveAddressForFuture;

  // confirm location
  String get confirmLocation;

  // select pin on map
  String get selectPinOnMap;

  // generic service
  String get genericService;

  // enter reason for suspension
  String get enterReasonForSuspension;

  // app language label
  String get appLanguageLabel;

  // profile photo approved
  String get profilePhotoApproved;

  // error approving photo
  String errorApprovingPhoto(String error);

  // error approving nic
  String errorApprovingNic(String error);

  // trade certifications approved
  String get tradeCertificationsApproved;

  // error approving certifications
  String errorApprovingCertifications(String error);

  // approve dp
  String get approveDp;

  // dp approved
  String get dpApproved;

  // approve nic both
  String get approveNicBoth;

  // approve certs
  String get approveCerts;

  // take profile photo
  String get takeProfilePhoto;

  // select profile photo
  String get selectProfilePhoto;

  // failed to complete profile
  String failedToCompleteProfile(String error);

  // service category
  String get serviceCategory;

  // please enter full name
  String get pleaseEnterFullName;

  // failed to set role
  String failedToSetRole(String error);

  // saved address label hint
  String get savedAddressLabelHint;

  // landmark note optional
  String get landmarkNoteOptional;

  // delete saved address
  String get deleteSavedAddress;

  // confirm delete saved address
  String get confirmDeleteSavedAddress;

  // add new
  String get addNew;

  // set service location
  String get setServiceLocation;

  // failed to update job location
  String failedToUpdateJobLocation(String error);

  // please select service location
  String get pleaseSelectServiceLocation;

  // confirm service location
  String get confirmServiceLocation;

  // pin attempts reset zero
  String get pinAttemptsResetZero;

  // cannot cancel in progress booking
  String get cannotCancelInProgressBooking;

  // service verification
  String get serviceVerification;

  // rate service provider
  String get rateServiceProvider;

  // job completed successfully
  String get jobCompletedSuccessfully;

  // verify and finish
  String get verifyAndFinish;

  // call customer
  String get callCustomer;

  // direct service booking
  String get directServiceBooking;

  // sign in cancelled by user
  String get signInCancelledByUser;

  // could not detect location
  String couldNotDetectLocation(String error);

  // unauthorized role switch
  String get unauthorizedRoleSwitch;

  // give pin hint
  String get givePinHint;

  // direct booking with
  String directBookingWith(String providerName);

  // direct booking with note
  String directBookingWithNote(String providerName, String note);

  // nic verified
  String get nicVerified;

  // status approved
  String get statusApproved;

  // use gps
  String get useGps;

  // location
  String get location;

  // delete
  String get delete;

  // edit
  String get edit;

  // service date
  String get serviceDate;

  // agreed price
  String get agreedPrice;

  // pin verified
  String get pinVerified;

  // provider details title
  String get providerDetailsTitle;

  // decline
  String get decline;

  // did you pay amount
  String didYouPayAmount(String amount, String name);

  // yes paid
  String get yesPaid;

  // report payment problem
  String get reportPaymentProblem;

  // cash payment confirmed
  String get cashPaymentConfirmed;

  // payment disputed with reason
  String paymentDisputedWithReason(String reason);

  // dispute payment prompt
  String get disputePaymentPrompt;

  // dispute payment reason hint
  String get disputePaymentReasonHint;

  // submit dispute
  String get submitDispute;

  // pay provider directly tip
  String get payProviderDirectlyTip;

  // cash received
  String get cashReceived;

  // payment note optional
  String get paymentNoteOptional;

  // payment note hint
  String get paymentNoteHint;

  // final amount exceeds limit
  String get finalAmountExceedsLimit;

  // payment waiting confirmation
  String get paymentWaitingConfirmation;

  // payment confirmed
  String get paymentConfirmed;

  // payment disputed
  String get paymentDisputed;

  // earnings today
  String get earningsToday;

  // earnings this week
  String get earningsThisWeek;

  // earnings this month
  String get earningsThisMonth;

  // total earnings
  String get totalEarnings;

  // export csv
  String get exportCsv;

  // csv export success
  String get csvExportSuccess;

  // pin code
  String get pinCode;

  // did you reach person
  String didYouReachPerson(String name);

  // call outcome answered
  String get callOutcomeAnswered;

  // call outcome no answer
  String get callOutcomeNoAnswer;

  // call outcome wrong number
  String get callOutcomeWrongNumber;

  // call requires accepted quote
  String get callRequiresAcceptedQuote;

  // call logs title
  String get callLogsTitle;

  // call log caller
  String get callLogCaller;

  // call log callee
  String get callLogCallee;

  // call log outcome
  String get callLogOutcome;

  // booking timeline title
  String get bookingTimelineTitle;

  // no timeline events
  String get noTimelineEvents;

  // view timeline
  String get viewTimeline;

  // admin action logs title
  String get adminActionLogsTitle;

  // admin audit trail subtitle
  String get adminAuditTrailSubtitle;

  // no admin logs found
  String get noAdminLogsFound;

  // filter users
  String get filterUsers;

  // filter bookings
  String get filterBookings;

  // filter system
  String get filterSystem;

  // no entries to export
  String get noEntriesToExport;

  // delete account title
  String get deleteAccountTitle;

  // delete account confirmation
  String get deleteAccountConfirmation;

  // delete account confirm action
  String get deleteAccountConfirmAction;

  // privacy policy
  String get privacyPolicy;

  // terms of service
  String get termsOfService;

  // photo
  String get photo;

  // send photo
  String get sendPhoto;

  // uploading image
  String get uploadingImage;

  // failed to upload image
  String get failedToUploadImage;

  // view photo
  String get viewPhoto;

  // booking type asap
  String get bookingTypeAsap;

  // booking type scheduled
  String get bookingTypeScheduled;

  // select scheduled date
  String get selectScheduledDate;

  // select time slot
  String get selectTimeSlot;

  // slot morning
  String get slotMorning;

  // slot afternoon
  String get slotAfternoon;

  // slot evening
  String get slotEvening;

  // reschedule booking
  String get rescheduleBooking;

  // propose new time
  String get proposeNewTime;

  // reschedule reason prompt
  String get rescheduleReasonPrompt;

  // reschedule reason hint
  String get rescheduleReasonHint;

  // submit reschedule request
  String get submitRescheduleRequest;

  // reschedule proposal banner
  String get rescheduleProposalBanner;

  // accept reschedule
  String get acceptReschedule;

  // decline reschedule
  String get declineReschedule;

  // cancel reschedule proposal
  String get cancelRescheduleProposal;

  // expired pill
  String get expiredPill;

  // working hours title
  String get workingHoursTitle;

  // service radius title
  String get serviceRadiusTitle;

  // service radius subtitle
  String get serviceRadiusSubtitle;

  // day monday
  String get dayMonday;

  // day tuesday
  String get dayTuesday;

  // day wednesday
  String get dayWednesday;

  // day thursday
  String get dayThursday;

  // day friday
  String get dayFriday;

  // day saturday
  String get daySaturday;

  // day sunday
  String get daySunday;

  // open time
  String get openTime;

  // close time
  String get closeTime;

  // closed day
  String get closedDay;

  // preset weekdays
  String get presetWeekdays;

  // preset all days
  String get presetAllDays;

  // preset247
  String get preset247;

  // unavailable now
  String get unavailableNow;

  // outside working hours
  String get outsideWorkingHours;

  // saved schedule success
  String get savedScheduleSuccess;

  // saved radius success
  String get savedRadiusSuccess;

  // service radius km
  String serviceRadiusKm(int radius);

  // reschedule requested notice
  String get rescheduleRequestedNotice;

  // save changes
  String get saveChanges;

  // job photos subtitle
  String get jobPhotosSubtitle;

  // before photos
  String get beforePhotos;

  // after photos
  String get afterPhotos;

  // add before photo
  String get addBeforePhoto;

  // add after photo
  String get addAfterPhoto;

  // no before photos
  String get noBeforePhotos;

  // no after photos
  String get noAfterPhotos;

  // portfolio title
  String get portfolioTitle;

  // portfolio subtitle
  String get portfolioSubtitle;

  // add portfolio item
  String get addPortfolioItem;

  // portfolio item title
  String get portfolioItemTitle;

  // portfolio item title hint
  String get portfolioItemTitleHint;

  // portfolio item desc
  String get portfolioItemDesc;

  // portfolio item desc hint
  String get portfolioItemDescHint;

  // upload photo
  String get uploadPhoto;

  // photo uploaded success
  String get photoUploadedSuccess;

  // portfolio item added
  String get portfolioItemAdded;

  // delete portfolio confirm
  String get deletePortfolioConfirm;

  // no portfolio items
  String get noPortfolioItems;

  // category label
  String get categoryLabel;

  // select category prompt
  String get selectCategoryPrompt;

  // new provider badge
  String get newProviderBadge;

  // block user title
  String get blockUserTitle;

  // block user confirm
  String get blockUserConfirm;

  // block user action
  String get blockUserAction;

  // unblock user action
  String get unblockUserAction;

  // user blocked success
  String get userBlockedSuccess;

  // user unblocked success
  String get userUnblockedSuccess;

  // report user title
  String get reportUserTitle;

  // report reason label
  String get reportReasonLabel;

  // report reason harassment
  String get reportReasonHarassment;

  // report reason spam
  String get reportReasonSpam;

  // report reason fraud
  String get reportReasonFraud;

  // report reason no show
  String get reportReasonNoShow;

  // report reason safety
  String get reportReasonSafety;

  // report reason other
  String get reportReasonOther;

  // report details hint
  String get reportDetailsHint;

  // report also block
  String get reportAlsoBlock;

  // report submitted success
  String get reportSubmittedSuccess;

  // offline banner text
  String get offlineBannerText;

  // retry action
  String get retryAction;

  // force update title
  String get forceUpdateTitle;

  // force update message
  String get forceUpdateMessage;

  // update now action
  String get updateNowAction;

  // emergency dispatch title
  String get emergencyDispatchTitle;

  // emergency dispatch subtitle
  String get emergencyDispatchSubtitle;

  // scanning nearby providers
  String get scanningNearbyProviders;

  // dispatch timer label
  String get dispatchTimerLabel;

  // no emergency providers found
  String get noEmergencyProvidersFound;

  // no emergency providers desc
  String get noEmergencyProvidersDesc;

  // emergency callout rate
  String get emergencyCalloutRate;

  // emergency eta approx
  String emergencyEtaApprox(int mins);

  // distance km away
  String distanceKmAway(String dist);

  // request emergency callout
  String get requestEmergencyCallout;

  // confirm emergency booking title
  String get confirmEmergencyBookingTitle;

  // confirm emergency booking desc
  String confirmEmergencyBookingDesc(String name, String rate);

  // emergency address prompt
  String get emergencyAddressPrompt;

  // emergency notes prompt
  String get emergencyNotesPrompt;

  // emergency notes hint
  String get emergencyNotesHint;

  // emergency hotlines title
  String get emergencyHotlinesTitle;

  // hotline police
  String get hotlinePolice;

  // hotline ambulance
  String get hotlineAmbulance;

  // hotline fire
  String get hotlineFire;

  // urgent help banner title
  String get urgentHelpBannerTitle;

  // urgent help banner desc
  String get urgentHelpBannerDesc;

  // urgent help banner action
  String get urgentHelpBannerAction;

  // my rates
  String get myRates;

  // rate card title
  String get rateCardTitle;

  // daily rate
  String get dailyRate;

  // per km travel rate
  String get perKmTravelRate;

  // standard visit fee
  String get standardVisitFee;

  // quote type firm
  String get quoteTypeFirm;

  // quote type estimate
  String get quoteTypeEstimate;

  // quote type inspect
  String get quoteTypeInspect;

  // price revision proposed
  String get priceRevisionProposed;

  // extra work requested
  String get extraWorkRequested;

  // visit only completed note
  String get visitOnlyCompletedNote;

  // completion type normal
  String get completionTypeNormal;

  // completion type visit only
  String get completionTypeVisitOnly;

  // hourly rate
  String get hourlyRate;

  // your usual rates
  String get yourUsualRates;

  // your usual rates subtitle
  String get yourUsualRatesSubtitle;

  // daily rate hint
  String get dailyRateHint;

  // hourly rate hint
  String get hourlyRateHint;

  // per km rate hint
  String get perKmRateHint;

  // visit fee optional hint
  String get visitFeeOptionalHint;

  // at least one rate required
  String get atLeastOneRateRequired;

  // daily rate range error
  String get dailyRateRangeError;

  // hourly rate range error
  String get hourlyRateRangeError;

  // per km rate range error
  String get perKmRateRangeError;

  // visit fee range error
  String get visitFeeRangeError;

  // within agreed price
  String get withinAgreedPrice;

  // visit fee only
  String get visitFeeOnly;

  // approved extras breakdown
  String get approvedExtrasBreakdown;

  // initial estimate label
  String get initialEstimateLabel;

  // revised agreed price
  String get revisedAgreedPrice;

  // final amount to pay
  String get finalAmountToPay;

  // price matches quote
  String get priceMatchesQuote;

  // propose new price
  String get proposeNewPrice;

  // propose revised price
  String get proposeRevisedPrice;

  // billing unit
  String get billingUnit;

  // billing unit fixed
  String get billingUnitFixed;

  // billing unit hour
  String get billingUnitHour;

  // billing unit day
  String get billingUnitDay;

  // unit rate lkr
  String get unitRateLkr;

  // quantity label
  String get quantityLabel;

  // price change reason
  String get priceChangeReason;

  // price change reason hint
  String get priceChangeReasonHint;

  // total revised price
  String get totalRevisedPrice;

  // submit proposal
  String get submitProposal;

  // add extra work item
  String get addExtraWorkItem;

  // extra description
  String get extraDescription;

  // extra description hint
  String get extraDescriptionHint;

  // extra amount lkr
  String get extraAmountLkr;

  // propose extra
  String get proposeExtra;

  // awaiting customer approval
  String get awaitingCustomerApproval;

  // price proposal sent
  String get priceProposalSent;

  // extra proposal sent
  String get extraProposalSent;

  // price confirmed matches
  String get priceConfirmedMatches;

  // price proposal rejected
  String get priceProposalRejected;

  // price proposal approved
  String get priceProposalApproved;

  // my rate card
  String get myRateCard;

  // rate card subtitle
  String get rateCardSubtitle;

  // save rates
  String get saveRates;

  // rate card updated success
  String get rateCardUpdatedSuccess;

  // travel rate
  String get travelRate;

  // pricing standard rates
  String get pricingStandardRates;

  // upload retry
  String get uploadRetry;

  // large media warning title
  String get largeMediaWarningTitle;

  // large media warning message
  String get largeMediaWarningMessage;

  // proceed
  String get proceed;

  // something went wrong
  String get somethingWentWrong;

  // customer did not agree visit only
  String customerDidNotAgreeVisitOnly(String amount);

  // complete visit only
  String get completeVisitOnly;

  // price revision reason required
  String get priceRevisionReasonRequired;

  // check rate and quantity
  String get checkRateAndQuantity;

  // extra description limit
  String get extraDescriptionLimit;

  // extra amount limit
  String get extraAmountLimit;

  // notes limit500
  String get notesLimit500;

  // valid visit fee prompt
  String get validVisitFeePrompt;

  // valid unit rate prompt
  String get validUnitRatePrompt;

  // valid quantity prompt
  String get validQuantityPrompt;

  // materials estimate limit
  String get materialsEstimateLimit;

  // visit inspection fee
  String get visitInspectionFee;

  // materials estimate colon
  String get materialsEstimateColon;

  // add issue video max
  String get addIssueVideoMax;

  // record video
  String get recordVideo;

  // error picking video
  String get errorPickingVideo;

  // video of issue optional
  String get videoOfIssueOptional;

  // job video
  String get jobVideo;

  // video clip
  String get videoClip;

  // failed to play video
  String get failedToPlayVideo;

  // failed to update rates
  String get failedToUpdateRates;

  // quote outdated declined
  String get quoteOutdatedDeclined;

  // you are meters away
  String youAreMetersAway(String distance);

  // im here gps wrong
  String get imHereGpsWrong;

  // slide to claim arrival
  String get slideToClaimArrival;

  // waiting customer confirmation
  String get waitingCustomerConfirmation;

  // arrival denied provider notice
  String get arrivalDeniedProviderNotice;

  // claim again arrival
  String get claimAgainArrival;

  // max claims reached
  String get maxClaimsReached;

  // customer did not answer
  String get customerDidNotAnswer;

  // start job verified gps
  String get startJobVerifiedGps;

  // call customer to confirm
  String get callCustomerToConfirm;

  // provider says arrived
  String providerSaysArrived(String providerName);

  // provider gps shows away
  String providerGpsShowsAway(String distance);

  // yes they are here
  String get yesTheyAreHere;

  // no not here
  String get noNotHere;

  // provider did not come
  String get providerDidNotCome;

  // confirm no show title
  String get confirmNoShowTitle;

  // confirm no show message
  String get confirmNoShowMessage;

  // location required to book
  String get locationRequiredToBook;

  // arrival mocked flag
  String get arrivalMockedFlag;

  // arrival outside zone flag
  String get arrivalOutsideZoneFlag;

  // arrival denied flag
  String get arrivalDeniedFlag;

  // no show flag
  String get noShowFlag;

  // gps outside zone alert
  String gpsOutsideZoneAlert(String distance);

  // proceed anyway
  String get proceedAnyway;

  // claim success notified
  String get claimSuccessNotified;

  // complete job enter pin
  String get completeJobEnterPin;

  // no show reported success
  String get noShowReportedSuccess;

  // provider reliability90 days
  String get providerReliability90Days;

  // provider no shows count
  String get providerNoShowsCount;

  // provider arrival denials count
  String get providerArrivalDenialsCount;

  // provider mocked gps count
  String get providerMockedGpsCount;

  // provider outside zone count
  String get providerOutsideZoneCount;

  // scheduled time passed prompt
  String get scheduledTimePassedPrompt;

  // choose new schedule title
  String get chooseNewScheduleTitle;

  // revised estimate default
  String get revisedEstimateDefault;

  // please enter six digits
  String get pleaseEnterSixDigits;

  // customer location not available title
  String get customerLocationNotAvailableTitle;

  // customer location not available desc
  String get customerLocationNotAvailableDesc;

  // location required title
  String get locationRequiredTitle;

  // job no location repost
  String get jobNoLocationRepost;

  // quote accepted chat message
  String quoteAcceptedChatMessage(String providerName, String price);

  // please enter service location
  String get pleaseEnterServiceLocation;

  // optimizing video notice
  String get optimizingVideoNotice;

  // add short video
  String get addShortVideo;

  // add short video subtitle
  String get addShortVideoSubtitle;

  // no services available yet
  String get noServicesAvailableYet;

  // edit saved address
  String get editSavedAddress;

  // sign in to manage saved addresses
  String get signInToManageSavedAddresses;

  // no saved addresses subtitle
  String get noSavedAddressesSubtitle;

  // become provider subtitle
  String get becomeProviderSubtitle;

  // switch to provider
  String get switchToProvider;

  // switch to provider subtitle
  String get switchToProviderSubtitle;

  // admin inspection mode
  String get adminInspectionMode;

  // admin inspection mode desc
  String get adminInspectionModeDesc;

  // set standard rates subtitle
  String get setStandardRatesSubtitle;

  // quote accepted title
  String get quoteAcceptedTitle;

  // customer confirmed booking
  String get customerConfirmedBooking;

  // enter project title
  String get enterProjectTitle;

  // select photo for showcase
  String get selectPhotoForShowcase;

  // failed to save showcase
  String failedToSaveShowcase(String error);

  // quote type
  String get quoteType;

  // inspection quote notice
  String get inspectionQuoteNotice;

  // materials estimate optional
  String get materialsEstimateOptional;

  // est distance km
  String get estDistanceKm;

  // travel rate lkr km
  String get travelRateLkrKm;

  // total quoted price
  String get totalQuotedPrice;

  // travel fee
  String get travelFee;

  // status selected
  String get statusSelected;

  // provider base location required
  String get providerBaseLocationRequired;

  // base workshop location
  String get baseWorkshopLocation;

  // base location dispatch notice
  String get baseLocationDispatchNotice;

  // suspension reason label
  String get suspensionReasonLabel;

  // register banner subtitle
  String get registerBannerSubtitle;

  // sort order
  String get sortOrder;

  // is live
  String get isLive;

  // edit category
  String get editCategory;

  // price history audit
  String get priceHistoryAudit;

  // final charged amount
  String get finalChargedAmount;

  // suspend customer confirm prompt
  String suspendCustomerConfirmPrompt(String name);

  // unable to load photo
  String get unableToLoadPhoto;

  // new time label
  String get newTimeLabel;

  // note label
  String get noteLabel;

  // reset pin attempts
  String get resetPinAttempts;

  // no service history yet
  String get noServiceHistoryYet;

  // no service history subtitle
  String get noServiceHistorySubtitle;

  // your rating review
  String get yourRatingReview;

  // sign in to view bookings
  String get signInToViewBookings;

  // pending admin approval unavailable
  String get pendingAdminApprovalUnavailable;

  // direct contact fast quotes
  String get directContactFastQuotes;

  // verified phone available
  String get verifiedPhoneAvailable;

  // official support
  String get officialSupport;

  // failed to save schedule
  String get failedToSaveSchedule;

  // status confirmed
  String get statusConfirmed;

  // status en route
  String get statusEnRoute;

  // status declined
  String get statusDeclined;

  // status assigned
  String get statusAssigned;

  // status scheduled
  String get statusScheduled;

  // completion pin label
  String get completionPinLabel;

  // chat photo message
  String get chatPhotoMessage;

  // hint full name
  String get hintFullName;

  // hint email
  String get hintEmail;

  // hint phone
  String get hintPhone;

  // hint category search
  String get hintCategorySearch;

  // hint amount
  String get hintAmount;

  // hint nic format
  String get hintNicFormat;

  // hint customer name
  String get hintCustomerName;

  // hint provider email
  String get hintProviderEmail;

  // hint admin name
  String get hintAdminName;

  // price status label
  String get priceStatusLabel;

  // proposed label
  String get proposedLabel;

  // role service provider
  String get roleServiceProvider;

  // role super admin
  String get roleSuperAdmin;

  // role support admin
  String get roleSupportAdmin;

  // role operations admin
  String get roleOperationsAdmin;

  // general dispute
  String get generalDispute;

  // nic approved message
  String get nicApprovedMessage;

  // nic under review message
  String get nicUnderReviewMessage;

  // amount lkr label
  String amountLkrLabel(Object amount);

  // search category hint
  String get searchCategoryHint;

  // search district hint
  String get searchDistrictHint;

  // visit fee only description
  String get visitFeeOnlyDescription;

  // provider verification pending
  String get providerVerificationPending;

  // send quote lkr
  String sendQuoteLkr(Object amount);

  // custom quote
  String get customQuote;

  // past service
  String get pastService;

  // you en route label
  String get youEnRouteLabel;

  // hint job address
  String get hintJobAddress;

  // hint category name
  String get hintCategoryName;

  // hint amount lkr
  String get hintAmountLkr;

  // complaint investigation suspended
  String complaintInvestigationSuspended(String reason);

  // admin suspension violations
  String get adminSuspensionViolations;

  // category created with sort order
  String categoryCreatedWithSortOrder(String name, int order);

  // category updated with sort order
  String categoryUpdatedWithSortOrder(String name, int order, bool status);

  // category deleted name
  String categoryDeletedName(String name);

  // category description default
  String categoryDescriptionDefault(String service);

  // zero registered
  String get zeroRegistered;

  // zero online now
  String get zeroOnlineNow;

  // market rate
  String get marketRate;

  // category updated success
  String categoryUpdatedSuccess(String name);

  // manual dispatch assigned
  String get manualDispatchAssigned;

  // dispatch title
  String get dispatchTitle;

  // reassign title
  String get reassignTitle;

  // manual dispatch assigned desc
  String manualDispatchAssignedDesc(
      String provider, String job, String address);

  // ledger price status
  String ledgerPriceStatus(String status);

  // ledger proposed lkr
  String ledgerProposedLkr(String amount);

  // ledger customer
  String get ledgerCustomer;

  // verification flagged
  String get verificationFlagged;

  // verification match
  String get verificationMatch;

  // verification valid
  String get verificationValid;

  // profile trust photo rationale
  String get profileTrustPhotoRationale;

  // profile choose gallery photo
  String get profileChooseGalleryPhoto;

  // capture nic front
  String get captureNicFront;

  // capture nic back
  String get captureNicBack;

  // capture nic prompt
  String get captureNicPrompt;

  // select nic front
  String get selectNicFront;

  // select nic back
  String get selectNicBack;

  // select nic gallery prompt
  String get selectNicGalleryPrompt;

  // complete provider profile title
  String get completeProviderProfileTitle;

  // providing services across sri lanka
  String get providingServicesAcrossSriLanka;

  // requesting domestic services
  String get requestingDomesticServices;

  // phone placeholder pattern
  String get phonePlaceholderPattern;

  // select service category
  String get selectServiceCategory;

  // update pin button
  String get updatePinButton;

  // pick on map button
  String get pickOnMapButton;

  // workshop address required label
  String get workshopAddressRequiredLabel;

  // operating address required error
  String get operatingAddressRequiredError;

  // complete provider registration
  String get completeProviderRegistration;

  // save profile
  String get saveProfile;

  // phone not set
  String get phoneNotSet;

  // address label home
  String get addressLabelHome;

  // address label work
  String get addressLabelWork;

  // address label other
  String get addressLabelOther;

  // video exceeds max120s
  String get videoExceedsMax120s;

  // failed to process video
  String failedToProcessVideo(String error);

  // job location label
  String get jobLocationLabel;

  // select job location subtitle
  String get selectJobLocationSubtitle;

  // change button
  String get changeButton;

  // set pin button
  String get setPinButton;

  // set pin here button
  String get setPinHereButton;

  // upload failed attempts
  String get uploadFailedAttempts;

  // booking past service
  String get bookingPastService;

  // booking status completed
  String get bookingStatusCompleted;

  // booking not specified
  String get bookingNotSpecified;

  // booking status scheduled
  String get bookingStatusScheduled;

  // quantity unit label
  String quantityUnitLabel(String unit);

  // rate hourly unit
  String get rateHourlyUnit;

  // rate daily unit
  String get rateDailyUnit;

  // rate travel unit
  String get rateTravelUnit;

  // picker tab form
  String get pickerTabForm;

  // picker tab map pin
  String get pickerTabMapPin;

  // camera permission rationale
  String get cameraPermissionRationale;

  // photo library permission rationale
  String get photoLibraryPermissionRationale;

  // privacy data collection points
  String get privacyDataCollectionPoints;

  // timeline booking created
  String get timelineBookingCreated;

  // timeline booking accepted
  String get timelineBookingAccepted;

  // timeline arrival claimed
  String get timelineArrivalClaimed;

  // timeline arrival denied
  String get timelineArrivalDenied;

  // timeline auto started
  String get timelineAutoStarted;

  // timeline visit fee only
  String get timelineVisitFeeOnly;

  // timeline price proposed
  String get timelinePriceProposed;

  // timeline price approved
  String get timelinePriceApproved;

  // timeline price rejected
  String get timelinePriceRejected;

  // timeline extra requested
  String get timelineExtraRequested;

  // timeline extra approved
  String get timelineExtraApproved;

  // timeline extra rejected
  String get timelineExtraRejected;

  // timeline payment confirmed
  String get timelinePaymentConfirmed;

  // timeline payment disputed
  String get timelinePaymentDisputed;

  // timeline no show reported
  String get timelineNoShowReported;

  // timeline before photo added
  String get timelineBeforePhotoAdded;

  // timeline after photo added
  String get timelineAfterPhotoAdded;

  // status open
  String get statusOpen;

  // status dispatched
  String get statusDispatched;

  // select job location
  String get selectJobLocation;

  // tap to pick location desc
  String get tapToPickLocationDesc;

  // set pin
  String get setPin;

  // rate card summary
  String rateCardSummary(Object visitFee, Object hourlyRate);

  // standard visit fee with currency
  String get standardVisitFeeWithCurrency;

  // hourly rate with unit
  String get hourlyRateWithUnit;

  // daily rate with unit
  String get dailyRateWithUnit;

  // travel rate with unit
  String get travelRateWithUnit;

  // price matches quote amount
  String priceMatchesQuoteAmount(Object amount);

  // quantity with unit
  String quantityWithUnit(String unit);

  // unit hours
  String get unitHours;

  // unit days
  String get unitDays;

  // unit jobs
  String get unitJobs;

  // language english
  String get languageEnglish;

  // language sinhala
  String get languageSinhala;

  // language tamil
  String get languageTamil;

  // location permission required
  String get locationPermissionRequired;

  // none
  String get none;

  // optional
  String get optional;

  // error provider category missing
  String get errorProviderCategoryMissing;

  // perm manage users label
  String get permManageUsersLabel;

  // perm manage users desc
  String get permManageUsersDesc;

  // perm handle support label
  String get permHandleSupportLabel;

  // perm handle support desc
  String get permHandleSupportDesc;

  // no permission for action
  String get noPermissionForAction;

  // help and support
  String get helpAndSupport;

  // my tickets
  String get myTickets;

  // report a problem
  String get reportAProblem;

  // ticket reply prompt
  String get ticketReplyPrompt;

  // ticket status open
  String get ticketStatusOpen;

  // ticket status in progress
  String get ticketStatusInProgress;

  // ticket status waiting user
  String get ticketStatusWaitingUser;

  // ticket status resolved
  String get ticketStatusResolved;

  // ticket status closed
  String get ticketStatusClosed;

  // type help
  String get typeHelp;

  // type report user
  String get typeReportUser;

  // type booking problem
  String get typeBookingProblem;

  // type payment dispute
  String get typePaymentDispute;

  // type account
  String get typeAccount;

  // type app problem
  String get typeAppProblem;

  // type feedback
  String get typeFeedback;

  // ticket subject
  String get ticketSubject;

  // ticket description
  String get ticketDescription;

  // ticket send
  String get ticketSend;

  // ticket attach photo
  String get ticketAttachPhoto;

  // ticket reply hint
  String get ticketReplyHint;

  // ticket close confirm
  String get ticketCloseConfirm;

  // ticket resolved note
  String get ticketResolvedNote;

  // ticket assign to me
  String get ticketAssignToMe;

  // warn user
  String get warnUser;

  // ban user
  String get banUser;

  // support phone
  String get supportPhone;

  // support email
  String get supportEmail;

  // call support
  String get callSupport;

  // email support
  String get emailSupport;

  // no tickets yet
  String get noTicketsYet;

  // ticket created success
  String get ticketCreatedSuccess;

  // help support title
  String get helpSupportTitle;

  // help support subtitle
  String get helpSupportSubtitle;

  // report problem title
  String get reportProblemTitle;

  // exact current location
  String get exactCurrentLocation;

  // location accuracy
  String locationAccuracy(int meters);

  // location accuracy low warning
  String locationAccuracyLowWarning(int meters);

  // fine tune pin instruction
  String get fineTunePinInstruction;

  // house apt no
  String get houseAptNo;

  // street name
  String get streetName;

  // town city
  String get townCity;

  // landmark optional
  String get landmarkOptional;

  // directions for provider
  String get directionsForProvider;

  // save this address
  String get saveThisAddress;

  // location required hint
  String get locationRequiredHint;

  // schedule mode asap
  String get scheduleModeAsap;

  // schedule mode date only
  String get scheduleModeDateOnly;

  // schedule mode time range
  String get scheduleModeTimeRange;

  // schedule any time
  String get scheduleAnyTime;

  // schedule from
  String get scheduleFrom;

  // schedule to
  String get scheduleTo;

  // schedule min duration error
  String get scheduleMinDurationError;

  // schedule max duration error
  String get scheduleMaxDurationError;

  // schedule same day error
  String get scheduleSameDayError;

  // schedule past error
  String get schedulePastError;

  // schedule today past cutoff
  String get scheduleTodayPastCutoff;

  // outside working hours warning
  String get outsideWorkingHoursWarning;

  // admin2fa title
  String get admin2faTitle;

  // admin2fa subtitle
  String get admin2faSubtitle;

  // login verification title
  String get loginVerificationTitle;

  // login verification subtitle
  String loginVerificationSubtitle(String email);

  // use different account
  String get useDifferentAccount;

  // continue as customer
  String get continueAsCustomer;

  // otp no session
  String get otpNoSession;

  // otp expired resend
  String get otpExpiredResend;

  // otp max attempts resend
  String get otpMaxAttemptsResend;

  // otp incorrect tries left
  String otpIncorrectTriesLeft(int count);

  // code already sent
  String get codeAlreadySent;

  // ticket submit permission denied
  String get ticketSubmitPermissionDenied;

  // ticket submit error general
  String get ticketSubmitErrorGeneral;

  // ticket category
  String get ticketCategory;

  // please fill required fields
  String get pleaseFillRequiredFields;

  // ticket photo upload failed
  String get ticketPhotoUploadFailed;

  // video upload mobile only
  String get videoUploadMobileOnly;

  // delete account subtitle
  String get deleteAccountSubtitle;

  // move pin to gate hint
  String get movePinToGateHint;

  // not here choose another
  String get notHereChooseAnother;

  // could not get location fallback
  String get couldNotGetLocationFallback;

  // try gps again
  String get tryGpsAgain;

  // add details for provider
  String get addDetailsForProvider;

  // provider note label
  String get providerNoteLabel;

  // provider note hint
  String get providerNoteHint;

  // save this place
  String get saveThisPlace;

  // search on map
  String get searchOnMap;

  // search place hint
  String get searchPlaceHint;

  // accuracy badge
  String accuracyBadge(int meters);

  // saved
  String get saved;

  // media upload failed retry
  String get mediaUploadFailedRetry;

  // job post permission denied
  String get jobPostPermissionDenied;

  // job post error general
  String get jobPostErrorGeneral;

  // emergency rate unavailable
  String get emergencyRateUnavailable;

  // nic upload error retry
  String get nicUploadErrorRetry;

  // email otp required error
  String get emailOtpRequiredError;

  // profile completion error
  String get profileCompletionError;

  // invalid nic format error
  String get invalidNicFormatError;

  // provider pending title
  String get providerPendingTitle;

  // provider pending subtitle
  String get providerPendingSubtitle;

  // provider rejected title
  String get providerRejectedTitle;

  // provider rejected subtitle
  String get providerRejectedSubtitle;

  // rejection reason label
  String get rejectionReasonLabel;

  // submitted details title
  String get submittedDetailsTitle;

  // submitted date label
  String get submittedDateLabel;

  // service category label
  String get serviceCategoryLabel;

  // applicant name label
  String get applicantNameLabel;

  // fix and resubmit
  String get fixAndResubmit;

  // provider pending customer toast
  String get providerPendingCustomerToast;

  // provider approved celebration
  String get providerApprovedCelebration;

  // provider application status badge
  String get providerApplicationStatusBadge;

  // provider application under review
  String get providerApplicationUnderReview;

  // provider application action needed
  String get providerApplicationActionNeeded;

  // provider resubmit title
  String get providerResubmitTitle;

  // provider resubmit subtitle
  String get providerResubmitSubtitle;

  // auto checks title
  String get autoChecksTitle;

  // nic format valid
  String get nicFormatValid;

  // nic format invalid
  String get nicFormatInvalid;

  // nic decoded birth and gender
  String get nicDecodedBirthAndGender;

  // age check valid
  String get ageCheckValid;

  // age check under18
  String get ageCheckUnder18;

  // duplicate nic detected
  String get duplicateNicDetected;

  // duplicate phone detected
  String get duplicatePhoneDetected;

  // no duplicates found
  String get noDuplicatesFound;

  // duplicate warning banner
  String get duplicateWarningBanner;

  // approval checklist title
  String get approvalChecklistTitle;

  // chk photo clear
  String get chkPhotoClear;

  // chk name matches
  String get chkNameMatches;

  // chk nic matches
  String get chkNicMatches;

  // chk face matches
  String get chkFaceMatches;

  // chk card not edited
  String get chkCardNotEdited;

  // all checks required
  String get allChecksRequired;

  // request resubmission
  String get requestResubmission;

  // reject application
  String get rejectApplication;

  // rejection reason dialog title
  String get rejectionReasonDialogTitle;

  // select preset reason
  String get selectPresetReason;

  // reason blurry photo
  String get reasonBlurryPhoto;

  // reason name mismatch
  String get reasonNameMismatch;

  // reason nic mismatch
  String get reasonNicMismatch;

  // reason wrong side
  String get reasonWrongSide;

  // reason face mismatch
  String get reasonFaceMismatch;

  // reason other
  String get reasonOther;

  // optional reviewer note
  String get optionalReviewerNote;

  // filter pending
  String get filterPending;

  // filter resubmitted
  String get filterResubmitted;

  // filter rejected
  String get filterRejected;

  // filter approved
  String get filterApproved;

  // face comparison title
  String get faceComparisonTitle;

  // profile photo label
  String get profilePhotoLabel;

  // nic front label
  String get nicFrontLabel;

  // nic back label
  String get nicBackLabel;

  // rotate photo
  String get rotatePhoto;

  // zoom hint
  String get zoomHint;

  // audit history title
  String get auditHistoryTitle;

  // submission attempt
  String submissionAttempt(String number);

  // no search results
  String get noSearchResults;

  // search unavailable fallback
  String get searchUnavailableFallback;

  // recent places
  String get recentPlaces;

  // use my current location
  String get useMyCurrentLocation;

  // showing jobs near you now
  String get showingJobsNearYouNow;

  // showing jobs near base
  String showingJobsNearBase(String area);

  // showing jobs near base no area
  String get showingJobsNearBaseNoArea;

  // set base location prompt
  String get setBaseLocationPrompt;

  // set base location btn
  String get setBaseLocationBtn;

  // away now
  String awayNow(String distance);

  // based away
  String basedAway(String distance);

  // location last updated mins ago
  String locationLastUpdatedMinsAgo(String minutes);

  // estimated label
  String get estimatedLabel;

  // base location title
  String get baseLocationTitle;

  // base location desc
  String get baseLocationDesc;

  // how do you charge title
  String get howDoYouChargeTitle;

  // how do you charge subtitle
  String get howDoYouChargeSubtitle;

  // pricing mode per hour
  String get pricingModePerHour;

  // pricing mode per day
  String get pricingModePerDay;

  // pricing mode price per job
  String get pricingModePricePerJob;

  // pricing mode visit fee
  String get pricingModeVisitFee;

  // pricing mode travel per km
  String get pricingModeTravelPerKm;

  // at least one base pricing mode required
  String get atLeastOneBasePricingModeRequired;

  // travel included
  String get travelIncluded;

  // quote each job
  String get quoteEachJob;

  // travel title
  String get travelTitle;

  // could not load exact location retry
  String get couldNotLoadExactLocationRetry;

  // getting your location
  String get gettingYourLocation;

  // try again
  String get tryAgain;

  // customer location missing call customer
  String get customerLocationMissingCallCustomer;

  // location sharing notification title
  String get locationSharingNotificationTitle;

  // location sharing notification text
  String get locationSharingNotificationText;

  // preparing media
  String get preparingMedia;

  // uploading photo progress
  String uploadingPhotoProgress(int current, int total);

  // upload photo bytes progress
  String uploadPhotoBytesProgress(
      int current, int total, String sentMb, String totalMb);

  // uploading video thumbnail
  String get uploadingVideoThumbnail;

  // uploading video file
  String get uploadingVideoFile;

  // upload video bytes progress
  String uploadVideoBytesProgress(String sentMb, String totalMb);

  // ticket assigned to you
  String get ticketAssignedToYou;

  // open booking timeline
  String openBookingTimeline(String id);

  // mark in review action
  String get markInReviewAction;

  // resolve action
  String get resolveAction;

  // dismiss action
  String get dismissAction;

  // message history title
  String get messageHistoryTitle;

  // no replies yet
  String get noRepliesYet;

  // reply as support admin hint
  String get replyAsSupportAdminHint;

  // nic warning under18
  String nicWarningUnder18(int age);

  // nic duplicate check not available
  String get nicDuplicateCheckNotAvailable;

  // nic duplicate nic approved
  String nicDuplicateNicApproved(String name, String id);

  // nic duplicate nic pending
  String nicDuplicateNicPending(String name, String id);

  // nic duplicate phone
  String nicDuplicatePhone(String name);

  // notification identity approved title
  String get notificationIdentityApprovedTitle;

  // notification identity approved body
  String get notificationIdentityApprovedBody;

  // hero verified artisans
  String get heroVerifiedArtisans;

  // hero live tracking
  String get heroLiveTracking;

  // hero transparent quotes
  String get heroTransparentQuotes;

  // hero direct quote requests
  String get heroDirectQuoteRequests;

  // hero private secure chat
  String get heroPrivateSecureChat;

  // hero community rated
  String get heroCommunityRated;

  // support ticket close confirm
  String get supportTicketCloseConfirm;

  // ticket closed message
  String get ticketClosedMessage;

  // ticket not found
  String get ticketNotFound;

  // booking timeline with id
  String bookingTimelineWithId(String id);

  // view ticket and thread
  String get viewTicketAndThread;

  // refresh images
  String get refreshImages;

  // quantity range min max
  String quantityRangeMinMax(String min, String max);

  // timeline desc created
  String get timelineDescCreated;

  // timeline desc accepted
  String get timelineDescAccepted;

  // timeline desc declined
  String get timelineDescDeclined;

  // timeline desc cancelled
  String get timelineDescCancelled;

  // timeline desc en route
  String get timelineDescEnRoute;

  // timeline desc arrived
  String get timelineDescArrived;

  // timeline desc arrival claimed
  String get timelineDescArrivalClaimed;

  // timeline desc arrival confirmed
  String get timelineDescArrivalConfirmed;

  // timeline desc arrival denied
  String get timelineDescArrivalDenied;

  // timeline desc arrival auto started
  String get timelineDescArrivalAutoStarted;

  // timeline desc completed
  String get timelineDescCompleted;

  // timeline desc completed visit only
  String get timelineDescCompletedVisitOnly;

  // timeline desc payment confirmed
  String get timelineDescPaymentConfirmed;

  // timeline desc payment disputed
  String get timelineDescPaymentDisputed;

  // timeline desc price proposed
  String get timelineDescPriceProposed;

  // timeline desc price approved
  String get timelineDescPriceApproved;

  // timeline desc price rejected
  String get timelineDescPriceRejected;

  // timeline desc price kept
  String get timelineDescPriceKept;

  // timeline desc extra requested
  String get timelineDescExtraRequested;

  // timeline desc extra approved
  String get timelineDescExtraApproved;

  // timeline desc extra rejected
  String get timelineDescExtraRejected;

  // timeline desc no show reported
  String get timelineDescNoShowReported;

  // timeline desc before photo added
  String get timelineDescBeforePhotoAdded;

  // timeline desc after photo added
  String get timelineDescAfterPhotoAdded;

  // timeline desc reschedule requested
  String get timelineDescRescheduleRequested;

  // timeline desc reschedule accepted
  String get timelineDescRescheduleAccepted;

  // timeline desc reschedule declined
  String get timelineDescRescheduleDeclined;

  // failed to set role generic
  String get failedToSetRoleGeneric;

  // role switch locked provider blocked
  String get roleSwitchLockedProviderBlocked;

  // cert upload section title
  String get certUploadSectionTitle;

  // cert upload section hint
  String get certUploadSectionHint;

  // cert upload button
  String get certUploadButton;

  // cert upload choose files
  String get certUploadChooseFiles;

  // cert upload max files error
  String get certUploadMaxFilesError;

  // cert upload file too large error
  String certUploadFileTooLargeError(String fileName);

  // cert upload unsupported type error
  String certUploadUnsupportedTypeError(String fileName);

  // cert upload title hint
  String get certUploadTitleHint;

  // cert default title
  String get certDefaultTitle;

  // cert certified badge
  String get certCertifiedBadge;

  // cert approved section title
  String get certApprovedSectionTitle;

  // cert add more
  String get certAddMore;

  // cert save button
  String get certSaveButton;

  // cert submitted success
  String get certSubmittedSuccess;

  // cert trade licenses title
  String certTradeLicensesTitle(int count);

  // cert number title
  String certNumberTitle(int number);

  // cert approve all
  String get certApproveAll;

  // cert reject reason title
  String get certRejectReasonTitle;

  // cert reject reason prompt
  String get certRejectReasonPrompt;

  // cert reject reason required
  String get certRejectReasonRequired;

  // cert approved notice
  String get certApprovedNotice;

  // cert rejected notice
  String get certRejectedNotice;

  // cert all approved notice
  String get certAllApprovedNotice;

  // quote rate for job hint
  String get quoteRateForJobHint;

  // quote inspect visit fee prompt
  String get quoteInspectVisitFeePrompt;

  // quote include visit cost hint
  String get quoteIncludeVisitCostHint;

  // quote add travel cost
  String get quoteAddTravelCost;

  // could not open maps
  String get couldNotOpenMaps;

  // location sharing stopped
  String get locationSharingStopped;

  // use current location action
  String get useCurrentLocationAction;

  // search place action
  String get searchPlaceAction;

  // approximate location warning
  String approximateLocationWarning(String minutes);

  // location outside sri lanka
  String get locationOutsideSriLanka;

  // set action
  String get setAction;

  // distance filter
  String get distanceFilter;

  // any distance
  String get anyDistance;

  // only serves my area
  String get onlyServesMyArea;

  // sort by nearest
  String get sortByNearest;

  // sort by top rated
  String get sortByTopRated;

  // show up to50 km
  String get showUpTo50Km;

  // providers near area
  String providersNearArea(String area);

  // under1 km away
  String get under1KmAway;

  // online now badge
  String get onlineNowBadge;

  // saved offline sync later
  String get savedOfflineSyncLater;

  // could not save check connection
  String get couldNotSaveCheckConnection;

  // provider profile not setup desc
  String get providerProfileNotSetupDesc;

  // complete registration action
  String get completeRegistrationAction;

  // set your usual rates
  String get setYourUsualRates;

  // price per job amount
  String pricePerJobAmount(String amount);

  // rate per day
  String ratePerDay(String amount);

  // rate per hour
  String ratePerHour(String amount);

  // rate visit fee
  String rateVisitFee(String amount);

  // rate per km
  String ratePerKm(String amount);

  // when do you need this
  String get whenDoYouNeedThis;

  // schedule mode today
  String get scheduleModeToday;

  // schedule mode specific day
  String get scheduleModeSpecificDay;

  // schedule mode flexible
  String get scheduleModeFlexible;

  // urgent help hint
  String get urgentHelpHint;

  // today disabled past20
  String get todayDisabledPast20;

  // slot anytime label
  String get slotAnytimeLabel;

  // slot morning short
  String get slotMorningShort;

  // slot afternoon short
  String get slotAfternoonShort;

  // slot evening short
  String get slotEveningShort;

  // slot anytime short
  String get slotAnytimeShort;

  // slot exact time
  String get slotExactTime;

  // flexible within3 days
  String get flexibleWithin3Days;

  // flexible within week
  String get flexibleWithinWeek;

  // flexible within2 weeks
  String get flexibleWithin2Weeks;

  // slot passed
  String get slotPassed;

  // cancel job title
  String get cancelJobTitle;

  // cancel job confirm prompt
  String get cancelJobConfirmPrompt;

  // cancel reason found someone
  String get cancelReasonFoundSomeone;

  // cancel reason no longer needed
  String get cancelReasonNoLongerNeeded;

  // cancel reason too expensive
  String get cancelReasonTooExpensive;

  // withdraw bid
  String get withdrawBid;

  // withdraw bid confirm prompt
  String get withdrawBidConfirmPrompt;

  // bid withdrawn success
  String get bidWithdrawnSuccess;

  // quote no longer available
  String get quoteNoLongerAvailable;

  // provider withdrew quote notice
  String get providerWithdrewQuoteNotice;

  // clash warning bidding
  String get clashWarningBidding;

  // clash warning post win
  String clashWarningPostWin(int count);

  // review bids button
  String get reviewBidsButton;

  // coverage warning count
  String coverageWarningCount(int count);

  // coverage warning zero
  String get coverageWarningZero;

  // my bids active tab
  String get myBidsActiveTab;

  // my bids past tab
  String get myBidsPastTab;

  // bid status pending
  String get bidStatusPending;

  // bid status accepted
  String get bidStatusAccepted;

  // bid status not selected
  String get bidStatusNotSelected;

  // bid status withdrawn
  String get bidStatusWithdrawn;

  // bid status job closed
  String get bidStatusJobClosed;

  // when can you come
  String get whenCanYouCome;

  // select day inside window
  String get selectDayInsideWindow;

  // pending job post banner
  String get pendingJobPostBanner;

  // job not found title
  String get jobNotFoundTitle;

  // job post failed title
  String get jobPostFailedTitle;

  // job load error title
  String get jobLoadErrorTitle;

  // cancel upload
  String get cancelUpload;

  // back action
  String get backAction;

  // tap location to see nearby
  String get tapLocationToSeeNearby;

  // location permission or gps disabled
  String get locationPermissionOrGpsDisabled;

  // your location outside sri lanka
  String get yourLocationOutsideSriLanka;

  // set location manually
  String get setLocationManually;

  // share location action
  String get shareLocationAction;

  // near me
  String get nearMe;

  // show nearby artisans
  String get showNearbyArtisans;

  // choose another area
  String get chooseAnotherArea;

  // location options
  String get locationOptions;

  // invalid request
  String get invalidRequest;

  // login otp required
  String get loginOtpRequired;

  // request timeout
  String get requestTimeout;

  // waiting for connection
  String get waitingForConnection;

  // post again
  String get postAgain;

  // post again success
  String get postAgainSuccess;

  // old photos unavailable
  String get oldPhotosUnavailable;

  // video not copied note
  String get videoNotCopiedNote;

  // some photos failed download
  String get somePhotosFailedDownload;

  // photos removed
  String get photosRemoved;

  // location locked has quotes
  String get locationLockedHasQuotes;

  // category cannot be edited
  String get categoryCannotBeEdited;

  // edit job post
  String get editJobPost;

  // edit job success
  String get editJobSuccess;

  // job updated badge
  String get jobUpdatedBadge;

  // delete job post
  String get deleteJobPost;

  // delete job post confirm
  String get deleteJobPostConfirm;

  // delete job post success
  String get deleteJobPostSuccess;

  // remove from history
  String get removeFromHistory;

  // remove from history confirm
  String get removeFromHistoryConfirm;

  // remove from history success
  String get removeFromHistorySuccess;

  // job expired title
  String get jobExpiredTitle;

  // job expired body
  String get jobExpiredBody;

  // history tab
  String get historyTab;

  // quote count bids
  String quoteCountBids(int count);

  // repost
  String get repost;

  // repost now
  String get repostNow;

  // edit details first
  String get editDetailsFirst;

  // repost job title
  String get repostJobTitle;

  // status expired
  String get statusExpired;

  // status deleted
  String get statusDeleted;

  // expired on
  String expiredOn(String date);

  // cancelled on
  String cancelledOn(String date);

  // completed on
  String completedOn(String date);

  // posted on
  String postedOn(String date);

  // renew post title
  String get renewPostTitle;

  // renew post prompt
  String get renewPostPrompt;

  // renew post success
  String get renewPostSuccess;

  // undo
  String get undo;

  // undo delete post success
  String get undoDeletePostSuccess;

  // provider cancellations count
  String get providerCancellationsCount;

  // provider cancelled prompt
  String get providerCancelledPrompt;

  // provider cancelled expired prompt
  String get providerCancelledExpiredPrompt;

  // use current location
  String get useCurrentLocation;

  // pick on map
  String get pickOnMap;

  // not set yet
  String get notSetYet;

  // updated time ago
  String updatedTimeAgo(String time);

  // hela service support
  String get helaServiceSupport;

  // need help contact support
  String get needHelpContactSupport;

  // new reply
  String get newReply;

  // start trip
  String get startTrip;

  // view live map
  String get viewLiveMap;

  // last seen mins ago
  String lastSeenMinsAgo(String minutes);

  // time passed choose later
  String get timePassedChooseLater;

  // view profile
  String get viewProfile;

  // jobs done count
  String jobsDoneCount(int count);

  // accept quote from list note
  String get acceptQuoteFromListNote;

  // back to quotes
  String get backToQuotes;

  // sort default
  String get sortDefault;

  // sort lowest price
  String get sortLowestPrice;

  // sort highest rating
  String get sortHighestRating;

  // provider cancel reason emergency
  String get providerCancelReasonEmergency;

  // provider cancel reason breakdown
  String get providerCancelReasonBreakdown;

  // provider cancel reason unreachable
  String get providerCancelReasonUnreachable;

  // provider cancel reason scope
  String get providerCancelReasonScope;

  // provider en route warning
  String get providerEnRouteWarning;

  // provider self en route warning
  String get providerSelfEnRouteWarning;

  // cancel job action title
  String get cancelJobActionTitle;

  // cancel job option a
  String get cancelJobOptionA;

  // cancel job option a desc
  String get cancelJobOptionADesc;

  // cancel job option b
  String get cancelJobOptionB;

  // cancel job option b desc
  String get cancelJobOptionBDesc;

  // keep booking
  String get keepBooking;

  // cannot quote again
  String get cannotQuoteAgain;

  // cannot quote customer chose another
  String get cannotQuoteCustomerChoseAnother;

  // cannot quote you cancelled booking
  String get cannotQuoteYouCancelledBooking;

  // cannot quote already accepted
  String get cannotQuoteAlreadyAccepted;

  // change trade contact support
  String get changeTradeContactSupport;

  // cannot quote category mismatch
  String get cannotQuoteCategoryMismatch;

  // change service category
  String get changeServiceCategory;

  // confirm change category
  String confirmChangeCategory(String from, String to);

  // trade will be set to
  String tradeWillBeSetTo(String trade);

  // category updated
  String get categoryUpdated;

  // location must be in sri lanka
  String get locationMustBeInSriLanka;

  // category not set contact support
  String get categoryNotSetContactSupport;

  // all bookings
  String get allBookings;

  // booking history
  String get bookingHistory;

  // repost daily limit reached
  String get repostDailyLimitReached;

  // reposted from earlier post
  String get repostedFromEarlierPost;

  // reposted badge
  String get repostedBadge;

  // repost open post with quotes warning
  String repostOpenPostWithQuotesWarning(int count);

  // mark arrival first
  String get markArrivalFirst;

  // confirm price with customer first
  String get confirmPriceWithCustomerFirst;

  // network error try again
  String get networkErrorTryAgain;

  // incorrect pin attempts used
  String incorrectPinAttemptsUsed(int attempts, int maxAttempts);

  // too many wrong pins
  String get tooManyWrongPins;

  // invalid final amount
  String get invalidFinalAmount;

  // booking or job not found
  String get bookingOrJobNotFound;

  // confirm price first notice
  String get confirmPriceFirstNotice;

  // waiting customer approve price notice
  String get waitingCustomerApprovePriceNotice;

  // customer rejected price notice
  String get customerRejectedPriceNotice;

  // confirm price action
  String get confirmPriceAction;

  // inspect booking propose price desc
  String get inspectBookingProposePriceDesc;

  // propose final price first notice
  String get proposeFinalPriceFirstNotice;

  // propose price action
  String get proposePriceAction;

  // cannot keep price propose instead
  String get cannotKeepPriceProposeInstead;

  // final price lkr
  String get finalPriceLkr;

  // number of hours
  String get numberOfHours;

  // number of days
  String get numberOfDays;

  // pending bids overlap accepted warning
  String pendingBidsOverlapAcceptedWarning(int count);

  // completed caps
  String get completedCaps;

  // view booking
  String get viewBooking;

  // booking cancelled label
  String get bookingCancelledLabel;

  // set visit fee first
  String get setVisitFeeFirst;

  // inspection fee lkr
  String inspectionFeeLkr(String fee);

  // price after inspection
  String get priceAfterInspection;

  // confirm emergency inspect booking desc
  String confirmEmergencyInspectBookingDesc(String name);

  // remove visit fee emergency confirm
  String get removeVisitFeeEmergencyConfirm;

  // visit fee emergency hint
  String get visitFeeEmergencyHint;

  // visit fee emergency range error
  String get visitFeeEmergencyRangeError;
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
  // lookup logic when only language code is specified
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
