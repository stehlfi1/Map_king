import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';

class PhotoPickerHelper {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: AppConstants.maxImageWidth.toDouble(),
      maxHeight: AppConstants.maxImageHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );
  }
  
  static Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.maxImageWidth.toDouble(),
      maxHeight: AppConstants.maxImageHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );
  }
  
  static Future<XFile?> pickImage(ImageSource source) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: AppConstants.maxImageWidth.toDouble(),
      maxHeight: AppConstants.maxImageHeight.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );
  }
}