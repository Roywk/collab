-- Module 5 professional flows: scenario media and spendable reward XP.
-- Run after 202609090001 and 202609090002.

alter table public.scenarios
  add column if not exists media_type text not null default 'none',
  add column if not exists media_url text,
  add column if not exists media_caption text;

alter table public.scenarios
  drop constraint if exists scenarios_media_type_check;
alter table public.scenarios
  add constraint scenarios_media_type_check
  check (media_type in ('none', 'image', 'video'));

alter table public.scenarios
  drop constraint if exists scenarios_media_url_check;
alter table public.scenarios
  add constraint scenarios_media_url_check
  check (media_type = 'none' or nullif(btrim(media_url), '') is not null);

alter table public.profiles add column if not exists available_xp integer;
update public.profiles
set available_xp = greatest(coalesce(total_xp, 0), 0)
where available_xp is null;
alter table public.profiles alter column available_xp set default 0;
alter table public.profiles alter column available_xp set not null;
alter table public.profiles drop constraint if exists profiles_available_xp_check;
alter table public.profiles add constraint profiles_available_xp_check
  check (available_xp >= 0);

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
      current_level = floor((coalesce(total_xp, 0) + xp_amount) / 200.0)::integer + 1,
      updated_at = now()
  where id = auth.uid();
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
  target_media_type text := coalesce(nullif(scenario_payload->>'media_type', ''), 'none');
begin
  if not public.is_awareness_admin() then
    raise exception 'Administrator access required';
  end if;
  if target_media_type not in ('none', 'image', 'video') then
    raise exception 'Unsupported scenario media type';
  end if;
  if target_media_type <> 'none'
     and nullif(btrim(scenario_payload->>'media_url'), '') is null then
    raise exception 'A public media URL is required';
  end if;

  target_id := nullif(scenario_payload->>'id', '')::uuid;
  if target_id is null then
    insert into public.scenarios (
      title, description, category, difficulty, xp_reward, status,
      is_active, published_at, updated_at,
      media_type, media_url, media_caption
    ) values (
      scenario_payload->>'title', scenario_payload->>'description',
      coalesce(scenario_payload->>'category', 'General'),
      coalesce(scenario_payload->>'difficulty', 'Beginner'),
      coalesce((scenario_payload->>'xp_reward')::integer, 50),
      coalesce(scenario_payload->>'status', 'draft'),
      coalesce(scenario_payload->>'status', 'draft') = 'published',
      case when scenario_payload->>'status' = 'published' then now() end,
      now(), target_media_type,
      nullif(btrim(scenario_payload->>'media_url'), ''),
      nullif(btrim(scenario_payload->>'media_caption'), '')
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
        updated_at = now(),
        media_type = target_media_type,
        media_url = nullif(btrim(scenario_payload->>'media_url'), ''),
        media_caption = nullif(btrim(scenario_payload->>'media_caption'), '')
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
    insert into public.scenario_options (
      step_id, option_text, is_correct, feedback
    ) values (
      target_step_id, option_value, option_index = correct_index,
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
  reward_cost integer;
  xp_balance integer;
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

  select rv.required_xp into reward_cost
  from public.reward_vouchers rv
  where rv.id = target_voucher_id
    and rv.status = 'published'
    and rv.is_active = true
    and rv.valid_until > now()
  for update;
  if reward_cost is null then
    raise exception 'This reward is no longer available';
  end if;

  select p.available_xp into xp_balance
  from public.profiles p
  where p.id = auth.uid()
  for update;
  if xp_balance is null then
    raise exception 'Learning profile not found';
  end if;
  if xp_balance < reward_cost then
    raise exception 'Not enough XP to redeem this reward';
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

  update public.profiles
  set available_xp = available_xp - reward_cost,
      updated_at = now()
  where id = auth.uid();

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

revoke all on function public.award_learning_xp(integer)
  from public, anon, authenticated;
grant execute on function public.admin_save_awareness_scenario(jsonb)
  to authenticated;
grant execute on function public.claim_reward_voucher(uuid)
  to authenticated;
