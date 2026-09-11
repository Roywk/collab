-- Module 5 professional CMS upgrade.
-- Run this entire migration once in the Supabase SQL Editor after 202609110003.
-- It adds grouped quizzes, direct CMS media uploads, configurable geofences,
-- realtime refresh, and one XP award per activity per Malaysia calendar day.

create sequence if not exists public.quiz_set_code_seq start 1;

create table if not exists public.quiz_sets (
  id uuid primary key default gen_random_uuid(),
  quiz_code text not null default (
    'QIZ-' || lpad(nextval('public.quiz_set_code_seq')::text, 6, '0')
  ),
  title text not null,
  description text not null,
  category text not null default 'General',
  difficulty text not null default 'Beginner',
  xp_reward integer not null default 80 check (xp_reward between 1 and 500),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  is_active boolean not null default false,
  sort_order integer not null default 0,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists quiz_sets_quiz_code_key
  on public.quiz_sets(quiz_code);
create unique index if not exists quiz_sets_unique_title_key
  on public.quiz_sets(lower(btrim(title)));
create index if not exists quiz_sets_status_order_idx
  on public.quiz_sets(status, sort_order, updated_at desc);

alter table public.quiz_questions
  add column if not exists quiz_set_id uuid
    references public.quiz_sets(id) on delete cascade,
  add column if not exists question_order integer not null default 0;

do $$
declare
  legacy_set_id uuid;
begin
  if exists (
    select 1 from public.quiz_questions where quiz_set_id is null
  ) then
    select id into legacy_set_id
    from public.quiz_sets
    where lower(btrim(title)) = lower('Spot the Scam Essentials')
    limit 1;

    if legacy_set_id is null then
      insert into public.quiz_sets (
        title, description, category, difficulty, xp_reward,
        status, is_active, published_at
      ) values (
        'Spot the Scam Essentials',
        'Practise recognising suspicious payment screens, QR codes, and phishing links.',
        'General', 'Beginner', 80,
        case when exists (
          select 1 from public.quiz_questions
          where status = 'published' and is_active = true
        ) then 'published' else 'draft' end,
        exists (
          select 1 from public.quiz_questions
          where status = 'published' and is_active = true
        ),
        case when exists (
          select 1 from public.quiz_questions
          where status = 'published' and is_active = true
        ) then now() else null end
      ) returning id into legacy_set_id;
    end if;

    update public.quiz_questions as target
    set quiz_set_id = legacy_set_id,
        question_order = coalesce(nullif(target.sort_order, 0),
          row_number_value::integer * 10)
    from (
      select id, row_number() over (order by sort_order, created_at, id)
        as row_number_value
      from public.quiz_questions
      where quiz_set_id is null
    ) ordered
    where target.id = ordered.id;
  end if;
end;
$$;

alter table public.quiz_questions alter column quiz_set_id set not null;
drop index if exists public.quiz_questions_unique_question_key;
create unique index if not exists quiz_questions_unique_in_set_key
  on public.quiz_questions(quiz_set_id, lower(btrim(question)));
create index if not exists quiz_questions_set_order_idx
  on public.quiz_questions(quiz_set_id, question_order);

alter table public.learning_lessons
  add column if not exists hotspot_radius_meters integer not null default 250;
alter table public.learning_lessons
  drop constraint if exists learning_lessons_hotspot_radius_check;
alter table public.learning_lessons
  add constraint learning_lessons_hotspot_radius_check
  check (hotspot_radius_meters between 50 and 5000);

alter table public.quiz_attempts
  add column if not exists quiz_set_id uuid
    references public.quiz_sets(id) on delete set null;
create index if not exists quiz_attempts_user_set_date_idx
  on public.quiz_attempts(user_id, quiz_set_id, completed_at desc);

create table if not exists public.user_quiz_set_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  quiz_set_id uuid not null references public.quiz_sets(id) on delete cascade,
  best_score_percent integer not null default 0
    check (best_score_percent between 0 and 100),
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, quiz_set_id)
);

create table if not exists public.learning_daily_awards (
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_key text not null,
  award_date date not null default
    ((now() at time zone 'Asia/Kuala_Lumpur')::date),
  xp_awarded integer not null check (xp_awarded between 1 and 500),
  created_at timestamptz not null default now(),
  primary key (user_id, activity_key, award_date)
);

-- Preserve today's already-earned state while moving from the older reward
-- functions, without adding XP a second time during this migration.
insert into public.learning_daily_awards (
  user_id, activity_key, award_date, xp_awarded, created_at
)
select completed.user_id, 'lesson:' || completed.lesson_id::text,
       (completed.completed_at at time zone 'Asia/Kuala_Lumpur')::date,
       least(500, greatest(1, lesson.xp_reward)), completed.completed_at
