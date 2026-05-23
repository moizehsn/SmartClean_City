import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// GPS utilities for SmartClean City.
///
/// Provides Haversine distance calculation and Firestore-based
/// duplicate-location detection within a configurable radius.
class GeoUtils {
  GeoUtils._();

  /// Earth's mean radius in meters.
  static const double _earthRadius = 6371000;

  /// Minimum distance (in meters) between two reports to be considered distinct.
  static const double duplicateRadiusMeters = 30;

  // ── Haversine formula ──────────────────────────────────────────────────────
  /// Returns the great-circle distance in meters between two GPS points.
  static double distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  // ── Duplicate check ────────────────────────────────────────────────────────
  /// Queries Firestore for active reports ('en attente' or 'en cours')
  /// and returns `true` if ANY report exists within [duplicateRadiusMeters]
  /// of the given coordinates.
  ///
  /// Uses two separate queries (Firestore doesn't support OR on the same field)
  /// then merges and checks distance client-side.
  static Future<bool> isDuplicateLocation(double lat, double lon) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('signalements');

      // Fetch both statuses in parallel
      final results = await Future.wait([
        collection.where('statut', isEqualTo: 'en attente').get(),
        collection.where('statut', isEqualTo: 'en cours').get(),
      ]);

      // Merge all documents
      final allDocs = [...results[0].docs, ...results[1].docs];

      // Check proximity
      for (final doc in allDocs) {
        final data = doc.data();
        final existingLat = (data['latitude'] as num?)?.toDouble();
        final existingLon = (data['longitude'] as num?)?.toDouble();

        if (existingLat == null || existingLon == null) continue;

        final distance = distanceInMeters(lat, lon, existingLat, existingLon);
        if (distance <= duplicateRadiusMeters) {
          return true; // Duplicate found within 30m
        }
      }

      return false; // No duplicates
    } catch (e) {
      // Fail-open: if Firestore query fails, allow the submission
      print('GeoUtils.isDuplicateLocation error: $e');
      return false;
    }
  }
}
