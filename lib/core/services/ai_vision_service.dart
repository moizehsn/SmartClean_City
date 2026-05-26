import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Three-state result for AI image validation.
enum AiValidationResult { valid, rejected, apiError }

/// Roboflow Litter Detection–powered image validation for SmartClean City.
///
/// Model: litter-detection-rftek  (version 2)
/// Endpoint: https://detect.roboflow.com/litter-detection-rftek/2
class AiVisionService {
  AiVisionService._();

  // ── Roboflow API constants ──────────────────────────────────────────────────
  static const String _apiKey = 'qcT3hSGjBzoHX49oJRg8';
  static const String _endpointUrl =
      'https://detect.roboflow.com/litter-detection-rftek/2';

  /// Confidence threshold — a prediction must exceed this value to be valid.
  static const double _confidenceThreshold = 0.60;

  // ── Core detection call ─────────────────────────────────────────────────────

  /// Sends [imageBytes] to the Roboflow inference endpoint and returns whether
  /// at least one litter detection with confidence > 60 % was found.
  ///
  /// Returns:
  /// - [AiValidationResult.valid]    – litter detected with high confidence.
  /// - [AiValidationResult.rejected] – no confident litter prediction found.
  /// - [AiValidationResult.apiError] – network / HTTP error.
  static Future<AiValidationResult> _detectLitter(
    Uint8List imageBytes,
  ) async {
    try {
      // Encode image to base64
      final String base64Image = base64Encode(imageBytes);

      // Build the full URL with the API key as a query parameter
      final Uri uri = Uri.parse('$_endpointUrl?api_key=$_apiKey');

      // POST request with base64 body
      final http.Response response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: base64Image,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print(
          '⚠️ ROBOFLOW API ERROR: HTTP ${response.statusCode} — ${response.body}',
        );
        return AiValidationResult.apiError;
      }

      // Parse the JSON response
      final Map<String, dynamic> jsonBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      final List<dynamic> predictions =
          (jsonBody['predictions'] as List<dynamic>?) ?? [];

      // Check if any prediction exceeds the confidence threshold
      final bool litterFound = predictions.any((dynamic p) {
        final double confidence =
            ((p as Map<String, dynamic>)['confidence'] as num?)?.toDouble() ??
            0.0;
        return confidence > _confidenceThreshold;
      });

      if (litterFound) {
        // ignore: avoid_print
        print('✅ Roboflow: litter detected with confidence > 60 %');
        return AiValidationResult.valid;
      } else {
        // ignore: avoid_print
        print(
          '🚫 Roboflow: no confident litter detection '
          '(${predictions.length} prediction(s) below threshold)',
        );
        return AiValidationResult.rejected;
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ ROBOFLOW EXCEPTION: $e');
      return AiValidationResult.apiError;
    }
  }

  // ── Public API (preserves existing call-sites) ──────────────────────────────

  /// Validates that the submitted image contains garbage / litter.
  ///
  /// Returns [AiValidationResult.valid] when the model detects litter with
  /// confidence > 60 %, [AiValidationResult.rejected] otherwise.
  /// Returns [AiValidationResult.apiError] on network or server failure.
  static Future<AiValidationResult> validateGarbageImage(
    Uint8List imageBytes,
  ) {
    return _detectLitter(imageBytes);
  }

  /// Validates that the submitted image shows a clean space (no litter).
  ///
  /// Returns [AiValidationResult.valid] when the model finds NO litter with
  /// confidence > 60 % (i.e. the space looks clean).
  /// Returns [AiValidationResult.rejected] when litter is still detected.
  /// Returns [AiValidationResult.apiError] on network or server failure.
  static Future<AiValidationResult> validateCleanImage(
    Uint8List imageBytes,
  ) async {
    final AiValidationResult result = await _detectLitter(imageBytes);

    // For a "clean" validation we invert the litter signal:
    //   - No litter found  → valid (space is clean)
    //   - Litter found     → rejected (space still dirty)
    //   - API error        → apiError (pass through)
    switch (result) {
      case AiValidationResult.valid:
        return AiValidationResult.rejected; // litter still present → not clean
      case AiValidationResult.rejected:
        return AiValidationResult.valid; // no litter → clean
      case AiValidationResult.apiError:
        return AiValidationResult.apiError;
    }
  }
}