from public.user_completed_lessons completed
join public.learning_lessons lesson on lesson.id = completed.lesson_id
where (completed.completed_at at time zone 'Asia/Kuala_Lumpur')::date =
      (now() at time zone 'Asia/Kuala_Lumpur')::date
on conflict do nothing;

insert into public.learning_daily_awards (
  user_id, activity_key, award_date, xp_awarded, created_at
)
select completed.user_id, 'scenario:' || completed.scenario_id::text,
       (completed.completed_at at time zone 'Asia/Kuala_Lumpur')::date,
       least(500, greatest(1, scenario.xp_reward)), completed.completed_at
from public.user_completed_scenarios completed
join public.scenarios scenario on scenario.id = completed.scenario_id
where (completed.completed_at at time zone 'Asia/Kuala_Lumpur')::date =
      (now() at time zone 'Asia/Kuala_Lumpur')::date
on conflict do nothing;

insert into public.learning_daily_awards (
  user_id, activity_key, award_date, xp_awarded, created_at
)
select attempt.user_id, 'quiz:' || attempt.quiz_set_id::text,
       (attempt.completed_at at time zone 'Asia/Kuala_Lumpur')::date,
       least(500, greatest(1, quiz.xp_reward)), attempt.completed_at
from public.quiz_attempts attempt
join public.quiz_sets quiz on quiz.id = attempt.quiz_set_id
where attempt.passed = true
  and (attempt.completed_at at time zone 'Asia/Kuala_Lumpur')::date =
      (now() at time zone 'Asia/Kuala_Lumpur')::date
on conflict do nothing;

alter table public.quiz_sets enable row level security;
alter table public.user_quiz_set_progress enable row level security;
alter table public.learning_daily_awards enable row level security;

drop policy if exists "published quiz sets read" on public.quiz_sets;
create policy "published quiz sets read" on public.quiz_sets
  for select to authenticated
  using ((status = 'published' and is_active = true) or public.is_awareness_admin());
drop policy if exists "quiz sets admin write" on public.quiz_sets;
create policy "quiz sets admin write" on public.quiz_sets
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "own quiz set progress" on public.user_quiz_set_progress;
create policy "own quiz set progress" on public.user_quiz_set_progress
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "own daily awards read" on public.learning_daily_awards;
create policy "own daily awards read" on public.learning_daily_awards
  for select to authenticated using (user_id = auth.uid());

