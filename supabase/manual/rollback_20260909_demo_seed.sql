-- Roll back data created by the 2026-09-09 Visit 1MY development seed.
-- Review the preview result first. This intentionally preserves Auth users,
-- real profile emails, pre-existing Maybank/CIMB records and the original
-- Demo Emergency Contact created on 2026-09-05.

begin;

-- Preview the records identified as generated demo contacts.
select
  contact.id,
  contact.user_id,
  contact.name,
  contact.phone_number,
  contact.created_at
from public.emergency_contacts as contact
where contact.name like '% Emergency Contact'
  and contact.phone_number ~ '^\+601[23][0-9]{8}$'
order by contact.created_at;

-- Remove only contacts matching the deterministic values produced by the two
-- seed/repair scripts. Existing manually entered contacts are preserved.
delete from public.emergency_contacts as contact
where contact.name like '% Emergency Contact'
  and contact.phone_number ~ '^\+601[23][0-9]{8}$';

-- Remove links created during or after that seed window, including links to
-- pre-existing Maybank/CIMB rows. Existing older links are preserved.
with rollback_seed_context as (
  select min(bank.created_at) as seed_started_at
  from public.banks as bank
  where bank.slug in (
    'public-bank',
    'rhb-bank',
    'hong-leong-bank',
    'ambank',
    'bank-islam',
    'bank-rakyat',
    'hsbc-malaysia',
    'standard-chartered-malaysia',
    'uob-malaysia',
    'ocbc-malaysia'
  )
)
delete from public.user_banks as link
using rollback_seed_context as context
where context.seed_started_at is not null
  and link.created_at >= context.seed_started_at;

delete from public.banks
where slug in (
  'public-bank',
  'rhb-bank',
  'hong-leong-bank',
  'ambank',
  'bank-islam',
  'bank-rakyat',
  'hsbc-malaysia',
  'standard-chartered-malaysia',
  'uob-malaysia',
  'ocbc-malaysia'
);

-- Remove facilities added by the demo seed.
delete from public.emergency_facilities
where name in (
  'Balai Polis Dang Wangi',
  'Balai Polis Travers',
  'Balai Polis Tun H.S. Lee',
  'Bomba Sentul',
  'Bomba Keramat',
  'Bomba Cheras',
  'Pejabat RELA Wilayah Persekutuan',
  'Pos RELA Brickfields',
  'Pos RELA Titiwangsa'
);

-- Restore the three records that existed before the demo seed changed them.
update public.emergency_facilities
set
  phone_number = null,
  availability_label = 'Emergency service',
  is_verified = false,
  updated_at = now()
where name = 'Bomba Jalan Hang Tuah';

update public.emergency_facilities
set
  phone_number = null,
  availability_label = 'Hours unavailable',
  is_verified = false,
  updated_at = now()
where name = 'Pos RELA Changkat';

update public.emergency_facilities
set
  address = '45, Jalan Bukit Bintang, 55100 Kuala Lumpur',
  phone_number = '+603-2141-9999',
  latitude = 3.146783,
  longitude = 101.710663,
  availability_label = 'Open 24 Hours',
  is_verified = false,
  updated_at = now()
where name = 'Balai Polis Bukit Bintang';

-- Undo deterministic profile filler values while preserving emails synchronized
-- from Auth and any values that do not match the seed's exact formula.
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
  profile_code = case
    when profile.profile_code =
      'USR-' || upper(replace(profile.id::text, '-', '')) then null
    else profile.profile_code
  end,
  display_name = case
    when profile.display_name =
      'Visit 1MY Tourist ' || lpad(ranked.row_number::text, 2, '0')
      then 'Tourist'
    else profile.display_name
  end,
  phone_number = case
    when profile.phone_number =
      '+6011' || lpad(ranked.row_number::text, 8, '0') then null
    else profile.phone_number
  end,
  nationality = case
    when profile.nationality = (array[
      'Malaysia',
      'Singapore',
      'United Kingdom',
      'Australia',
      'Japan',
      'Indonesia'
    ])[1 + mod((ranked.row_number - 1)::integer, 6)] then null
    else profile.nationality
  end,
  total_xp = case
    when profile.total_xp = mod((ranked.row_number * 125)::integer, 1500)
      then 0
    else profile.total_xp
  end,
  current_level = case
    when profile.current_level =
      1 + mod((ranked.row_number - 1)::integer, 5) then 1
    else profile.current_level
  end,
  updated_at = now()
from ranked_profiles as ranked
where profile.id = ranked.id;

commit;

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
