# Snap Motion Product and Compliance Decisions

Last updated: 2026-06-09

## Backend Input Format

The first backend version accepts JPEG still frames only.

Accepted input:

- `image/jpeg`
- One selected frame for each `CaptureSlot`
- A `CaptureManifest` that includes device metadata, capture slot names, quality scores, pose, local capture time, and the local client file URL

Not accepted in the first version:

- HEVC video
- Long raw enrollment video
- Arbitrary user-provided archives
- Non-image uploads

Rationale: JPEG frames keep upload size, moderation scope, storage risk, and generation cost lower. The iOS client already selects the best frame per slot, so sending long video would add privacy and infrastructure cost before it is needed.

## Raw Media Retention

Raw enrollment media is deleted immediately after a job reaches a terminal state.

Terminal states:

- `succeeded`
- `failed`
- `expired`

What remains after deletion:

- Job ID
- Final status
- Error message, if any
- Avatar ID, if generation succeeded
- Final `AvatarRecipe`
- Timestamps and non-sensitive operational metadata

What must not remain:

- Original JPEG enrollment frames
- Raw videos
- Temporary provider input files

The local Node backend implements this policy by deleting the upload directory in `markSucceeded`, `markFailed`, and `markExpired`.

## First Model Provider

The first production integration target is an OpenAI-compatible vision model endpoint configured by environment variables:

- `OPENAI_COMPATIBLE_BASE_URL`
- `OPENAI_COMPATIBLE_API_KEY`
- `OPENAI_COMPATIBLE_MODEL`

The backend falls back to a local fixture generator when these variables are not set. This keeps local development deterministic while preserving a clear provider integration path.

Provider selection criteria for production:

- Can process the selected JPEG frame set
- Can return strict JSON
- Supports a low-latency, low-cost vision model
- Allows the app to avoid retaining raw media after terminal job state
- Provides operational logs without requiring long-term storage of user images

The first production provider must be recorded with:

- Average generation latency
- Average input/output token usage or equivalent billing units
- Failure rate
- Schema invalid rate
- Cost per successful generation

## Age Gate and Child Safety

The first version is not designed for children and should include a 13+ age gate before public release.

Policy:

- Do not market Snap Motion to children.
- Do not knowingly collect face enrollment media from users under 13.
- Add an age confirmation gate before production onboarding.
- If the product direction changes toward children or school/family use, perform a COPPA review before collecting any face media.

Until the age gate is implemented in-app, production release remains blocked.

## Privacy Copy Requirements

Before production release, onboarding and privacy policy copy must state:

- The camera is used for face pose capture and avatar preview.
- Selected JPEG frames are uploaded only for avatar generation.
- Raw uploaded frames are deleted when generation succeeds, fails, or expires.
- The generated `AvatarRecipe` may be retained to render the avatar.
- Users can retry generation, which creates a new job and new temporary uploads.
