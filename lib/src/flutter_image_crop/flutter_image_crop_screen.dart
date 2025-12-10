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

  Size displayedImageSize = Size.zero;
  Offset displayedImageOffset = Offset.zero;

  Rect cropRect = Rect.fromLTWH(50, 50, 200, 200);

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
    } catch (e) {
      print("❌ Error loading image: $e");
    }
  }

  void _calculateImageDisplay(Size containerSize) {
    if (image == null) return;
    if (lastContainerSize == containerSize) return;

    lastContainerSize = containerSize;

    final imgW = image!.width.toDouble();
    final imgH = image!.height.toDouble();

    final scale = (containerSize.width / imgW)
        .clamp(0, containerSize.height / imgH);

    final displayedWidth = imgW * scale;
    final displayedHeight = imgH * scale;

    final offsetX = (containerSize.width - displayedWidth) / 2;
    final offsetY = (containerSize.height - displayedHeight) / 2;

    displayedImageSize = Size(displayedWidth, displayedHeight);
    displayedImageOffset = Offset(offsetX, offsetY);

    setState(() {});
  }

  Rect _screenToImageCoordinates(Rect screenRect) {
    if (image == null) return screenRect;

    final scale = displayedImageSize.width / image!.width;

    final left = (screenRect.left - displayedImageOffset.dx) / scale;
    final top = (screenRect.top - displayedImageOffset.dy) / scale;
    final right = (screenRect.right - displayedImageOffset.dx) / scale;
    final bottom = (screenRect.bottom - displayedImageOffset.dy) / scale;

    final w = image!.width.toDouble();
    final h = image!.height.toDouble();

    return Rect.fromLTRB(
      left.clamp(0, w),
      top.clamp(0, h),
      right.clamp(0, w),
      bottom.clamp(0, h),
    );
  }

  Future<Uint8List> _cropImage() async {
    final crop = _screenToImageCoordinates(cropRect);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      image!,
      crop,
      Rect.fromLTWH(0, 0, crop.width, crop.height),
      Paint(),
    );

    final picture = recorder.endRecording();
    final cropped =
    await picture.toImage(crop.width.toInt(), crop.height.toInt());

    final byteData =
    await cropped.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _saveCroppedImage() async {
    try {
      final bytes = await _cropImage();
      Navigator.pop(context, bytes); // 🔥 RETURN CROPPED IMAGE
    } catch (e) {
      print("❌ Error cropping: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: _saveCroppedImage,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _calculateImageDisplay(constraints.biggest);
          });

          if (image == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Image.file(widget.imageFile, fit: BoxFit.contain),
              ),

              // Black overlay + crop box
              Positioned.fill(
                child: CustomPaint(
                  painter: _CropOverlayPainter(cropRect),
                ),
              ),

              // Draggable crop box
              Positioned(
                left: cropRect.left,
                top: cropRect.top,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      cropRect = cropRect.translate(d.delta.dx, d.delta.dy);
                    });
                  },
                  child: Container(
                    width: cropRect.width,
                    height: cropRect.height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            cropRect = Rect.fromLTWH(
                              cropRect.left,
                              cropRect.top,
                              cropRect.width + d.delta.dx,
                              cropRect.height + d.delta.dy,
                            );
                          });
                        },
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()
      ..color = Colors.black.withOpacity(0.6);

    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cut = Path()..addRect(cropRect);
    final finalPath = Path.combine(PathOperation.difference, full, cut);

    canvas.drawPath(finalPath, overlay);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
