import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    if (ctx.model?.provider !== "openai-codex" || ctx.model.id !== "gpt-6.1-sol") return;
    if (!event.payload || typeof event.payload !== "object" || Array.isArray(event.payload)) return;
    return { ...event.payload, service_tier: "priority" };
  });
}
