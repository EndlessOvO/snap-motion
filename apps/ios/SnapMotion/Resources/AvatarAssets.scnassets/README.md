# Avatar Assets

Expected first-version asset:

- `CuteAvatarTemplate.scn`

Expected rig morph targets:

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
