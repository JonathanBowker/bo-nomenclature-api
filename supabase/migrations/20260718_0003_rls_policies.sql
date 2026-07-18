alter table public.tenants enable row level security;
alter table public.tenant_memberships enable row level security;
alter table public.domains enable row level security;
alter table public.terms enable row level security;
alter table public.variants enable row level security;
alter table public.variant_destinations enable row level security;
alter table public.examples enable row level security;
alter table public.rules enable row level security;
alter table public.rule_destinations enable row level security;
alter table public.approvals enable row level security;
alter table public.audit_entries enable row level security;

create or replace function public.current_tenant_ids()
returns setof uuid
language sql
stable
as $$
  select tenant_id
  from public.tenant_memberships
  where user_id = auth.uid()
$$;

create or replace function public.current_user_can_manage_tenant(target_tenant_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.tenant_memberships
    where user_id = auth.uid()
      and tenant_id = target_tenant_id
      and role in ('brand_manager', 'reviewer')
  )
$$;

drop policy if exists tenant_read on public.tenants;
create policy tenant_read on public.tenants
for select using (id in (select public.current_tenant_ids()));

drop policy if exists membership_read on public.tenant_memberships;
create policy membership_read on public.tenant_memberships
for select using (tenant_id in (select public.current_tenant_ids()));

drop policy if exists membership_manage on public.tenant_memberships;
create policy membership_manage on public.tenant_memberships
for all using (public.current_user_can_manage_tenant(tenant_id))
with check (public.current_user_can_manage_tenant(tenant_id));

drop policy if exists domains_select on public.domains;
create policy domains_select on public.domains
for select using (tenant_id in (select public.current_tenant_ids()));

drop policy if exists domains_manage on public.domains;
create policy domains_manage on public.domains
for all using (public.current_user_can_manage_tenant(tenant_id))
with check (public.current_user_can_manage_tenant(tenant_id));

drop policy if exists terms_select on public.terms;
create policy terms_select on public.terms
for select using (tenant_id in (select public.current_tenant_ids()));

drop policy if exists terms_manage on public.terms;
create policy terms_manage on public.terms
for all using (public.current_user_can_manage_tenant(tenant_id))
with check (public.current_user_can_manage_tenant(tenant_id));

drop policy if exists variants_access on public.variants;
create policy variants_access on public.variants
for all using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
)
with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_manage_tenant(t.tenant_id)
  )
);

drop policy if exists variant_destinations_access on public.variant_destinations;
create policy variant_destinations_access on public.variant_destinations
for all using (
  exists (
    select 1
    from public.variants v
    join public.terms t on t.id = v.term_id
    where v.id = variant_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
)
with check (
  exists (
    select 1
    from public.variants v
    join public.terms t on t.id = v.term_id
    where v.id = variant_id
      and public.current_user_can_manage_tenant(t.tenant_id)
  )
);

drop policy if exists examples_access on public.examples;
create policy examples_access on public.examples
for all using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
)
with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_manage_tenant(t.tenant_id)
  )
);

drop policy if exists rules_access on public.rules;
create policy rules_access on public.rules
for all using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
)
with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_manage_tenant(t.tenant_id)
  )
);

drop policy if exists rule_destinations_access on public.rule_destinations;
create policy rule_destinations_access on public.rule_destinations
for all using (
  exists (
    select 1
    from public.rules r
    join public.terms t on t.id = r.term_id
    where r.id = rule_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
)
with check (
  exists (
    select 1
    from public.rules r
    join public.terms t on t.id = r.term_id
    where r.id = rule_id
      and public.current_user_can_manage_tenant(t.tenant_id)
  )
);

drop policy if exists approvals_access on public.approvals;
create policy approvals_access on public.approvals
for all using (
  exists (
    select 1
    from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
)
with check (
  exists (
    select 1
    from public.terms t
    where t.id = term_id
      and public.current_user_can_manage_tenant(t.tenant_id)
  )
);

drop policy if exists audit_read on public.audit_entries;
create policy audit_read on public.audit_entries
for select using (tenant_id in (select public.current_tenant_ids()));
