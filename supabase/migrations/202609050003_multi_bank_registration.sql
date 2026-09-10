-- Visit 1MY - allow a tourist to select multiple banks during registration.
-- The Flutter client sends bank_ids as an ordered JSON array. The first valid
-- active bank becomes primary; every remaining bank is retained as non-primary.

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    display_name,
    phone_number,
    nationality,
    role
  )
  values (
    new.id,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      'Tourist'),
    nullif(trim(new.raw_user_meta_data ->> 'phone_number'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'nationality'), ''),
    'tourist'
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();

  if jsonb_typeof(new.raw_user_meta_data -> 'bank_ids') = 'array' then
    insert into public.user_banks (user_id, bank_id, is_primary)
    select
      new.id,
      bank.id,
      selected.ordinality = 1
    from jsonb_array_elements_text(
      new.raw_user_meta_data -> 'bank_ids'
    ) with ordinality as selected(bank_id, ordinality)
    join public.banks as bank
      on bank.id::text = selected.bank_id
      and bank.is_active = true
    on conflict (user_id, bank_id) do update
      set is_primary = excluded.is_primary;
  elsif nullif(new.raw_user_meta_data ->> 'bank_id', '') is not null then
    -- Continue accepting registrations sent by older app versions.
    insert into public.user_banks (user_id, bank_id, is_primary)
    select new.id, bank.id, true
    from public.banks as bank
    where bank.id::text = new.raw_user_meta_data ->> 'bank_id'
      and bank.is_active = true
    on conflict (user_id, bank_id) do update
      set is_primary = excluded.is_primary;
  end if;

  if nullif(trim(new.raw_user_meta_data ->> 'emergency_contact_name'), '')
      is not null
    and nullif(trim(
      new.raw_user_meta_data ->> 'emergency_contact_phone'
    ), '') is not null then
    insert into public.emergency_contacts (
      user_id,
      name,
      phone_number,
      relationship,
      is_primary
    )
    values (
      new.id,
      trim(new.raw_user_meta_data ->> 'emergency_contact_name'),
      trim(new.raw_user_meta_data ->> 'emergency_contact_phone'),
      nullif(trim(
        new.raw_user_meta_data ->> 'emergency_contact_relationship'
      ), ''),
      true
    );
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();
