create or replace function public.is_active_approval(
  approval_status text,
  effective_at timestamptz,
  expires_at timestamptz
)
returns boolean
language sql
immutable
as $$
  select approval_status = 'approved'
    and effective_at <= now()
    and (expires_at is null or expires_at > now())
$$;

create or replace function public.term_active_approval_state(
  input_term_id uuid,
  input_destination_code text
)
returns text
language sql
stable
as $$
  with latest as (
    select a.*
    from public.approvals a
    where a.term_id = input_term_id
      and a.destination_code = input_destination_code
    order by a.effective_at desc, a.created_at desc
    limit 1
  )
  select coalesce(
    (
      select case
        when public.is_active_approval(status, effective_at, expires_at) then 'approved'
        when status = 'approved' and expires_at is not null and expires_at <= now() then 'expired'
        else status
      end
      from latest
    ),
    'missing'
  )
$$;

create or replace function public.current_actor_id()
returns uuid
language sql
stable
as $$
  select auth.uid()
$$;

create or replace function public.updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

drop trigger if exists trg_domains_updated_at on public.domains;
create trigger trg_domains_updated_at
before update on public.domains
for each row execute function public.updated_at_column();

drop trigger if exists trg_terms_updated_at on public.terms;
create trigger trg_terms_updated_at
before update on public.terms
for each row execute function public.updated_at_column();

drop trigger if exists trg_variants_updated_at on public.variants;
create trigger trg_variants_updated_at
before update on public.variants
for each row execute function public.updated_at_column();

drop trigger if exists trg_examples_updated_at on public.examples;
create trigger trg_examples_updated_at
before update on public.examples
for each row execute function public.updated_at_column();

drop trigger if exists trg_rules_updated_at on public.rules;
create trigger trg_rules_updated_at
before update on public.rules
for each row execute function public.updated_at_column();
