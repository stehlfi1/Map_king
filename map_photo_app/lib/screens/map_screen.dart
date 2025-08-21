import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_marker.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/photo_detail_dialog.dart';
import '../models/search_result.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  Position? _currentPosition;
  List<PhotoMarker> _photoMarkers = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  
  // Prague coordinates as default
  static const LatLng _pragueCenter = LatLng(49.7437, 14.3208);
  LatLng _currentMapCenter = _pragueCenter;
  
  // Settings
  bool _showCoordinatesInInfo = true;
  double _defaultMapZoom = 12.0;
  bool _enableHaptics = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadSettings();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadPhotoMarkers();
    _loadCurrentLocation(); 
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCurrentLocation() async {
    try {
      if (await LocationService.isPermissionPermanentlyDenied()) {
        _showLocationPermissionDialog();
        return;
      }

      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _currentMapCenter = LatLng(position.latitude, position.longitude);
        });
        
        if (_mapController != null) {
          _mapController!.move(LatLng(position.latitude, position.longitude), 12.0);
        }
      } else {
        _showLocationPermissionDialog();
      }
    } catch (e) {
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Needed'),
        content: const Text(
          'This app needs location permission to show your current position on the map and help place photos at your location. '
          'Please enable location permission in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              LocationService.redirectToAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPhotoMarkers() async {
    final markers = await StorageService.loadMarkers();
    setState(() {
      _photoMarkers = markers;
    });
  }

  List<Marker> _buildMarkers() {
    return _photoMarkers.map((photoMarker) {
      return Marker(
        width: 70,
        height: 70,
        point: LatLng(photoMarker.latitude, photoMarker.longitude),
        child: GestureDetector(
          onTap: () => _showPhotoDetail(photoMarker),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31),
              child: Image.file(
                File(photoMarker.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue,
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showPhotoDetail(PhotoMarker photoMarker) {
    showDialog(
      context: context,
      builder: (context) => PhotoDetailDialog(
        photoMarker: photoMarker,
        onDelete: () => _deletePhotoMarker(photoMarker),
        onUpdate: (updatedMarker) => _updatePhotoMarker(photoMarker, updatedMarker),
      ),
    );
  }

  Future<void> _deletePhotoMarker(PhotoMarker photoMarker) async {
    try {
      await StorageService.deleteMarker(photoMarker);
      await _loadPhotoMarkers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo marker deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting marker: $e')),
        );
      }
    }
  }

  Future<void> _updatePhotoMarker(PhotoMarker oldMarker, PhotoMarker updatedMarker) async {
    try {
      final index = _photoMarkers.indexWhere((marker) => marker.id == oldMarker.id);
      if (index != -1) {
        _photoMarkers[index] = updatedMarker;
        await StorageService.saveMarkers(_photoMarkers);
        setState(() {
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating marker: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      _triggerHaptics();
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      await _addPhotoAtLocation(image.path, 'Photo taken');
      _triggerHaptics();
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _addPhotoAtLocation(String imagePath, String actionType) async {
    try {
      final savedPath = await StorageService.savePhoto(imagePath);
      
      final photoMarker = PhotoMarker(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: _currentMapCenter.latitude,
        longitude: _currentMapCenter.longitude,
        imagePath: savedPath,
        timestamp: DateTime.now(),
        description: '$actionType at ${DateTime.now().toString().substring(0, 16)}',
      );

      _photoMarkers.add(photoMarker);
      await StorageService.saveMarkers(_photoMarkers);
      
      setState(() {
      });

      _showSuccess('Photo added to map at current view center!');
    } catch (e) {
      _showError('Error saving photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      await _addPhotoAtLocation(image.path, 'Photo added from gallery');
    } catch (e) {
      _showError('Error adding photo: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _zoomIn() {
    if (_mapController != null) {
      final currentZoom = _mapController!.camera.zoom;
      _mapController!.move(_currentMapCenter, currentZoom + 1);
    }
  }

  void _zoomOut() {
    if (_mapController != null) {
      final currentZoom = _mapController!.camera.zoom;
      _mapController!.move(_currentMapCenter, currentZoom - 1);
    }
  }


  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pragueCenter,
        initialZoom: _defaultMapZoom,
        onPositionChanged: (MapCamera position, bool hasGesture) {
          if (hasGesture) {
            setState(() {
              _currentMapCenter = position.center;
            });
          } else {
            _currentMapCenter = position.center;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mapPhotoApp',
        ),
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildFlutterMap(),
          const Center(
            child: Icon(
              Icons.add,
              size: 30,
              color: Colors.red,
            ),
          ),
          
          // Info banner  
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showCoordinatesInInfo) ...[
                        Text(
                          '${_currentMapCenter.latitude.toStringAsFixed(4)}, ${_currentMapCenter.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_photoMarkers.length} photos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Left side buttons
          Positioned(
            left: 16,
            top: 120,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomIn,
                  heroTag: "zoom_in",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _zoomOut,
                  heroTag: "zoom_out",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _loadCurrentLocation,
                  heroTag: "location",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          
          // Right side buttons
          Positioned(
            right: 16,
            top: 120,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _openSearch(),
                  heroTag: "search",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  child: const Icon(Icons.search),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          showCoordinates: _showCoordinatesInInfo,
                          defaultZoom: _defaultMapZoom,
                          enableHaptics: _enableHaptics,
                        ),
                      ),
                    );
                    
                    if (result != null) {
                      setState(() {
                        _showCoordinatesInInfo = result['showCoordinates'] ?? _showCoordinatesInInfo;
                        _defaultMapZoom = result['defaultZoom'] ?? _defaultMapZoom;
                        _enableHaptics = result['enableHaptics'] ?? _enableHaptics;
                      });
                      _saveSettings();
                    }
                  },
                  heroTag: "settings",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey.shade600,
                  child: const Icon(Icons.settings),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 68,
        height: 68,
        child: FloatingActionButton(
          onPressed: _showPhotoOptions,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_a_photo, size: 30),
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showCoordinatesInInfo = prefs.getBool('showCoordinates') ?? true;
      _defaultMapZoom = prefs.getDouble('defaultZoom') ?? 12.0;
      _enableHaptics = prefs.getBool('enableHaptics') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showCoordinates', _showCoordinatesInInfo);
    await prefs.setDouble('defaultZoom', _defaultMapZoom);
    await prefs.setBool('enableHaptics', _enableHaptics);
  }

  void _triggerHaptics() {
    if (_enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _openSearch() async {
    _triggerHaptics();
    final SearchResult? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
    
    if (result != null && _mapController != null) {
      _triggerHaptics();
      final targetLocation = LatLng(result.latitude, result.longitude);
      _mapController!.move(targetLocation, _defaultMapZoom);
      
      setState(() {
        _currentMapCenter = targetLocation;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigated to ${result.shortName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}