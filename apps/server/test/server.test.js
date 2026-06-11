import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { createSnapMotionServer } from "../src/server.js";
import { JobStore } from "../src/job-store.js";
import { makeFixtureRecipe } from "../src/avatar-recipe-fixture.js";

test("job upload completion generates an avatar and deletes raw uploads", async () => {
  const rootDirectory = await mkdtemp(join(tmpdir(), "snap-motion-test-"));
  const store = new JobStore({ rootDirectory });
  const server = createSnapMotionServer({
    store,
    generator: async ({ job }) => ({
      recipe: makeFixtureRecipe({ avatarID: `avatar_${job.id}` }),
      metadata: { provider: "test-fixture", generationLatencyMs: 12 }
    })
  });
  await new Promise((resolve) => server.listen(0, resolve));
  const baseURL = `http://127.0.0.1:${server.address().port}`;

  try {
    const createResponse = await fetch(`${baseURL}/v1/avatar-jobs`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: "device-test",
        client: { platform: "ios", app_version: "1.0.0", os_version: "17.0" },
        manifest: {
          schema_version: 1,
          created_at: new Date().toISOString(),
          device: { model: "iPhone", os_version: "17.0", app_version: "1.0.0" },
          capture_slots: [
            { slot: "neutralFront", local_url: "file:///neutral.jpg", quality: {}, pose: {}, captured_at: new Date().toISOString() }
          ]
        }
      })
    });
    assert.equal(createResponse.status, 201);
    const creation = await createResponse.json();
    assert.equal(creation.status, "waiting_for_upload");

    assert.match(creation.upload_urls[0].url, /^http:\/\//);

    const uploadResponse = await fetch(creation.upload_urls[0].url, {
      method: "PUT",
      headers: { "Content-Type": "image/jpeg" },
      body: Buffer.from("jpeg")
    });
    assert.equal(uploadResponse.status, 204);

    const completeResponse = await fetch(`${baseURL}/v1/avatar-jobs/${creation.job_id}/uploads/complete`, { method: "POST" });
    assert.equal(completeResponse.status, 200);
    const processingJob = await completeResponse.json();
    assert.equal(processingJob.status, "processing");

    const completedJob = await waitForSucceededJob(baseURL, creation.job_id);

    const avatarResponse = await fetch(`${baseURL}/v1/avatars/${completedJob.avatar_id}`);
    assert.equal(avatarResponse.status, 200);
    const avatar = await avatarResponse.json();
    assert.equal(avatar.avatar_id, completedJob.avatar_id);

    const storedJob = store.getJob(creation.job_id);
    assert.equal(storedJob.uploadSlots[0].uploaded, true);
    assert.equal(storedJob.provider, "test-fixture");
    assert.equal(storedJob.generationLatencyMs, 12);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test("upload completion returns before a slow generator finishes", async () => {
  const rootDirectory = await mkdtemp(join(tmpdir(), "snap-motion-test-"));
  const store = new JobStore({ rootDirectory });
  let resolveGenerator;
  const generatorStarted = new Promise((resolve) => {
    resolveGenerator = resolve;
  });
  const server = createSnapMotionServer({
    store,
    generator: async ({ job }) => {
      await generatorStarted;
      return {
        recipe: makeFixtureRecipe({ avatarID: `avatar_${job.id}` }),
        metadata: { provider: "slow-test-fixture", generationLatencyMs: 1000 }
      };
    }
  });
  await new Promise((resolve) => server.listen(0, resolve));
  const baseURL = `http://127.0.0.1:${server.address().port}`;

  try {
    const creation = await createUploadedJob(baseURL);
    const completeResponse = await fetch(`${baseURL}/v1/avatar-jobs/${creation.job_id}/uploads/complete`, { method: "POST" });
    assert.equal(completeResponse.status, 200);
    const processingJob = await completeResponse.json();
    assert.equal(processingJob.status, "processing");
    assert.equal(processingJob.avatar_id, null);

    resolveGenerator();
    const completedJob = await waitForSucceededJob(baseURL, creation.job_id);
    assert.equal(completedJob.status, "succeeded");
    assert.ok(completedJob.avatar_id);
  } finally {
    resolveGenerator?.();
    await new Promise((resolve) => server.close(resolve));
  }
});

test("repeated upload completion does not start duplicate generation", async () => {
  const rootDirectory = await mkdtemp(join(tmpdir(), "snap-motion-test-"));
  const store = new JobStore({ rootDirectory });
  let generateCount = 0;
  let resolveGenerator;
  const generatorStarted = new Promise((resolve) => {
    resolveGenerator = resolve;
  });
  const server = createSnapMotionServer({
    store,
    generator: async ({ job }) => {
      generateCount += 1;
      await generatorStarted;
      return {
        recipe: makeFixtureRecipe({ avatarID: `avatar_${job.id}` }),
        metadata: { provider: "idempotent-test-fixture", generationLatencyMs: 1000 }
      };
    }
  });
  await new Promise((resolve) => server.listen(0, resolve));
  const baseURL = `http://127.0.0.1:${server.address().port}`;

  try {
    const creation = await createUploadedJob(baseURL);
    const firstComplete = await fetch(`${baseURL}/v1/avatar-jobs/${creation.job_id}/uploads/complete`, { method: "POST" });
    const secondComplete = await fetch(`${baseURL}/v1/avatar-jobs/${creation.job_id}/uploads/complete`, { method: "POST" });
    assert.equal(firstComplete.status, 200);
    assert.equal(secondComplete.status, 200);
    assert.equal(generateCount, 1);

    resolveGenerator();
    await waitForSucceededJob(baseURL, creation.job_id);
    const thirdComplete = await fetch(`${baseURL}/v1/avatar-jobs/${creation.job_id}/uploads/complete`, { method: "POST" });
    const completedJob = await thirdComplete.json();
    assert.equal(completedJob.status, "succeeded");
    assert.equal(generateCount, 1);
  } finally {
    resolveGenerator?.();
    await new Promise((resolve) => server.close(resolve));
  }
});

test("upload endpoint rejects non-JPEG content", async () => {
  const rootDirectory = await mkdtemp(join(tmpdir(), "snap-motion-test-"));
  const store = new JobStore({ rootDirectory });
  const server = createSnapMotionServer({ store });
  await new Promise((resolve) => server.listen(0, resolve));
  const baseURL = `http://127.0.0.1:${server.address().port}`;

  try {
    const createResponse = await fetch(`${baseURL}/v1/avatar-jobs`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        device_id: "device-test",
        manifest: {
          schema_version: 1,
          created_at: new Date().toISOString(),
          device: { model: "iPhone", os_version: "17.0", app_version: "1.0.0" },
          capture_slots: [
            { slot: "neutralFront", local_url: "file:///neutral.jpg", quality: {}, pose: {}, captured_at: new Date().toISOString() }
          ]
        }
      })
    });
    const creation = await createResponse.json();

    const uploadResponse = await fetch(creation.upload_urls[0].url, {
      method: "PUT",
      headers: { "Content-Type": "application/octet-stream" },
      body: Buffer.from("not-jpeg")
    });

    assert.equal(uploadResponse.status, 415);
    assert.equal(store.getJob(creation.job_id).uploadSlots[0].uploaded, false);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

async function createUploadedJob(baseURL) {
  const createResponse = await fetch(`${baseURL}/v1/avatar-jobs`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      device_id: "device-test",
      client: { platform: "ios", app_version: "1.0.0", os_version: "17.0" },
      manifest: {
        schema_version: 1,
        created_at: new Date().toISOString(),
        device: { model: "iPhone", os_version: "17.0", app_version: "1.0.0" },
        capture_slots: [
          { slot: "neutralFront", local_url: "file:///neutral.jpg", quality: {}, pose: {}, captured_at: new Date().toISOString() }
        ]
      }
    })
  });
  assert.equal(createResponse.status, 201);
  const creation = await createResponse.json();

  const uploadResponse = await fetch(creation.upload_urls[0].url, {
    method: "PUT",
    headers: { "Content-Type": "image/jpeg" },
    body: Buffer.from("jpeg")
  });
  assert.equal(uploadResponse.status, 204);
  return creation;
}

async function waitForSucceededJob(baseURL, jobID) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const jobResponse = await fetch(`${baseURL}/v1/avatar-jobs/${jobID}`);
    assert.equal(jobResponse.status, 200);
    const job = await jobResponse.json();
    if (job.status === "succeeded") {
      assert.ok(job.avatar_id);
      return job;
    }
    await new Promise((resolve) => setTimeout(resolve, 10));
  }

  assert.fail("Job did not succeed.");
}
