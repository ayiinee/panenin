import hashlib
import json
from typing import Any
from uuid import UUID


def canonical_payload_hash(payload: dict[str, Any]) -> str:
    encoded = json.dumps(
        payload,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
        default=str,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def normalize_idempotency_key(value: str) -> str:
    return str(UUID(value))
