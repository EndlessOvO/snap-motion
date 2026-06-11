# Snap Motion Device Validation Matrix

Last updated: 2026-06-10

Run this matrix before TestFlight or production release. Results should be recorded with device model, iOS version, build number, lighting condition, and pass/fail notes.

## Verified So Far

- iPhone 17 / iOS 26.4.1 connected over USB with Developer Mode enabled and DDI services available.
- Xcode 26.5 with iOS 26.5 SDK builds `SnapMotion` for the connected iPhone.
- Apple Development signing with Team `G758ATTU5P` installs and launches `local.snapmotion.SnapMotion` on the connected iPhone.
- iPhone 17 / iOS 26.5 Simulator unit and UI tests pass.
- `./scripts/verify.sh` passes on Xcode 26.5.

## Required Devices

Minimum matrix:

- iPhone 12 or newer with TrueDepth camera, iOS 17+
- One current-generation iPhone with latest iOS
- One older supported iPhone with iOS 17.x

Simulator can verify navigation, fixture preview, error states, and backend fallback flows, but it does not validate AR face tracking quality.

## Capture Conditions

Run enrollment under each condition:

- Indoor soft light
- Low light
- Strong backlight
- Glasses
- Facial hair
- Long hair or bangs near face outline
- Multiple skin tones

## Pass Criteria

Enrollment:

- Camera permission prompt appears before camera use.
- Denied camera permission shows a clear retry/error state.
- Unsupported devices show a TrueDepth requirement state.
- Every `CaptureSlot` can be completed from live AR frames.
- Saved JPEG frames exist for every completed slot.
- `CaptureManifest` contains real device model, OS version, app version, pose, quality, and slot metadata.

Preview:

- Fixture avatar loads without network or backend.
- Missing real SceneKit asset falls back to the built-in procedural rig.
- Manual blink, mouth, and smile controls visibly affect the avatar.
- Live mode drives blink, jaw open, smile, and head pose from ARKit blend shapes.
- Reload recovers from avatar load failure.

Generation:

- Backend job creation succeeds.
- Upload URLs accept only `image/jpeg`.
- All selected frames upload successfully.
- Upload completion starts generation.
- Polling reaches `succeeded` with fixture fallback when no provider is configured.
- Polling reaches a visible failure state when backend generation fails.
- Raw uploaded frames are deleted when a job reaches `succeeded`, `failed`, or `expired`.

Compliance:

- 13+ age confirmation appears before production onboarding.
- Camera and upload copy matches privacy policy language.
- No raw enrollment frames remain after terminal job cleanup.

## Remaining Pre-Release Work

- Replace procedural fallback with a production SceneKit template rig.
- Validate morph target names and `AvatarRecipe.rig.morphCalibration` on real devices.
- Record production provider latency, cost, failure rate, and schema invalid rate.
- Complete and record the capture-condition matrix below on at least one current iPhone and one older supported iPhone.
