// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'InGame';

  @override
  String get brandTagline => 'Finde deine Crew. Spielt zusammen.';

  @override
  String get loginEmailLabel => 'E-Mail';

  @override
  String get loginEmailHint => 'Gib deine E-Mail ein';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginPasswordHint => 'Gib dein Passwort ein';

  @override
  String get loginSubmit => 'Anmelden';

  @override
  String get loginNoAccount => 'Noch kein Konto?';

  @override
  String get loginRegister => 'Registrieren';

  @override
  String get socialDividerOr => 'oder';

  @override
  String get socialContinueWithSteam => 'Mit Steam fortfahren';

  @override
  String get socialContinueWithApple => 'Mit Apple fortfahren';

  @override
  String validatorFieldRequired(String fieldName) {
    return '$fieldName ist erforderlich';
  }

  @override
  String get validatorEmailRequired => 'E-Mail ist erforderlich';

  @override
  String get validatorEmailInvalid => 'Gib eine gültige E-Mail-Adresse ein';

  @override
  String get validatorPasswordRequired => 'Passwort ist erforderlich';

  @override
  String get validatorPasswordMin => 'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get validatorPasswordConfirmRequired => 'Bitte bestätige dein Passwort';

  @override
  String get validatorPasswordsMismatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get validatorDisplayNameRequired => 'Anzeigename ist erforderlich';

  @override
  String get validatorDisplayNameMin => 'Der Anzeigename muss mindestens 2 Zeichen lang sein';

  @override
  String get validatorDisplayNameMax => 'Der Anzeigename darf höchstens 30 Zeichen lang sein';

  @override
  String get errorSomethingWentWrong => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorConnectionTimedOut => 'Zeitüberschreitung bei der Verbindung. Bitte prüfe dein Internet.';

  @override
  String get errorCouldNotConnect => 'Es konnte keine Verbindung zum Server hergestellt werden. Bitte versuche es später erneut.';

  @override
  String get errorNetwork => 'Netzwerkfehler. Bitte prüfe deine Verbindung.';

  @override
  String get errorInvalidRequest => 'Ungültige Anfrage. Bitte prüfe deine Eingaben.';

  @override
  String get errorInvalidCredentials => 'Ungültige Anmeldedaten. Bitte versuche es erneut.';

  @override
  String get errorNoPermission => 'Du hast keine Berechtigung dafür.';

  @override
  String get errorNotFound => 'Nicht gefunden.';

  @override
  String get errorAlreadyExists => 'Diese Ressource existiert bereits.';

  @override
  String get errorCheckInput => 'Bitte prüfe deine Eingaben.';

  @override
  String get errorTooManyRequests => 'Zu viele Anfragen. Bitte warte einen Moment.';

  @override
  String get errorServer => 'Serverfehler. Bitte versuche es später erneut.';

  @override
  String errorUnknownWithCode(int statusCode) {
    return 'Etwas ist schiefgelaufen (Fehler $statusCode).';
  }

  @override
  String errorValidationFieldMessage(String field, String message) {
    return '$field: $message';
  }

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonFinish => 'Fertig';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonDeny => 'Ablehnen';

  @override
  String get commonShare => 'Teilen';

  @override
  String get navigationGroups => 'Gruppen';

  @override
  String get navigationHome => 'Start';

  @override
  String get navigationDiscover => 'Entdecken';

  @override
  String get navigationProfile => 'Profil';

  @override
  String get registerTitle => 'Konto erstellen';

  @override
  String get registerSubtitle => 'Tritt der Community bei';

  @override
  String get registerDisplayNameLabel => 'Anzeigename';

  @override
  String get registerDisplayNameHint => 'Wähle einen Anzeigenamen';

  @override
  String get registerEmailTaken => 'Diese E-Mail ist bereits vergeben';

  @override
  String get registerDisplayNameTaken => 'Dieser Anzeigename ist bereits vergeben';

  @override
  String get registerPasswordHint => 'Erstelle ein Passwort';

  @override
  String get registerConfirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get registerConfirmPasswordHint => 'Bestätige dein Passwort';

  @override
  String get registerSubmit => 'Konto erstellen';

  @override
  String get registerAlreadyHaveAccount => 'Hast du bereits ein Konto?';

  @override
  String get registerLogin => 'Anmelden';

  @override
  String get onboardingTimeSlotRequired => 'Wähle mindestens ein Zeitfenster aus, um das Onboarding abzuschließen.';

  @override
  String get onboardingDefaultBio => 'InGame-Spieler';

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei InGame';

  @override
  String get onboardingWelcomeSubtitle => 'Koordiniere Gaming-Sessions mit Freunden';

  @override
  String get onboardingGetStarted => 'Los geht\'s';

  @override
  String get onboardingProfileTitle => 'Richte dein Profil ein';

  @override
  String get onboardingProfileSubtitle => 'Lass andere Spieler wissen, wer du bist.';

  @override
  String get onboardingDisplayNameHint => 'So sehen dich andere';

  @override
  String get onboardingDisplayNameShort => 'Muss mindestens 2 Zeichen lang sein';

  @override
  String get onboardingBioLabel => 'Bio';

  @override
  String get onboardingBioHint => 'Erzähle anderen etwas über dich (optional)';

  @override
  String get onboardingAvatarUrlLabel => 'Avatar-URL';

  @override
  String get onboardingAvatarUrlHint => 'Link zu deinem Avatarbild (optional)';

  @override
  String get onboardingGamingTitle => 'Gaming-Präferenzen';

  @override
  String get onboardingGamingSubtitle => 'Wähle mindestens ein Zeitfenster, damit Gruppen sehen können, wann du spielst.';

  @override
  String get onboardingConnectSteamTitle => 'Steam verbinden';

  @override
  String get onboardingConnectSteamSubtitle => 'Verknüpfe dein Konto später in den Einstellungen';

  @override
  String get timeSlotMorningLabel => 'Morgen';

  @override
  String get timeSlotMorningSubtitle => '6 Uhr - 12 Uhr';

  @override
  String get timeSlotAfternoonLabel => 'Nachmittag';

  @override
  String get timeSlotAfternoonSubtitle => '12 Uhr - 18 Uhr';

  @override
  String get timeSlotEveningLabel => 'Abend';

  @override
  String get timeSlotEveningSubtitle => '18 Uhr - 0 Uhr';

  @override
  String get timeSlotNightLabel => 'Nacht';

  @override
  String get timeSlotNightSubtitle => '0 Uhr - 6 Uhr';

  @override
  String get groupsListTitle => 'Meine Gruppen';

  @override
  String get groupsEmptyTitle => 'Noch keine Gruppen';

  @override
  String get groupsEmptySubtitle => 'Erstelle deine erste Gruppe oder tritt einer bei';

  @override
  String get groupsCreate => 'Gruppe erstellen';

  @override
  String get groupsBrowse => 'Gruppen durchsuchen';

  @override
  String get groupDirectoryTitle => 'Gruppen entdecken';

  @override
  String get groupDirectorySearchHint => 'Gruppen suchen...';

  @override
  String get groupDirectoryNoResults => 'Keine Gruppen gefunden';

  @override
  String get groupDirectoryNoDiscoverable => 'Noch keine sichtbaren Gruppen';

  @override
  String groupDirectoryJoinSuccess(String groupName) {
    return '$groupName beigetreten!';
  }

  @override
  String get groupDirectoryJoinRequestSent => 'Beitrittsanfrage gesendet!';

  @override
  String get groupDirectoryJoinAction => 'Beitreten';

  @override
  String get groupDirectoryRequestJoinAction => 'Beitritt anfragen';

  @override
  String get joinGroupTitle => 'Gruppe beitreten';

  @override
  String get joinGroupInvitedTitle => 'Du wurdest eingeladen!';

  @override
  String get joinGroupSubtitle => 'Tippe unten, um dieser Gruppe beizutreten';

  @override
  String joinGroupSubtitleNamed(String groupName) {
    return '$groupName beitreten';
  }

  @override
  String joinGroupMembers(int count) {
    return '$count Mitglieder';
  }

  @override
  String get joinGroupOpenJoin => 'Offener Beitritt';

  @override
  String get joinGroupApprovalRequired => 'Genehmigung erforderlich';

  @override
  String get joinGroupButton => 'Gruppe beitreten';

  @override
  String get inviteCodeTitle => 'Einladungscode';

  @override
  String get inviteCopyLink => 'Link kopieren';

  @override
  String inviteShareText(String inviteLink, String inviteCode) {
    return 'Tritt meiner InGame-Gruppe über diesen Link bei: $inviteLink\nEinladungscode: $inviteCode';
  }

  @override
  String get inviteLinkCopied => 'Einladungslink in die Zwischenablage kopiert';

  @override
  String get inviteDetailsCopied => 'Einladungsdetails in die Zwischenablage kopiert';

  @override
  String get steamAuthConnecting => 'Verbindung zu Steam wird hergestellt...';

  @override
  String get steamAuthTryAgain => 'Erneut versuchen';

  @override
  String get steamAuthBackToPrefix => 'Zurueck zu';

  @override
  String get steamAuthBackToLogin => 'Zurueck zum Login';

  @override
  String get errorRetryAction => 'Erneut versuchen';

  @override
  String get authSignInCancelled => 'Anmeldung wurde abgebrochen.';

  @override
  String get authAppleSignInFailed => 'Apple-Anmeldung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get authErrorGeneric => 'Authentifizierung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get authErrorDebugPrefix => 'Authentifizierung fehlgeschlagen';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLoadError => 'Profil konnte nicht geladen werden';

  @override
  String get profileEdit => 'Profil bearbeiten';

  @override
  String get profileLogout => 'Abmelden';

  @override
  String get profileSectionAccount => 'Konto';

  @override
  String get profileSectionConnectedAccounts => 'Verknuepfte Konten';

  @override
  String get profileSectionPreferences => 'Einstellungen';

  @override
  String get profileEmailLabel => 'E-Mail';

  @override
  String get profileTimezoneLabel => 'Zeitzone';

  @override
  String get profileMemberSinceLabel => 'Mitglied seit';

  @override
  String get profileNotSet => 'Nicht festgelegt';

  @override
  String get profileUnknown => 'Unbekannt';

  @override
  String get profileConnected => 'Verbunden';

  @override
  String get profileNotConnected => 'Nicht verbunden';

  @override
  String get profileConnectedAccountsEmailPassword => 'E-Mail und Passwort';

  @override
  String get profileConnectedAccountsSteam => 'Steam';

  @override
  String get profileConnectedAccountsApple => 'Apple';

  @override
  String profileDisconnectTitle(String provider) {
    return '$provider trennen';
  }

  @override
  String profileDisconnectMessage(String provider) {
    return 'Moechtest du dein $provider-Konto wirklich trennen?';
  }

  @override
  String profileDisconnectFailed(String provider, String message) {
    return '$provider konnte nicht getrennt werden: $message';
  }

  @override
  String get profileSteamLinkedSuccess => 'Steam-Konto erfolgreich verknuepft';

  @override
  String profileLinkSteamFailed(String message) {
    return 'Steam konnte nicht verknuepft werden: $message';
  }

  @override
  String get profileSetEmailPasswordTitle => 'E-Mail und Passwort hinzufuegen';

  @override
  String get profileSetEmailPasswordDescription => 'Fuege eine E-Mail-Anmeldung zu deinem Konto hinzu, damit du dich ohne Social-Provider anmelden kannst.';

  @override
  String get profileEmailPasswordAddedSuccess => 'E-Mail und Passwort erfolgreich hinzugefuegt';

  @override
  String profileSetEmailFailed(String message) {
    return 'E-Mail konnte nicht gesetzt werden: $message';
  }

  @override
  String get profileAppleLinkedSuccess => 'Apple-Konto erfolgreich verknuepft';

  @override
  String get profileAppleSignInFailed => 'Apple-Anmeldung fehlgeschlagen.';

  @override
  String profileLinkAppleFailed(String message) {
    return 'Apple konnte nicht verknuepft werden: $message';
  }

  @override
  String get profileSectionGamingHours => 'Gaming-Zeiten';

  @override
  String get profileNoSchedule => 'Kein Zeitplan festgelegt';

  @override
  String get profileEveryDay => 'Jeden Tag';

  @override
  String get profileWeekdays => 'Wochentage';

  @override
  String get profileWeekends => 'Wochenende';

  @override
  String get editProfileTitle => 'Profil bearbeiten';

  @override
  String get editProfileDisplayNameHint => 'Gib deinen Anzeigenamen ein';

  @override
  String get editProfileBioLabel => 'Bio';

  @override
  String get editProfileBioHint => 'Erzähle anderen etwas über dich';

  @override
  String get editProfileSave => 'Änderungen speichern';

  @override
  String get avatarUploadSoon => 'Avatar-Upload kommt bald';

  @override
  String get timezoneLabel => 'Zeitzone';

  @override
  String get gamingHoursTitle => 'Gaming-Zeiten';

  @override
  String get gamingHoursNotSet => 'Nicht festgelegt';

  @override
  String gamingHoursSelectStartTime(String day) {
    return 'Startzeit für $day wählen';
  }

  @override
  String gamingHoursSelectEndTime(String day) {
    return 'Endzeit für $day wählen';
  }

  @override
  String get commonAdd => 'Hinzufuegen';

  @override
  String get groupTitleFallback => 'Gruppe';

  @override
  String get groupVisibilityPublic => 'Oeffentlich';

  @override
  String get groupVisibilityPrivate => 'Privat';

  @override
  String get groupJoinModeOpenLabel => 'Offen';

  @override
  String get groupJoinModeApprovalLabel => 'Freigabe';

  @override
  String get groupJoinModeOpenDescription => 'Jede Person kann sofort beitreten';

  @override
  String get groupJoinModeApprovalDescription => 'Mitglieder muessen von einem Admin bestaetigt werden';

  @override
  String get groupDetailMenuInvite => 'Einladen';

  @override
  String get groupDetailMenuSettings => 'Einstellungen';

  @override
  String get groupDetailMenuLeave => 'Gruppe verlassen';

  @override
  String get groupDetailSectionAbout => 'Ueber die Gruppe';

  @override
  String get groupDetailSectionMembers => 'Mitglieder';

  @override
  String get groupDetailLeaveTitle => 'Gruppe verlassen';

  @override
  String get groupDetailLeaveMessage => 'Moechtest du diese Gruppe wirklich verlassen?';

  @override
  String get createGroupTitle => 'Gruppe erstellen';

  @override
  String get createGroupNameLabel => 'Gruppenname';

  @override
  String get createGroupNameHint => 'Gib einen Namen fuer deine Gruppe ein';

  @override
  String get createGroupNameRequired => 'Ein Gruppenname ist erforderlich';

  @override
  String get createGroupNameMin => 'Der Name muss mindestens 3 Zeichen lang sein';

  @override
  String get createGroupDescriptionLabel => 'Beschreibung';

  @override
  String get createGroupDescriptionHint => 'Worum geht es in dieser Gruppe? (optional)';

  @override
  String get createGroupDiscoverableTitle => 'Auffindbar';

  @override
  String get createGroupDiscoverableSubtitle => 'Erlaube anderen, diese Gruppe zu finden und ihr beizutreten';

  @override
  String get createGroupJoinModeLabel => 'Beitrittsmodus';

  @override
  String get createGroupSubmit => 'Gruppe erstellen';

  @override
  String get groupSettingsTitle => 'Gruppeneinstellungen';

  @override
  String get groupSettingsUpdated => 'Gruppe aktualisiert';

  @override
  String get groupSettingsRemoveMemberTitle => 'Mitglied entfernen';

  @override
  String groupSettingsRemoveMemberMessage(String displayName) {
    return '$displayName aus dieser Gruppe entfernen?';
  }

  @override
  String groupSettingsMemberRemoved(String displayName) {
    return '$displayName entfernt';
  }

  @override
  String get groupSettingsRequestApproved => 'Anfrage bestaetigt';

  @override
  String get groupSettingsDenyRequestTitle => 'Anfrage ablehnen';

  @override
  String groupSettingsDenyRequestMessage(String displayName) {
    return 'Beitrittsanfrage von $displayName ablehnen?';
  }

  @override
  String get groupSettingsRequestDenied => 'Anfrage abgelehnt';

  @override
  String get groupSettingsDeleteTitle => 'Gruppe loeschen';

  @override
  String get groupSettingsDeleteMessage => 'Diese Aktion kann nicht rueckgaengig gemacht werden. Alle Mitglieder werden entfernt.';

  @override
  String get groupSettingsSectionGroupInfo => 'Gruppeninfo';

  @override
  String get groupSettingsSectionVisibility => 'Sichtbarkeit';

  @override
  String groupSettingsSectionMembers(int count) {
    return 'Mitglieder ($count)';
  }

  @override
  String groupSettingsSectionPendingRequests(int count) {
    return 'Offene Anfragen ($count)';
  }

  @override
  String get groupSettingsSectionDangerZone => 'Gefahrenzone';

  @override
  String get groupSettingsDangerDescription => 'Das Loeschen dieser Gruppe ist dauerhaft und entfernt alle Mitglieder.';

  @override
  String get groupSettingsRemoveTooltip => 'Entfernen';

  @override
  String get groupSettingsApproveTooltip => 'Genehmigen';

  @override
  String get groupSettingsDenyTooltip => 'Ablehnen';

  @override
  String get groupSettingsRoleMember => 'Mitglied';

  @override
  String groupSettingsTimeAgoDays(int count) {
    return 'vor $count T';
  }

  @override
  String groupSettingsTimeAgoHours(int count) {
    return 'vor $count Std';
  }

  @override
  String groupSettingsTimeAgoMinutes(int count) {
    return 'vor $count Min';
  }

  @override
  String get dayMonShort => 'Mo';

  @override
  String get dayTueShort => 'Di';

  @override
  String get dayWedShort => 'Mi';

  @override
  String get dayThuShort => 'Do';

  @override
  String get dayFriShort => 'Fr';

  @override
  String get daySatShort => 'Sa';

  @override
  String get daySunShort => 'So';

  @override
  String get memberRoleOwner => 'Besitzer';

  @override
  String get memberRoleAdmin => 'Admin';

  @override
  String get memberStatusReady => 'Spielbereit';

  @override
  String get memberStatusOnline => 'Online';

  @override
  String get memberStatusAway => 'Abwesend';

  @override
  String get memberStatusOffline => 'Offline';

  @override
  String get groupDetailReadyToggleLabel => 'Spielbereit';

  @override
  String get groupDetailReadyToggleHint => 'Zeig deiner Gruppe, dass du zum Spielen verfügbar bist';

  @override
  String get languageSwitcherLabel => 'Sprache';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';
}
