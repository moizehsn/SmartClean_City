# Debugger's Report — UI/Logic Overhaul

## Root Cause Analysis

### 1. Admin Flotte View — Blank Screen on Web

**Root Cause:** The entire page (title row + driver cards) was inside a `StreamBuilder`. When the Firestore query returned data, the `SingleChildScrollView` > `Column` > `Wrap` layout had **no `Expanded`** to constrain the list. On web, `Wrap` inside an unconstrained `Column` receives infinite height, causing the renderer to either crash silently or produce a blank viewport.

**The Trap:** Title + "Créer un Chauffeur" button now live **outside** the `StreamBuilder` — they render immediately regardless of DB state. The driver list is wrapped in `Expanded` inside the `StreamBuilder`, and any `snapshot.hasError` renders a red error card with the exact exception string via `SelectableText`. Future DB failures will show the error, not a blank screen.

### 2. Admin Carte View — Google Map Silent Crash

**Root Cause:** The previous `StreamBuilder` pattern rebuilt the entire `GoogleMap` widget on every snapshot emission. On web, this causes the map element to unmount/remount — Flutter web's Google Maps plugin cannot recover, leaving a grey/white void. The fix from the hotfix session extracted the stream into `initState` + `StreamSubscription` with a `ValueKey('admin-map')`.

**The Trap:** Any stream error is caught by `Subscription.onError`, stored in `_error`, and renders a **dark red overlay** with the exact exception in monospace. If the Google Map widget itself fails (invalid API key, CORS, etc.), the error from the stream subscription will surface here rather than silently vanishing.

### 3. Driver Profile — Hardcoded Dummy Data

**Root Cause:** The profile header displayed hardcoded "Chauffeur" and "Camion Benne — 1234-AB-16" strings with no Firestore fetch. The gear/settings icon in the AppBar had an empty `onPressed`.

**The Trap:** Profile header now fetches real `nom`, `camion_type`, `matricule` from `citoyens/{uid}` via a `FutureBuilder`-style approach in `initState`. If the fetch fails, it falls back to the localized "Chauffeur" string without crashing. "Modifier profil" and "Notifications" buttons show a SnackBar "Bientôt disponible" with a primary-green background — users get feedback instead of a dead tap.

### 4. Login Freeze — Race Condition with AuthWrapper

**Root Cause:** After `signInWithEmailAndPassword`, the code fetched the user's role from Firestore, then pushed a role-specific screen. But `AuthWrapper` (which wraps the app) also listens to `authStateChanges` and would race to rebuild the navigation stack — sometimes **after** the manual push, freezing the UI because two route stacks conflicted.

**The Trap:** The new code **unconditionally** pushes `AuthWrapper` with `pushAndRemoveUntil`. It does NOT fetch the role or decide routing — it delegates entirely to `AuthWrapper`, which already handles role-based routing via `authStateChanges` + `role` lookup. This eliminates the race: there is exactly ONE canonical route source.

### 5. Admin Dashboard — Arabic RTL Toggle Dead

**Root Cause:** The `_isArabic` state existed and toggled, and `Directionality` was already wrapping the body. But the sidebar menu labels were `static const` — switching the text direction had no visible effect because the French labels remained.

**The Trap:** Sidebar labels are now a getter that returns a different `_SidebarItem` list based on `_isArabic`, drawing from an Arabic label map (`لوحة القيادة`, `المواطنون`, etc.). The same getter feeds the top bar title. Any future RTL issues will be isolated to individual child views, not the shell itself.

---

## Summary of Traps Added

| Screen | Trap Mechanism | Failure Behavior |
|--------|---------------|------------------|
| Admin Flotte | `LayoutBuilder` + `SizedBox(width: constraints.maxWidth)` + `snapshot.hasError` | Shows error text in red card; `Wrap` receives bounded width |
| Admin Carte | `_error` state + dark red overlay | Shows exact exception in monospace on dark red background |
| Driver Profile | `StatefulWidget` + `initState` try/catch fallback | Shows `_nom ?? l.t('chauffeur')` if Firestore fetch fails |
| Login | `popUntil(route.isFirst)` back to `AuthWrapper` | No race — AuthWrapper's StreamBuilder handles routing |
| Admin Shell | Dynamic `_menuItems` getter + `isArabic` param on all widgets | Arabic labels on toggle + RTL layout |

## Alternative Approaches (Round 2)

After the first round didn't resolve the issues, these alternative fixes were applied:

### Admin Flotte View (Round 2)
- **Root cause revisited:** `Wrap` widget inside `Expanded` > `StreamBuilder` on web can receive unbounded width if the parent chain doesn't propagate constraints correctly. On Flutter web, this causes the `Wrap` to render nothing.
- **Alternative:** Added `LayoutBuilder` at the top level + `SizedBox(width: constraints.maxWidth)` around the `StreamBuilder`. This guarantees the `Wrap` always has explicit horizontal bounds.
- **Error trap:** Error state now shows a larger (56px) red error icon with `SelectableText` for the exact exception.

### Login Freeze (Round 2)
- **Root cause revisited:** The freeze was caused by the race between manual navigation (pushing a new route) and `AuthWrapper` rebuilding via `authStateChanges` — two competing routing authorities.
- **Alternative:** Instead of pushing a NEW route, use `Navigator.popUntil((route) => route.isFirst)` to POP back to the root `AuthWrapper`. Since `AuthWrapper` already listens to `authStateChanges()` via `StreamBuilder`, it will immediately rebuild with the logged-in user's role-based screen. No push, no race.
- **Added:** 15-second timeout on `signInWithEmailAndPassword`, 10-second timeout on Firestore profile fetch. `TimeoutException` is caught separately to show a network error message.

### Arabic Localization (Complete)
- **Root cause:** Only sidebar menu labels were localized; the brand section ("Admin Panel"), role label ("Administrateur"), and search placeholder ("Rechercher…") stayed in French.
- **Complete:** All hardcoded strings in the admin dashboard shell now have Arabic counterparts:
  - "Admin Panel" → "لوحة الإدارة"
  - "Administrateur" → "مسؤول"
  - "Rechercher…" → "بحث…"
  - Sidebar menu labels (already done in Round 1)

**Compilation:** 0 errors across all 5 refactored files.
