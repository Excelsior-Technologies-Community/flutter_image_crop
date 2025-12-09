# flutter_image_crop
A simple, native image cropping library for Flutter without third-party dependencies. Built with pure Dart and Flutter widgets.

## Features
- 🖼️ Native Flutter Implementation - No external native dependencies-
- 🎯 Simple API - Easy to integrate and use
- 🎨 Customizable UI - Adjustable crop border colors, grid lines
- 📱 Responsive Design - Works on all screen sizes
- 🚫 No Platform Channels - Pure Dart implementation

## Installation
Add to your pubspec.yaml :
```
dependencies:
  flutter_image_crop:
    path: ../flutter_image_crop # your path
```
from git:
```
dependencies:
  flutter_image_crop:
    git:
      url: https://github.com/yourusername/flutter_image_crop.git
```
## Project Structure
```
text
flutter_image_crop/
├── lib/
│   ├── flutter_image_crop.dart      # Main export file
│   └── src/
│       ├── flutter_image_crop_screen.dart  # Main crop screen
│       └── image_picker_screen.dart        # Image picker screen
├── pubspec.yaml
└── README.md

```
## Basic Usage
```
import 'package:flutter/material.dart';
import 'package:flutter_image_crop/flutter_image_crop.dart';
import 'package:image_picker/image_picker.dart';

class MyApp extends StatelessWidget {
  final picker = ImagePicker();
  
  Future<void> cropImage(BuildContext context) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FlutterImageCropScreen(
            imageFile: File(pickedFile.path),
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => cropImage(context),
          child: Text('Crop Image'),
        ),
      ),
    );
  }
}

```
## Android Permission needed
1. AndroidManifest.xml (android/app/src/main/AndroidManifest.xml)
```
    <!-- === ESSENTIAL PERMISSIONS === -->
        <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
        <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- For Camera Access -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Optional: For saving cropped images -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"
        tools:ignore="ScopedStorage" />

```
## ImagePickerScreen
A pre-built screen for image selection.

Properties:
```
ImagePickerScreen({
  String title = 'Select Image',
  Color? appBarColor,
  Widget? customButton,
})
```
## FlutterImageCropScreen
The main cropping screen with draggable crop area.

Properties:
```
FlutterImageCropScreen({
  required File imageFile,
  Color? appBarColor,
  Color? cropBorderColor,
  double cropBorderWidth = 2.0,
  bool showGrid = true,
})
```
## Example:
```
FlutterImageCropScreen(
  imageFile: myImageFile,
  appBarColor: Colors.deepPurple,
  cropBorderColor: Colors.red,
  cropBorderWidth: 3.0,
  showGrid: false,
)
```
## Performance Tips
- Image Size: Resize large images before cropping for better performance
- Memory Management: Dispose of image resources properly
