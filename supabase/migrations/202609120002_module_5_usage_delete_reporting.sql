-- Module 5 voucher usage, complete administrator deletion and detailed audit.
-- Run after 202609120001.

alter table public.user_claimed_vouchers
  add column if not exists used_at timestamptz;

create or replace function public.use_claimed_voucher(target_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare claim_row record;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select ucv.id, ucv.used_at, rv.title, rv.discount_amount, rv.partner_name
  into claim_row
  from public.user_claimed_vouchers ucv
  join public.reward_vouchers rv on rv.id = ucv.voucher_id
  where ucv.user_id = auth.uid()
    and upper(btrim(ucv.full_promo_code)) = upper(btrim(target_code))
  for update of ucv;
  if claim_row.id is null then
    raise exception 'This voucher code is not assigned to your account';
  end if;
  if claim_row.used_at is not null then
    raise exception 'This voucher has already been used';
  end if;
  update public.user_claimed_vouchers set used_at = now()
  where id = claim_row.id;
  return jsonb_build_object(
    'title', claim_row.title,
    'benefit', claim_row.discount_amount,
    'partner_name', claim_row.partner_name,
    'used_at', now()
  );
end;
$$;
revoke all on function public.use_claimed_voucher(text)
  from public, anon, authenticated;
grant execute on function public.use_claimed_voucher(text) to authenticated;

create or replace function public.admin_delete_reward_voucher(target_voucher_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_awareness_admin() then raise exception 'Administrator access required'; end if;
  delete from public.user_claimed_vouchers where voucher_id = target_voucher_id;
  delete from public.voucher_codes where voucher_id = target_voucher_id;
  delete from public.reward_vouchers where id = target_voucher_id;
end;
$$;

create or replace function public.admin_delete_reward_partner(target_partner_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare voucher_id uuid;
begin
  if not public.is_awareness_admin() then raise exception 'Administrator access required'; end if;
  for voucher_id in select id from public.reward_vouchers where partner_id = target_partner_id loop
    perform public.admin_delete_reward_voucher(voucher_id);
  end loop;
  delete from public.reward_partner_evidence where partner_id = target_partner_id;
  delete from public.reward_partners where id = target_partner_id;
end;
$$;
revoke all on function public.admin_delete_reward_voucher(uuid)
  from public, anon, authenticated;
revoke all on function public.admin_delete_reward_partner(uuid)
  from public, anon, authenticated;
grant execute on function public.admin_delete_reward_voucher(uuid) to authenticated;
grant execute on function public.admin_delete_reward_partner(uuid) to authenticated;

drop function if exists public.admin_awareness_analytics();
create or replace function public.admin_awareness_analytics(
  filter_from timestamptz default null,
  filter_to timestamptz default null,
  filter_category text default null
)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  with activity as (
    select ucl.user_id, p.display_name, 'Lesson'::text activity_type,
      ll.title content_title, ll.category, ucl.completed_at occurred_at,
      null::text voucher_code, false voucher_used
    from public.user_completed_lessons ucl
    join public.profiles p on p.id = ucl.user_id
    join public.learning_lessons ll on ll.id = ucl.lesson_id
    union all
    select ucs.user_id, p.display_name, 'Scenario', s.title, s.category,
      ucs.completed_at, null, false
    from public.user_completed_scenarios ucs
    join public.profiles p on p.id = ucs.user_id
    join public.scenarios s on s.id = ucs.scenario_id
    union all
    select qa.user_id, p.display_name, 'Quiz', qs.title, qs.category,
      qa.completed_at, null, false
    from public.quiz_attempts qa
    join public.profiles p on p.id = qa.user_id
    left join public.quiz_sets qs on qs.id = qa.quiz_set_id
    union all
    select ucv.user_id, p.display_name, 'Voucher', rv.title,
      coalesce(rp.category, 'Reward'), coalesce(vc.claimed_at, rv.created_at),
      ucv.full_promo_code, ucv.used_at is not null
    from public.user_claimed_vouchers ucv
    join public.profiles p on p.id = ucv.user_id
    join public.reward_vouchers rv on rv.id = ucv.voucher_id
    left join public.reward_partners rp on rp.id = rv.partner_id
    left join public.voucher_codes vc on vc.id = ucv.voucher_code_id
  ), filtered as (
    select * from activity
    where (filter_from is null or occurred_at >= filter_from)
      and (filter_to is null or occurred_at < filter_to)
      and (filter_category is null or category = filter_category)
  )
  select case when public.is_awareness_admin() then jsonb_build_object(
    'lesson_completions', (select count(*) from filtered where activity_type = 'Lesson'),
    'scenario_completions', (select count(*) from filtered where activity_type = 'Scenario'),
    'quiz_attempts', (select count(*) from filtered where activity_type = 'Quiz'),
    'quiz_passes', (select count(*) from public.quiz_attempts qa
      left join public.quiz_sets qs on qs.id = qa.quiz_set_id
      where qa.passed and (filter_from is null or qa.completed_at >= filter_from)
        and (filter_to is null or qa.completed_at < filter_to)
        and (filter_category is null or qs.category = filter_category)),
    'xp_awarded', (select coalesce(sum(xp_awarded), 0)
      from public.learning_daily_awards a
      where (filter_from is null or a.created_at >= filter_from)
        and (filter_to is null or a.created_at < filter_to)),
    'voucher_claims', (select count(*) from filtered where activity_type = 'Voucher'),
    'voucher_uses', (select count(*) from filtered where activity_type = 'Voucher' and voucher_used),
    'active_learners', (select count(distinct user_id) from filtered),
    'categories', coalesce((select jsonb_agg(category order by category)
      from (select distinct category from activity where category is not null) c), '[]'::jsonb),
    'activities', coalesce((select jsonb_agg(row_data order by occurred_at desc)
      from (select * from filtered order by occurred_at desc limit 250) row_data), '[]'::jsonb)
  ) else null end;
$$;
revoke all on function public.admin_awareness_analytics(timestamptz, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.admin_awareness_analytics(timestamptz, timestamptz, text)
  to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = 'user_claimed_vouchers'
  ) then
    alter publication supabase_realtime add table public.user_claimed_vouchers;
  end if;
end $$;
