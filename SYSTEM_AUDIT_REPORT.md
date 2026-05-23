# SYSTEM AUDIT REPORT — SmartClean City

**Auditor**: Big Pickle (Lead System Auditor)  
**Date**: May 20, 2026  
**Version**: 1.0.0  
**Project Type**: Flutter Multi-Platform (Mobile, Web, Desktop)  
**Backend**: Firebase (Auth, Firestore, Hosting)

---

## 1. Project Structure (Analyzed Tree)

```
smartclean/
├── lib/
│   ├── main.dart                          # Entry point, locale management
│   ├── firebase_options.dart              # Firebase multi-platform config
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_keys.dart              # Groq + Gemini API keys
│   │   │   ├── app_colors.dart            # Design system color tokens
│   │   │   └── app_strings.dart           # English strings (UNUSED)
│   │   ├── l10n/app_localizations.dart    # FR/AR localization delegate
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Firebase Auth wrapper
│   │   │   ├── ai_service.dart            # Groq API chat (Eco-Bot)
│   │   │   ├── ai_vision_service.dart     # Gemini image validation (MOCKED)
│   │   │   └── geo_utils.dart             # Haversine + duplicate detection
│   │   └── theme/app_theme.dart           # Material3 theme with locale fonts
│   ├── features/
│   │   ├── admin/
│   │   │   ├── admin_dashboard_shell.dart # Sidebar + TopBar shell
│   │   │   └── views/
│   │   │       ├── admin_dashboard_view.dart   # KPIs, bar chart, recent table
│   │   │       ├── admin_carte_view.dart       # Google Maps live markers
│   │   │       ├── admin_signalements_view.dart # Data table + filters + actions
│   │   │       ├── admin_flotte_view.dart      # Driver cards + creation dialog
│   │   │       ├── admin_citoyens_view.dart    # Citizen leaderboard
│   │   │       └── admin_parametres_view.dart  # Admin profile + security
│   │   ├── auth/
│   │   │   ├── auth_wrapper.dart           # Role-based routing orchestrator
│   │   │   ├── connexion_screen.dart       # Login form
│   │   │   ├── inscription_screen.dart     # Registration form
│   │   │   ├── complete_profile_screen.dart # Post-signup profile completion
│   │   │   ├── verification_screen.dart    # Email verification gate
│   │   │   └── forgot_password_screen.dart # Password reset
│   │   ├── chatbot/eco_bot_screen.dart    # Chat UI with Groq API
│   │   ├── driver/
│   │   │   ├── driver_main_screen.dart     # Bottom nav shell
│   │   │   ├── driver_dashboard.dart       # Filter stat cards + mission list
│   │   │   ├── driver_map.dart            # Map with custom pin markers
│   │   │   ├── mission_active_screen.dart  # Active mission execution flow
│   │   │   ├── mission_detail_screen.dart  # Legacy detail screen
│   │   │   ├── mission_validation_screen.dart # Legacy validation screen
│   │   │   ├── driver_history.dart        # Completed missions with before/after
│   │   │   └── driver_profile.dart        # Driver profile + stats
│   │   ├── home/accueil_screen.dart       # Citizen home with stats + recent
│   │   ├── profile/
│   │   │   ├── profil_citoyen_screen.dart # Citizen profile + stats
│   │   │   ├── modifier_profil_screen.dart # Edit pseudo
│   │   │   ├── notifications_screen.dart  # Placeholder ("Coming soon")
│   │   │   └── confidentialite_screen.dart # Placeholder ("Coming soon")
│   │   └── reports/
│   │       ├── nouveau_signalement_screen.dart # Photo + GPS + submit flow
│   │       ├── mes_signalements_screen.dart    # Filtered list with live updates
│   │       └── detail_signalement_screen.dart  # Timeline + photo + info
│   └── shared/
│       ├── firestore/signalement_model.dart  # Typed Firestore model + badges
│       ├── mock/mock_data.dart               # Mock data (UNUSED in prod)
│       ├── navigation/main_shell.dart        # Citizen bottom nav shell
│       └── widgets/
│           ├── app_text_field.dart           # "No-Line" design text field
│           ├── bottom_nav_bar.dart           # Unused legacy nav bar
│           ├── glass_container.dart          # Glassmorphic container
│           ├── primary_button.dart           # Gradient primary button
│           ├── report_status_chip.dart       # Status chip (UNUSED in prod)
│           └── secondary_button.dart         # Ghost outline button
```

