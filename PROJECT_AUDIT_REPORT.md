# SmartClean City — Project Audit Report

**Date:** 2026-05-24  
**Auditor:** Antigravity (Lead AI Architect)  
**Scope:** Full codebase — `lib/` directory, all features, services, shared widgets, and `pubspec.yaml`  
**Constraint:** READ-ONLY. No code was modified during this audit.

---

## Summary of Steps 1 & 2 (Already Applied)

Before the audit, the following changes were made:

| File | Action |
|---|---|
| `lib/core/constants/api_keys.dart` | ✅ Removed `deepseekApiKey`. Only `geminiApiKey` remains. |
| `lib/core/services/ai_service.dart` | ✅ Fully replaced Deepseek HTTP implementation with `google_generative_ai` SDK (`gemini-1.5-flash`, `ChatSession`). |
| `lib/core/services/ai_vision_service.dart` | ✅ Fully replaced Deepseek HTTP Vision implementation with Gemini multimodal SDK (`DataPart`, `gemini-1.5-flash`). |

The `http` package import is now removed from both AI service files. The `http` package is still used elsewhere — keep it in `pubspec.yaml`.

---

## Audit Findings

Issues are categorized as:
- 🔴 **CRITICAL** — Can cause crashes, data loss, security breaches, or broken production features.
- 🟡 **WARNING** — Logic errors, unhandled edge cases, or bad practices that will cause subtle bugs.
- 🔵 **OPTIMIZATION** — Code that works but has performance, maintainability, or UX concerns.

---

## 🔴 CRITICAL Issues

---

### C-01 · API Key Hardcoded in Source Code (Security Vulnerability)

**File:** `lib/core/constants/api_keys.dart` — Line 3

```dart
static const String geminiApiKey = 'AIzaSyCdt_FdIzsVmkmiuGAdFViDnJjlaR9w60M';
```

**Risk:** The Gemini API key is committed directly in source code. If this repository is ever pushed to a public Git host (GitHub, GitLab, etc.), the key will be exposed to bots that scan repos for secrets within minutes. Even in a private repo, all contributors have access.

**Recommendation:** Move the key to:
- A `.env` file (excluded via `.gitignore`) loaded with the `flutter_dotenv` package, OR
- Android/iOS build secrets / CI environment variables.

---

### C-02 · Race Condition on Mission Accept — No Firestore Transaction

**File:** `lib/features/driver/mission_detail_screen.dart` — Lines 123–129

```dart
await FirebaseFirestore.instance
    .collection('signalements')
    .doc(docId)
    .update({
      'chauffeur_id': driverUid,
      'statut': 'en cours',
    });
```

**Risk:** When a report is `en attente`, ALL drivers see it simultaneously. Two drivers can press "Accept" at the same moment. Without a Firestore transaction, both `.update()` calls succeed, producing an inconsistent state — two drivers are assigned to the same job.

**Recommendation:** Wrap the update in `runTransaction` that first reads the document, checks `statut == 'en attente'`, then atomically writes. Abort and show a "mission already taken" dialog if the check fails.

---

### C-03 · `_confirmCancel` Missing `context.mounted` Guard Before Firestore Write

**Files:**
- `lib/features/reports/mes_signalements_screen.dart` — Lines 340–345
- `lib/features/home/accueil_screen.dart` — Lines 384–389

```dart
if (confirmed == true) {
  await FirebaseFirestore.instance
      .collection('signalements')
      .doc(signalement.id)
      .update({'statut': 'annulé'});
}
```

The dialog `await` can complete after the widget has been removed from the tree (real-time stream updates the list and the card is disposed). There is no `context.mounted` check before the Firestore write.

---

### C-04 · 4-Digit Random ID — Collision Risk in Production

**File:** `lib/features/reports/nouveau_signalement_screen.dart` — Lines 259–260

```dart
final idCourt = '#${1000 + Random().nextInt(9000)}';
```

Range is only 9,000 values (`#1000`–`#9999`). With real-world usage, duplicate `id_court` values are statistically guaranteed, causing user confusion as this is shown as a unique identifier.

**Recommendation:** Use Firestore's auto-generated document ID or a server-side atomic counter with a transaction.

---

### C-05 · Sign-Out Navigates to `InscriptionScreen` Instead of `ConnexionScreen`

**File:** `lib/features/profile/profil_citoyen_screen.dart` — Lines 33–40

```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const InscriptionScreen()),
  (_) => false,
);
```

After signing out, the app navigates to the **registration screen**, not the login screen. A user who logs out to switch accounts is sent to sign-up instead. Compare with `admin_dashboard_shell.dart:80` which correctly navigates to `ConnexionScreen`.

