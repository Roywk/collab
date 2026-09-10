-- Insert one separate emergency contact for each of the five tourist accounts.
-- These phone numbers belong to the emergency contacts, not to the tourists.
-- The user_id is resolved from each user's Supabase Authentication email.
-- Safe to rerun: existing contacts for only these five demo users are replaced.

begin;

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
      'Expected 5 Auth users but found %. Check the account emails.',
      matched_users;
  end if;
end;
$$;

-- Remove only the old emergency contacts belonging to these five demo users.
with target_users as (
  select auth_user.id
  from auth.users as auth_user
  where lower(auth_user.email) = any (array[
    'ker@gmail.com',
    'seow@gmail.com',
    'sia@gmail.com',
    'gan@gmail.com',
    'ho@gmail.com'
  ])
)
delete from public.emergency_contacts as contact
using target_users as target
where contact.user_id = target.id;

with contact_seed (
  user_email,
  emergency_contact_name,
  emergency_contact_phone,
  emergency_contact_relationship
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
  seed.emergency_contact_name,
  seed.emergency_contact_phone,
  seed.emergency_contact_relationship,
  true,
  true
from contact_seed as seed
join auth.users as auth_user
  on lower(auth_user.email) = seed.user_email;

commit;

-- Verify which emergency contact is linked to each tourist account.
select
  auth_user.email as tourist_login_email,
  profile.display_name as tourist_name,
  profile.phone_number as tourist_phone_number,
  contact.id as emergency_contact_id,
  contact.name as emergency_contact_name,
  contact.phone_number as emergency_contact_phone_number,
  contact.relationship,
  contact.is_primary,
  contact.is_active
from auth.users as auth_user
join public.profiles as profile on profile.id = auth_user.id
join public.emergency_contacts as contact on contact.user_id = auth_user.id
where lower(auth_user.email) = any (array[
  'ker@gmail.com',
  'seow@gmail.com',
  'sia@gmail.com',
  'gan@gmail.com',
  'ho@gmail.com'
])
order by auth_user.email;
