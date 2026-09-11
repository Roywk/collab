-- Module 5 report filters are activity types, not content-topic categories.
drop function if exists public.admin_awareness_analytics(timestamptz, timestamptz, text);

create function public.admin_awareness_analytics(
  filter_from timestamptz default null,
  filter_to timestamptz default null,
  filter_activity_type text default null
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
    select qa.user_id, p.display_name, 'Quiz', coalesce(qs.title, 'Quiz'),
      coalesce(qs.category, 'General'), qa.completed_at, null, false
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
      and (filter_activity_type is null or activity_type = filter_activity_type)
  )
  select case when public.is_awareness_admin() then jsonb_build_object(
    'lesson_completions', (select count(*) from filtered where activity_type = 'Lesson'),
    'scenario_completions', (select count(*) from filtered where activity_type = 'Scenario'),
    'quiz_attempts', (select count(*) from filtered where activity_type = 'Quiz'),
    'quiz_passes', (select count(*) from public.quiz_attempts qa
      where qa.passed
        and (filter_activity_type is null or filter_activity_type = 'Quiz')
        and (filter_from is null or qa.completed_at >= filter_from)
        and (filter_to is null or qa.completed_at < filter_to)),
    'xp_awarded', (select coalesce(sum(xp_awarded), 0)
      from public.learning_daily_awards a
      where (filter_activity_type is null
          or (filter_activity_type = 'Lesson' and a.activity_key like 'lesson:%')
          or (filter_activity_type = 'Scenario' and a.activity_key like 'scenario:%')
          or (filter_activity_type = 'Quiz' and a.activity_key like 'quiz:%'))
        and (filter_from is null or a.created_at >= filter_from)
        and (filter_to is null or a.created_at < filter_to)),
    'voucher_claims', (select count(*) from filtered where activity_type = 'Voucher'),
    'voucher_uses', (select count(*) from filtered where activity_type = 'Voucher' and voucher_used),
    'active_learners', (select count(distinct user_id) from filtered),
    'categories', '[]'::jsonb,
    'activities', coalesce((select jsonb_agg(row_data order by occurred_at desc)
      from (select * from filtered order by occurred_at desc limit 250) row_data), '[]'::jsonb)
  ) else null end;
$$;

revoke all on function public.admin_awareness_analytics(timestamptz, timestamptz, text)
  from public, anon, authenticated;
grant execute on function public.admin_awareness_analytics(timestamptz, timestamptz, text)
  to authenticated;

-- XP balance changes must reach every open learning surface immediately.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end $$;
