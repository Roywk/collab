-- Module 5: Scam Awareness CMS, learning progress and finite reward inventory.
-- Safe to run after the schema shared with the project on 2026-09-09.

create extension if not exists pgcrypto;

alter table public.learning_lessons
  add column if not exists status text not null default 'draft',
  add column if not exists xp_reward integer not null default 20,
  add column if not exists hotspot_label text,
  add column if not exists sort_order integer not null default 0,
  add column if not exists published_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

alter table public.learning_lessons
  drop constraint if exists learning_lessons_status_check;
alter table public.learning_lessons
  add constraint learning_lessons_status_check
  check (status in ('draft', 'published', 'archived'));

update public.learning_lessons
set status = case when coalesce(is_active, false) then 'published' else 'draft' end,
    updated_at = coalesce(created_at, now())
where status = 'draft';

alter table public.quiz_questions
  add column if not exists difficulty text not null default 'Beginner',
  add column if not exists image_url text,
  add column if not exists time_limit_seconds integer not null default 15,
  add column if not exists status text not null default 'draft',
  add column if not exists is_active boolean not null default false,
  add column if not exists sort_order integer not null default 0,
  add column if not exists published_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

alter table public.quiz_questions
  drop constraint if exists quiz_questions_status_check;
alter table public.quiz_questions
  add constraint quiz_questions_status_check
  check (status in ('draft', 'published', 'archived'));
alter table public.quiz_questions
  drop constraint if exists quiz_questions_correct_index_check;
alter table public.quiz_questions
  add constraint quiz_questions_correct_index_check
  check (correct_index >= 0 and correct_index < cardinality(options));
alter table public.quiz_questions
  drop constraint if exists quiz_questions_time_limit_check;
alter table public.quiz_questions
  add constraint quiz_questions_time_limit_check
  check (time_limit_seconds between 5 and 300);

update public.quiz_questions
set status = case when coalesce(is_active, false) then 'published' else 'draft' end,
    updated_at = coalesce(created_at, now())
where status = 'draft';

alter table public.scenarios
  add column if not exists category text not null default 'General',
  add column if not exists status text not null default 'draft',
  add column if not exists sort_order integer not null default 0,
  add column if not exists published_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

alter table public.scenarios
  drop constraint if exists scenarios_status_check;
alter table public.scenarios
  add constraint scenarios_status_check
  check (status in ('draft', 'published', 'archived'));

update public.scenarios
set status = case when coalesce(is_active, false) then 'published' else 'draft' end,
    updated_at = coalesce(created_at, now())
where status = 'draft';

alter table public.reward_vouchers
  add column if not exists status text not null default 'draft',
  add column if not exists description text,
  add column if not exists image_url text,
  add column if not exists terms text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.reward_vouchers
  drop constraint if exists reward_vouchers_status_check;
alter table public.reward_vouchers
  add constraint reward_vouchers_status_check
  check (status in ('draft', 'published', 'archived'));

update public.reward_vouchers
set status = case when coalesce(is_active, false) then 'published' else 'draft' end
where status = 'draft';

create table if not exists public.user_completed_scenarios (
  user_id uuid not null references public.profiles(id) on delete cascade,
  scenario_id uuid not null references public.scenarios(id) on delete cascade,
  completed_at timestamptz not null default now(),
  primary key (user_id, scenario_id)
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  score integer not null check (score >= 0),
  total_questions integer not null check (total_questions > 0),
  time_taken_seconds integer not null default 0 check (time_taken_seconds >= 0),
  passed boolean not null,
  xp_earned integer not null default 0 check (xp_earned >= 0),
  completed_at timestamptz not null default now(),
  check (score <= total_questions)
);

