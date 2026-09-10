-- Visit 1MY - Module 2: Scam Reporting & Validation
-- 1. Ensure scam_reports has all Module 2 fields
alter table public.scam_reports
  add column if not exists reporter_id uuid references auth.users(id),
  add column if not exists is_anonymous boolean default false,
  add column if not exists amount_lost numeric(12, 2),
  add column if not exists evidence_urls text[] default '{}',
  add column if not exists metadata jsonb default '{}', -- For EXIF (location/timestamp)
  add column if not exists witness_count int default 1;

-- 2. Live Witness Consensus Logic
-- Automatically verifies a report if other reports occur within 100m in the last 4 hours
create or replace function public.fn_live_witness_consensus()
returns trigger as $$
declare
    matching_count int;
begin
    -- Count similar reports: same category, within 100m, within last 4 hours
    select count(*)
    into matching_count
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
        set
            verification_status = 'Verified',
            witness_count = matching_count + 1
        where id = new.id;
    end if;

    return new;
end;
$$ language plpgsql security definer;

create trigger tr_scam_consensus
after insert on public.scam_reports
for each row execute function public.fn_live_witness_consensus();

-- 3. RLS Policies for Reporting
create policy "Users can view their own reports"
  on public.scam_reports for select
  using (auth.uid() = reporter_id);

create policy "Users can insert reports"
  on public.scam_reports for insert
  with check (auth.uid() = reporter_id);