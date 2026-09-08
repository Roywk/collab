-- Visit 1MY development seed: profiles, banks, facilities and user links.
-- Run after the authentication, banking, SOS and Help Nearby migrations.
-- This script is idempotent and is intended for development/demo projects.
-- Verify all public hotline and facility details before production use.

create extension if not exists pgcrypto;

-- A profile must always belong to a real Supabase Auth user. Backfill any Auth
-- tourist that does not yet have a profile instead of creating orphan rows.
insert into public.profiles (
  id,
  email,
  display_name,
  phone_number,
  nationality,
  preferred_language,
  role
)
select
  auth_user.id,
  auth_user.email,
  coalesce(
    nullif(trim(auth_user.raw_user_meta_data ->> 'full_name'), ''),
    'Tourist'
  ),
  nullif(trim(auth_user.raw_user_meta_data ->> 'phone_number'), ''),
  nullif(trim(auth_user.raw_user_meta_data ->> 'nationality'), ''),
  coalesce(
    nullif(trim(auth_user.raw_user_meta_data ->> 'preferred_language'), ''),
    'English'
  ),
  'tourist'
from auth.users as auth_user
where not exists (
  select 1
  from public.admin_accounts as admin_account
  where admin_account.id = auth_user.id
)
on conflict (id) do update set
  email = coalesce(excluded.email, public.profiles.email),
  updated_at = now();

-- Fill empty/default profile fields with deterministic demo values. Existing
-- user-entered values are preserved.
with ranked_profiles as (
  select
    profile.id,
    row_number() over (order by profile.created_at, profile.id) as row_number
  from public.profiles as profile
  where not exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = profile.id
  )
)
update public.profiles as profile
set
  profile_code = coalesce(
    nullif(trim(profile.profile_code), ''),
    'USR-' || upper(replace(profile.id::text, '-', ''))
  ),
  display_name = case
    when nullif(trim(profile.display_name), '') is null
      or trim(profile.display_name) = 'Tourist'
      then 'Visit 1MY Tourist ' || lpad(ranked.row_number::text, 2, '0')
    else profile.display_name
  end,
  email = coalesce(profile.email, auth_user.email),
  phone_number = coalesce(
    nullif(trim(profile.phone_number), ''),
    '+6011' || lpad(ranked.row_number::text, 8, '0')
  ),
  nationality = coalesce(
    nullif(trim(profile.nationality), ''),
    (array[
      'Malaysia',
      'Singapore',
      'United Kingdom',
      'Australia',
      'Japan',
      'Indonesia'
    ])[1 + mod((ranked.row_number - 1)::integer, 6)]
  ),
  preferred_language = coalesce(
    nullif(trim(profile.preferred_language), ''),
    'English'
  ),
  total_xp = case
    when profile.total_xp = 0
      then mod((ranked.row_number * 125)::integer, 1500)
    else profile.total_xp
  end,
  current_level = case
    when profile.current_level = 1
      then 1 + mod((ranked.row_number - 1)::integer, 5)
    else profile.current_level
  end,
  role = 'tourist',
  updated_at = now()
from ranked_profiles as ranked
join auth.users as auth_user on auth_user.id = ranked.id
where profile.id = ranked.id;

