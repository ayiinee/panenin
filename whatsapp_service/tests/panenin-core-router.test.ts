import { describe, expect, it, vi } from "vitest";
import {
  PaneninCoreApiError,
  type PaneninCoreClientLike,
} from "../src/panenin-core/client.js";
import { PaneninCoreRouter } from "../src/panenin-core/router.js";

function setup() {
  const delegate = { route: vi.fn().mockResolvedValue("jawaban lama") };
  const coreClient: PaneninCoreClientLike = {
    resolveIdentity: vi.fn().mockResolvedValue({ linked: false }),
    linkIdentity: vi.fn().mockResolvedValue({
      linked: true,
      organizationName: "Tani Makmur",
    }),
    getContext: vi.fn().mockResolvedValue({
      identity: {
        organizationId: "org-1",
        organizationType: "FARM",
        organizationName: "Tani Makmur",
      },
      inventorySummary: { batchCount: 2, availableQuantity: "125.5" },
      listingSummary: { total: 3, published: 1 },
      demandSummary: { total: 4, open: 2 },
      orderSummary: { total: 5, active: 3 },
      pendingActions: [],
    }),
  };
  const router = new PaneninCoreRouter({
    delegate,
    coreClient,
    subjectPepper: "subject-pepper-yang-panjang-aman",
  });
  return { router, delegate, coreClient };
}

describe("PaneninCoreRouter", () => {
  it("MENU menambahkan command akun hanya saat wrapper Core aktif", async () => {
    const { router } = setup();
    const result = await router.route({ sender: "628123", text: "MENU" });
    expect(result).toContain("jawaban lama");
    expect(result).toContain("HUBUNGKAN <kode>");
    expect(result).toContain("RINGKASAN");
  });

  it("HUBUNGKAN menukar kode tanpa meneruskan nomor mentah", async () => {
    const { router, delegate, coreClient } = setup();
    const result = await router.route({
      sender: "628123456789",
      text: "hubungkan abc123",
    });

    expect(result).toContain("berhasil terhubung");
    expect(coreClient.linkIdentity).toHaveBeenCalledWith(
      expect.stringMatching(/^wa:v1:[0-9a-f]{64}$/),
      "ABC123",
    );
    expect(coreClient.linkIdentity).not.toHaveBeenCalledWith(
      expect.stringContaining("628123456789"),
      expect.anything(),
    );
    expect(delegate.route).not.toHaveBeenCalled();
  });

  it("format HUBUNGKAN yang salah ditolak sebelum request Core", async () => {
    const { router, coreClient } = setup();
    await expect(router.route({
      sender: "628123",
      text: "HUBUNGKAN 12",
    })).resolves.toContain("Format kode");
    expect(coreClient.linkIdentity).not.toHaveBeenCalled();
  });

  it("STATUS AKUN memberi instruksi untuk subject yang belum tertaut", async () => {
    const { router } = setup();
    await expect(router.route({
      sender: "628123",
      text: "STATUS AKUN",
    })).resolves.toContain("belum terhubung");
  });

  it("RINGKASAN membaca context Core tanpa mutation", async () => {
    const { router, coreClient } = setup();
    const result = await router.route({
      sender: "628123",
      text: "RINGKASAN",
    });
    expect(result).toContain("2 batch stok");
    expect(result).toContain("3 pesanan aktif");
    expect(coreClient.getContext).toHaveBeenCalledOnce();
  });

  it("kode kedaluwarsa menghasilkan pesan aman dan actionable", async () => {
    const { router, coreClient } = setup();
    vi.mocked(coreClient.linkIdentity).mockRejectedValue(
      new PaneninCoreApiError("LINK_CODE_EXPIRED", 409),
    );
    await expect(router.route({
      sender: "628123",
      text: "HUBUNGKAN ABC123",
    })).resolves.toContain("kedaluwarsa");
  });

  it("pesan lain tetap melewati router percakapan lama", async () => {
    const { router, delegate } = setup();
    await expect(router.route({
      sender: "628123",
      text: "Bagaimana cara packing?",
    })).resolves.toBe("jawaban lama");
    expect(delegate.route).toHaveBeenCalledOnce();
  });
});
