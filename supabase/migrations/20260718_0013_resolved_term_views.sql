create or replace view public.resolved_term_sets as
with winning_terms as (
  select distinct on (rcv.domain_id, rcv.destination_code, rcv.term_id)
    rcv.domain_id,
    rcv.destination_code,
    rcv.term_id,
    rcv.canonical_text,
    rcv.category,
    rcv.ancestor_domain_id,
    rcv.depth
  from public.resolved_constraint_variants rcv
  order by rcv.domain_id, rcv.destination_code, rcv.term_id, rcv.depth asc
),
term_variants as (
  select
    wt.domain_id,
    wt.destination_code,
    wt.term_id,
    jsonb_agg(
      jsonb_build_object(
        'id', rcv.variant_id,
        'variantText', rcv.variant_text,
        'variantType', rcv.variant_type,
        'locale', rcv.locale_code,
        'destinations', jsonb_build_array(rcv.destination_code),
        'copyrightLine', rcv.copyright_line
      )
      order by rcv.variant_type, rcv.variant_text
    ) as variants
  from winning_terms wt
  join public.resolved_constraint_variants rcv
    on rcv.domain_id = wt.domain_id
   and rcv.destination_code = wt.destination_code
   and rcv.term_id = wt.term_id
  group by wt.domain_id, wt.destination_code, wt.term_id
),
ranked_rules as (
  select
    rcr.domain_id,
    rcr.destination_code,
    rcr.term_id,
    rcr.rule_id,
    rcr.rule_text,
    rcr.enforcement_level,
    rcr.priority,
    rcr.ancestor_domain_id,
    rcr.depth,
    row_number() over (
      partition by rcr.domain_id, rcr.destination_code, rcr.term_id, rcr.rule_text
      order by rcr.depth asc, rcr.priority asc, rcr.rule_id asc
    ) as precedence_rank,
    count(*) over (
      partition by rcr.domain_id, rcr.destination_code, rcr.term_id, rcr.rule_text
    ) as same_rule_count
  from public.resolved_constraint_rules rcr
),
term_rules as (
  select
    rr.domain_id,
    rr.destination_code,
    rr.term_id,
    jsonb_agg(
      jsonb_build_object(
        'id', rr.rule_id,
        'ruleText', rr.rule_text,
        'enforcementLevel', rr.enforcement_level,
        'destinations', jsonb_build_array(rr.destination_code)
      )
      order by rr.priority asc, rr.rule_id asc
    ) filter (where rr.precedence_rank = 1) as rules,
    jsonb_agg(to_jsonb(rr.rule_text) order by rr.rule_text)
      filter (where rr.precedence_rank > 1 or rr.same_rule_count > 1) as overridden_rules
  from ranked_rules rr
  group by rr.domain_id, rr.destination_code, rr.term_id
)
select
  wt.domain_id,
  wt.destination_code,
  wt.term_id,
  wt.canonical_text,
  case
    when wt.depth = 0 then null
    else wt.ancestor_domain_id
  end as inherited_from,
  coalesce(tr.overridden_rules, '[]'::jsonb) as overridden_rules,
  tv.variants,
  coalesce(tr.rules, '[]'::jsonb) as rules
from winning_terms wt
join term_variants tv
  on tv.domain_id = wt.domain_id
 and tv.destination_code = wt.destination_code
 and tv.term_id = wt.term_id
left join term_rules tr
  on tr.domain_id = wt.domain_id
 and tr.destination_code = wt.destination_code
 and tr.term_id = wt.term_id;