---

### C-06 · `Future.microtask(() => signOut())` Called Inside `build()` Method

**File:** `lib/features/auth/auth_wrapper.dart` — Lines 128–130

```dart
if (user.emailVerified) {
  Future.microtask(() => FirebaseAuth.instance.signOut());
```

Calling `Future.microtask(() => signOut())` inside a `FutureBuilder`'s `builder` (which runs during the widget `build` phase) triggers a state mutation from `build`. `signOut()` fires an auth state change which calls `setState` on `_AuthWrapperState` — directly from a build call. This can cause "setState() or markNeedsBuild() called during build" exceptions.

**Recommendation:** Replace with `WidgetsBinding.instance.addPostFrameCallback((_) { FirebaseAuth.instance.signOut(); })`.

---

## 🟡 WARNING Issues

---

### W-01 · AI Vision — No Image Size Guard Before Gemini's 4MB Limit

**File:** `lib/core/services/ai_vision_service.dart` (new Gemini version)

The Gemini API Vision has a **4MB binary limit per request**. While `imageQuality: 25` typically produces small images, there is no explicit size check before calling the API. On some high-density sensors, 25% quality at 1080px can approach 500KB raw, which becomes ~670KB base64 — still safe, but with no guard.

**Recommendation:** Add `if (imageBytes.length > 3_500_000) return AiValidationResult.apiError;` before the API call.

---

### W-02 · `geo_utils.dart` — Unbounded Firestore Query Fetches ALL Active Reports

**File:** `lib/core/services/geo_utils.dart` — Lines 54–57

```dart
final results = await Future.wait([
  collection.where('statut', isEqualTo: 'en attente').get(),
  collection.where('statut', isEqualTo: 'en cours').get(),
]);
```

This fetches **every single active report city-wide** to check for a 30m duplicate. As the database grows (thousands of reports), this is slow, expensive, and data-heavy. No `.limit()` is applied.

**Recommendation:** Use a Firestore bounding-box latitude/longitude filter or GeoHash-based query to reduce documents fetched before client-side Haversine comparison.

---

### W-03 · `driver_dashboard.dart` — 4 Concurrent Firestore Real-Time Listeners Per Screen

**File:** `lib/features/driver/driver_dashboard.dart` — Lines 277–289, 420–430

The screen holds 4 simultaneous persistent Firestore WebSocket connections:
- 1 in the main mission list `StreamBuilder`
- 3 inside `_FilterStatCard` widgets (one per status)

Each produces listener billing in Firestore and uses memory.

**Recommendation:** Use a single aggregated query or a Provider/Riverpod solution to share one stream and compute counts client-side.

---

### W-04 · `accueil_screen.dart` — Inner `StreamBuilder` Has No Error Handler

**File:** `lib/features/home/accueil_screen.dart` — Lines 66–115

The inner `StreamBuilder<DocumentSnapshot>` (for the citizen profile greeting) handles `data` but never handles `hasError`. If Firestore rules block the read, the greeting silently fails and shows "Citoyen" with no indication of an error.

---

### W-05 · `mission_detail_screen.dart` — `data` Map is Stale by Design

**File:** `lib/features/driver/mission_detail_screen.dart` — Lines 14–23

`MissionDetailScreen` is a `StatelessWidget` that receives `Map<String, dynamic> data` at construction time. The `_statut` getter reads from this frozen snapshot. If the document is updated in Firestore while the screen is open, the UI will not reflect the change.

---

### W-06 · Helper Functions Defined Inside `build()` Method

**File:** `lib/features/reports/nouveau_signalement_screen.dart` — Lines 395–411

```dart
String _phaseLabel() { ... }
IconData _phaseIcon() { ... }
```

Local functions defined inside `build()` are recreated on every rebuild. They should be extracted as class methods for clarity and efficiency.

---

### W-07 · Firestore Composite Index Requirement Not Documented

**File:** `lib/features/reports/mes_signalements_screen.dart` — Lines 33–45

When a status filter is active, the query uses `where('citoyen_id')` + `where('statut')` + `orderBy('timestamp')`. Firestore requires a **composite index** for this. Without it, the query silently fails (stream emits an error caught by `_FirestoreErrorCard`). This index is not documented anywhere in the codebase.

---

### W-08 · `_isLoading` Not Reset on Successful Login Path

**File:** `lib/features/auth/connexion_screen.dart` — Lines 42–54

```dart
setState(() => _isLoading = true);
try {
  // ...
  widget.onLoginSuccess?.call();
  return; // ← _isLoading is still true here
```

