# SmartClean City — Deployment Log

> Generated: 21 May 2026
> Sprint: Enterprise-Grade Refactoring — Login Freeze, Mission Pickup, Vulnerability Hardening

---

## 1. Executive Summary

Three architectural issues were diagnosed and resolved in this sprint:

### Bug #1 — Mobile Login Freeze (Root Cause: StreamBuilder / native auth delay)
The `AuthWrapper` relied on a `StreamBuilder<User?>` listening to `FirebaseAuth.instance.authStateChanges()`. On Android, Google Play Services can delay the stream emission after `signInWithEmailAndPassword()` completes. The `StreamBuilder`'s builder function was never called during this gap, so the `currentUser` fallback was never evaluated. The `ConnexionScreen` persisted with its loading spinner indefinitely.

**Fix:** Refactored `AuthWrapper` into a `StatefulWidget`. The state stores a `_user` field initialized from `FirebaseAuth.instance.currentUser` synchronously. A `_onLoginSuccess()` callback is passed to `ConnexionScreen`; on login success, the callback calls `setState` which immediately re-runs `build()`. The `build()` method reads `_user ?? FirebaseAuth.instance.currentUser`, so even if the stream hasn't fired, the authenticated user is detected and the UI routes to the correct dashboard. The inner `FutureBuilder`'s `.get()` call is cached by `_lastUid` to avoid redundant Firestore reads on parent rebuilds, and a 10-second timeout prevents hanging.

### Bug #2 — Driver Dashboard Empty (Root Cause: missing `chauffeur_id` + query mismatch)
Citizen-created reports had no `chauffeur_id` field. The driver's "Nouveaux" tab queried `where('chauffeur_id', isEqualTo: uid)` combined with `where('statut', ...)`. Firestore equality filters exclude documents where the field is missing/null, so drivers saw zero reports. Additionally, the admin UI had no mechanism to assign a driver to a report, making it impossible for drivers to ever see any report.

**Fix:** Implemented a "Mission Pickup" pattern:
- Citizen writes `chauffeur_id: ''` on report creation — a non-null empty string that new queries can match.
- "Nouveaux" tab queries `where('statut', isEqualTo: 'en attente')` without any `chauffeur_id` filter — all drivers see all pending reports city-wide.
- "En cours" and "Terminé" tabs filter by `chauffeur_id == currentDriverUid` — exclusive to the assigned driver.
- `MissionDetailScreen` now detects `statut == 'en attente'` and shows an **"Accepter la mission"** button. Tapping it updates the Firestore document: sets `chauffeur_id = driverUid`, `statut = 'en cours'`. Live streams react automatically (no manual refresh).

### Vulnerability Hardening
- **Null guards:** `FirebaseAuth.instance.currentUser!.uid` replaced with `currentUser?.uid ?? ''` in all driver queries.
- **Soft-delete:** Report cancellation changed from hard `.delete()` to `.update({'statut': 'annulé'})`, preserving relational integrity.
- **Firestore `.get()` timeout:** 10-second timeout added to profile fetch in `AuthWrapper`.

---

## 2. File-by-File Modification Log

| # | File | Change Type | Lines Changed | Description |
|---|------|-------------|---------------|-------------|
| 1 | `lib/features/auth/auth_wrapper.dart` | **Rewrite** | 1–164 | Converted `StatelessWidget` → `StatefulWidget`. Stores `_user` from `currentUser` synchronously in `initState`. Listens to both `authStateChanges()` and `idTokenChanges()` for redundancy. Caches `_profileFuture` keyed by `_lastUid` to prevent redundant `.get()` calls. Added `_onLoginSuccess()` callback passed to `ConnexionScreen`. 10-second timeout on `.get()`. |
| 2 | `lib/features/auth/connexion_screen.dart` | Modify | 11–13, 49–52 | Added `VoidCallback? onLoginSuccess` parameter. On successful `signInWithEmailAndPassword()`, calls `widget.onLoginSuccess?.call()` to signal `AuthWrapper` to rebuild immediately. |
| 3 | `lib/features/reports/nouveau_signalement_screen.dart` | Modify | 258 | Added `'chauffeur_id': ''` to the report's Firestore document, making it queryable by the driver's "Nouveaux" tab. |
| 4 | `lib/features/driver/driver_dashboard.dart` | **Rewrite** (queries) | 1 (import), 73 (removed getter), 226–252 (badge), 258–264 (list query), 324–348 (onTap), 382–387 (stat card query) | Added `mission_detail_screen.dart` import. Removed `_listIsTappable` getter. Main list query now conditionally includes/excludes `chauffeur_id` filter based on `_currentFilter`. `_FilterStatCard` counts use same conditional pattern. "Nouveaux" tab cards navigate to `MissionDetailScreen` on tap; "En cours" cards focus map. Null guards on all `currentUser` accesses. |
| 5 | `lib/features/driver/mission_detail_screen.dart` | **Rewrite** | 1–376 | Added `FirebaseFirestore` and `FirebaseAuth` imports. Detects `statut == 'en attente'` via `_isPickable` getter. Shows orange "En attente d'affectation" status + **"Accepter la mission"** button for pickable reports. Shows purple "Mission en cours" status + existing navigation/complete buttons for active missions. `_accepterMission()` shows confirmation dialog, writes `chauffeur_id` + sets `statut = 'en cours'`, then pops back to dashboard. |
| 6 | `lib/features/home/accueil_screen.dart` | Modify | 385–388 | Hard `.delete()` replaced with `.update({'statut': 'annulé'})`. |
| 7 | `lib/features/reports/mes_signalements_screen.dart` | Modify | 341–344 | Hard `.delete()` replaced with `.update({'statut': 'annulé'})`. |

