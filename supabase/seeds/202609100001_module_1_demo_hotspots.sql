-- Visit 1MY - clearly labelled academic demo data for Module 1.
-- Safe to run more than once: an existing demo title is not inserted again.

begin;

with demo_cases (
  title,
  category,
  description,
  latitude,
  longitude,
  location_name,
  verification_status,
  reported_at
) as (
  values
    (
      '[DEMO] Taxi fare manipulation near KL Sentral',
      'Taxi Scam',
      'Academic demonstration record: a driver refuses to use the meter and demands an inflated fixed fare.',
      3.1340::double precision,
      101.6869::double precision,
      'KL Sentral, Kuala Lumpur',
      'Verified',
      now() - interval '8 days'
    ),
    (
      '[DEMO] Currency exchange distraction at Bukit Bintang',
      'Currency Exchange Scam',
      'Academic demonstration record: the victim is distracted while notes are counted and receives less cash than agreed.',
      3.1466::double precision,
      101.7101::double precision,
      'Bukit Bintang, Kuala Lumpur',
      'Verified',
      now() - interval '7 days'
    ),
    (
      '[DEMO] Pickpocket warning at Petaling Street',
      'Pickpocket',
      'Academic demonstration record: coordinated crowd distraction followed by theft from an unsecured bag.',
      3.1442::double precision,
      101.6965::double precision,
      'Petaling Street, Kuala Lumpur',
      'Verified',
      now() - interval '6 days'
    ),
    (
      '[DEMO] Tourist overcharging near Jonker Walk',
      'Overcharging',
      'Academic demonstration record: a visitor is presented with a final price substantially higher than the displayed price.',
      2.1960::double precision,
      102.2465::double precision,
      'Jonker Walk, Melaka',
      'Verified',
      now() - interval '5 days'
    ),
    (
      '[DEMO] Fake tour service near George Town',
      'Fake Services',
      'Academic demonstration record: payment is requested for a tour that has no valid booking or registered operator.',
      5.4141::double precision,
      100.3292::double precision,
      'George Town, Penang',
      'Verified',
      now() - interval '4 days'
    ),
    (
      '[DEMO] QR payment replacement near JB City Square',
      'QR Code Fraud',
      'Academic demonstration record: a legitimate payment QR code is covered with a code that redirects money to another account.',
      1.4620::double precision,
      103.7645::double precision,
      'JB City Square, Johor Bahru',
      'Verified',
      now() - interval '3 days'
    ),
    (
      '[DEMO] Photo service pressure near Kota Kinabalu waterfront',
      'Photo Scam',
      'Academic demonstration record: an unsolicited photo service is followed by aggressive demands for payment.',
      5.9814::double precision,
      116.0735::double precision,
      'Kota Kinabalu Waterfront, Sabah',
      'Verified',
      now() - interval '2 days'
    ),
    (
      '[DEMO] Transport ticket scam near Kuching Waterfront',
      'Transport Scam',
      'Academic demonstration record: unofficial sellers offer invalid transport tickets and request immediate cash payment.',
      1.5585::double precision,
      110.3447::double precision,
      'Kuching Waterfront, Sarawak',
      'Verified',
      now() - interval '1 day'
    ),
    (
      '[DEMO] Pending report near Batu Caves',
      'Other',
      'Academic demonstration record awaiting admin review. It must not be displayed on the public tourist map.',
      3.2379::double precision,
      101.6840::double precision,
      'Batu Caves, Selangor',
      'Pending',
      now()
    )
)
insert into public.scam_reports (
  title,
  category,
  description,
  latitude,
  longitude,
  location_name,
  verification_status,
  is_official,
  is_active,
  source_reference,
  reported_at
)
select
  demo.title,
  demo.category,
  demo.description,
  demo.latitude,
  demo.longitude,
  demo.location_name,
  demo.verification_status,
  true,
  true,
  null,
  demo.reported_at
from demo_cases as demo
where not exists (
  select 1
  from public.scam_reports as existing
  where existing.title = demo.title
    and existing.is_official = true
);

commit;
