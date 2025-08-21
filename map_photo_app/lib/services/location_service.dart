import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {

  static Future<bool> checkPermissions() async {
    final permission = await Permission.location.status;
    return permission.isGranted;
  }

  static Future<bool> requestPermissions() async {
    if (await checkPermissions()) {
      return true;
    }

    final permission = await Permission.location.request();
    return permission.isGranted;
  }

  static Future<bool> isPermissionPermanentlyDenied() async {
    final permission = await Permission.location.status;
    return permission.isPermanentlyDenied;
  }

  static Future<void> redirectToAppSettings() async {
    await openAppSettings();
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkPermissions()) {
        final granted = await requestPermissions();
        if (!granted) return null;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream();
  }

  static Future<double> getDistanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}