-- Expanded bank directory. Values are development seed data; administrators
-- can amend them through Bank Hotline Management.
insert into public.banks (
  slug,
  name,
  country_code,
  country_name,
  hotline_number,
  service_type,
  target_department,
  supports_kill_switch,
  availability_label,
  is_active
)
values
  (
    'maybank', 'Maybank', 'MY', 'Malaysia', '+603-5891-4744',
    '24/7 Card Freeze & Emergency Helpline',
    'Card Emergency Services Department', true,
    'Card Freeze Available', true
  ),
  (
    'cimb-bank', 'CIMB Bank', 'MY', 'Malaysia', '+603-6204-7788',
    '24/7 Card Freeze & Emergency Helpline',
    'Consumer Contact Centre', true, '24/7 Hotline', true
  ),
  (
    'public-bank', 'Public Bank', 'MY', 'Malaysia', '+603-2176-8000',
    'Card and Account Emergency Support',
    'Card Services Department', true, 'Emergency Hotline', true
  ),
  (
    'rhb-bank', 'RHB Bank', 'MY', 'Malaysia', '+603-9206-8118',
    'Customer Contact and Card Support',
    'Customer Contact Centre', true, '24/7 Hotline', true
  ),
  (
    'hong-leong-bank', 'Hong Leong Bank', 'MY', 'Malaysia',
    '+603-7626-8899', 'Card and Digital Banking Support',
    'Customer Service Centre', true, '24/7 Hotline', true
  ),
  (
    'ambank', 'AmBank', 'MY', 'Malaysia', '+603-2178-8888',
    'Card and Account Assistance', 'Contact Centre', true,
    'Emergency Hotline', true
  ),
  (
    'bank-islam', 'Bank Islam', 'MY', 'Malaysia', '+603-2690-0900',
    'Card and Account Assistance', 'Contact Centre', true,
    'Emergency Hotline', true
  ),
  (
    'bank-rakyat', 'Bank Rakyat', 'MY', 'Malaysia', '+603-2692-4600',
    'Card and Account Assistance', 'Tele-Rakyat Contact Centre', true,
    'Customer Hotline', true
  ),
  (
    'hsbc-malaysia', 'HSBC Malaysia', 'GB', 'International',
    '+603-8321-5400', '24/7 Lost Card Assistance',
    'Card Support Centre', true, '24/7 Hotline', true
  ),
  (
    'standard-chartered-malaysia', 'Standard Chartered Malaysia', 'GB',
    'International', '+603-7711-8888', 'Card and Account Assistance',
    'Client Care Centre', true, '24/7 Hotline', true
  ),
  (
    'uob-malaysia', 'UOB Malaysia', 'SG', 'International',
    '+603-2612-8121', 'Card and Account Assistance',
    'Customer Service Centre', true, '24/7 Hotline', true
  ),
  (
    'ocbc-malaysia', 'OCBC Malaysia', 'SG', 'International',
    '+603-8317-5000', 'Card and Account Assistance',
    'Contact Centre', true, '24/7 Hotline', true
  )
on conflict (slug) do update set
  name = excluded.name,
  country_code = excluded.country_code,
  country_name = excluded.country_name,
  hotline_number = excluded.hotline_number,
  service_type = excluded.service_type,
  target_department = excluded.target_department,
  supports_kill_switch = excluded.supports_kill_switch,
  availability_label = excluded.availability_label,
  is_active = excluded.is_active,
  updated_at = now();

-- Expanded Kuala Lumpur emergency directory. These records intentionally stay
-- unverified until an administrator confirms them with the responsible agency.
insert into public.emergency_facilities (
  name,
  facility_type,
  agency_label,
  address,
  phone_number,
  latitude,
  longitude,
  availability_label,
  is_active,
  is_verified
)
values
  (
    'Balai Polis Bukit Bintang', 'police', 'PDRM POLICE',
    '45, Jalan Bukit Bintang, 55100 Kuala Lumpur', '+603-2141-9999',
    3.146783, 101.710663, 'Open 24 Hours', true, false
  ),
  (
    'Balai Polis Dang Wangi', 'police', 'PDRM POLICE',
    'Jalan Dang Wangi, 50100 Kuala Lumpur', '+603-2600-2222',
    3.156702, 101.700104, 'Open 24 Hours', true, false
  ),
  (
    'Balai Polis Travers', 'police', 'PDRM POLICE',
    'Jalan Travers, 50470 Kuala Lumpur', '+603-2274-2222',
    3.129825, 101.680543, 'Open 24 Hours', true, false
  ),
  (
    'Balai Polis Tun H.S. Lee', 'police', 'PDRM POLICE',
    'Jalan Tun H S Lee, 50000 Kuala Lumpur', '+603-2071-9999',
    3.145193, 101.696448, 'Open 24 Hours', true, false
  ),
  (
    'Bomba Jalan Hang Tuah', 'fire_rescue', 'FIRE & RESCUE',
    'Jalan Hang Tuah, 55200 Kuala Lumpur', '+603-2148-4444',
    3.139498, 101.705458, 'Open 24 Hours', true, false
  ),
  (
    'Bomba Sentul', 'fire_rescue', 'FIRE & RESCUE',
    'Jalan Tun Razak, Sentul, 51000 Kuala Lumpur', '+603-4041-4444',
    3.177716, 101.695918, 'Open 24 Hours', true, false
  ),
  (
    'Bomba Keramat', 'fire_rescue', 'FIRE & RESCUE',
    'Jalan Jelatek, 54200 Kuala Lumpur', '+603-4251-4444',
    3.169921, 101.735538, 'Open 24 Hours', true, false
  ),
  (
    'Bomba Cheras', 'fire_rescue', 'FIRE & RESCUE',
    'Jalan Yaacob Latif, 56000 Kuala Lumpur', '+603-9284-5555',
    3.118912, 101.734532, 'Open 24 Hours', true, false
  ),
  (
    'Pos RELA Changkat', 'rela', 'RELA CIVIL',
    'Changkat Bukit Bintang, 50200 Kuala Lumpur', '+603-2142-8888',
    3.147596, 101.708681, 'Limited Hours', true, false
  ),
  (
    'Pejabat RELA Wilayah Persekutuan', 'rela', 'RELA CIVIL',
    'Jalan Sultan Sulaiman, 50000 Kuala Lumpur', '+603-2273-6167',
    3.140081, 101.692332, 'Office Hours', true, false
  ),
  (
    'Pos RELA Brickfields', 'rela', 'RELA CIVIL',
    'Brickfields, 50470 Kuala Lumpur', '+603-2274-8888',
    3.130194, 101.685322, 'Limited Hours', true, false
  ),
  (
    'Pos RELA Titiwangsa', 'rela', 'RELA CIVIL',
    'Titiwangsa, 53200 Kuala Lumpur', '+603-4023-8888',
    3.177742, 101.706864, 'Limited Hours', true, false
  )