On success, the method returns early without ever resetting `_isLoading = false`. The `AuthWrapper` typically rebuilds so fast this is invisible, but on slower devices the login button stays frozen.

---

### W-09 · Double Firebase Auth Stream Subscription

**File:** `lib/features/auth/auth_wrapper.dart` — Lines 37–52

Both `authStateChanges()` and `idTokenChanges()` are subscribed simultaneously. On the same login event, both streams fire in rapid succession, potentially causing two `setState` calls and two Firestore profile fetches.

---

### W-10 · Admin Sidebar Firestore Stream Re-subscribed on Every Search Keystroke

**File:** `lib/features/admin/admin_dashboard_shell.dart` — Lines 304–309

The `StreamBuilder` inside `_AdminSidebar` (a `StatelessWidget`) creates a new Firestore snapshot listener every time the parent calls `setState`. Since `setState` is triggered on every keystroke in the search field (via `_searchCtrl.addListener`), this stream is re-subscribed repeatedly under heavy typing.

**Recommendation:** Move the admin profile stream to the parent `State` class as a stable, single subscription.

---

## 🔵 OPTIMIZATION Issues

---

### O-01 · Pervasive Use of Deprecated `.withOpacity()` (50+ Locations)

**Files:** Found in virtually every file in the project.

`Color.withOpacity()` is deprecated in Flutter 3.3+. The replacement is `Color.withValues(alpha: x)`. Some files (e.g., `profil_citoyen_screen.dart`) already use the new API correctly, making the codebase inconsistent.

**Recommendation:** Project-wide migration from `withOpacity` → `withValues(alpha: ...)`.

---

### O-02 · `AiService` Static Model Has No Error Recovery Path

**File:** `lib/core/services/ai_service.dart`

If the Gemini API returns a persistent error (e.g., quota exceeded, invalid key), the cached `_model` and `_chat` remain in an errored state. Subsequent calls will continue failing with no auto-recovery.

**Recommendation:** On catch, call `resetChat()` and log the error type before returning the error string.

---

### O-03 · `driver_dashboard.dart` — All Documents Fetched Then Sliced Client-Side

**File:** `lib/features/driver/driver_dashboard.dart` — Lines 334, 343

All matching Firestore documents are fetched, then a client-side sort is performed, then `take(10)` is called. The server-side query has no `.limit()` or `.orderBy()`.

**Recommendation:** Add `.orderBy('timestamp', descending: true).limit(10)` to the query builder.

---

### O-04 · `accueil_screen.dart` — Extra Firestore Listener for Just 2 Profile Fields

**File:** `lib/features/home/accueil_screen.dart` — Lines 28–31

A full document real-time listener is maintained just to display `pseudo`/`nom`. Consider caching this in `SharedPreferences` or passing it from `AuthWrapper`.

---

### O-05 · `_encodeToBase64` Method is Dead Code

**File:** `lib/features/reports/nouveau_signalement_screen.dart` — Lines 85–88

```dart
Future<String> _encodeToBase64(File file) async {
  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}
```

This method is defined but **never called**. The actual base64 encoding at line 259 is done inline. This is dead code and should be removed.

---

### O-06 · Raw Firestore Error Messages Shown in Production UI

**Files:**
- `mes_signalements_screen.dart:517–568`
- `accueil_screen.dart:558–605`
- `driver_dashboard.dart:684–736`

The `_FirestoreErrorCard` / `_ErrorCard` widgets render `error.toString()` directly on screen, exposing internal Firestore error messages and resource paths to end users.

**Recommendation:** Wrap with `kDebugMode`:
```dart
if (kDebugMode) SelectableText(error?.toString() ?? '')
else Text('Erreur de chargement. Vérifiez votre connexion.')
```

---

### O-07 · Typing Indicator Animation Controllers Recreated Per Message

**File:** `lib/features/chatbot/eco_bot_screen.dart` — Lines 344–347

`_TypingIndicator` is conditionally added/removed from the list on each message, creating 3 new `AnimationController`s each time loading starts. The `mounted` guard is correctly present, but the pattern is slightly wasteful for rapid exchanges.

---

### O-08 · "Acceptés" Stat Counts Pending Reports — Logic Error

**File:** `lib/features/profile/profil_citoyen_screen.dart` — Lines 111

```dart
final acceptes = reports.where((r) => r.statut == 'en attente').length;
```

`'en attente'` means **pending**, not accepted. This stat is shown to citizens under the label `signalements_acceptes` (accepted reports), but it's actually counting reports waiting for a driver. The count for truly in-progress reports (`'en cours'`) is not shown at all.

---

### O-09 · Admin Language Preference Not Persisted

