# WhatsApp Core Implementation Plan

Status: audit complete; implementation blocked pending an isolated PostgreSQL/Supabase `DATABASE_URL` and a schema decision for profile commodity ownership.

Branch: `feat/whatsapp-agent-core-integration`

Contract target: `0.1.0`

## 1. Current condition

### Backend

- FastAPI exposes `GET /api/v1/health` and the authenticated `GET /api/v1/auth/me` route only.
- Supabase access-token verification calls `/auth/v1/user` through `httpx`; no database session, repository, domain service, transaction, or audit writer exists yet.
- `SQLAlchemy[asyncio]` and `asyncpg` are already dependencies, but there is no engine or session factory.
- Error responses already use `data`, `error`, and `requestId`, although success envelope helpers and domain-error mapping are not centralized.
- Tests cover Supabase authentication only and currently use mocks rather than PostgreSQL.

### Flutter

- Authentication uses Supabase and validates the resulting access token through FastAPI.
- `ApiClient` only implements `/api/v1/auth/me`; it has one manual refresh-on-401 path and no reusable typed GET/POST/PUT/PATCH methods, timeout policy, or request-ID propagation.
- Profile submission validates locally and then waits for a timer; it does not persist `users`, `organizations`, address, or selected commodities.
- Inventory uses `demoStockItems` and mutates an in-memory list.
- Farmer demands are static local values.
- Orders use `demoOrders`; order transitions only mutate widget state.
- Buyer catalog uses `BuyerHomeFixture` by default.
- Flutter role values (`FARMER`, `BUYER`) do not match database organization types (`FARM`, `UMKM`).

### Supabase schema

Supabase migrations already own the public schema and define:

- identity: `users`, `organizations`, `user_channels`;
- catalog/inventory: `commodities`, `inventory_batches`, `inventory_movements`, `listings`, `listing_media`;
- demand/matching: `demands`, `matches`;
- order lifecycle: `orders`, `inventory_reservations`, `order_status_history`;
- WhatsApp/bot: `conversation_sessions`, `incoming_messages`, `outgoing_messages`, `bot_actions`;
- operations: `audit_logs`, `jobs`;
- knowledge storage: `knowledge_documents`, `knowledge_chunks` with `vector(1536)`.

The schema has validation triggers for organization roles, canonical units, listing availability, demand ownership, match compatibility, order compatibility, reservation batch consistency, and official order transitions. Order status history reads transaction-local `app.action_source` and `app.actor_user_id`.

Supabase migrations remain the only schema authority. SQLAlchemy models will map existing tables only; neither `metadata.create_all()` nor Alembic will be used.

### Verified schema gaps and constraints

- `whatsapp_link_codes` does not exist.
- `bot_actions` lacks confirmation hash, expiry/confirmation/cancellation timestamps, expected version, channel subject, and payload hash.
- `bot_actions.idempotency_key` is already non-null and unique. Preview creation must use a generated placeholder; confirmation atomically replaces it with the caller UUID and replays the stored result only for that same key.
- `organizations` supports one owner only; there is no organization-membership model.
- There is no table that can persist the profile's selected commodities. An additive `organization_commodities` table is required, or the product requirement must be reduced.
- Existing order transitions do not allow arbitrary completion. `COMPLETE_ORDER` can only execute from `DELIVERED`; the backend must not bypass the trigger.
- Requested control actions do not include `MARK_PICKED_UP` or `MARK_DELIVERED`; the WhatsApp contract therefore cannot drive the complete delivery lifecycle in version `0.1.0`.
- `inventory_reservations.expires_at` is required, but no reservation TTL setting is defined by the request. A product-approved default/configuration is required before order creation is finalized.
- RLS grants authenticated clients read access only to matches, orders, and order history. All new mobile writes must go through FastAPI.
- The repository has no usable integration-test `DATABASE_URL`, and the local Supabase stack cannot start while Docker Desktop is unavailable.

## 2. Planned files

### New backend files

