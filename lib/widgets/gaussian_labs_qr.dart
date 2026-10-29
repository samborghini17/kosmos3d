import '../l10n/app_text.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// GoPro Labs video recipe. No shutter/start command is included.
/// Linear lens is subsequently set and verified by BLE (setting 121).
const gaussianVideoLabsRecipe = 'mVr4p30w55i2M1i2S45b1e0hS0';
Future<void> showGaussianLabsQr(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const AppText('Gaussian Splatting - daylight video'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppText(
            'Requires GoPro Labs firmware. Show this QR to each camera and confirm the settings on its display. No capture is started.',
          ),
          const SizedBox(height: 12),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(data: gaussianVideoLabsRecipe, size: 230),
          ),
          const SizedBox(height: 12),
          const AppText(
            '4K / 30 fps / 5500K / ISO 100-200 / 45-degree shutter (1/240 s) / high bitrate / stabilization off. Select Linear in the app. Use good lighting.',
          ),
          const SizedBox(height: 8),
          const AppText(
            'QR acceptance and Protune values are not verified over BLE. Keep the configured Video preset active on each camera.',
            style: TextStyle(color: Colors.orange),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const AppText('Close'),
      ),
    ],
  ),
);
