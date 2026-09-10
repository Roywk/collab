-- Visit 1MY - Limit Module 1 official cases and public map data to Kuala Lumpur.
-- This migration does not delete or rewrite existing scam reports.

begin;

create or replace function public.enforce_official_scam_admin()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  admin_allowed boolean;
begin
  if current_user in ('postgres', 'supabase_admin', 'service_role') then
    admin_allowed := true;
  else
    admin_allowed := public.is_admin() is true;
  end if;

  if tg_op = 'INSERT' then
    if new.is_official = true and admin_allowed is not true then
      raise exception 'Only an administrator can publish an official scam case'
        using errcode = '42501';
    end if;
  elsif tg_op = 'UPDATE' then
    if (old.is_official = true or new.is_official = true)
      and admin_allowed is not true then
      raise exception 'Only an administrator can modify an official scam case'
        using errcode = '42501';
    end if;
  end if;

  if new.is_official = true and (
    new.latitude is null
    or new.longitude is null
    or new.latitude not between 3.03 and 3.25
    or new.longitude not between 101.60 and 101.80
  ) then
    raise exception 'Official scam cases must be located in Kuala Lumpur'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create or replace function public.get_scam_map_reports()
returns table (
  id uuid,
  report_code text,
  title text,
  category text,
  description text,
  latitude double precision,
  longitude double precision,
  verification_status text,
  reported_at timestamp with time zone,
  location_name text,
  is_official boolean,
  source_reference text,
  is_active boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    report.id,
    report.report_code,
    report.title,
    report.category,
    report.description,
    report.latitude,
    report.longitude,
    report.verification_status,
    report.reported_at,
    report.location_name,
    report.is_official,
    report.source_reference,
    report.is_active
  from public.scam_reports as report
  where report.is_active = true
    and report.verification_status = 'Verified'
    and report.latitude between 3.03 and 3.25
    and report.longitude between 101.60 and 101.80
  order by report.reported_at desc;
$$;

revoke all on function public.get_scam_map_reports() from public;
grant execute on function public.get_scam_map_reports() to anon, authenticated;

commit;
