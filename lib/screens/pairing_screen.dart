import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/pairing_code.dart';
import '../providers/connection_provider.dart';
import '../widgets/app_eyebrow.dart';
import '../widgets/pairing_code_field.dart';
import '../widgets/pl_button.dart';
import '../widgets/pl_logo.dart';
import '../widgets/pl_scaffold.dart';
import 'qr_scanner_screen.dart';

/// Screen 00 — Pairing. Shown when the app doesn't know which Personally
/// account it is connecting: a fresh install loses the deep link's `ref` on the
/// way through the App Store, so the member scans the QR on the website or
/// types the short code printed beside it.
///
/// Both paths end the same way: a reference id, and the welcome screen.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    FocusScope.of(context).unfocus();
    final scanned = await QrScannerScreen.open(context);
    if (scanned == null || !mounted) return;
    await context.read<ConnectionProvider>().submitScannedCode(scanned);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await context.read<ConnectionProvider>().submitPairingCode(_code.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();
    final complete = PairingCode.isComplete(_code.text);

    return PlScaffold(
      ground: PlGround.dark,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Align(alignment: Alignment.centerLeft, child: PlLogo.small()),
            const SizedBox(height: 40),
            const AppEyebrow('Pair your account', onDark: true),
            const SizedBox(height: 16),
            Text('Connect this\napp to you', style: AppType.display()),
            const SizedBox(height: 16),
            Text(
              'Open your formula on personally.com and tap Connect Apple '
              'Health. Scan the code it shows, or type it in below.',
              style: AppType.body(color: AppColors.mutedOnDark),
            ),
            const SizedBox(height: 28),
            PlButton(
              label: 'Scan QR code',
              style: PlButtonStyle.lime,
              onPressed: provider.isPairing ? null : _scan,
            ),
            const SizedBox(height: 26),
            const _OrDivider(),
            const SizedBox(height: 22),
            Text(
              'Enter your ${PairingCode.length}-character code',
              style: AppType.label(color: AppColors.mutedOnDark),
            ),
            const SizedBox(height: 12),
            PairingCodeField(
              controller: _code,
              enabled: !provider.isPairing,
              hasError: provider.pairingError != null,
              onChanged: (_) {
                context.read<ConnectionProvider>().clearPairingError();
                setState(() {});
              },
              // Typing the sixth character is the member saying "go".
              onCompleted: (_) => _submit(),
            ),
            _PairingError(message: provider.pairingError),
            const SizedBox(height: 20),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: complete || provider.isPairing ? 1 : 0.42,
              child: PlButton(
                label: 'Pair this app',
                style: PlButtonStyle.solid,
                onDark: true,
                busy: provider.isPairing,
                onPressed: complete && !provider.isPairing ? _submit : null,
              ),
            ),
            const SizedBox(height: 4),
            PlButton(
              label: 'I don’t have a code',
              style: PlButtonStyle.ghost,
              onDark: true,
              onPressed: () => context.read<ConnectionProvider>().goToFunnel(),
            ),
            const SizedBox(height: 8),
            Text(
              'Codes last 30 minutes and work once.',
              textAlign: TextAlign.center,
              style: AppType.label(color: AppColors.subtleOnDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// A hairline rule with "or" set into it.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.lineDark),
    );

    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: AppType.eyebrow(color: AppColors.subtleOnDark),
          ),
        ),
        line,
      ],
    );
  }
}

/// The reason the last attempt was rejected — the endpoint's own wording, which
/// already distinguishes "not valid" from "used" and "expired".
class _PairingError extends StatelessWidget {
  const _PairingError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1, right: 8),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppColors.redLight,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      message!,
                      style: AppType.body(
                        color: AppColors.redLight,
                      ).copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
