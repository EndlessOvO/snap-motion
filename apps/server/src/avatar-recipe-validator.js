const FACE_SHAPES = new Set(["round", "oval", "heart", "square", "long"]);
const EYE_SHAPES = new Set(["almond", "round", "monolid", "hooded", "upturned", "downturned"]);
const BROW_SHAPES = new Set(["soft_arch", "straight", "rounded", "angled"]);
const NOSE_STYLES = new Set(["button", "straight", "soft", "defined"]);
const MOUTH_STYLES = new Set(["soft_smile", "small", "wide", "full"]);
const HAIR_STYLES = new Set(["short", "bob", "long", "curly", "wavy", "buzz", "bald", "ponytail"]);
const FACIAL_HAIR = new Set(["none", "stubble", "mustache", "beard"]);
const ACCESSORY_TYPES = new Set(["glasses", "earrings", "hat"]);
const HEX_COLOR = /^#[0-9A-Fa-f]{6}$/;

export function validateAvatarRecipe(recipe) {
  const errors = [];

  object(recipe, "recipe", errors);
  if (errors.length > 0) {
    return { valid: false, errors };
  }

  exactKeys(recipe, [
    "schema_version",
    "avatar_id",
    "display_name",
    "rig",
    "face",
    "skin",
    "eyes",
    "brows",
    "nose",
    "mouth",
    "hair",
    "accessories",
    "materials"
  ], "recipe", errors, ["display_name"]);

  equals(recipe.schema_version, 1, "schema_version", errors);
  nonEmptyString(recipe.avatar_id, "avatar_id", errors);
  optionalString(recipe.display_name, "display_name", errors);
  validateRig(recipe.rig, errors);
  validateFace(recipe.face, errors);
  validateSkin(recipe.skin, errors);
  validateEyes(recipe.eyes, errors);
  validateBrows(recipe.brows, errors);
  validateNose(recipe.nose, errors);
  validateMouth(recipe.mouth, errors);
  validateHair(recipe.hair, errors);
  validateAccessories(recipe.accessories, errors);
  validateMaterials(recipe.materials, errors);

  return { valid: errors.length === 0, errors };
}

function validateRig(value, errors) {
  object(value, "rig", errors);
  if (!value) return;
  exactKeys(value, ["template_id", "morph_calibration"], "rig", errors);
  nonEmptyString(value.template_id, "rig.template_id", errors);
  object(value.morph_calibration, "rig.morph_calibration", errors);
  if (value.morph_calibration) {
    for (const [key, calibration] of Object.entries(value.morph_calibration)) {
      nonEmptyString(key, "rig.morph_calibration key", errors);
      numberRange(calibration, 0, 3, `rig.morph_calibration.${key}`, errors);
    }
  }
}

function validateFace(value, errors) {
  object(value, "face", errors);
  if (!value) return;
  exactKeys(value, ["shape", "roundness", "jaw_width", "cheek_fullness"], "face", errors);
  enumValue(value.shape, FACE_SHAPES, "face.shape", errors);
  numberRange(value.roundness, 0, 1, "face.roundness", errors);
  numberRange(value.jaw_width, 0, 1, "face.jaw_width", errors);
  numberRange(value.cheek_fullness, 0, 1, "face.cheek_fullness", errors);
}

function validateSkin(value, errors) {
  object(value, "skin", errors);
  if (!value) return;
  exactKeys(value, ["tone_hex", "warmth", "roughness"], "skin", errors);
  hex(value.tone_hex, "skin.tone_hex", errors);
  numberRange(value.warmth, 0, 1, "skin.warmth", errors);
  numberRange(value.roughness, 0, 1, "skin.roughness", errors);
}

function validateEyes(value, errors) {
  object(value, "eyes", errors);
  if (!value) return;
  exactKeys(value, ["shape", "color_hex", "size", "spacing"], "eyes", errors);
  enumValue(value.shape, EYE_SHAPES, "eyes.shape", errors);
  hex(value.color_hex, "eyes.color_hex", errors);
  numberRange(value.size, 0, 1, "eyes.size", errors);
  numberRange(value.spacing, 0, 1, "eyes.spacing", errors);
}

function validateBrows(value, errors) {
  object(value, "brows", errors);
  if (!value) return;
  exactKeys(value, ["shape", "color_hex", "thickness"], "brows", errors);
  enumValue(value.shape, BROW_SHAPES, "brows.shape", errors);
  hex(value.color_hex, "brows.color_hex", errors);
  numberRange(value.thickness, 0, 1, "brows.thickness", errors);
}

