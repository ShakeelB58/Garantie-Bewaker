import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/user_message.dart';
import '../application/document_service.dart';
import '../data/camera_scanner.dart';
import '../data/document_picker.dart';

/// Camera in de app met een kader voor de bon.
final cameraScannerProvider = Provider<CameraScanner>(
  (ref) => InAppCameraScanner(),
);

/// Beschikbare camera's. In tests vervangen (daar is geen camera).
final availableCamerasProvider =
    Provider<Future<List<CameraDescription>> Function()>(
      (ref) => availableCameras,
    );

class InAppCameraScanner implements CameraScanner {
  @override
  Future<ScanResult?> scan(NavigatorState navigator) =>
      navigator.push<ScanResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ScannerScreen(),
        ),
      );
}

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _problem;
  bool _busy = false;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // De camera moet vrijgegeven worden als de app op de achtergrond gaat.
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && controller == null) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await ref.read(availableCamerasProvider)();
      if (cameras.isEmpty) {
        _fail('Er is geen camera beschikbaar op dit toestel.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.veryHigh,
        // Geen microfoon: alleen foto's.
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(_flash);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _problem = null;
      });
    } on CameraException catch (e) {
      _fail(_messageFor(e));
    } catch (_) {
      _fail('De camera kon niet worden gestart.');
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _problem = message);
  }

  static String _messageFor(CameraException e) => switch (e.code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' =>
      'Bonvrij heeft geen toegang tot de camera. Je kunt dit aanzetten in de '
          'instellingen van je telefoon, of een foto uit je fotobibliotheek '
          'kiezen.',
    _ => 'De camera kon niet worden gestart.',
  };

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy || !controller.value.isInitialized) {
      return;
    }
    setState(() => _busy = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<ScanResult>((
        file: PickedFile(path: photo.path, originalName: photo.name),
        fromGallery: false,
      ));
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('De foto kon niet worden gemaakt.')),
        );
      }
    }
  }

  Future<void> _fromGallery() async {
    final picker = ref.read(documentPickerProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await picker.pick(DocumentSource.gallery);
      if (file != null && navigator.mounted) {
        navigator.pop<ScanResult>((file: file, fromGallery: true));
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(userMessageFor(error))));
    }
  }

  Future<void> _toggleFlash() async {
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    try {
      await _controller?.setFlashMode(next);
      setState(() => _flash = next);
    } catch (_) {
      // Sommige toestellen hebben geen flitser; dan blijft het zoals het was.
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Kassabon scannen'),
        leading: IconButton(
          tooltip: 'Sluiten',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _problem != null
                  ? _Problem(message: _problem!, onGallery: _fromGallery)
                  : controller == null || !controller.value.isInitialized
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _Preview(controller: controller),
            ),
            _Controls(
              flash: _flash,
              canCapture: controller != null && !_busy && _problem == null,
              onGallery: _fromGallery,
              onCapture: _capture,
              onFlash: controller == null ? null : _toggleFlash,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: CameraPreview(controller)),
        const IgnorePointer(child: CustomPaint(painter: _FramePainter())),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: Text(
            'Leg de bon plat neer en houd hem binnen het kader.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              shadows: const [Shadow(blurRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hoeken van het kader rond de bon.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.78,
      height: size.height * 0.78,
    );
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 32.0;
    final corners = [
      (rect.topLeft, const Offset(len, 0), const Offset(0, len)),
      (rect.topRight, const Offset(-len, 0), const Offset(0, len)),
      (rect.bottomLeft, const Offset(len, 0), const Offset(0, -len)),
      (rect.bottomRight, const Offset(-len, 0), const Offset(0, -len)),
    ];
    for (final (point, h, v) in corners) {
      canvas
        ..drawLine(point, point + h, paint)
        ..drawLine(point, point + v, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.flash,
    required this.canCapture,
    required this.onGallery,
    required this.onCapture,
    required this.onFlash,
  });

  final FlashMode flash;
  final bool canCapture;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback? onFlash;

  @override
  Widget build(BuildContext context) {
    final (flashIcon, flashLabel) = switch (flash) {
      FlashMode.auto => (Icons.flash_auto, 'Flitser: automatisch'),
      FlashMode.always => (Icons.flash_on, 'Flitser: aan'),
      _ => (Icons.flash_off, 'Flitser: uit'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            tooltip: 'Kiezen uit foto\'s',
            iconSize: 30,
            color: Colors.white,
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: onGallery,
          ),
          Semantics(
            button: true,
            label: 'Foto maken',
            child: GestureDetector(
              onTap: canCapture ? onCapture : null,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.teal, width: 5),
                ),
                padding: const EdgeInsets.all(5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canCapture ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: flashLabel,
            iconSize: 30,
            color: Colors.white,
            disabledColor: Colors.white38,
            icon: Icon(flashIcon),
            onPressed: onFlash,
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onGallery});

  final String message;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Kiezen uit foto\'s'),
            ),
          ],
        ),
      ),
    );
  }
}
