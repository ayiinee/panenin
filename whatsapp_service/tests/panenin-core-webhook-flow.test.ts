import { describe, expect, it, vi } from "vitest";
import { PaneninCoreRouter } from "../src/panenin-core/router.js";
import type { MessagingProvider } from "../src/types/messaging.js";
import { createWebhookHandler } from "../src/webhook/handler.js";
import { normalizeFonntePayload } from "../src/webhook/normalize-fonnte-payload.js";

describe("Fonnte to Panenin Core identity flow", () => {
  it("memproses HUBUNGKAN sekali lalu mengirim balasan sukses", async () => {
    const sendText = vi.fn().mockResolvedValue({ providerMessageId: "out-1" });
    const provider: MessagingProvider = {
      parseWebhook: normalizeFonntePayload,
      sendText,
    };
    const store = {
      claimIncoming: vi.fn().mockResolvedValue(true),
      markIncomingStatus: vi.fn().mockResolvedValue(undefined),
      resetSession: vi.fn().mockResolvedValue(undefined),
    };
    const linkIdentity = vi.fn().mockResolvedValue({
      linked: true,
      organizationName: "Tani Makmur",
    });
    const router = new PaneninCoreRouter({
      delegate: { route: vi.fn().mockResolvedValue("fallback") },
      coreClient: {
        linkIdentity,
        resolveIdentity: vi.fn(),
        getContext: vi.fn(),
      },
      subjectPepper: "subject-pepper-yang-panjang-aman",
    });
    const scheduled: Array<() => Promise<void>> = [];
    const handler = createWebhookHandler({
      provider,
      store,
      router,
      webhookSecret: "webhook-secret",
      schedule: (task) => scheduled.push(task),
    });

    const response = await handler(new Request(
      "http://localhost/webhook/fonnte?token=webhook-secret",
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          id: "incoming-1",
          sender: "628123456789",
          message: "HUBUNGKAN ABC123",
        }),
      },
    ));
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: "ok", accepted: 1 });

    await scheduled[0]!();

    expect(linkIdentity).toHaveBeenCalledWith(
      expect.stringMatching(/^wa:v1:[0-9a-f]{64}$/),
      "ABC123",
    );
    expect(sendText).toHaveBeenCalledWith({
      to: "628123456789",
      text: expect.stringContaining("berhasil terhubung"),
    });
    expect(store.markIncomingStatus).toHaveBeenCalledWith(
      "incoming-1",
      "processed",
    );
  });
});
