-- Visit 1MY - Module 4: Admin Bank Hotline Management
-- Run after 202608310001_module_4_emergency_banking.sql.
-- This grants bank-directory CRUD only to authenticated users with an active
-- admin_accounts row. It does not expose other users' banks.

alter table public.banks enable row level security;
alter table public.user_banks enable row level security;

drop policy if exists "Admins manage bank directory" on public.banks;
create policy "Admins manage bank directory"
  on public.banks
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

-- The admin repository checks whether a bank is referenced before deletion.
-- Admins may inspect only the bank_id link needed for that integrity check.
drop policy if exists "Admins can inspect user bank links"
  on public.user_banks;
create policy "Admins can inspect user bank links"
  on public.user_banks
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.admin_accounts
      where admin_accounts.id = auth.uid()
        and admin_accounts.is_active = true
    )
  );

grant select, insert, update, delete on public.banks to authenticated;
grant select on public.user_banks to authenticated;

-- Relationship used by the tourist app remains:
-- user_banks.user_id = auth.uid()
-- user_banks.bank_id -> banks.id
-- The mobile query joins that bank_id to banks and returns only active banks.
