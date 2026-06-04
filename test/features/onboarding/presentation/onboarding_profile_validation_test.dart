import 'package:flutter_test/flutter_test.dart';
import 'package:ingame/features/onboarding/presentation/onboarding_profile_validation.dart';

void main() {
  test(
    'submission validation succeeds for a valid untouched onboarding profile',
    () {
      expect(
        isOnboardingProfileSubmissionValid(
          displayName: 'Ready Player',
          email: 'ready@test.com',
          hasEmailAvailabilityError: false,
        ),
        isTrue,
      );
    },
  );

  test(
    'submission validation fails when the email availability check failed',
    () {
      expect(
        isOnboardingProfileSubmissionValid(
          displayName: 'Ready Player',
          email: 'ready@test.com',
          hasEmailAvailabilityError: true,
        ),
        isFalse,
      );
    },
  );

  test('submission validation fails for invalid profile fields', () {
    expect(
      isOnboardingProfileSubmissionValid(
        displayName: 'R',
        email: 'not-an-email',
        hasEmailAvailabilityError: false,
      ),
      isFalse,
    );
  });
}
