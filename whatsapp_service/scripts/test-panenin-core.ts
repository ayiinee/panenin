import "dotenv/config";
import { parsePaneninCoreEnv } from "../src/config/env.js";
import { PaneninCoreClient } from "../src/panenin-core/client.js";

async function main(): Promise<void> {
  const env = parsePaneninCoreEnv();
  if (!env.PANENIN_CORE_ENABLED) {
    throw new Error("Set PANENIN_CORE_ENABLED=true sebelum smoke test");
  }
  const client = new PaneninCoreClient({
    baseUrl: env.PANENIN_CORE_API_URL,
    serviceToken: env.PANENIN_AI_SERVICE_TOKEN,
  });
  const identity = await client.resolveIdentity(`wa:v1:${"0".repeat(64)}`);
  if (typeof identity.linked !== "boolean") {
    throw new Error("Respons identity Panenin Core tidak valid");
  }
  console.log("CORE_IDENTITY_OK");
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : "Smoke test Panenin Core gagal");
  process.exitCode = 1;
});
