import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SlideToConfirm extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;

  const SlideToConfirm(
      {super.key, required this.label, required this.onConfirmed});

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dragX = 0;
  bool _confirmed = false;
  static const _knobSize = 52.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _knobSize - 8;
        return Container(
          height: _knobSize + 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  _confirmed ? 'Arrival Confirmed' : widget.label,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
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
                    if (_dragX >= maxDrag * 0.85) {
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
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.double_arrow, color: Colors.white),
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
