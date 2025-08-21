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
import '../widgets/custom_floating_action_button.dart';
import '../widgets/info_banner.dart';
import '../models/search_result.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';
import '../utils/snackbar_helper.dart';
import '../utils/photo_picker_helper.dart';
import '../utils/app_logger.dart';
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
  
  // Prague coordinates as default
  static const LatLng _pragueCenter = LatLng(AppConstants.pragueLatitude, AppConstants.pragueLongitude);
  LatLng _currentMapCenter = _pragueCenter;
  
  // Settings
  bool _showCoordinatesInInfo = true;
  double _defaultMapZoom = AppConstants.defaultMapZoom;
  bool _enableHaptics = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadSettings();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    AppLogger.info('MapScreen', 'Starting app initialization');
    
    // Validate storage before loading markers
    final storageValid = await StorageService.validateAndRepairStorage();
    AppLogger.debug('MapScreen', 'Storage validation result: $storageValid');
    
    await _loadPhotoMarkers();
    // Don't request location on startup - let user decide 
    setState(() {
      _isLoading = false;
    });
    
    AppLogger.info('MapScreen', 'App initialization complete');
  }

  /// Get current location - handles both startup and user requests
  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _currentMapCenter = LatLng(position.latitude, position.longitude);
        });
        
        if (_mapController != null) {
          _mapController!.move(LatLng(position.latitude, position.longitude), AppConstants.defaultMapZoom);
        }
        
        SnackBarHelper.showSuccess(context, 'Location updated successfully');
      } else {
        // Check if permanently denied and show settings dialog
        if (await LocationService.isPermissionPermanentlyDenied()) {
          _showLocationPermissionDialog();
        } else {
          SnackBarHelper.showError(context, 'Unable to get location. Please check location services.');
        }
      }
    } catch (e) {
      AppLogger.error('MapScreen', 'Location error', e);
      SnackBarHelper.showError(context, 'Location error occurred. Please try again.');
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppConstants.locationPermissionTitle),
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
        width: AppConstants.markerSize,
        height: AppConstants.markerSize,
        point: LatLng(photoMarker.latitude, photoMarker.longitude),
        child: GestureDetector(
          onTap: () => _showPhotoDetail(photoMarker),
          child: Container(
            width: AppConstants.markerSize,
            height: AppConstants.markerSize,
            decoration: AppStyles.markerShadow,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.circularBorderRadius - AppConstants.borderCircularOffset),
              child: Image.file(
                File(photoMarker.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue,
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: AppConstants.largeIconSize,
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
        SnackBarHelper.showSuccess(context, AppConstants.photoDeletedMessage);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, '${AppConstants.errorDeletingMarker} $e');
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
        SnackBarHelper.showError(context, '${AppConstants.errorUpdatingMarker} $e');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      _triggerHaptics();
      final XFile? image = await PhotoPickerHelper.pickFromCamera();

      if (image == null) return;

      await _addPhotoAtLocation(image.path, AppConstants.photoTakenMessage);
      _triggerHaptics();
    } catch (e) {
      SnackBarHelper.showError(context, '${AppConstants.errorTakingPhoto} $e');
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
        // Trigger rebuild for new marker
      });

      SnackBarHelper.showSuccess(context, AppConstants.photoAddedSuccessMessage);
    } catch (e) {
      SnackBarHelper.showError(context, '${AppConstants.errorSavingPhoto} $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await PhotoPickerHelper.pickFromGallery();

      if (image == null) return;

      await _addPhotoAtLocation(image.path, AppConstants.photoFromGalleryMessage);
    } catch (e) {
      SnackBarHelper.showError(context, '${AppConstants.errorSavingPhoto} $e');
    }
  }


  void _zoomIn() {
    if (_mapController != null) {
      final currentZoom = _mapController!.camera.zoom;
      _mapController!.move(_currentMapCenter, currentZoom + AppConstants.maxLinesSingle);
    }
  }

  void _zoomOut() {
    if (_mapController != null) {
      final currentZoom = _mapController!.camera.zoom;
      _mapController!.move(_currentMapCenter, currentZoom - AppConstants.maxLinesSingle);
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
          // Crosshair - always centered on screen
          const Center(
            child: Icon(
              Icons.add,
              size: AppConstants.crosshairSize,
              color: Colors.red,
            ),
          ),
          
          // Info banner  
          Positioned(
            top: AppConstants.topOffset,
            left: AppConstants.standardPadding,
            right: AppConstants.standardPadding,
            child: InfoBanner(
              currentMapCenter: _currentMapCenter,
              showCoordinates: _showCoordinatesInInfo,
              photoCount: _photoMarkers.length,
            ),
          ),
          
          // Left side buttons - positioned dynamically based on coordinates display
          Positioned(
            left: AppConstants.standardPadding,
            top: _showCoordinatesInInfo 
                ? AppConstants.buttonTopOffset + AppConstants.buttonOffsetWithCoords
                : AppConstants.buttonTopOffset - AppConstants.buttonOffsetNoCoords,
            child: MapButtonGroup(
              buttons: [
                MapControlButton(
                  onPressed: _zoomIn,
                  icon: Icons.add,
                  heroTag: AppConstants.zoomInHeroTag,
                ),
                MapControlButton(
                  onPressed: _zoomOut,
                  icon: Icons.remove,
                  heroTag: AppConstants.zoomOutHeroTag,
                ),
                MapControlButton(
                  onPressed: _getCurrentLocation,
                  icon: Icons.my_location,
                  heroTag: AppConstants.locationHeroTag,
                  foregroundColor: Colors.blue,
                ),
              ],
            ),
          ),
          
          // Right side buttons - positioned dynamically based on coordinates display
          Positioned(
            right: AppConstants.standardPadding,
            top: _showCoordinatesInInfo 
                ? AppConstants.buttonTopOffset + AppConstants.buttonOffsetWithCoords
                : AppConstants.buttonTopOffset - AppConstants.buttonOffsetNoCoords,
            child: MapButtonGroup(
              buttons: [
                MapControlButton(
                  onPressed: _openSearch,
                  icon: Icons.search,
                  heroTag: AppConstants.searchHeroTag,
                  foregroundColor: Colors.blue,
                ),
                MapControlButton(
                  onPressed: _openSettings,
                  icon: Icons.settings,
                  heroTag: AppConstants.settingsHeroTag,
                  foregroundColor: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: _showPhotoOptions,
        icon: Icons.add_a_photo,
        heroTag: "photo",
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        mini: false,
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showCoordinatesInInfo = prefs.getBool(AppConstants.showCoordinatesKey) ?? true;
      _defaultMapZoom = prefs.getDouble(AppConstants.defaultZoomKey) ?? AppConstants.defaultMapZoom;
      _enableHaptics = prefs.getBool(AppConstants.enableHapticsKey) ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.showCoordinatesKey, _showCoordinatesInInfo);
    await prefs.setDouble(AppConstants.defaultZoomKey, _defaultMapZoom);
    await prefs.setBool(AppConstants.enableHapticsKey, _enableHaptics);
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

      SnackBarHelper.showSuccess(context, '${AppConstants.navigatedToMessage} ${result.shortName}');
    }
  }

  void _openSettings() async {
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
        _showCoordinatesInInfo = result[AppConstants.showCoordinatesKey] ?? _showCoordinatesInInfo;
        _defaultMapZoom = result[AppConstants.defaultZoomKey] ?? _defaultMapZoom;
        _enableHaptics = result[AppConstants.enableHapticsKey] ?? _enableHaptics;
      });
      _saveSettings();
    }
  }
}