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
      '[DEMO] Tourist overcharging near Central Market',
      'Overcharging',
      'Academic demonstration record: a visitor is presented with a final price substantially higher than the displayed price.',
      3.1457::double precision,
      101.6953::double precision,
      'Central Market, Kuala Lumpur',
      'Verified',
      now() - interval '5 days'
    ),
    (
      '[DEMO] Fake tour service near Jalan Alor',
      'Fake Services',
      'Academic demonstration record: payment is requested for a tour that has no valid booking or registered operator.',
      3.1451::double precision,
      101.7088::double precision,
      'Jalan Alor, Kuala Lumpur',
      'Verified',
      now() - interval '4 days'
    ),
    (
      '[DEMO] QR payment replacement near Masjid Jamek',
      'QR Code Fraud',
      'Academic demonstration record: a legitimate payment QR code is covered with a code that redirects money to another account.',
      3.1494::double precision,
      101.6963::double precision,
      'Masjid Jamek, Kuala Lumpur',
      'Verified',
      now() - interval '3 days'
    ),
    (
      '[DEMO] Photo service pressure near Chow Kit',
      'Photo Scam',
      'Academic demonstration record: an unsolicited photo service is followed by aggressive demands for payment.',
      3.1655::double precision,
      101.6983::double precision,
      'Chow Kit, Kuala Lumpur',
      'Verified',
      now() - interval '2 days'
    ),
    (
      '[DEMO] Transport ticket scam near Titiwangsa',
      'Transport Scam',
      'Academic demonstration record: unofficial sellers offer invalid transport tickets and request immediate cash payment.',
      3.1774::double precision,
      101.6953::double precision,
      'Titiwangsa, Kuala Lumpur',
      'Verified',
      now() - interval '1 day'
    ),
    (
      '[DEMO] Pending report near KLCC',
      'Other',
      'Academic demonstration record awaiting admin review. It must not be displayed on the public tourist map.',
      3.1579::double precision,
      101.7117::double precision,
      'KLCC, Kuala Lumpur',
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
