create or replace view public.active_constraint_variants as
select
  t.tenant_id,
  t.domain_id,
  t.id as term_id,
  t.canonical_text,
  t.category,
  v.id as variant_id,
  v.variant_text,
  v.variant_type,
  v.locale_code,
  v.copyright_line,
  v.match_mode,
  v.validation_pattern,
  vd.destination_code
from public.terms t
join public.variants v on v.term_id = t.id
join public.variant_destinations vd on vd.variant_id = v.id
where exists (
  select 1
  from public.approvals a
  where a.term_id = t.id
    and a.destination_code = vd.destination_code
    and a.status = 'approved'
    and a.effective_at <= now()
    and (a.expires_at is null or a.expires_at > now())
);

create or replace view public.active_constraint_rules as
select
  t.tenant_id,
  t.domain_id,
  t.id as term_id,
  r.id as rule_id,
  r.rule_text,
  r.enforcement_level,
  r.priority,
  rd.destination_code
from public.terms t
join public.rules r on r.term_id = t.id
join public.rule_destinations rd on rd.rule_id = r.id
where exists (
  select 1
  from public.approvals a
  where a.term_id = t.id
    and a.destination_code = rd.destination_code
    and a.status = 'approved'
    and a.effective_at <= now()
    and (a.expires_at is null or a.expires_at > now())
);

create or replace view public.domain_constraint_sets as
select
  v.tenant_id,
  v.domain_id,
  v.term_id,
  v.canonical_text,
  v.category,
  v.variant_id,
  v.variant_text,
  v.variant_type,
  v.locale_code,
  v.copyright_line,
  v.match_mode,
  v.validation_pattern,
  v.destination_code,
  coalesce(
    (
      select jsonb_agg(
        jsonb_build_object(
          'rule_id', r.rule_id,
          'rule_text', r.rule_text,
          'enforcement_level', r.enforcement_level,
          'priority', r.priority
        )
        order by r.priority asc, r.rule_id asc
      )
      from public.active_constraint_rules r
      where r.term_id = v.term_id
        and r.destination_code = v.destination_code
    ),
    '[]'::jsonb
  ) as rules
from public.active_constraint_variants v;
