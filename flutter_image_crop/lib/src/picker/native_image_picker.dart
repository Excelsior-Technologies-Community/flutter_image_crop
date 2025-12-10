import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class NativeImagePicker {
  static const MethodChannel _channel =
  MethodChannel('native_image_picker');

  static Future<File?> pickImage() async {
    final path = await _channel.invokeMethod<String>('pickImage');
    if (path == null) return null;
    return File(path);
  }
}
