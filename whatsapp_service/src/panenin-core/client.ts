import { randomUUID } from "node:crypto";

export interface PaneninIdentity {
  linked: boolean;
  userId?: string;
  organizationId?: string;
  organizationType?: string;
  organizationName?: string;
}

export interface PaneninCoreContext {
  identity: {
    organizationId: string;
    organizationType: string;
    organizationName: string;
  };
  inventorySummary: {
    batchCount: number;
    availableQuantity: string;
  };
  listingSummary: {
    total: number;
    published: number;
  };
  demandSummary: {
    total: number;
    open: number;
  };
  orderSummary: {
    total: number;
    active: number;
  };
  pendingActions: Array<{
    actionId: string;
    intent: string;
    expiresAt: string;
  }>;
}

export interface PaneninCoreClientLike {
  resolveIdentity(channelSubject: string): Promise<PaneninIdentity>;
  linkIdentity(channelSubject: string, linkCode: string): Promise<PaneninIdentity>;
  getContext(channelSubject: string): Promise<PaneninCoreContext>;
}

export interface PaneninCoreClientOptions {
  baseUrl: string;
  serviceToken: string;
  timeoutMs?: number;
  fetchFn?: typeof fetch;
}

export class PaneninCoreApiError extends Error {
  public constructor(
    public readonly code: string,
    public readonly status: number,
  ) {
    super(`Panenin Core request failed: ${code}`);
    this.name = "PaneninCoreApiError";
  }
}

export class PaneninCoreClient implements PaneninCoreClientLike {
  private readonly baseUrl: string;
  private readonly timeoutMs: number;
  private readonly fetchFn: typeof fetch;

  public constructor(private readonly options: PaneninCoreClientOptions) {
    this.baseUrl = options.baseUrl.replace(/\/+$/, "");
    this.timeoutMs = options.timeoutMs ?? 8_000;
    this.fetchFn = options.fetchFn ?? fetch;
  }

  public async resolveIdentity(channelSubject: string): Promise<PaneninIdentity> {
    return this.request<PaneninIdentity>("/api/v1/internal/agent/identity/resolve", {
      method: "POST",
      body: {
        channel: "WHATSAPP",
        channelSubject,
      },
    });
  }

  public async linkIdentity(
    channelSubject: string,
    linkCode: string,
  ): Promise<PaneninIdentity> {
    return this.request<PaneninIdentity>("/api/v1/internal/agent/identity/link", {
      method: "POST",
      body: {
        channel: "WHATSAPP",
        channelSubject,
        linkCode,
      },
    });
  }

  public async getContext(channelSubject: string): Promise<PaneninCoreContext> {
    const query = new URLSearchParams({ channelSubject });
    return this.request<PaneninCoreContext>(
      `/api/v1/internal/agent/context?${query.toString()}`,
      { method: "GET" },
    );
  }

  private async request<T>(
    path: string,
    input: { method: "GET" | "POST"; body?: Record<string, unknown> },
  ): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await this.fetchFn(`${this.baseUrl}${path}`, {
        method: input.method,
        headers: {
          Authorization: `Bearer ${this.options.serviceToken}`,
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-Request-ID": randomUUID(),
        },
        ...(input.body ? { body: JSON.stringify(input.body) } : {}),
        signal: controller.signal,
      });
      const payload: unknown = await response.json().catch(() => null);
      if (!response.ok) {
        throw new PaneninCoreApiError(readErrorCode(payload), response.status);
      }
      if (!isSuccessEnvelope(payload)) {
        throw new PaneninCoreApiError("INVALID_CORE_RESPONSE", 502);
      }
      return payload.data as T;
    } catch (error) {
      if (error instanceof PaneninCoreApiError) throw error;
      if (error instanceof Error && error.name === "AbortError") {
        throw new PaneninCoreApiError("CORE_TIMEOUT", 504);
      }
      throw new PaneninCoreApiError("CORE_UNAVAILABLE", 503);
    } finally {
      clearTimeout(timer);
    }
  }
}

function isSuccessEnvelope(
  value: unknown,
): value is { data: unknown; error: null; requestId: string } {
  if (!isRecord(value)) return false;
  return "data" in value
    && value["error"] === null
    && typeof value["requestId"] === "string";
}

function readErrorCode(value: unknown): string {
  if (!isRecord(value) || !isRecord(value["error"])) return "CORE_REQUEST_FAILED";
  const code = value["error"]["code"];
  return typeof code === "string" && code ? code : "CORE_REQUEST_FAILED";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
