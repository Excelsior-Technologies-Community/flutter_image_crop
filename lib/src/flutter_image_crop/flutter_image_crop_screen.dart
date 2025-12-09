import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FlutterImageCropScreen extends StatefulWidget {
  final File imageFile;

  const FlutterImageCropScreen({super.key, required this.imageFile});

  @override
  State<FlutterImageCropScreen> createState() => _FlutterImageCropScreenState();
}

class _FlutterImageCropScreenState extends State<FlutterImageCropScreen> {
  ui.Image? image;

  // Displayed image size and position
  Size displayedImageSize = Size.zero;
  Offset displayedImageOffset = Offset.zero;

  // Crop rectangle
  Rect cropRect = Rect.fromLTWH(50, 50, 200, 200);

  // To prevent infinite calculations
  Size? lastContainerSize;

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  Future<void> loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        image = frame.image;
      });
      print("✅ Image loaded: ${image!.width}x${image!.height}");
    } catch (e) {
      print("❌ Error loading image: $e");
    }
  }

  // Calculate how the image is displayed (with BoxFit.contain)
  void _calculateImageDisplay(Size containerSize) {
    if (image == null) return;

    // Calculate only if container size changed
    if (lastContainerSize == containerSize) return;
    lastContainerSize = containerSize;

    final imageWidth = image!.width.toDouble();
    final imageHeight = image!.height.toDouble();

    // Calculate scale to fit image in container with BoxFit.contain
    final scaleX = containerSize.width / imageWidth;
    final scaleY = containerSize.height / imageHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate displayed size
    final displayedWidth = imageWidth * scale;
    final displayedHeight = imageHeight * scale;

    // Calculate offset to center the image
    final offsetX = (containerSize.width - displayedWidth) / 2;
    final offsetY = (containerSize.height - displayedHeight) / 2;

    setState(() {
      displayedImageSize = Size(displayedWidth, displayedHeight);
      displayedImageOffset = Offset(offsetX, offsetY);
    });

    // Print only once
    print("📐 Image Display Calculation:");
    print("   Container: $containerSize");
    print("   Image: ${image!.width}x${image!.height}");
    print(
      "   Displayed: ${displayedWidth.toInt()}x${displayedHeight.toInt()} at Offset(${offsetX.toInt()}, ${offsetY.toInt()})",
    );
    print("   Scale: ${scale.toStringAsFixed(4)}");
  }

  // Convert screen crop rect to actual image pixels
  Rect _screenToImageCoordinates(Rect screenRect) {
    if (image == null) return screenRect;

    // Calculate scale factor
    final scale = displayedImageSize.width / image!.width;
    if (scale == 0) return screenRect;

    // Adjust for image offset and scale
    final double left = (screenRect.left - displayedImageOffset.dx) / scale;
    final double top = (screenRect.top - displayedImageOffset.dy) / scale;
    final double right = (screenRect.right - displayedImageOffset.dx) / scale;
    final double bottom = (screenRect.bottom - displayedImageOffset.dy) / scale;

    // Clamp to image bounds
    final imageWidth = image!.width.toDouble();
    final imageHeight = image!.height.toDouble();

    final clampedLeft = left.clamp(0, imageWidth).toDouble();
    final clampedTop = top.clamp(0, imageHeight).toDouble();
    final clampedRight = right.clamp(0, imageWidth).toDouble();
    final clampedBottom = bottom.clamp(0, imageHeight).toDouble();

    // Calculate final width and height
    final width = (clampedRight - clampedLeft).clamp(1, imageWidth).toDouble();
    final height = (clampedBottom - clampedTop)
        .clamp(1, imageHeight)
        .toDouble();

    return Rect.fromLTWH(clampedLeft, clampedTop, width, height);
  }

  Future<Uint8List> _cropImage() async {
    if (image == null) {
      throw Exception("Image not loaded");
    }

    // Convert screen crop rect to image coordinates
    final imageCropRect = _screenToImageCoordinates(cropRect);

    // Print crop info
    print("✂️ Crop Info:");
    print(
      "   Screen crop: ${cropRect.left.toInt()},${cropRect.top.toInt()} ${cropRect.width.toInt()}x${cropRect.height.toInt()}",
    );
    print(
      "   Image crop: ${imageCropRect.left.toInt()},${imageCropRect.top.toInt()} ${imageCropRect.width.toInt()}x${imageCropRect.height.toInt()}",
    );

    // Create canvas for cropped image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw the cropped portion
    canvas.drawImageRect(
      image!,
      imageCropRect,
      Rect.fromLTWH(0, 0, imageCropRect.width, imageCropRect.height),
      paint,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(
      imageCropRect.width.toInt(),
      imageCropRect.height.toInt(),
    );

    // Convert to bytes
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  void _saveCroppedImage() async {
    try {
      final croppedBytes = await _cropImage();

      // Show cropped image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Cropped Image")),
            body: Center(child: Image.memory(croppedBytes)),
          ),
        ),
      );
    } catch (e) {
      print("❌ Error cropping: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error cropping: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: _saveCroppedImage,
            tooltip: "Crop",
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate image display when layout is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculateImageDisplay(constraints.biggest);
          });

          return image == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Display image with BoxFit.contain
                    Center(
                      child: Image.file(widget.imageFile, fit: BoxFit.contain),
                    ),

                    // Crop overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropOverlayPainter(
                          cropRect,
                          displayedImageOffset,
                          displayedImageSize,
                        ),
                      ),
                    ),

                    // Crop rectangle (draggable)
                    Positioned(
                      left: cropRect.left,
                      top: cropRect.top,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            cropRect = cropRect.translate(
                              details.delta.dx,
                              details.delta.dy,
                            );
                          });
                        },
                        child: Container(
                          width: cropRect.width,
                          height: cropRect.height,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Stack(
                            children: [
                              // Resize handle - bottom right
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      cropRect = Rect.fromLTWH(
                                        cropRect.left,
                                        cropRect.top,
                                        cropRect.width + details.delta.dx,
                                        cropRect.height + details.delta.dy,
                                      );
                                    });
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Instructions
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Instructions:",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "• Drag square to move",
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              "• Drag blue circle to resize",
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              "• Tap crop button when done",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "reset",
            onPressed: () {
              setState(() {
                cropRect = Rect.fromLTWH(
                  (displayedImageOffset.dx + displayedImageSize.width / 2) -
                      100,
                  (displayedImageOffset.dy + displayedImageSize.height / 2) -
                      100,
                  200,
                  200,
                );
              });
            },
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Custom painter for crop overlay
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Offset imageOffset;
  final Size imageSize;

  _CropOverlayPainter(this.cropRect, this.imageOffset, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent overlay outside crop area
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw grid lines inside crop area
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.bottom),
      gridPaint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height * 2 / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height * 2 / 3),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
