-- Visit 1MY repair: synchronize Auth emails and create missing user contacts.
-- Safe to run repeatedly after 202609090001_seed_profile_banks_facilities.sql.

-- Public profiles mirror the email from the authoritative Auth account.
update public.profiles as profile
set
  email = auth_user.email,
  updated_at = now()
from auth.users as auth_user
where profile.id = auth_user.id
  and auth_user.email is not null
  and profile.email is distinct from auth_user.email;

-- Add one active primary emergency contact for every tourist profile that does
-- not already have one. Existing contacts are never overwritten.
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
  case
    when nullif(trim(profile.display_name), '') is null
      then 'Demo Emergency Contact'
    else profile.display_name || ' Emergency Contact'
  end,
  '+6013' || lpad(profile.row_number::text, 8, '0'),
  (array['Family', 'Friend', 'Guardian'])[
    1 + mod((profile.row_number - 1)::integer, 3)
  ],
  true,
  true
from missing_contacts as profile;

-- Report which profiles can use this app's email/password login. Rows marked
-- NO_EMAIL_AUTH need an email-based user created in Authentication > Users.
select
  profile.id,
  profile.profile_code,
  profile.display_name,
  auth_user.email as auth_email,
  case
    when auth_user.email is null then 'NO_EMAIL_AUTH'
    when auth_user.encrypted_password is null
      or auth_user.encrypted_password = '' then 'NO_PASSWORD'
    else 'LOGIN_READY'
  end as login_status,
  count(contact.id) filter (
    where contact.is_active = true
  ) as active_emergency_contacts
from public.profiles as profile
join auth.users as auth_user on auth_user.id = profile.id
left join public.emergency_contacts as contact on contact.user_id = profile.id
where not exists (
  select 1
  from public.admin_accounts as admin_account
  where admin_account.id = profile.id
)
group by
  profile.id,
  profile.profile_code,
  profile.display_name,
  auth_user.email,
  auth_user.encrypted_password
order by profile.profile_code nulls last, profile.created_at;
