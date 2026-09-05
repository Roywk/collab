# Visit 1MY

Flutter tourist-safety application with a Supabase-backed web/admin interface.

## Module 4: Emergency Assistance

Module 4 provides the emergency dashboard and the complete **Bank Hotline &
Kill Switch** flow from the supplied mobile UI: user-specific bank retrieval,
search and country filters, bank details, freeze confirmation, call audit log,
and native phone-dialer hand-off.

Before using the module, run
`supabase/migrations/202608310001_module_4_emergency_banking.sql` in the
Supabase SQL Editor. It creates the `banks`, `user_banks`, and
`kill_switch_requests` tables, enables row-level security, and inserts the
Maybank and CIMB hotline records from the UI.

The registration flow should insert the signed-in user's selected bank into
`user_banks`. A Flutter insert example and a SQL Editor test insert are included
at the bottom of the migration. The emergency directory contains no hard-coded
bank names or hotline numbers.

### Incident Report Generator setup

The Incident Report Generator provides the complete form, verification,
English/Bahasa Melayu translation, report preview, PDF generation, and download
flow.

1. Run `supabase/migrations/202608310002_module_4_incident_reports.sql` in the
   Supabase SQL Editor and choose **Run and enable RLS** if prompted.
2. Add the Gemini API key as a Supabase Edge Function secret. Never place this
   key in Flutter or `config/dev.json`:

   ```text
   supabase secrets set GEMINI_API_KEY=your_key_here
   ```

3. Optionally select a different model; the default is
   `gemini-3.5-flash-lite`:

   ```text
   supabase secrets set GEMINI_MODEL=gemini-3.5-flash-lite
   ```

4. Deploy the authenticated translation function:

   ```text
   supabase functions deploy translate-incident-report
   ```

The function uses the Gemini Interactions API with structured output and
`store: false`. Report rows are protected by RLS, so each signed-in user can
only access their own reports.

### Help Nearby setup

Help Nearby checks location permission before showing its permission page. If
permission was already granted, the app goes directly to the nearest-facilities
screen. Facilities are loaded from Supabase, filtered by service type, sorted
by live GPS distance, and shown on an OpenStreetMap preview.

1. Run `supabase/migrations/202609010001_module_4_help_nearby.sql` in the
   Supabase SQL Editor and keep RLS enabled.
2. Verify every prototype facility's address, coordinates, telephone number,
   operating hours, and official source before setting `is_verified` to true.
3. Rebuild the mobile app after changing native location-permission metadata.

`Navigate Now` uses a universal Google Maps directions URL with the user's
current position and the selected facility address. This URL handoff does not
require a Google Maps API key.

## Module 1: Scam Alert & Scam Map

Module 1 now provides:

- an OpenStreetMap scam map with Verified/Pending markers and clustering;
- live GPS tracking and Haversine-based warnings within 200 metres;
- landmark/location search, category filters, and marker detail sheets;
- SQLite caching of scam data and automatic caching of viewed map tiles;
- an admin form for publishing official Verified scam cases;
- coordinate validation with a map preview;
- threat-density analytics with PDF and CSV export.

## Supabase setup

Before running Module 1, execute
`supabase/migrations/202608240001_module_1_scam_map.sql` in the Supabase SQL
Editor. The migration adds the map fields, indexes, coordinate constraints, and
row-level security policies used by the app.

The tourist flow uses Supabase email/password accounts. Anonymous sign-in is no
longer required.

### User accounts, profile, and admin login

Run these migrations in this order so registration can link each user to the
data used by Bank Hotline and Share My Location / SOS:

1. `supabase/migrations/202608310001_module_4_emergency_banking.sql`
2. `supabase/migrations/202609020001_module_4_sos_location.sql`
3. `supabase/migrations/202609050000_auth_profiles.sql`
4. `supabase/migrations/202609050003_multi_bank_registration.sql`

