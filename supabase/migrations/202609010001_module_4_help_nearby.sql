-- Visit 1MY - Module 4: Help Nearby
-- Run in the Supabase SQL Editor and keep RLS enabled.

create table if not exists public.emergency_facilities (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  facility_type text not null,
  agency_label text not null,
  address text not null,
  phone_number text,
  latitude double precision not null,
  longitude double precision not null,
  availability_label text not null default 'Hours unavailable',
  is_active boolean not null default true,
  is_verified boolean not null default false,
  source_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint emergency_facilities_type_check
    check (facility_type in ('police', 'fire_rescue', 'rela')),
  constraint emergency_facilities_latitude_check
    check (latitude between -90 and 90),
  constraint emergency_facilities_longitude_check
    check (longitude between -180 and 180)
);

create index if not exists emergency_facilities_active_type_idx
  on public.emergency_facilities (is_active, facility_type);

alter table public.emergency_facilities enable row level security;

drop policy if exists "Authenticated users can read active emergency facilities"
  on public.emergency_facilities;
create policy "Authenticated users can read active emergency facilities"
  on public.emergency_facilities
  for select
  to authenticated
  using (is_active = true);

grant select on public.emergency_facilities to authenticated;

-- Prototype directory entries matching the supplied Help Nearby UI.
-- Verify contact details, coordinates, operating hours, and source URLs with
-- the relevant agency before setting is_verified = true in production.
insert into public.emergency_facilities (
  name,
  facility_type,
  agency_label,
  address,
  phone_number,
  latitude,
  longitude,
  availability_label,
  is_verified
)
values
  (
    'Balai Polis Bukit Bintang',
    'police',
    'PDRM POLICE',
    '45, Jalan Bukit Bintang, 55100 Kuala Lumpur',
    '+603-2141-9999',
    3.146783,
    101.710663,
    'Open 24 Hours',
    false
  ),
  (
    'Bomba Jalan Hang Tuah',
    'fire_rescue',
    'FIRE & RESCUE',
    'Jalan Hang Tuah, 55200 Kuala Lumpur',
    null,
    3.139498,
    101.705458,
    'Emergency service',
    false
  ),
  (
    'Pos RELA Changkat',
    'rela',
    'RELA CIVIL',
    'Changkat Bukit Bintang, 50200 Kuala Lumpur',
    null,
    3.147596,
    101.708681,
    'Hours unavailable',
    false
  )
on conflict (name) do update set
  facility_type = excluded.facility_type,
  agency_label = excluded.agency_label,
  address = excluded.address,
  phone_number = excluded.phone_number,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  availability_label = excluded.availability_label,
  is_active = true,
  updated_at = now();
