# Agent API Runbook

## Local prerequisites

- Python 3.12
- Flutter stable
- Node.js and repository-local Supabase CLI
- PostgreSQL/Supabase test database
- Docker Desktop when using local Supabase

Copy public frontend settings into `frontend/config.local.json`. Keep backend secrets only in the ignored root `.env` or a deployment secret manager.

Required backend settings:

```env
DATABASE_URL=postgresql+asyncpg://...
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
PANENIN_AI_SERVICE_TOKEN_HASH=sha256-hex-without-plaintext-token
PANENIN_AGENT_CONTRACT_VERSION=0.1.0
WHATSAPP_LINK_CODE_TTL_SECONDS=600
BOT_ACTION_TTL_SECONDS=600
ORDER_RESERVATION_TTL_SECONDS=86400
CONFIRMATION_CODE_PEPPER=random-secret
```

## Database migration warning

On 17 July 2026, repository migrations `20260717120000` and
`20260717170000` were applied to the configured Supabase project and their
history was reconciled to the repository versions. Database health and the
created columns/tables were verified after application.

The remote database still reports migration `20260716163145`, which owns a
separate `panenin_ai_lab` schema and is intentionally not tracked by this
repository. Do not run an unattended `supabase db push` until that external
migration is imported from its owning repository or otherwise reconciled.
Panenin Core changes are additive and do not access `panenin_ai_lab`.

Recommended validation sequence:

1. Start a disposable local Supabase stack.
2. Run `npx supabase db reset` and confirm all repository migrations and seed succeed.
3. Run backend integration tests against the local database.
4. Review migration diff against the intended remote project.
5. Apply remotely only with explicit deployment approval and backup/rollback readiness.

## Run backend

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

Health endpoints:

- `/api/v1/health`
- `/api/v1/health/database`
- `/docs`

## Run Flutter Web

```powershell
cd frontend
flutter run -d chrome --web-port=3000 --dart-define-from-file=config.local.json
```

Use `127.0.0.1` for web and `10.0.2.2` for an Android emulator when the backend runs on the host.

## Demo WhatsApp dan remote control

`whatsapp_service/` is a byte-for-byte import of
`farelfhr/panenin-whatsapp-rag-lab` branch
`feat/panenin-core-business-tools` at commit
`d77ea505d2367b2faa44092b8e95d46195b00a94`. It is a standalone Node.js and
TypeScript service containing the Fonnte gateway, Groq/Gemini RAG pipeline,
isolated Supabase lab schema, OpenClaw runtime, local knowledge base, and its
own test suite.

Install the exact locked dependencies and create the local environment file:

```powershell
cd whatsapp_service
npm ci
Copy-Item .env.example .env
```

Fill `whatsapp_service/.env` according to
`whatsapp_service/docs/MANUAL_SETUP_CHECKLIST.md`. Do not reuse the backend
service-role key unless the isolated lab schema and its security boundary have
been reviewed.

Enable the Panenin Core identity integration in `whatsapp_service/.env`:

```env
PANENIN_CORE_ENABLED=true
PANENIN_CORE_API_URL=http://127.0.0.1:8000
PANENIN_AI_SERVICE_TOKEN=<plaintext token whose SHA-256 is configured in Core>
WHATSAPP_SUBJECT_PEPPER=<independent random secret, at least 24 characters>
```

`PANENIN_AI_SERVICE_TOKEN` must match `PANENIN_AI_SERVICE_TOKEN_HASH` in the
FastAPI environment. `WHATSAPP_SUBJECT_PEPPER` stays only in the WhatsApp
service and deterministically pseudonymizes the sender as `wa:v1:<hmac>`.

The Flutter build also requires the public demo-device number:

```env
WHATSAPP_PHONE_NUMBER=628...
```

Run `scripts/prepare_demo_config.py` after adding it to the root `.env`.

Run the quality gates:

```powershell
npm run typecheck
npm test
npm run build
```

With FastAPI, its database, and the Core integration environment active, run
the safe identity smoke test:

```powershell
npm run test:core
```

It resolves a fixed synthetic opaque subject and prints
`CORE_IDENTITY_OK`; it does not link an account or mutate business data.

Run the complete local demo:

```powershell
npm run demo
```

The launcher starts or reuses the internal RAG tool, OpenClaw gateway, and
webhook service. Only the webhook port may be exposed publicly. Never expose
the OpenClaw gateway on port `18789` or the internal tool server on port
`3001`.

For a real Fonnte device, first start a temporary public tunnel:

```powershell
cloudflared tunnel --url http://127.0.0.1:8000 --no-autoupdate
```

Copy the generated `https://...trycloudflare.com` URL into
`whatsapp_service/.env`, including the webhook route and URL-encoded secret:

```env
PUBLIC_WEBHOOK_URL=https://...trycloudflare.com/webhook/fonnte?token=...
```

Register the secure webhook and recommended device settings:

```powershell
npm run fonnte:activate
npm run demo:check
```

The service implements the deterministic `HUBUNGKAN <kode>`, `STATUS AKUN`,
and read-only `RINGKASAN` flows against the canonical Core contract. These
commands bypass OpenClaw. Transaction preview/confirmation tools remain
intentionally unavailable in the WhatsApp service; it must not be presented as
a transaction gateway.

## Export and validate contract

```powershell
backend\.venv\Scripts\python.exe scripts\export_agent_contract.py
backend\.venv\Scripts\python.exe -m pytest
```

The canonical file is `contracts/panenin-agent-api.openapi.yaml`.

## Rollback

- Rotate/remove the agent token hash to disable internal routes immediately.
- Roll application traffic back to the prior build; additive nullable columns remain compatible.
- Do not delete migration history or pending actions. Let pending actions expire.
- Correct schema/data through a reviewed forward migration, never a generic SQL endpoint.