- `backend/app/core/database.py`: async engine, `async_sessionmaker`, request session dependency, transaction-local context, database health check, and dependency override seam.
- `backend/app/core/errors.py`: stable domain errors and safe error envelope mapping.
- `backend/app/core/idempotency.py`: payload hashing and UUID validation helpers.
- `backend/app/core/security.py`: code generation, HMAC hashing, and constant-time verification without secret logging.
- `backend/app/core/schemas.py`: reusable success/error envelopes.
- Domain packages under `organizations`, `inventory`, `listings`, `demands`, `matching`, and `orders`, each split into models, schemas, repository, service, and router where applicable.
- `backend/app/whatsapp/`: link-code creation/status and shared identity-linking service.
- `backend/app/agent_api/`: service-token security, canonical schemas, read endpoints, preview service, closed action registry, confirmation/cancellation, and audit writer.
- `backend/tests/conftest.py`: isolated PostgreSQL session/transaction fixtures and FastAPI dependency overrides.
- Backend unit/integration test modules grouped by security, identity, previews, confirmation, orders, transitions, redaction, and mobile APIs.

### New Flutter files

- Data models and repositories for profile, inventory, listings/catalog, demands/matches, orders, and WhatsApp linking.
- Presentation state/adapters that retain the existing screens while loading production data through repositories.
- A simple WhatsApp linking screen/section showing one-time code, expiry, instructions, refresh, and error/loading states.
- Repository and widget tests for each production path.

### New schema and contract files

- One timestamped additive Supabase migration for `whatsapp_link_codes`, `bot_actions` enhancements, constraints/indexes/grants, and—only after approval—the profile commodity relation.
- `contracts/panenin-agent-api.openapi.yaml` using OpenAPI 3.1 and contract version `0.1.0`.

### New documentation

- `docs/WHATSAPP_CORE_ARCHITECTURE.md`
- `docs/AGENT_API_SECURITY.md`
- `docs/AGENT_API_RUNBOOK.md`
- `docs/WHATSAPP_LINKING_FLOW.md`

### Existing files to change

- `.env.example`, `backend/app/core/config.py`, `backend/app/main.py`, and `backend/app/api/router.py`.
- Existing Flutter `ApiClient`, profile, stock, home, and order screens plus route declarations.
- `backend/requirements.txt` only if a test/contract-validation dependency is proven necessary.
- Existing Supabase migrations will not be edited.

## 3. Data ownership

- Supabase migrations own schema and constraints.
- FastAPI is the sole business authority and only writer for profile, organization, inventory, listing, demand, match, order, reservation, WhatsApp identity, bot action, and audit data.
- Flutter owns presentation state only and authenticates with a Supabase user token.
- The external WhatsApp AI Service owns conversation orchestration and natural-language generation only. It receives a narrow internal API and never receives SQL credentials, service-role keys, full addresses, email addresses, or raw phone numbers.
- `channel_subject` is the only WhatsApp identity crossing the agent boundary and must match `^wa:v1:[0-9a-f]+$`. Raw numbers are never stored in `user_channels.channel_identifier`.
- FastAPI derives `actor_user_id` from the Supabase token or resolved channel; clients cannot supply it.

## 4. Transaction boundaries

Each mutation opens one SQLAlchemy transaction and performs authorization, locking, revalidation, writes, and audit before commit. Any exception rolls the entire transaction back.

### Link identity

Lock the unconsumed link code, verify HMAC/expiry/attempt limit, upsert the channel link, mark it verified, consume the code, and write audit in one transaction.

### Preview

Resolve identity and organization, validate/normalize against canonical commodities and units, read candidate matches, create one pending `bot_actions` row with payload hash and hashed one-time code, then commit. Preview must not write any domain entity.

### Confirm action

1. Lock `bot_actions` with `SELECT FOR UPDATE`.
2. Verify channel ownership, pending status, HMAC code, expiry, payload hash, and idempotency key.
3. Revalidate current domain state and lock all rows in deterministic order.
4. Execute only a statically registered handler.
5. Persist domain mutations, action result, confirmation/completion state, and a redacted audit record.
6. Commit once. Duplicate confirmation with the same key returns the stored result; a different key conflicts.

### Order creation

Lock listing then inventory batch, and demand when supplied. Revalidate status/quantity/price/unit/ownership; calculate totals; insert order and active reservation; decrement available/listed/demand quantities; insert `RESERVE` movement; update terminal listing/demand statuses; set transaction-local action source/actor; and audit in one transaction.

### Order control

Lock order and active reservation plus its batch/listing. Apply only the existing transition graph. Reject/cancel releases active reservation and quantities exactly once. Completion consumes the active reservation according to the agreed lifecycle rule. The database trigger records status history.

## 5. Threat model