---

## 2. Data Flow: Signalement Lifecycle

```
CITIZEN                           ADMIN                          DRIVER
   │                                │                              │
   ├─ Photo (camera)                │                              │
   ├─ GPS (geolocator)              │                              │
   ├─ Duplicate check (30m radius)  │                              │
   ├─ AI validation (mocked)        │                              │
   └─ Firestore: signalements.add   │                              │
       statut: "en attente" ────────┼──►  Dashboard sees stat →   │
       citizen_id, photo_base64     │     Reject → "rejeté"       │
                                    │     Accept → "en cours" ────┼──► Map sees
                                    │                              │     Accept mission
                                    │                              │     Navigate to location
                                    │                              │     Clean + after-photo
                                    │                              │     AI validation (mocked)
                                    │                              └──► Update:
                                    │   ◄─────────────────────────────── statut: "terminé"
                                    │                                   photo_apres_base64
                                    │                                   citizen gets +10 pts
  ◄── Live status update by ───────┼── Live stream listener ──────┤
      Firestore stream listener     │                              │
```

**Pain point**: No push notification system. Citizens must have the app open and rely on Firestore's real-time listener to see status changes.

---

## 3. Architecture Integrity

| Criteria | Status | Observations |
|---|---|---|
| **Feature isolation** | ✅ Good | Each role (admin/auth/driver/citizen) has its own `features/` subdirectory. No cross-imports between role features. |
| **Component separation** | ⚠️ Mixed | `shared/widgets/` contains reusable components, but several features define private widgets (`_StatusBadge`, `_BottomNav`, `_ActionTile`) that are duplicated. |
| **State management** | ❌ None | No state management library (Provider, Riverpod, Bloc, etc.). Entire app relies on `StreamBuilder` + `setState`. Business logic is embedded in widgets. |
| **Routing** | ⚠️ Redundant | `AuthWrapper` handles role-based routing, but `ConnexionScreen` also manually navigates by role, creating dual routing paths. `go_router` is declared in `pubspec.yaml` but never used. |
| **Localization** | ✅ Good | Custom `AppLocalizations` delegate with full French/Arabic support. Locale persisted to `SharedPreferences`. |
| **Feature parity** | ⚠️ Incomplete | `NotificationsScreen` and `ConfidentialiteScreen` are placeholders. "Voir tout" button in `AccueilScreen` has empty `onPressed`. |

### 3.1 Code Duplication

| File(s) | Duplicated Element | Impact |
|---|---|---|
| `admin_signalements_view.dart`, `admin_dashboard_view.dart`, `admin_carte_view.dart` | `_StatusBadge` widget — identical 3× | Violates DRY; any styling change requires 3 edits |
| `accueil_screen.dart`, `mes_signalements_screen.dart` | `_confirmCancel()` dialog — nearly identical | Logic duplication for report cancellation |
| `main_shell.dart`, `driver_main_screen.dart`, `bottom_nav_bar.dart` | Bottom navigation bar — implemented 3× | `bottom_nav_bar.dart` is unused; existing implementations differ in styling |
| `profil_citoyen_screen.dart`, `driver_profile.dart` | `_ActionTile`, `_StatCard`, font helpers — nearly identical | Each profile screen reimplements the same patterns |
| `admin_signalements_view.dart` (`_DetailRow`), `admin_flotte_view.dart` (`_DetailRow`), `admin_parametres_view.dart` (`_InfoRow`) | Label+value row widgets | 3 implementations of the same concept |
| `mission_active_screen.dart`, `mission_detail_screen.dart`, `mission_validation_screen.dart` | Mission flow screens | 3 screens with overlapping concerns; `mission_detail_screen` and `mission_validation_screen` appear to be legacy code not connected to the main flow |

