-- Visit 1MY - Module 4: Share My Location / SOS
-- Run this entire file once in the Supabase SQL Editor with RLS enabled.

create extension if not exists pgcrypto;

create table if not exists public.emergency_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone_number text not null,
  relationship text,
  is_primary boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint emergency_contacts_name_not_blank
    check (length(trim(name)) > 0),
  constraint emergency_contacts_phone_e164
    check (phone_number ~ '^\+[1-9][0-9]{7,14}$')
);

create unique index if not exists emergency_contacts_one_primary_per_user_idx
  on public.emergency_contacts (user_id)
  where is_primary = true and is_active = true;

create index if not exists emergency_contacts_user_active_idx
  on public.emergency_contacts (user_id, is_active);

create table if not exists public.sos_share_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  emergency_contact_id uuid not null
    references public.emergency_contacts(id) on delete restrict,
  channel text not null,
  status text not null default 'composer_opened',
  created_at timestamptz not null default now(),
  constraint sos_share_events_channel_check
    check (channel in ('whatsapp', 'sms')),
  constraint sos_share_events_status_check
    check (status in ('composer_opened'))
);

create index if not exists sos_share_events_user_created_idx
  on public.sos_share_events (user_id, created_at desc);

alter table public.emergency_contacts enable row level security;
alter table public.sos_share_events enable row level security;

drop policy if exists "Users manage their own emergency contacts"
  on public.emergency_contacts;
create policy "Users manage their own emergency contacts"
  on public.emergency_contacts
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "Users read their own SOS share events"
  on public.sos_share_events;
create policy "Users read their own SOS share events"
  on public.sos_share_events
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users record their own SOS share events"
  on public.sos_share_events;
create policy "Users record their own SOS share events"
  on public.sos_share_events
  for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1
      from public.emergency_contacts contact
      where contact.id = emergency_contact_id
        and contact.user_id = auth.uid()
        and contact.is_active = true
    )
  );

grant select, insert, update, delete on public.emergency_contacts
  to authenticated;
grant select, insert on public.sos_share_events to authenticated;

-- REGISTRATION INSERT EXAMPLE (run from the app after sign-up/sign-in):
-- await supabase.from('emergency_contacts').insert({
--   'user_id': supabase.auth.currentUser!.id,
--   'name': emergencyContactName,
--   'phone_number': emergencyContactPhoneInE164Format, // e.g. +447700900123
--   'relationship': relationship,
--   'is_primary': true,
-- });
--
-- SQL Editor test example (replace the UUID and contact values):
-- insert into public.emergency_contacts
--   (user_id, name, phone_number, relationship, is_primary)
-- values
--   ('00000000-0000-0000-0000-000000000000', 'Emergency Contact',
--    '+447700900123', 'Family', true);
