# Agent API Security

## Authentication

All `/api/v1/internal/agent` routes require `Authorization: Bearer <token>`. The backend hashes the presented token with SHA-256 and compares it in constant time with `PANENIN_AI_SERVICE_TOKEN_HASH`. Empty or incorrect credentials receive a generic 401 response.

The plaintext service token is never stored in source control. Rotate it by changing the external service secret and backend hash together.

## Identity and tenant isolation

The agent sends only an opaque `channelSubject` matching `wa:v1:<hex>`. FastAPI resolves it through a verified active `user_channels` row. User and organization IDs are derived by the backend; requests cannot provide `actor_user_id`.

Identity responses contain organization type, ID, and display name only. Email, raw phone number, detailed address, and user access tokens are excluded.

## Confirmation controls

Every WhatsApp mutation has two stages:

1. Preview validates and normalizes the request, calculates candidates/totals, and stores a pending `bot_actions` row. No inventory, listing, demand, order, or control mutation occurs.
2. Confirmation provides the action ID, one-time code, channel subject, and UUID idempotency key. FastAPI locks the action, rechecks ownership/state, executes one closed handler, audits, and returns the entity result.

Codes are generated with a restricted cryptographic alphabet and stored only as HMAC-SHA256 using `CONFIRMATION_CODE_PEPPER`. Plaintext is returned once. Payload hashes detect database tampering. Expiry defaults to ten minutes.

## Replay and concurrency

- A completed action replays its stored result only for the same idempotency key.
- Reusing a key for another action conflicts.
- `SELECT FOR UPDATE` serializes action confirmation and quantity-sensitive rows.
- Order totals are calculated from locked listing data.
- PostgreSQL constraints and transition triggers remain the final invariant layer.

## Forbidden capabilities

The API intentionally has no execute-SQL endpoint, generic mutation endpoint, generic table access, arbitrary filtering, arbitrary HTTP proxy, dynamic action import, `eval`, or model execution.

## Logging and audit

Application logs and audit payloads must exclude service/user tokens, one-time confirmation/link codes, raw channel identifiers derived from phone numbers, complete addresses, and provider payloads. Request IDs may be logged and returned for tracing.

## Recommended perimeter controls

- TLS termination and private networking or IP allowlisting.
- Gateway rate limits for identity linking and confirmation.
- Token rotation and secret-manager injection.
- Alerting on repeated 401, confirmation conflicts, and expired link attempts.
- Database role limited to required `public` objects in production.
