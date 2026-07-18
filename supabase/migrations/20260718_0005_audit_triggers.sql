create or replace function public.capture_audit_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  row_tenant_id uuid;
  row_entity_id uuid;
begin
  if tg_op = 'DELETE' then
    row_tenant_id := old.tenant_id;
    row_entity_id := old.id;
  else
    row_tenant_id := new.tenant_id;
    row_entity_id := new.id;
  end if;

  insert into public.audit_entries (
    tenant_id,
    entity_type,
    entity_id,
    action,
    actor_id,
    before_snapshot,
    after_snapshot
  )
  values (
    row_tenant_id,
    tg_table_name,
    row_entity_id,
    lower(tg_op),
    auth.uid(),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_audit_domains on public.domains;
create trigger trg_audit_domains after insert or update or delete on public.domains
for each row execute function public.capture_audit_entry();

drop trigger if exists trg_audit_terms on public.terms;
create trigger trg_audit_terms after insert or update or delete on public.terms
for each row execute function public.capture_audit_entry();

drop trigger if exists trg_audit_variants on public.variants;
create trigger trg_audit_variants after insert or update or delete on public.variants
for each row execute function public.capture_audit_entry();

drop trigger if exists trg_audit_examples on public.examples;
create trigger trg_audit_examples after insert or update or delete on public.examples
for each row execute function public.capture_audit_entry();

drop trigger if exists trg_audit_rules on public.rules;
create trigger trg_audit_rules after insert or update or delete on public.rules
for each row execute function public.capture_audit_entry();
