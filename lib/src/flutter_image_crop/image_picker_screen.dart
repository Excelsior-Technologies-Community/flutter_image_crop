import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_crop/platform/image_picker_channel.dart';
import 'package:flutter_image_crop/src/flutter_image_crop/flutter_image_crop_screen.dart';
class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  Uint8List? cropped;

  Future<void> pickImage() async {
    print("📱 Calling NATIVE pickImage...");

    final file = await NativeImagePicker.pickImage();

    if (file == null) {
      print("❌ No image selected");
      return;
    }

    print("✅ Native returned: ${file.path}");

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlutterImageCropScreen(imageFile: file),
      ),
    );

    if (result != null) {
      setState(() {
        cropped = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
          title: Text("Native Image Picker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Show image first
            cropped == null
                ? const Text("No cropped image")
                : Image.memory(cropped!, width: 250),

            const SizedBox(height: 30),

            // Button BELOW the image
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick & Crop Image"),
            ),
          ],
        ),
      ),
    );
  }
}
