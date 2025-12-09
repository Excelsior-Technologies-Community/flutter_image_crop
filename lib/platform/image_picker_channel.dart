import 'package:flutter/services.dart';

class NativeImagePicker {
  static const MethodChannel _channel =
  MethodChannel('native_image_picker');

  static Future<String?> pickImageFromGallery() async {
    try {
      final String? imagePath = await _channel.invokeMethod('pickImage');
      return imagePath;
    } on PlatformException catch (e) {
      print("❌ Platform error: ${e.message}");
      return null;
    } catch (e) {
      print("❌ Error: $e");
      return null;
    }
  }
}