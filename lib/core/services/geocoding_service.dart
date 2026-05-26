// ignore_for_file: avoid_print
import 'dart:async';
import 'package:geocoding/geocoding.dart';


/// Reverse geocoding helper — converts LatLng to a human-readable
/// neighbourhood / locality name (e.g. "Cite El Badr", "Laghouat").
///
/// Results are cached in memory (keyed by rounded coords) so that
/// repeated calls for the same location never hit the platform geocoder twice.
class GeocodingService {
  GeocodingService._();

  // ── In-memory cache ──────────────────────────────────────────────────────────
  // Key: "${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}"
  static final Map<String, String> _cache = {};

  // ── In-flight deduplication — prevents parallel calls for the same key ───────
  static final Map<String, Future<String>> _inflight = {};

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Returns the most descriptive neighbourhood name available.
  /// Priority: subLocality → locality → subAdministrativeArea → administrativeArea.
  ///
  /// NEVER returns null. Falls back to [fallback] on any error.
  /// Always prints errors to the console so failures are visible during debug.
  static Future<String> getNeighborhood(
    double lat,
    double lng, {
    String fallback = 'Zone non reconnue',
  }) {
    final key = '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

    // 1. Cache hit — instant return
    if (_cache.containsKey(key)) {
      print('GEOCODING [CACHE HIT] $key → ${_cache[key]}');
      return Future.value(_cache[key]!);
    }

    // 2. In-flight deduplication — don't fire two requests for the same key
    if (_inflight.containsKey(key)) {
      print('GEOCODING [IN-FLIGHT] $key — reusing pending future');
      return _inflight[key]!;
    }

    // 3. New request
    print('GEOCODING [REQUEST] lat=$lat, lng=$lng, key=$key');
    final future = _fetch(lat, lng, key, fallback);
    _inflight[key] = future;

    // Clean up in-flight map once resolved (success or error)
    future.whenComplete(() => _inflight.remove(key));

    return future;
  }

  /// Clears the in-memory cache (useful for testing / locale change).
  static void clearCache() {
    _cache.clear();
    _inflight.clear();
    print('GEOCODING [CACHE CLEARED]');
  }

  // ── Private implementation ───────────────────────────────────────────────────

  static Future<String> _fetch(
    double lat,
    double lng,
    String key,
    String fallback,
  ) async {
    try {
      print('GEOCODING [FETCHING] $key …');

      final placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 5));

      print('GEOCODING [RAW] $key → ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        print(
          'GEOCODING [PLACEMARK] '
          'subLocality="${p.subLocality}" '
          'locality="${p.locality}" '
          'subAdminArea="${p.subAdministrativeArea}" '
          'adminArea="${p.administrativeArea}" '
          'country="${p.country}"',
        );

        final name = _pick([
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ], fallback);

        print('GEOCODING [RESULT] $key → "$name"');
        _cache[key] = name;
        return name;
      } else {
        print('GEOCODING [EMPTY] $key — no placemarks returned');
      }
    } on TimeoutException {
      print('GEOCODING ERROR: $key — request timed out after 5 seconds');
    } catch (e, stack) {
      print('GEOCODING ERROR: $key — $e');
      print('GEOCODING STACK: $stack');
    }

    print('GEOCODING [FALLBACK] $key → "$fallback"');
    _cache[key] = fallback;
    return fallback;
  }

  static String _pick(List<String?> candidates, String fallback) {
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
    return fallback;
  }
}
