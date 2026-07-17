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

The WhatsApp provider adapter is isolated in `whatsapp_service/`. It receives
the raw Fonnte sender only in memory, derives an HMAC channel subject, and calls
the narrow internal-agent API. It never forwards or stores the raw number in
Panenin Core.

Start Core on port 8001 and the WhatsApp service on port 8000:

```powershell
.\scripts\start_whatsapp_demo.ps1
```

Open `http://127.0.0.1:8000/demo` for a provider-independent demo. The demo
flow is `HUBUNGKAN DEMO12`, `STOK`, `UBAH STOK 1 32`, then
`KONFIRMASI 123456`. The browser simulator uses isolated in-memory data and
cannot mutate Supabase.

For a real Fonnte device, set its POST webhook to:

```text
https://your-public-host.example/webhook/fonnte
```

Configure Fonnte's webhook secret to exactly match
`FONNTE_WEBHOOK_SECRET`. Enable auto-read as required by Fonnte. The real
provider path uses Panenin Core and therefore requires the database migrations,
`PANENIN_AI_SERVICE_TOKEN`, its matching SHA-256 hash in
`PANENIN_AI_SERVICE_TOKEN_HASH`, and a non-empty
`WHATSAPP_SUBJECT_PEPPER`.

Before a live-number demo, verify the device token without printing it:

```powershell
$token = ((Get-Content .env | Where-Object { $_ -match '^FONNTE_TOKEN=' }) -split '=', 2)[1]
$profile = Invoke-RestMethod -Method Post -Uri https://api.fonnte.com/device -Headers @{ Authorization = $token }
$profile.status
```

The result must be `True` and `device_status` should be `connect`.

Supported deterministic commands:

- `HUBUNGKAN <kode>`
- `STATUS`
- `STOK`
- `UBAH STOK <nomor> <jumlah>`
- `PESANAN`
- `TERIMA|TOLAK|SIAP|BATAL|SELESAI <nomor>`
- `KONFIRMASI <kode>` or `BATALKAN`

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