### 3.2 Dead Code

| File | Status | Notes |
|---|---|---|
| `lib/shared/mock/mock_data.dart` | ❌ UNUSED | Mock data defined but never imported in any production screen |
| `lib/shared/widgets/report_status_chip.dart` | ❌ UNUSED | `ReportStatusChip` widget and `ReportStatus` enum never used |
| `lib/shared/widgets/bottom_nav_bar.dart` | ❌ UNUSED | `AppBottomNavBar` defined but the app uses inline implementations |
| `lib/core/constants/app_strings.dart` | ❌ UNUSED | All screens use `AppLocalizations.t()` instead |
| `lib/features/driver/mission_detail_screen.dart` | ❌ UNUSED | Legacy; `MissionActiveScreen` is the current implementation |
| `lib/features/driver/mission_validation_screen.dart` | ❌ UNUSED | Legacy; validation is now inline in `MissionActiveScreen` |
| `go_router` dependency (`pubspec.yaml`) | ❌ UNUSED | Package declared but never imported |

---

## 4. Logic & Bugs

| # | Severity | File:Line | Description | Impact |
|---|---|---|---|---|
| **B1** | 🔴 **CRITICAL** | `driver_profile.dart:314` | **Logout does not sign out of Firebase.** The `se_deconnecter` button calls `Navigator.pushReplacement(ConnexionScreen())` but never calls `FirebaseAuth.instance.signOut()`. The auth state remains alive. | User appears to log out but Firebase session persists. Reopening the app will skip login. |
| **B2** | 🔴 **CRITICAL** | `driver_history.dart:41` | **Hardcoded `chauffeur_id: 'chauffeur_mock'`.** The history query filters by a literal string, not the current user's UID. | History will NEVER show data for real driver accounts. |
| **B3** | 🟠 **HIGH** | `nouveau_signalement_screen.dart:248` | **Weak `id_court` generation.** `Random().nextInt(9000)` gives only 9,000 possible values. Collision probability grows quadratically with dataset size. | Duplicate report IDs after ~120 reports (birthday paradox). |
| **B4** | 🟠 **HIGH** | `connexion_screen.dart:60-82` | **Duplicate role routing logic.** The login screen manually pushes `AdminDashboardShell` or `DriverMainScreen` after successful login. `AuthWrapper` does the same via `authStateChanges()`. | Two parallel routing paths create potential race conditions. If the auth state stream fires before the Navigator completes, the user could be redirected incorrectly. |
| **B5** | 🟠 **HIGH** | `profil_citoyen_screen.dart:37` | **Logout redirects to `InscriptionScreen` instead of `ConnexionScreen`.** After sign out, user is taken to the registration screen. | UX anti-pattern: user wants to log in, not re-register. |
| **B6** | 🟡 **MEDIUM** | `accueil_screen.dart:195` | **"Voir tout" button has empty `onPressed`.** The `TextButton` has `onPressed: () {}`. | Button is rendered but non-functional. |
| **B7** | 🟡 **MEDIUM** | `admin_flotte_view.dart:271-301` | **Secondary Firebase app may not be fully cleaned up on error.** If `createUserWithEmailAndPassword` succeeds but `signOut()` or Firestore `set` fails, the `finally` block deletes the secondary app. However, if the initial `Firebase.initializeApp` succeeds but user creation fails, the secondary app still gets deleted. This is mostly safe, but if `set()` after `signOut()` uses a stale reference, it could fail. | Edge case: user created in Auth but profile not written to Firestore. Orphaned account. |
| **B8** | 🟡 **MEDIUM** | `geo_utils.dart:48-81` | **No index on Firestore query.** `collection.where('statut', isEqualTo: 'en attente').get()` without an index on 'statut' + 'timestamp' will trigger a Firebase console warning. For small datasets this works, but Firestore will recommend a composite index as data grows. | Performance degradation at scale. |
| **B9** | 🟡 **MEDIUM** | `admin_carte_view.dart:433-488` | **Redundant `LayoutBuilder` + `ConstrainedBox` wrapping Google Map.** The map is wrapped in unnecessary layers that could cause layout overflow on narrow screens. | Potential layout issues on small web panels. |
| **B10** | 🟢 **LOW** | `driver_dashboard.dart:275` | **`.where('statut', ...).orderBy('timestamp')` requires composite index.** Firestore needs a composite index on `statut` + `timestamp` descending, which is not explicitly created. Firebase will show a console error/link to create one. | Missing index link in console on first query. |
| **B11** | 🟢 **LOW** | `driver_profile.dart:179` | **Hardcoded chauffeur_id `'chauffeur_mock'`** in profile stats card. Same issue as B2 but for stats, not history. | Stats always show 0 for real drivers. |
| **B12** | 🟢 **LOW** | `AdminDashboardView` line usage of `(d.data() as Map)` | **Unsafe `as Map` cast instead of `Map<String, dynamic>`.** Several casts use `as Map` (not typed) which will fail if Firestore data changes shape. | Potential runtime cast exceptions. |

