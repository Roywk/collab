-- Allow administrators to archive notifications while travellers continue to
-- read active announcements only. This changes policies only; no data changes.

begin;

drop policy if exists traveller_notifications_public_read
  on public.traveller_notifications;
drop policy if exists traveller_notifications_anon_read
  on public.traveller_notifications;
drop policy if exists traveller_notifications_authenticated_read
  on public.traveller_notifications;

create policy traveller_notifications_anon_read
  on public.traveller_notifications
  for select
  to anon
  using (is_active = true);

create policy traveller_notifications_authenticated_read
  on public.traveller_notifications
  for select
  to authenticated
  using (is_active = true or public.is_admin() is true);

commit;
