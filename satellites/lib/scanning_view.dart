import 'dart:async';

import 'package:flutter/material.dart';
// TODO: Ensure quality of scans when running (pretty good until now)
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:mobile_scanner_example/scanner_error_widget.dart';
import 'package:vibration/vibration.dart';

class ScanningView extends StatefulWidget {
  final int stationID;

  const ScanningView({super.key, required this.stationID});

  @override
  State<ScanningView> createState() => _ScanningViewState();
}

class _ScanningViewState extends State<ScanningView>
    with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.unrestricted,
    useNewCameraSelector: true,
    formats: [BarcodeFormat.qrCode],
  );

  StreamSubscription<Object?>? _subscription;

  final Map<String, DateTime> _scannedBarcodes = {};
  final List<Map<String, dynamic>> _barcodeBuffer = [];

  Timer? _timer;

  bool _displayPreview = true;
  bool _hasVibrator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _subscription = controller.barcodes.listen(_handleBarcode);
    unawaited(controller.start());

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _removeOldCodes();
    });

    Vibration.hasVibrator().then((val) {_hasVibrator = true;});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(_handleBarcode);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
         _displayPreview = !_displayPreview;
        });
      },
      child: Stack(
        children: [
            _displayPreview
              ? MobileScanner(
                  controller: controller,
                  errorBuilder: (ctx, err, chld) {
                    return Text(err.errorDetails!.message!);
                  },
                  fit: BoxFit.contain,
                )
              : Container(),
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture capt) {

    if (_hasVibrator) {
      Vibration.vibrate(duration: 10);
    }

    final currentTime = DateTime.now();
    for (var barcode in capt.barcodes) {
      print("Found Barcode: ${barcode.displayValue}");
      if (!_scannedBarcodes.containsKey(barcode.displayValue!)) {
        _barcodeBuffer.add({
          'runner_id': barcode.displayValue!,
          'station_id': widget.stationID,
          'timestamp': currentTime.toIso8601String()
        });
      }
      _scannedBarcodes.addEntries({barcode.displayValue!: currentTime}.entries);
    }
  }

  void _removeOldCodes() {
    _sendBufferedBarcodes();
    final currentTime = DateTime.now();
    _scannedBarcodes.removeWhere(
        (key, value) => currentTime.difference(value).inSeconds > 30);
    for (var barcode in _scannedBarcodes.entries) {
      print('${barcode.key}: ${barcode.value}');
    }
  }

  void _sendBufferedBarcodes() {
    // TODO: Add some sort of redundancy
      final future = Supabase.instance.client
          .from("runner_logs")
          .insert(_barcodeBuffer)
          .select();

      future.whenComplete(() {
        print("Buffered barcodes sent");
        _barcodeBuffer.clear();
      });
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    _timer?.cancel();
    await controller.dispose();
  }
}