---

## 3. Post-Deployment Instructions

### 3.1 Firebase Console — Composite Indexes

The following composite indexes must be created manually in the [Firebase Console](https://console.firebase.google.com/) under **Firestore Database → Indexes** for the app's project.

| Collection | Fields indexed | Query served | Reason |
|------------|---------------|--------------|--------|
| `signalements` | `citoyen_id` ASC, `timestamp` DESC | `AccueilScreen` + `MesSignalementsScreen` "Tous" filter | `where('citoyen_id', ...)` + `orderBy('timestamp', ...)` |
| `signalements` | `chauffeur_id` ASC, `statut` ASC | Driver "En cours" / "Terminé" tabs | `where('chauffeur_id', ...)` + `where('statut', ...)` |
| `signalements` | `statut` ASC, `chauffeur_id` ASC, `timestamp_fin` DESC | `DriverHistory` | `where('statut', ...)` + `where('chauffeur_id', ...)` + `orderBy('timestamp_fin', ...)` |

**To create an index:**
1. Open [Firebase Console → Firestore → Indexes](https://console.firebase.google.com/project/_/firestore/indexes).
2. Click **"Add Index"**.
3. Enter the collection name (e.g., `signalements`).
4. Add each field with the correct sort order (ASC for most, DESC for `timestamp` / `timestamp_fin`).
5. Click **"Create"** and wait for the status to change from "Creating" to "Enabled" (typically 1–3 minutes).

> Without these indexes, Firestore **throws an error** on the affected queries — they will fail silently unless caught by the error card UI.

### 3.2 Build Commands

```bash
# Navigate to project root
cd smartclean

# Clean build artifacts
flutter clean

# Regenerate platform-specific files
flutter pub get

# Generate launcher icons (Android, iOS, Web)
flutter pub run flutter_launcher_icons

# Build Android APK (split by ABI for smaller size)
flutter build apk --split-per-abi

# Build Android App Bundle (for Play Store)
flutter build appbundle

# Build iOS (requires macOS + Xcode)
flutter build ios --no-codesign

# Build Web (admin panel + citizen web)
flutter build web

# Run linting check
flutter analyze
```

### 3.3 Verification Checklist

After deploying, verify each scenario:

#### Login Flow (Mobile Android/iOS)
- [ ] Fresh install → login screen appears (loading spinner briefly on cold start, then login form)
- [ ] Enter valid credentials → tap "Se connecter" → **transitions to dashboard without cold restart** (critical — this was Bug #1)
- [ ] Enter invalid credentials → error SnackBar shown → still on login screen → can retry
- [ ] Logout → returns to login screen
- [ ] Kill app → reopen → **automatically logs back in** via auth persistence (no login prompt if previously authenticated)

#### Mission Pickup Flow (Driver)
- [ ] Citizen creates a new report → appears in ALL drivers' "**Nouveaux**" tab with count incrementing
- [ ] Tap a "Nouveaux" card → navigates to `MissionDetailScreen` with orange "En attente" badge
- [ ] Tap **"Accepter la mission"** → confirmation dialog → document updated → returns to dashboard
- [ ] Accepted report disappears from "Nouveaux" tab and appears in "**En cours**" tab
- [ ] Tap "En cours" card → navigates to `MissionDetailScreen` with purple "Mission en cours" badge + navigation button
- [ ] "Terminé" tab shows completed missions only for this driver
- [ ] Other drivers see the accepted report in their "Nouveaux" count until it's accepted by someone (auto-updates via live stream)

#### Soft-Delete (Citizen)
- [ ] Citizen cancels a report → report status changes to `annulé` (not deleted)
- [ ] Canceled report appears in "Tous" filter of `MesSignalementsScreen`
- [ ] Canceled report does NOT appear in the driver's "Nouveaux" tab (because driver queries only `statut == 'en attente'`)
- [ ] Admin can see canceled reports in `AdminSignalementsView` via "Tous" filter

#### Admin Panel (Web — must remain unchanged)
- [ ] Admin login → dashboard with 4 sidebar items
- [ ] Signalements view: filter pills, data table, accept/reject actions
- [ ] Citoyens view: role tabs, promote/delete, search
- [ ] Parameters view: toggle locale (FR/AR)

#### Localization
- [ ] Toggle locale from FR to AR and back — all screens reflect the change immediately
- [ ] RTL layout works correctly in Arabic mode

### 3.4 Rollback Plan

If critical issues are found after deployment:

```bash
# Revert the last commit
git revert HEAD

# Or reset to the previous stable commit
git log --oneline -5
git reset --hard <previous-stable-hash>

# Rebuild and redeploy
flutter clean
flutter pub get
flutter build apk --split-per-abi
```

### 3.5 Known Limitations / Future Work

1. **GeoUtils scalability:** `isDuplicateLocation()` fetches ALL pending reports — should add a geographic bounding box when the report base grows beyond ~1000 documents.
2. **Admin driver assignment:** The admin UI currently has no way to `chauffeur_id` to a report manually. If needed, add a dropdown in `_showReportDetails()` in `admin_signalements_view.dart`.
3. **`timestamp_fin` field:** `DriverHistory` queries `orderBy('timestamp_fin', ...)` but no code writes this field. The `MissionValidationScreen` should be updated to write `timestamp_fin` when a mission is marked complete.
4. **`annulé` status in `SignalementModel`:** The model's `doneSteps` returns 1 for unknown statuses — consider adding explicit handling for `annulé` if timeline visualization is needed.
5. **Firestore security rules:** No security rules are documented. For production, ensure rules are set to validate `chauffeur_id` writes and prevent unauthorized access.
