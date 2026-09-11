-- Visit 1MY - Module 1 presentation dataset.
-- Run only in the coursework/demo Supabase project, not a production system.
-- Safe to rerun: titles already present are skipped and no existing rows change.

begin;

with presentation_cases (
  title,
  category,
  description,
  latitude,
  longitude,
  location_name,
  amount_lost,
  reported_at
) as (
  values
    ('Rental Deposit Fraud Near Setapak Central', 'Fake Services', 'A property advertiser requested an advance deposit before viewing and stopped responding after payment.', 3.2049::double precision, 101.7216::double precision, 'Setapak Central, Kuala Lumpur', 1200::numeric, now() - interval '6 days'),
    ('QR Payment Replacement at Setapak Market', 'QR Code Fraud', 'A payment QR label was replaced with another account code, redirecting the victim payment.', 3.1988::double precision, 101.7186::double precision, 'Setapak Market, Kuala Lumpur', 350::numeric, now() - interval '5 days'),
    ('Unlicensed Taxi Overcharge in Wangsa Maju', 'Taxi Scam', 'A driver refused to use the meter and demanded an inflated fare from visitors.', 3.2058::double precision, 101.7319::double precision, 'Wangsa Maju, Kuala Lumpur', 180::numeric, now() - interval '4 days'),
    ('Fake Event Ticket Seller at Danau Kota', 'Fake Services', 'Tickets sold through an unofficial agent could not be validated at the venue.', 3.2054::double precision, 101.7174::double precision, 'Danau Kota, Setapak', 240::numeric, now() - interval '3 days'),
    ('Phishing Payment Link Shared in Setapak', 'Phishing', 'A message impersonating a booking provider directed visitors to a fraudulent payment page.', 3.1956::double precision, 101.7124::double precision, 'Setapak, Kuala Lumpur', 800::numeric, now() - interval '2 days'),
    ('Cash Change Distraction Near Sri Rampai', 'Currency Exchange Scam', 'The victim received less cash than agreed after being distracted during counting.', 3.1982::double precision, 101.7371::double precision, 'Sri Rampai, Kuala Lumpur', 500::numeric, now() - interval '1 day'),
    ('Transport Booking Scam Near Taman Melati', 'Transport Scam', 'An unofficial seller accepted payment for a transport booking that did not exist.', 3.2196::double precision, 101.7218::double precision, 'Taman Melati, Setapak', 420::numeric, now() - interval '18 hours'),
    ('Mobile Wallet Impersonation at Wangsa Walk', 'Phishing', 'A caller impersonating wallet support requested a verification code and transferred funds.', 3.1986::double precision, 101.7425::double precision, 'Wangsa Walk, Kuala Lumpur', 950::numeric, now() - interval '6 hours'),

    ('Tour Package Deposit Scam in Setapak', 'Fake Services', 'An online operator collected deposits for a tour package without confirming any booking.', 3.2015::double precision, 101.7242::double precision, 'Setapak, Kuala Lumpur', 1600::numeric, date_trunc('month', now()) + interval '1 day 10 hours'),
    ('Counterfeit Gift Card Offer at Danau Kota', 'Gift Card Scam', 'Discounted gift cards were offered but the supplied codes had already been redeemed.', 3.2072::double precision, 101.7161::double precision, 'Danau Kota, Setapak', 300::numeric, date_trunc('month', now()) + interval '3 days 14 hours'),
    ('Pickpocket Distraction Near Sentul Station', 'Pickpocket', 'A coordinated distraction was used to remove a wallet from an unsecured bag.', 3.1788::double precision, 101.6951::double precision, 'Sentul, Kuala Lumpur', 650::numeric, date_trunc('month', now()) + interval '5 days 16 hours'),
    ('Online Accommodation Listing in Setapak', 'Fake Services', 'A copied accommodation listing was used to request payment outside the booking platform.', 3.2091::double precision, 101.7288::double precision, 'Setapak, Kuala Lumpur', 1350::numeric, date_trunc('month', now()) + interval '7 days 11 hours'),

    ('Currency Exchange Short-Change at Bukit Bintang', 'Currency Exchange Scam', 'The amount handed to a visitor was lower than the amount displayed during the exchange.', 3.1466::double precision, 101.7108::double precision, 'Bukit Bintang, Kuala Lumpur', 700::numeric, date_trunc('year', now()) + interval '14 days 12 hours'),
    ('Fake Taxi Booking Near KLCC', 'Taxi Scam', 'A fake booking representative requested an advance transfer for transport that never arrived.', 3.1579::double precision, 101.7123::double precision, 'KLCC, Kuala Lumpur', 260::numeric, date_trunc('year', now()) + interval '1 month 9 days 13 hours'),
    ('Invalid Attraction Tickets at Central Market', 'Fake Services', 'Unofficial attraction tickets sold to visitors were rejected when presented.', 3.1457::double precision, 101.6953::double precision, 'Central Market, Kuala Lumpur', 480::numeric, date_trunc('year', now()) + interval '2 months 18 days 15 hours'),
    ('QR Payment Redirection Near Petaling Street', 'QR Code Fraud', 'A modified payment code redirected a purchase payment to an unrelated account.', 3.1441::double precision, 101.6975::double precision, 'Petaling Street, Kuala Lumpur', 320::numeric, date_trunc('year', now()) + interval '3 months 7 days 17 hours'),
    ('Photography Payment Pressure at Chow Kit', 'Photo Scam', 'An unsolicited photography service was followed by aggressive demands for payment.', 3.1674::double precision, 101.6980::double precision, 'Chow Kit, Kuala Lumpur', 150::numeric, date_trunc('year', now()) + interval '4 months 21 days 12 hours'),
    ('Fraudulent Airport Transfer at KL Sentral', 'Transport Scam', 'A seller collected payment for an airport transfer without assigning a real vehicle.', 3.1343::double precision, 101.6861::double precision, 'KL Sentral, Kuala Lumpur', 380::numeric, date_trunc('year', now()) + interval '5 months 11 days 9 hours'),
    ('Restaurant Menu Price Substitution in Bangsar', 'Overcharging', 'A different higher-priced menu was presented when the visitor requested the final bill.', 3.1292::double precision, 101.6784::double precision, 'Bangsar, Kuala Lumpur', 210::numeric, date_trunc('year', now()) + interval '6 months 16 days 20 hours'),
    ('Fake Delivery Fee Request in Cheras', 'Phishing', 'A fraudulent delivery message requested card details through an imitation tracking website.', 3.1068::double precision, 101.7259::double precision, 'Cheras, Kuala Lumpur', 560::numeric, date_trunc('year', now()) + interval '7 months 8 days 10 hours'),

    ('Tourist SIM Registration Scam at KLCC', 'Fake Services', 'A seller charged for a SIM registration service but supplied an inactive card.', 3.1592::double precision, 101.7111::double precision, 'KLCC, Kuala Lumpur', 190::numeric, date_trunc('year', now()) - interval '11 months' + interval '12 days'),
    ('Payment Card Phishing Near Bukit Bintang', 'Phishing', 'A fake refund form collected payment card information from a visitor.', 3.1478::double precision, 101.7134::double precision, 'Bukit Bintang, Kuala Lumpur', 1100::numeric, date_trunc('year', now()) - interval '9 months' + interval '8 days'),
    ('Unofficial Transport Pass at Masjid Jamek', 'Transport Scam', 'An invalid public transport pass was sold by an unofficial street vendor.', 3.1494::double precision, 101.6963::double precision, 'Masjid Jamek, Kuala Lumpur', 120::numeric, date_trunc('year', now()) - interval '6 months' + interval '19 days'),
    ('Gift Card Payment Demand Near Brickfields', 'Gift Card Scam', 'A caller impersonating an authority demanded settlement using retail gift cards.', 3.1328::double precision, 101.6878::double precision, 'Brickfields, Kuala Lumpur', 2000::numeric, date_trunc('year', now()) - interval '3 months' + interval '24 days')
)
insert into public.scam_reports (
  title,
  category,
  description,
  latitude,
  longitude,
  location_name,
  amount_lost,
  evidence_urls,
  verification_status,
  is_official,
  is_active,
  source_reference,
  reported_at,
  created_at,
  updated_at
)
select
  presentation.title,
  presentation.category,
  presentation.description,
  presentation.latitude,
  presentation.longitude,
  presentation.location_name,
  presentation.amount_lost,
  '{}'::text[],
  'Verified',
  true,
  true,
  null,
  presentation.reported_at,
  presentation.reported_at,
  presentation.reported_at
from presentation_cases as presentation
where not exists (
  select 1
  from public.scam_reports as existing
  where existing.title = presentation.title
);

commit;
