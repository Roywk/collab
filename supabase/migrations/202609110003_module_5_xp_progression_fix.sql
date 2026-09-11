-- Module 5 XP progression correction.
-- XP balance: 0..9999. Levels are permanent, use lifetime XP, and advance
-- every 200 XP. Failed quizzes never award XP.

create table if not exists public.learning_practice_awards (
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_key text not null,
  award_date date not null default ((now() at time zone 'Asia/Kuala_Lumpur')::date),
  xp_awarded integer not null check (xp_awarded between 1 and 50),
  attempt_count integer not null default 1,
  created_at timestamptz not null default now(),
  primary key (user_id, activity_key, award_date)
);

alter table public.learning_practice_awards
  add column if not exists attempt_count integer not null default 1;

alter table public.learning_practice_awards enable row level security;
drop policy if exists "own practice awards read" on public.learning_practice_awards;
create policy "own practice awards read" on public.learning_practice_awards
  for select to authenticated using (user_id = auth.uid());

alter table public.learning_practice_awards
  drop constraint if exists learning_practice_awards_xp_awarded_check;
alter table public.learning_practice_awards
  add constraint learning_practice_awards_xp_awarded_check
  check (xp_awarded between 1 and 50);

update public.profiles
set total_xp = least(9999, greatest(0, coalesce(total_xp, 0))),
    available_xp = least(9999, greatest(0, coalesce(available_xp, 0))),
    current_level = least(
      50,
      floor(least(9999, greatest(0, coalesce(total_xp, 0))) / 200.0)::integer + 1
    );

alter table public.profiles
  drop constraint if exists profiles_total_xp_range_check;
alter table public.profiles
  add constraint profiles_total_xp_range_check
  check (total_xp between 0 and 9999);
alter table public.profiles
  drop constraint if exists profiles_available_xp_check;
alter table public.profiles
  add constraint profiles_available_xp_check
  check (available_xp between 0 and 9999);
alter table public.profiles
  drop constraint if exists profiles_learning_level_check;
alter table public.profiles
  add constraint profiles_learning_level_check
  check (current_level between 1 and 50);

-- Old logic stored a 20 XP "best award" even when the user was below the
-- graduation line. Reset only the progress marker so their next real pass can
-- receive the complete passing reward.
update public.user_quiz_progress
set best_xp_award = 0,
    updated_at = now()
where best_score_percent < 70 and best_xp_award > 0;

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
  set total_xp = least(9999, coalesce(total_xp, 0) + xp_amount),
      available_xp = least(9999, coalesce(available_xp, 0) + xp_amount),
      current_level = least(
        50,
        floor(least(9999, coalesce(total_xp, 0) + xp_amount) / 200.0)::integer + 1
      ),
      updated_at = now()
  where id = auth.uid();
end;
$$;

