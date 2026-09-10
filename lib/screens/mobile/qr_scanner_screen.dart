import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/app_theme.dart';
import '../../core/app_widgets.dart';
import '../../data/qr_repository.dart';
import 'qr_result_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({required this.repository, super.key});

  final QrRepository repository;

  @override
  State<QrScannerScreen> createState() {
    return _QrScannerScreenState();
  }
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool isProcessing = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> verifyValue(String value) async {
    final cleanedValue = value.trim();

    if (isProcessing || cleanedValue.isEmpty) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await scannerController.stop();

      final result = await widget.repository.verifyQrData(cleanedValue);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) {
            return QrResultScreen(result: result);
          },
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not verify the QR code: $error')),
      );

      setState(() {
        isProcessing = false;
      });

      await scannerController.start();
    }
  }

  Future<void> enterManually() async {
    final inputController = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter QR destination'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL or QR data',
              hintText: 'https://merchant.example/pay',
            ),
            onSubmitted: (enteredValue) {
              Navigator.of(dialogContext).pop(enteredValue);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(inputController.text);
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    inputController.dispose();

    if (value != null && value.trim().isNotEmpty) {
      await verifyValue(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Scan QR Code',
      onBack: () => Navigator.of(context).pop(),
      showBottomNavigation: false,
      darkBackground: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (capture.barcodes.isEmpty) {
                return;
              }

              final value = capture.barcodes.first.rawValue;

              if (value != null) {
                verifyValue(value);
              }
            },
            errorBuilder: (context, error) {
              return Container(
                color: const Color(0xFF090B10),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.no_photography_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Camera is unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorDetails?.message ?? error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: enterManually,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      child: const Text('Enter QR Details Manually'),
                    ),
                  ],
                ),
              );
            },
          ),

          IgnorePointer(
            child: Container(color: Colors.black.withValues(alpha: 0.42)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  const Text(
                    'Point the camera at a payment QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.red, width: 3),
                    ),
                    child: Center(
                      child: isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(
                              Icons.qr_code_2_rounded,
                              color: Colors.white24,
                              size: 130,
                            ),
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'Works with payment links, merchant '
                    'codes and tourism posters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 14),

                  OutlinedButton(
                    onPressed: isProcessing ? null : enterManually,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    child: const Text('Enter Manually'),
                  ),

                  const SizedBox(height: 4),

                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) {
                            return const CameraHelpScreen();
                          },
                        ),
                      );
                    },
                    child: const Text(
                      'Camera access help',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraHelpScreen extends StatelessWidget {
  const CameraHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileShell(
      title: 'Camera Access',
      onBack: () => Navigator.of(context).pop(),
      showBottomNavigation: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.blue,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Allow camera access in your browser or '
              'Android settings to scan payment and '
              'merchant QR codes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            PrimaryActionButton(
              label: 'Return to Scanner',
              icon: Icons.camera_alt_outlined,
              color: AppColors.red,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Enter Details Manually'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
