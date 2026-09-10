-- Visit 1MY - Module 1 compatibility with the separate admin_accounts table.
-- This migration does not recreate tables or delete application data.

begin;

-- The authentication migration moves administrator authorization out of
-- profiles.role. Keep the existing scam_reports RLS policies and Module 1
-- trigger working by making their shared helper use admin_accounts.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_accounts as admin_account
    where admin_account.id = (select auth.uid())
      and admin_account.is_active = true
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

commit;
