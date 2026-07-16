create table public.knowledge_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  source_type text not null,
  source_uri text,
  content text not null,
  checksum text not null,
  status text not null default 'DRAFT' check (
    status in ('DRAFT', 'PROCESSING', 'ACTIVE', 'FAILED', 'ARCHIVED')
  ),
  version integer not null default 1 check (version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (checksum, version)
);

create table public.knowledge_chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public.knowledge_documents(id) on delete cascade,
  chunk_index integer not null check (chunk_index >= 0),
  chunk_text text not null,
  token_count integer check (token_count is null or token_count > 0),
  embedding extensions.vector(1536),
  embedding_model text,
  metadata_json jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata_json) = 'object'),
  created_at timestamptz not null default now(),
  unique (document_id, chunk_index),
  check ((embedding is null) = (embedding_model is null))
);

create trigger knowledge_documents_set_updated_at before update on public.knowledge_documents
for each row execute function public.set_updated_at();