- **Stolen agent credential:** store only a configured token hash, compare in constant time, scope it to `/api/v1/internal/agent`, return generic 401 errors, and support rotation through environment configuration.
- **Replay/double execution:** action ownership, expiry, hashed one-time confirmation code, unique confirmation idempotency key, row lock, stored result replay, and payload hash.
- **Concurrent oversell:** deterministic `SELECT FOR UPDATE`, revalidation inside one transaction, database checks, and concurrency integration tests.
- **Cross-tenant access:** organization ownership checks derived from authenticated identity; channel subject resolves to the actor and is rechecked at confirmation.
- **Injection/confused deputy:** explicit Pydantic schemas, closed action registry, no generic table/mutation/SQL/filter/proxy endpoint, no dynamic imports/eval, and no caller-supplied actor ID or totals.
- **PII/secret leakage:** structured safe errors, redacted responses/audits, no token/code/raw number/address payload logging, and no backend secret in Flutter.
- **Code guessing:** cryptographically random codes, HMAC with `CONFIRMATION_CODE_PEPPER`, short TTL, bounded failures, single use, and constant-time comparison.
- **Stale preview:** expected-state marker plus full state revalidation under row locks before execution.

## 6. Rollback plan

- Application rollback: stop the new FastAPI build and return traffic to the previous version. New tables/nullable columns are additive, so old code remains compatible.
- Migration rollback: do not edit or delete historical migrations. If rollback is required, add a forward corrective migration. Preserve `whatsapp_link_codes`, enhanced `bot_actions`, and audit data until retention/export approval; do not destructively drop them during incident response.
- Feature rollback: disable internal-agent routes by removing/rotating the service token and keep mobile reads operational.
- In-flight actions: leave pending actions immutable until they expire; never auto-confirm after rollback.
- Data correction: use a reviewed, narrow corrective migration or domain-specific administrative command—never a generic SQL endpoint.

## 7. Implementation order

1. Obtain an isolated test database and validate all existing Supabase migrations plus seed.
2. Resolve the profile commodity relation and reservation TTL decisions.
3. Add the additive Supabase migration and validate it on a disposable database.
4. Add configuration, database session management, safe errors/envelopes, hashing, and agent service authentication.
5. Map existing tables with SQLAlchemy and implement shared organization/identity authorization.
6. Implement deterministic matching and read-only mobile/agent queries.
7. Implement WhatsApp link-code creation, resolve, link, status, and redacted context.
8. Implement preview creation for sell, buy, order, and controls.
9. Implement the closed confirmation/cancellation registry and domain transactions.
10. Publish and validate the canonical OpenAPI contract against implemented routes.
11. Add authenticated mobile routes using the same services.
12. Extend Flutter networking/repositories, then replace production fixture paths while retaining fixtures for tests/previews.
13. Add WhatsApp linking UI without backend secrets.
14. Complete architecture/security/runbook/linking documentation.

## 8. Testing order

1. Migration reset/validation on an isolated Supabase/PostgreSQL instance.
2. Core security/hash/envelope unit tests.
3. Service-token and Supabase-auth route tests.
4. Identity link/resolve tests including wrong, expired, reused, and attempt-limited codes.
5. Role, ownership, and redaction tests.
6. Preview tests proving no inventory/listing/demand/order mutation occurs.
7. Confirmation tests for wrong/expired codes, ownership, duplicate idempotency, and unknown intents.
8. Domain integration tests for matching, transitions, reservation release/consume, audit source, row locks, and concurrent no-oversell behavior.
9. Contract lint/validation and route/contract parity test.
10. Existing backend authentication suite.
11. Flutter repository tests followed by loading/empty/error/success widget tests and all existing widget tests.
12. Final `python -m pytest`, `flutter analyze`, `flutter test`, and Supabase migration validation.

## 9. Blocking decisions and prerequisites

Implementation must not proceed until:

- `DATABASE_URL` points to an isolated, disposable PostgreSQL database with all Supabase migrations applied; production is forbidden.
- The team approves an additive `organization_commodities` relation (recommended columns: `organization_id`, `commodity_id`, `created_at`, composite primary key) or removes selected-commodity persistence from scope.
- A reservation expiry policy is chosen (recommended configurable seconds with an explicit default and documented release behavior).
- Contract version `0.1.0` accepts that WhatsApp control supports only the listed actions and that `COMPLETE_ORDER` is valid only from `DELIVERED`.

No implementation should weaken existing triggers or replace Supabase migration authority to bypass these blockers.
