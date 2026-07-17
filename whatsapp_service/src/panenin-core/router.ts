import type { ConversationRouterLike } from "../webhook/handler.js";
import { createWhatsAppChannelSubject } from "./channel-subject.js";
import {
  PaneninCoreApiError,
  type PaneninCoreClientLike,
  type PaneninCoreContext,
} from "./client.js";

const LINK_COMMAND = /^hubungkan(?:\s+([a-z0-9]+))?\s*$/i;
const ACCOUNT_STATUS_COMMAND = /^(?:akun|status\s+akun)\s*$/i;
const SUMMARY_COMMAND = /^(?:ringkasan|ringkasan\s+akun)\s*$/i;
const MENU_COMMAND = /^(?:menu|help|bantuan)\s*$/i;

export interface PaneninCoreRouterOptions {
  delegate: ConversationRouterLike;
  coreClient: PaneninCoreClientLike;
  subjectPepper: string;
}

export class PaneninCoreRouter implements ConversationRouterLike {
  public constructor(private readonly options: PaneninCoreRouterOptions) {}

  public async route(input: { sender: string; text: string }): Promise<string> {
    const normalized = input.text.trim();
    if (MENU_COMMAND.test(normalized)) {
      const menu = await this.options.delegate.route(input);
      return [
        menu,
        "",
        "Akun Panenin:",
        "• HUBUNGKAN <kode> — tautkan WhatsApp dari aplikasi",
        "• STATUS AKUN — periksa status tautan",
        "• RINGKASAN — lihat ringkasan data akun",
      ].join("\n");
    }
    const linkMatch = LINK_COMMAND.exec(normalized);
    if (linkMatch) {
      const linkCode = linkMatch[1]?.toUpperCase() ?? "";
      if (!/^[A-Z0-9]{6,12}$/.test(linkCode)) {
        return "Format kode belum tepat. Kirim HUBUNGKAN diikuti kode dari aplikasi Panenin, misalnya HUBUNGKAN ABC123.";
      }
      return this.link(input.sender, linkCode);
    }
    if (ACCOUNT_STATUS_COMMAND.test(normalized)) {
      return this.accountStatus(input.sender);
    }
    if (SUMMARY_COMMAND.test(normalized)) {
      return this.summary(input.sender);
    }
    return this.options.delegate.route(input);
  }

  private async link(sender: string, linkCode: string): Promise<string> {
    try {
      const identity = await this.options.coreClient.linkIdentity(
        this.subject(sender),
        linkCode,
      );
      if (!identity.linked) return unavailableText();
      const organization = safeDisplayName(identity.organizationName);
      return organization
        ? `WhatsApp berhasil terhubung ke akun Panenin ${organization}. Ketik RINGKASAN untuk melihat data akunmu.`
        : "WhatsApp berhasil terhubung ke akun Panenin. Ketik RINGKASAN untuk melihat data akunmu.";
    } catch (error) {
      return linkErrorText(error);
    }
  }

  private async accountStatus(sender: string): Promise<string> {
    try {
      const identity = await this.options.coreClient.resolveIdentity(
        this.subject(sender),
      );
      if (!identity.linked) {
        return "WhatsApp ini belum terhubung. Buat kode dari menu Hubungkan WhatsApp di aplikasi Panenin, lalu kirim HUBUNGKAN <kode>.";
      }
      const organization = safeDisplayName(identity.organizationName);
      return organization
        ? `WhatsApp sudah terhubung ke akun Panenin ${organization}.`
        : "WhatsApp sudah terhubung ke akun Panenin.";
    } catch {
      return unavailableText();
    }
  }

  private async summary(sender: string): Promise<string> {
    try {
      const context = await this.options.coreClient.getContext(
        this.subject(sender),
      );
      return formatContext(context);
    } catch (error) {
      if (error instanceof PaneninCoreApiError && error.code === "FORBIDDEN") {
        return "WhatsApp ini belum terhubung. Hubungkan akunmu dari aplikasi Panenin terlebih dahulu.";
      }
      return unavailableText();
    }
  }

  private subject(sender: string): string {
    return createWhatsAppChannelSubject(sender, this.options.subjectPepper);
  }
}

function formatContext(context: PaneninCoreContext): string {
  const name = safeDisplayName(context.identity.organizationName) ?? "akunmu";
  return [
    `Ringkasan Panenin ${name}:`,
    `• ${context.inventorySummary.batchCount} batch stok (${context.inventorySummary.availableQuantity} tersedia)`,
    `• ${context.listingSummary.published} listing tayang dari ${context.listingSummary.total}`,
    `• ${context.demandSummary.open} permintaan terbuka`,
    `• ${context.orderSummary.active} pesanan aktif`,
    `• ${context.pendingActions.length} tindakan menunggu konfirmasi`,
  ].join("\n");
}

function linkErrorText(error: unknown): string {
  if (!(error instanceof PaneninCoreApiError)) return unavailableText();
  switch (error.code) {
    case "INVALID_LINK_CODE":
      return "Kode penghubung tidak valid. Buat kode baru dari aplikasi Panenin lalu coba lagi.";
    case "LINK_CODE_EXPIRED":
      return "Kode penghubung sudah kedaluwarsa. Buat kode baru dari aplikasi Panenin.";
    case "LINK_CODE_USED":
      return "Kode penghubung sudah pernah digunakan. Periksa STATUS AKUN atau buat kode baru.";
    case "LINK_CODE_LOCKED":
      return "Kode penghubung tidak dapat digunakan. Buat kode baru dari aplikasi Panenin.";
    case "CHANNEL_ALREADY_LINKED":
      return "WhatsApp ini sudah terhubung ke akun Panenin lain.";
    default:
      return unavailableText();
  }
}

function unavailableText(): string {
  return "Layanan akun Panenin sedang tidak tersedia. Silakan coba lagi sebentar lagi.";
}

function safeDisplayName(value: string | undefined): string | undefined {
  const normalized = value?.replace(/[\r\n\t]+/g, " ").trim();
  if (!normalized) return undefined;
  return normalized.slice(0, 80);
}
