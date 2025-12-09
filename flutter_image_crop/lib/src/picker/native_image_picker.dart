// File: lib/platform/image_picker_channel.dart

import 'package:flutter/services.dart';

class NativeImagePicker {
  static const MethodChannel _channel = MethodChannel('native_image_picker');

  static Future<String?> pickImageFromGallery() async {
    try {
      final String? path = await _channel.invokeMethod('pickImage');
      return path;
    } on PlatformException catch (e) {
      print("Failed to pick image: ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error: $e");
      return null;
    }
  }
}