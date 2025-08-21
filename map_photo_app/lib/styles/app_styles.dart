import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppStyles {
  // Text Styles
  static const TextStyle boldTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: AppConstants.titleTextSize,
  );
  
  static const TextStyle mediumText = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: AppConstants.mediumTextSize,
  );
  
  static const TextStyle standardText = TextStyle(
    fontSize: AppConstants.standardTextSize,
  );
  
  static const TextStyle smallText = TextStyle(
    fontSize: AppConstants.smallTextSize,
  );
  
  static const TextStyle largeTitle = TextStyle(
    fontSize: AppConstants.largeTextSize,
    fontWeight: FontWeight.w500,
  );
  
  // Color-specific text styles
  static TextStyle greyText(BuildContext context) => TextStyle(
    fontSize: AppConstants.standardTextSize,
    color: Colors.grey.shade600,
  );
  
  static TextStyle lightGreyText(BuildContext context) => TextStyle(
    fontSize: AppConstants.standardTextSize,
    color: Colors.grey.shade500,
  );
  
  static TextStyle coordinateText(BuildContext context) => TextStyle(
    fontSize: AppConstants.mediumTextSize,
    fontWeight: FontWeight.w500,
    color: Colors.grey.shade700,
  );
  
  static TextStyle photoCountText(BuildContext context) => TextStyle(
    fontSize: AppConstants.smallTextSize,
    fontWeight: FontWeight.w500,
    color: Colors.green.shade600,
  );
  
  static TextStyle subtitleText(BuildContext context) => TextStyle(
    fontSize: AppConstants.standardTextSize,
    color: Colors.grey.shade600,
  );
  
  static TextStyle errorText(BuildContext context) => TextStyle(
    fontSize: AppConstants.standardTextSize,
    color: Colors.red.shade600,
  );
  
  static const TextStyle listTileTitle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: AppConstants.titleTextSize,
  );
  
  static TextStyle listTileSubtitle(BuildContext context) => TextStyle(
    color: Colors.grey.shade600,
    fontSize: AppConstants.mediumTextSize,
  );
  
  // Box Decorations
  static BoxDecoration cardShadow = BoxDecoration(
    color: Colors.white.withOpacity(AppConstants.backgroundOpacity),
    borderRadius: BorderRadius.circular(AppConstants.standardBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(AppConstants.shadowOpacity),
        blurRadius: 4,
      ),
    ],
  );
  
  static BoxDecoration markerShadow = BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.circularBorderRadius),
    border: Border.all(color: Colors.white, width: 4),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(AppConstants.darkShadowOpacity),
        blurRadius: 6,
        spreadRadius: 2,
      ),
    ],
  );
  
  static BoxDecoration settingsCardShadow = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(AppConstants.lightShadowOpacity),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
  );
  
  static BoxDecoration iconContainer(Color color) => BoxDecoration(
    color: color.withOpacity(AppConstants.buttonBackgroundOpacity),
    borderRadius: BorderRadius.circular(AppConstants.standardBorderRadius),
  );
  
  static BoxDecoration searchBarDecoration = BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(AppConstants.roundBorderRadius),
  );
  
  static BoxDecoration commentContainer = BoxDecoration(
    border: Border.all(color: Colors.grey.shade300),
    borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
  );
  
  static BoxDecoration searchResultIcon(BuildContext context) => BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(AppConstants.mediumIconSize),
  );
  
  // Input Decorations
  static const InputDecoration searchInputDecoration = InputDecoration(
    hintText: 'Search places...',
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppConstants.largePadding, 
      vertical: AppConstants.largeBorderRadius
    ),
  );
  
  static const InputDecoration commentInputDecoration = InputDecoration(
    hintText: 'Add a comment...',
    border: OutlineInputBorder(),
  );
  
  // Common Padding
  static const EdgeInsets standardPadding = EdgeInsets.all(AppConstants.standardPadding);
  static const EdgeInsets smallPadding = EdgeInsets.all(AppConstants.smallPadding);
  static const EdgeInsets largePadding = EdgeInsets.all(AppConstants.largePadding);
  
  // Sized Boxes (common spacing)
  static const SizedBox smallVerticalSpace = SizedBox(height: AppConstants.smallPadding);
  static const SizedBox standardVerticalSpace = SizedBox(height: AppConstants.fabSpacing);
  static const SizedBox mediumVerticalSpace = SizedBox(height: AppConstants.standardPadding);
  static const SizedBox largeVerticalSpace = SizedBox(height: AppConstants.largePadding);
  
  static const SizedBox smallHorizontalSpace = SizedBox(width: AppConstants.smallPadding);
  static const SizedBox standardHorizontalSpace = SizedBox(width: AppConstants.fabSpacing);
  static const SizedBox mediumHorizontalSpace = SizedBox(width: AppConstants.standardPadding);
  
  // Colors
  static const Color primaryBlue = Colors.blue;
  static const Color successGreen = Colors.green;
  static const Color errorRed = Colors.red;
  static const Color warningOrange = Colors.orange;
}