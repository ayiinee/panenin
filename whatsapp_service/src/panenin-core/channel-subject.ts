import { createHmac } from "node:crypto";

export function createWhatsAppChannelSubject(
  sender: string,
  pepper: string,
): string {
  const normalizedSender = normalizeSender(sender);
  if (!normalizedSender) throw new Error("sender WhatsApp wajib diisi");
  if (pepper.length < 24) throw new Error("pepper subject WhatsApp terlalu pendek");

  const digest = createHmac("sha256", pepper)
    .update(normalizedSender)
    .digest("hex");
  return `wa:v1:${digest}`;
}

function normalizeSender(sender: string): string {
  const trimmed = sender.trim();
  if (!trimmed) return "";

  const address = trimmed.split("@", 1)[0] ?? "";
  const digits = address.replace(/\D/g, "");
  return digits || address.toLowerCase();
}
