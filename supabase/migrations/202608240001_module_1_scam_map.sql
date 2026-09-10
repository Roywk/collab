-- Visit 1MY - Module 1: Scam Alert & Scam Map
-- Run this migration in the Supabase SQL editor before using Module 1.

begin;

alter table public.scam_reports
  add column if not exists title text,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_name text,
  add column if not exists is_official boolean not null default false,
  add column if not exists source_reference text,
  add column if not exists is_active boolean not null default true;

-- Official location-based cases do not have to belong to a business record.
alter table public.scam_reports
  alter column threat_record_id drop not null;

alter table public.scam_reports
  drop constraint if exists scam_reports_latitude_check,
  add constraint scam_reports_latitude_check
    check (latitude is null or latitude between -90 and 90),
  drop constraint if exists scam_reports_longitude_check,
  add constraint scam_reports_longitude_check
    check (longitude is null or longitude between -180 and 180),
  drop constraint if exists scam_reports_public_source_check,
  add constraint scam_reports_public_source_check
    check (
      source_reference is null
      or source_reference ~* '^https?://'
    );

create index if not exists scam_reports_map_status_idx
  on public.scam_reports (verification_status, is_active)
  where latitude is not null and longitude is not null;

create index if not exists scam_reports_map_location_idx
  on public.scam_reports using gin (
    to_tsvector(
      'simple',
      coalesce(title, '') || ' ' || coalesce(location_name, '') || ' ' ||
      coalesce(category, '')
    )
  );

-- The five existing scam_reports RLS policies are intentionally left unchanged.
-- This trigger prevents a non-admin client from assigning the official badge
-- while preserving the existing insert policy exactly as it is.
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

  return new;
end;
$$;

drop trigger if exists enforce_official_scam_admin on public.scam_reports;
create trigger enforce_official_scam_admin
  before insert or update
  on public.scam_reports
  for each row
  execute function public.enforce_official_scam_admin();

-- Expose only verified, non-sensitive fields on the public map without
-- granting map clients access to evidence URLs or reporter IDs.

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
    and report.latitude is not null
    and report.longitude is not null
  order by report.reported_at desc;
$$;

revoke all on function public.get_scam_map_reports() from public;
grant execute on function public.get_scam_map_reports() to anon, authenticated;

commit;
