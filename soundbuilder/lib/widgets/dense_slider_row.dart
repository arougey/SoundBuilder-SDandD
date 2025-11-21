// lib/widgets/dense_slider_row.dart
import 'package:flutter/material.dart';

class DenseSliderRow extends StatelessWidget {
  final IconData icon;
  final double value;           // <— current real value
  final double min;
  final double max;
  final double center;          // logical "zero" point in [min, max]
  final ValueChanged<double> onChanged;

  const DenseSliderRow({
    super.key,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.center,
    required this.onChanged,
  });

  // Map real -> UI [-1..+1], where 0 == center
  static double _toUi(double v, double min, double max, double center) {
    final left = center - min;
    final right = max - center;
    if (v >= center) {
      return right == 0 ? 0 : (v - center) / right;     // 0..+1
    } else {
      return left == 0 ? 0 : (v - center) / left;       // -1..0
    }
  }

  // Map UI [-1..+1] -> real
  static double _fromUi(double u, double min, double max, double center) {
    final left = center - min;
    final right = max - center;
    if (u >= 0) {
      return right == 0 ? center : center + u * right;
    } else {
      return left == 0 ? center : center + u * left;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 2,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
    );

    final uiValue = _toUi(value, min, max, center);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [ Icon(icon, size: 20) ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: sliderTheme,
            child: Slider(
              min: -1.0,
              max:  1.0,
              value: uiValue.clamp(-1.0, 1.0),
              onChanged: (u) {
                final real = _fromUi(u, min, max, center).clamp(min, max);
                onChanged(real);
              },
            ),
          ),
        ),
      ],
    );
  }
}