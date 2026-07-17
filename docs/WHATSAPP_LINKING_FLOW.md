# WhatsApp Linking Flow

## Mobile initiation

1. An authenticated Flutter user completes a profile and organization.
2. Flutter calls `POST /api/v1/whatsapp/link-code` with the Supabase user token.
3. FastAPI invalidates earlier unconsumed codes for that user, generates a six-character code, stores only its HMAC hash, and returns plaintext once with a maximum ten-minute expiry.
4. Flutter shows `HUBUNGKAN <kode>` and an expiry time.

## Agent completion

1. The external WhatsApp service derives an opaque subject such as `wa:v1:<hex>` without sending the raw phone number to Panenin Core.
2. It calls `POST /api/v1/internal/agent/identity/link` using its service bearer token, channel subject, and plaintext link code.
3. FastAPI locks the code, verifies hash/expiry/single-use state, prevents the subject from being linked to another user, upserts `user_channels`, marks it verified, consumes the code, and audits the link atomically.
4. Later calls use `identity/resolve` or `/context`; no code is required again.

The WhatsApp service handles the following commands before any AI routing:

- `HUBUNGKAN <kode>` exchanges the one-time code.
- `STATUS AKUN` resolves the opaque subject and reports linked/unlinked state.
- `RINGKASAN` reads the redacted Core account context.

These commands never enter OpenClaw and never send the raw sender number to
Panenin Core.

## Status refresh

Flutter calls `GET /api/v1/whatsapp/status`. The response includes only linked state and verification time. It never returns the stored channel subject.

## Failure behavior

- Unknown code: `INVALID_LINK_CODE`
- Expired code: `LINK_CODE_EXPIRED`
- Consumed code: `LINK_CODE_USED`
- Subject linked to another account: `CHANNEL_ALREADY_LINKED`
- Missing profile: link-code generation is rejected

Codes and raw contact data are never included in audit JSON or application error messages.

## Required runtime alignment

- FastAPI: `PANENIN_AI_SERVICE_TOKEN_HASH` and `CONFIRMATION_CODE_PEPPER`.
- WhatsApp service: `PANENIN_CORE_ENABLED=true`,
  `PANENIN_CORE_API_URL`, the matching plaintext
  `PANENIN_AI_SERVICE_TOKEN`, and an independent
  `WHATSAPP_SUBJECT_PEPPER`.
- Flutter: `WHATSAPP_PHONE_NUMBER` in the dart-define configuration.

The service-token plaintext and subject pepper are backend-only secrets. The
WhatsApp phone number is a public application build value.
