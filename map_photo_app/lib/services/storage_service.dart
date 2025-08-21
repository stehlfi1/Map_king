import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_marker.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class StorageService {
  static const String _markersKey = AppConstants.markersStorageKey;

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    AppLogger.debug('StorageService', 'Local path: ${directory.path}');
    return directory.path;
  }

  static Future<Directory> get _photoDirectory async {
    final path = await _localPath;
    final photoDir = Directory('$path/${AppConstants.photoDirectoryName}');
    if (!await photoDir.exists()) {
      AppLogger.debug('StorageService', 'Creating photo directory: ${photoDir.path}');
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  static Future<String> savePhoto(String sourcePath) async {
    try {
      AppLogger.debug('StorageService', 'Saving photo from: $sourcePath');
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      final photoDir = await _photoDirectory;
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destinationPath = '${photoDir.path}/$fileName';
      
      await sourceFile.copy(destinationPath);
      
      // Verify the file was actually saved
      final savedFile = File(destinationPath);
      if (!await savedFile.exists()) {
        throw Exception('Photo file was not created at destination');
      }
      
      final fileSize = await savedFile.length();
      AppLogger.debug('StorageService', 'Photo saved: $fileName (${fileSize} bytes)');
      return destinationPath;
    } catch (e) {
      AppLogger.error('StorageService', 'Failed to save photo', e);
      throw Exception('Failed to save photo: $e');
    }
  }

  static Future<void> deletePhoto(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error but don't throw - deletion should be silent on failure
      print('Warning: Failed to delete photo at $imagePath: $e');
    }
  }

  static Future<void> saveMarkers(List<PhotoMarker> markers) async {
    try {
      AppLogger.debug('StorageService', 'Saving ${markers.length} markers');
      final prefs = await SharedPreferences.getInstance();
      final markersJson = markers.map((marker) => marker.toJson()).toList();
      final markersString = jsonEncode(markersJson);
      await prefs.setString(_markersKey, markersString);
    } catch (e) {
      AppLogger.error('StorageService', 'Failed to save markers', e);
      throw Exception('Failed to save markers: $e');
    }
  }

  static Future<List<PhotoMarker>> loadMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersString = prefs.getString(_markersKey);
      
      if (markersString == null) {
        AppLogger.debug('StorageService', 'No markers found');
        return [];
      }

      final markersJson = jsonDecode(markersString) as List;
      final allMarkers = markersJson.map((json) => PhotoMarker.fromJson(json)).toList();
      
      // Check which markers have existing files
      final validMarkers = <PhotoMarker>[];
      int missingFiles = 0;
      for (final marker in allMarkers) {
        if (File(marker.imagePath).existsSync()) {
          validMarkers.add(marker);
        } else {
          missingFiles++;
        }
      }
      
      if (missingFiles > 0) {
        AppLogger.warning('StorageService', 'Found $missingFiles markers with missing image files');
      }
      AppLogger.debug('StorageService', 'Loaded ${validMarkers.length} valid markers');
      return validMarkers;
    } catch (e) {
      AppLogger.error('StorageService', 'Failed to load markers', e);
      return [];
    }
  }

  static Future<void> deleteMarker(PhotoMarker marker) async {
    try {
      final markers = await loadMarkers();
      markers.removeWhere((m) => m.id == marker.id);
      await saveMarkers(markers);
      await deletePhoto(marker.imagePath);
    } catch (e) {
      throw Exception('Failed to delete marker: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final markers = await loadMarkers();
      for (final marker in markers) {
        await deletePhoto(marker.imagePath);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_markersKey);
    } catch (e) {
      throw Exception('Failed to clear data: $e');
    }
  }

  /// Performs a comprehensive storage health check
  static Future<Map<String, dynamic>> getStorageStatus() async {
    try {
      AppLogger.debug('StorageService', 'Performing storage health check...');
      
      final localPath = await _localPath;
      final photoDir = await _photoDirectory;
      final prefs = await SharedPreferences.getInstance();
      final markersString = prefs.getString(_markersKey);
      
      // Count actual photo files in directory
      final photoFiles = photoDir.listSync().whereType<File>().length;
      
      // Count markers in SharedPreferences
      int markersInPrefs = 0;
      int validMarkers = 0;
      List<String> missingPhotos = [];
      
      if (markersString != null) {
        final markersJson = jsonDecode(markersString) as List;
        markersInPrefs = markersJson.length;
        
        for (final json in markersJson) {
          final marker = PhotoMarker.fromJson(json);
          if (File(marker.imagePath).existsSync()) {
            validMarkers++;
          } else {
            missingPhotos.add(marker.imagePath);
          }
        }
      }
      
      final status = {
        'localPath': localPath,
        'photoDirectoryPath': photoDir.path,
        'photoDirectoryExists': await photoDir.exists(),
        'photoFilesCount': photoFiles,
        'markersInPreferences': markersInPrefs,
        'validMarkersCount': validMarkers,
        'missingPhotosCount': missingPhotos.length,
        'missingPhotoPaths': missingPhotos,
        'sharedPreferencesHasData': markersString != null,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      AppLogger.debug('StorageService', 'Storage health check complete');
      return status;
    } catch (e) {
      AppLogger.error('StorageService', 'Error getting storage status', e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Validates storage integrity and repairs if possible
  static Future<bool> validateAndRepairStorage() async {
    try {
      AppLogger.debug('StorageService', 'Validating and repairing storage...');
      final status = await getStorageStatus();
      
      if (status.containsKey('error')) {
        AppLogger.error('StorageService', 'Storage validation failed: ${status['error']}');
        return false;
      }
      
      final missingCount = status['missingPhotosCount'] as int;
      if (missingCount > 0) {
        AppLogger.info('StorageService', 'Found $missingCount markers with missing photos - attempting recovery...');
        
        // Try to recover markers by updating their paths
        final recovered = await _attemptMarkerRecovery();
        AppLogger.info('StorageService', 'Recovery attempt completed - recovered $recovered markers');
        
        // Clean up any remaining markers with missing photos
        final markers = await loadMarkers(); // This will filter out unrecoverable markers
        await saveMarkers(markers);
        
        AppLogger.info('StorageService', 'Cleaned up unrecoverable markers');
      }
      
      return true;
    } catch (e) {
      AppLogger.error('StorageService', 'Error validating storage', e);
      return false;
    }
  }
  
  /// Attempts to recover markers with missing photos by searching for files with similar names
  static Future<int> _attemptMarkerRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersString = prefs.getString(_markersKey);
      if (markersString == null) return 0;
      
      final markersJson = jsonDecode(markersString) as List;
      final allMarkers = markersJson.map((json) => PhotoMarker.fromJson(json)).toList();
      final photoDir = await _photoDirectory;
      
      // Get all available photo files
      final availableFiles = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg'))
          .toList();
      
      int recovered = 0;
      bool hasChanges = false;
      
      for (int i = 0; i < allMarkers.length; i++) {
        final marker = allMarkers[i];
        if (!File(marker.imagePath).existsSync()) {
          AppLogger.debug('StorageService', 'Attempting to recover marker ${marker.id} with missing photo');
          
          // Try to find a photo file that might belong to this marker
          // Look for files with similar timestamps or the marker's ID
          final markerTimestamp = marker.timestamp.millisecondsSinceEpoch;
          
          for (final file in availableFiles) {
            final fileName = file.path.split('/').last;
            // Check if filename contains the marker's timestamp (within a reasonable range)
            if (fileName.contains('photo_')) {
              final timestampMatch = RegExp(r'photo_(\d+)\.jpg').firstMatch(fileName);
              if (timestampMatch != null) {
                final fileTimestamp = int.tryParse(timestampMatch.group(1) ?? '');
                if (fileTimestamp != null) {
                  // If timestamps are within 5 seconds of each other, consider it a match
                  final timeDiff = (markerTimestamp - fileTimestamp).abs();
                  if (timeDiff < 5000) {
                    AppLogger.debug('StorageService', 'Found potential match for marker ${marker.id}');
                    
                    // Update the marker with the correct path
                    final updatedMarker = marker.copyWith(imagePath: file.path);
                    allMarkers[i] = updatedMarker;
                    recovered++;
                    hasChanges = true;
                    break;
                  }
                }
              }
            }
          }
        }
      }
      
      // Save updated markers if any were recovered
      if (hasChanges) {
        final markersJson = allMarkers.map((marker) => marker.toJson()).toList();
        final markersString = jsonEncode(markersJson);
        await prefs.setString(_markersKey, markersString);
        AppLogger.debug('StorageService', 'Saved recovered markers to SharedPreferences');
      }
      
      return recovered;
    } catch (e) {
      AppLogger.error('StorageService', 'Error during marker recovery', e);
      return 0;
    }
  }
}