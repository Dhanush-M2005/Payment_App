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

          if (rawValue != null && rawValue.startsWith('upi://pay')) {
            await _controller?.stopImageStream();
            if (!mounted) return;

            Navigator.pop(context, {
              'upiUri': rawValue, // ✅ FULL URI
            });
            return;
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
        if (rawValue != null && rawValue.startsWith('upi://pay')) {
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

    final bytes = Uint8List.fromList(
      image.planes.fold<List<int>>(
        [],
        (prev, plane) => prev..addAll(plane.bytes),
      ),
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan UPI QR"), actions: const []),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          // Scan Area Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.image),
                label: const Text("Upload from Gallery"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
