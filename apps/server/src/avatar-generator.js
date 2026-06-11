import { makeFixtureRecipe } from "./avatar-recipe-fixture.js";
import { validateAvatarRecipe } from "./avatar-recipe-validator.js";

const DEFAULT_PROVIDER_TIMEOUT_MS = 25_000;
const DEFAULT_PROVIDER_MAX_ATTEMPTS = 2;

export async function generateAvatarRecipe({ job, provider = process.env, fetcher = fetch } = {}) {
  const startedAt = Date.now();

  if (provider.OPENAI_COMPATIBLE_BASE_URL && provider.OPENAI_COMPATIBLE_API_KEY && provider.OPENAI_COMPATIBLE_MODEL) {
    try {
      const recipe = await generateWithRetries({ job, provider, fetcher });
      const validation = validateAvatarRecipe(recipe);
      if (!validation.valid) {
        throw new AvatarGenerationError(`Provider returned invalid AvatarRecipe: ${validation.errors.join("; ")}`);
      }
      return {
        recipe,
        metadata: {
          provider: provider.OPENAI_COMPATIBLE_MODEL,
          generationLatencyMs: Date.now() - startedAt
        }
      };
    } catch (error) {
      const fallback = makeLocalRecipe(job);
      return {
        recipe: fallback,
        metadata: {
          provider: "local-fixture-fallback",
          attemptedProvider: provider.OPENAI_COMPATIBLE_MODEL,
          fallbackReason: error.message,
          generationLatencyMs: Date.now() - startedAt
        }
      };
    }
  }

  const recipe = makeLocalRecipe(job);
  return {
    recipe,
    metadata: {
      provider: "local-fixture",
      generationLatencyMs: Date.now() - startedAt
    }
  };
}

async function generateWithRetries({ job, provider, fetcher = fetch }) {
  const maxAttempts = positiveInteger(provider.OPENAI_COMPATIBLE_MAX_ATTEMPTS, DEFAULT_PROVIDER_MAX_ATTEMPTS);
  let lastError;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await generateWithOpenAICompatibleProvider({ job, provider, fetcher });
    } catch (error) {
      lastError = toAvatarGenerationError(error);
      if (!lastError.retryable || attempt === maxAttempts) {
        throw lastError;
      }
    }
  }

  throw lastError;
}

async function generateWithOpenAICompatibleProvider({ job, provider, fetcher }) {
  const timeoutMs = positiveInteger(provider.OPENAI_COMPATIBLE_TIMEOUT_MS, DEFAULT_PROVIDER_TIMEOUT_MS);
  const response = await fetchWithTimeout(providerChatCompletionsURL(provider.OPENAI_COMPATIBLE_BASE_URL), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${provider.OPENAI_COMPATIBLE_API_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: provider.OPENAI_COMPATIBLE_MODEL,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: "Return only a JSON AvatarRecipe matching the Snap Motion schema."
        },
        {
          role: "user",
          content: [
            "Generate an AvatarRecipe from this capture manifest.",
            JSON.stringify(job.manifest)
          ].join("\\n")
        }
      ]
    })
  }, { timeoutMs, fetcher });

  if (!response.ok) {
    throw new AvatarGenerationError(`Provider returned HTTP ${response.status}`, {
      retryable: response.status === 408 || response.status === 429 || response.status >= 500
    });
  }

  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string") {
    throw new AvatarGenerationError("Provider response did not include JSON content.");
  }

  return JSON.parse(content);
}

async function fetchWithTimeout(url, options, { timeoutMs, fetcher }) {
  const controller = new AbortController();
  const timeout = setTimeout(() => {
    controller.abort(new Error(`Provider request timed out after ${timeoutMs}ms`));
  }, timeoutMs);

  try {
    return await fetcher(url, { ...options, signal: controller.signal });
  } catch (error) {
    if (controller.signal.aborted) {
      throw new AvatarGenerationError(`Provider request timed out after ${timeoutMs}ms`, { cause: error, retryable: true });
    }

    throw new AvatarGenerationError(`Provider request failed: ${error.message}`, { cause: error, retryable: true });
  } finally {
    clearTimeout(timeout);
  }
}

function makeLocalRecipe(job) {
  const recipe = makeFixtureRecipe({
    avatarID: `avatar_${job.id.replace(/^job_/, "")}`,
    displayName: "Local Snap Friend"
  });
  const validation = validateAvatarRecipe(recipe);
  if (!validation.valid) {
    throw new AvatarGenerationError(`Local AvatarRecipe fixture is invalid: ${validation.errors.join("; ")}`);
  }
  return recipe;
}

function providerChatCompletionsURL(baseURL) {
  const url = new URL(baseURL);
  url.pathname = `${url.pathname.replace(/\/$/, "")}/chat/completions`;
  url.search = "";
  url.hash = "";
  return url;
}

function positiveInteger(value, fallback) {
  const number = Number(value);
  if (!Number.isInteger(number) || number <= 0) {
    return fallback;
  }
  return number;
}

function toAvatarGenerationError(error) {
  if (error instanceof AvatarGenerationError) {
    return error;
  }

  return new AvatarGenerationError(error.message ?? "Provider request failed.", { cause: error, retryable: true });
}

export class AvatarGenerationError extends Error {
  constructor(message, { cause, retryable = false } = {}) {
    super(message, { cause });
    this.name = "AvatarGenerationError";
    this.retryable = retryable;
  }
}
