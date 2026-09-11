-- Module 5 refinement: Level 0 onboarding, partner evidence, atomic inventory,
-- and administrator learning analytics. Run after 202609110004.

alter table public.profiles alter column current_level set default 0;
alter table public.profiles drop constraint if exists profiles_current_level_check;
alter table public.profiles add constraint profiles_current_level_check
  check (current_level between 0 and 50);
update public.profiles
set current_level = least(50, floor(greatest(coalesce(total_xp, 0), 0) / 200.0)::integer),
    updated_at = now()
where current_level is distinct from
  least(50, floor(greatest(coalesce(total_xp, 0), 0) / 200.0)::integer);

create or replace function public.award_learning_xp(xp_amount integer)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or xp_amount <= 0 or xp_amount > 500 then
    raise exception 'Invalid XP award';
  end if;
  update public.profiles
  set total_xp = coalesce(total_xp, 0) + xp_amount,
      available_xp = coalesce(available_xp, 0) + xp_amount,
      current_level = least(50,
        floor((coalesce(total_xp, 0) + xp_amount) / 200.0)::integer),
      updated_at = now()
  where id = auth.uid();
end;
$$;
revoke all on function public.award_learning_xp(integer)
  from public, anon, authenticated;

create table if not exists public.reward_partner_evidence (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references public.reward_partners(id) on delete cascade,
  file_name text not null,
  file_url text not null,
  uploaded_by uuid references public.admin_accounts(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (partner_id, file_url)
);
create index if not exists reward_partner_evidence_partner_idx
  on public.reward_partner_evidence(partner_id, created_at desc);
alter table public.reward_partner_evidence enable row level security;
drop policy if exists "partner evidence admin access" on public.reward_partner_evidence;
create policy "partner evidence admin access" on public.reward_partner_evidence
  for all to authenticated using (public.is_awareness_admin())
  with check (public.is_awareness_admin());

create or replace function public.enforce_partner_evidence_on_verification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.verification_status = 'verified' and not exists (
    select 1 from public.reward_partner_evidence e where e.partner_id = new.id
  ) then
    raise exception 'At least one verification evidence image is required before verification';
  end if;
  return new;
end;
$$;
drop trigger if exists reward_partner_evidence_required on public.reward_partners;
create constraint trigger reward_partner_evidence_required
after insert or update of verification_status on public.reward_partners
deferrable initially deferred for each row
execute function public.enforce_partner_evidence_on_verification();

create or replace function public.admin_replace_voucher_codes(
  target_voucher_id uuid,
  supplied_codes text[]
)
returns table(total_codes integer, available_codes integer, claimed_codes integer)
language plpgsql
security definer
set search_path = public
as $$
declare clean_codes text[];
begin
  if not public.is_awareness_admin() then
    raise exception 'Administrator access required';
  end if;
  select coalesce(array_agg(distinct upper(btrim(code))), array[]::text[])
  into clean_codes
  from unnest(coalesce(supplied_codes, array[]::text[])) code
  where nullif(btrim(code), '') is not null;

  if exists (
    select 1 from public.voucher_codes vc
    where vc.code = any(clean_codes) and vc.voucher_id <> target_voucher_id
  ) then
    raise exception 'A supplied voucher code already belongs to another reward';
  end if;

  insert into public.voucher_codes(voucher_id, code)
  select target_voucher_id, code from unnest(clean_codes) code
  on conflict (code) do nothing;
  update public.voucher_codes set status = 'available'
  where voucher_id = target_voucher_id and status = 'disabled'
    and code = any(clean_codes);
  update public.voucher_codes set status = 'disabled'
  where voucher_id = target_voucher_id and status = 'available'
    and not (code = any(clean_codes));

  return query select
    count(*)::integer,
    count(*) filter (where status = 'available')::integer,
    count(*) filter (where status = 'claimed')::integer
  from public.voucher_codes where voucher_id = target_voucher_id;
end;
$$;
revoke all on function public.admin_replace_voucher_codes(uuid, text[])
  from public, anon, authenticated;
grant execute on function public.admin_replace_voucher_codes(uuid, text[])
  to authenticated;

create or replace function public.admin_awareness_analytics()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case when public.is_awareness_admin() then jsonb_build_object(
    'lesson_completions', (select count(*) from public.user_completed_lessons),
    'scenario_completions', (select count(*) from public.user_completed_scenarios),
    'quiz_attempts', (select count(*) from public.quiz_attempts),
    'quiz_passes', (select count(*) from public.quiz_attempts where passed),
    'xp_awarded', (select coalesce(sum(xp_awarded), 0) from public.learning_daily_awards),
    'voucher_claims', (select count(*) from public.user_claimed_vouchers),
    'active_learners', (select count(distinct user_id) from public.learning_daily_awards),
    'recent_claims', coalesce((select jsonb_agg(row_data order by claimed_at desc)
      from (select p.display_name, rv.title, rv.partner_name,
                   ucv.full_promo_code, vc.claimed_at
            from public.user_claimed_vouchers ucv
            join public.profiles p on p.id = ucv.user_id
            join public.reward_vouchers rv on rv.id = ucv.voucher_id
            left join public.voucher_codes vc on vc.id = ucv.voucher_code_id
            order by vc.claimed_at desc nulls last limit 20) row_data), '[]'::jsonb)
  ) else null end;
$$;
revoke all on function public.admin_awareness_analytics()
  from public, anon, authenticated;
grant execute on function public.admin_awareness_analytics() to authenticated;

do $$
declare target_table text;
begin
  foreach target_table in array array[
    'reward_partner_evidence', 'user_completed_lessons',
    'user_completed_scenarios', 'quiz_attempts'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = target_table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I', target_table
      );
    end if;
  end loop;
end $$;
