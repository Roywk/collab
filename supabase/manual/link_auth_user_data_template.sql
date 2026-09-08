-- Link one EXISTING Supabase Auth user to Visit 1MY application data.
-- First create the email/password user in Authentication > Users.
-- Then edit the values in the DECLARE section and the email in the final
-- verification query, and run this whole script.
-- Do not put the user's password in this file or in public.profiles.

do $$
declare
  account_email text := 'tourist01@example.com';
  account_name text := 'Demo Tourist 01';
  account_phone text := '+60123456781';
  account_nationality text := 'Malaysia';
  account_language text := 'English';
  selected_bank_slugs text[] := array['maybank', 'cimb-bank'];
  contact_name text := 'Demo Family Contact';
  contact_phone text := '+60187654321';
  contact_relationship text := 'Family';
  account_id uuid;
  primary_contact_id uuid;
begin
  select auth_user.id
  into account_id
  from auth.users as auth_user
  where lower(auth_user.email) = lower(account_email)
  limit 1;

  if account_id is null then
    raise exception
      'No Auth user found for %. Create it in Authentication > Users first.',
      account_email;
  end if;

  if exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = account_id
  ) then
    raise exception '% belongs to an administrator account.', account_email;
  end if;

  insert into public.profiles (
    id,
    email,
    display_name,
    phone_number,
    nationality,
    preferred_language,
    role
  )
  values (
    account_id,
    lower(account_email),
    account_name,
    account_phone,
    account_nationality,
    account_language,
    'tourist'
  )
  on conflict (id) do update set
    email = excluded.email,
    display_name = excluded.display_name,
    phone_number = excluded.phone_number,
    nationality = excluded.nationality,
    preferred_language = excluded.preferred_language,
    role = 'tourist',
    updated_at = now();

  if coalesce(array_length(selected_bank_slugs, 1), 0) = 0 then
    raise exception 'Select at least one bank slug.';
  end if;

  if exists (
    select 1
    from unnest(selected_bank_slugs) as requested(slug)
    left join public.banks as bank on bank.slug = requested.slug
    where bank.id is null
  ) then
    raise exception 'One or more selected bank slugs do not exist.';
  end if;

  update public.user_banks
  set is_primary = false
  where user_id = account_id
    and is_primary = true;

  insert into public.user_banks (user_id, bank_id, is_primary)
  select
    account_id,
    bank.id,
    requested.ordinality = 1
  from unnest(selected_bank_slugs)
    with ordinality as requested(slug, ordinality)
  join public.banks as bank on bank.slug = requested.slug
  on conflict (user_id, bank_id) do update set
    is_primary = excluded.is_primary;

  select contact.id
  into primary_contact_id
  from public.emergency_contacts as contact
  where contact.user_id = account_id
    and contact.is_primary = true
    and contact.is_active = true
  limit 1;

  if primary_contact_id is null then
    insert into public.emergency_contacts (
      user_id,
      name,
      phone_number,
      relationship,
      is_primary,
      is_active
    )
    values (
      account_id,
      contact_name,
      contact_phone,
      contact_relationship,
      true,
      true
    );
  else
    update public.emergency_contacts
    set
      name = contact_name,
      phone_number = contact_phone,
      relationship = contact_relationship,
      updated_at = now()
    where id = primary_contact_id;
  end if;
end;
$$;

-- Verify the linked account without exposing any password information.
select
  profile.id,
  profile.email,
  profile.display_name,
  profile.phone_number,
  profile.nationality,
  profile.preferred_language,
  bank.name as bank_name,
  link.is_primary as primary_bank,
  contact.name as emergency_contact,
  contact.phone_number as emergency_contact_phone
from public.profiles as profile
left join public.user_banks as link on link.user_id = profile.id
left join public.banks as bank on bank.id = link.bank_id
left join public.emergency_contacts as contact
  on contact.user_id = profile.id
  and contact.is_primary = true
  and contact.is_active = true
where lower(profile.email) = lower('tourist01@example.com')
order by link.is_primary desc, bank.name;
