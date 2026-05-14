import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tattoo/i18n/strings.g.dart';

class CameraSwitchButton extends StatelessWidget {
  const CameraSwitchButton({
    super.key,
    required this.controller,
    required this.isSwitching,
    required this.onPressed,
  });

  final MobileScannerController controller;
  final bool isSwitching;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final availableCameras = state.availableCameras;
        final hasMultipleCameras =
            availableCameras == null || availableCameras > 1;
        final canSwitch =
            state.isInitialized &&
            state.isRunning &&
            hasMultipleCameras &&
            !isSwitching &&
            state.cameraDirection != .unknown &&
            state.cameraDirection != .external;
        final icon = switch (state.cameraDirection) {
          .front => Icons.camera_front_outlined,
          .back => Icons.camera_rear_outlined,
          _ => Icons.cameraswitch_outlined,
        };

        return Tooltip(
          message: t.scanner.switchCamera,
          child: IconButton.filledTonal(
            onPressed: canSwitch ? onPressed : null,
            icon: Icon(icon),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withAlpha(160),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black.withAlpha(80),
              disabledForegroundColor: Colors.white.withAlpha(120),
            ),
          ),
        );
      },
    );
  }
}
