# Snap Motion iOS Technical Plan

## Product Target

Snap Motion iOS focuses on a native, device-first avatar enrollment and preview flow:

- SwiftUI screens for enrollment, generation progress, and avatar preview.
- ARKit real-time face tracking through `ARFaceTrackingConfiguration`.
- SceneKit avatar rendering driven by `ARFaceAnchor.blendShapes`.
- A backend generation job that turns selected selfie frames into a structured `AvatarRecipe`.
- A cute, controllable template rig instead of an AI-generated arbitrary 3D mesh.

The first production-quality version should feel similar to Face ID enrollment: the user follows an oval guide, turns their head, blinks, opens their mouth, and receives an animated avatar preview when generation completes.

## Architecture

```txt
SwiftUI Feature Layer
  FaceEnrollment -> GenerationProgress -> AvatarPreview

Domain Models
  AvatarRecipe, AvatarJob, CaptureManifest, FaceTrackingFrame

Core Services
  Camera permission
  AR face tracking
  Face quality scoring
  SceneKit rendering
  Networking
  Local storage
```

The client is responsible for:

- Capturing a small, high-quality set of frames, not a long raw video by default.
- Estimating enrollment progress locally from pose, expression, blur, and lighting.
- Uploading a manifest plus selected frames.
- Polling avatar generation status.
- Rendering a deterministic template rig from `AvatarRecipe`.

The backend is responsible for:

- Creating upload jobs and short-lived upload URLs.
- Calling an OpenAI-compatible vision model to infer structured avatar parameters.
- Validating the result against the shared schema.
- Producing texture URLs and finalized `AvatarRecipe` data.
- Deleting raw enrollment media after the task reaches a terminal state.

## Enrollment Flow

1. Request camera permission.
2. Start `ARFaceTrackingSession` only on supported devices.
3. Show the face oval and live progress markers.
4. Collect frames for neutral, left, right, up, down, blink, mouth open, and smile.
5. Score every candidate frame for lighting, blur, face presence, and target pose.
6. Keep the best frame per required capture slot.
7. Submit the selected enrollment package.
8. Route to generation progress.

Recommended first-version capture slots:

| Slot | Purpose |
| --- | --- |
| `neutralFront` | Main identity and skin tone reference |
| `turnLeft` | Face shape, jaw, ears, hair side profile |
| `turnRight` | Face shape, jaw, ears, hair side profile |
| `lookUp` | Chin, lower face, glasses fit |
| `lookDown` | Brow, hairline, glasses fit |
| `blink` | Eye shape and eyelid behavior |
| `mouthOpen` | Mouth rig calibration |
| `smile` | Expression style and cheek behavior |

## Rendering Strategy

SceneKit is the first-version renderer because it gives stable access to:

- `SCNScene` assets in `AvatarAssets.scnassets`.
- Morph targets through `SCNMorpher`.
- A simple bridge into SwiftUI through `SCNView`.
- Straightforward mapping from ARKit blend shapes to rig morph names.

RealityKit can be evaluated later for better asset pipelines or spatial rendering, but it should not block the first useful avatar preview.

The rig should expose normalized morph target names such as:

- `blink_L`, `blink_R`
- `jaw_open`
- `smile_L`, `smile_R`
- `brow_up_L`, `brow_up_R`
- `mouth_funnel`, `mouth_pucker`
- `cheek_squint_L`, `cheek_squint_R`

`AvatarExpressionMapper` owns the mapping from ARKit blend shapes to these rig names.

## `AvatarRecipe`

`AvatarRecipe` is a stable contract between backend and iOS. It should be:

- Strictly versioned.
- Codable on iOS.
- Validated by JSON Schema on the backend.
- Expressive enough to customize a template rig.
- Conservative enough to avoid arbitrary asset execution.

The recipe should describe:

- Face shape and proportions.
- Skin tone and material parameters.
- Eye, eyebrow, nose, and mouth styles.
- Hair style, color, and optional facial hair.
- Accessories such as glasses.
- Texture resource URLs or cache keys.
- Rig preset and morph calibration multipliers.

See [avatar-recipe.schema.json](/Users/endlessovo/dev/ai/snap-motion/docs/avatar-recipe.schema.json).

## Backend API Contract

### `POST /v1/avatar-jobs`

Creates a job and returns upload slots.

Request:

```json
{
  "device_id": "anonymous-device-id",
  "client": {
    "platform": "ios",
    "app_version": "1.0.0",
    "os_version": "17.0"
  },
  "manifest": {
    "schema_version": 1,
    "capture_slots": ["neutralFront", "turnLeft", "turnRight"]
  }
}
```

Response:

```json
{
  "job_id": "job_123",
  "status": "waiting_for_upload",
  "upload_urls": [
    {
      "slot": "neutralFront",
      "url": "https://storage.example/upload/neutralFront",
      "method": "PUT",
      "content_type": "image/jpeg"
    }
  ]
}
```

