# CampusFix — Demo Video Script (target 9 min, limit 7–10)

**Setup before recording**
- Phone/emulator A: signed out. Phone/emulator B (or second run): signed in as staff.
- Browser tab: Firebase console → project `campusfix-alu-2026` (Authentication, Firestore, Storage tabs open).
- IDE open on the repo. Demo accounts: `demo.student@alustudent.com`, `demo.staff@alustudent.com` (passwords kept privately, not in the repo).
- Have one real `@alustudent.com` inbox ready for the registration + verification step.

| Time | Rubric item | Show | Say (key points) |
|---|---|---|---|
| 0:00–0:40 | Product thinking | Title + home screen | Problem: campus issues reported informally, no feedback, no prioritisation. CampusFix: report in 30 s, watch it get fixed live, staff triage from one screen. |
| 0:40–2:00 | **Auth** | Register with a non-campus email → error. Register with `@alustudent.com` → Verify screen → click link in inbox → "I've verified" → Home. Console → Authentication shows the new user. Kill and reopen app → still signed in. Logout → login. Wrong password → error. | Domain allow-list in validator **and** rules; email verification required before any data is readable; session persists via `userChanges()` stream; errors mapped to friendly messages. |
| 2:00–3:30 | **CRUD + features** | Tap "+" → submit empty (validation) → pick category, title, description, location, photo (upload progress) → success sheet → "Track my report". Console → Firestore `incidents/{id}` + `history` appear; Storage shows photo. Edit the report, then delete another one while still Submitted. | Batch write: incident + first history entry together. Server timestamps. Owner can edit/delete only while Submitted (rule). Anonymous toggle never stores the name. |
| 3:30–4:30 | **Search / filter** | Reports tab: search "projector", status chips, category chips, clear filters; empty state. | Server streams the list, filtering/search derived in a Riverpod provider — instant, no extra reads. |
| 4:30–6:00 | **RBAC + real time** | Device B (staff): Dashboard queue sorted by priority → open the new report → set priority High → move to In Review then Resolved with a note. Device A updates live: timeline, pill, notification badge. Staff: Hide as spam. | Staff panel only rendered for staff, but security comes from rules: `changedOnly([...])` + `isStaff()` reads role from `users/{uid}`. One batch writes status + history + notification. |
| 6:00–7:30 | **Architecture / state / code** | IDE: folder tree `core / data / logic / ui`; `incident_repository.dart` interface → Firebase + fake implementations; `incident_providers.dart` (`StreamProvider`, `filteredFeedProvider`); a reusable widget (`StatusTimeline`). | UI never imports Firebase. Riverpod providers compose streams → every screen updates from one source. `async/await` + `AsyncValue.guard` for actions; `AsyncValue` for loading/error/data states. |
| 7:30–8:30 | **Security + testing** | `firestore.rules` excerpt; terminal: `cd rules-test && npm test` (11 pass); `flutter test` (18 pass). | Rules tested in the emulator: self-promotion, spoofed reporter, status changes, owner edit window all denied. Fakes make widget/logic tests run without a backend. |
| 8:30–9:00 | Wrap-up | Home screen | Limitations (client-side search, app-side rate limit, in-app notifications) and next steps (Cloud Functions, push, search service). |

**Checklist while recording**: say *why* for each choice; keep the console visible when data changes; don't show passwords.
