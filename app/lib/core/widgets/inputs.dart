import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../motion/motion.dart';

/// Search box with debounced input (no request per keystroke) and a clear
/// button. Owns and disposes its timer.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onQuery,
    this.controller,
    this.debounce = const Duration(milliseconds: 250),
    this.autofocus = false,
  });

  final String hint;
  final ValueChanged<String> onQuery;
  final TextEditingController? controller;
  final Duration debounce;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  Timer? _timer;

  void _changed(String value) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onQuery(value.trim()));
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    setState(() {});
    widget.onQuery('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: _changed,
      onSubmitted: (v) {
        _timer?.cancel();
        widget.onQuery(v.trim());
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: _clear,
              ),
      ),
    );
  }
}

/// − [qty] + with large touch targets. Quantity is whole pieces within
/// [min]..[max]; the server validates again.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100000,
    required this.decreaseLabel,
    required this.increaseLabel,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String decreaseLabel;
  final String increaseLabel;

  void _set(int next) {
    final clamped = next.clamp(min, max);
    if (clamped != value) {
      unawaited(HapticFeedback.selectionClick());
      onChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget button(IconData icon, String label, VoidCallback? onTap) => IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(kMinTouchTarget),
        backgroundColor: AppColors.surfaceMuted,
        disabledBackgroundColor: AppColors.surfaceMuted.withValues(alpha: 0.5),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove_rounded, decreaseLabel, value > min ? () => _set(value - 1) : null),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56),
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.instant),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: text.titleLarge!.copyWith(fontFeatures: AppType.figures),
            ),
          ),
        ),
        button(Icons.add_rounded, increaseLabel, value < max ? () => _set(value + 1) : null),
      ],
    );
  }
}