create or replace function public.admin_save_quiz_set(quiz_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_id uuid;
  question_payload jsonb;
  question_index integer := 0;
  option_values text[];
  correct_index integer;
  target_status text := coalesce(nullif(quiz_payload->>'status', ''), 'draft');
begin
  if not public.is_awareness_admin() then
    raise exception 'Administrator access required';
  end if;
  if nullif(btrim(quiz_payload->>'title'), '') is null
     or nullif(btrim(quiz_payload->>'description'), '') is null then
    raise exception 'Quiz title and briefing are required';
  end if;
  if target_status not in ('draft', 'published', 'archived') then
    raise exception 'Invalid quiz status';
  end if;
  if jsonb_typeof(quiz_payload->'questions') <> 'array'
     or jsonb_array_length(quiz_payload->'questions') < 1
     or jsonb_array_length(quiz_payload->'questions') > 20 then
    raise exception 'A quiz must contain between 1 and 20 questions';
  end if;

  target_id := nullif(quiz_payload->>'id', '')::uuid;
  if target_id is null then
    insert into public.quiz_sets (
      title, description, category, difficulty, xp_reward,
      status, is_active, published_at, updated_at
    ) values (
      btrim(quiz_payload->>'title'),
      btrim(quiz_payload->>'description'),
      coalesce(nullif(btrim(quiz_payload->>'category'), ''), 'General'),
      coalesce(nullif(btrim(quiz_payload->>'difficulty'), ''), 'Beginner'),
      coalesce((quiz_payload->>'xp_reward')::integer, 80),
      target_status, target_status = 'published',
      case when target_status = 'published' then now() else null end,
      now()
    ) returning id into target_id;
  else
    update public.quiz_sets
    set title = btrim(quiz_payload->>'title'),
        description = btrim(quiz_payload->>'description'),
        category = coalesce(nullif(btrim(quiz_payload->>'category'), ''), 'General'),
        difficulty = coalesce(nullif(btrim(quiz_payload->>'difficulty'), ''), 'Beginner'),
        xp_reward = coalesce((quiz_payload->>'xp_reward')::integer, 80),
        status = target_status,
        is_active = target_status = 'published',
        published_at = case
          when target_status = 'published' then coalesce(published_at, now())
          else published_at
        end,
        updated_at = now()
    where id = target_id;
    if not found then raise exception 'Quiz set not found'; end if;
    delete from public.quiz_questions where quiz_set_id = target_id;
  end if;

  for question_payload in
    select value from jsonb_array_elements(quiz_payload->'questions')
  loop
    option_values := array(
      select btrim(value)
      from jsonb_array_elements_text(question_payload->'options')
      where nullif(btrim(value), '') is not null
    );
    correct_index := coalesce((question_payload->>'correct_index')::integer, -1);
    if nullif(btrim(question_payload->>'question'), '') is null
       or nullif(btrim(question_payload->>'explanation'), '') is null
       or array_length(option_values, 1) not between 2 and 4
       or correct_index < 0
       or correct_index >= array_length(option_values, 1) then
      raise exception 'Every question needs text, an explanation, 2-4 answers, and one correct answer';
    end if;
    if coalesce((question_payload->>'time_limit_seconds')::integer, 0)
       not between 5 and 300 then
      raise exception 'Question time limits must be between 5 and 300 seconds';
    end if;

    question_index := question_index + 1;
    insert into public.quiz_questions (
      quiz_set_id, question_order, question, options, correct_index,
      explanation, category, difficulty, image_url, time_limit_seconds,
      status, is_active, sort_order, published_at, updated_at
    ) values (
      target_id, question_index * 10,
      btrim(question_payload->>'question'), option_values, correct_index,
      btrim(question_payload->>'explanation'),
      coalesce(nullif(btrim(quiz_payload->>'category'), ''), 'General'),
      coalesce(nullif(btrim(quiz_payload->>'difficulty'), ''), 'Beginner'),
      nullif(btrim(question_payload->>'image_url'), ''),
      (question_payload->>'time_limit_seconds')::integer,
      target_status, target_status = 'published', question_index * 10,
      case when target_status = 'published' then now() else null end,
      now()
    );
  end loop;
  return target_id;
end;
$$;

create or replace function public.set_quiz_set_status(
  target_quiz_set_id uuid,
  target_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_awareness_admin() then
    raise exception 'Administrator access required';
  end if;
  if target_status not in ('draft', 'published', 'archived') then
    raise exception 'Invalid quiz status';
  end if;
  update public.quiz_sets
  set status = target_status,
      is_active = target_status = 'published',
      published_at = case
        when target_status = 'published' then coalesce(published_at, now())
        else published_at
      end,
      updated_at = now()
  where id = target_quiz_set_id;
  update public.quiz_questions
  set status = target_status,
      is_active = target_status = 'published',
      published_at = case
        when target_status = 'published' then coalesce(published_at, now())
        else published_at
      end,
      updated_at = now()
  where quiz_set_id = target_quiz_set_id;
end;
$$;

create or replace function public.award_daily_learning_xp(
  target_activity_key text,
  target_xp integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_rows integer;
begin
  if auth.uid() is null or nullif(btrim(target_activity_key), '') is null
     or target_xp not between 1 and 500 then
    raise exception 'Invalid daily XP award';
  end if;
  insert into public.learning_daily_awards (
    user_id, activity_key, award_date, xp_awarded
  ) values (
    auth.uid(), btrim(target_activity_key),
    (now() at time zone 'Asia/Kuala_Lumpur')::date, target_xp
  ) on conflict do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 0 then return 0; end if;
  perform public.award_learning_xp(target_xp);
  return target_xp;
end;
$$;

create or replace function public.complete_learning_lesson_v2(target_lesson_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare lesson_xp integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select xp_reward into lesson_xp from public.learning_lessons
  where id = target_lesson_id and status = 'published' and is_active = true;
  if lesson_xp is null then raise exception 'Lesson is not available'; end if;
  insert into public.user_completed_lessons (user_id, lesson_id)
  values (auth.uid(), target_lesson_id) on conflict do nothing;
  return public.award_daily_learning_xp(
    'lesson:' || target_lesson_id::text, lesson_xp
  );
end;
$$;

create or replace function public.complete_learning_scenario_v2(target_scenario_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare scenario_xp integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select xp_reward into scenario_xp from public.scenarios
  where id = target_scenario_id and status = 'published' and is_active = true;
  if scenario_xp is null then raise exception 'Scenario is not available'; end if;
  insert into public.user_completed_scenarios (user_id, scenario_id)
  values (auth.uid(), target_scenario_id) on conflict do nothing;
  return public.award_daily_learning_xp(
    'scenario:' || target_scenario_id::text, scenario_xp
  );
end;
$$;

create or replace function public.record_quiz_set_attempt(
  target_quiz_set_id uuid,
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
  configured_xp integer;
  expected_total integer;
  awarded_xp integer := 0;
begin
  if auth.uid() is null or question_total <= 0 or answer_score < 0
     or answer_score > question_total or elapsed_seconds < 0 then
    raise exception 'Invalid quiz attempt';
  end if;
  select qs.xp_reward, count(qq.id)::integer
  into configured_xp, expected_total
  from public.quiz_sets qs
  join public.quiz_questions qq on qq.quiz_set_id = qs.id
  where qs.id = target_quiz_set_id
    and qs.status = 'published' and qs.is_active = true
  group by qs.xp_reward;
  if configured_xp is null or expected_total <> question_total then
    raise exception 'Quiz content changed. Please restart the challenge';
  end if;

  score_percent := floor(answer_score * 100.0 / question_total)::integer;
  if score_percent >= 70 then
    awarded_xp := public.award_daily_learning_xp(
      'quiz:' || target_quiz_set_id::text, configured_xp
    );
  end if;

  insert into public.user_quiz_set_progress (
    user_id, quiz_set_id, best_score_percent, completed_at
  ) values (
    auth.uid(), target_quiz_set_id, score_percent,
    case when score_percent >= 70 then now() else null end
  ) on conflict (user_id, quiz_set_id) do update
  set best_score_percent = greatest(
        public.user_quiz_set_progress.best_score_percent,
        excluded.best_score_percent
      ),
      completed_at = case
        when excluded.best_score_percent >= 70
          then coalesce(public.user_quiz_set_progress.completed_at, now())
        else public.user_quiz_set_progress.completed_at
      end,
      updated_at = now();

  insert into public.quiz_attempts (
    user_id, quiz_set_id, score, total_questions,
    time_taken_seconds, passed, xp_earned
  ) values (
    auth.uid(), target_quiz_set_id, answer_score, question_total,
    elapsed_seconds, score_percent >= 70, awarded_xp
  );
  return awarded_xp;
end;
$$;

revoke all on function public.admin_save_quiz_set(jsonb)
  from public, anon, authenticated;
grant execute on function public.admin_save_quiz_set(jsonb) to authenticated;
revoke all on function public.set_quiz_set_status(uuid, text)
  from public, anon, authenticated;
grant execute on function public.set_quiz_set_status(uuid, text) to authenticated;
revoke all on function public.award_daily_learning_xp(text, integer)
  from public, anon, authenticated;
grant execute on function public.complete_learning_lesson_v2(uuid) to authenticated;
grant execute on function public.complete_learning_scenario_v2(uuid) to authenticated;
grant execute on function public.record_quiz_set_attempt(uuid, integer, integer, integer)
  to authenticated;

-- Public media bucket. Writes remain restricted to registered Awareness admins.
insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
) values (
  'awareness-media', 'awareness-media', true, 52428800,
  array['image/jpeg', 'image/png', 'video/mp4']
) on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "awareness media admin insert" on storage.objects;
create policy "awareness media admin insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'awareness-media' and public.is_awareness_admin());
drop policy if exists "awareness media admin update" on storage.objects;
create policy "awareness media admin update" on storage.objects
  for update to authenticated
  using (bucket_id = 'awareness-media' and public.is_awareness_admin())
  with check (bucket_id = 'awareness-media' and public.is_awareness_admin());
drop policy if exists "awareness media admin delete" on storage.objects;
create policy "awareness media admin delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'awareness-media' and public.is_awareness_admin());

-- Ensure all Module 5 tables that drive UI refresh are in the Realtime publication.
do $$
declare target_table text;
begin
  foreach target_table in array array[
    'learning_lessons', 'quiz_sets', 'quiz_questions', 'scenarios',
    'reward_partners', 'reward_vouchers', 'voucher_codes',
    'profiles', 'user_claimed_vouchers'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public' and tablename = target_table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I', target_table
      );
    end if;
  end loop;
end;
$$;

select
  (select count(*) from public.quiz_sets) as quiz_sets,
  (select count(*) from public.quiz_questions) as quiz_questions,
  (select public from storage.buckets where id = 'awareness-media')
    as awareness_media_public;
