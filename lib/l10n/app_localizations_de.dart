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
  String get validatorEmailInvalid => 'Gib eine gueltige E-Mail-Adresse ein';

  @override
  String get validatorPasswordRequired => 'Passwort ist erforderlich';

  @override
  String get validatorPasswordMin => 'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get validatorPasswordConfirmRequired => 'Bitte bestaetige dein Passwort';

  @override
  String get validatorPasswordsMismatch => 'Die Passwoerter stimmen nicht ueberein';

  @override
  String get validatorDisplayNameRequired => 'Anzeigename ist erforderlich';

  @override
  String get validatorDisplayNameMin => 'Der Anzeigename muss mindestens 2 Zeichen lang sein';

  @override
  String get validatorDisplayNameMax => 'Der Anzeigename darf hoechstens 30 Zeichen lang sein';

  @override
  String get errorSomethingWentWrong => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorConnectionTimedOut => 'Zeitueberschreitung bei der Verbindung. Bitte pruefe dein Internet.';

  @override
  String get errorCouldNotConnect => 'Es konnte keine Verbindung zum Server hergestellt werden. Bitte versuche es spaeter erneut.';

  @override
  String get errorNetwork => 'Netzwerkfehler. Bitte pruefe deine Verbindung.';

  @override
  String get errorInvalidRequest => 'Ungueltige Anfrage. Bitte pruefe deine Eingaben.';

  @override
  String get errorInvalidCredentials => 'Ungueltige Anmeldedaten. Bitte versuche es erneut.';

  @override
  String get errorNoPermission => 'Du hast keine Berechtigung dafuer.';

  @override
  String get errorNotFound => 'Nicht gefunden.';

  @override
  String get errorAlreadyExists => 'Diese Ressource existiert bereits.';

  @override
  String get errorCheckInput => 'Bitte pruefe deine Eingaben.';

  @override
  String get errorTooManyRequests => 'Zu viele Anfragen. Bitte warte einen Moment.';

  @override
  String get errorServer => 'Serverfehler. Bitte versuche es spaeter erneut.';

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
  String get commonBack => 'Zurueck';

  @override
  String get commonNext => 'Weiter';

  @override
  String get commonFinish => 'Fertig';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Loeschen';

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
  String get registerDisplayNameHint => 'Waehle einen Anzeigenamen';

  @override
  String get registerEmailTaken => 'Diese E-Mail ist bereits vergeben';

  @override
  String get registerDisplayNameTaken => 'Dieser Anzeigename ist bereits vergeben';

  @override
  String get registerPasswordHint => 'Erstelle ein Passwort';

  @override
  String get registerConfirmPasswordLabel => 'Passwort bestaetigen';

  @override
  String get registerConfirmPasswordHint => 'Bestaetige dein Passwort';

  @override
  String get registerSubmit => 'Konto erstellen';

  @override
  String get registerAlreadyHaveAccount => 'Hast du bereits ein Konto?';

  @override
  String get registerLogin => 'Anmelden';

  @override
  String get onboardingTimeSlotRequired => 'Waehle mindestens ein Zeitfenster aus, um das Onboarding abzuschliessen.';

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
  String get onboardingBioHint => 'Erzaehle anderen etwas ueber dich (optional)';

  @override
  String get onboardingAvatarUrlLabel => 'Avatar-URL';

  @override
  String get onboardingAvatarUrlHint => 'Link zu deinem Avatarbild (optional)';

  @override
  String get onboardingGamingTitle => 'Gaming-Praeferenzen';

  @override
  String get onboardingGamingSubtitle => 'Waehle mindestens ein Zeitfenster, damit Gruppen sehen koennen, wann du spielst.';

  @override
  String get onboardingConnectSteamTitle => 'Steam verbinden';

  @override
  String get onboardingConnectSteamSubtitle => 'Verknuepfe dein Konto spaeter in den Einstellungen';

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
    return 'Tritt meiner InGame-Gruppe ueber diesen Link bei: $inviteLink\nEinladungscode: $inviteCode';
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
  String get steamAuthBackToLogin => 'Zurueck zum Login';

  @override
  String get errorRetryAction => 'Erneut versuchen';

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
  String get editProfileBioHint => 'Erzaehle anderen etwas ueber dich';

  @override
  String get editProfileSave => 'Aenderungen speichern';

  @override
  String get avatarUploadSoon => 'Avatar-Upload kommt bald';

  @override
  String get timezoneLabel => 'Zeitzone';

  @override
  String get gamingHoursTitle => 'Gaming-Zeiten';

  @override
  String get gamingHoursNotSet => 'Nicht festgelegt';

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
}
