-- Visit 1MY - Module 4: Admin Emergency Facility Management
-- Run after 202609010001_module_4_help_nearby.sql.

alter table public.emergency_facilities enable row level security;

drop policy if exists "Admins manage emergency facility directory"
  on public.emergency_facilities;
create policy "Admins manage emergency facility directory"
  on public.emergency_facilities
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
        and admin_accounts.is_active = true
    )
  )
  with check (
    exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
        and admin_accounts.is_active = true
    )
  );

grant select, insert, update, delete on public.emergency_facilities
  to authenticated;

-- The existing authenticated-user SELECT policy continues to expose only
-- active rows to the mobile Help Nearby service. Admins can also see inactive
-- rows through the policy above.
