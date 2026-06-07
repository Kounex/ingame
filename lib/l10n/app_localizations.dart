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

  /// No description provided for @socialContinueWithDiscord.
  ///
  /// In en, this message translates to:
  /// **'Continue with Discord'**
  String get socialContinueWithDiscord;

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

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

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

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get commonViewDetails;

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

  /// No description provided for @avatarEditorActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar photo'**
  String get avatarEditorActionTitle;

  /// No description provided for @avatarEditorPhotoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo library'**
  String get avatarEditorPhotoLibrary;

  /// No description provided for @avatarEditorUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get avatarEditorUploadPhoto;

  /// No description provided for @avatarEditorTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get avatarEditorTakePhoto;

  /// No description provided for @avatarEditorUseUrl.
  ///
  /// In en, this message translates to:
  /// **'Use image URL'**
  String get avatarEditorUseUrl;

  /// No description provided for @avatarEditorRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get avatarEditorRemovePhoto;

  /// No description provided for @avatarEditorUseUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Use image URL'**
  String get avatarEditorUseUrlTitle;

  /// No description provided for @avatarEditorUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get avatarEditorUrlLabel;

  /// No description provided for @avatarEditorUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/avatar.jpg'**
  String get avatarEditorUrlHint;

  /// No description provided for @avatarEditorChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get avatarEditorChangePhoto;

  /// No description provided for @avatarEditorHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo, upload one, or paste an image URL.'**
  String get avatarEditorHint;

  /// No description provided for @avatarEditorEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the avatar to edit it, or choose a different photo below.'**
  String get avatarEditorEditHint;

  /// No description provided for @avatarEditorUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading avatar... {percent}%'**
  String avatarEditorUploading(int percent);

  /// No description provided for @avatarEditorUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload failed. Please try again.'**
  String get avatarEditorUploadFailed;

  /// No description provided for @avatarEditorInvalidFileType.
  ///
  /// In en, this message translates to:
  /// **'Use a JPEG, PNG, or WebP image.'**
  String get avatarEditorInvalidFileType;

  /// No description provided for @avatarEditorInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid image URL.'**
  String get avatarEditorInvalidUrl;

  /// No description provided for @avatarEditorCropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop avatar'**
  String get avatarEditorCropTitle;

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
  /// **'Add your usual time slots now or skip this step and set them later.'**
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

  /// No description provided for @timeSlotAllDayLabel.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get timeSlotAllDayLabel;

  /// No description provided for @timeSlotAllDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Morning, afternoon, evening, and night'**
  String get timeSlotAllDaySubtitle;

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

  /// No description provided for @groupDirectoryRequestSentAction.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get groupDirectoryRequestSentAction;

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

  /// No description provided for @joinGroupRequestSentButton.
  ///
  /// In en, this message translates to:
  /// **'Request Sent'**
  String get joinGroupRequestSentButton;

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

  /// No description provided for @discordAuthConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Discord...'**
  String get discordAuthConnecting;

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

  /// No description provided for @authAppleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in is not available in this build.'**
  String get authAppleUnavailable;

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

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your groups and profile.'**
  String get profileLogoutConfirmMessage;

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

  /// No description provided for @profileSectionSocials.
  ///
  /// In en, this message translates to:
  /// **'Socials'**
  String get profileSectionSocials;

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

  /// No description provided for @profileSocialIdentityLinkInConnectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Link in Connected Accounts'**
  String get profileSocialIdentityLinkInConnectedAccounts;

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

  /// No description provided for @profileConnectedAccountsDiscord.
  ///
  /// In en, this message translates to:
  /// **'Discord'**
  String get profileConnectedAccountsDiscord;

  /// No description provided for @profileConnectedAccountsApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get profileConnectedAccountsApple;

  /// No description provided for @profileConnectedAccountsXbox.
  ///
  /// In en, this message translates to:
  /// **'Xbox'**
  String get profileConnectedAccountsXbox;

  /// No description provided for @profileConnectedAccountsPlayStation.
  ///
  /// In en, this message translates to:
  /// **'PlayStation'**
  String get profileConnectedAccountsPlayStation;

  /// No description provided for @profileConnectedAccountsNintendo.
  ///
  /// In en, this message translates to:
  /// **'Nintendo'**
  String get profileConnectedAccountsNintendo;

  /// No description provided for @profileConnectedTapToDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Connected. Tap to disconnect.'**
  String get profileConnectedTapToDisconnect;

  /// No description provided for @profileDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {provider}?'**
  String profileDisconnectTitle(String provider);

  /// No description provided for @profileDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'You won\'t be able to sign in with {provider} after this.'**
  String profileDisconnectMessage(String provider);

  /// No description provided for @profileDisconnectSessionNotice.
  ///
  /// In en, this message translates to:
  /// **'Your current session will stay active on this device.'**
  String get profileDisconnectSessionNotice;

  /// No description provided for @profileDisconnectKeepAnotherMethod.
  ///
  /// In en, this message translates to:
  /// **'Make sure another sign-in method is already connected before you continue.'**
  String get profileDisconnectKeepAnotherMethod;

  /// No description provided for @profileDisconnectSteamFeatureNotice.
  ///
  /// In en, this message translates to:
  /// **'Steam-connected features will stay unavailable until you relink Steam.'**
  String get profileDisconnectSteamFeatureNotice;

  /// No description provided for @profileDisconnectAction.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get profileDisconnectAction;

  /// No description provided for @profileDisconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to disconnect {provider}: {message}'**
  String profileDisconnectFailed(String provider, String message);

  /// No description provided for @profileDisconnectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{provider} disconnected.'**
  String profileDisconnectedSuccess(String provider);

  /// No description provided for @profileLastAuthMethodRequired.
  ///
  /// In en, this message translates to:
  /// **'Add another sign-in method before disconnecting this one.'**
  String get profileLastAuthMethodRequired;

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

  /// No description provided for @profileDiscordLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Discord account linked successfully'**
  String get profileDiscordLinkedSuccess;

  /// No description provided for @profileLinkDiscordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to link Discord: {message}'**
  String profileLinkDiscordFailed(String message);

  /// No description provided for @profileSetEmailPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Email & Password'**
  String get profileSetEmailPasswordTitle;

  /// No description provided for @profileSetEmailPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a password to the email already on your account so you can sign in without a social provider.'**
  String get profileSetEmailPasswordDescription;

  /// No description provided for @profileEmailPasswordAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email & password added successfully'**
  String get profileEmailPasswordAddedSuccess;

  /// No description provided for @profileSetEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add email & password: {message}'**
  String profileSetEmailFailed(String message);

  /// No description provided for @profileChangeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get profileChangeEmailTitle;

  /// No description provided for @profileChangeEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'Update the account email used for recovery and future email & password sign-in.'**
  String get profileChangeEmailDescription;

  /// No description provided for @profileChangeEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email updated successfully'**
  String get profileChangeEmailSuccess;

  /// No description provided for @profileAddEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Set an account email first before adding a password.'**
  String get profileAddEmailFirst;

  /// No description provided for @profileChangeEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change email: {message}'**
  String profileChangeEmailFailed(String message);

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

  /// No description provided for @profileSocialIdentityAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {provider}'**
  String profileSocialIdentityAddTitle(String provider);

  /// No description provided for @profileSocialIdentityEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {provider}'**
  String profileSocialIdentityEditTitle(String provider);

  /// No description provided for @profileSocialIdentityGamertagLabel.
  ///
  /// In en, this message translates to:
  /// **'Gamertag'**
  String get profileSocialIdentityGamertagLabel;

  /// No description provided for @profileSocialIdentityShareLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile share link'**
  String get profileSocialIdentityShareLinkLabel;

  /// No description provided for @profileSocialIdentityFriendCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Friend code'**
  String get profileSocialIdentityFriendCodeLabel;

  /// No description provided for @profileSocialIdentityOnlineIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Online ID'**
  String get profileSocialIdentityOnlineIdLabel;

  /// No description provided for @profileSocialIdentityNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileSocialIdentityNicknameLabel;

  /// No description provided for @profileSocialIdentityInvalidShareLink.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid profile share link.'**
  String get profileSocialIdentityInvalidShareLink;

  /// No description provided for @profileSocialIdentitySavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{provider} saved.'**
  String profileSocialIdentitySavedSuccess(String provider);

  /// No description provided for @profileSocialIdentityCopiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{provider} copied.'**
  String profileSocialIdentityCopiedSuccess(String provider);

  /// No description provided for @profileSocialIdentityOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open {provider} profile.'**
  String profileSocialIdentityOpenFailed(String provider);

  /// No description provided for @profileSocialIdentityCopyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy {provider}.'**
  String profileSocialIdentityCopyFailed(String provider);

  /// No description provided for @profileSocialIdentityRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{provider} removed.'**
  String profileSocialIdentityRemovedSuccess(String provider);

  /// No description provided for @profileSocialIdentitySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save {provider}: {message}'**
  String profileSocialIdentitySaveFailed(String provider, String message);

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

  /// No description provided for @authSteamRelinkRequired.
  ///
  /// In en, this message translates to:
  /// **'This Steam login was disconnected. Sign in with another method and relink Steam from Profile.'**
  String get authSteamRelinkRequired;

  /// No description provided for @authAppleRelinkRequired.
  ///
  /// In en, this message translates to:
  /// **'This Apple login was disconnected. Sign in with another method and relink Apple from Profile.'**
  String get authAppleRelinkRequired;

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

  /// No description provided for @groupDetailOwnerLeaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership or delete the group before leaving it yourself.'**
  String get groupDetailOwnerLeaveMessage;

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

  /// No description provided for @groupSettingsPromoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Promote to Admin'**
  String get groupSettingsPromoteTitle;

  /// No description provided for @groupSettingsPromoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Promote {displayName} to admin?'**
  String groupSettingsPromoteMessage(String displayName);

  /// No description provided for @groupSettingsPromoteAction.
  ///
  /// In en, this message translates to:
  /// **'Promote'**
  String get groupSettingsPromoteAction;

  /// No description provided for @groupSettingsPromoted.
  ///
  /// In en, this message translates to:
  /// **'{displayName} is now an admin.'**
  String groupSettingsPromoted(String displayName);

  /// No description provided for @groupSettingsDemoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Demote to Member'**
  String get groupSettingsDemoteTitle;

  /// No description provided for @groupSettingsDemoteMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove admin access for {displayName}?'**
  String groupSettingsDemoteMessage(String displayName);

  /// No description provided for @groupSettingsDemoteAction.
  ///
  /// In en, this message translates to:
  /// **'Demote'**
  String get groupSettingsDemoteAction;

  /// No description provided for @groupSettingsDemoted.
  ///
  /// In en, this message translates to:
  /// **'{displayName} is now a member.'**
  String groupSettingsDemoted(String displayName);

  /// No description provided for @groupSettingsTransferOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get groupSettingsTransferOwnershipTitle;

  /// No description provided for @groupSettingsTransferOwnershipMessage.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership to {displayName}? You will remain in the group as an admin.'**
  String groupSettingsTransferOwnershipMessage(String displayName);

  /// No description provided for @groupSettingsTransferOwnershipAction.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get groupSettingsTransferOwnershipAction;

  /// No description provided for @groupSettingsOwnershipTransferred.
  ///
  /// In en, this message translates to:
  /// **'{displayName} is now the group owner.'**
  String groupSettingsOwnershipTransferred(String displayName);

  /// No description provided for @groupOwnerCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership or delete the group before leaving it yourself.'**
  String get groupOwnerCannotLeave;

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

  /// No description provided for @groupDetailReadyToggleOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to change your ready status'**
  String get groupDetailReadyToggleOfflineHint;

  /// No description provided for @groupDetailReadyToggleReconnectingHint.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get groupDetailReadyToggleReconnectingHint;

  /// No description provided for @groupDetailReadyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on ready status?'**
  String get groupDetailReadyConfirmTitle;

  /// No description provided for @groupDetailReadyConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your group will see that you\'re ready to play right now.'**
  String get groupDetailReadyConfirmMessage;

  /// No description provided for @groupDetailReadyConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Turn On'**
  String get groupDetailReadyConfirmAction;

  /// No description provided for @groupDetailCoordinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan together'**
  String get groupDetailCoordinationTitle;

  /// No description provided for @groupDetailCoordinationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See availability windows, session RSVPs, and recent group activity.'**
  String get groupDetailCoordinationSubtitle;

  /// No description provided for @groupDetailCoordinationNextSession.
  ///
  /// In en, this message translates to:
  /// **'Next up: {title}'**
  String groupDetailCoordinationNextSession(String title);

  /// No description provided for @groupDetailCoordinationAction.
  ///
  /// In en, this message translates to:
  /// **'Open planning hub'**
  String get groupDetailCoordinationAction;

  /// No description provided for @groupCoordinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Coordination'**
  String get groupCoordinationTitle;

  /// No description provided for @groupCoordinationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan sessions with scheduled availability, RSVPs, and a shared activity stream.'**
  String get groupCoordinationSubtitle;

  /// No description provided for @groupCoordinationWindowsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} windows'**
  String groupCoordinationWindowsCount(int count);

  /// No description provided for @groupCoordinationSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String groupCoordinationSessionsCount(int count);

  /// No description provided for @groupCoordinationActivityCount.
  ///
  /// In en, this message translates to:
  /// **'{count} updates'**
  String groupCoordinationActivityCount(int count);

  /// No description provided for @groupCoordinationCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability Calendar'**
  String get groupCoordinationCalendarTitle;

  /// No description provided for @groupCoordinationCalendarAdd.
  ///
  /// In en, this message translates to:
  /// **'Add window'**
  String get groupCoordinationCalendarAdd;

  /// No description provided for @groupCoordinationCalendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scheduled ready windows yet.'**
  String get groupCoordinationCalendarEmpty;

  /// No description provided for @groupCoordinationCalendarEmptyRange.
  ///
  /// In en, this message translates to:
  /// **'No ready windows in this range.'**
  String get groupCoordinationCalendarEmptyRange;

  /// No description provided for @groupCoordinationUpcomingWindowsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming windows'**
  String get groupCoordinationUpcomingWindowsTitle;

  /// No description provided for @groupCoordinationUpcomingWindowsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming ready windows.'**
  String get groupCoordinationUpcomingWindowsEmpty;

  /// No description provided for @groupCoordinationUpcomingWindowsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'All upcoming windows'**
  String get groupCoordinationUpcomingWindowsSheetTitle;

  /// No description provided for @groupCoordinationUpcomingWindowsViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all ({count} more)'**
  String groupCoordinationUpcomingWindowsViewAll(int count);

  /// No description provided for @groupCoordinationCalendarThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get groupCoordinationCalendarThisWeek;

  /// No description provided for @groupCoordinationCalendarPreviousRange.
  ///
  /// In en, this message translates to:
  /// **'Previous range'**
  String get groupCoordinationCalendarPreviousRange;

  /// No description provided for @groupCoordinationCalendarNextRange.
  ///
  /// In en, this message translates to:
  /// **'Next range'**
  String get groupCoordinationCalendarNextRange;

  /// No description provided for @groupCoordinationCalendarRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}'**
  String groupCoordinationCalendarRangeLabel(String start, String end);

  /// No description provided for @groupCoordinationSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get groupCoordinationSessionsTitle;

  /// No description provided for @groupCoordinationSessionAdd.
  ///
  /// In en, this message translates to:
  /// **'Propose session'**
  String get groupCoordinationSessionAdd;

  /// No description provided for @groupCoordinationSessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions planned yet.'**
  String get groupCoordinationSessionsEmpty;

  /// No description provided for @groupCoordinationActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get groupCoordinationActivityTitle;

  /// No description provided for @groupCoordinationActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get groupCoordinationActivityEmpty;

  /// No description provided for @groupCoordinationActivityRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get groupCoordinationActivityRecent;

  /// No description provided for @groupCoordinationActivityHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get groupCoordinationActivityHistory;

  /// No description provided for @groupCoordinationActivityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupCoordinationActivityFilterAll;

  /// No description provided for @groupCoordinationActivityFilterSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get groupCoordinationActivityFilterSessions;

  /// No description provided for @groupCoordinationActivityFilterAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get groupCoordinationActivityFilterAvailability;

  /// No description provided for @groupCoordinationActivityFilterRsvps.
  ///
  /// In en, this message translates to:
  /// **'RSVPs'**
  String get groupCoordinationActivityFilterRsvps;

  /// No description provided for @groupCoordinationActivityFilterMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get groupCoordinationActivityFilterMine;

  /// No description provided for @groupCoordinationActivityBucketToday.
  ///
  /// In en, this message translates to:
  /// **'Today ({count})'**
  String groupCoordinationActivityBucketToday(int count);

  /// No description provided for @groupCoordinationActivityBucketYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday ({count})'**
  String groupCoordinationActivityBucketYesterday(int count);

  /// No description provided for @groupCoordinationActivityBucketEarlierThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Earlier this week ({count})'**
  String groupCoordinationActivityBucketEarlierThisWeek(int count);

  /// No description provided for @groupCoordinationActivityBucketEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier ({count})'**
  String groupCoordinationActivityBucketEarlier(int count);

  /// No description provided for @groupCoordinationActivityRsvpBurst.
  ///
  /// In en, this message translates to:
  /// **'{count} RSVP updates'**
  String groupCoordinationActivityRsvpBurst(int count);

  /// No description provided for @groupCoordinationAddWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Add ready window'**
  String get groupCoordinationAddWindowTitle;

  /// No description provided for @groupCoordinationEditWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit ready window'**
  String get groupCoordinationEditWindowTitle;

  /// No description provided for @groupCoordinationDeleteWindowConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete ready window?'**
  String get groupCoordinationDeleteWindowConfirmTitle;

  /// No description provided for @groupCoordinationDeleteWindowConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This scheduled ready window will be removed for everyone in the group.'**
  String get groupCoordinationDeleteWindowConfirmMessage;

  /// No description provided for @groupCoordinationAddSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose session'**
  String get groupCoordinationAddSessionTitle;

  /// No description provided for @groupCoordinationEditSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit session'**
  String get groupCoordinationEditSessionTitle;

  /// No description provided for @groupCoordinationEditSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Session'**
  String get groupCoordinationEditSessionAction;

  /// No description provided for @groupCoordinationDeleteSessionAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get groupCoordinationDeleteSessionAction;

  /// No description provided for @groupCoordinationDeleteSessionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session?'**
  String get groupCoordinationDeleteSessionConfirmTitle;

  /// No description provided for @groupCoordinationDeleteSessionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This planned session will be removed for everyone in the group.'**
  String get groupCoordinationDeleteSessionConfirmMessage;

  /// No description provided for @groupCoordinationStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get groupCoordinationStartsAt;

  /// No description provided for @groupCoordinationEndsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get groupCoordinationEndsAt;

  /// No description provided for @groupCoordinationFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get groupCoordinationFieldTitle;

  /// No description provided for @groupCoordinationFieldGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get groupCoordinationFieldGame;

  /// No description provided for @groupCoordinationFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get groupCoordinationFieldNotes;

  /// No description provided for @groupCoordinationFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get groupCoordinationFieldStatus;

  /// No description provided for @groupCoordinationStatusProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get groupCoordinationStatusProposed;

  /// No description provided for @groupCoordinationStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get groupCoordinationStatusConfirmed;

  /// No description provided for @groupCoordinationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get groupCoordinationStatusCancelled;

  /// No description provided for @groupCoordinationCancelSessionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel session?'**
  String get groupCoordinationCancelSessionConfirmTitle;

  /// No description provided for @groupCoordinationCancelSessionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the group will see that this session was cancelled.'**
  String get groupCoordinationCancelSessionConfirmMessage;

  /// No description provided for @groupCoordinationCancelSessionConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Session'**
  String get groupCoordinationCancelSessionConfirmAction;

  /// No description provided for @groupCoordinationRsvpIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get groupCoordinationRsvpIn;

  /// No description provided for @groupCoordinationRsvpMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get groupCoordinationRsvpMaybe;

  /// No description provided for @groupCoordinationRsvpOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get groupCoordinationRsvpOut;

  /// No description provided for @groupCoordinationRsvpUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating RSVP...'**
  String get groupCoordinationRsvpUpdating;

  /// No description provided for @groupCoordinationYourResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get groupCoordinationYourResponseTitle;

  /// No description provided for @groupCoordinationResponsesTitle.
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get groupCoordinationResponsesTitle;

  /// No description provided for @groupCoordinationResponsesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No responses yet.'**
  String get groupCoordinationResponsesEmpty;

  /// No description provided for @groupCoordinationOwnedByYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get groupCoordinationOwnedByYou;

  /// No description provided for @groupCoordinationUntitledSession.
  ///
  /// In en, this message translates to:
  /// **'Untitled session'**
  String get groupCoordinationUntitledSession;

  /// No description provided for @groupCoordinationProposedBy.
  ///
  /// In en, this message translates to:
  /// **'Proposed by {displayName}'**
  String groupCoordinationProposedBy(String displayName);

  /// No description provided for @groupCoordinationActivityScheduledReadyUpdated.
  ///
  /// In en, this message translates to:
  /// **'{displayName} updated a ready window'**
  String groupCoordinationActivityScheduledReadyUpdated(String displayName);

  /// No description provided for @groupCoordinationActivityScheduledReadyDeleted.
  ///
  /// In en, this message translates to:
  /// **'{displayName} removed a ready window'**
  String groupCoordinationActivityScheduledReadyDeleted(String displayName);

  /// No description provided for @groupCoordinationActivitySessionProposed.
  ///
  /// In en, this message translates to:
  /// **'{displayName} proposed a session'**
  String groupCoordinationActivitySessionProposed(String displayName);

  /// No description provided for @groupCoordinationActivitySessionUpdated.
  ///
  /// In en, this message translates to:
  /// **'{displayName} updated a session'**
  String groupCoordinationActivitySessionUpdated(String displayName);

  /// No description provided for @groupCoordinationActivitySessionDeleted.
  ///
  /// In en, this message translates to:
  /// **'{displayName} removed a session'**
  String groupCoordinationActivitySessionDeleted(String displayName);

  /// No description provided for @groupCoordinationActivitySessionRsvpUpdated.
  ///
  /// In en, this message translates to:
  /// **'{displayName} responded to a session'**
  String groupCoordinationActivitySessionRsvpUpdated(String displayName);

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
