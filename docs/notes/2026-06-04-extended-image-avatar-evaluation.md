# ExtendedImage Avatar Evaluation

## Recommendation

`adopt`

Adopt the shared `extended_image` square editor for every supported avatar image source and keep `EditableAvatarField` centered on one edit-before-upload flow.

## Why

1. The refactor proved that `extended_image` can support the full shared square crop UI while keeping the existing presigned upload contract unchanged.
2. Every supported image source now follows one editor-centered path, which removes the old split between upload, mobile cropper branches, and direct URL persistence.
3. Existing avatars, including provider avatars such as Steam, can now reopen directly in the editor on tap while `Change photo` remains available for source switching.
4. The picker/source-loader/editor seams keep the shared widget testable through provider overrides instead of platform-channel-heavy tests.
5. Removing `image_cropper` reduced dependency surface and left one maintained avatar-editing model instead of two.

## Code Impact

Added:

- `lib/shared/services/avatar_image_editor.dart`
- `lib/shared/services/avatar_image_picker.dart`
- `lib/shared/services/avatar_source_loader.dart`
- `lib/shared/widgets/avatar_editor_dialog.dart`

Modified:

- `lib/shared/widgets/editable_avatar_field.dart`
- `test/shared/widgets/editable_avatar_field_test.dart`
- `docs/specs/2026-05-30-core-platform-profiles.md`
- `docs/specs/roadmap.md`
- `pubspec.yaml`
- `pubspec.lock`

Dependency impact:

- Added `extended_image`
- Added `image`
- Removed `image_cropper`
- Kept `image_picker`
- Kept `file_selector`

## Test Impact

Automated coverage added or revalidated:

- `test/shared/widgets/editable_avatar_field_test.dart`
  - direct edit tap for existing avatars
  - separate `Change photo` chooser path
  - `Upload photo`, `Photo library`, and `Take photo` all route through the editor boundary
  - URL fetch -> crop -> upload
  - cancel leaves the current avatar unchanged
  - existing remove/pointer/fallback regressions still pass
- Existing onboarding and edit-profile tests still pass with the shared widget in place

Validation completed in this spike:

- `flutter analyze` on the avatar spike files
- targeted widget tests for avatar, onboarding, and edit-profile flows

Manual validation still recommended before treating this as a final cross-platform migration decision:

- Web: crop responsiveness with large images, upload success against real storage CORS
- iOS: gesture feel, small-screen dialog usability, orientation behavior
- Android: gesture feel, back/dismiss behavior, large-image responsiveness

## Spec Impact

Updated `docs/specs/2026-05-30-core-platform-profiles.md` to reflect the maintained unified contract:

- every supported avatar image source routes through the shared square editor
- tapping an existing avatar reopens it directly for editing
- URL input now fetches/crops/uploads instead of persisting external URLs directly

## Follow-up Options

1. Validate real-device/editor ergonomics for camera and library images on iOS/Android.
2. Validate real remote-image fetch behavior for provider avatars and arbitrary URL input on Web, especially around CORS.
3. Refine the shared editor UI if needed without reopening the source-specific architecture decision.
