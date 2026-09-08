-- Visit 1MY linked demo data
--
-- BEFORE RUNNING:
-- 1. Create a normal tourist in Supabase Dashboard > Authentication > Users,
--    or register one through the mobile app.
-- 2. Replace the email below with that Auth user's email.
-- 3. Run this entire file in Supabase SQL Editor.
--
-- Passwords remain in Supabase Auth. Never add a password column to profiles.

do $$
declare
  target_email constant text := 'tourist.demo@example.com'; -- CHANGE THIS
  target_user_id uuid;
  generated_profile_code text;
begin
  select auth_user.id
  into target_user_id
  from auth.users as auth_user
  where lower(auth_user.email) = lower(target_email)
  limit 1;

  if target_user_id is null then
    raise exception
      'No Supabase Auth user found for %. Create the Auth user first or change target_email.',
      target_email;
  end if;

  if exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = target_user_id
  ) then
    raise exception
      'The account % is an administrator. Use a tourist Auth account instead.',
      target_email;
  end if;

  generated_profile_code :=
    'DEMO-' || upper(substr(replace(target_user_id::text, '-', ''), 1, 8));

  -- The profile ID is exactly the same UUID as auth.users.id.
  insert into public.profiles (
    id,
    profile_code,
    display_name,
    role,
    email,
    phone_number,
    nationality,
    preferred_language,
    total_xp,
    current_level,
    updated_at
  )
  values (
    target_user_id,
    generated_profile_code,
    'Sarah Johnson',
    'tourist',
    target_email,
    '+60123456789',
    'United Kingdom',
    'English',
    120,
    2,
    now()
  )
  on conflict (id) do update set
    profile_code = excluded.profile_code,
    display_name = excluded.display_name,
    role = 'tourist',
    email = excluded.email,
    phone_number = excluded.phone_number,
    nationality = excluded.nationality,
    preferred_language = excluded.preferred_language,
    total_xp = excluded.total_xp,
    current_level = excluded.current_level,
    updated_at = now();

  -- Shared bank directory records.
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
    is_active,
    updated_at
  )
  values
    (
      'maybank',
      'Maybank',
      'MY',
      'Malaysia',
      '+603-5891-4744',
      '24/7 Card Freeze & Emergency Helpline',
      'Card Emergency Services Department',
      true,
      'Card Freeze Available',
      true,
      now()
    ),
    (
      'cimb-bank',
      'CIMB Bank',
      'MY',
      'Malaysia',
      '+603-6204-7788',
      '24/7 Card Freeze & Emergency Helpline',
      'Consumer Contact Centre',
      true,
      '24/7 Hotline',
      true,
      now()
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
    is_active = true,
    updated_at = now();

  -- Keep exactly one primary bank, then link this user to two banks.
  update public.user_banks
  set is_primary = false
  where user_id = target_user_id
    and is_primary = true;

  insert into public.user_banks (user_id, bank_id, is_primary)
  select
    target_user_id,
    bank.id,
    bank.slug = 'maybank'
  from public.banks as bank
  where bank.slug in ('maybank', 'cimb-bank')
  on conflict (user_id, bank_id) do update set
    is_primary = excluded.is_primary;

  -- Keep one active primary emergency contact for this demo user.
  update public.emergency_contacts
  set is_primary = false,
      updated_at = now()
  where user_id = target_user_id
    and is_primary = true
    and is_active = true;

  update public.emergency_contacts
  set name = 'Alex Johnson',
      relationship = 'Family',
      is_primary = true,
      is_active = true,
      updated_at = now()
  where user_id = target_user_id
    and phone_number = '+447700900123';

  if not found then
    insert into public.emergency_contacts (
      user_id,
      name,
      phone_number,
      relationship,
      is_primary,
      is_active
    )
    values (
      target_user_id,
      'Alex Johnson',
      '+447700900123',
      'Family',
      true,
      true
    );
  end if;

  -- Shared Help Nearby directory. These records are not owned by one user.
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
    is_verified,
    updated_at
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
      true,
      false,
      now()
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
      true,
      false,
      now()
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
      true,
      false,
      now()
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

  raise notice 'Linked demo data created for % (%)',
    target_email,
    target_user_id;
end;
$$;

-- Verification output: one row per user/bank link.
select
  profile.id as user_id,
  profile.profile_code,
  profile.display_name,
  profile.email,
  bank.name as bank_name,
  user_bank.is_primary,
  contact.name as emergency_contact,
  contact.phone_number as emergency_contact_phone,
  contact.relationship
from public.profiles as profile
left join public.user_banks as user_bank
  on user_bank.user_id = profile.id
left join public.banks as bank
  on bank.id = user_bank.bank_id
left join public.emergency_contacts as contact
  on contact.user_id = profile.id
  and contact.is_primary = true
  and contact.is_active = true
where lower(profile.email) = lower('tourist.demo@example.com') -- CHANGE THIS TOO
order by user_bank.is_primary desc, bank.name;

select
  name,
  facility_type,
  address,
  phone_number,
  availability_label,
  is_active,
  is_verified
from public.emergency_facilities
order by facility_type, name;
