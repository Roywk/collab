-- Visit 1MY - administrator announcements displayed by the traveller app bell.

begin;

create table if not exists public.traveller_notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(trim(title)) between 3 and 100),
  message text not null check (char_length(trim(message)) between 3 and 500),
  severity text not null default 'Information'
    check (severity in ('Information', 'Warning', 'Critical')),
  published_by uuid references auth.users(id) on delete set null
    default auth.uid(),
  published_at timestamp with time zone not null default now(),
  is_active boolean not null default true
);

create index if not exists traveller_notifications_active_published_idx
  on public.traveller_notifications (is_active, published_at desc);

alter table public.traveller_notifications enable row level security;

drop policy if exists traveller_notifications_public_read
  on public.traveller_notifications;
create policy traveller_notifications_public_read
  on public.traveller_notifications
  for select
  to anon, authenticated
  using (is_active = true);

drop policy if exists traveller_notifications_admin_insert
  on public.traveller_notifications;
create policy traveller_notifications_admin_insert
  on public.traveller_notifications
  for insert
  to authenticated
  with check (public.is_admin() is true and published_by = auth.uid());

drop policy if exists traveller_notifications_admin_update
  on public.traveller_notifications;
create policy traveller_notifications_admin_update
  on public.traveller_notifications
  for update
  to authenticated
  using (public.is_admin() is true)
  with check (public.is_admin() is true);

commit;
