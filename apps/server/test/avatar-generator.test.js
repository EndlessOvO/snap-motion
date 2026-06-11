import assert from "node:assert/strict";
import test from "node:test";
import { generateAvatarRecipe } from "../src/avatar-generator.js";

const provider = {
  OPENAI_COMPATIBLE_BASE_URL: "https://api.example.com/v1",
  OPENAI_COMPATIBLE_API_KEY: "test-key",
  OPENAI_COMPATIBLE_MODEL: "test-model",
  OPENAI_COMPATIBLE_TIMEOUT_MS: "10",
  OPENAI_COMPATIBLE_MAX_ATTEMPTS: "1"
};

const job = {
  id: "job_generator_test",
  manifest: {
    schema_version: 1,
    capture_slots: [{ slot: "neutralFront" }]
  }
};

test("OpenAI-compatible provider URL keeps the base API path", async () => {
  let requestedURL;
  const result = await generateAvatarRecipe({
    job,
    provider,
    fetcher: async (url) => {
      requestedURL = url;
      return {
        ok: true,
        async json() {
          return {
            choices: [
              {
                message: {
                  content: JSON.stringify({
                    schema_version: 1,
                    avatar_id: "avatar_provider",
                    display_name: "Provider Friend",
                    rig: { template_id: "cute_avatar_v1", morph_calibration: { blink_L: 1 } },
                    face: { shape: "round", roundness: 0.5, jaw_width: 0.5, cheek_fullness: 0.5 },
                    skin: { tone_hex: "#E9B98F", warmth: 0.5, roughness: 0.5 },
                    eyes: { shape: "almond", color_hex: "#4A2C1A", size: 0.5, spacing: 0.5 },
                    brows: { shape: "soft_arch", color_hex: "#2B1B12", thickness: 0.5 },
                    nose: { style: "soft", width: 0.5, length: 0.5 },
                    mouth: { style: "soft_smile", width: 0.5, fullness: 0.5 },
                    hair: { style: "wavy", color_hex: "#24170F", facial_hair: "none" },
                    accessories: [],
                    materials: {
                      skin_texture_url: "https://assets.snap-motion.local/skin-fixture.png",
                      hair_texture_url: "https://assets.snap-motion.local/hair-fixture.png",
                      extra_texture_urls: []
                    }
                  })
                }
              }
            ]
          };
        }
      };
    }
  });

  assert.equal(requestedURL.href, "https://api.example.com/v1/chat/completions");
  assert.equal(result.recipe.avatar_id, "avatar_provider");
  assert.equal(result.metadata.provider, "test-model");
});

test("provider timeout falls back to a local recipe instead of failing the job", async () => {
  const result = await generateAvatarRecipe({
    job,
    provider,
    fetcher: (_url, { signal }) => new Promise((resolve, reject) => {
      signal.addEventListener("abort", () => reject(signal.reason), { once: true });
    })
  });

  assert.equal(result.recipe.avatar_id, "avatar_generator_test");
  assert.equal(result.metadata.provider, "local-fixture-fallback");
  assert.equal(result.metadata.attemptedProvider, "test-model");
  assert.match(result.metadata.fallbackReason, /timed out/);
});
