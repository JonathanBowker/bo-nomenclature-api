create or replace view public.term_audit_feed as
select
  ae.id,
  ae.tenant_id,
  ae.entity_type,
  ae.entity_id,
  ae.action,
  ae.actor_id,
  ae.occurred_at,
  ae.before_snapshot,
  ae.after_snapshot
from public.audit_entries ae;

create or replace view public.domain_rule_overview as
select
  d.id as domain_id,
  d.tenant_id,
  d.parent_id,
  d.name as domain_name,
  t.id as term_id,
  t.canonical_text,
  r.id as rule_id,
  r.rule_text,
  r.enforcement_level
from public.domains d
left join public.terms t on t.domain_id = d.id
left join public.rules r on r.term_id = t.id;
