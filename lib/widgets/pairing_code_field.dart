import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/pairing_code.dart';

/// The 6-character pairing code entry: one cell per character, backed by a
/// single invisible text field so the system keyboard, paste and autofill all
/// behave exactly as they would on a normal input.
class PairingCodeField extends StatefulWidget {
  const PairingCodeField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = false,
  });

  final TextEditingController controller;

  /// Fires once the sixth character lands — the code is ready to redeem.
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  final bool enabled;

  /// Tints the cells when the last attempt was rejected.
  final bool hasError;
  final bool autofocus;

  @override
  State<PairingCodeField> createState() => _PairingCodeFieldState();
}

class _PairingCodeFieldState extends State<PairingCodeField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  String _lastValue = '';

  void _onTextChanged() {
    final value = widget.controller.text;
    if (value == _lastValue) return;
    _lastValue = value;

    setState(() {});
    widget.onChanged?.call(value);

    if (value.length == PairingCode.length) {
      _focus.unfocus();
      widget.onCompleted(value);
    }
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;

    return Semantics(
      label: 'Pairing code, ${PairingCode.length} characters',
      textField: true,
      child: Stack(
        children: [
          Row(
            children: List.generate(PairingCode.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == PairingCode.length - 1 ? 0 : 8,
                  ),
                  child: _Cell(
                    character: index < code.length ? code[index] : '',
                    // The next empty cell is where typing lands.
                    active: _focus.hasFocus && index == code.length,
                    hasError: widget.hasError,
                  ),
                ),
              );
            }),
          ),
          // Invisible, but full-size: taps anywhere on the cells open the
          // keyboard, and the caret/selection UI never shows through.
          Positioned.fill(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              showCursor: false,
              cursorWidth: 0,
              enableInteractiveSelection: false,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: PairingCode.length,
              style: const TextStyle(color: Colors.transparent, height: 0.1),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(PairingCode.length),
                _UpperCaseFormatter(),
              ],
              onSubmitted: (value) {
                if (value.length == PairingCode.length) {
                  widget.onCompleted(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single character cell. Empty, filled and active each read differently at a
/// glance so the member always knows where they are in the code.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.character,
    required this.active,
    required this.hasError,
  });

  final String character;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = character.isNotEmpty;

    final Color border = hasError
        ? AppColors.red.withValues(alpha: 0.7)
        : active
            ? AppColors.lime
            : filled
                ? AppColors.cream.withValues(alpha: 0.34)
                : AppColors.lineDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: active ? 0.09 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: active || filled ? 1.6 : 1),
      ),
      child: filled
          ? Text(
              character,
              style: AppType.heading(color: AppColors.white).copyWith(
                fontSize: 24,
                letterSpacing: 0,
              ),
            )
          : _Placeholder(active: active),
    );
  }
}

/// A dash in an empty cell; the active cell gets a lime caret instead.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: active ? 2 : 12,
      height: active ? 24 : 2,
      decoration: BoxDecoration(
        color: active ? AppColors.lime : AppColors.subtleOnDark,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
