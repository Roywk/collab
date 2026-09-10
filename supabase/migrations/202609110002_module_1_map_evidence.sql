-- Visit 1MY - expose approved evidence photos and loss amount for verified map cases.
-- This creates a new read-only RPC and does not alter or delete report data.

begin;

create or replace function public.get_scam_map_reports_v2()
returns table (
  id uuid,
  report_code text,
  title text,
  category text,
  description text,
  latitude double precision,
  longitude double precision,
  verification_status text,
  reported_at timestamp with time zone,
  location_name text,
  is_official boolean,
  source_reference text,
  is_active boolean,
  evidence_urls text[],
  amount_lost numeric
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    report.id,
    report.report_code,
    report.title,
    report.category,
    report.description,
    report.latitude,
    report.longitude,
    report.verification_status,
    report.reported_at,
    report.location_name,
    report.is_official,
    report.source_reference,
    report.is_active,
    report.evidence_urls,
    report.amount_lost
  from public.scam_reports as report
  where report.is_active = true
    and report.verification_status = 'Verified'
    and report.latitude between 3.03 and 3.25
    and report.longitude between 101.60 and 101.80
  order by report.reported_at desc;
$$;

revoke all on function public.get_scam_map_reports_v2() from public;
grant execute on function public.get_scam_map_reports_v2() to anon, authenticated;

commit;
