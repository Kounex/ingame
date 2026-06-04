import '../../../core/utils/validators.dart';

bool isOnboardingProfileSubmissionValid({
  required String displayName,
  required String email,
  required bool hasEmailAvailabilityError,
}) {
  return FormValidators.displayName(displayName) == null &&
      FormValidators.email(email) == null &&
      !hasEmailAvailabilityError;
}
