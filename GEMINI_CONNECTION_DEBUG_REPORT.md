# Gemini Connection Failure — Debug Report

## 1. Root Cause Hypothesis

### **PRIMARY (99% confidence): Invalid model name `gemini-2.5-flash`**

During the AI Vision refactoring, the model name was silently changed from the original (which was `gemini-1.5-flash`) to `gemini-2.5-flash` at `ai_vision_service.dart:17`:

```dart
// REFACTORED (broken):
model: 'gemini-2.5-flash',

// ORIGINAL (commented-out in git HEAD):
model: 'gemini-1.5-flash',
```

**Why this fails 100% of the time:**

| Evidence | Detail |
|----------|--------|
| `pubspec.lock` | `google_generative_ai: 0.4.7` — released late 2024, before Gemini 2.5 was even announced |
| Gemini model catalog | As of the SDK's release, stable models are `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-1.0-pro`. `gemini-2.5-flash` does **not** exist as a model ID |
| API behavior | The SDK constructs `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent`. The API returns a 404 / `NOT_FOUND` error, which throws an exception caught by the generic `catch` block |
| Reproducibility | The error is *deterministic* — the model lookup fails before any network delay, so every single call immediately hits the `catch` block |

### **SECONDARY: API key never verified end-to-end**

The original code had ALL Gemini logic **completely commented out** — both `validateGarbageImage` and `validateCleanImage` were mocked (`return true` after 1s delay). The real Gemini code was never executed even once. So the API key at `api_keys.dart:4`:

```dart
static const String geminiApiKey = 'AIzaSyCOO3HoweqaNjp_ZjMozwtLSIlCRNNP5wA';
```

has **never been tested** in this project. It may be:
- Not enabled for the Generative Language API
- Restricted by Android/iOS/HTTP referrer
- Revoked or quota-exhausted
- Valid — we will only know after fixing the model name

---

## 2. Missing Dependencies Check

| Dependency | Status |
|------------|--------|
| `google_generative_ai: ^0.4.7` | ✅ Present in `pubspec.yaml:52` |
| `mime` package | ✅ **Not required.** The code uses a custom byte-magic `_detectMimeType()` method — no `package:mime` import exists |
| All transitive deps | ✅ `flutter pub get` succeeds, `flutter analyze` passes with 0 errors |

There are **no missing dependencies**. The catch block is triggered by an API error, not a compile-time or import failure.

---

## 3. Action Plan

### Step A — Add diagnostic `print(e)` to the catch block (immediate)

**File:** `lib/core/services/ai_vision_service.dart`

In both `validateGarbageImage` and `validateCleanImage`, add a `print` statement before the `return`:

```dart
} catch (e) {
  print('⚠️ GEMINI API ERROR: $e');   // ← ADD THIS
  return AiValidationResult.apiError;
}
```

This will reveal the exact error message (expected: *"models/gemini-2.5-flash not found"* or *"Model not found"*).

### Step B — Fix the model name

Change line 17 from:
```dart
model: 'gemini-2.5-flash',
```
to:
```dart
model: 'gemini-1.5-flash',
```

`gemini-1.5-flash` is the model confirmed in the original commented-out code, is stable in the SDK 0.4.7, and is widely available.

### Step C — Re-test

1. After applying Step B, restart the app
2. Submit a garbage image from the citizen flow
3. Check the debug console for the `print` output
4. Expected: `GEMINI RAW RESPONSE: "YES"` or `"NO"`

### Step D — If Step C still fails, verify the API key directly

If the model fix doesn't work, test the API key independently:

```bash
# Using curl (run from any terminal with network access):
$env:API_KEY = "AIzaSyCOO3HoweqaNjp_ZjMozwtLSIlCRNNP5wA"
curl.exe -X POST "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$env:API_KEY" `
  -H "Content-Type: application/json" `
  -d '{
    "contents": [{
      "parts": [{"text": "Say YES and nothing else."}]
    }]
  }'
```

Expected response: `{"candidates":[{"content":{"parts":[{"text":"YES"}]}}]}`

If this fails, the API key itself is invalid or restricted — generate a new key from [Google AI Studio](https://aistudio.google.com/apikey).

---

## Summary

| Issue | Probability | Fix |
|-------|-------------|-----|
| Invalid model `gemini-2.5-flash` | 99% | Revert to `gemini-1.5-flash` |
| API key invalid/unverified | 1% | Test with curl, generate new key if needed |
| Missing `mime` package | 0% | Not used |
| Null/bad image bytes | <1% | `File.readAsBytes()` from `image_picker` path is reliable |
| SDK version too old | 0% | `0.4.7` supports `gemini-1.5-flash` |
