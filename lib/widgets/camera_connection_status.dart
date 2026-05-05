import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gopro_service.dart';

class CameraConnectionStatus extends StatelessWidget {
  const CameraConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final goPro = context.watch<GoProService>();
    final connectedCount = goPro.devices.where((d) => d.isConnected).length;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: connectedCount > 0 ? primaryColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: connectedCount > 0 ? primaryColor.withValues(alpha: 0.5) : Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 14, color: connectedCount > 0 ? primaryColor : Colors.white54),
              const SizedBox(width: 4),
              Text(
                '$connectedCount',
                style: TextStyle(
                  color: connectedCount > 0 ? primaryColor : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
