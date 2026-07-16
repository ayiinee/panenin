create table public.conversation_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  user_channel_id uuid references public.user_channels(id) on delete set null,
  current_intent text,
  state text not null,
  context_json jsonb not null default '{}'::jsonb check (jsonb_typeof(context_json) = 'object'),
  status text not null default 'ACTIVE' check (status in ('ACTIVE', 'COMPLETED', 'EXPIRED')),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.incoming_messages (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  provider_message_id text not null,
  user_channel_id uuid references public.user_channels(id) on delete set null,
  conversation_session_id uuid references public.conversation_sessions(id) on delete set null,
  channel_identifier text not null,
  message_type text not null check (
    message_type in ('TEXT', 'IMAGE', 'DOCUMENT', 'LOCATION', 'INTERACTIVE', 'UNKNOWN')
  ),
  raw_payload_json jsonb not null check (jsonb_typeof(raw_payload_json) = 'object'),
  processing_status text not null default 'RECEIVED' check (
    processing_status in ('RECEIVED', 'QUEUED', 'PROCESSING', 'PROCESSED', 'FAILED', 'IGNORED')
  ),
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  failure_reason text,
  unique (provider, provider_message_id)
);

create table public.outgoing_messages (
  id uuid primary key default gen_random_uuid(),
  user_channel_id uuid not null references public.user_channels(id),
  provider text not null,
  provider_message_id text,
  message_type text not null check (message_type in ('TEXT', 'IMAGE', 'DOCUMENT', 'INTERACTIVE')),
  payload_json jsonb not null check (jsonb_typeof(payload_json) = 'object'),
  status text not null default 'PENDING' check (
    status in ('PENDING', 'SENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED')
  ),
  attempts integer not null default 0 check (attempts >= 0),
  scheduled_at timestamptz not null default now(),
  sent_at timestamptz,
  delivered_at timestamptz,
  failed_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.bot_actions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  conversation_session_id uuid references public.conversation_sessions(id) on delete set null,
  intent text not null,
  parameters_json jsonb not null check (jsonb_typeof(parameters_json) = 'object'),
  risk_level text not null check (risk_level in ('LOW', 'MEDIUM', 'HIGH')),
  confirmation_status text not null check (
    confirmation_status in ('NOT_REQUIRED', 'PENDING', 'CONFIRMED', 'REJECTED', 'EXPIRED')
  ),
  execution_status text not null default 'PENDING' check (
    execution_status in ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')
  ),
  idempotency_key text not null unique,
  result_json jsonb,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (risk_level = 'LOW' or confirmation_status <> 'NOT_REQUIRED')
);

create trigger conversation_sessions_set_updated_at before update on public.conversation_sessions
for each row execute function public.set_updated_at();
create trigger outgoing_messages_set_updated_at before update on public.outgoing_messages
for each row execute function public.set_updated_at();
create trigger bot_actions_set_updated_at before update on public.bot_actions
for each row execute function public.set_updated_at();