### `POST /v1/avatar-jobs/{job_id}/uploads/complete`

Confirms all selected frames are uploaded and starts generation.

### `GET /v1/avatar-jobs/{job_id}`

Returns current status:

- `waiting_for_upload`
- `queued`
- `processing`
- `succeeded`
- `failed`
- `expired`

### `GET /v1/avatars/{avatar_id}`

Returns the finalized `AvatarRecipe` plus signed asset URLs.

## Module Responsibilities

### `FaceEnrollment`

- SwiftUI enrollment surface.
- Oval guide and pose prompts.
- View model state machine.
- Quality-gated frame selection.

### `ARFaceTracking`

- Owns `ARSession`.
- Converts `ARFaceAnchor` into `FaceTrackingFrame`.
- Avoids leaking ARKit details into feature views.

### `FaceQuality`

- Lighting evaluation.
- Blur estimation.
- Pose target scoring.
- Best-frame selection per capture slot.

### `Rendering`

- Loads the SceneKit template rig.
- Applies recipe style and material parameters.
- Applies real-time expression frames.
- Centralizes ARKit-to-rig mapping.

### `Networking`

- Creates and tracks generation jobs.
- Uploads selected frames.
- Downloads recipes and assets.
- Keeps transport DTOs separate from UI state.

### `LocalStorage`

- Anonymous device identity.
- Cached recipe data.
- Cached texture and template assets.

## Milestones

### Milestone 1: Local Preview Prototype

- Build SwiftUI navigation.
- Add a static `AvatarRecipe` fixture.
- Load the template SceneKit avatar.
- Drive blink, jaw, and smile with local sliders.

Exit criteria:

- The avatar renders on device.
- Morph targets can be driven without ARKit.
- The UI has the final navigation shape.

### Milestone 2: Live AR Expression Driving

- Add `ARFaceTrackingSession`.
- Map selected ARKit blend shapes to rig morphs.
- Add face support and permission handling.

Exit criteria:

- Blink, jaw open, smile, and head pose drive the avatar live on iPhone 12+.
- Unsupported devices fail gracefully.

### Milestone 3: Enrollment Capture

- Implement pose progress.
- Add lighting and blur checks.
- Select best frames for required slots.
- Produce `CaptureManifest`.

Exit criteria:

- Enrollment succeeds only with all required slots.
- Failure and retry states are covered.

### Milestone 4: Backend Generation

- Implement job creation, uploads, polling, and recipe download.
- Add schema validation on backend.
- Cache the completed recipe locally.

Exit criteria:

- A real enrollment package returns a rendered avatar.
- Raw source frames are deleted after terminal job completion.

### Milestone 5: Polish and Device Validation

- Tune morph multipliers.
- Add loading and error states.
- Run UI tests and device matrix checks.

Exit criteria:

- iPhone 12+ on iOS 17+ gives stable enrollment and preview.
- Unit tests cover recipe decoding, job status, expression mapping, and quality scoring.

## Test Plan

Unit tests:

- `AvatarRecipe` decoding from fixtures.
- `AvatarJob.Status` decoding and terminal-state behavior.
- `AvatarExpressionMapper` mapping weights and clamping.
- `CaptureFrameSelector` choosing best candidate per slot.
- `FaceQualityEvaluator` scoring low light, blur, and pose misses.

UI tests:

- Permission denied.
- Enrollment success.
- Enrollment failure and retry.
- Generation progress success.
- Generation failure.
- Avatar preview loaded.

Device validation:

- iPhone 12, 13, 14, 15, and 16 families where available.
- Front TrueDepth camera required for ARKit face tracking.
- Indoor low light and bright backlight.
- Glasses, facial hair, long hair, and varied skin tones.

Backend tests:

- Upload URL creation.
- Upload completion transition.
- Provider response parsing.
- JSON Schema validation.
- Expiration and raw-media deletion.

## Risks and Decisions

| Area | Decision | Risk | Mitigation |
| --- | --- | --- | --- |
| 3D generation | Template rig plus recipe | Less unique geometry | Faster, controllable, animatable results |
| Renderer | SceneKit first | Older API surface | Stable morph support and SwiftUI bridge |
| Capture media | Selected frames | Less temporal data | Add short clips later only if needed |
| Identity | Anonymous device ID | No cross-device sync | Add account layer after retention policy is clear |
| Provider | OpenAI-compatible vision API | Model output drift | Schema validation and retry repair pass |

## Open Questions

- Should the first backend accept JPEG frames only, or also short HEVC clips?
- What retention window is acceptable for raw enrollment media before deletion?
- Do we want an on-device-only demo mode using bundled recipes?
- Which provider will be the first real OpenAI-compatible vision backend?
- Does the app need COPPA or age-gate handling before launch?
