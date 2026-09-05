-- Optional local/demo account metadata.
--
-- First create these two users in Supabase Dashboard > Authentication > Users:
--   tourist.demo@visit1my.test
--   admin.demo@visit1my.test
-- Choose temporary passwords in Supabase Auth. Never store those passwords in
-- this file or in any public table. Then run this seed in the SQL Editor.

update public.profiles as profile
set
  email = auth_user.email,
  display_name = 'Demo Tourist',
  role = 'tourist',
  nationality = 'United Kingdom',
  preferred_language = 'English',
  updated_at = now()
from auth.users as auth_user
where profile.id = auth_user.id
  and lower(auth_user.email) = 'tourist.demo@visit1my.test';

insert into public.admin_accounts (id, email, display_name, is_active)
select
  auth_user.id,
  auth_user.email,
  'Demo Administrator',
  true
from auth.users as auth_user
where lower(auth_user.email) = 'admin.demo@visit1my.test'
on conflict (id) do update set
  email = excluded.email,
  display_name = excluded.display_name,
  is_active = true,
  updated_at = now();

-- Give the demo tourist a primary bank when the Maybank seed exists.
insert into public.user_banks (user_id, bank_id, is_primary)
select auth_user.id, bank.id, true
from auth.users as auth_user
cross join public.banks as bank
where lower(auth_user.email) = 'tourist.demo@visit1my.test'
  and bank.slug = 'maybank'
on conflict (user_id, bank_id) do update
  set is_primary = excluded.is_primary;

-- Add a non-production SOS contact for the demo tourist.
insert into public.emergency_contacts (
  user_id,
  name,
  phone_number,
  relationship,
  is_primary
)
select
  auth_user.id,
  'Demo Emergency Contact',
  '+60111111111',
  'Family',
  true
from auth.users as auth_user
where lower(auth_user.email) = 'tourist.demo@visit1my.test'
  and not exists (
    select 1
    from public.emergency_contacts as contact
    where contact.user_id = auth_user.id
      and contact.is_primary = true
      and contact.is_active = true
  );
