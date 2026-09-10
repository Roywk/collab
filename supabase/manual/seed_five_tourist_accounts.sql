-- Visit 1MY demo data for five existing Supabase Auth accounts.
-- Run this whole file in the Supabase SQL Editor.
--
-- Required Auth emails:
--   ker@gmail.com, seow@gmail.com, sia@gmail.com,
--   gan@gmail.com, ho@gmail.com
--
-- The script is idempotent. It replaces user_banks and emergency_contacts only
-- for these five demo users. Passwords remain exclusively in Supabase Auth.

begin;

-- Stop without changing anything unless all five login accounts already exist.
do $$
declare
  matched_users integer;
begin
  select count(*)
  into matched_users
  from auth.users as auth_user
  where lower(auth_user.email) = any (array[
    'ker@gmail.com',
    'seow@gmail.com',
    'sia@gmail.com',
    'gan@gmail.com',
    'ho@gmail.com'
  ]);

  if matched_users <> 5 then
    raise exception
      'Expected 5 Auth users but found %. Check the five email addresses.',
      matched_users;
  end if;
end;
$$;

-- Ensure the public profile data matches the five Auth accounts shown.
with profile_seed (
  email,
  profile_code,
  display_name,
  phone_number,
  nationality,
  preferred_language
) as (
  values
    (
      'ker@gmail.com', 'U0172', 'KER ZHENG FENG',
      '+601110000172', 'Malaysia', 'English'
    ),
    (
      'seow@gmail.com', 'U0173', 'SEOW KIM HUI',
      '+601110000173', 'Malaysia', 'English'
    ),
    (
      'sia@gmail.com', 'U0170', 'SIA JIN HAN',
      '+601110000170', 'Malaysia', 'English'
    ),
    (
      'gan@gmail.com', 'U0169', 'GAN KA CHUN',
      '+601110000169', 'Malaysia', 'English'
    ),
    (
      'ho@gmail.com', 'U0171', 'HO JUN JIE',
      '+601110000171', 'Malaysia', 'English'
    )
)
insert into public.profiles (
  id,
  profile_code,
  display_name,
  role,
  email,
  phone_number,
  nationality,
  preferred_language
)
select
  auth_user.id,
  seed.profile_code,
  seed.display_name,
  'tourist',
  lower(auth_user.email),
  seed.phone_number,
  seed.nationality,
  seed.preferred_language
from profile_seed as seed
join auth.users as auth_user
  on lower(auth_user.email) = seed.email
on conflict (id) do update set
  profile_code = excluded.profile_code,
  display_name = excluded.display_name,
  role = 'tourist',
  email = excluded.email,
  phone_number = excluded.phone_number,
  nationality = excluded.nationality,
  preferred_language = excluded.preferred_language,
  updated_at = now();

