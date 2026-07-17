import hashlib
import hmac
import re


def derive_channel_subject(sender: str, pepper: str) -> str:
    if not pepper:
        raise ValueError("WHATSAPP_SUBJECT_PEPPER belum dikonfigurasi.")
    normalized = re.sub(r"[^0-9A-Za-z@._-]", "", sender.strip().lower())
    if not normalized:
        raise ValueError("Identitas pengirim tidak valid.")
    digest = hmac.new(
        pepper.encode("utf-8"),
        normalized.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return f"wa:v1:{digest}"


def verify_webhook_secret(presented: str, configured: str) -> bool:
    if not presented or not configured:
        return False
    return hmac.compare_digest(presented, configured)

