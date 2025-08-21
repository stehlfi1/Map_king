import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../styles/app_styles.dart';

class SnackBarHelper {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyles.successGreen,
        duration: const Duration(seconds: AppConstants.snackBarDurationSeconds),
      ),
    );
  }
  
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyles.errorRed,
        duration: const Duration(seconds: AppConstants.snackBarDurationSeconds),
      ),
    );
  }
  
}