create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid not null,
  source text not null check (source in ('APP', 'WHATSAPP', 'ADMIN', 'SYSTEM', 'WORKER')),
  old_data_json jsonb,
  new_data_json jsonb,
  request_id text,
  created_at timestamptz not null default now()
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  job_type text not null,
  payload_json jsonb not null check (jsonb_typeof(payload_json) = 'object'),
  status text not null default 'PENDING' check (
    status in ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'DEAD')
  ),
  priority smallint not null default 0,
  attempts integer not null default 0 check (attempts >= 0),
  max_attempts integer not null default 3 check (max_attempts > 0),
  available_at timestamptz not null default now(),
  locked_at timestamptz,
  lock_expires_at timestamptz,
  locked_by text,
  last_error text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (attempts <= max_attempts)
);

create trigger jobs_set_updated_at before update on public.jobs
for each row execute function public.set_updated_at();
