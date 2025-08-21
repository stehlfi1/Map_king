import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

class InfoBanner extends StatelessWidget {
  final LatLng currentMapCenter;
  final bool showCoordinates;
  final int photoCount;

  const InfoBanner({
    super.key,
    required this.currentMapCenter,
    required this.showCoordinates,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.compactPadding),
      decoration: AppStyles.cardShadow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCoordinates) ...[
            Text(
              '${currentMapCenter.latitude.toStringAsFixed(4)}, ${currentMapCenter.longitude.toStringAsFixed(4)}',
              style: AppStyles.coordinateText(context),
              textAlign: TextAlign.center,
            ),
            AppStyles.smallVerticalSpace,
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera,
                color: Colors.green.shade600,
                size: AppConstants.smallIconSize,
              ),
              AppStyles.smallHorizontalSpace,
              Text(
                '$photoCount photos',
                style: AppStyles.photoCountText(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}