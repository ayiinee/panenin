import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panenin/app/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';

typedef CameraInitializer = Future<CameraController> Function();

class QuickSellCameraScreen extends StatefulWidget {
  const QuickSellCameraScreen({this.initializeCamera, super.key});

  final CameraInitializer? initializeCamera;

  @override
  State<QuickSellCameraScreen> createState() => _QuickSellCameraScreenState();
}

class _QuickSellCameraScreenState extends State<QuickSellCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _error;
  bool _initializing = false;
  bool _takingPicture = false;
  bool _flashEnabled = false;
  bool _cameraPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraPaused = true;
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _cameraPaused = false;
      _initializeCamera();
    }
  }

  Future<CameraController> _createCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'Kamera tidak ditemukan.');
    }

    final camera = cameras.firstWhere(
      (item) => item.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    await controller.setFlashMode(FlashMode.off);
    return controller;
  }

  Future<void> _initializeCamera() async {
    if (_initializing || _cameraPaused) return;

    _initializing = true;
    _error = null;
    if (mounted) setState(() {});

    try {
      final controller = await (widget.initializeCamera ?? _createCamera)();
      if (!mounted || _cameraPaused) {
        await controller.dispose();
        return;
      }
      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _flashEnabled = false;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _initializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _disposeCamera() async {
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final enabled = !_flashEnabled;
    try {
      await controller.setFlashMode(enabled ? FlashMode.always : FlashMode.off);
      if (mounted) setState(() => _flashEnabled = enabled);
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash tidak tersedia pada kamera ini.')),
      );
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _takingPicture) {
      return;
    }

    setState(() => _takingPicture = true);
    try {
      final photo = await controller.takePicture();
      final savedPath = await _persistPhoto(photo);
      if (mounted) Navigator.of(context).pop<String>(savedPath);
    } on Object {
      if (!mounted) return;
      setState(() => _takingPicture = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto gagal diambil. Silakan coba lagi.')),
      );
    }
  }

  Future<String> _persistPhoto(XFile photo) async {
    final documents = await getApplicationDocumentsDirectory();
    final photos = Directory(
      '${documents.path}${Platform.pathSeparator}stock_photos',
    );
    await photos.create(recursive: true);
    final savedPath =
        '${photos.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}.jpg';
    await photo.saveTo(savedPath);
    return savedPath;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final cameraReady = _controller?.value.isInitialized ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ColoredBox(
          color: Colors.white,
          child: Column(
            children: [
              const SafeArea(bottom: false, child: _CameraHeader()),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cameraSize = math.min(
                      constraints.maxWidth,
                      math.max(0.0, constraints.maxHeight - 120),
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox.square(
                            key: const ValueKey('camera-square-preview'),
                            dimension: cameraSize,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _CameraView(
                                  controller: _controller,
                                  error: _error,
                                  initializing: _initializing,
                                  onRetry: _initializeCamera,
                                ),
                                if (cameraReady) const _FocusFrame(),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: cameraSize - 50,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _CaptureButton(
                              enabled: cameraReady && !_takingPicture,
                              loading: _takingPicture,
                              onPressed: _takePicture,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 58,
                          bottom: 28 + bottomPadding,
                          child: _FlashButton(
                            enabled: cameraReady,
                            active: _flashEnabled,
                            onPressed: _toggleFlash,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraHeader extends StatelessWidget {
  const _CameraHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 115,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Foto Produk Anda!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Positioned(
            left: 8,
            child: IconButton(
              key: const ValueKey('camera-back'),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Kembali',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size.square(48),
                maximumSize: const Size.square(48),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.controller,
    required this.error,
    required this.initializing,
    required this.onRetry,
  });

  final CameraController? controller;
  final Object? error;
  final bool initializing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(
                  _cameraErrorMessage(error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  key: const ValueKey('retry-camera'),
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (initializing ||
        controller == null ||
        !controller!.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final previewSize = controller!.value.previewSize!;
    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }
}

class _FocusFrame extends StatelessWidget {
  const _FocusFrame();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(280.0, constraints.maxWidth - 72);
        return Center(
          child: CustomPaint(
            size: Size.square(size),
            painter: _FocusFramePainter(),
          ),
        );
      },
    );
  }
}

class _FocusFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const corner = 38.0;
    final framePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 10)
      ..quadraticBezierTo(0, 0, 10, 0)
      ..lineTo(corner, 0)
      ..moveTo(size.width - corner, 0)
      ..lineTo(size.width - 10, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 10)
      ..lineTo(size.width, corner)
      ..moveTo(size.width, size.height - corner)
      ..lineTo(size.width, size.height - 10)
      ..quadraticBezierTo(size.width, size.height, size.width - 10, size.height)
      ..lineTo(size.width - corner, size.height)
      ..moveTo(corner, size.height)
      ..lineTo(10, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 10)
      ..lineTo(0, size.height - corner);
    canvas.drawPath(path, framePaint);

    final scanPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      scanPaint,
    );

    final focusPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 13, focusPaint);
    canvas.drawLine(
      center - const Offset(8, 0),
      center + const Offset(8, 0),
      focusPaint,
    );
    canvas.drawLine(
      center - const Offset(0, 8),
      center + const Offset(0, 8),
      focusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ambil foto',
      child: SizedBox.square(
        dimension: 100,
        child: FilledButton(
          key: const ValueKey('take-picture'),
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledForegroundColor: Color(0xB3FFFFFF),
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 4),
            ),
            elevation: 8,
            shadowColor: const Color(0x59000000),
          ),
          child: loading
              ? const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.camera_alt_rounded, size: 48),
        ),
      ),
    );
  }
}

class _FlashButton extends StatelessWidget {
  const _FlashButton({
    required this.enabled,
    required this.active,
    required this.onPressed,
  });

  final bool enabled;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 53,
          child: IconButton(
            key: const ValueKey('toggle-flash'),
            onPressed: enabled ? onPressed : null,
            tooltip: active ? 'Matikan flash' : 'Nyalakan flash',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: const Color(0xFF6B7280),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFF4B5563)),
              ),
            ),
            icon: Icon(
              active ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Flash',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _cameraErrorMessage(Object error) {
  if (error is CameraException) {
    return switch (error.code) {
      'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' =>
        'Izin kamera diperlukan untuk memotret produk.',
      'CameraAccessRestricted' =>
        'Akses kamera dibatasi oleh pengaturan perangkat.',
      'NoCamera' => 'Kamera tidak ditemukan pada perangkat ini.',
      _ => 'Kamera tidak dapat dibuka. Silakan coba lagi.',
    };
  }
  return 'Kamera tidak dapat dibuka. Silakan coba lagi.';
}
