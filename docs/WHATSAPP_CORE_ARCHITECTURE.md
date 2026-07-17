# Panenin Core Architecture

## Authority boundary

Flutter and the external WhatsApp AI Service call FastAPI. FastAPI is the only component allowed to apply Panenin business rules or mutate the `public` schema. Supabase migrations remain the schema authority.

```text
Flutter --------------------\
                             > FastAPI -> Supabase public schema
WhatsApp AI Service --------/
```

The AI Service may interpret language and explain deterministic results. It never receives SQL credentials and never executes Claude, Gemini, OpenClaw, Fonnte, embedding, or RAG workloads inside this repository.

## Backend modules

- `auth`: validates Supabase user access tokens for mobile routes.
- `organizations`: profile and owned organization management.
- `inventory`: batches and auditable stock movements.
- `listings`: owned listings and redacted public catalog.
- `demands`: buyer demand creation and role-specific reads.
- `matching`: deterministic listing/demand scoring and persisted suggestions.
- `orders`: row-locked order creation, reservations, official transitions, release, and consumption.
- `whatsapp`: one-time link codes and channel-subject identity linking.
- `agent_api`: service authentication, read context, preview, confirmation, cancellation, and closed action execution.

Routers perform authentication, input validation, service invocation, and response envelopes. Services own authorization and transactions. Repositories own narrow SQL statements.

## Data ownership

- `auth.users`: Supabase Auth.
- `public.users` and `public.organizations`: Panenin Core profile authority.
- inventory/listing/demand/match/order tables: Panenin Core domain services.
- `user_channels`: opaque `wa:v1:<hex>` subjects only; raw phone numbers are forbidden.
- `bot_actions`: normalized preview payload, HMAC code hash, expiry, expected state, idempotency, and result.
- `audit_logs`: redacted mutation facts; never plaintext codes, tokens, raw contacts, or complete addresses.
- `panenin_ai_lab`: detected in the configured remote database but intentionally outside this repository and architecture.

## Transaction model

Every mutation runs in one async SQLAlchemy transaction. Confirmation locks `bot_actions`, re-resolves channel ownership, verifies expiry/code/idempotency/payload, locks domain rows, revalidates current state, executes a statically registered handler, writes audit, and commits once.

Order creation locks listing and inventory batch, then an optional demand. It calculates totals server-side, creates the order and reservation, decrements quantities, records a `RESERVE` movement, and lets existing database triggers create status history.

Reject/cancel releases an active reservation exactly once. Completion consumes it without decrementing available stock a second time.

## Matching

Matching is deterministic and filters exact commodity/unit compatibility, maximum price, date availability, positive quantity, and grade tolerance. A normalized score and structured reasons are persisted with `SUGGESTED` status. Distance is reserved for a later contract version because current matching requests do not contain coordinates.

## Known limitations

- Version `0.1.0` does not expose WhatsApp actions for `PICKED_UP` or `DELIVERED`; `COMPLETE_ORDER` remains valid only from the database-approved `DELIVERED` state.
- RESCUE previews do not include an expiry input; confirmed RESCUE listings currently receive a deterministic one-day expiry.
- Link-code guessing cannot safely increment a particular user's failed counter when a submitted code matches no row. Deployment should add channel/IP rate limiting at the gateway.
- The configured remote database has migration history not present in this repository. See the runbook before applying migrations.