-- Expanded demo bank directory. Maybank and CIMB fraud numbers match their
-- official published emergency contacts. Review all other records before use
-- outside a development/demo environment.
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
    '24/7 Fraud and Account Emergency', 'Fraud Hotline', true,
    '24/7 Fraud Hotline', true
  ),
  (
    'cimb-bank', 'CIMB Bank', 'MY', 'Malaysia', '+603-6204-7788',
    '24/7 Card and Fraud Assistance', 'Consumer Contact Centre', true,
    '24/7 Hotline', true
  ),
  (
    'public-bank', 'Public Bank', 'MY', 'Malaysia', '+603-2176-8000',
    'Card and Account Emergency Support', 'Card Services Department', false,
    'Verify Before Production', true
  ),
  (
    'rhb-bank', 'RHB Bank', 'MY', 'Malaysia', '+603-9206-8118',
    'Customer Contact and Card Support', 'Customer Contact Centre', false,
    'Verify Before Production', true
  ),
  (
    'hong-leong-bank', 'Hong Leong Bank', 'MY', 'Malaysia',
    '+603-7626-8899', 'Card and Digital Banking Support',
    'Customer Service Centre', false, 'Verify Before Production', true
  ),
  (
    'ambank', 'AmBank', 'MY', 'Malaysia', '+603-2178-8888',
    'Card and Account Assistance', 'Contact Centre', false,
    'Verify Before Production', true
  ),
  (
    'bank-islam', 'Bank Islam', 'MY', 'Malaysia', '+603-2690-0900',
    'Card and Account Assistance', 'Contact Centre', false,
    'Verify Before Production', true
  ),
  (
    'bank-rakyat', 'Bank Rakyat', 'MY', 'Malaysia', '+603-2692-4600',
    'Card and Account Assistance', 'Tele-Rakyat Contact Centre', false,
    'Verify Before Production', true
  ),
  (
    'hsbc-malaysia', 'HSBC Malaysia', 'GB', 'International',
    '+603-8321-5400', 'Lost Card Assistance', 'Card Support Centre', false,
    'Verify Before Production', true
  ),
  (
    'standard-chartered-malaysia', 'Standard Chartered Malaysia', 'GB',
    'International', '+603-7711-8888', 'Card and Account Assistance',
    'Client Care Centre', false, 'Verify Before Production', true
  ),
  (
    'uob-malaysia', 'UOB Malaysia', 'SG', 'International',
    '+603-2612-8121', 'Card and Account Assistance',
    'Customer Service Centre', false, 'Verify Before Production', true
  ),
  (
    'ocbc-malaysia', 'OCBC Malaysia', 'SG', 'International',
    '+603-8317-5000', 'Card and Account Assistance', 'Contact Centre', false,
    'Verify Before Production', true
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

-- Additional Kuala Lumpur demo facilities. They remain unverified so an admin
-- can review them before production deployment.
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

-- Replace bank selections only for these five accounts. Array order determines
-- the primary bank: the first slug is primary.
with target_users as (
  select auth_user.id
  from auth.users as auth_user
  where lower(auth_user.email) = any (array[
    'ker@gmail.com', 'seow@gmail.com', 'sia@gmail.com',
    'gan@gmail.com', 'ho@gmail.com'
  ])
)
delete from public.user_banks as link
using target_users as target
where link.user_id = target.id;

with bank_assignments (email, bank_slugs) as (
  values
    ('ker@gmail.com', array['maybank', 'cimb-bank', 'rhb-bank']::text[]),
    (
      'seow@gmail.com',
      array['public-bank', 'hong-leong-bank', 'ocbc-malaysia']::text[]
    ),
    ('sia@gmail.com', array['cimb-bank', 'ambank', 'bank-islam']::text[]),
    (
      'gan@gmail.com',
      array['maybank', 'bank-rakyat', 'uob-malaysia']::text[]
    ),
    (
      'ho@gmail.com',
      array['public-bank', 'rhb-bank', 'hsbc-malaysia']::text[]
    )
)
insert into public.user_banks (user_id, bank_id, is_primary)
select
  auth_user.id,
  bank.id,
  requested.ordinality = 1
from bank_assignments as assignment
join auth.users as auth_user
  on lower(auth_user.email) = assignment.email
cross join lateral unnest(assignment.bank_slugs)
  with ordinality as requested(slug, ordinality)
join public.banks as bank on bank.slug = requested.slug;

-- Replace contacts only for the same five demo users and insert one generated
-- primary contact for each account.
with target_users as (
  select auth_user.id
  from auth.users as auth_user
  where lower(auth_user.email) = any (array[
    'ker@gmail.com', 'seow@gmail.com', 'sia@gmail.com',
    'gan@gmail.com', 'ho@gmail.com'
  ])
)
delete from public.emergency_contacts as contact
using target_users as target
where contact.user_id = target.id;

with contact_assignments (
  email,
  contact_name,
  contact_phone,
  relationship
) as (
  values
    ('ker@gmail.com', 'LIM MEI LING', '+60187650172', 'Sister'),
    ('seow@gmail.com', 'TAN WEI JIAN', '+60127340173', 'Brother'),
    ('sia@gmail.com', 'LEE AMANDA', '+60169880170', 'Family'),
    ('gan@gmail.com', 'GAN WEI MING', '+60175550169', 'Brother'),
    ('ho@gmail.com', 'CHEN JIA YI', '+60193210171', 'Friend')
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
  auth_user.id,
  assignment.contact_name,
  assignment.contact_phone,
  assignment.relationship,
  true,
  true
from contact_assignments as assignment
join auth.users as auth_user
  on lower(auth_user.email) = assignment.email;

commit;

-- Verification result: five users, their contacts and all assigned banks.
select
  profile.profile_code,
  profile.display_name,
  profile.email,
  contact.name as emergency_contact,
  contact.phone_number as emergency_contact_phone,
  string_agg(
    bank.name || case when link.is_primary then ' (Primary)' else '' end,
    ', '
    order by link.is_primary desc, bank.name
  ) as assigned_banks
from public.profiles as profile
join public.emergency_contacts as contact
  on contact.user_id = profile.id
  and contact.is_primary = true
  and contact.is_active = true
join public.user_banks as link on link.user_id = profile.id
join public.banks as bank on bank.id = link.bank_id
where lower(profile.email) = any (array[
  'ker@gmail.com', 'seow@gmail.com', 'sia@gmail.com',
  'gan@gmail.com', 'ho@gmail.com'
])
group by
  profile.profile_code,
  profile.display_name,
  profile.email,
  contact.name,
  contact.phone_number
order by profile.profile_code;
