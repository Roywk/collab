# Visit 1MY

Flutter tourist-safety application with a Supabase-backed web/admin interface.

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

The configured Supabase project must have anonymous sign-in enabled for the
tourist flow. Admin accounts need a corresponding `profiles` row whose `role`
is `admin`.

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

## Verification

```text
flutter analyze
flutter test
```
