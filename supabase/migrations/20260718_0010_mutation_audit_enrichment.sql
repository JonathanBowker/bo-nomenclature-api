create or replace function public.current_request_reason()
returns text
language sql
stable
as $$
  select nullif(current_setting('request.headers.x-audit-reason', true), '')
$$;

create or replace function public.current_request_id()
returns text
language sql
stable
as $$
  select nullif(current_setting('request.headers.x-request-id', true), '')
$$;

create or replace function public.capture_governed_audit_entry()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  row_tenant_id uuid;
  row_entity_id uuid;
  row_actor_id uuid;
  related_term_id uuid;
begin
  if tg_op = 'DELETE' then
    row_entity_id := old.id;
  else
    row_entity_id := new.id;
  end if;

  row_actor_id := coalesce(auth.uid(), public.current_actor_id());

  if tg_table_name = 'approvals' then
    select t.tenant_id into row_tenant_id
    from public.terms t
    where t.id = coalesce(new.term_id, old.term_id);
  elsif tg_table_name in ('variants', 'examples', 'rules') then
    related_term_id := coalesce(new.term_id, old.term_id);
    select t.tenant_id into row_tenant_id
    from public.terms t
    where t.id = related_term_id;
  elsif tg_table_name = 'variant_destinations' then
    select t.tenant_id into row_tenant_id
    from public.variants v
    join public.terms t on t.id = v.term_id
    where v.id = coalesce(new.variant_id, old.variant_id);
  elsif tg_table_name = 'rule_destinations' then
    select t.tenant_id into row_tenant_id
    from public.rules r
    join public.terms t on t.id = r.term_id
    where r.id = coalesce(new.rule_id, old.rule_id);
  else
    row_tenant_id := coalesce(new.tenant_id, old.tenant_id);
  end if;

  insert into public.audit_entries (
    tenant_id,
    entity_type,
    entity_id,
    action,
    actor_id,
    before_snapshot,
    after_snapshot,
    reason,
    request_id
  )
  values (
    row_tenant_id,
    tg_table_name,
    row_entity_id,
    case
      when tg_op = 'INSERT' then 'create'
      when tg_op = 'UPDATE' then 'update'
      when tg_op = 'DELETE' then 'delete'
      else lower(tg_op)
    end,
    row_actor_id,
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end,
    public.current_request_reason(),
    public.current_request_id()
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_audit_domains on public.domains;
create trigger trg_audit_domains after insert or update or delete on public.domains
for each row execute function public.capture_governed_audit_entry();

drop trigger if exists trg_audit_terms on public.terms;
create trigger trg_audit_terms after insert or update or delete on public.terms
for each row execute function public.capture_governed_audit_entry();

drop trigger if exists trg_audit_variants on public.variants;
create trigger trg_audit_variants after insert or update or delete on public.variants
for each row execute function public.capture_governed_audit_entry();

drop trigger if exists trg_audit_examples on public.examples;
create trigger trg_audit_examples after insert or update or delete on public.examples
for each row execute function public.capture_governed_audit_entry();

drop trigger if exists trg_audit_rules on public.rules;
create trigger trg_audit_rules after insert or update or delete on public.rules
for each row execute function public.capture_governed_audit_entry();

drop trigger if exists trg_audit_approvals on public.approvals;
create trigger trg_audit_approvals after insert or update or delete on public.approvals
for each row execute function public.capture_governed_audit_entry();
