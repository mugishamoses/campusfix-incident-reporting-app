# CampusFix — Campus Incident Reporting App

Flutter (Android/iOS) app for reporting and tracking campus facility & safety issues.
Students report (category, description, location, optional photo, anonymous option) and
follow status live; staff triage, prioritise, resolve and hide spam.

**Stack:** Flutter · Riverpod · go_router · Firebase Auth / Cloud Firestore / Storage.

## Architecture
```
lib/core    theme tokens, constants, validators, router (auth + role redirects)
lib/data    models + repositories (only layer that imports Firebase)
lib/logic   Riverpod providers / notifiers (streams, filters, form + staff actions)
lib/ui      screens + reusable widgets (no Firebase imports)
```
Each repository has a fake (in-memory) and a Firebase implementation behind one interface.

## Run
```bash
flutter pub get
flutter run                                   # real Firebase (project campusfix-alu-2026)
flutter run --dart-define=FAKE_BACKEND=true   # offline demo data, demo accounts
flutter test
cd rules-test && npm install && npm test   # security-rule tests (Firestore emulator, needs Java)
```
Demo accounts (fake backend): `amina@alustudent.com` / `staff@alustudent.com`, password `password`.

## Firebase setup
1. `firebase login` then `dart pub global activate flutterfire_cli && flutterfire configure`
2. Console: enable Email/Password auth, Firestore, Storage (Blaze plan required for Storage).
3. `firebase deploy --only firestore,storage`
4. Promote a staff member: in Firestore, set `users/{uid}.role = "staff"`.

## Security
See `firestore.rules` / `storage.rules`: campus-email + verified-email gate, students can only
create `submitted` reports as themselves and edit/delete them while still submitted, only staff can
change status/priority/visibility, nobody can change their own role, photos ≤ 5 MB images only.
