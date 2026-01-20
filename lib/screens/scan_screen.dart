import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  bool _isInit = false;
  bool _isProcessing = false;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    setState(() => _isInit = true);
    _startScanning();
  }

  void _startScanning() {
    _controller?.startImageStream((image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        if (inputImage == null) return;

        final barcodes = await _barcodeScanner.processImage(inputImage);

        for (final barcode in barcodes) {
          final rawValue = barcode.rawValue;

          if (rawValue != null) {
            print("---------------------------------------------------------");
            print("Detected QR Code: $rawValue");
            print("---------------------------------------------------------");

            // Allow any QR that contains 'pa=' (common for UPI) OR starts with upi://
            if (rawValue.toLowerCase().startsWith('upi://') ||
                rawValue.contains('pa=')) {
              print(
                "---------------------------------------------------------",
              );
              print("Creating transaction for: $rawValue");
              print(
                "---------------------------------------------------------",
              );
              await _controller?.stopImageStream();
              if (!mounted) return;

              Navigator.pop(context, {
                'upiUri': rawValue, // ✅ FULL URI
              });
              return;
            }
          }
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);

    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);

      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue != null &&
            rawValue.toLowerCase().startsWith('upi://pay')) {
          print("---------------------------------------------------------");
          print("Creating transaction for: $rawValue");
          print("---------------------------------------------------------");
          await _controller?.stopImageStream();
          if (!mounted) return;

          Navigator.pop(context, {'upiUri': rawValue});
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No valid UPI QR code found in image")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error scanning image: $e")));
      }
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    // Concatenate planes to get full image bytes
    final allBytes = BytesBuilder();
    for (final plane in image.planes) {
      allBytes.add(plane.bytes);
    }
    final bytes = allBytes.toBytes();

    final sensorOrientation = _controller!.description.sensorOrientation;
    InputImageRotation imageRotation = InputImageRotation.rotation0deg;

    switch (sensorOrientation) {
      case 0:
        imageRotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        imageRotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        imageRotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        imageRotation = InputImageRotation.rotation270deg;
        break;
    }

    // Fixed for Android: usually rotation90deg for portrait
    if (Platform.isAndroid) {
      imageRotation = InputImageRotation.rotation90deg;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Size of the scan box
    const double scanSize = 280;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // Custom Overlay: Darkens background + Blue Corners
          CustomPaint(
            painter: ScannerOverlayPainter(
              scanWindow: Rect.fromCenter(
                center: MediaQuery.of(context).size.center(Offset.zero),
                width: scanSize,
                height: scanSize,
              ),
              borderRadius: 24.0,
              cornerColor: Colors.blue, // App Theme Blue
              cornerLength: 40.0,
              strokeWidth: 6.0,
            ),
          ),

          // Close Button (Top Left)
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),

          // Flash Button (Top Right)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: () async {
                // Toggle flash logic could go here if needed
              },
              icon: const Icon(
                Icons
                    .flash_on, // Placeholder, toggle logic needed if functional
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: const Text(
              "Scan any QR code to pay",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Upload Button
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.image, color: Colors.black),
                  label: const Text(
                    "Upload from gallery",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;
  final Color cornerColor;
  final double cornerLength;
  final double strokeWidth;

  ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderRadius,
    required this.cornerColor,
    required this.cornerLength,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Dark Overlay with Cutout
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final overlayPaint = Paint()
      ..color = Colors.black
          .withOpacity(0.5) // Darkening
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // 2. Draw Blue Corners
    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double r = borderRadius;
    final double l = cornerLength;
    final double x = scanWindow.left;
    final double y = scanWindow.top;
    final double w = scanWindow.width;
    final double h = scanWindow.height;

    // Top Left
    final pathTL = Path()
      ..moveTo(x, y + l)
      ..lineTo(x, y + r)
      ..arcToPoint(Offset(x + r, y), radius: Radius.circular(r))
      ..lineTo(x + l, y);
    canvas.drawPath(pathTL, paint);

    // Top Right
    final pathTR = Path()
      ..moveTo(x + w - l, y)
      ..lineTo(x + w - r, y)
      ..arcToPoint(Offset(x + w, y + r), radius: Radius.circular(r))
      ..lineTo(x + w, y + l);
    canvas.drawPath(pathTR, paint);

    // Bottom Right
    final pathBR = Path()
      ..moveTo(x + w, y + h - l)
      ..lineTo(x + w, y + h - r)
      ..arcToPoint(Offset(x + w - r, y + h), radius: Radius.circular(r))
      ..lineTo(x + w - l, y + h);
    canvas.drawPath(pathBR, paint);

    // Bottom Left
    final pathBL = Path()
      ..moveTo(x + l, y + h)
      ..lineTo(x + r, y + h)
      ..arcToPoint(Offset(x, y + h - r), radius: Radius.circular(r))
      ..lineTo(x, y + h - l);
    canvas.drawPath(pathBL, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
