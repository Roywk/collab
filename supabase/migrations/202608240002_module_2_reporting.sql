-- Enable PostGIS extension (Required for coordinate distance logic)
create extension if not exists postgis;

-- 1. Create or Update the Scam Reports table
create table if not exists public.scam_reports (
  id uuid primary key default gen_random_uuid()
);

-- Safely add all required columns if they don't exist
alter table public.scam_reports
  add column if not exists created_at timestamptz default now() not null,
  add column if not exists updated_at timestamptz default now(),
  add column if not exists reporter_id uuid references auth.users(id),
  add column if not exists title text,
  add column if not exists category text,
  add column if not exists description text,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_name text,
  add column if not exists amount_lost numeric(12, 2) default 0,
  add column if not exists evidence_urls text[] default '{}',
  add column if not exists is_anonymous boolean default false,
  add column if not exists verification_status text default 'Pending',
  add column if not exists admin_notes text,
  add column if not exists witness_count int default 1,
  add column if not exists metadata jsonb default '{}';

-- Ensure the check constraint exists
alter table public.scam_reports drop constraint if exists scam_reports_verification_status_check;
alter table public.scam_reports add constraint scam_reports_verification_status_check
  check (verification_status in ('Pending', 'Verified', 'Resolved', 'Fake'));

-- Ensure RLS is on
alter table public.scam_reports enable row level security;

-- 2. Fix Witness Consensus Logic
create or replace function public.fn_live_witness_consensus()
returns trigger as $$
declare
    matching_count int;
begin
    select count(*) into matching_count
    from public.scam_reports
    where category = new.category
      and id != new.id
      and verification_status = 'Pending'
      and created_at > (now() - interval '4 hours')
      and (
        st_distance(
          st_point(longitude, latitude)::geography,
          st_point(new.longitude, new.latitude)::geography
        ) < 100
      );

    if matching_count >= 2 then
        update public.scam_reports
        set verification_status = 'Verified', witness_count = matching_count + 1
        where id = new.id;
    end if;
    return new;
end;
$$ language plpgsql security definer;

drop trigger if exists tr_scam_consensus on public.scam_reports;
create trigger tr_scam_consensus after insert on public.scam_reports
for each row execute function public.fn_live_witness_consensus();

-- 3. RLS Policies
drop policy if exists "Users can view their own reports" on public.scam_reports;
create policy "Users can view their own reports" on public.scam_reports for select using (auth.uid() = reporter_id);

drop policy if exists "Users can insert reports" on public.scam_reports;
create policy "Users can insert reports" on public.scam_reports for insert with check (auth.uid() = reporter_id);

drop policy if exists "Anyone can view verified reports" on public.scam_reports;
create policy "Anyone can view verified reports" on public.scam_reports for select using (verification_status = 'Verified');

-- 4. Storage Bucket Setup
insert into storage.buckets (id, name, public)
values ('scam-evidence', 'scam-evidence', true)
on conflict (id) do nothing;

drop policy if exists "Public Access to Evidence" on storage.objects;
create policy "Public Access to Evidence" on storage.objects for select using ( bucket_id = 'scam-evidence' );

drop policy if exists "Authenticated users can upload evidence" on storage.objects;
create policy "Authenticated users can upload evidence" on storage.objects for insert with check (
    bucket_id = 'scam-evidence' and auth.role() = 'authenticated'
);

-- Force a schema cache reload
notify pgrst, 'reload schema';