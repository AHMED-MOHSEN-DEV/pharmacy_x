import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class BranchLocation {
  final String name;
  final double lat;
  final double lng;

  const BranchLocation({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class LocationService {
  static const List<BranchLocation> branches = [
    BranchLocation(
      name: 'Main Pharmacy',
      lat: 25.704591585996454,
      lng: 32.65004217362406,
    ),
    BranchLocation(
      name: 'Branch 2',
      lat: 25.70496316820527,
      lng: 32.6496252858074,
    ),
    BranchLocation(
      name: 'Branch 3',
      lat: 29.995461988183667,
      lng: 31.32013320227057,
    ),
        BranchLocation(
      name: 'Branch 4',
      lat: 25.73584082467388,
      lng: 32.759627402167006,
    ),
  ];

  static const double geofenceRadius = 20.0;

  static Future<Position?> getCurrentPosition() async {
    try {
      final ok = await _ensurePermission();
      if (!ok) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } on PlatformException catch (e) {
      print('[LocationService] PlatformException: $e');
      return null;
    } on LocationServiceDisabledException {
      print('[LocationService] GPS disabled');
      return null;
    } catch (e) {
      print('[LocationService] Error: $e');
      return null;
    }
  }

  static Stream<Position> getPositionStream() async* {
    final ok = await _ensurePermission();
    if (!ok) {
      yield* const Stream.empty();
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      yield* Geolocator.getPositionStream(locationSettings: settings);
    } on PlatformException catch (e) {
      print('[LocationService] Stream PlatformException: $e');
      yield* const Stream.empty();
    } catch (e) {
      print('[LocationService] Stream error: $e');
      yield* const Stream.empty();
    }
  }

  static double distanceFromBranch(
    double userLat,
    double userLng,
    BranchLocation branch,
  ) {
    return Geolocator.distanceBetween(
      branch.lat,
      branch.lng,
      userLat,
      userLng,
    );
  }

  static BranchLocation? nearestBranch(double userLat, double userLng) {
    if (branches.isEmpty) return null;

    BranchLocation nearest = branches.first;
    double minDistance = distanceFromBranch(userLat, userLng, nearest);

    for (final branch in branches.skip(1)) {
      final distance = distanceFromBranch(userLat, userLng, branch);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = branch;
      }
    }

    return nearest;
  }

  static double nearestDistance(double userLat, double userLng) {
    final branch = nearestBranch(userLat, userLng);
    if (branch == null) return double.infinity;
    return distanceFromBranch(userLat, userLng, branch);
  }

  static bool isInsideAnyBranch(double userLat, double userLng) {
    return nearestDistance(userLat, userLng) <= geofenceRadius;
  }

  static String nearestBranchName(double userLat, double userLng) {
    final branch = nearestBranch(userLat, userLng);
    return branch?.name ?? 'Unknown';
  }

  static Future<void> openSettings() => Geolocator.openAppSettings();

  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  static Future<bool> _ensurePermission() async {
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } on PlatformException {
      return false;
    }
    if (!serviceEnabled) return false;

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }

      if (permission == LocationPermission.deniedForever) return false;
    } on PlatformException {
      return false;
    }

    return true;
  }
}