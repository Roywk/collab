-- Visit 1MY - Module 4: Emergency Assistance / Bank Kill Switch
-- Run the entire file once in the Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.banks (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  country_code char(2) not null,
  country_name text not null,
  hotline_number text not null,
  service_type text not null,
  target_department text not null,
  supports_kill_switch boolean not null default true,
  availability_label text not null default 'Emergency Hotline',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint banks_slug_format check (slug ~ '^[a-z0-9-]+$'),
  constraint banks_country_code_format check (country_code ~ '^[A-Z]{2}$'),
  constraint banks_hotline_not_blank check (length(trim(hotline_number)) > 0)
);

create table if not exists public.user_banks (
  user_id uuid not null references auth.users(id) on delete cascade,
  bank_id uuid not null references public.banks(id) on delete restrict,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, bank_id)
);

-- A user can register several banks, but only one can be their primary bank.
create unique index if not exists user_banks_one_primary_per_user_idx
  on public.user_banks (user_id)
  where is_primary = true;

create index if not exists user_banks_user_id_idx
  on public.user_banks (user_id);

create table if not exists public.kill_switch_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  bank_id uuid not null references public.banks(id) on delete restrict,
  hotline_number text not null,
  status text not null default 'dialer_opened',
  requested_at timestamptz not null default now(),
  constraint kill_switch_status_check
    check (status in ('dialer_opened', 'call_started', 'cancelled'))
);

create index if not exists kill_switch_requests_user_requested_idx
  on public.kill_switch_requests (user_id, requested_at desc);

alter table public.banks enable row level security;
alter table public.user_banks enable row level security;
alter table public.kill_switch_requests enable row level security;

drop policy if exists "Active banks are readable" on public.banks;
create policy "Active banks are readable"
  on public.banks
  for select
  to anon, authenticated
  using (is_active = true);

drop policy if exists "Users can read their registered banks" on public.user_banks;
create policy "Users can read their registered banks"
  on public.user_banks
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can register their own banks" on public.user_banks;
create policy "Users can register their own banks"
  on public.user_banks
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can update their own banks" on public.user_banks;
create policy "Users can update their own banks"
  on public.user_banks
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "Users can remove their own banks" on public.user_banks;
create policy "Users can remove their own banks"
  on public.user_banks
  for delete
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can log their own kill switch calls"
  on public.kill_switch_requests;
create policy "Users can log their own kill switch calls"
  on public.kill_switch_requests
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can read their own kill switch calls"
  on public.kill_switch_requests;
create policy "Users can read their own kill switch calls"
  on public.kill_switch_requests
  for select
  to authenticated
  using (user_id = auth.uid());

grant select on public.banks to anon, authenticated;
grant select, insert, update, delete on public.user_banks to authenticated;
grant select, insert on public.kill_switch_requests to authenticated;

-- Hotline seed data shown in the supplied UI. The app reads these values from
-- Supabase; it does not contain any hard-coded bank or phone-number fallback.
insert into public.banks (
  slug,
  name,
  country_code,
  country_name,
  hotline_number,
  service_type,
  target_department,
  supports_kill_switch,
  availability_label
)
values
  (
    'maybank',
    'Maybank',
    'MY',
    'Malaysian Operations',
    '+603-5891-4744',
    '24/7 Card Freeze & Emergency Helpline',
    'Card Emergency Services Department',
    true,
    'Card Freeze Available'
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
    '24/7 Hotline'
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

-- REGISTRATION INSERT (run from the app after sign-up/sign-in):
--
-- await supabase.from('user_banks').insert({
--   'user_id': supabase.auth.currentUser!.id,
--   'bank_id': selectedBankId,
--   'is_primary': true,
-- });
--
-- SQL Editor test example (replace the UUID with an auth.users id):
-- insert into public.user_banks (user_id, bank_id, is_primary)
-- select '00000000-0000-0000-0000-000000000000'::uuid, id, true
-- from public.banks
-- where slug = 'maybank'
-- on conflict (user_id, bank_id)
-- do update set is_primary = excluded.is_primary;
