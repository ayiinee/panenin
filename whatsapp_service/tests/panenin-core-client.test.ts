import { describe, expect, it, vi } from "vitest";
import { createWhatsAppChannelSubject } from "../src/panenin-core/channel-subject.js";
import {
  PaneninCoreApiError,
  PaneninCoreClient,
} from "../src/panenin-core/client.js";

const subject = `wa:v1:${"a".repeat(64)}`;

describe("Panenin Core integration client", () => {
  it("membuat subject stabil tanpa membawa nomor mentah", () => {
    const pepper = "subject-pepper-yang-panjang-aman";
    const first = createWhatsAppChannelSubject("+62 812-3456@c.us", pepper);
    const second = createWhatsAppChannelSubject("628123456", pepper);

    expect(first).toBe(second);
    expect(first).toMatch(/^wa:v1:[0-9a-f]{64}$/);
    expect(first).not.toContain("628123456");
  });

  it("menukar link code memakai bearer service token dan camelCase contract", async () => {
    const fetchFn = vi.fn<typeof fetch>().mockResolvedValue(
      new Response(JSON.stringify({
        data: {
          linked: true,
          organizationId: "org-1",
          organizationName: "Tani Makmur",
        },
        error: null,
        requestId: "request-1",
      }), {
        status: 200,
        headers: { "content-type": "application/json" },
      }),
    );
    const client = new PaneninCoreClient({
      baseUrl: "http://127.0.0.1:8000/",
      serviceToken: "service-token",
      fetchFn,
    });

    await expect(client.linkIdentity(subject, "ABC123")).resolves.toMatchObject({
      linked: true,
      organizationName: "Tani Makmur",
    });
    expect(fetchFn).toHaveBeenCalledOnce();
    const [url, init] = fetchFn.mock.calls[0]!;
    expect(url).toBe("http://127.0.0.1:8000/api/v1/internal/agent/identity/link");
    expect(init?.headers).toMatchObject({
      Authorization: "Bearer service-token",
      "Content-Type": "application/json",
    });
    expect(JSON.parse(String(init?.body))).toEqual({
      channel: "WHATSAPP",
      channelSubject: subject,
      linkCode: "ABC123",
    });
  });

  it("menjaga error backend menjadi code aman tanpa membawa pesan respons", async () => {
    const fetchFn = vi.fn<typeof fetch>().mockResolvedValue(
      new Response(JSON.stringify({
        data: null,
        error: {
          code: "INVALID_LINK_CODE",
          message: "secret-detail-yang-tidak-boleh-diteruskan",
        },
        requestId: "request-2",
      }), {
        status: 409,
        headers: { "content-type": "application/json" },
      }),
    );
    const client = new PaneninCoreClient({
      baseUrl: "http://127.0.0.1:8000",
      serviceToken: "service-token",
      fetchFn,
    });

    const error = await client.linkIdentity(subject, "ABC123").catch(
      (caught: unknown) => caught,
    );
    expect(error).toBeInstanceOf(PaneninCoreApiError);
    expect(error).toMatchObject({ code: "INVALID_LINK_CODE", status: 409 });
    expect(String(error)).not.toContain("secret-detail");
  });

  it("menolak data sukses yang tidak sesuai kontrak", async () => {
    const fetchFn = vi.fn<typeof fetch>().mockResolvedValue(
      new Response(JSON.stringify({
        data: { linked: "yes" },
        error: null,
        requestId: "request-3",
      }), { status: 200 }),
    );
    const client = new PaneninCoreClient({
      baseUrl: "http://127.0.0.1:8000",
      serviceToken: "service-token",
      fetchFn,
    });

    await expect(client.resolveIdentity(subject)).rejects.toMatchObject({
      code: "INVALID_CORE_RESPONSE",
      status: 502,
    });
  });
});
