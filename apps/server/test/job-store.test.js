import assert from "node:assert/strict";
import { mkdtemp, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { JobStore } from "../src/job-store.js";

test("markExpired records terminal state and deletes raw uploads", async () => {
  const rootDirectory = await mkdtemp(join(tmpdir(), "snap-motion-test-"));
  const store = new JobStore({ rootDirectory });
  const job = await store.createJob({
    deviceID: "device-test",
    client: {},
    manifest: {
      capture_slots: [{ slot: "neutralFront" }]
    }
  });

  const slot = job.uploadSlots[0];
  const saved = await store.saveUpload({
    jobID: job.id,
    slotName: slot.slot,
    token: slot.token,
    body: Buffer.from("jpeg")
  });
  assert.equal(saved, true);
  await stat(slot.path);

  const expired = await store.markExpired(job.id);

  assert.equal(expired.status, "expired");
  assert.equal(expired.errorMessage, "Job expired.");
  await assert.rejects(stat(slot.path), { code: "ENOENT" });
});