function validateNose(value, errors) {
  object(value, "nose", errors);
  if (!value) return;
  exactKeys(value, ["style", "width", "length"], "nose", errors);
  enumValue(value.style, NOSE_STYLES, "nose.style", errors);
  numberRange(value.width, 0, 1, "nose.width", errors);
  numberRange(value.length, 0, 1, "nose.length", errors);
}

function validateMouth(value, errors) {
  object(value, "mouth", errors);
  if (!value) return;
  exactKeys(value, ["style", "width", "fullness"], "mouth", errors);
  enumValue(value.style, MOUTH_STYLES, "mouth.style", errors);
  numberRange(value.width, 0, 1, "mouth.width", errors);
  numberRange(value.fullness, 0, 1, "mouth.fullness", errors);
}

function validateHair(value, errors) {
  object(value, "hair", errors);
  if (!value) return;
  exactKeys(value, ["style", "color_hex", "facial_hair"], "hair", errors, ["facial_hair"]);
  enumValue(value.style, HAIR_STYLES, "hair.style", errors);
  hex(value.color_hex, "hair.color_hex", errors);
  if (value.facial_hair !== undefined) {
    enumValue(value.facial_hair, FACIAL_HAIR, "hair.facial_hair", errors);
  }
}

function validateAccessories(value, errors) {
  if (!Array.isArray(value)) {
    errors.push("accessories must be an array");
    return;
  }

  value.forEach((accessory, index) => {
    object(accessory, `accessories[${index}]`, errors);
    if (!accessory) return;
    exactKeys(accessory, ["type", "style", "color_hex"], `accessories[${index}]`, errors, ["color_hex"]);
    enumValue(accessory.type, ACCESSORY_TYPES, `accessories[${index}].type`, errors);
    nonEmptyString(accessory.style, `accessories[${index}].style`, errors);
    if (accessory.color_hex !== undefined) {
      hex(accessory.color_hex, `accessories[${index}].color_hex`, errors);
    }
  });
}

function validateMaterials(value, errors) {
  object(value, "materials", errors);
  if (!value) return;
  exactKeys(value, ["skin_texture_url", "hair_texture_url", "extra_texture_urls"], "materials", errors);
  uri(value.skin_texture_url, "materials.skin_texture_url", errors);
  uri(value.hair_texture_url, "materials.hair_texture_url", errors);
  if (!Array.isArray(value.extra_texture_urls)) {
    errors.push("materials.extra_texture_urls must be an array");
  } else {
    value.extra_texture_urls.forEach((url, index) => uri(url, `materials.extra_texture_urls[${index}]`, errors));
  }
}

function object(value, path, errors) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    errors.push(`${path} must be an object`);
  }
}

function exactKeys(value, allowedKeys, path, errors, optionalKeys = []) {
  const required = new Set(allowedKeys.filter((key) => !optionalKeys.includes(key)));
  for (const key of required) {
    if (!(key in value)) {
      errors.push(`${path}.${key} is required`);
    }
  }
  for (const key of Object.keys(value)) {
    if (!allowedKeys.includes(key)) {
      errors.push(`${path}.${key} is not allowed`);
    }
  }
}

function equals(value, expected, path, errors) {
  if (value !== expected) {
    errors.push(`${path} must be ${expected}`);
  }
}

function nonEmptyString(value, path, errors) {
  if (typeof value !== "string" || value.length === 0) {
    errors.push(`${path} must be a non-empty string`);
  }
}

function optionalString(value, path, errors) {
  if (value !== undefined && typeof value !== "string") {
    errors.push(`${path} must be a string`);
  }
}

function numberRange(value, minimum, maximum, path, errors) {
  if (typeof value !== "number" || Number.isNaN(value) || value < minimum || value > maximum) {
    errors.push(`${path} must be a number from ${minimum} to ${maximum}`);
  }
}

function enumValue(value, allowed, path, errors) {
  if (!allowed.has(value)) {
    errors.push(`${path} is invalid`);
  }
}

function hex(value, path, errors) {
  if (typeof value !== "string" || !HEX_COLOR.test(value)) {
    errors.push(`${path} must be a #RRGGBB color`);
  }
}

function uri(value, path, errors) {
  if (typeof value !== "string") {
    errors.push(`${path} must be a URI`);
    return;
  }

  try {
    new URL(value);
  } catch {
    errors.push(`${path} must be a valid URI`);
  }
}
