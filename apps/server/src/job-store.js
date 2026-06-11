import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { randomUUID } from "node:crypto";

export class JobStore {
  constructor({ rootDirectory, now = () => new Date() }) {
    this.rootDirectory = rootDirectory;
    this.now = now;
    this.jobs = new Map();
    this.avatars = new Map();
  }

  async createJob({ deviceID, client, manifest }) {
    const id = `job_${randomUUID()}`;
    const uploadSlots = manifest.capture_slots.map((frame) => {
      const token = randomUUID();
      return {
        slot: frame.slot,
        token,
        expiresAt: new Date(this.now().getTime() + 15 * 60 * 1000).toISOString(),
        uploaded: false,
        path: join(this.rootDirectory, "uploads", id, `${frame.slot}.jpg`)
      };
    });

    const job = {
      id,
      status: "waiting_for_upload",
      deviceID,
      client,
      manifest,
      uploadSlots,
      avatarID: null,
      errorMessage: null,
      provider: null,
      generationLatencyMs: null,
      generationStartedAt: null,
      createdAt: this.now().toISOString(),
      updatedAt: this.now().toISOString()
    };
    this.jobs.set(id, job);
    return job;
  }

  getJob(jobID) {
    return this.jobs.get(jobID) ?? null;
  }

  getUploadSlot(jobID, slotName, token) {
    const job = this.getJob(jobID);
    if (!job) return null;
    return job.uploadSlots.find((slot) => slot.slot === slotName && slot.token === token) ?? null;
  }

  async saveUpload({ jobID, slotName, token, body }) {
    const slot = this.getUploadSlot(jobID, slotName, token);
    if (!slot) {
      return false;
    }
    if (new Date(slot.expiresAt).getTime() < this.now().getTime()) {
      return false;
    }

    await mkdir(join(this.rootDirectory, "uploads", jobID), { recursive: true });
    await writeFile(slot.path, body);
    slot.uploaded = true;
    const job = this.getJob(jobID);
    job.updatedAt = this.now().toISOString();
    return true;
  }

  markProcessing(jobID) {
    const job = this.getJob(jobID);
    if (!job) return null;
    if (job.status === "processing" || isTerminalStatus(job.status)) {
      return job;
    }
    if (!job.uploadSlots.every((slot) => slot.uploaded)) {
      job.status = "waiting_for_upload";
      job.errorMessage = "Not all upload slots have been uploaded.";
      job.updatedAt = this.now().toISOString();
      return job;
    }
    job.status = "processing";
    job.errorMessage = null;
    job.generationStartedAt = this.now().toISOString();
    job.updatedAt = this.now().toISOString();
    return job;
  }

  async markSucceeded(jobID, recipe, metadata = {}) {
    const job = this.getJob(jobID);
    if (!job) return null;
    job.status = "succeeded";
    job.avatarID = recipe.avatar_id;
    job.provider = metadata.provider ?? null;
    job.generationLatencyMs = metadata.generationLatencyMs ?? null;
    job.updatedAt = this.now().toISOString();
    this.avatars.set(recipe.avatar_id, recipe);
    await this.deleteRawUploads(jobID);
    return job;
  }

  async markFailed(jobID, message, metadata = {}) {
    const job = this.getJob(jobID);
    if (!job) return null;
    job.status = "failed";
    job.errorMessage = message;
    job.provider = metadata.provider ?? null;
    job.generationLatencyMs = metadata.generationLatencyMs ?? null;
    job.updatedAt = this.now().toISOString();
    await this.deleteRawUploads(jobID);
    return job;
  }

  async markExpired(jobID, message = "Job expired.") {
    const job = this.getJob(jobID);
    if (!job) return null;
    job.status = "expired";
    job.errorMessage = message;
    job.updatedAt = this.now().toISOString();
    await this.deleteRawUploads(jobID);
    return job;
  }

  getAvatar(avatarID) {
    return this.avatars.get(avatarID) ?? null;
  }

  async deleteRawUploads(jobID) {
    await rm(join(this.rootDirectory, "uploads", jobID), { recursive: true, force: true });
  }
}

function isTerminalStatus(status) {
  return status === "succeeded" || status === "failed" || status === "expired";
}

export async function readJSON(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  if (chunks.length === 0) {
    return null;
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

export async function readBuffer(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}
