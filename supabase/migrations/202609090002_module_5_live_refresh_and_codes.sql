-- Module 5 follow-up: human-readable references and safe reward availability.
-- UUIDs remain the internal primary keys so existing foreign keys keep working.

create sequence if not exists public.learning_lesson_code_seq start 1;
create sequence if not exists public.quiz_question_code_seq start 1;
create sequence if not exists public.scenario_code_seq start 1;
create sequence if not exists public.scenario_step_code_seq start 1;
create sequence if not exists public.scenario_option_code_seq start 1;
create sequence if not exists public.reward_voucher_code_seq start 1;
create sequence if not exists public.voucher_inventory_code_seq start 1;
create sequence if not exists public.quiz_attempt_code_seq start 1;
create sequence if not exists public.voucher_claim_code_seq start 1;

alter table public.learning_lessons add column if not exists lesson_code text;
alter table public.quiz_questions add column if not exists question_code text;
alter table public.scenarios add column if not exists scenario_code text;
alter table public.scenario_steps add column if not exists step_code text;
alter table public.scenario_options add column if not exists option_code text;
alter table public.reward_vouchers add column if not exists voucher_code text;
alter table public.voucher_codes add column if not exists inventory_code text;
alter table public.quiz_attempts add column if not exists attempt_code text;
alter table public.user_claimed_vouchers add column if not exists claim_code text;

alter table public.learning_lessons alter column lesson_code
  set default ('LSN-' || lpad(nextval('public.learning_lesson_code_seq')::text, 6, '0'));
alter table public.quiz_questions alter column question_code
  set default ('QST-' || lpad(nextval('public.quiz_question_code_seq')::text, 6, '0'));
alter table public.scenarios alter column scenario_code
  set default ('SCN-' || lpad(nextval('public.scenario_code_seq')::text, 6, '0'));
alter table public.scenario_steps alter column step_code
  set default ('SST-' || lpad(nextval('public.scenario_step_code_seq')::text, 6, '0'));
alter table public.scenario_options alter column option_code
  set default ('SOP-' || lpad(nextval('public.scenario_option_code_seq')::text, 6, '0'));
alter table public.reward_vouchers alter column voucher_code
  set default ('VCH-' || lpad(nextval('public.reward_voucher_code_seq')::text, 6, '0'));
alter table public.voucher_codes alter column inventory_code
  set default ('VCI-' || lpad(nextval('public.voucher_inventory_code_seq')::text, 6, '0'));
alter table public.quiz_attempts alter column attempt_code
  set default ('QZA-' || lpad(nextval('public.quiz_attempt_code_seq')::text, 6, '0'));
alter table public.user_claimed_vouchers alter column claim_code
  set default ('CLM-' || lpad(nextval('public.voucher_claim_code_seq')::text, 6, '0'));

update public.learning_lessons set lesson_code = default where lesson_code is null;
update public.quiz_questions set question_code = default where question_code is null;
update public.scenarios set scenario_code = default where scenario_code is null;
update public.scenario_steps set step_code = default where step_code is null;
update public.scenario_options set option_code = default where option_code is null;
update public.reward_vouchers set voucher_code = default where voucher_code is null;
update public.voucher_codes set inventory_code = default where inventory_code is null;
update public.quiz_attempts set attempt_code = default where attempt_code is null;
update public.user_claimed_vouchers set claim_code = default where claim_code is null;

alter table public.learning_lessons alter column lesson_code set not null;
alter table public.quiz_questions alter column question_code set not null;
alter table public.scenarios alter column scenario_code set not null;
alter table public.scenario_steps alter column step_code set not null;
alter table public.scenario_options alter column option_code set not null;
alter table public.reward_vouchers alter column voucher_code set not null;
alter table public.voucher_codes alter column inventory_code set not null;
alter table public.quiz_attempts alter column attempt_code set not null;
alter table public.user_claimed_vouchers alter column claim_code set not null;

create unique index if not exists learning_lessons_lesson_code_key
  on public.learning_lessons(lesson_code);
create unique index if not exists quiz_questions_question_code_key
  on public.quiz_questions(question_code);
create unique index if not exists scenarios_scenario_code_key
  on public.scenarios(scenario_code);
create unique index if not exists scenario_steps_step_code_key
  on public.scenario_steps(step_code);
create unique index if not exists scenario_options_option_code_key
  on public.scenario_options(option_code);
create unique index if not exists reward_vouchers_voucher_code_key
  on public.reward_vouchers(voucher_code);
create unique index if not exists voucher_codes_inventory_code_key
  on public.voucher_codes(inventory_code);
create unique index if not exists quiz_attempts_attempt_code_key
  on public.quiz_attempts(attempt_code);
create unique index if not exists user_claimed_vouchers_claim_code_key
  on public.user_claimed_vouchers(claim_code)
  where claim_code is not null;

create or replace function public.get_reward_inventory()
returns table(voucher_id uuid, available_codes bigint)
language sql
stable
security definer
set search_path = public
as $$
  select rv.id, count(vc.id) filter (where vc.status = 'available')
  from public.reward_vouchers rv
  left join public.voucher_codes vc on vc.voucher_id = rv.id
  where rv.status = 'published' and rv.is_active = true
  group by rv.id;
$$;

revoke all on function public.get_reward_inventory() from public, anon;
grant execute on function public.get_reward_inventory() to authenticated;

-- Demo inventory for published prototype rewards that currently have no codes.
-- Replace these from Awareness CMS when real sponsor batches are available.
do $$
declare
  reward_row record;
  code_number integer;
  clean_prefix text;
begin
  for reward_row in
    select rv.id, rv.promo_code_prefix
    from public.reward_vouchers rv
    where rv.status = 'published'
      and rv.is_active = true
      and not exists (
        select 1 from public.voucher_codes vc where vc.voucher_id = rv.id
      )
  loop
    clean_prefix := upper(
      regexp_replace(coalesce(nullif(reward_row.promo_code_prefix, ''), 'V1MY-'), '[^A-Za-z0-9-]', '', 'g')
    );
    if right(clean_prefix, 1) <> '-' then
      clean_prefix := clean_prefix || '-';
    end if;

    for code_number in 1..5 loop
      insert into public.voucher_codes (voucher_id, code)
      values (reward_row.id, clean_prefix || lpad(code_number::text, 4, '0'))
      on conflict (code) do nothing;
    end loop;
  end loop;
end $$;