on conflict (name) do update set
  facility_type = excluded.facility_type,
  agency_label = excluded.agency_label,
  address = excluded.address,
  phone_number = excluded.phone_number,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  availability_label = excluded.availability_label,
  is_active = excluded.is_active,
  is_verified = excluded.is_verified,
  updated_at = now();

-- Give every profile a varied set of up to three active banks. Existing bank
-- links are retained. The final update supplies a primary only when missing.
with ranked_profiles as (
  select
    profile.id,
    row_number() over (order by profile.created_at, profile.id) as row_number
  from public.profiles as profile
  where not exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = profile.id
  )
),
ranked_banks as (
  select
    bank.id,
    row_number() over (order by bank.slug) as row_number,
    count(*) over () as bank_count
  from public.banks as bank
  where bank.is_active = true
),
selected_links as (
  select profile.id as user_id, bank.id as bank_id
  from ranked_profiles as profile
  join ranked_banks as bank
    on bank.row_number in (
      1 + mod((profile.row_number - 1)::integer, bank.bank_count::integer),
      1 + mod((profile.row_number + 2)::integer, bank.bank_count::integer),
      1 + mod((profile.row_number + 5)::integer, bank.bank_count::integer)
    )
)
insert into public.user_banks (user_id, bank_id, is_primary)
select selected.user_id, selected.bank_id, false
from selected_links as selected
on conflict (user_id, bank_id) do nothing;

with users_without_primary as (
  select profile.id as user_id
  from public.profiles as profile
  where not exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = profile.id
  )
  and not exists (
    select 1
    from public.user_banks as existing_primary
    where existing_primary.user_id = profile.id
      and existing_primary.is_primary = true
  )
),
chosen_primary as (
  select
    missing.user_id,
    min(link.bank_id::text)::uuid as bank_id
  from users_without_primary as missing
  join public.user_banks as link on link.user_id = missing.user_id
  group by missing.user_id
)
update public.user_banks as link
set is_primary = true
from chosen_primary as chosen
where link.user_id = chosen.user_id
  and link.bank_id = chosen.bank_id;

-- Add one primary demo emergency contact only when the profile does not already
-- have one. Generated numbers satisfy the existing E.164 validation rule.
with ranked_profiles as (
  select
    profile.id,
    profile.display_name,
    row_number() over (order by profile.created_at, profile.id) as row_number
  from public.profiles as profile
  where not exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = profile.id
  )
),
missing_contacts as (
  select ranked.*
  from ranked_profiles as ranked
  where not exists (
    select 1
    from public.emergency_contacts as contact
    where contact.user_id = ranked.id
      and contact.is_primary = true
      and contact.is_active = true
  )
)
insert into public.emergency_contacts (
  user_id,
  name,
  phone_number,
  relationship,
  is_primary,
  is_active
)
select
  profile.id,
  profile.display_name || ' Emergency Contact',
  '+6012' || lpad(profile.row_number::text, 8, '0'),
  (array['Family', 'Friend', 'Guardian'])[
    1 + mod((profile.row_number - 1)::integer, 3)
  ],
  true,
  true
from missing_contacts as profile;

-- Quick verification summary returned by the Supabase SQL Editor.
select 'profiles' as table_name, count(*) as record_count
from public.profiles
union all
select 'banks', count(*) from public.banks
union all
select 'emergency_facilities', count(*) from public.emergency_facilities
union all
select 'user_banks', count(*) from public.user_banks
union all
select 'emergency_contacts', count(*) from public.emergency_contacts
order by table_name;
