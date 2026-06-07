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
  String get brandTagline => 'Find your squad. Game together.';

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
  String get socialContinueWithDiscord => 'Continue with Discord';

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
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonDeny => 'Deny';

  @override
  String get commonShare => 'Share';

  @override
  String get commonClose => 'Close';

  @override
  String get commonViewDetails => 'View details';

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
  String get avatarEditorActionTitle => 'Choose avatar photo';

  @override
  String get avatarEditorPhotoLibrary => 'Photo library';

  @override
  String get avatarEditorUploadPhoto => 'Upload photo';

  @override
  String get avatarEditorTakePhoto => 'Take photo';

  @override
  String get avatarEditorUseUrl => 'Use image URL';

  @override
  String get avatarEditorRemovePhoto => 'Remove photo';

  @override
  String get avatarEditorUseUrlTitle => 'Use image URL';

  @override
  String get avatarEditorUrlLabel => 'Image URL';

  @override
  String get avatarEditorUrlHint => 'https://example.com/avatar.jpg';

  @override
  String get avatarEditorChangePhoto => 'Change photo';

  @override
  String get avatarEditorHint => 'Choose a photo, upload one, or paste an image URL.';

  @override
  String get avatarEditorEditHint => 'Tap the avatar to edit it, or choose a different photo below.';

  @override
  String avatarEditorUploading(int percent) {
    return 'Uploading avatar... $percent%';
  }

  @override
  String get avatarEditorUploadFailed => 'Avatar upload failed. Please try again.';

  @override
  String get avatarEditorInvalidFileType => 'Use a JPEG, PNG, or WebP image.';

  @override
  String get avatarEditorInvalidUrl => 'Enter a valid image URL.';

  @override
  String get avatarEditorCropTitle => 'Crop avatar';

  @override
  String get onboardingAvatarUrlLabel => 'Avatar URL';

  @override
  String get onboardingAvatarUrlHint => 'Link to your avatar image (optional)';

  @override
  String get onboardingGamingTitle => 'Gaming Preferences';

  @override
  String get onboardingGamingSubtitle => 'Add your usual time slots now or skip this step and set them later.';

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
  String get timeSlotAllDayLabel => 'All day';

  @override
  String get timeSlotAllDaySubtitle => 'Morning, afternoon, evening, and night';

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
  String get groupDirectoryRequestSentAction => 'Request Sent';

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
  String get joinGroupRequestSentButton => 'Request Sent';

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
  String get discordAuthConnecting => 'Connecting to Discord...';

  @override
  String get steamAuthTryAgain => 'Try Again';

  @override
  String get steamAuthBackToPrefix => 'Back to';

  @override
  String get steamAuthBackToLogin => 'Back to Login';

  @override
  String get errorRetryAction => 'Retry';

  @override
  String get authSignInCancelled => 'Sign-in was cancelled.';

  @override
  String get authAppleSignInFailed => 'Apple sign-in failed. Please try again.';

  @override
  String get authAppleUnavailable => 'Apple sign-in is not available in this build.';

  @override
  String get authErrorGeneric => 'Authentication failed. Please try again.';

  @override
  String get authErrorDebugPrefix => 'Authentication failed';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadError => 'Could not load profile';

  @override
  String get profileEdit => 'Edit Profile';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirmTitle => 'Log out?';

  @override
  String get profileLogoutConfirmMessage => 'You\'ll need to sign in again to access your groups and profile.';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileSectionConnectedAccounts => 'Connected Accounts';

  @override
  String get profileSectionSocials => 'Socials';

  @override
  String get profileSectionPreferences => 'Preferences';

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
  String get profileConnected => 'Connected';

  @override
  String get profileNotConnected => 'Not connected';

  @override
  String get profileSocialIdentityLinkInConnectedAccounts => 'Link in Connected Accounts';

  @override
  String get profileConnectedAccountsEmailPassword => 'Email & Password';

  @override
  String get profileConnectedAccountsSteam => 'Steam';

  @override
  String get profileConnectedAccountsDiscord => 'Discord';

  @override
  String get profileConnectedAccountsApple => 'Apple';

  @override
  String get profileConnectedAccountsXbox => 'Xbox';

  @override
  String get profileConnectedAccountsPlayStation => 'PlayStation';

  @override
  String get profileConnectedAccountsNintendo => 'Nintendo';

  @override
  String get profileConnectedTapToDisconnect => 'Connected. Tap to disconnect.';

  @override
  String profileDisconnectTitle(String provider) {
    return 'Disconnect $provider?';
  }

  @override
  String profileDisconnectMessage(String provider) {
    return 'You won\'t be able to sign in with $provider after this.';
  }

  @override
  String get profileDisconnectSessionNotice => 'Your current session will stay active on this device.';

  @override
  String get profileDisconnectKeepAnotherMethod => 'Make sure another sign-in method is already connected before you continue.';

  @override
  String get profileDisconnectSteamFeatureNotice => 'Steam-connected features will stay unavailable until you relink Steam.';

  @override
  String get profileDisconnectAction => 'Disconnect';

  @override
  String profileDisconnectFailed(String provider, String message) {
    return 'Failed to disconnect $provider: $message';
  }

  @override
  String profileDisconnectedSuccess(String provider) {
    return '$provider disconnected.';
  }

  @override
  String get profileLastAuthMethodRequired => 'Add another sign-in method before disconnecting this one.';

  @override
  String get profileSteamLinkedSuccess => 'Steam account linked successfully';

  @override
  String profileLinkSteamFailed(String message) {
    return 'Failed to link Steam: $message';
  }

  @override
  String get profileDiscordLinkedSuccess => 'Discord account linked successfully';

  @override
  String profileLinkDiscordFailed(String message) {
    return 'Failed to link Discord: $message';
  }

  @override
  String get profileSetEmailPasswordTitle => 'Add Email & Password';

  @override
  String get profileSetEmailPasswordDescription => 'Add a password to the email already on your account so you can sign in without a social provider.';

  @override
  String get profileEmailPasswordAddedSuccess => 'Email & password added successfully';

  @override
  String profileSetEmailFailed(String message) {
    return 'Failed to add email & password: $message';
  }

  @override
  String get profileChangeEmailTitle => 'Change Email';

  @override
  String get profileChangeEmailDescription => 'Update the account email used for recovery and future email & password sign-in.';

  @override
  String get profileChangeEmailSuccess => 'Email updated successfully';

  @override
  String get profileAddEmailFirst => 'Set an account email first before adding a password.';

  @override
  String profileChangeEmailFailed(String message) {
    return 'Failed to change email: $message';
  }

  @override
  String get profileAppleLinkedSuccess => 'Apple account linked successfully';

  @override
  String get profileAppleSignInFailed => 'Apple sign-in failed.';

  @override
  String profileLinkAppleFailed(String message) {
    return 'Failed to link Apple: $message';
  }

  @override
  String profileSocialIdentityAddTitle(String provider) {
    return 'Add $provider';
  }

  @override
  String profileSocialIdentityEditTitle(String provider) {
    return 'Edit $provider';
  }

  @override
  String get profileSocialIdentityGamertagLabel => 'Gamertag';

  @override
  String get profileSocialIdentityShareLinkLabel => 'Profile share link';

  @override
  String get profileSocialIdentityFriendCodeLabel => 'Friend code';

  @override
  String get profileSocialIdentityOnlineIdLabel => 'Online ID';

  @override
  String get profileSocialIdentityNicknameLabel => 'Nickname';

  @override
  String get profileSocialIdentityInvalidShareLink => 'Enter a valid profile share link.';

  @override
  String profileSocialIdentitySavedSuccess(String provider) {
    return '$provider saved.';
  }

  @override
  String profileSocialIdentityCopiedSuccess(String provider) {
    return '$provider copied.';
  }

  @override
  String profileSocialIdentityOpenFailed(String provider) {
    return 'Failed to open $provider profile.';
  }

  @override
  String profileSocialIdentityCopyFailed(String provider) {
    return 'Failed to copy $provider.';
  }

  @override
  String profileSocialIdentityRemovedSuccess(String provider) {
    return '$provider removed.';
  }

  @override
  String profileSocialIdentitySaveFailed(String provider, String message) {
    return 'Failed to save $provider: $message';
  }

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
  String gamingHoursSelectStartTime(String day) {
    return 'Select start time for $day';
  }

  @override
  String gamingHoursSelectEndTime(String day) {
    return 'Select end time for $day';
  }

  @override
  String get commonAdd => 'Add';

  @override
  String get authSteamRelinkRequired => 'This Steam login was disconnected. Sign in with another method and relink Steam from Profile.';

  @override
  String get authAppleRelinkRequired => 'This Apple login was disconnected. Sign in with another method and relink Apple from Profile.';

  @override
  String get groupTitleFallback => 'Group';

  @override
  String get groupVisibilityPublic => 'Public';

  @override
  String get groupVisibilityPrivate => 'Private';

  @override
  String get groupJoinModeOpenLabel => 'Open';

  @override
  String get groupJoinModeApprovalLabel => 'Approval';

  @override
  String get groupJoinModeOpenDescription => 'Anyone can join instantly';

  @override
  String get groupJoinModeApprovalDescription => 'Members must be approved by an admin';

  @override
  String get groupDetailMenuInvite => 'Invite';

  @override
  String get groupDetailMenuSettings => 'Settings';

  @override
  String get groupDetailMenuLeave => 'Leave Group';

  @override
  String get groupDetailSectionAbout => 'About';

  @override
  String get groupDetailSectionMembers => 'Members';

  @override
  String get groupDetailLeaveTitle => 'Leave Group';

  @override
  String get groupDetailLeaveMessage => 'Are you sure you want to leave this group?';

  @override
  String get groupDetailOwnerLeaveMessage => 'Transfer ownership or delete the group before leaving it yourself.';

  @override
  String get createGroupTitle => 'Create Group';

  @override
  String get createGroupNameLabel => 'Group Name';

  @override
  String get createGroupNameHint => 'Enter a name for your group';

  @override
  String get createGroupNameRequired => 'Group name is required';

  @override
  String get createGroupNameMin => 'Name must be at least 3 characters';

  @override
  String get createGroupDescriptionLabel => 'Description';

  @override
  String get createGroupDescriptionHint => 'What is this group about? (optional)';

  @override
  String get createGroupDiscoverableTitle => 'Discoverable';

  @override
  String get createGroupDiscoverableSubtitle => 'Allow others to find and join this group';

  @override
  String get createGroupJoinModeLabel => 'Join Mode';

  @override
  String get createGroupSubmit => 'Create Group';

  @override
  String get groupSettingsTitle => 'Group Settings';

  @override
  String get groupSettingsUpdated => 'Group updated';

  @override
  String get groupSettingsRemoveMemberTitle => 'Remove Member';

  @override
  String groupSettingsRemoveMemberMessage(String displayName) {
    return 'Remove $displayName from this group?';
  }

  @override
  String groupSettingsMemberRemoved(String displayName) {
    return '$displayName removed';
  }

  @override
  String get groupSettingsRequestApproved => 'Request approved';

  @override
  String get groupSettingsDenyRequestTitle => 'Deny Request';

  @override
  String groupSettingsDenyRequestMessage(String displayName) {
    return 'Deny join request from $displayName?';
  }

  @override
  String get groupSettingsRequestDenied => 'Request denied';

  @override
  String get groupSettingsDeleteTitle => 'Delete Group';

  @override
  String get groupSettingsDeleteMessage => 'This action cannot be undone. All members will be removed.';

  @override
  String get groupSettingsSectionGroupInfo => 'Group Info';

  @override
  String get groupSettingsSectionVisibility => 'Visibility';

  @override
  String groupSettingsSectionMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String groupSettingsSectionPendingRequests(int count) {
    return 'Pending Requests ($count)';
  }

  @override
  String get groupSettingsSectionDangerZone => 'Danger Zone';

  @override
  String get groupSettingsDangerDescription => 'Deleting this group is permanent and will remove all members.';

  @override
  String get groupSettingsRemoveTooltip => 'Remove';

  @override
  String get groupSettingsApproveTooltip => 'Approve';

  @override
  String get groupSettingsDenyTooltip => 'Deny';

  @override
  String get groupSettingsRoleMember => 'Member';

  @override
  String get groupSettingsPromoteTitle => 'Promote to Admin';

  @override
  String groupSettingsPromoteMessage(String displayName) {
    return 'Promote $displayName to admin?';
  }

  @override
  String get groupSettingsPromoteAction => 'Promote';

  @override
  String groupSettingsPromoted(String displayName) {
    return '$displayName is now an admin.';
  }

  @override
  String get groupSettingsDemoteTitle => 'Demote to Member';

  @override
  String groupSettingsDemoteMessage(String displayName) {
    return 'Remove admin access for $displayName?';
  }

  @override
  String get groupSettingsDemoteAction => 'Demote';

  @override
  String groupSettingsDemoted(String displayName) {
    return '$displayName is now a member.';
  }

  @override
  String get groupSettingsTransferOwnershipTitle => 'Transfer Ownership';

  @override
  String groupSettingsTransferOwnershipMessage(String displayName) {
    return 'Transfer ownership to $displayName? You will remain in the group as an admin.';
  }

  @override
  String get groupSettingsTransferOwnershipAction => 'Transfer ownership';

  @override
  String groupSettingsOwnershipTransferred(String displayName) {
    return '$displayName is now the group owner.';
  }

  @override
  String get groupOwnerCannotLeave => 'Transfer ownership or delete the group before leaving it yourself.';

  @override
  String groupSettingsTimeAgoDays(int count) {
    return '${count}d ago';
  }

  @override
  String groupSettingsTimeAgoHours(int count) {
    return '${count}h ago';
  }

  @override
  String groupSettingsTimeAgoMinutes(int count) {
    return '${count}m ago';
  }

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

  @override
  String get groupDetailReadyToggleLabel => 'Ready to play';

  @override
  String get groupDetailReadyToggleHint => 'Let your group know you\'re available to game';

  @override
  String get groupDetailReadyToggleOfflineHint => 'Connect to change your ready status';

  @override
  String get groupDetailReadyToggleReconnectingHint => 'Reconnecting…';

  @override
  String get groupDetailReadyConfirmTitle => 'Turn on ready status?';

  @override
  String get groupDetailReadyConfirmMessage => 'Your group will see that you\'re ready to play right now.';

  @override
  String get groupDetailReadyConfirmAction => 'Turn On';

  @override
  String get groupDetailCoordinationTitle => 'Plan together';

  @override
  String get groupDetailCoordinationSubtitle => 'See availability windows, session RSVPs, and recent group activity.';

  @override
  String groupDetailCoordinationNextSession(String title) {
    return 'Next up: $title';
  }

  @override
  String get groupDetailCoordinationAction => 'Open planning hub';

  @override
  String get groupCoordinationTitle => 'Group Coordination';

  @override
  String get groupCoordinationSubtitle => 'Plan sessions with scheduled availability, RSVPs, and a shared activity stream.';

  @override
  String groupCoordinationWindowsCount(int count) {
    return '$count windows';
  }

  @override
  String groupCoordinationSessionsCount(int count) {
    return '$count sessions';
  }

  @override
  String groupCoordinationActivityCount(int count) {
    return '$count updates';
  }

  @override
  String get groupCoordinationCalendarTitle => 'Availability Calendar';

  @override
  String get groupCoordinationCalendarAdd => 'Add window';

  @override
  String get groupCoordinationCalendarEmpty => 'No scheduled ready windows yet.';

  @override
  String get groupCoordinationCalendarEmptyRange => 'No ready windows in this range.';

  @override
  String get groupCoordinationUpcomingWindowsTitle => 'Upcoming windows';

  @override
  String get groupCoordinationUpcomingWindowsEmpty => 'No upcoming ready windows.';

  @override
  String get groupCoordinationUpcomingWindowsSheetTitle => 'All upcoming windows';

  @override
  String groupCoordinationUpcomingWindowsViewAll(int count) {
    return 'View all ($count more)';
  }

  @override
  String get groupCoordinationCalendarThisWeek => 'This Week';

  @override
  String get groupCoordinationCalendarPreviousRange => 'Previous range';

  @override
  String get groupCoordinationCalendarNextRange => 'Next range';

  @override
  String groupCoordinationCalendarRangeLabel(String start, String end) {
    return '$start - $end';
  }

  @override
  String get groupCoordinationSessionsTitle => 'Sessions';

  @override
  String get groupCoordinationSessionAdd => 'Propose session';

  @override
  String get groupCoordinationSessionsEmpty => 'No sessions planned yet.';

  @override
  String get groupCoordinationActivityTitle => 'Activity';

  @override
  String get groupCoordinationActivityEmpty => 'No activity yet.';

  @override
  String get groupCoordinationActivityRecent => 'Recent';

  @override
  String get groupCoordinationActivityHistory => 'History';

  @override
  String get groupCoordinationActivityFilterAll => 'All';

  @override
  String get groupCoordinationActivityFilterSessions => 'Sessions';

  @override
  String get groupCoordinationActivityFilterAvailability => 'Availability';

  @override
  String get groupCoordinationActivityFilterRsvps => 'RSVPs';

  @override
  String get groupCoordinationActivityFilterMine => 'Mine';

  @override
  String groupCoordinationActivityBucketToday(int count) {
    return 'Today ($count)';
  }

  @override
  String groupCoordinationActivityBucketYesterday(int count) {
    return 'Yesterday ($count)';
  }

  @override
  String groupCoordinationActivityBucketEarlierThisWeek(int count) {
    return 'Earlier this week ($count)';
  }

  @override
  String groupCoordinationActivityBucketEarlier(int count) {
    return 'Earlier ($count)';
  }

  @override
  String groupCoordinationActivityRsvpBurst(int count) {
    return '$count RSVP updates';
  }

  @override
  String get groupCoordinationAddWindowTitle => 'Add ready window';

  @override
  String get groupCoordinationEditWindowTitle => 'Edit ready window';

  @override
  String get groupCoordinationDeleteWindowConfirmTitle => 'Delete ready window?';

  @override
  String get groupCoordinationDeleteWindowConfirmMessage => 'This scheduled ready window will be removed for everyone in the group.';

  @override
  String get groupCoordinationAddSessionTitle => 'Propose session';

  @override
  String get groupCoordinationEditSessionTitle => 'Edit session';

  @override
  String get groupCoordinationEditSessionAction => 'Edit Session';

  @override
  String get groupCoordinationDeleteSessionAction => 'Delete Session';

  @override
  String get groupCoordinationDeleteSessionConfirmTitle => 'Delete session?';

  @override
  String get groupCoordinationDeleteSessionConfirmMessage => 'This planned session will be removed for everyone in the group.';

  @override
  String get groupCoordinationStartsAt => 'Starts';

  @override
  String get groupCoordinationEndsAt => 'Ends';

  @override
  String get groupCoordinationFieldTitle => 'Title';

  @override
  String get groupCoordinationFieldGame => 'Game';

  @override
  String get groupCoordinationFieldNotes => 'Notes';

  @override
  String get groupCoordinationFieldStatus => 'Status';

  @override
  String get groupCoordinationStatusProposed => 'Proposed';

  @override
  String get groupCoordinationStatusConfirmed => 'Confirmed';

  @override
  String get groupCoordinationStatusCancelled => 'Cancelled';

  @override
  String get groupCoordinationCancelSessionConfirmTitle => 'Cancel session?';

  @override
  String get groupCoordinationCancelSessionConfirmMessage => 'Everyone in the group will see that this session was cancelled.';

  @override
  String get groupCoordinationCancelSessionConfirmAction => 'Cancel Session';

  @override
  String get groupCoordinationRsvpIn => 'In';

  @override
  String get groupCoordinationRsvpMaybe => 'Maybe';

  @override
  String get groupCoordinationRsvpOut => 'Out';

  @override
  String get groupCoordinationRsvpUpdating => 'Updating RSVP...';

  @override
  String get groupCoordinationYourResponseTitle => 'Your response';

  @override
  String get groupCoordinationResponsesTitle => 'Responses';

  @override
  String get groupCoordinationResponsesEmpty => 'No responses yet.';

  @override
  String get groupCoordinationOwnedByYou => 'You';

  @override
  String get groupCoordinationUntitledSession => 'Untitled session';

  @override
  String groupCoordinationProposedBy(String displayName) {
    return 'Proposed by $displayName';
  }

  @override
  String groupCoordinationActivityScheduledReadyUpdated(String displayName) {
    return '$displayName updated a ready window';
  }

  @override
  String groupCoordinationActivityScheduledReadyDeleted(String displayName) {
    return '$displayName removed a ready window';
  }

  @override
  String groupCoordinationActivitySessionProposed(String displayName) {
    return '$displayName proposed a session';
  }

  @override
  String groupCoordinationActivitySessionUpdated(String displayName) {
    return '$displayName updated a session';
  }

  @override
  String groupCoordinationActivitySessionDeleted(String displayName) {
    return '$displayName removed a session';
  }

  @override
  String groupCoordinationActivitySessionRsvpUpdated(String displayName) {
    return '$displayName responded to a session';
  }

  @override
  String get languageSwitcherLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';
}