In **Supabase Dashboard > Authentication > Providers**, keep the Email provider
enabled. The mobile registration form creates the Supabase Auth account and the
database trigger creates its `profiles` row, one `user_banks` link for every
selected bank, and its primary `emergency_contacts` row. The first selected
bank is marked as primary. Passwords remain in Supabase Auth and are never
stored in a public database table.

The mobile footer includes **Profile** after **Learn**. The profile page lets a
signed-in user update their personal details, preferred language, primary bank,
and primary emergency contact.

For an administrator, first create an email/password account in **Authentication
> Users**, then insert that Auth user into the separate administrator table:

```sql
insert into public.admin_accounts (id, email, display_name)
select id, email, 'Visit 1MY Administrator'
from auth.users
where email = 'admin@example.com'
on conflict (id) do update set
  email = excluded.email,
  display_name = excluded.display_name,
  is_active = true,
  updated_at = now();
```

Tourists remain in `profiles`; only active records in `admin_accounts` can pass
the admin website login. Both account types authenticate through Supabase Auth.
Passwords are hashed and managed by Auth—they are intentionally never stored in
either public table.

The mobile login rejects accounts found in `admin_accounts`, and the admin
login rejects accounts that are not in that table. Profile RLS also prevents an
active administrator from reading or updating tourist profile data.

For optional dummy records, first create the two email users listed at the top
of `supabase/seeds/202609050001_demo_accounts.sql` in **Authentication > Users**,
then run that seed in the SQL Editor. Use temporary test passwords and do not
deploy those demo accounts to production.

When running Flutter Web, open `/#/admin` after the local origin to go directly
to the responsive admin login (for example, `http://localhost:55948/#/admin`).
Mobile users can also reach it through **Administrator Login** on the sign-in
screen.

## Run from Android Studio

1. Open this directory as the Flutter project.
2. Run `flutter pub get` (or click **Pub get** in `pubspec.yaml`).
3. In **Run > Edit Configurations**, add this to **Additional run args**:

   ```text
   --dart-define-from-file=config/dev.json
   ```

4. Select an Android emulator or connected phone and run `lib/main.dart`.
5. Grant location and notification permissions when prompted.

For command-line use:

```text
flutter run --dart-define-from-file=config/dev.json
```

## Share My Location / SOS setup

Run `supabase/migrations/202609020001_module_4_sos_location.sql` in the
Supabase SQL Editor. Keep Row Level Security enabled. During registration,
store at least one contact in `emergency_contacts` with `is_primary = true`.
Phone numbers must use E.164 international format, such as `+447700900123`.

The SOS button retrieves that contact and the device's live GPS coordinates,
then opens WhatsApp with a pre-filled message and Google Maps link. WhatsApp
requires the user to tap **Send**; the app records only that the composer was
opened. If WhatsApp cannot be opened, the app attempts the device SMS composer.

## Verification

```text
flutter analyze
flutter test
```

## Admin bank hotline management

Run `supabase/migrations/202609050001_module_4_admin_bank_directory.sql`
after the emergency banking and user-profile migrations. The policy permits
CRUD only when the signed-in user has an active `admin_accounts` record.

The admin website manages the shared `banks` directory. Tourist accounts store
only `user_banks.user_id` and `user_banks.bank_id`; the mobile app joins that
bank ID to `banks` whenever it loads hotline details. If an admin removes a bank
that is already referenced by a user, it is safely marked inactive instead of
breaking the user's foreign-key relationship.

## Admin emergency facility management

Run `supabase/migrations/202609050002_module_4_admin_emergency_facilities.sql`
after the Help Nearby migration. Admin accounts can then add, edit, deactivate,
or delete PDRM, Bomba, and RELA directory records from **Emergency Facilities**
in the web admin sidebar. The mobile Help Nearby service reads active records
from this same `emergency_facilities` table, so no synchronization job or
duplicate facility table is required.
