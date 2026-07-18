create or replace function public.current_user_role_for_tenant(target_tenant_id uuid)
returns text
language sql
stable
as $$
  select tm.role
  from public.tenant_memberships tm
  where tm.user_id = auth.uid()
    and tm.tenant_id = target_tenant_id
  limit 1
$$;

create or replace function public.current_user_can_write_tenant(target_tenant_id uuid)
returns boolean
language sql
stable
as $$
  select coalesce(public.current_user_role_for_tenant(target_tenant_id) = 'brand_manager', false)
$$;

drop policy if exists membership_manage on public.tenant_memberships;
create policy membership_manage on public.tenant_memberships
for all using (public.current_user_can_write_tenant(tenant_id))
with check (public.current_user_can_write_tenant(tenant_id));

drop policy if exists domains_manage on public.domains;
create policy domains_manage on public.domains
for all using (public.current_user_can_write_tenant(tenant_id))
with check (public.current_user_can_write_tenant(tenant_id));

drop policy if exists terms_manage on public.terms;
create policy terms_manage on public.terms
for all using (public.current_user_can_write_tenant(tenant_id))
with check (public.current_user_can_write_tenant(tenant_id));

drop policy if exists variants_access on public.variants;
create policy variants_access on public.variants
for select using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
);

drop policy if exists variants_manage on public.variants;
create policy variants_manage on public.variants
for insert with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists variants_update on public.variants;
create policy variants_update on public.variants
for update using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
)
with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists variants_delete on public.variants;
create policy variants_delete on public.variants
for delete using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists variant_destinations_access on public.variant_destinations;
create policy variant_destinations_access on public.variant_destinations
for select using (
  exists (
    select 1
    from public.variants v
    join public.terms t on t.id = v.term_id
    where v.id = variant_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
);

drop policy if exists variant_destinations_manage on public.variant_destinations;
create policy variant_destinations_manage on public.variant_destinations
for all using (
  exists (
    select 1
    from public.variants v
    join public.terms t on t.id = v.term_id
    where v.id = variant_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
)
with check (
  exists (
    select 1
    from public.variants v
    join public.terms t on t.id = v.term_id
    where v.id = variant_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists examples_access on public.examples;
create policy examples_access on public.examples
for select using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
);

drop policy if exists examples_manage on public.examples;
create policy examples_manage on public.examples
for all using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
)
with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists rules_access on public.rules;
create policy rules_access on public.rules
for select using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
);

drop policy if exists rules_manage on public.rules;
create policy rules_manage on public.rules
for all using (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
)
with check (
  exists (
    select 1 from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists rule_destinations_access on public.rule_destinations;
create policy rule_destinations_access on public.rule_destinations
for select using (
  exists (
    select 1
    from public.rules r
    join public.terms t on t.id = r.term_id
    where r.id = rule_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
);

drop policy if exists rule_destinations_manage on public.rule_destinations;
create policy rule_destinations_manage on public.rule_destinations
for all using (
  exists (
    select 1
    from public.rules r
    join public.terms t on t.id = r.term_id
    where r.id = rule_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
)
with check (
  exists (
    select 1
    from public.rules r
    join public.terms t on t.id = r.term_id
    where r.id = rule_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);

drop policy if exists approvals_access on public.approvals;
create policy approvals_access on public.approvals
for select using (
  exists (
    select 1
    from public.terms t
    where t.id = term_id
      and t.tenant_id in (select public.current_tenant_ids())
  )
);

drop policy if exists approvals_manage on public.approvals;
create policy approvals_manage on public.approvals
for all using (
  exists (
    select 1
    from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
)
with check (
  exists (
    select 1
    from public.terms t
    where t.id = term_id
      and public.current_user_can_write_tenant(t.tenant_id)
  )
);