**File:** `lib/features/admin/admin_dashboard_shell.dart` — Lines 25, 115

The admin's language toggle (`_isArabic`) is stored in ephemeral `State`. It resets to French on every rebuild. The citizen side uses `SharedPreferences` for persistence — the admin panel should too.

---

### O-10 · `AuthService` Instantiated Fresh on Every Login Attempt

**File:** `lib/features/auth/connexion_screen.dart` — Line 43

`AuthService()` is constructed as a new object on every login tap. While Firebase returns singletons internally, the extra allocation is unnecessary. `AuthService` should use static methods or be a singleton.

---

### O-11 · No Image Size Guard Before Firestore 1MB Document Limit

**File:** `lib/features/reports/nouveau_signalement_screen.dart` — Line 230

Firestore documents have a **1 MB hard limit**. Base64 encoding adds ~33% overhead. No guard exists to reject images exceeding ~750 KB before the Firestore write. A write failure here shows a generic, unhelpful error.

**Recommendation:** Add `if (imageBytes.length > 750000) { _showSnackBar('Image trop grande...'); return; }` after line 230.

---

## Summary Table

| ID | Severity | File | Line(s) | Issue |
|---|---|---|---|---|
| C-01 | 🔴 Critical | `api_keys.dart` | 3 | API key hardcoded in source |
| C-02 | 🔴 Critical | `mission_detail_screen.dart` | 123–129 | Race condition on mission accept |
| C-03 | 🔴 Critical | `mes_signalements_screen.dart` | 340–345 | Missing `mounted` guard on cancel write |
| C-04 | 🔴 Critical | `nouveau_signalement_screen.dart` | 260 | 4-digit random ID collision risk |
| C-05 | 🔴 Critical | `profil_citoyen_screen.dart` | 37 | Sign-out navigates to registration screen |
| C-06 | 🔴 Critical | `auth_wrapper.dart` | 129 | `Future.microtask` + `signOut` inside `build()` |
| W-01 | 🟡 Warning | `ai_vision_service.dart` | — | No image size guard before 4MB Gemini limit |
| W-02 | 🟡 Warning | `geo_utils.dart` | 54–57 | Unbounded Firestore fetch for duplicate check |
| W-03 | 🟡 Warning | `driver_dashboard.dart` | 277–289 | 4 concurrent Firestore listeners |
| W-04 | 🟡 Warning | `accueil_screen.dart` | 66–115 | Inner StreamBuilder lacks error handler |
| W-05 | 🟡 Warning | `mission_detail_screen.dart` | 14–23 | Stale frozen `data` map on StatelessWidget |
| W-06 | 🟡 Warning | `nouveau_signalement_screen.dart` | 395–411 | Helpers defined inside `build()` |
| W-07 | 🟡 Warning | `mes_signalements_screen.dart` | 33–45 | Composite Firestore index not documented |
| W-08 | 🟡 Warning | `connexion_screen.dart` | 54 | `_isLoading` not reset on success |
| W-09 | 🟡 Warning | `auth_wrapper.dart` | 37–52 | Double Firebase Auth stream subscription |
| W-10 | 🟡 Warning | `admin_dashboard_shell.dart` | 304–309 | Sidebar stream re-subscribed per keystroke |
| O-01 | 🔵 Optim. | Project-wide | 50+ files | Deprecated `.withOpacity()` |
| O-02 | 🔵 Optim. | `ai_service.dart` | — | Static model with no error recovery |
| O-03 | 🔵 Optim. | `driver_dashboard.dart` | 343 | All docs fetched, client-side limited to 10 |
| O-04 | 🔵 Optim. | `accueil_screen.dart` | 28–31 | Extra Firestore listener for 2 profile fields |
| O-05 | 🔵 Optim. | `nouveau_signalement_screen.dart` | 85–88 | `_encodeToBase64` is dead code |
| O-06 | 🔵 Optim. | Multiple | — | Raw Firestore errors in production UI |
| O-07 | 🔵 Optim. | `eco_bot_screen.dart` | 344–347 | Typing indicator controllers recreated per message |
| O-08 | 🔵 Optim. | `profil_citoyen_screen.dart` | 111 | "Acceptés" counts pending reports (logic error) |
| O-09 | 🔵 Optim. | `admin_dashboard_shell.dart` | 25, 115 | Admin language preference not persisted |
| O-10 | 🔵 Optim. | `connexion_screen.dart` | 43 | `AuthService` re-instantiated per login tap |
| O-11 | 🔵 Optim. | `nouveau_signalement_screen.dart` | 230 | No image size guard before Firestore 1MB limit |

---

*This report was generated by a static code analysis pass. No source code was modified during Step 3.*
