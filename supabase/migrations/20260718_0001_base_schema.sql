create extension if not exists pgcrypto;

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.tenant_memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('brand_manager', 'reviewer', 'reader', 'service_consumer')),
  created_at timestamptz not null default now(),
  unique (tenant_id, user_id)
);

create table if not exists public.domains (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  parent_id uuid references public.domains(id) on delete restrict,
  name text not null,
  slug text not null,
  domain_type text not null,
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  unique (tenant_id, slug)
);

create table if not exists public.terms (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  domain_id uuid not null references public.domains(id) on delete cascade,
  canonical_text text not null,
  category text not null,
  approval_state text not null default 'draft' check (approval_state in ('draft', 'approved', 'inactive')),
  source_reference text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id)
);

create table if not exists public.variants (
  id uuid primary key default gen_random_uuid(),
  term_id uuid not null references public.terms(id) on delete cascade,
  variant_text text not null,
  variant_type text not null check (variant_type in ('approved', 'prohibited', 'equivalent', 'regional')),
  locale_code text,
  copyright_line text,
  match_mode text not null default 'exact' check (match_mode in ('exact', 'case_insensitive', 'normalized', 'pattern')),
  validation_pattern text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id)
);

create table if not exists public.variant_destinations (
  id uuid primary key default gen_random_uuid(),
  variant_id uuid not null references public.variants(id) on delete cascade,
  destination_code text not null,
  is_primary boolean not null default false,
  unique (variant_id, destination_code)
);

create table if not exists public.examples (
  id uuid primary key default gen_random_uuid(),
  term_id uuid not null references public.terms(id) on delete cascade,
  example_type text not null check (example_type in ('correct', 'incorrect')),
  caption text,
  content_text text,
  asset_url text,
  destination_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  check (content_text is not null or asset_url is not null)
);

create table if not exists public.rules (
  id uuid primary key default gen_random_uuid(),
  term_id uuid not null references public.terms(id) on delete cascade,
  rule_text text not null,
  enforcement_level text not null check (enforcement_level in ('hard', 'warning', 'informational')),
  priority integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id)
);

create table if not exists public.rule_destinations (
  id uuid primary key default gen_random_uuid(),
  rule_id uuid not null references public.rules(id) on delete cascade,
  destination_code text not null,
  unique (rule_id, destination_code)
);

create table if not exists public.approvals (
  id uuid primary key default gen_random_uuid(),
  term_id uuid not null references public.terms(id) on delete cascade,
  destination_code text not null,
  status text not null check (status in ('approved', 'revoked', 'expired', 'superseded')),
  comment text,
  effective_at timestamptz not null default now(),
  expires_at timestamptz,
  actor_id uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.audit_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  action text not null check (action in ('create', 'update', 'delete')),
  actor_id uuid references auth.users(id),
  occurred_at timestamptz not null default now(),
  before_snapshot jsonb,
  after_snapshot jsonb,
  reason text,
  request_id text
);
