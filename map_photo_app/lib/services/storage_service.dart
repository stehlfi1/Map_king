import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_marker.dart';

class StorageService {
  static const String _markersKey = 'photo_markers';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<Directory> get _photoDirectory async {
    final path = await _localPath;
    final photoDir = Directory('$path/photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  static Future<String> savePhoto(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      final photoDir = await _photoDirectory;
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destinationPath = '${photoDir.path}/$fileName';
      
      await sourceFile.copy(destinationPath);
      return destinationPath;
    } catch (e) {
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
    }
  }

  static Future<void> saveMarkers(List<PhotoMarker> markers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersJson = markers.map((marker) => marker.toJson()).toList();
      final markersString = jsonEncode(markersJson);
      await prefs.setString(_markersKey, markersString);
    } catch (e) {
      throw Exception('Failed to save markers: $e');
    }
  }

  static Future<List<PhotoMarker>> loadMarkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final markersString = prefs.getString(_markersKey);
      
      if (markersString == null) {
        return [];
      }

      final markersJson = jsonDecode(markersString) as List;
      return markersJson
          .map((json) => PhotoMarker.fromJson(json))
          .where((marker) => File(marker.imagePath).existsSync())
          .toList();
    } catch (e) {
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
}