// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'InGame';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'Enter your email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginSubmit => 'Log In';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginRegister => 'Register';

  @override
  String get socialDividerOr => 'or';

  @override
  String get socialContinueWithSteam => 'Continue with Steam';

  @override
  String get socialContinueWithApple => 'Continue with Apple';

  @override
  String validatorFieldRequired(String fieldName) {
    return '$fieldName is required';
  }

  @override
  String get validatorEmailRequired => 'Email is required';

  @override
  String get validatorEmailInvalid => 'Enter a valid email address';

  @override
  String get validatorPasswordRequired => 'Password is required';

  @override
  String get validatorPasswordMin => 'Password must be at least 8 characters';

  @override
  String get validatorPasswordConfirmRequired => 'Please confirm your password';

  @override
  String get validatorPasswordsMismatch => 'Passwords do not match';

  @override
  String get validatorDisplayNameRequired => 'Display name is required';

  @override
  String get validatorDisplayNameMin => 'Display name must be at least 2 characters';

  @override
  String get validatorDisplayNameMax => 'Display name must be at most 30 characters';

  @override
  String get errorSomethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get errorConnectionTimedOut => 'Connection timed out. Please check your internet.';

  @override
  String get errorCouldNotConnect => 'Could not connect to the server. Please try again later.';

  @override
  String get errorNetwork => 'Network error. Please check your connection.';

  @override
  String get errorInvalidRequest => 'Invalid request. Please check your input.';

  @override
  String get errorInvalidCredentials => 'Invalid credentials. Please try again.';

  @override
  String get errorNoPermission => 'You don\'t have permission to do this.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorAlreadyExists => 'This resource already exists.';

  @override
  String get errorCheckInput => 'Please check your input.';

  @override
  String get errorTooManyRequests => 'Too many requests. Please wait a moment.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String errorUnknownWithCode(int statusCode) {
    return 'Something went wrong (error $statusCode).';
  }

  @override
  String errorValidationFieldMessage(String field, String message) {
    return '$field: $message';
  }

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonFinish => 'Finish';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonDeny => 'Deny';

  @override
  String get commonShare => 'Share';

  @override
  String get navigationGroups => 'Groups';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationDiscover => 'Discover';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'Join the community';

  @override
  String get registerDisplayNameLabel => 'Display Name';

  @override
  String get registerDisplayNameHint => 'Choose a display name';

  @override
  String get registerEmailTaken => 'This email is already taken';

  @override
  String get registerDisplayNameTaken => 'This display name is already taken';

  @override
  String get registerPasswordHint => 'Create a password';

  @override
  String get registerConfirmPasswordLabel => 'Confirm Password';

  @override
  String get registerConfirmPasswordHint => 'Confirm your password';

  @override
  String get registerSubmit => 'Create Account';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account?';

  @override
  String get registerLogin => 'Log in';

  @override
  String get onboardingTimeSlotRequired => 'Select at least one time slot to complete onboarding.';

  @override
  String get onboardingDefaultBio => 'InGame player';

  @override
  String get onboardingWelcomeTitle => 'Welcome to InGame';

  @override
  String get onboardingWelcomeSubtitle => 'Coordinate gaming sessions with friends';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingProfileTitle => 'Set Up Your Profile';

  @override
  String get onboardingProfileSubtitle => 'Let other players know who you are.';

  @override
  String get onboardingDisplayNameHint => 'How others will see you';

  @override
  String get onboardingDisplayNameShort => 'Must be at least 2 characters';

  @override
  String get onboardingBioLabel => 'Bio';

  @override
  String get onboardingBioHint => 'Tell others about yourself (optional)';

  @override
  String get onboardingAvatarUrlLabel => 'Avatar URL';

  @override
  String get onboardingAvatarUrlHint => 'Link to your avatar image (optional)';

  @override
  String get onboardingGamingTitle => 'Gaming Preferences';

  @override
  String get onboardingGamingSubtitle => 'Select at least one time slot so groups can see when you play.';

  @override
  String get onboardingConnectSteamTitle => 'Connect Steam';

  @override
  String get onboardingConnectSteamSubtitle => 'Link your account later in settings';

  @override
  String get timeSlotMorningLabel => 'Morning';

  @override
  String get timeSlotMorningSubtitle => '6 AM - 12 PM';

  @override
  String get timeSlotAfternoonLabel => 'Afternoon';

  @override
  String get timeSlotAfternoonSubtitle => '12 PM - 6 PM';

  @override
  String get timeSlotEveningLabel => 'Evening';

  @override
  String get timeSlotEveningSubtitle => '6 PM - 12 AM';

  @override
  String get timeSlotNightLabel => 'Night';

  @override
  String get timeSlotNightSubtitle => '12 AM - 6 AM';

  @override
  String get groupsListTitle => 'My Groups';

  @override
  String get groupsEmptyTitle => 'No groups yet';

  @override
  String get groupsEmptySubtitle => 'Create or join your first group';

  @override
  String get groupsCreate => 'Create Group';

  @override
  String get groupsBrowse => 'Browse Groups';

  @override
  String get groupDirectoryTitle => 'Discover Groups';

  @override
  String get groupDirectorySearchHint => 'Search groups...';

  @override
  String get groupDirectoryNoResults => 'No groups found';

  @override
  String get groupDirectoryNoDiscoverable => 'No discoverable groups yet';

  @override
  String groupDirectoryJoinSuccess(String groupName) {
    return 'Joined $groupName!';
  }

  @override
  String get groupDirectoryJoinRequestSent => 'Join request sent!';

  @override
  String get groupDirectoryJoinAction => 'Join';

  @override
  String get groupDirectoryRequestJoinAction => 'Request to Join';

  @override
  String get joinGroupTitle => 'Join Group';

  @override
  String get joinGroupInvitedTitle => 'You\'ve been invited!';

  @override
  String get joinGroupSubtitle => 'Tap below to join this group';

  @override
  String joinGroupSubtitleNamed(String groupName) {
    return 'Join $groupName';
  }

  @override
  String joinGroupMembers(int count) {
    return '$count members';
  }

  @override
  String get joinGroupOpenJoin => 'Open join';

  @override
  String get joinGroupApprovalRequired => 'Approval required';

  @override
  String get joinGroupButton => 'Join Group';

  @override
  String get inviteCodeTitle => 'Invite Code';

  @override
  String get inviteCopyLink => 'Copy Link';

  @override
  String inviteShareText(String inviteLink, String inviteCode) {
    return 'Join my InGame group with this link: $inviteLink\nInvite code: $inviteCode';
  }

  @override
  String get inviteLinkCopied => 'Invite link copied to clipboard';

  @override
  String get inviteDetailsCopied => 'Invite details copied to clipboard';

  @override
  String get steamAuthConnecting => 'Connecting to Steam...';

  @override
  String get steamAuthTryAgain => 'Try Again';

  @override
  String get steamAuthBackToLogin => 'Back to Login';

  @override
  String get errorRetryAction => 'Retry';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadError => 'Could not load profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileTimezoneLabel => 'Timezone';

  @override
  String get profileMemberSinceLabel => 'Member since';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileUnknown => 'Unknown';

  @override
  String get profileSectionGamingHours => 'Gaming Hours';

  @override
  String get profileNoSchedule => 'No schedule set';

  @override
  String get profileEveryDay => 'Every day';

  @override
  String get profileWeekdays => 'Weekdays';

  @override
  String get profileWeekends => 'Weekends';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editProfileDisplayNameHint => 'Enter your display name';

  @override
  String get editProfileBioLabel => 'Bio';

  @override
  String get editProfileBioHint => 'Tell others about yourself';

  @override
  String get editProfileSave => 'Save Changes';

  @override
  String get avatarUploadSoon => 'Avatar upload coming soon';

  @override
  String get timezoneLabel => 'Timezone';

  @override
  String get gamingHoursTitle => 'Gaming Hours';

  @override
  String get gamingHoursNotSet => 'Not set';

  @override
  String get dayMonShort => 'Mon';

  @override
  String get dayTueShort => 'Tue';

  @override
  String get dayWedShort => 'Wed';

  @override
  String get dayThuShort => 'Thu';

  @override
  String get dayFriShort => 'Fri';

  @override
  String get daySatShort => 'Sat';

  @override
  String get daySunShort => 'Sun';

  @override
  String get memberRoleOwner => 'Owner';

  @override
  String get memberRoleAdmin => 'Admin';

  @override
  String get memberStatusReady => 'Ready to play';

  @override
  String get memberStatusOnline => 'Online';

  @override
  String get memberStatusAway => 'Away';

  @override
  String get memberStatusOffline => 'Offline';
}
