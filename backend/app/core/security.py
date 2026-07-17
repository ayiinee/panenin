import hashlib
import hmac
import secrets

from app.core.errors import ConfigurationError

_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


def generate_confirmation_code(length: int = 6) -> str:
    return "".join(secrets.choice(_CODE_ALPHABET) for _ in range(length))


def hash_one_time_code(code: str, pepper: str) -> str:
    if not pepper:
        raise ConfigurationError("CONFIRMATION_CODE_PEPPER belum dikonfigurasi.")
    normalized = code.strip().upper().encode("utf-8")
    return hmac.new(pepper.encode("utf-8"), normalized, hashlib.sha256).hexdigest()


def verify_one_time_code(code: str, expected_hash: str, pepper: str) -> bool:
    candidate = hash_one_time_code(code, pepper)
    return hmac.compare_digest(candidate, expected_hash)


def hash_service_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def verify_service_token(token: str, configured_hash: str) -> bool:
    if not token or not configured_hash:
        return False
    expected = configured_hash.removeprefix("sha256:").lower()
    return hmac.compare_digest(hash_service_token(token), expected)
