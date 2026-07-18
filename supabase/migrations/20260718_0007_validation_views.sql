create or replace view public.active_term_approvals as
select
  a.term_id,
  a.destination_code,
  a.status,
  a.effective_at,
  a.expires_at,
  public.term_active_approval_state(a.term_id, a.destination_code) as derived_status
from public.approvals a;

create or replace view public.destination_scoped_variants as
select
  v.id as variant_id,
  t.id as term_id,
  t.domain_id,
  t.tenant_id,
  t.canonical_text,
  t.category,
  v.variant_text,
  v.variant_type,
  v.locale_code,
  v.copyright_line,
  v.match_mode,
  v.validation_pattern,
  vd.destination_code
from public.variants v
join public.terms t on t.id = v.term_id
join public.variant_destinations vd on vd.variant_id = v.id;

create or replace view public.validation_candidates as
select
  dsv.*,
  ata.derived_status as approval_status
from public.destination_scoped_variants dsv
left join public.active_term_approvals ata
  on ata.term_id = dsv.term_id
 and ata.destination_code = dsv.destination_code;
