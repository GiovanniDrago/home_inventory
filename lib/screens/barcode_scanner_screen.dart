import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _isScanned = false;
  bool _isFlashOn = false;
  final _manualController = TextEditingController();
  final _focusNode = FocusNode();

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isScanned = true);
    _controller.stop();
    Navigator.of(context).pop(barcode.rawValue);
  }

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  void _submitManual() {
    final barcode = _manualController.text.trim();
    if (barcode.isNotEmpty) {
      _controller.stop();
      Navigator.of(context).pop(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            onPressed: () {
              _controller.stop();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return _CameraErrorView(
                error: error,
                onManualEntry: () => _focusNode.requestFocus(),
              );
            },
          ),
          // Scan frame overlay
          Center(
            child: Container(
              width: 250,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Top controls
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'flash',
                onPressed: _toggleFlash,
                backgroundColor: Colors.black54,
                child: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Bottom instruction + manual entry
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Align barcode within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Or type barcode manually',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white24,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            keyboardType: TextInputType.number,
                            onSubmitted: (_) => _submitManual(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _submitManual,
                          child: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onManualEntry;

  const _CameraErrorView({required this.error, required this.onManualEntry});

  @override
  Widget build(BuildContext context) {
    String message = 'Camera error';
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      message = 'Camera permission denied. Please enable camera access in settings.';
    } else if (error.errorCode == MobileScannerErrorCode.unsupported) {
      message = 'Barcode scanning is not supported on this device.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onManualEntry,
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter Barcode Manually'),
            ),
          ],
        ),
      ),
    );
  }
}
