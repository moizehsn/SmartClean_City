import 'dart:typed_data';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import '../constants/api_keys.dart';

/// Gemini-powered image validation for SmartClean City.
///
/// Two responsibilities:
/// 1. Citizen side — confirm the photo shows garbage before submission.
/// 2. Driver side  — confirm the photo shows a clean area before closing.
///
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │  🔧 TESTING MODE — AI MOCKED                                          │
/// │  Both methods return `true` after a 1-second delay.                    │
/// │  Uncomment the real Gemini logic and remove the mock when ready.       │
/// └─────────────────────────────────────────────────────────────────────────┘
class AiVisionService {
  AiVisionService._();

  // static final _model = GenerativeModel(
  //   model: 'gemini-1.5-flash',
  //   apiKey: ApiKeys.geminiApiKey,
  // );

  // ── Citizen: Does the photo show garbage? ──────────────────────────────────
  /// MOCKED — always returns true after 1s delay for UI effect.
  static Future<bool> validateGarbageImage(Uint8List imageBytes) async {
    // ═══════════════════════════════════════════════════════════════════════
    // MOCK: Simulate AI processing delay, then approve.
    await Future.delayed(const Duration(seconds: 1));
    print('[AI MOCK] validateGarbageImage → true (testing mode)');
    return true;
    // ═══════════════════════════════════════════════════════════════════════

    // ── REAL GEMINI LOGIC (uncomment when ready) ──────────────────────────
    // try {
    //   final content = [
    //     Content.multi([
    //       TextPart(
    //         'You are a municipal waste inspector for a city cleaning service. '
    //         'Analyze this image. Does it show actionable urban waste, such as '
    //         'piles of garbage on the street, overflowing public dumpsters, '
    //         'outdoor garbage bags, or illegal outdoor dumping? '
    //         'You MUST EXCLUDE indoor office trash cans, private indoor bins, '
    //         'and very minor litter. '
    //         'Answer strictly with "YES" or "NO" and nothing else.',
    //       ),
    //       DataPart('image/jpeg', imageBytes),
    //     ]),
    //   ];
    //
    //   final response = await _model.generateContent(content);
    //   final rawText = response.text ?? '';
    //   print('GEMINI RAW RESPONSE (garbage check): "$rawText"');
    //
    //   final answer = rawText.trim().toUpperCase();
    //   return answer.contains('YES');
    // } catch (e) {
    //   print('GEMINI ERROR (garbage check): $e');
    //   return false;
    // }
  }

  // ── Driver: Does the photo show a clean place? ─────────────────────────────
  /// MOCKED — always returns true after 1s delay for UI effect.
  static Future<bool> validateCleanImage(Uint8List imageBytes) async {
    // ═══════════════════════════════════════════════════════════════════════
    // MOCK: Simulate AI processing delay, then approve.
    await Future.delayed(const Duration(seconds: 1));
    print('[AI MOCK] validateCleanImage → true (testing mode)');
    return true;
    // ═══════════════════════════════════════════════════════════════════════

    // ── REAL GEMINI LOGIC (uncomment when ready) ──────────────────────────
    // try {
    //   final content = [
    //     Content.multi([
    //       TextPart(
    //         'You are a strict quality controller. '
    //         'Does this image show a clean environment without any visible '
    //         'piles of garbage or waste? '
    //         'Answer ONLY with "YES" or "NO".',
    //       ),
    //       DataPart('image/jpeg', imageBytes),
    //     ]),
    //   ];
    //
    //   final response = await _model.generateContent(content);
    //   final rawText = response.text ?? '';
    //   print('GEMINI RAW RESPONSE (clean check): "$rawText"');
    //
    //   final answer = rawText.trim().toUpperCase();
    //   return answer.contains('YES');
    // } catch (e) {
    //   print('GEMINI ERROR (clean check): $e');
    //   return false;
    // }
  }
}
