# Snap Motion iOS

This folder contains the native iOS plan and starter source layout for Snap Motion.

The app target should be created in Xcode as a SwiftUI iOS app with:

- Minimum iOS: 17.0
- Device family: iPhone
- Required capability: camera access
- Required hardware for live face tracking: TrueDepth front camera

Required `Info.plist` key:

```xml
<key>NSCameraUsageDescription</key>
<string>Snap Motion uses the front camera to capture face poses and drive your avatar preview.</string>
```

Suggested first target contents:

- Add every `.swift` file under `apps/ios/SnapMotion`.
- Add `Resources/AvatarAssets.scnassets` to the app target.
- Replace the placeholder `CuteAvatarTemplate.scn` reference with the real SceneKit rig when available.

See [iOS Technical Plan](/Users/endlessovo/dev/ai/snap-motion/docs/ios-technical-plan.md) for architecture, milestones, and backend contract details.
