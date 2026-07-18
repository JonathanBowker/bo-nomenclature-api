create unique index if not exists idx_terms_domain_canonical_text
  on public.terms (domain_id, lower(canonical_text));

create index if not exists idx_domains_tenant_parent
  on public.domains (tenant_id, parent_id);

create index if not exists idx_variants_term_type_locale
  on public.variants (term_id, variant_type, locale_code);

create index if not exists idx_variant_destinations_lookup
  on public.variant_destinations (destination_code, variant_id);

create index if not exists idx_rule_destinations_lookup
  on public.rule_destinations (destination_code, rule_id);

create index if not exists idx_approvals_term_destination_effective
  on public.approvals (term_id, destination_code, effective_at desc);

create index if not exists idx_audit_entries_lookup
  on public.audit_entries (entity_type, entity_id, occurred_at desc);

create or replace function public.prevent_domain_cycles()
returns trigger
language plpgsql
as $$
declare
  current_parent uuid;
begin
  current_parent := new.parent_id;
  while current_parent is not null loop
    if current_parent = new.id then
      raise exception 'Domain hierarchy cycle detected';
    end if;
    select parent_id into current_parent from public.domains where id = current_parent;
  end loop;
  return new;
end;
$$;

drop trigger if exists trg_prevent_domain_cycles on public.domains;
create trigger trg_prevent_domain_cycles
before insert or update on public.domains
for each row execute function public.prevent_domain_cycles();
