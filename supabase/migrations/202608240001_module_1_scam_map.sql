-- Visit 1MY - Module 1: Scam Alert & Scam Map
-- Run this migration in the Supabase SQL editor before using Module 1.

alter table public.scam_reports
  add column if not exists title text,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_name text,
  add column if not exists is_official boolean not null default false,
  add column if not exists source_reference text,
  add column if not exists is_active boolean not null default true,
  add column if not exists published_by uuid references auth.users(id);

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
  drop constraint if exists scam_reports_verification_status_check,
  add constraint scam_reports_verification_status_check
    check (verification_status in ('Pending', 'Verified', 'Resolved', 'Fake'));

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

-- Public clients may read active map incidents only. Existing project policies
-- remain authoritative for other scam_reports operations.
alter table public.scam_reports enable row level security;

drop policy if exists "Active scam map reports are readable" on public.scam_reports;
create policy "Active scam map reports are readable"
  on public.scam_reports
  for select
  to anon, authenticated
  using (
    is_active = true
    and verification_status in ('Pending', 'Verified')
  );

drop policy if exists "Admins can publish official scam cases" on public.scam_reports;
create policy "Admins can publish official scam cases"
  on public.scam_reports
  for insert
  to authenticated
  with check (
    is_official = true
    and verification_status = 'Verified'
    and published_by = auth.uid()
    and exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
        and admin_accounts.is_active = true
    )
  );

drop policy if exists "Admins can update official scam cases" on public.scam_reports;
create policy "Admins can update official scam cases"
  on public.scam_reports
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
        and admin_accounts.is_active = true
    )
  )
  with check (
    exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
        and admin_accounts.is_active = true
    )
  );
