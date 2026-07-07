// PowerPump — Food Scan Proxy
// Holds the Anthropic API key server-side and enforces the free quota:
// WEEKLY_LIMIT scans per user per ISO week. State lives in Workers KV (binding: SCANS).

const MODEL = "claude-haiku-4-5-20251001";
const WEEKLY_LIMIT = 1;
const MAX_IMAGE_BASE64_CHARS = 1_500_000; // ~1MB of JPEG, well above the app's 512px output

function isoWeekKey(date) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
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

    const userID = typeof body.user_id === "string" ? body.user_id.slice(0, 64) : "";
    const image = typeof body.image === "string" ? body.image : "";
    const language = typeof body.language === "string" ? body.language.slice(0, 40) : "English";

    if (!userID || !image) return json({ error: "bad_request" }, 400);
    if (image.length > MAX_IMAGE_BASE64_CHARS) return json({ error: "image_too_large" }, 413);

    const kvKey = `scan:${userID}:${isoWeekKey(new Date())}`;
    const used = parseInt((await env.SCANS.get(kvKey)) || "0", 10);
    if (used >= WEEKLY_LIMIT) {
      return json({ error: "weekly_limit_reached" }, 429);
    }

    const anthropicResp = await fetch("https://api.anthropic.com/v1/messages", {
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
                source: { type: "base64", media_type: "image/jpeg", data: image },
              },
              { type: "text", text: buildPrompt(language) },
            ],
          },
        ],
      }),
    });

    if (!anthropicResp.ok) {
      return json({ error: "upstream_error", status: anthropicResp.status }, 502);
    }

    // Count the scan only after a successful upstream call
    await env.SCANS.put(kvKey, String(used + 1), { expirationTtl: 60 * 60 * 24 * 8 });

    return new Response(anthropicResp.body, {
      headers: { "content-type": "application/json" },
    });
  },
};
