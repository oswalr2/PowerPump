// PowerPump — Food Scan Proxy
// Holds the Anthropic API key server-side and enforces the free quota:
// WEEKLY_LIMIT scans per user per ISO week, plus DAILY_IP_LIMIT scans per
// client IP per UTC day (so rotating user IDs doesn't give unlimited scans).
// State lives in Workers KV (binding: SCANS).
//
// This is best-effort abuse protection only: user_id is client-generated and
// KV is eventually consistent. Real protection needs App Attest / DeviceCheck
// and Cloudflare rate-limiting rules in front of this Worker.

const MODEL = "claude-haiku-4-5-20251001";
const WEEKLY_LIMIT = 1;
const DAILY_IP_LIMIT = 5;
const MAX_IMAGE_BASE64_CHARS = 1_500_000; // ~1MB of JPEG, well above the app's 512px output

const USER_TTL = 60 * 60 * 24 * 8; // a bit over one ISO week
const IP_TTL = 60 * 60 * 24 * 2; // a bit over one UTC day

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const BASE64_RE = /^[A-Za-z0-9+/]+={0,2}$/;

// The app's 5 languages. Only these fixed strings ever reach the prompt.
const LANGUAGES = new Map([
  ["english", "English"],
  ["en", "English"],
  ["spanish", "Spanish"],
  ["es", "Spanish"],
  ["french", "French"],
  ["fr", "French"],
  ["italian", "Italian"],
  ["it", "Italian"],
  ["portuguese", "Brazilian Portuguese"],
  ["brazilian portuguese", "Brazilian Portuguese"],
  ["pt", "Brazilian Portuguese"],
  ["pt-br", "Brazilian Portuguese"],
]);

function resolveLanguage(value) {
  if (typeof value !== "string") return "English";
  return LANGUAGES.get(value.trim().toLowerCase()) ?? "English";
}

// Identify the image format from its first bytes instead of trusting the client.
function sniffMediaType(base64) {
  if (base64.startsWith("/9j/")) return "image/jpeg"; // FF D8 FF
  if (base64.startsWith("iVBORw0KGgo")) return "image/png"; // 89 50 4E 47 0D 0A 1A 0A
  return null;
}

function isoWeekKey(date) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

function dayKey(date) {
  return date.toISOString().slice(0, 10);
}

// IPv6 clients usually control a whole /64, so count per /64 instead of per address.
function ipBucket(ip) {
  if (!ip.includes(":")) return ip;
  let parts;
  if (ip.includes("::")) {
    const [head, tail] = ip.split("::");
    const h = head ? head.split(":") : [];
    const t = tail ? tail.split(":") : [];
    parts = [...h, ...Array(Math.max(0, 8 - h.length - t.length)).fill("0"), ...t];
  } else {
    parts = ip.split(":");
  }
  return `${parts.slice(0, 4).join(":").toLowerCase()}::/64`;
}

// Reserve one unit of quota before doing the expensive work. KV has no atomic
// increment, so this narrows (but cannot fully close) the read-then-write race.
async function reserve(env, key, limit, ttl) {
  const used = parseInt((await env.SCANS.get(key)) || "0", 10);
  if (used >= limit) return false;
  await env.SCANS.put(key, String(used + 1), { expirationTtl: ttl });
  return true;
}

async function release(env, key, ttl) {
  const used = parseInt((await env.SCANS.get(key)) || "0", 10);
  if (used > 0) await env.SCANS.put(key, String(used - 1), { expirationTtl: ttl });
}

function buildPrompt(language) {
  return `Analyze the food in this image. For EACH food item you can identify, estimate the weight and nutrition.
Use food names in ${language}.
Respond ONLY with valid JSON — no explanation, no markdown, no code block. Use this exact format:
{"items":[{"name":"Food Name","grams":150,"calories":200,"protein":15.0,"carbs":20.0,"fat":8.0}],"totalCalories":200,"totalProtein":15.0,"totalCarbs":20.0,"totalFat":8.0}
If you cannot identify any food, respond: {"items":[],"totalCalories":0,"totalProtein":0,"totalCarbs":0,"totalFat":0}`;
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/scan") {
      return new Response("Not found", { status: 404 });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: "bad_request" }, 400);
    }

    const userID = typeof body.user_id === "string" ? body.user_id : "";
    const image = typeof body.image === "string" ? body.image : "";
    const language = resolveLanguage(body.language);

    if (!UUID_RE.test(userID) || !image) return json({ error: "bad_request" }, 400);
    if (image.length > MAX_IMAGE_BASE64_CHARS) return json({ error: "image_too_large" }, 413);
    const mediaType = sniffMediaType(image);
    if (!mediaType || !BASE64_RE.test(image)) return json({ error: "unsupported_image" }, 415);

    const now = new Date();
    const ip = request.headers.get("CF-Connecting-IP") || "unknown";
    const ipKey = `ip:${ipBucket(ip)}:${dayKey(now)}`;
    const userKey = `scan:${userID.toLowerCase()}:${isoWeekKey(now)}`;

    if (!(await reserve(env, ipKey, DAILY_IP_LIMIT, IP_TTL))) {
      return json({ error: "daily_ip_limit_reached" }, 429);
    }
    if (!(await reserve(env, userKey, WEEKLY_LIMIT, USER_TTL))) {
      await release(env, ipKey, IP_TTL);
      return json({ error: "weekly_limit_reached" }, 429);
    }

    // Give the reserved quota back if the scan didn't happen.
    const rollback = () => Promise.all([release(env, ipKey, IP_TTL), release(env, userKey, USER_TTL)]);

    let anthropicResp;
    try {
      anthropicResp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": env.ANTHROPIC_API_KEY,
          "anthropic-version": "2023-06-01",
          "content-type": "application/json",
        },
        body: JSON.stringify({
          model: MODEL,
          max_tokens: 1024,
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "image",
                  source: { type: "base64", media_type: mediaType, data: image },
                },
                { type: "text", text: buildPrompt(language) },
              ],
            },
          ],
        }),
      });
    } catch {
      await rollback();
      return json({ error: "upstream_error" }, 502);
    }

    if (!anthropicResp.ok) {
      await rollback();
      return json({ error: "upstream_error", status: anthropicResp.status }, 502);
    }

    return new Response(anthropicResp.body, {
      headers: { "content-type": "application/json" },
    });
  },
};