create table if not exists public.user_quiz_progress (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  best_score_percent integer not null default 0
    check (best_score_percent between 0 and 100),
  best_xp_award integer not null default 0 check (best_xp_award >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.voucher_codes (
  id uuid primary key default gen_random_uuid(),
  voucher_id uuid not null references public.reward_vouchers(id) on delete cascade,
  code text not null unique,
  status text not null default 'available'
    check (status in ('available', 'claimed', 'disabled')),
  claimed_by uuid references public.profiles(id) on delete set null,
  claimed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.user_claimed_vouchers
  add column if not exists voucher_code_id uuid
  references public.voucher_codes(id) on delete set null;

create unique index if not exists user_claimed_vouchers_one_per_reward
  on public.user_claimed_vouchers(user_id, voucher_id);
create index if not exists awareness_lessons_status_order_idx
  on public.learning_lessons(status, sort_order, created_at desc);
create index if not exists awareness_questions_status_order_idx
  on public.quiz_questions(status, sort_order, created_at desc);
create index if not exists awareness_scenarios_status_order_idx
  on public.scenarios(status, sort_order, created_at desc);
create index if not exists voucher_codes_inventory_idx
  on public.voucher_codes(voucher_id, status);

create or replace function public.is_awareness_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_accounts
    where id = auth.uid() and is_active = true
  );
$$;

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
      current_level = floor((coalesce(total_xp, 0) + xp_amount) / 200.0)::integer + 1,
      updated_at = now()
  where id = auth.uid();
end;
$$;

create or replace function public.complete_learning_lesson(
  target_lesson_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  lesson_xp integer;
  inserted_rows integer;
begin
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
    return true;
  end if;
  return false;
end;
$$;

create or replace function public.complete_learning_scenario(
  target_scenario_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  scenario_xp integer;
  inserted_rows integer;
begin
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
    return true;
  end if;
  return false;
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
  previous_xp integer;
  awarded_delta integer;
begin
  if auth.uid() is null or question_total <= 0 or answer_score < 0
     or answer_score > question_total or elapsed_seconds < 0 then
    raise exception 'Invalid quiz attempt';
  end if;

  score_percent := floor(answer_score * 100.0 / question_total)::integer;
  candidate_xp := case when score_percent >= 70 then 80 else 20 end;

  insert into public.user_quiz_progress (
    user_id, best_score_percent, best_xp_award
  ) values (
    auth.uid(), score_percent, candidate_xp
  )
  on conflict (user_id) do nothing;

  select best_xp_award into previous_xp
  from public.user_quiz_progress
  where user_id = auth.uid()
  for update;

  awarded_delta := greatest(0, candidate_xp - previous_xp);
  update public.user_quiz_progress
  set best_score_percent = greatest(best_score_percent, score_percent),
      best_xp_award = greatest(best_xp_award, candidate_xp),
      updated_at = now()
  where user_id = auth.uid();

  -- The insert above starts a new row at candidate_xp, so award it on first run.
  if not exists (
    select 1 from public.quiz_attempts where user_id = auth.uid()
  ) then
    awarded_delta := candidate_xp;
  end if;

  insert into public.quiz_attempts (
    user_id, score, total_questions, time_taken_seconds, passed, xp_earned
  ) values (
    auth.uid(), answer_score, question_total, elapsed_seconds,
    score_percent >= 70, awarded_delta
  );

  if awarded_delta > 0 then
    perform public.award_learning_xp(awarded_delta);
  end if;
  return awarded_delta;
end;
$$;

create or replace function public.admin_save_awareness_scenario(
  scenario_payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_id uuid;
  target_step_id uuid;
  option_value text;
  option_index integer := 0;
  correct_index integer := coalesce((scenario_payload->>'correct_index')::integer, 0);
begin
  if not public.is_awareness_admin() then
    raise exception 'Administrator access required';
  end if;

  target_id := nullif(scenario_payload->>'id', '')::uuid;
  if target_id is null then
    insert into public.scenarios (
      title, description, category, difficulty, xp_reward, status,
      is_active, published_at, updated_at
    ) values (
      scenario_payload->>'title', scenario_payload->>'description',
      coalesce(scenario_payload->>'category', 'General'),
      coalesce(scenario_payload->>'difficulty', 'Beginner'),
      coalesce((scenario_payload->>'xp_reward')::integer, 50),
      coalesce(scenario_payload->>'status', 'draft'),
      coalesce(scenario_payload->>'status', 'draft') = 'published',
      case when scenario_payload->>'status' = 'published' then now() end,
      now()
    ) returning id into target_id;
  else
    update public.scenarios
    set title = scenario_payload->>'title',
        description = scenario_payload->>'description',
        category = coalesce(scenario_payload->>'category', 'General'),
        difficulty = coalesce(scenario_payload->>'difficulty', 'Beginner'),
        xp_reward = coalesce((scenario_payload->>'xp_reward')::integer, 50),
        status = coalesce(scenario_payload->>'status', 'draft'),
        is_active = coalesce(scenario_payload->>'status', 'draft') = 'published',
        published_at = case
          when scenario_payload->>'status' = 'published' then coalesce(published_at, now())
          else published_at
        end,
        updated_at = now()
    where id = target_id;
  end if;

  delete from public.scenario_options
  where step_id in (
    select id from public.scenario_steps where scenario_id = target_id
  );
  delete from public.scenario_steps where scenario_id = target_id;

  insert into public.scenario_steps (scenario_id, situation, step_order)
  values (target_id, scenario_payload->>'situation', 1)
  returning id into target_step_id;

  for option_value in
    select jsonb_array_elements_text(scenario_payload->'options')
  loop
    insert into public.scenario_options (step_id, option_text, is_correct, feedback)
    values (
      target_step_id,
      option_value,
      option_index = correct_index,
      coalesce(scenario_payload->>'feedback', '')
    );
    option_index := option_index + 1;
  end loop;

  return target_id;
end;
$$;

create or replace function public.claim_reward_voucher(target_voucher_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_code public.voucher_codes%rowtype;
  existing_code text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select ucv.full_promo_code into existing_code
  from public.user_claimed_vouchers ucv
  where ucv.user_id = auth.uid() and ucv.voucher_id = target_voucher_id;
  if existing_code is not null then
    return existing_code;
  end if;

  if not exists (
    select 1
    from public.reward_vouchers rv
    join public.profiles p on p.id = auth.uid()
    where rv.id = target_voucher_id
      and rv.status = 'published'
      and rv.is_active = true
      and rv.valid_until > now()
      and coalesce(p.total_xp, 0) >= rv.required_xp
  ) then
    raise exception 'This reward is locked or no longer available';
  end if;

  select * into selected_code
  from public.voucher_codes
  where voucher_id = target_voucher_id and status = 'available'
  order by created_at
  for update skip locked
  limit 1;

  if selected_code.id is null then
    raise exception 'This reward is currently out of stock';
  end if;

  update public.voucher_codes
  set status = 'claimed', claimed_by = auth.uid(), claimed_at = now()
  where id = selected_code.id;

  insert into public.user_claimed_vouchers (
    user_id, voucher_id, voucher_code_id, full_promo_code
  ) values (
    auth.uid(), target_voucher_id, selected_code.id, selected_code.code
  );

  return selected_code.code;
end;
$$;

revoke all on function public.award_learning_xp(integer) from public, anon, authenticated;
grant execute on function public.complete_learning_lesson(uuid) to authenticated;
grant execute on function public.complete_learning_scenario(uuid) to authenticated;
grant execute on function public.record_quiz_attempt(integer, integer, integer)
  to authenticated;
grant execute on function public.claim_reward_voucher(uuid) to authenticated;
grant execute on function public.admin_save_awareness_scenario(jsonb) to authenticated;

alter table public.learning_lessons enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.scenarios enable row level security;
alter table public.scenario_steps enable row level security;
alter table public.scenario_options enable row level security;
alter table public.reward_vouchers enable row level security;
alter table public.voucher_codes enable row level security;
alter table public.user_completed_lessons enable row level security;
alter table public.user_completed_scenarios enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.user_quiz_progress enable row level security;
alter table public.user_claimed_vouchers enable row level security;

drop policy if exists "awareness lessons public read" on public.learning_lessons;
create policy "awareness lessons public read" on public.learning_lessons
  for select to authenticated
  using (status = 'published' and is_active = true or public.is_awareness_admin());
drop policy if exists "awareness lessons admin write" on public.learning_lessons;
create policy "awareness lessons admin write" on public.learning_lessons
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "awareness quiz public read" on public.quiz_questions;
create policy "awareness quiz public read" on public.quiz_questions
  for select to authenticated
  using (status = 'published' and is_active = true or public.is_awareness_admin());
drop policy if exists "awareness quiz admin write" on public.quiz_questions;
create policy "awareness quiz admin write" on public.quiz_questions
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "awareness scenarios public read" on public.scenarios;
create policy "awareness scenarios public read" on public.scenarios
  for select to authenticated
  using (status = 'published' and is_active = true or public.is_awareness_admin());
drop policy if exists "awareness scenarios admin write" on public.scenarios;
create policy "awareness scenarios admin write" on public.scenarios
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "awareness scenario steps read" on public.scenario_steps;
create policy "awareness scenario steps read" on public.scenario_steps
  for select to authenticated
  using (exists (
    select 1 from public.scenarios s
    where s.id = scenario_id
      and (s.status = 'published' and s.is_active = true or public.is_awareness_admin())
  ));
drop policy if exists "awareness scenario steps admin" on public.scenario_steps;
create policy "awareness scenario steps admin" on public.scenario_steps
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "awareness scenario options read" on public.scenario_options;
create policy "awareness scenario options read" on public.scenario_options
  for select to authenticated
  using (exists (
    select 1 from public.scenario_steps ss
    join public.scenarios s on s.id = ss.scenario_id
    where ss.id = step_id
      and (s.status = 'published' and s.is_active = true or public.is_awareness_admin())
  ));
drop policy if exists "awareness scenario options admin" on public.scenario_options;
create policy "awareness scenario options admin" on public.scenario_options
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "awareness rewards public read" on public.reward_vouchers;
create policy "awareness rewards public read" on public.reward_vouchers
  for select to authenticated
  using (status = 'published' and is_active = true or public.is_awareness_admin());
drop policy if exists "awareness rewards admin write" on public.reward_vouchers;
create policy "awareness rewards admin write" on public.reward_vouchers
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "voucher codes admin only" on public.voucher_codes;
create policy "voucher codes admin only" on public.voucher_codes
  for all to authenticated
  using (public.is_awareness_admin()) with check (public.is_awareness_admin());

drop policy if exists "own completed lessons" on public.user_completed_lessons;
create policy "own completed lessons" on public.user_completed_lessons
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "own completed scenarios" on public.user_completed_scenarios;
create policy "own completed scenarios" on public.user_completed_scenarios
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "own quiz attempts" on public.quiz_attempts;
create policy "own quiz attempts" on public.quiz_attempts
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "own quiz progress" on public.user_quiz_progress;
create policy "own quiz progress" on public.user_quiz_progress
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "own claimed vouchers" on public.user_claimed_vouchers;
create policy "own claimed vouchers" on public.user_claimed_vouchers
  for select to authenticated using (user_id = auth.uid() or public.is_awareness_admin());

-- Starter content makes the module usable immediately and can be edited in the CMS.
insert into public.learning_lessons (
  title, category, read_time, difficulty, content, red_flags, what_to_do,
  hotspot_label, latitude, longitude, is_location_based, xp_reward,
  status, is_active, published_at, sort_order
)
select
  'Bukit Bintang Backpack Safety', 'Physical Safety', '3 min', 'Beginner',
  'Crowded shopping streets are ideal environments for distraction theft. Keep bags where you can see them, reduce phone use while walking, and decide your route before entering dense crowds.',
  array['A stranger creates a sudden distraction', 'Someone repeatedly bumps or crowds you', 'A bag zip is outside your field of view'],
  'Move your backpack to the front, keep valuables in an inner zipped pocket, and step into a staffed shop if you feel followed.',
  'Bukit Bintang', 3.1466, 101.7113, true, 20,
  'published', true, now(), 10
where not exists (
  select 1 from public.learning_lessons where title = 'Bukit Bintang Backpack Safety'
);

insert into public.learning_lessons (
  title, category, read_time, difficulty, content, red_flags, what_to_do,
  xp_reward, status, is_active, published_at, sort_order
)
select
  'KLIA Taxi Meter & E-hailing Check', 'Transport Scams', '4 min', 'Beginner',
  'Use the official taxi counter or book through a recognized e-hailing app. A driver who approaches you inside the arrival hall and insists on a cash-only fixed fare is not following the normal booking flow.',
  array['Unsolicited approach inside arrivals', 'Cash-only fixed price', 'Refusal to show a booking or use the meter'],
  'Decline firmly, keep your luggage with you, and walk to the official transport counter or designated pickup zone.',
  25, 'published', true, now(), 20
where not exists (
  select 1 from public.learning_lessons where title = 'KLIA Taxi Meter & E-hailing Check'
);

insert into public.quiz_questions (
  question, options, correct_index, explanation, category, difficulty,
  time_limit_seconds, status, is_active, published_at, sort_order
)
select
  'A QR stand has a slightly raised sticker placed over the original code. What should you do?',
  array['Scan it and check later', 'Ask the merchant to verify the displayed name before paying', 'Pay cash without telling staff', 'Photograph it and leave'],
  1,
  'Sticker overlays can redirect payment to a scammer. Verify the QR with staff and confirm the merchant name in your banking app before authorizing payment.',
  'Payment & QR Fraud', 'Beginner', 15, 'published', true, now(), 10
where not exists (
  select 1 from public.quiz_questions where question like 'A QR stand has a slightly raised sticker%'
);

insert into public.quiz_questions (
  question, options, correct_index, explanation, category, difficulty,
  time_limit_seconds, status, is_active, published_at, sort_order
)
select
  'Which payment-screen detail is the strongest reason to stop a transaction?',
  array['The page uses a blue button', 'The merchant name does not match the business', 'The amount includes cents', 'The receipt is digital'],
  1,
  'A mismatched merchant name is a direct warning that funds may be going to a different recipient.',
  'Payment & QR Fraud', 'Intermediate', 12, 'published', true, now(), 20
where not exists (
  select 1 from public.quiz_questions where question = 'Which payment-screen detail is the strongest reason to stop a transaction?'
);

do $$
declare
  new_scenario_id uuid;
  new_step_id uuid;
begin
  if not exists (select 1 from public.scenarios where title = 'Taxi Tout at KLIA') then
    insert into public.scenarios (
      title, description, category, difficulty, xp_reward, status,
      is_active, published_at, sort_order
    ) values (
      'Taxi Tout at KLIA',
      'Practice refusing an unauthorized fixed-fare offer at the airport.',
      'Transport Scams', 'Beginner', 50, 'published', true, now(), 10
    ) returning id into new_scenario_id;

    insert into public.scenario_steps (scenario_id, situation, step_order)
    values (
      new_scenario_id,
      'A man near arrivals takes hold of your suitcase handle and says his taxi is the last available car. He demands RM180 cash now.',
      1
    ) returning id into new_step_id;

    insert into public.scenario_options (step_id, option_text, is_correct, feedback)
    values
      (new_step_id, 'Pay quickly so he releases the luggage', false, 'Urgency and physical control of luggage are pressure tactics. Keep control of your belongings.'),
      (new_step_id, 'Take back the suitcase, decline, and use the official counter', true, 'Correct. A firm refusal and the official booking channel remove the scammer’s leverage.'),
      (new_step_id, 'Negotiate the price down to RM120', false, 'Negotiating still accepts an unauthorized transport offer. Use a verified channel instead.');
  end if;
end $$;

insert into public.reward_vouchers (
  partner_name, title, discount_amount, required_xp, valid_until,
  promo_code_prefix, status, is_active
)
select
  'Merdeka Hotel KL', 'Guardian Weekend Stay', '15% OFF', 400,
  now() + interval '180 days', 'MHKL', 'published', true
where not exists (
  select 1 from public.reward_vouchers where partner_name = 'Merdeka Hotel KL'
    and title = 'Guardian Weekend Stay'
);

insert into public.voucher_codes (voucher_id, code)
select rv.id, code
from public.reward_vouchers rv
cross join unnest(array['MHKL-7M4K', 'MHKL-P9Q2', 'MHKL-X3BD', 'MHKL-R8WA']) code
where rv.partner_name = 'Merdeka Hotel KL'
  and rv.title = 'Guardian Weekend Stay'
on conflict (code) do nothing;
