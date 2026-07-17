import { describe, expect, it } from "vitest";
import { parsePaneninCoreEnv } from "../src/config/env.js";

describe("Panenin Core environment", () => {
  it("tetap opsional agar mode lab lama dapat berjalan", () => {
    expect(parsePaneninCoreEnv({})).toMatchObject({
      PANENIN_CORE_ENABLED: false,
      PANENIN_CORE_API_URL: "http://127.0.0.1:8000",
    });
  });

  it("mewajibkan token dan pepper kuat ketika integrasi diaktifkan", () => {
    expect(() => parsePaneninCoreEnv({
      PANENIN_CORE_ENABLED: "true",
      PANENIN_AI_SERVICE_TOKEN: "pendek",
      WHATSAPP_SUBJECT_PEPPER: "pendek",
    })).toThrow("PANENIN_AI_SERVICE_TOKEN");
  });

  it("menerima konfigurasi integrasi lengkap", () => {
    expect(parsePaneninCoreEnv({
      PANENIN_CORE_ENABLED: "true",
      PANENIN_CORE_API_URL: "http://127.0.0.1:8001",
      PANENIN_AI_SERVICE_TOKEN: "service-token-at-least-24-chars",
      WHATSAPP_SUBJECT_PEPPER: "subject-pepper-at-least-24-chars",
    })).toMatchObject({
      PANENIN_CORE_ENABLED: true,
      PANENIN_CORE_API_URL: "http://127.0.0.1:8001",
    });
  });
});
