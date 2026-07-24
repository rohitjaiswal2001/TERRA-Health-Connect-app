import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/app_logger.dart';
import '../models/pairing_payload.dart';
import '../services/redirect_service.dart';
import '../widgets/pl_button.dart';

/// Full-screen QR reader for the code the website shows next to the quiz's
/// "Connect Apple Health" step.
///
/// Pops with the raw scanned value (the caller decides what to do with it), or
/// with `null` if the member backs out. It only ever accepts a value the app
/// can actually act on — anything else keeps the camera running and says so,
/// rather than dumping the member back with a cryptic error.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  /// Opens the scanner and resolves to the scanned value, or `null`.
  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const QrScannerScreen(),
      ),
    );
  }

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  static const String _scope = 'Scanner';

  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  /// Guards against a second detection arriving while we're popping.
  bool _handled = false;

  /// Shown when a barcode is read but isn't one of ours.
  String? _hint;

  @override
  void initState() {
    super.initState();
    // The camera state is the thing that goes wrong on a device, and it goes
    // wrong silently (a black preview), so trace every transition.
    _controller.addListener(_logCameraState);
  }

  void _logCameraState() {
    final state = _controller.value;
    final error = state.error;
    if (error != null) {
      AppLog.fail(
        _scope,
        'camera error → ${error.errorCode.name}: '
        '${error.errorDetails?.message ?? error.errorCode.message}',
      );
      return;
    }
    AppLog.step(
      _scope,
      'camera → running=${state.isRunning}, initialized=${state.isInitialized}, '
      'torch=${state.torchState.name}',
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_logCameraState);
    _sweep.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;

      if (PairingPayload.parse(raw) == null) {
        AppLog.warn(_scope, 'ignored a QR that is not a Personally code');
        setState(() => _hint = 'That isn’t a Personally code. Try the one on '
            'personally.com.');
        continue;
      }

      _handled = true;
      AppLog.ok(_scope, 'captured a Personally code');
      HapticFeedback.mediumImpact();
      _stopCamera();
      Navigator.of(context).pop(raw);
      return;
    }
  }

  /// Fire and forget: the route is going away, we just want the camera off.
  void _stopCamera() {
    _controller.stop().catchError((Object e) {
      AppLog.warn(_scope, 'stopping the camera failed — $e');
    });
  }

  /// Ask for the camera again — after the member has turned it on in Settings,
  /// or when the first attempt failed for a transient reason.
  Future<void> _retry() async {
    AppLog.step(_scope, 'restarting the camera');
    try {
      await _controller.start();
    } catch (e) {
      AppLog.fail(_scope, 'restart failed — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final window = _scanWindow(constraints.biggest);

            return ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                // When the camera can't run, the framing overlay is noise on
                // top of an explanation — drop it and let the message speak.
                final failed = state.error != null;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Always mounted, in the same slot, so the controller stays
                    // attached and a retry can bring the preview back.
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      scanWindow: window,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error) => _CameraError(
                        error: error,
                        onRetry: _retry,
                      ),
                    ),
                    if (!failed) ...[
                      // Dim everything outside the window so the eye goes to it.
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _WindowPainter(window: window),
                          size: constraints.biggest,
                        ),
                      ),
                      IgnorePointer(
                        child: _Reticle(window: window, sweep: _sweep),
                      ),
                    ],
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          children: [
                            _TopBar(
                              controller: _controller,
                              onClose: () {
                                _stopCamera();
                                Navigator.of(context).pop();
                              },
                            ),
                            const Spacer(),
                            if (!failed) _Caption(hint: _hint, window: window),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// A square window, sized to the screen and sitting slightly above centre so
  /// the caption underneath stays clear of it.
  Rect _scanWindow(Size size) {
    final side = (size.width * 0.72).clamp(200.0, 320.0);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: side,
      height: side,
    );
  }
}

/// Close and torch controls, as circular glass buttons over the preview.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.onClose});

  final MobileScannerController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _GlassButton(
          icon: Icons.close_rounded,
          semanticLabel: 'Close the scanner',
          onTap: onClose,
        ),
        ValueListenableBuilder<MobileScannerState>(
          valueListenable: controller,
          builder: (context, state, _) {
            if (state.torchState == TorchState.unavailable) {
              return const SizedBox(width: 44);
            }
            final on = state.torchState == TorchState.on;
            return _GlassButton(
              icon: on ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
              semanticLabel: on ? 'Turn the torch off' : 'Turn the torch on',
              highlighted: on,
              onTap: controller.toggleTorch,
            );
          },
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: highlighted
            ? AppColors.lime
            : AppColors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 21,
              color: highlighted ? AppColors.black : AppColors.cream,
            ),
          ),
        ),
      ),
    );
  }
}

/// Instructions under the window, plus the "not a Personally code" nudge and
/// the way back to typing the code by hand.
class _Caption extends StatelessWidget {
  const _Caption({required this.hint, required this.window});

