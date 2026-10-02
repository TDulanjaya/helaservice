import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

class SlideToConfirm extends StatefulWidget {
  final String label;
  final String? confirmedLabel;
  final VoidCallback onConfirmed;

  const SlideToConfirm({
    super.key,
    required this.label,
    this.confirmedLabel,
    required this.onConfirmed,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dragX = 0;
  bool _confirmed = false;
  static const _knobSize = 50.0;
  static const _trackHeight = 58.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _knobSize - 8;
        return Container(
          height: _trackHeight,
          decoration: BoxDecoration(
            color: _confirmed
                ? context.themeSuccessTint
                : context.themeAmberTint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _confirmed
                  ? context.themeSuccess.withValues(alpha: 0.3)
                  : context.themeBorder,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _confirmed ? 1.0 : (1.0 - (_dragX / maxDrag)).clamp(0.0, 1.0),
                  child: Text(
                    _confirmed
                        ? (widget.confirmedLabel ??
                            context.l10n.arrivalConfirmed)
                        : widget.label,
                    style: TextStyle(
                      color: _confirmed
                          ? context.themeSuccess
                          : context.themeAmberText,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragX,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_confirmed) return;
                    setState(() {
                      _dragX = (_dragX + details.delta.dx).clamp(0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_confirmed) return;
                    if (_dragX >= maxDrag * 0.8) {
                      setState(() {
                        _dragX = maxDrag;
                        _confirmed = true;
                      });
                      widget.onConfirmed();
                    } else {
                      setState(() => _dragX = 0);
                    }
                  },
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: BoxDecoration(
                      color: _confirmed ? context.themeSuccess : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _confirmed ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      color: _confirmed ? Colors.white : AppColors.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

