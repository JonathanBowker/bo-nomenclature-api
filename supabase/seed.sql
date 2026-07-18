insert into auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'brand.manager@example.com',
  crypt('password', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"name":"Brand Manager"}'::jsonb,
  now(),
  now()
)
on conflict (id) do nothing;

insert into public.tenants (id, name, slug)
values ('10000000-0000-0000-0000-000000000001', 'Brand Oracle Demo', 'brand-oracle-demo')
on conflict (id) do nothing;

insert into public.tenant_memberships (tenant_id, user_id, role)
values (
  '10000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'brand_manager'
)
on conflict (tenant_id, user_id) do update set role = excluded.role;

insert into public.domains (id, tenant_id, parent_id, name, slug, domain_type, created_by, updated_by)
values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', null, 'Brand Oracle', 'brand-oracle', 'brand', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'Travel Portfolio', 'travel-portfolio', 'portfolio', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 'Resort Collection', 'resort-collection', 'property', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 'Sky Lounge', 'sky-lounge', 'venue', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
on conflict (id) do nothing;

insert into public.terms (id, tenant_id, domain_id, canonical_text, category, approval_state, source_reference, created_by, updated_by)
values (
  '30000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000004',
  'PwC',
  'brand_name',
  'approved',
  'guideline:pwc-primary',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001'
)
on conflict (id) do nothing;

insert into public.variants (id, term_id, variant_text, variant_type, locale_code, copyright_line, match_mode, validation_pattern, created_by, updated_by)
values
  (
    '40000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'PwC',
    'approved',
    'en-GB',
    'PwC is a network of firms.',
    'exact',
    '^PwC$',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    'PricewaterhouseCoopers',
    'prohibited',
    'en-GB',
    null,
    'case_insensitive',
    '^(?i:PricewaterhouseCoopers)$',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001'
  )
on conflict (id) do nothing;

insert into public.variant_destinations (variant_id, destination_code, is_primary)
values
  ('40000000-0000-0000-0000-000000000001', 'video', true),
  ('40000000-0000-0000-0000-000000000002', 'video', false),
  ('40000000-0000-0000-0000-000000000002', 'social', false)
on conflict (variant_id, destination_code) do nothing;

insert into public.examples (term_id, example_type, caption, content_text, destination_code, created_by, updated_by)
values
  ('30000000-0000-0000-0000-000000000001', 'correct', 'Correct first mention', 'PwC announced the update.', 'video', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001'),
  ('30000000-0000-0000-0000-000000000001', 'incorrect', 'Incorrect expanded form', 'PricewaterhouseCoopers announced the update.', 'video', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001');

insert into public.rules (id, term_id, rule_text, enforcement_level, priority, created_by, updated_by)
values
  ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'Use the approved short form on first mention in video content.', 'hard', 10, '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001')
on conflict (id) do nothing;

insert into public.rule_destinations (rule_id, destination_code)
values ('50000000-0000-0000-0000-000000000001', 'video')
on conflict (rule_id, destination_code) do nothing;

insert into public.approvals (id, term_id, destination_code, status, comment, effective_at, expires_at, actor_id)
values
  (
    '60000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'video',
    'approved',
    'Approved for current launch.',
    now() - interval '1 day',
    now() + interval '90 days',
    '00000000-0000-0000-0000-000000000001'
  ),
  (
    '60000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000001',
    'print',
    'approved',
    'Expired print approval.',
    now() - interval '30 days',
    now() - interval '1 day',
    '00000000-0000-0000-0000-000000000001'
  )
on conflict (id) do nothing;
