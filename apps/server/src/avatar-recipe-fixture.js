export function makeFixtureRecipe({ avatarID = "avatar_fixture", displayName = "Snap Friend" } = {}) {
  return {
    schema_version: 1,
    avatar_id: avatarID,
    display_name: displayName,
    rig: {
      template_id: "cute_avatar_v1",
      morph_calibration: {
        blink_L: 1,
        blink_R: 1,
        jaw_open: 1,
        smile_L: 1,
        smile_R: 1,
        brow_up_L: 1,
        brow_up_R: 1,
        mouth_funnel: 1,
        mouth_pucker: 1,
        cheek_squint_L: 1,
        cheek_squint_R: 1
      }
    },
    face: {
      shape: "round",
      roundness: 0.72,
      jaw_width: 0.42,
      cheek_fullness: 0.78
    },
    skin: {
      tone_hex: "#E9B98F",
      warmth: 0.62,
      roughness: 0.36
    },
    eyes: {
      shape: "almond",
      color_hex: "#4A2C1A",
      size: 0.64,
      spacing: 0.52
    },
    brows: {
      shape: "soft_arch",
      color_hex: "#2B1B12",
      thickness: 0.58
    },
    nose: {
      style: "soft",
      width: 0.46,
      length: 0.5
    },
    mouth: {
      style: "soft_smile",
      width: 0.55,
      fullness: 0.48
    },
    hair: {
      style: "wavy",
      color_hex: "#24170F",
      facial_hair: "none"
    },
    accessories: [],
    materials: {
      skin_texture_url: "https://assets.snap-motion.local/skin-fixture.png",
      hair_texture_url: "https://assets.snap-motion.local/hair-fixture.png",
      extra_texture_urls: []
    }
  };
}
