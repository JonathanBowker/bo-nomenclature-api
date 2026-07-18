\set ON_ERROR_STOP on

begin;

insert into public.tenants (id, name, slug)
values (
  '10000000-0000-0000-0000-000000000001'::uuid,
  'Acceptance Tenant',
  'acceptance-tenant'
);

insert into public.domains (id, tenant_id, parent_id, name, slug, domain_type, status)
values
  (
    '20000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    null,
    'Acceptance Root',
    'acceptance-root',
    'brand',
    'active'
  ),
  (
    '20000000-0000-0000-0000-000000000004'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    '20000000-0000-0000-0000-000000000001'::uuid,
    'Acceptance Leaf',
    'acceptance-leaf',
    'venue',
    'active'
  );

insert into public.terms (
  id,
  tenant_id,
  domain_id,
  canonical_text,
  category,
  approval_state,
  source_reference
)
values (
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  '10000000-0000-0000-0000-000000000001'::uuid,
  '20000000-0000-0000-0000-000000000004'::uuid,
  'Acceptance Check Term',
  'service_name',
  'draft',
  'acceptance:test'
);

insert into public.variants (
  id,
  term_id,
  variant_text,
  variant_type,
  locale_code,
  copyright_line,
  match_mode,
  validation_pattern
)
values
(
  '40000000-0000-0000-0000-0000000000aa'::uuid,
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  'Acceptance Check Term',
  'approved',
  'en-GB',
  'Acceptance copyright line.',
  'exact',
  '^Acceptance Check Term$'
),
(
  '40000000-0000-0000-0000-0000000000ab'::uuid,
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  'Bad Acceptance Check Term',
  'prohibited',
  'en-GB',
  null,
  'exact',
  '^Bad Acceptance Check Term$'
);

insert into public.variant_destinations (
  variant_id,
  destination_code,
  is_primary
)
values
(
  '40000000-0000-0000-0000-0000000000aa'::uuid,
  'video',
  true
),
(
  '40000000-0000-0000-0000-0000000000ab'::uuid,
  'video',
  false
);

insert into public.rules (
  id,
  term_id,
  rule_text,
  enforcement_level,
  priority
)
values (
  '50000000-0000-0000-0000-0000000000aa'::uuid,
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  'Use the approved acceptance term in video content.',
  'hard',
  10
);

insert into public.rule_destinations (
  rule_id,
  destination_code
)
values (
  '50000000-0000-0000-0000-0000000000aa'::uuid,
  'video'
);

insert into public.approvals (
  id,
  term_id,
  destination_code,
  status,
  comment,
  effective_at,
  expires_at
)
values (
  '60000000-0000-0000-0000-0000000000aa'::uuid,
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  'video',
  'approved',
  'database acceptance verification',
  now(),
  now() + interval '7 days'
);

select public.term_active_approval_state(
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  'video'::text
) as derived_approval_state;

select
  entity_type,
  action,
  count(*) as total
from public.audit_entries
where entity_id in (
  '30000000-0000-0000-0000-0000000000aa'::uuid,
  '60000000-0000-0000-0000-0000000000aa'::uuid
)
group by entity_type, action
order by entity_type, action;

select
  tablename,
  count(*) as policy_count
from pg_policies
where schemaname = 'public'
  and tablename in ('domains', 'terms', 'approvals', 'audit_entries')
group by tablename
order by tablename;

select
  count(*) as active_video_constraints
from public.domain_constraint_sets
where domain_id = '20000000-0000-0000-0000-000000000004'::uuid
  and destination_code = 'video';

rollback;
