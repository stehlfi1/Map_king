class AppConstants {
  // UI Dimensions
  static const double markerSize = 70.0;
  static const double crosshairSize = 30.0;
  static const double fabSpacing = 8.0;
  static const double standardPadding = 16.0;
  static const double smallPadding = 4.0;
  static const double largePadding = 20.0;
  static const double compactPadding = 12.0;
  
  // Header Dimensions  
  static const double coordinateTextWidth = 140.0;
  
  // Map Constants
  static const double defaultMapZoom = 12.0;
  static const double pragueLatitude = 49.7437;
  static const double pragueLongitude = 14.3208;
  
  // Positioning
  static const double topOffset = 50.0;
  static const double buttonTopOffset = 120.0; // Base position for buttons
  
  // Image Settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
  
  // Animation & Timing
  static const int debounceDelayMs = 500;
  static const int snackBarDurationSeconds = 2;
  
  // UI Components
  static const double searchBarHeight = 45.0;
  static const double circularProgressStrokeWidth = 2.0;
  static const double dividerHeight = 1.0;
  static const int maxLinesSingle = 1;
  static const int maxLinesDouble = 2;
  static const double borderCircularOffset = 4.0;
  
  // Button positioning offsets
  static const double buttonOffsetWithCoords = 20.0;
  static const double buttonOffsetNoCoords = 10.0;
  
  // Text & Messages
  static const String photoTakenMessage = 'Photo taken';
  static const String photoFromGalleryMessage = 'Photo added from gallery';
  static const String photoAddedSuccessMessage = 'Photo added to map at current view center!';
  static const String photoDeletedMessage = 'Photo marker deleted';
  static const String errorTakingPhoto = 'Error taking photo:';
  static const String errorSavingPhoto = 'Error saving photo:';
  static const String errorDeletingMarker = 'Error deleting marker:';
  static const String errorUpdatingMarker = 'Error updating marker:';
  static const String searchFailedMessage = 'Search failed. Please try again.';
  static const String navigatedToMessage = 'Navigated to';
  
  // Dialog Titles
  static const String locationPermissionTitle = 'Location Permission Needed';
  static const String deletePhotoTitle = 'Delete Photo';
  static const String photoDetailsTitle = 'Photo Details';
  
  // Settings Keys
  static const String showCoordinatesKey = 'showCoordinates';
  static const String defaultZoomKey = 'defaultZoom';
  static const String enableHapticsKey = 'enableHaptics';
  
  // Hero Tags
  static const String zoomInHeroTag = "zoom_in";
  static const String zoomOutHeroTag = "zoom_out";
  static const String locationHeroTag = "location";
  static const String searchHeroTag = "search";
  static const String settingsHeroTag = "settings";
  
  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 20.0;
  static const double largeIconSize = 30.0;
  static const double extraLargeIconSize = 50.0;
  static const double listTileIconSize = 40.0;
  
  // Border Radius
  static const double smallBorderRadius = 4.0;
  static const double standardBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;
  static const double roundBorderRadius = 25.0;
  static const double circularBorderRadius = 35.0;
  
  // Opacity Values
  static const double backgroundOpacity = 0.9;
  static const double shadowOpacity = 0.2;
  static const double lightShadowOpacity = 0.05;
  static const double buttonBackgroundOpacity = 0.1;
  static const double darkShadowOpacity = 0.4;
  
  // Text Sizes
  static const double smallTextSize = 12.0;
  static const double mediumTextSize = 13.0;
  static const double standardTextSize = 14.0;
  static const double titleTextSize = 16.0;
  static const double largeTextSize = 18.0;
  
  // Storage Keys
  static const String markersStorageKey = 'photo_markers';
  static const String photoDirectoryName = 'photos';
}