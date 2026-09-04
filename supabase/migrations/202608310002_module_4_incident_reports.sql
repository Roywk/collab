-- Visit 1MY - Module 4: Incident Report Generator
-- Run this migration in the Supabase SQL editor after the emergency banking migration.

create sequence if not exists public.incident_report_reference_seq;

create or replace function public.next_incident_report_reference()
returns text
language sql
volatile
set search_path = public
as $$
  select '1MY-PDRM-' || to_char(current_date, 'YYYYMMDD') || '-' ||
    lpad(nextval('public.incident_report_reference_seq')::text, 6, '0');
$$;

create table if not exists public.incident_reports (
  id uuid primary key default gen_random_uuid(),
  report_reference text not null unique
    default public.next_incident_report_reference(),
  user_id uuid not null references auth.users(id) on delete cascade,
  input_language text not null,
  incident_at timestamptz not null,
  source_report jsonb not null,
  english_report jsonb not null,
  malay_report jsonb not null,
  translation_model text,
  status text not null default 'translated',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint incident_reports_input_language_check
    check (input_language in ('en', 'ms')),
  constraint incident_reports_status_check
    check (status in ('translated', 'pdf_generated', 'downloaded')),
  constraint incident_reports_source_object_check
    check (jsonb_typeof(source_report) = 'object'),
  constraint incident_reports_english_object_check
    check (jsonb_typeof(english_report) = 'object'),
  constraint incident_reports_malay_object_check
    check (jsonb_typeof(malay_report) = 'object')
);

create index if not exists incident_reports_user_created_idx
  on public.incident_reports (user_id, created_at desc);

alter table public.incident_reports enable row level security;

drop policy if exists "Users can create their own incident reports"
  on public.incident_reports;
create policy "Users can create their own incident reports"
  on public.incident_reports
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can read their own incident reports"
  on public.incident_reports;
create policy "Users can read their own incident reports"
  on public.incident_reports
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can update their own incident reports"
  on public.incident_reports;
create policy "Users can update their own incident reports"
  on public.incident_reports
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "Users can delete their own incident reports"
  on public.incident_reports;
create policy "Users can delete their own incident reports"
  on public.incident_reports
  for delete
  to authenticated
  using (user_id = auth.uid());

grant usage, select on sequence public.incident_report_reference_seq
  to authenticated;
grant select, insert, update, delete on public.incident_reports
  to authenticated;
