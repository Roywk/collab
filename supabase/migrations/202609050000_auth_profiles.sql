-- Visit 1MY - User profiles and role-based login
-- Supabase Auth stores passwords securely. Never create a password column in
-- public.profiles or any other public table.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  profile_code text unique,
  display_name text not null default 'Tourist',
  role text not null default 'tourist',
  email text,
  phone_number text,
  nationality text,
  preferred_language text not null default 'English',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  total_xp integer not null default 0,
  current_level integer not null default 1
);

-- Safely extend an existing profiles table if one was created earlier.
alter table public.profiles add column if not exists email text;
alter table public.profiles
  add column if not exists display_name text not null default 'Tourist';
alter table public.profiles add column if not exists phone_number text;
alter table public.profiles add column if not exists nationality text;
alter table public.profiles
  add column if not exists preferred_language text not null default 'English';
alter table public.profiles
  add column if not exists role text not null default 'tourist';
alter table public.profiles
  add column if not exists created_at timestamptz not null default now();
alter table public.profiles
  add column if not exists updated_at timestamptz not null default now();

-- Administrators use a separate authorization table. Authentication passwords
-- remain in Supabase Auth and are never copied into a public table.
create table if not exists public.admin_accounts (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  display_name text not null default 'Visit 1MY Administrator',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Preserve administrators from the legacy profiles.role design.
insert into public.admin_accounts (id, email, display_name, is_active)
select
  profile.id,
  auth_user.email,
  coalesce(nullif(trim(profile.display_name), ''), 'Visit 1MY Administrator'),
  true
from public.profiles as profile
join auth.users as auth_user on auth_user.id = profile.id
where lower(trim(profile.role)) = 'admin'
  and auth_user.email is not null
on conflict (id) do update set
  email = excluded.email,
  display_name = excluded.display_name,
  updated_at = now();

-- Restore profiles as the tourist-only account table after legacy admins have
-- been copied into admin_accounts.
alter table public.profiles
  drop constraint if exists profiles_role_check;

update public.profiles
set role = 'tourist';

alter table public.profiles alter column role set default 'tourist';
alter table public.profiles alter column role set not null;
alter table public.profiles
  add constraint profiles_role_check check (role = 'tourist');

-- Populate the new public email column from the authoritative Auth record.
update public.profiles as profile
set email = auth_user.email,
    updated_at = now()
from auth.users as auth_user
where profile.id = auth_user.id
  and auth_user.email is not null
  and profile.email is distinct from auth_user.email;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    display_name,
    phone_number,
    nationality,
    role
  )
  values (
    new.id,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      'Tourist'),
    nullif(trim(new.raw_user_meta_data ->> 'phone_number'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'nationality'), ''),
    'tourist'
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();

  -- Registration metadata is inserted server-side so it also works when
  -- email confirmation is enabled and the client receives no session yet.
  if jsonb_typeof(new.raw_user_meta_data -> 'bank_ids') = 'array' then
    insert into public.user_banks (user_id, bank_id, is_primary)
    select
      new.id,
      bank.id,
      selected.ordinality = 1
    from jsonb_array_elements_text(
      new.raw_user_meta_data -> 'bank_ids'
    ) with ordinality as selected(bank_id, ordinality)
    join public.banks as bank
      on bank.id::text = selected.bank_id
      and bank.is_active = true
    on conflict (user_id, bank_id) do update
      set is_primary = excluded.is_primary;
  elsif nullif(new.raw_user_meta_data ->> 'bank_id', '') is not null then
    -- Backward compatibility for older mobile builds.
    insert into public.user_banks (user_id, bank_id, is_primary)
    select new.id, bank.id, true
    from public.banks as bank
    where bank.id::text = new.raw_user_meta_data ->> 'bank_id'
      and bank.is_active = true
    on conflict (user_id, bank_id) do update
      set is_primary = excluded.is_primary;
  end if;

  if nullif(trim(new.raw_user_meta_data ->> 'emergency_contact_name'), '')
      is not null
    and nullif(trim(
      new.raw_user_meta_data ->> 'emergency_contact_phone'
    ), '') is not null then
    insert into public.emergency_contacts (
      user_id,
      name,
      phone_number,
      relationship,
      is_primary
    )
    values (
      new.id,
      trim(new.raw_user_meta_data ->> 'emergency_contact_name'),
      trim(new.raw_user_meta_data ->> 'emergency_contact_phone'),
      nullif(trim(
        new.raw_user_meta_data ->> 'emergency_contact_relationship'
      ), ''),
      true
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Backfill tourist profiles for Auth users created before this migration.
insert into public.profiles (id, email, display_name, role)
select
  users.id,
  users.email,
  coalesce(nullif(trim(users.raw_user_meta_data ->> 'full_name'), ''),
    'Tourist'),
  'tourist'
from auth.users as users
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.admin_accounts enable row level security;

drop policy if exists "Users can read their own profile" on public.profiles;
create policy "Users can read their own profile"
  on public.profiles
  for select
  to authenticated
  using (
    id = auth.uid()
    and not exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
    )
  );

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using (
    id = auth.uid()
    and not exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
    )
  )
  with check (
    id = auth.uid()
    and not exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
    )
  );

grant select on public.profiles to authenticated;
revoke update on public.profiles from authenticated;
grant update (
  display_name,
  phone_number,
  nationality,
  preferred_language,
  updated_at
) on public.profiles to authenticated;

drop policy if exists "Administrators can read their own account"
  on public.admin_accounts;
create policy "Administrators can read their own account"
  on public.admin_accounts
  for select
  to authenticated
  using (id = auth.uid());

revoke all on public.admin_accounts from anon, authenticated;
grant select on public.admin_accounts to authenticated;

-- ADMIN ACCOUNT SETUP:
-- 1. Create the account in Supabase Dashboard > Authentication > Users.
-- 2. Add only that trusted account to the separate admin table:
--
-- insert into public.admin_accounts (id, email, display_name)
-- select id, email, 'Visit 1MY Administrator'
-- from auth.users
-- where email = 'admin@example.com'
-- on conflict (id) do update set
--   email = excluded.email,
--   display_name = excluded.display_name,
--   is_active = true,
--   updated_at = now();
--
-- Never add a password column here. Supabase Auth stores the password hash.
