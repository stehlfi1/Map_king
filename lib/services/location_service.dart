import 'package:geolocator/geolocator.dart';
import '../utils/app_logger.dart';

class LocationService {
  
  /// Simply gets current location - lets Geolocator handle all permissions natively
  static Future<Position?> getCurrentLocation() async {
    try {
      AppLogger.debug('LocationService', 'Checking location services...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.debug('LocationService', 'Location services are disabled');
        return null;
      }

      // Check permission status using Geolocator
      LocationPermission permission = await Geolocator.checkPermission();
      AppLogger.debug('LocationService', 'Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        // Request permission - this shows the native iOS dialog
        AppLogger.debug('LocationService', 'Requesting permission (native dialog will show)');
        permission = await Geolocator.requestPermission();
        AppLogger.debug('LocationService', 'Permission result: $permission');
        
        if (permission == LocationPermission.denied) {
          AppLogger.debug('LocationService', 'Permission denied by user');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.debug('LocationService', 'Permission permanently denied');
        return null;
      }

      // Permission granted - get position
      AppLogger.debug('LocationService', 'Getting position...');
      return await Geolocator.getCurrentPosition();
      
    } catch (e) {
      AppLogger.error('LocationService', 'Error getting location', e);
      return null;
    }
  }
  
  /// Check if permission is permanently denied (for custom dialog)
  static Future<bool> isPermissionPermanentlyDenied() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }
  
  /// Open app settings
  static Future<void> redirectToAppSettings() async {
    await Geolocator.openAppSettings();
  }

}