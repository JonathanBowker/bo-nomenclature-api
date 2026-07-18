create or replace function public.validate_approval_event(
  input_term_id uuid,
  input_destination_code text,
  input_status text,
  input_effective_at timestamptz,
  input_expires_at timestamptz
)
returns void
language plpgsql
as $$
declare
  target_tenant_id uuid;
begin
  select tenant_id into target_tenant_id
  from public.terms
  where id = input_term_id;

  if target_tenant_id is null then
    raise exception 'Term % does not exist', input_term_id;
  end if;

  if not public.current_user_can_write_tenant(target_tenant_id) then
    raise exception 'Current user cannot approve terms for tenant %', target_tenant_id;
  end if;

  if input_destination_code is null or btrim(input_destination_code) = '' then
    raise exception 'destination_code is required';
  end if;

  if input_status not in ('approved', 'revoked') then
    raise exception 'Approval status must be approved or revoked';
  end if;

  if input_expires_at is not null and input_effective_at >= input_expires_at then
    raise exception 'expires_at must be later than effective_at';
  end if;
end;
$$;

create or replace function public.refresh_term_approval_state(input_term_id uuid)
returns void
language plpgsql
as $$
declare
  has_active_approval boolean;
begin
  select exists (
    select 1
    from public.approvals a
    where a.term_id = input_term_id
      and a.status = 'approved'
      and a.effective_at <= now()
      and (a.expires_at is null or a.expires_at > now())
  ) into has_active_approval;

  update public.terms
  set approval_state = case when has_active_approval then 'approved' else 'inactive' end
  where id = input_term_id;
end;
$$;

create or replace function public.record_term_approval(
  input_term_id uuid,
  input_destination_code text,
  input_status text,
  input_comment text default null,
  input_effective_at timestamptz default now(),
  input_expires_at timestamptz default null
)
returns public.approvals
language plpgsql
security definer
set search_path = public
as $$
declare
  new_approval public.approvals;
begin
  perform public.validate_approval_event(
    input_term_id,
    input_destination_code,
    input_status,
    input_effective_at,
    input_expires_at
  );

  update public.approvals
  set status = 'superseded'
  where term_id = input_term_id
    and destination_code = input_destination_code
    and status = 'approved'
    and (expires_at is null or expires_at > input_effective_at)
    and effective_at <= input_effective_at;

  insert into public.approvals (
    term_id,
    destination_code,
    status,
    comment,
    effective_at,
    expires_at,
    actor_id
  )
  values (
    input_term_id,
    input_destination_code,
    input_status,
    input_comment,
    input_effective_at,
    input_expires_at,
    auth.uid()
  )
  returning * into new_approval;

  perform public.refresh_term_approval_state(input_term_id);

  return new_approval;
end;
$$;

grant execute on function public.record_term_approval(uuid, text, text, text, timestamptz, timestamptz) to authenticated;
