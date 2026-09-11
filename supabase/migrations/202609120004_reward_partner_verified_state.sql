-- A verified sponsor must be active to satisfy the voucher deployment policy.
-- Repair legacy rows that were visually verified but remained suspended.
update public.reward_partners
set is_active = true,
    updated_at = now()
where verification_status = 'verified'
  and is_active is not true;

alter table public.reward_partners
  drop constraint if exists reward_partners_verified_active_check;
alter table public.reward_partners
  add constraint reward_partners_verified_active_check
  check (verification_status <> 'verified' or is_active = true);
