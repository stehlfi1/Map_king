import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String heroTag;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const CustomFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = true,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: mini,
      onPressed: onPressed,
      heroTag: heroTag,
      backgroundColor: backgroundColor ?? Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
      child: Icon(icon),
    );
  }
}

class MapControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String heroTag;
  final Color? foregroundColor;

  const MapControlButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.heroTag,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      heroTag: heroTag,
      backgroundColor: Colors.white,
      foregroundColor: foregroundColor ?? Colors.black,
    );
  }
}

class MapButtonGroup extends StatelessWidget {
  final List<MapControlButton> buttons;

  const MapButtonGroup({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: buttons
          .map((button) => [
                button,
                if (button != buttons.last)
                  const SizedBox(height: AppConstants.fabSpacing),
              ])
          .expand((element) => element)
          .toList(),
    );
  }
}

class IconContainer extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double? size;

  const IconContainer({
    super.key,
    required this.icon,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.all(AppConstants.fabSpacing),
      decoration: AppStyles.iconContainer(color),
      child: Icon(
        icon,
        color: color,
        size: size ?? AppConstants.mediumIconSize,
      ),
    );
  }
}