---

## 5. Performance Analysis

| # | Severity | Area | Issue | Recommendation |
|---|---|---|---|---|
| **P1** | 🔴 **CRITICAL** | Photo storage | **Base64 photos stored in Firestore documents.** This is the #1 anti-pattern for Firestore. Base64 inflates binary by ~33%. The 1 MB document limit is easily hit with multiple photos. Every document read includes the full photo bytes. | Migrate to Firebase Storage + Cloud Functions for thumbnail generation. Store only the download URL in Firestore. |
| **P2** | 🟠 **HIGH** | Image rendering | **No image caching.** Every `Image.memory(base64Decode(...))` decodes the full Base64 string on every build. Even if the document hasn't changed, the image is re-decoded. | Use `cached_network_image` for Storage URLs, or implement an in-memory Base64 cache keyed by document ID + update timestamp. |
| **P3** | 🟠 **HIGH** | Admin Dashboard | **Client-side counting of all documents.** `AdminDashboardView` fetches ALL signalements and ALL citoyens, then filters/counts client-side with `.where(...)` in Dart. For 10k+ documents, this reads all data on every snapshot. | Use Firestore `count()` aggregation queries (available since late 2023) or maintain counter documents updated via server-side increments. |
| **P4** | 🟡 **MEDIUM** | Driver Dashboard | **Redundant Firestore listeners.** Each `_FilterStatCard` opens its own `snapshots()` listener for the same collection with different `statut` filters. 3 cards = 3 listeners when 1 would suffice. | Use a single listener at the parent level and distribute counts. |
| **P5** | 🟡 **MEDIUM** | AccueilScreen | **Nested StreamBuilders.** `AccueilScreen` uses a `StreamBuilder<List<Signalement>>` wrapping a `StreamBuilder<DocumentSnapshot>` for the profile, and each refetches data independently. | Combine streams with `StreamZip` or `FutureBuilder` for the profile. |
| **P6** | 🟢 **LOW** | UI | **`const` constructor violations.** Many `StatefulWidget` constructors are `const` but call `setState` immediately (e.g., EcoBotScreen's `addPostFrameCallback`). | Use `const` only for truly immutable widgets. |

---

## 6. Security Audit

| # | Severity | Area | Finding | Recommendation |
|---|---|---|---|---|
| **S1** | 🔴 **CRITICAL** | Firestore Rules | **No Firestore Security Rules file found.** The project root contains no `firestore.rules`. Without server-side rules, any authenticated user can read/write any collection. Role-based access is only enforced client-side via the `role` field, which is trivially bypassed. | **Immediately deploy Firestore Security Rules.** See Section 8 for recommended rules. |
| **S2** | 🔴 **CRITICAL** | API Keys | **Sensitive keys exposed in client code.** Groq API key (`api_keys.dart`), Gemini API key, Google Maps API key, and Firebase API keys are all embedded in the client binary. | Move Groq/Gemini calls to a Cloud Function proxy. Use Firebase App Check to restrict API access. Restrict Maps API key by HTTP referrer for web and package name for Android. |
| **S3** | 🟠 **HIGH** | Driver Creation | **Secondary Firebase App pattern in `admin_flotte_view.dart`.** While creative, this approach: (a) exposes the account creation password in the UI, (b) has no rate limiting, (c) logs unhashed passwords in memory. | Use an Admin Cloud Function with `firebase-admin` SDK to create driver accounts server-side with validated inputs. |
| **S4** | 🟠 **HIGH** | Auth | **No rate limiting on login/registration.** `connexion_screen.dart` and `inscription_screen.dart` allow unlimited attempts. Brute force protection relies solely on Firebase Auth's built-in thresholds. | Implement exponential backoff on the client and monitor Firebase Auth usage. |
| **S5** | 🟡 **MEDIUM** | Auth | **Email verification bypass for admin/chauffeur.** In `auth_wrapper.dart`, verification is skipped for `role == 'admin'` or `role == 'chauffeur'`. While intentional, there's no secondary validation that the admin account itself was created legitimately. | Document this design decision clearly. Consider requiring admin email verification as well. |
| **S6** | 🟡 **MEDIUM** | Data | **`citoyen_id` is sent as client-controlled string.** `citoyen_id: FirebaseAuth.instance.currentUser?.uid ?? 'unknown'` could be `'unknown'` if the user session is lost mid-operation. | Read `currentUser` once at the start of submission and fail early if null. |

---

## 7. SWOT Analysis

### Strengths (Points forts)

| Category | Strength |
|---|---|
| **Architecture** | Clean feature-based folder structure with clear separation of roles (Citizen/Admin/Driver). |
| **Design System** | Excellent "Urban Organicism" design language with consistent `AppColors`, typography (Manrope/Tajawal/Cairo), and glassmorphic components. |
| **Localization** | First-class French/Arabic support with persisted locale, RTL-aware layouts, and localized fonts. |
| **Real-time UX** | Full use of Firestore `snapshots()` for live-updating dashboards, maps, and mission lists. |
| **AI Integration** | Groq API for Eco-Bot chatbot and Gemini vision (mocked but architected) for image validation. |
| **Gamification** | Citizen points system (+10 per resolved report) with leaderboard in admin panel. |
| **Navigation** | Cross-tab communication via `ValueNotifier<LatLng>` between driver dashboard and map is elegant. |
| **Photo Quality** | `imageQuality: 25` and `maxWidth: 1080` are good defaults balancing quality and Firestore size limits. |
| **Error Handling** | Consistent `mounted` checks after every `await`, graceful error cards for Firestore failures. |

### Weaknesses (Points faibles)

| Category | Weakness | Impact |
|---|---|---|
| **State Management** | No state management library. Full reliance on `StreamBuilder` + `setState`. | Difficult to test, no business logic layer, widget rebuild inefficiency. |
| **Code Duplication** | 6+ instances of duplicated widgets (StatusBadge, BottomNav, ActionTile, DetailRow). | Maintenance burden; inconsistent behavior if one copy is updated but others are not. |
| **Dead Code** | 6+ files/declarations that are imported but never used (`mock_data.dart`, `report_status_chip.dart`, `app_strings.dart`, `go_router`, `mission_detail_screen.dart`, `mission_validation_screen.dart`). | Confuses developers; wastes compile time; suggests incomplete refactoring. |
| **Data Architecture** | Base64 photos stored directly in Firestore documents. | Will hit 1 MB document limit; no CDN; no caching; expensive reads. |
| **Firestore Rules** | No server-side security rules. | Any authenticated user can read/write all data. Critical vulnerability. |
| **Routing** | Dual routing: `AuthWrapper` + manual routing in `ConnexionScreen`. | Potential race conditions; confusing control flow. |
| **Hardcoded Values** | `chauffeur_mock` ID in 2 places. | Production driver data never loads. |
| **Testing** | Zero meaningful test coverage. `test/widget_test.dart` is the default Flutter template test. | No regression safety net. |

### Errors & Bugs (Critical runtime crashes)

| # | File:Line | Condition | Result |
|---|---|---|---|
| E1 | `auth_wrapper.dart:56` | If `profileSnapshot.data!.data()` returns null or a non-Map type | `as Map<String, dynamic>?` will throw `_CastError` |
| E2 | `admin_flotte_view.dart:291` | If `secondaryAuth.createUserWithEmailAndPassword()` fails, `credential.user!.uid` will throw `NullError` | Crash on null user after failed creation |
| E3 | `auth_wrapper.dart:35` | If `currentUser?.uid` is null, `.doc(null)` creates a non-existent document reference | `FutureBuilder` will wait indefinitely (never completes) |
| E4 | `connexion_screen.dart:51` | If `currentUser` is null after sign-in (edge case) | `user.uid` used without null check on line 51 |
| E5 | `signalement_model.dart:35` | If `doc.data()` is not a `Map<String, dynamic>` (e.g., null for deleted docs) | `as Map<String, dynamic>` throws `_CastError` |

---

## 8. Actionable Recommendations

### Immediate (Critical — fix before production)

| # | Priority | Action | Details |
|---|---|---|---|
| R1 | 🔴 **CRITICAL** | **Deploy Firestore Security Rules** | Deploy the following rules immediately. Without them, the app has no data protection. |
| R2 | 🔴 **CRITICAL** | **Fix driver_profile.dart logout** | Add `await FirebaseAuth.instance.signOut();` before navigation on line 314. |
| R3 | 🔴 **CRITICAL** | **Fix driver_history.dart hardcoded ID** | Replace `'chauffeur_mock'` with `FirebaseAuth.instance.currentUser?.uid` on line 41. |
| R4 | 🔴 **CRITICAL** | **Fix driver_profile.dart hardcoded ID** | Same as R3 for the profile stats query on line 179. |
| R5 | 🟠 **HIGH** | **Move photos to Firebase Storage** | Replace Base64-in-Firestore with Firebase Storage + download URL. Add Cloud Function to generate thumbnails. |

### Short-term (High impact)

| # | Priority | Action | Details |
|---|---|---|---|
| R6 | 🟠 **HIGH** | **Eliminate dead code** | Remove `mock_data.dart`, `report_status_chip.dart`, `bottom_nav_bar.dart`, `app_strings.dart`, `mission_detail_screen.dart`, `mission_validation_screen.dart`, and the `go_router` dependency. |
| R7 | 🟠 **HIGH** | **Consolidate `_StatusBadge` into shared widget** | Create a single `StatusBadge` in `shared/widgets/` and replace all 3 private implementations. |
| R8 | 🟠 **HIGH** | **Consolidate bottom navigation** | Unify `main_shell.dart` and `driver_main_screen.dart` bottom navs into a single `shared/widgets/` component. |
| R9 | 🟠 **HIGH** | **Fix weak `id_court` generation** | Use a server-side timestamp-based ID (via Firebase `update` with a `FieldValue.serverTimestamp`) or a Firestore counter document for collision-free sequential IDs. |
| R10 | 🟠 **HIGH** | **Fix duplicate routing** | Remove manual role routing from `connexion_screen.dart`; let `AuthWrapper` handle all routing via `authStateChanges()`. |
| R11 | 🟠 **HIGH** | **Fix profil_citoyen_screen.dart logout redirect** | Change `InscriptionScreen` to `ConnexionScreen` on line 37. |

### Medium-term (Architecture improvements)

| # | Priority | Action | Details |
|---|---|---|---|
| R12 | 🟡 **MEDIUM** | **Adopt a state management library** | Introduce Riverpod or Bloc. Move Firestore stream logic from widgets to services/repositories. |
| R13 | 🟡 **MEDIUM** | **Add Firestore composite indexes** | Create composite indexes for `(statut, timestamp desc)` and `(citoyen_id, timestamp desc)` to avoid console warnings and optimize queries. |
| R14 | 🟡 **MEDIUM** | **Use Firestore `count()` for dashboard KPIs** | Replace client-side `.length` with `count()` aggregation queries for all dashboard statistics. |
| R15 | 🟡 **MEDIUM** | **Proxy AI APIs through Cloud Functions** | Move Groq and Gemini API calls to Firebase Cloud Functions to protect API keys and add rate limiting. |
| R16 | 🟡 **MEDIUM** | **Implement Firestore `Client` side caching** | Use `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)` to reduce reads. |
| R17 | 🟡 **MEDIUM** | **Add push notifications** | Integrate FCM (Firebase Cloud Messaging) to notify citizens when their report status changes. |

### Long-term (Strategic)

| # | Priority | Action | Details |
|---|---|---|---|
| R18 | 🟢 **LOW** | **Add unit and widget tests** | Implement tests for `Signalement.fromFirestore()`, `GeoUtils.distanceInMeters()`, and core business logic. |
| R19 | 🟢 **LOW** | **Implement placeholder screens** | Fill `NotificationsScreen` and `ConfidentialiteScreen` with actual content, or remove them. |
| R20 | 🟢 **LOW** | **CI/CD pipeline** | Add GitHub Actions for `flutter analyze`, `flutter test`, and Firebase deploy. |

### Firestore Security Rules (Recommended)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── Helper: auth checks ─────────────────────────────────
    function isAuthenticated() {
      return request.auth != null;
    }
    function isAdmin() {
      return isAuthenticated()
        && exists(/databases/$(database)/documents/citoyens/$(request.auth.uid))
        && get(/databases/$(database)/documents/citoyens/$(request.auth.uid)).data.role == 'admin';
    }
    function isChauffeur() {
      return isAuthenticated()
        && exists(/databases/$(database)/documents/citoyens/$(request.auth.uid))
        && get(/databases/$(database)/documents/citoyens/$(request.auth.uid)).data.role == 'chauffeur';
    }
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // ── Signalements ────────────────────────────────────────
    match /signalements/{docId} {
      // Citizens: create only with their own citoyen_id
      allow create: if isAuthenticated()
        && request.resource.data.citoyen_id == request.auth.uid;
      // Citizens: read own; Admin: read all; Driver: read assigned/pending
      allow read: if isAuthenticated()
        && (resource.data.citoyen_id == request.auth.uid
            || isAdmin()
            || isChauffeur());
      // Citizens: update own pending; Admin: update all; Driver: update assigned
      allow update: if isAuthenticated()
        && (isAdmin()
            || (isOwner(resource.data.citoyen_id)
                && resource.data.statut == 'en attente')
            || (isChauffeur()
                && resource.data.statut == 'en cours'));
      // No delete except owner or admin
      allow delete: if isAuthenticated()
        && (isOwner(resource.data.citoyen_id) || isAdmin());
    }

    // ── Citoyens (profile) ──────────────────────────────────
    match /citoyens/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId)
        && request.resource.data.role == 'citoyen';
      allow update: if isOwner(userId)
        || isAdmin();
      allow delete: if isAdmin();
    }
  }
}
```

---

## 9. Conclusion

**SmartClean City** demonstrates strong architectural foundations with its clean feature separation, excellent design system, and thoughtful real-time UX. The Firebase integration, role-based routing via `AuthWrapper`, and cross-tab communication patterns are well-architected.

However, the codebase exhibits typical early-stage Flutter project issues: absence of a state management strategy, critical hardcoded values (`chauffeur_mock`), Base64 photo storage anti-pattern, and — most critically — **no Firestore Security Rules**, leaving all data accessible to any authenticated user.

**The project is functionally complete** (the signalement lifecycle works end-to-end: Citizen → Admin → Driver) but **requires immediate security hardening** before production deployment. The 10 critical/high-priority findings in this report (R1–R11) should be addressed before any public launch.

**Overall Assessment**: 6.5/10 — Strong foundation with critical security gaps that must be closed.

---

*Report generated by Big Pickle System Auditor — SmartClean City PFE Audit — May 2026*
