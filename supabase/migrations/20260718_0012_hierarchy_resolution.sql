create or replace view public.domain_ancestor_chain as
with recursive ancestor_chain as (
  select
    d.id as requested_domain_id,
    d.id as ancestor_domain_id,
    d.parent_id,
    d.tenant_id,
    0 as depth
  from public.domains d
  union all
  select
    ac.requested_domain_id,
    p.id as ancestor_domain_id,
    p.parent_id,
    p.tenant_id,
    ac.depth + 1 as depth
  from ancestor_chain ac
  join public.domains p on p.id = ac.parent_id
)
select * from ancestor_chain;

create or replace view public.resolved_constraint_variants as
select
  dac.requested_domain_id as domain_id,
  dac.ancestor_domain_id,
  dac.depth,
  dcs.term_id,
  dcs.canonical_text,
  dcs.category,
  dcs.variant_id,
  dcs.variant_text,
  dcs.variant_type,
  dcs.locale_code,
  dcs.copyright_line,
  dcs.match_mode,
  dcs.validation_pattern,
  dcs.destination_code
from public.domain_ancestor_chain dac
join public.domain_constraint_sets dcs on dcs.domain_id = dac.ancestor_domain_id;

create or replace view public.resolved_constraint_rules as
select
  dac.requested_domain_id as domain_id,
  dac.ancestor_domain_id,
  dac.depth,
  acr.term_id,
  acr.rule_id,
  acr.rule_text,
  acr.enforcement_level,
  acr.priority,
  acr.destination_code
from public.domain_ancestor_chain dac
join public.active_constraint_rules acr on acr.domain_id = dac.ancestor_domain_id;