  final String? hint;
  final Rect window;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Point at the code on screen',
          textAlign: TextAlign.center,
          style: AppType.heading(color: AppColors.white).copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          'Open personally.com on your computer and tap Connect Apple Health '
          'to bring up your code.',
          textAlign: TextAlign.center,
          style: AppType.body(color: AppColors.mutedOnDark),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: hint == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hint!,
                      textAlign: TextAlign.center,
                      style: AppType.label(color: AppColors.redLight),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Enter the code instead',
            style: AppType.button(color: AppColors.cream).copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}

/// The lime corner brackets and the sweeping scan line inside the window.
class _Reticle extends StatelessWidget {
  const _Reticle({required this.window, required this.sweep});

  final Rect window;
  final Animation<double> sweep;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fromRect(
          rect: window,
          child: CustomPaint(painter: _CornersPainter()),
        ),
        Positioned.fromRect(
          rect: window.deflate(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedBuilder(
              animation: sweep,
              builder: (context, _) {
                return Align(
                  alignment: Alignment(0, sweep.value * 2 - 1),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.lime.withValues(alpha: 0),
                          AppColors.lime.withValues(alpha: 0.9),
                          AppColors.lime.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints the scrim with the scan window punched out of it.
class _WindowPainter extends CustomPainter {
  const _WindowPainter({required this.window});

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(window, const Radius.circular(28)));

    canvas.drawPath(
      Path.combine(PathOperation.difference, scrim, hole),
      Paint()..color = AppColors.black.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(_WindowPainter oldDelegate) => oldDelegate.window != window;
}

/// Four lime corner brackets — the frame, without a full box around the code.
class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const arm = 30.0;
    const radius = 28.0;

    final paint = Paint()
      ..color = AppColors.lime
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final path = Path()
      // Top-left
      ..moveTo(rect.left, rect.top + radius + arm)
      ..lineTo(rect.left, rect.top + radius)
      ..arcToPoint(
        Offset(rect.left + radius, rect.top),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left + radius + arm, rect.top)
      // Top-right
      ..moveTo(rect.right - radius - arm, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right, rect.top + radius + arm)
      // Bottom-right
      ..moveTo(rect.right, rect.bottom - radius - arm)
      ..lineTo(rect.right, rect.bottom - radius)
      ..arcToPoint(
        Offset(rect.right - radius, rect.bottom),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.right - radius - arm, rect.bottom)
      // Bottom-left
      ..moveTo(rect.left + radius + arm, rect.bottom)
      ..lineTo(rect.left + radius, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - radius),
        radius: const Radius.circular(radius),
      )
      ..lineTo(rect.left, rect.bottom - radius - arm);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}

/// The camera couldn't run. Names the actual reason — a denied permission, a
/// simulator with no camera, a build that never got the plugin — and always
/// leaves the typed-code path one tap away.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  bool get _denied =>
      error.errorCode == MobileScannerErrorCode.permissionDenied;

  /// No camera hardware — the iOS Simulator, essentially always.
  bool get _unsupported =>
      error.errorCode == MobileScannerErrorCode.unsupported;

  String get _title => switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied => 'Camera access is off',
        MobileScannerErrorCode.unsupported => 'No camera on this device',
        _ => 'The camera didn’t start',
      };

  String get _body => switch (error.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'Turn the camera on for Personally in Settings, then try again — or '
              'type your code instead.',
        MobileScannerErrorCode.unsupported =>
          'The Simulator has no camera. Run on a real iPhone to scan, or type '
              'the 6-character code instead.',
        _ => 'You can try again, or type the 6-character code from the website '
            'instead.',
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.mutedOnDark,
              size: 34,
            ),
            const SizedBox(height: 18),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: AppType.heading(color: AppColors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _body,
              textAlign: TextAlign.center,
              style: AppType.body(color: AppColors.mutedOnDark),
            ),
            const SizedBox(height: 28),
            if (_denied)
              PlButton(
                label: 'Open Settings',
                style: PlButtonStyle.solid,
                onDark: true,
                onPressed: () => const RedirectService().openAppSettings(),
              )
            else if (!_unsupported)
              PlButton(
                label: 'Try again',
                style: PlButtonStyle.solid,
                onDark: true,
                onPressed: onRetry,
              ),
            const SizedBox(height: 4),
            PlButton(
              label: 'Enter the code instead',
              style: PlButtonStyle.ghost,
              onDark: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            // The exact failure, for the Xcode console and for us — never the
            // member's problem to decode, but it's what makes this debuggable.
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              Text(
                '${error.errorCode.name} · '
                '${error.errorDetails?.message ?? error.errorCode.message}',
                textAlign: TextAlign.center,
                style: AppType.label(color: AppColors.subtleOnDark)
                    .copyWith(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
