import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'InGame'**
  String get appTitle;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Find your squad. Game together.'**
  String get brandTagline;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginSubmit;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get loginRegister;

  /// No description provided for @socialDividerOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get socialDividerOr;

  /// No description provided for @socialContinueWithSteam.
  ///
  /// In en, this message translates to:
  /// **'Continue with Steam'**
  String get socialContinueWithSteam;

  /// No description provided for @socialContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get socialContinueWithApple;

  /// No description provided for @validatorFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String validatorFieldRequired(String fieldName);

  /// No description provided for @validatorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validatorEmailRequired;

  /// No description provided for @validatorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validatorEmailInvalid;

  /// No description provided for @validatorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validatorPasswordRequired;

  /// No description provided for @validatorPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validatorPasswordMin;

  /// No description provided for @validatorPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validatorPasswordConfirmRequired;

  /// No description provided for @validatorPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validatorPasswordsMismatch;

  /// No description provided for @validatorDisplayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get validatorDisplayNameRequired;

  /// No description provided for @validatorDisplayNameMin.
  ///
  /// In en, this message translates to:
  /// **'Display name must be at least 2 characters'**
  String get validatorDisplayNameMin;

  /// No description provided for @validatorDisplayNameMax.
  ///
  /// In en, this message translates to:
  /// **'Display name must be at most 30 characters'**
  String get validatorDisplayNameMax;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSomethingWentWrong;

  /// No description provided for @errorConnectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please check your internet.'**
  String get errorConnectionTimedOut;

  /// No description provided for @errorCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server. Please try again later.'**
  String get errorCouldNotConnect;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please check your input.'**
  String get errorInvalidRequest;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please try again.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errorNoPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorNotFound;

  /// No description provided for @errorAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This resource already exists.'**
  String get errorAlreadyExists;

  /// No description provided for @errorCheckInput.
  ///
  /// In en, this message translates to:
  /// **'Please check your input.'**
  String get errorCheckInput;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get errorTooManyRequests;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorUnknownWithCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong (error {statusCode}).'**
  String errorUnknownWithCode(int statusCode);

  /// No description provided for @errorValidationFieldMessage.
  ///
  /// In en, this message translates to:
  /// **'{field}: {message}'**
  String errorValidationFieldMessage(String field, String message);

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get commonFinish;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get commonDeny;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @navigationGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navigationGroups;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navigationDiscover;

  /// No description provided for @navigationProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navigationProfile;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the community'**
  String get registerSubtitle;

  /// No description provided for @registerDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get registerDisplayNameLabel;

  /// No description provided for @registerDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a display name'**
  String get registerDisplayNameHint;

  /// No description provided for @registerEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already taken'**
  String get registerEmailTaken;

  /// No description provided for @registerDisplayNameTaken.
  ///
  /// In en, this message translates to:
  /// **'This display name is already taken'**
  String get registerDisplayNameTaken;

  /// No description provided for @registerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerSubmit;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registerLogin;

  /// No description provided for @onboardingTimeSlotRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one time slot to complete onboarding.'**
  String get onboardingTimeSlotRequired;

  /// No description provided for @onboardingDefaultBio.
  ///
  /// In en, this message translates to:
  /// **'InGame player'**
  String get onboardingDefaultBio;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to InGame'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coordinate gaming sessions with friends'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Profile'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let other players know who you are.'**
  String get onboardingProfileSubtitle;

  /// No description provided for @onboardingDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How others will see you'**
  String get onboardingDisplayNameHint;

  /// No description provided for @onboardingDisplayNameShort.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 2 characters'**
  String get onboardingDisplayNameShort;

  /// No description provided for @onboardingBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get onboardingBioLabel;

  /// No description provided for @onboardingBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself (optional)'**
  String get onboardingBioHint;

  /// No description provided for @onboardingAvatarUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get onboardingAvatarUrlLabel;

  /// No description provided for @onboardingAvatarUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Link to your avatar image (optional)'**
  String get onboardingAvatarUrlHint;

  /// No description provided for @onboardingGamingTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaming Preferences'**
  String get onboardingGamingTitle;

  /// No description provided for @onboardingGamingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select at least one time slot so groups can see when you play.'**
  String get onboardingGamingSubtitle;

  /// No description provided for @onboardingConnectSteamTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Steam'**
  String get onboardingConnectSteamTitle;

  /// No description provided for @onboardingConnectSteamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Link your account later in settings'**
  String get onboardingConnectSteamSubtitle;

  /// No description provided for @timeSlotMorningLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get timeSlotMorningLabel;

  /// No description provided for @timeSlotMorningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'6 AM - 12 PM'**
  String get timeSlotMorningSubtitle;

  /// No description provided for @timeSlotAfternoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get timeSlotAfternoonLabel;

  /// No description provided for @timeSlotAfternoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'12 PM - 6 PM'**
  String get timeSlotAfternoonSubtitle;

  /// No description provided for @timeSlotEveningLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get timeSlotEveningLabel;

  /// No description provided for @timeSlotEveningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'6 PM - 12 AM'**
  String get timeSlotEveningSubtitle;

  /// No description provided for @timeSlotNightLabel.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get timeSlotNightLabel;

  /// No description provided for @timeSlotNightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'12 AM - 6 AM'**
  String get timeSlotNightSubtitle;

  /// No description provided for @groupsListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get groupsListTitle;

  /// No description provided for @groupsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get groupsEmptyTitle;

  /// No description provided for @groupsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create or join your first group'**
  String get groupsEmptySubtitle;

  /// No description provided for @groupsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get groupsCreate;

  /// No description provided for @groupsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse Groups'**
  String get groupsBrowse;

  /// No description provided for @groupDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover Groups'**
  String get groupDirectoryTitle;

  /// No description provided for @groupDirectorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search groups...'**
  String get groupDirectorySearchHint;

  /// No description provided for @groupDirectoryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get groupDirectoryNoResults;

  /// No description provided for @groupDirectoryNoDiscoverable.
  ///
  /// In en, this message translates to:
  /// **'No discoverable groups yet'**
  String get groupDirectoryNoDiscoverable;

  /// No description provided for @groupDirectoryJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined {groupName}!'**
  String groupDirectoryJoinSuccess(String groupName);

  /// No description provided for @groupDirectoryJoinRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Join request sent!'**
  String get groupDirectoryJoinRequestSent;

  /// No description provided for @groupDirectoryJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groupDirectoryJoinAction;

  /// No description provided for @groupDirectoryRequestJoinAction.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get groupDirectoryRequestJoinAction;

  /// No description provided for @joinGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupTitle;

  /// No description provided for @joinGroupInvitedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited!'**
  String get joinGroupInvitedTitle;

  /// No description provided for @joinGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap below to join this group'**
  String get joinGroupSubtitle;

  /// No description provided for @joinGroupSubtitleNamed.
  ///
  /// In en, this message translates to:
  /// **'Join {groupName}'**
  String joinGroupSubtitleNamed(String groupName);

  /// No description provided for @joinGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String joinGroupMembers(int count);

  /// No description provided for @joinGroupOpenJoin.
  ///
  /// In en, this message translates to:
  /// **'Open join'**
  String get joinGroupOpenJoin;

  /// No description provided for @joinGroupApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get joinGroupApprovalRequired;

  /// No description provided for @joinGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupButton;

  /// No description provided for @inviteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCodeTitle;

  /// No description provided for @inviteCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get inviteCopyLink;

  /// No description provided for @inviteShareText.
  ///
  /// In en, this message translates to:
  /// **'Join my InGame group with this link: {inviteLink}\nInvite code: {inviteCode}'**
  String inviteShareText(String inviteLink, String inviteCode);

  /// No description provided for @inviteLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied to clipboard'**
  String get inviteLinkCopied;

  /// No description provided for @inviteDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite details copied to clipboard'**
  String get inviteDetailsCopied;

  /// No description provided for @steamAuthConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Steam...'**
  String get steamAuthConnecting;

  /// No description provided for @steamAuthTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get steamAuthTryAgain;

  /// No description provided for @steamAuthBackToPrefix.
  ///
  /// In en, this message translates to:
  /// **'Back to'**
  String get steamAuthBackToPrefix;

  /// No description provided for @steamAuthBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get steamAuthBackToLogin;

  /// No description provided for @errorRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetryAction;

  /// No description provided for @authSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authSignInCancelled;

  /// No description provided for @authAppleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get authAppleSignInFailed;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorDebugPrefix.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authErrorDebugPrefix;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileLoadError;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @profileSectionConnectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected Accounts'**
  String get profileSectionConnectedAccounts;

  /// No description provided for @profileSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profileSectionPreferences;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get profileTimezoneLabel;

  /// No description provided for @profileMemberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get profileMemberSinceLabel;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get profileUnknown;

  /// No description provided for @profileConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get profileConnected;

  /// No description provided for @profileNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get profileNotConnected;

  /// No description provided for @profileConnectedAccountsEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email & Password'**
  String get profileConnectedAccountsEmailPassword;

  /// No description provided for @profileConnectedAccountsSteam.
  ///
  /// In en, this message translates to:
  /// **'Steam'**
  String get profileConnectedAccountsSteam;

  /// No description provided for @profileConnectedAccountsApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get profileConnectedAccountsApple;

  /// No description provided for @profileDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {provider}'**
  String profileDisconnectTitle(String provider);

  /// No description provided for @profileDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect your {provider} account?'**
  String profileDisconnectMessage(String provider);

  /// No description provided for @profileDisconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect {provider}: {message}'**
  String profileDisconnectFailed(String provider, String message);

  /// No description provided for @profileSteamLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Steam account linked successfully'**
  String get profileSteamLinkedSuccess;

  /// No description provided for @profileLinkSteamFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to link Steam: {message}'**
  String profileLinkSteamFailed(String message);

  /// No description provided for @profileSetEmailPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Email & Password'**
  String get profileSetEmailPasswordTitle;

  /// No description provided for @profileSetEmailPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Add email login to your account so you can sign in without a social provider.'**
  String get profileSetEmailPasswordDescription;

  /// No description provided for @profileEmailPasswordAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email & password added successfully'**
  String get profileEmailPasswordAddedSuccess;

  /// No description provided for @profileSetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set email: {message}'**
  String profileSetEmailFailed(String message);

  /// No description provided for @profileAppleLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Apple account linked successfully'**
  String get profileAppleLinkedSuccess;

  /// No description provided for @profileAppleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed.'**
  String get profileAppleSignInFailed;

  /// No description provided for @profileLinkAppleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to link Apple: {message}'**
  String profileLinkAppleFailed(String message);

  /// No description provided for @profileSectionGamingHours.
  ///
  /// In en, this message translates to:
  /// **'Gaming Hours'**
  String get profileSectionGamingHours;

  /// No description provided for @profileNoSchedule.
  ///
  /// In en, this message translates to:
  /// **'No schedule set'**
  String get profileNoSchedule;

  /// No description provided for @profileEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get profileEveryDay;

  /// No description provided for @profileWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get profileWeekdays;

  /// No description provided for @profileWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get profileWeekends;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your display name'**
  String get editProfileDisplayNameHint;

  /// No description provided for @editProfileBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editProfileBioLabel;

  /// No description provided for @editProfileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself'**
  String get editProfileBioHint;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSave;

  /// No description provided for @avatarUploadSoon.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload coming soon'**
  String get avatarUploadSoon;

  /// No description provided for @timezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezoneLabel;

  /// No description provided for @gamingHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaming Hours'**
  String get gamingHoursTitle;

  /// No description provided for @gamingHoursNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get gamingHoursNotSet;

  /// No description provided for @gamingHoursSelectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select start time for {day}'**
  String gamingHoursSelectStartTime(String day);

  /// No description provided for @gamingHoursSelectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Select end time for {day}'**
  String gamingHoursSelectEndTime(String day);

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @groupTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupTitleFallback;

  /// No description provided for @groupVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get groupVisibilityPublic;

  /// No description provided for @groupVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get groupVisibilityPrivate;

  /// No description provided for @groupJoinModeOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get groupJoinModeOpenLabel;

  /// No description provided for @groupJoinModeApprovalLabel.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get groupJoinModeApprovalLabel;

  /// No description provided for @groupJoinModeOpenDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone can join instantly'**
  String get groupJoinModeOpenDescription;

  /// No description provided for @groupJoinModeApprovalDescription.
  ///
  /// In en, this message translates to:
  /// **'Members must be approved by an admin'**
  String get groupJoinModeApprovalDescription;

  /// No description provided for @groupDetailMenuInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupDetailMenuInvite;

  /// No description provided for @groupDetailMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get groupDetailMenuSettings;

  /// No description provided for @groupDetailMenuLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get groupDetailMenuLeave;

  /// No description provided for @groupDetailSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get groupDetailSectionAbout;

  /// No description provided for @groupDetailSectionMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupDetailSectionMembers;

  /// No description provided for @groupDetailLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get groupDetailLeaveTitle;

  /// No description provided for @groupDetailLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this group?'**
  String get groupDetailLeaveMessage;

  /// No description provided for @createGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupTitle;

  /// No description provided for @createGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get createGroupNameLabel;

  /// No description provided for @createGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your group'**
  String get createGroupNameHint;

  /// No description provided for @createGroupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get createGroupNameRequired;

  /// No description provided for @createGroupNameMin.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get createGroupNameMin;

  /// No description provided for @createGroupDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createGroupDescriptionLabel;

  /// No description provided for @createGroupDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this group about? (optional)'**
  String get createGroupDescriptionHint;

  /// No description provided for @createGroupDiscoverableTitle.
  ///
  /// In en, this message translates to:
  /// **'Discoverable'**
  String get createGroupDiscoverableTitle;

  /// No description provided for @createGroupDiscoverableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow others to find and join this group'**
  String get createGroupDiscoverableSubtitle;

  /// No description provided for @createGroupJoinModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join Mode'**
  String get createGroupJoinModeLabel;

  /// No description provided for @createGroupSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupSubmit;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Settings'**
  String get groupSettingsTitle;

  /// No description provided for @groupSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated'**
  String get groupSettingsUpdated;

  /// No description provided for @groupSettingsRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get groupSettingsRemoveMemberTitle;

  /// No description provided for @groupSettingsRemoveMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {displayName} from this group?'**
  String groupSettingsRemoveMemberMessage(String displayName);

  /// No description provided for @groupSettingsMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{displayName} removed'**
  String groupSettingsMemberRemoved(String displayName);

  /// No description provided for @groupSettingsRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get groupSettingsRequestApproved;

  /// No description provided for @groupSettingsDenyRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Deny Request'**
  String get groupSettingsDenyRequestTitle;

  /// No description provided for @groupSettingsDenyRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Deny join request from {displayName}?'**
  String groupSettingsDenyRequestMessage(String displayName);

  /// No description provided for @groupSettingsRequestDenied.
  ///
  /// In en, this message translates to:
  /// **'Request denied'**
  String get groupSettingsRequestDenied;

  /// No description provided for @groupSettingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get groupSettingsDeleteTitle;

  /// No description provided for @groupSettingsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All members will be removed.'**
  String get groupSettingsDeleteMessage;

  /// No description provided for @groupSettingsSectionGroupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get groupSettingsSectionGroupInfo;

  /// No description provided for @groupSettingsSectionVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get groupSettingsSectionVisibility;

  /// No description provided for @groupSettingsSectionMembers.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String groupSettingsSectionMembers(int count);

  /// No description provided for @groupSettingsSectionPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests ({count})'**
  String groupSettingsSectionPendingRequests(int count);

  /// No description provided for @groupSettingsSectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get groupSettingsSectionDangerZone;

  /// No description provided for @groupSettingsDangerDescription.
  ///
  /// In en, this message translates to:
  /// **'Deleting this group is permanent and will remove all members.'**
  String get groupSettingsDangerDescription;

  /// No description provided for @groupSettingsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupSettingsRemoveTooltip;

  /// No description provided for @groupSettingsApproveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get groupSettingsApproveTooltip;

  /// No description provided for @groupSettingsDenyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get groupSettingsDenyTooltip;

  /// No description provided for @groupSettingsRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupSettingsRoleMember;

  /// No description provided for @groupSettingsTimeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String groupSettingsTimeAgoDays(int count);

  /// No description provided for @groupSettingsTimeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String groupSettingsTimeAgoHours(int count);

  /// No description provided for @groupSettingsTimeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String groupSettingsTimeAgoMinutes(int count);

  /// No description provided for @dayMonShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMonShort;

  /// No description provided for @dayTueShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTueShort;

  /// No description provided for @dayWedShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWedShort;

  /// No description provided for @dayThuShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThuShort;

  /// No description provided for @dayFriShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFriShort;

  /// No description provided for @daySatShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySatShort;

  /// No description provided for @daySunShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySunShort;

  /// No description provided for @memberRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get memberRoleOwner;

  /// No description provided for @memberRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get memberRoleAdmin;

  /// No description provided for @memberStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get memberStatusReady;

  /// No description provided for @memberStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get memberStatusOnline;

  /// No description provided for @memberStatusAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get memberStatusAway;

  /// No description provided for @memberStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get memberStatusOffline;

  /// No description provided for @groupDetailReadyToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Ready to play'**
  String get groupDetailReadyToggleLabel;

  /// No description provided for @groupDetailReadyToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Let your group know you\'re available to game'**
  String get groupDetailReadyToggleHint;

  /// No description provided for @languageSwitcherLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSwitcherLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