create or replace function public.award_daily_practice_xp(
  target_activity_key text,
  target_xp integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  malaysia_date date := (now() at time zone 'Asia/Kuala_Lumpur')::date;
  already_awarded integer := 0;
  actual_award integer;
begin
  if auth.uid() is null or nullif(btrim(target_activity_key), '') is null
     or target_xp < 1 or target_xp > 50 then
    raise exception 'Invalid practice reward';
  end if;

  perform pg_advisory_xact_lock(
    hashtext(auth.uid()::text || ':' || btrim(target_activity_key) || ':' || malaysia_date::text)
  );

  select xp_awarded into already_awarded
  from public.learning_practice_awards
  where user_id = auth.uid()
    and activity_key = btrim(target_activity_key)
    and award_date = malaysia_date
  for update;
  already_awarded := coalesce(already_awarded, 0);

  actual_award := least(target_xp, greatest(0, 50 - already_awarded));
  if actual_award = 0 then
    return 0;
  end if;

  insert into public.learning_practice_awards (
    user_id, activity_key, award_date, xp_awarded, attempt_count
  ) values (
    auth.uid(), btrim(target_activity_key), malaysia_date, actual_award, 1
  )
  on conflict (user_id, activity_key, award_date) do update
  set xp_awarded = public.learning_practice_awards.xp_awarded + excluded.xp_awarded,
      attempt_count = public.learning_practice_awards.attempt_count + 1;

  perform public.award_learning_xp(actual_award);
  return actual_award;
end;
$$;

create or replace function public.record_quiz_attempt(
  answer_score integer,
  question_total integer,
  elapsed_seconds integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  score_percent integer;
  candidate_xp integer;
  previous_xp integer := 0;
  awarded_delta integer;
begin
  if auth.uid() is null or question_total <= 0 or answer_score < 0
     or answer_score > question_total or elapsed_seconds < 0 then
    raise exception 'Invalid quiz attempt';
  end if;

  perform pg_advisory_xact_lock(hashtext(auth.uid()::text));

  score_percent := floor(answer_score * 100.0 / question_total)::integer;
  candidate_xp := case
    when score_percent = 100 then 80
    when score_percent >= 85 then 60
    when score_percent >= 70 then 40
    else 0
  end;

  select best_xp_award into previous_xp
  from public.user_quiz_progress
  where user_id = auth.uid()
  for update;
  previous_xp := coalesce(previous_xp, 0);
  awarded_delta := greatest(0, candidate_xp - previous_xp);

  insert into public.user_quiz_progress (
    user_id, best_score_percent, best_xp_award
  ) values (
    auth.uid(), score_percent, candidate_xp
  )
  on conflict (user_id) do update
  set best_score_percent = greatest(
        public.user_quiz_progress.best_score_percent,
        excluded.best_score_percent
      ),
      best_xp_award = greatest(
        public.user_quiz_progress.best_xp_award,
        excluded.best_xp_award
      ),
      updated_at = now();

  if awarded_delta > 0 then
    perform public.award_learning_xp(awarded_delta);
  elsif score_percent = 100 then
    awarded_delta := public.award_daily_practice_xp(
      'quiz:spot-the-scam', 10
    );
  end if;

  insert into public.quiz_attempts (
    user_id, score, total_questions, time_taken_seconds, passed, xp_earned
  ) values (
    auth.uid(), answer_score, question_total, elapsed_seconds,
    score_percent >= 70, awarded_delta
  );

  return awarded_delta;
end;
$$;

create or replace function public.complete_learning_lesson_v2(
  target_lesson_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  lesson_xp integer;
  inserted_rows integer;
  practice_xp integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select xp_reward into lesson_xp
  from public.learning_lessons
  where id = target_lesson_id and status = 'published' and is_active = true;
  if lesson_xp is null then
    raise exception 'Lesson is not available';
  end if;

  insert into public.user_completed_lessons (user_id, lesson_id)
  values (auth.uid(), target_lesson_id)
  on conflict do nothing;
  get diagnostics inserted_rows = row_count;

  if inserted_rows = 1 then
    perform public.award_learning_xp(lesson_xp);
    return lesson_xp;
  end if;

  practice_xp := greatest(5, least(15, lesson_xp / 4));
  return public.award_daily_practice_xp(
    'lesson:' || target_lesson_id::text,
    practice_xp
  );
end;
$$;

create or replace function public.complete_learning_scenario_v2(
  target_scenario_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  scenario_xp integer;
  inserted_rows integer;
  practice_xp integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select xp_reward into scenario_xp
  from public.scenarios
  where id = target_scenario_id and status = 'published' and is_active = true;
  if scenario_xp is null then
    raise exception 'Scenario is not available';
  end if;

  insert into public.user_completed_scenarios (user_id, scenario_id)
  values (auth.uid(), target_scenario_id)
  on conflict do nothing;
  get diagnostics inserted_rows = row_count;

  if inserted_rows = 1 then
    perform public.award_learning_xp(scenario_xp);
    return scenario_xp;
  end if;

  practice_xp := greatest(5, least(15, scenario_xp / 5));
  return public.award_daily_practice_xp(
    'scenario:' || target_scenario_id::text,
    practice_xp
  );
end;
$$;

revoke all on function public.award_learning_xp(integer)
  from public, anon, authenticated;
revoke all on function public.award_daily_practice_xp(text, integer)
  from public, anon, authenticated;
grant execute on function public.record_quiz_attempt(integer, integer, integer)
  to authenticated;
grant execute on function public.complete_learning_lesson_v2(uuid)
  to authenticated;
grant execute on function public.complete_learning_scenario_v2(uuid)
  to authenticated;
