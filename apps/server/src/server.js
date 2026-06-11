import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { generateAvatarRecipe } from "./avatar-generator.js";
import { JobStore, readBuffer, readJSON } from "./job-store.js";

export function createSnapMotionServer({
  store = new JobStore({ rootDirectory: join(tmpdir(), "snap-motion-server") }),
  generator = generateAvatarRecipe
} = {}) {
  return createServer(async (request, response) => {
    try {
      const url = new URL(request.url, "http://localhost");
      const route = matchRoute(request.method, url.pathname);

      if (!route) {
        sendJSON(response, 404, { error: "Not found." });
        return;
      }

      if (route.name === "createJob") {
        const body = await readJSON(request);
        const manifest = body?.manifest;
        if (!body?.device_id || !manifest?.capture_slots?.length) {
          sendJSON(response, 400, { error: "device_id and manifest.capture_slots are required." });
          return;
        }

        const job = await store.createJob({
          deviceID: body.device_id,
          client: body.client ?? {},
          manifest
        });
        sendJSON(response, 201, {
          job_id: job.id,
          status: job.status,
          upload_urls: job.uploadSlots.map((slot) => ({
            slot: slot.slot,
            url: absoluteURL(request, `/v1/avatar-jobs/${job.id}/uploads/${slot.slot}?token=${slot.token}`),
            method: "PUT",
            content_type: "image/jpeg"
          }))
        });
        return;
      }

      if (route.name === "upload") {
        const contentType = request.headers["content-type"]?.split(";")[0]?.trim().toLowerCase();
        if (contentType !== "image/jpeg") {
          sendJSON(response, 415, { error: "Only image/jpeg uploads are accepted." });
          return;
        }

        const body = await readBuffer(request);
        const saved = await store.saveUpload({
          jobID: route.params.jobID,
          slotName: route.params.slot,
          token: url.searchParams.get("token"),
          body
        });
        sendJSON(response, saved ? 204 : 404, saved ? null : { error: "Upload slot not found or expired." });
        return;
      }

      if (route.name === "completeUploads") {
        const existingJob = store.getJob(route.params.jobID);
        const generationAlreadyStarted = Boolean(existingJob?.generationStartedAt);
        const job = store.markProcessing(route.params.jobID);
        if (!job) {
          sendJSON(response, 404, { error: "Job not found." });
          return;
        }
        if (job.status !== "processing" || generationAlreadyStarted) {
          sendJob(response, job);
          return;
        }

        runGeneration({ job, store, generator });
        sendJob(response, job);
        return;
      }

      if (route.name === "getJob") {
        const job = store.getJob(route.params.jobID);
        if (!job) {
          sendJSON(response, 404, { error: "Job not found." });
          return;
        }
        sendJob(response, job);
        return;
      }

      if (route.name === "getAvatar") {
        const avatar = store.getAvatar(route.params.avatarID);
        if (!avatar) {
          sendJSON(response, 404, { error: "Avatar not found." });
          return;
        }
        sendJSON(response, 200, avatar);
      }
    } catch (error) {
      sendJSON(response, 500, { error: error.message });
    }
  });
}

function runGeneration({ job, store, generator }) {
  queueMicrotask(async () => {
    try {
      const generated = await generator({ job });
      const recipe = generated.recipe ?? generated;
      await store.markSucceeded(job.id, recipe, generated.metadata ?? {});
    } catch (error) {
      await store.markFailed(job.id, error.message);
    }
  });
}

function matchRoute(method, pathname) {
  if (method === "POST" && pathname === "/v1/avatar-jobs") {
    return { name: "createJob", params: {} };
  }

  let match = pathname.match(/^\/v1\/avatar-jobs\/([^/]+)\/uploads\/([^/]+)$/);
  if (method === "PUT" && match) {
    return { name: "upload", params: { jobID: match[1], slot: match[2] } };
  }

  match = pathname.match(/^\/v1\/avatar-jobs\/([^/]+)\/uploads\/complete$/);
  if (method === "POST" && match) {
    return { name: "completeUploads", params: { jobID: match[1] } };
  }

  match = pathname.match(/^\/v1\/avatar-jobs\/([^/]+)$/);
  if (method === "GET" && match) {
    return { name: "getJob", params: { jobID: match[1] } };
  }

  match = pathname.match(/^\/v1\/avatars\/([^/]+)$/);
  if (method === "GET" && match) {
    return { name: "getAvatar", params: { avatarID: match[1] } };
  }

  return null;
}

function sendJob(response, job) {
  sendJSON(response, 200, {
    job_id: job.id,
    status: job.status,
    avatar_id: job.avatarID,
    error_message: job.errorMessage
  });
}

function sendJSON(response, statusCode, body) {
  response.statusCode = statusCode;
  if (body === null || statusCode === 204) {
    response.end();
    return;
  }
  response.setHeader("Content-Type", "application/json");
  response.end(JSON.stringify(body));
}

function absoluteURL(request, path) {
  const protocol = request.headers["x-forwarded-proto"] ?? "http";
  const host = request.headers.host ?? "localhost";
  return `${protocol}://${host}${path}`;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const port = Number(process.env.PORT ?? 8787);
  createSnapMotionServer().listen(port, () => {
    console.log(`Snap Motion server listening on http://localhost:${port}`);
  });
}
