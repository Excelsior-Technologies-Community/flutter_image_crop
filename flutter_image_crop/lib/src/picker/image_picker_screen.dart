import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_crop/src/flutter_image_crop_screen.dart';
import 'package:flutter_image_crop/src/picker/native_image_picker.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  bool isLoading = false;

  Future<void> pickAndCrop(BuildContext context) async {
    setState(() { isLoading = true; });

    try {
      final path = await NativeImagePicker.pickImageFromGallery();

      if (path == null || path.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No image selected")),
          );
        }
        return;
      }

      print("📁 Selected path: $path");

      final selectedFile = File(path);

      if (await selectedFile.exists()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlutterImageCropScreen(imageFile: selectedFile),
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File not found. Try selecting from 'Files' app instead of 'Photos'.")),
          );
        }
      }
    } catch (e) {
      print("❌ Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Image Picker")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () => pickAndCrop(context),
          child: const Text("Pick Image & Crop"),
        ),
      ),
    );
  }
}