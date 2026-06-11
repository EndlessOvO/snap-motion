# Avatar Assets

Included first-version demo asset:

- `CuteAvatarTemplate.scn`
- `CuteAvatarTemplate.dae` source used to generate the SceneKit asset

The demo rig exposes these morph targets:

- `blink_L`
- `blink_R`
- `jaw_open`
- `smile_L`
- `smile_R`
- `brow_up_L`
- `brow_up_R`
- `mouth_funnel`
- `mouth_pucker`
- `cheek_squint_L`
- `cheek_squint_R`

Keep template assets deterministic and versioned. The backend should reference the selected template through `AvatarRecipe.rig.template_id`.

The included rig is intentionally minimal and is suitable for local preview, target validation, and regression testing. Replace it with a production-quality character rig before release.
