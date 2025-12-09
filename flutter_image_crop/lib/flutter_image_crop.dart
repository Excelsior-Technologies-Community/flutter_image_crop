library flutter_image_crop;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_crop/flutter_image_crop.dart' show FlutterImageCropScreen;

export 'src/flutter_image_crop_screen.dart';
export 'src/picker/image_picker_screen.dart';
export 'src/picker/native_image_picker.dart';

/// Main class for accessing crop functionality
class FlutterImageCrop {
  /// Version info
  static String get version => '1.0.0';

  /// Check if package is working
  static String test() => 'Flutter Image Crop Package is working!';

  static void openCrop(BuildContext context, File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlutterImageCropScreen(imageFile: imageFile),
      ),
    );
  }
}