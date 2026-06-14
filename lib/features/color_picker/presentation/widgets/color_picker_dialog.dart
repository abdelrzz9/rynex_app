import 'dart:math';
import 'package:flutter/material.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  static Future<Color?> show(BuildContext context, Color initialColor) {
    return showDialog<Color>(
      context: context,
      builder: (ctx) => ColorPickerDialog(
        initialColor: initialColor,
        onColorChanged: (_) {},
      ),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _brightness;
  late double _alpha;

  @override
  void initState() {
    super.initState();
    final hsb = _rgbToHsb(widget.initialColor);
    _hue = hsb[0];
    _saturation = hsb[1];
    _brightness = hsb[2];
    _alpha = widget.initialColor.opacity;
  }

  Color get _currentColor => HSLColor.fromAHSL(_alpha, _hue, _saturation, _brightness).toColor();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);

    return AlertDialog(
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorWheel(),
              const SizedBox(height: 16),
              _buildBrightnessSlider(),
              const SizedBox(height: 12),
              _buildAlphaSlider(),
              const SizedBox(height: 16),
              _buildHexInput(),
              const SizedBox(height: 12),
              _buildPresetColors(),
              const SizedBox(height: 16),
              _buildPreview(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onColorChanged(_currentColor);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildColorWheel() {
    return SizedBox(
      width: 280,
      height: 280,
      child: ColorWheel(
        hue: _hue,
        saturation: _saturation,
        brightness: _brightness,
        onChanged: (hue, saturation) {
          setState(() {
            _hue = hue;
            _saturation = saturation;
          });
        },
      ),
    );
  }

  Widget _buildBrightnessSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Brightness', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        _GradientSlider(
          value: _brightness,
          colors: [
            HSLColor.fromAHSL(1, _hue, _saturation, 0).toColor(),
            HSLColor.fromAHSL(1, _hue, _saturation, 1).toColor(),
          ],
          onChanged: (v) => setState(() => _brightness = v),
        ),
      ],
    );
  }

  Widget _buildAlphaSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Opacity', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        _GradientSlider(
          value: _alpha,
          colors: [
            _currentColor.withValues(alpha: 0),
            _currentColor.withValues(alpha: 1),
          ],
          onChanged: (v) => setState(() => _alpha = v),
        ),
      ],
    );
  }

  Widget _buildHexInput() {
    final hex = _currentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    final controller = TextEditingController(text: '#$hex');
    return Row(
      children: [
        const Text('HEX', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onSubmitted: (value) {
              final hexStr = value.replaceAll('#', '');
              if (hexStr.length == 6) {
                final color = Color(int.parse('FF$hexStr', radix: 16));
                final hsb = _rgbToHsb(color);
                setState(() {
                  _hue = hsb[0];
                  _saturation = hsb[1];
                  _brightness = hsb[2];
                });
              }
            },
          ),
        ),
        const Spacer(),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetColors() {
    const presetColors = [
      Color(0xFFFFFFFF),
      Color(0xFFBDBDBD),
      Color(0xFF757575),
      Color(0xFF212121),
      Color(0xFF000000),
      Color(0xFFF44336),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF673AB7),
      Color(0xFF3F51B5),
      Color(0xFF2196F3),
      Color(0xFF03A9F4),
      Color(0xFF00BCD4),
      Color(0xFF009688),
      Color(0xFF4CAF50),
      Color(0xFF8BC34A),
      Color(0xFFCDDC39),
      Color(0xFFFFEB3B),
      Color(0xFFFFC107),
      Color(0xFFFF9800),
      Color(0xFFFF5722),
      Color(0xFF795548),
      Color(0xFF9E9E9E),
      Color(0xFF607D8B),
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: presetColors.map((color) {
        final isSelected = _currentColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () {
            final hsb = _rgbToHsb(color);
            setState(() {
              _hue = hsb[0];
              _saturation = hsb[1];
              _brightness = hsb[2];
            });
          },
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade400,
                width: isSelected ? 2 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        color: _currentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
    );
  }

  static List<double> _rgbToHsb(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;

    final maxVal = [r, g, b].reduce(_max);
    final minVal = [r, g, b].reduce(_min);
    final delta = maxVal - minVal;

    var hueVal = 0.0;
    if (delta > 0) {
      if (maxVal == r) {
        hueVal = 60.0 * (((g - b) / delta) % 6);
      } else if (maxVal == g) {
        hueVal = 60.0 * (((b - r) / delta) + 2);
      } else {
        hueVal = 60.0 * (((r - g) / delta) + 4);
      }
    }
    if (hueVal < 0) hueVal += 360.0;

    final saturationVal = maxVal == 0 ? 0.0 : (delta / maxVal);
    final brightnessVal = maxVal;

    return [hueVal.toDouble(), saturationVal.toDouble(), brightnessVal.toDouble()];
  }

  static double _max(double a, double b) => a > b ? a : b;
  static double _min(double a, double b) => a < b ? a : b;
}

class ColorWheel extends StatelessWidget {
  final double hue;
  final double saturation;
  final double brightness;
  final void Function(double hue, double saturation) onChanged;

  const ColorWheel({
    super.key,
    required this.hue,
    required this.saturation,
    required this.brightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return GestureDetector(
          onPanDown: (d) => _updateColor(d.localPosition, size),
          onPanUpdate: (d) => _updateColor(d.localPosition, size),
          child: CustomPaint(
            size: Size(size, size),
            painter: _ColorWheelPainter(
              hue: hue,
              saturation: saturation,
              brightness: brightness,
            ),
          ),
        );
      },
    );
  }

  void _updateColor(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > radius) return;

    final angle = atan2(dy, dx);
    var h = (angle * 180 / pi + 360) % 360;
    final s = distance / radius;

    h = h.clamp(0, 360).toDouble();
    onChanged(h, s.clamp(0, 1));
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double brightness;

  _ColorWheelPainter({
    required this.hue,
    required this.saturation,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final outerRadius = radius;
    final innerRadius = radius * 0.15;

    // Draw color wheel
    for (var angle = 0; angle < 360; angle += 1) {
      final rad = angle * pi / 180;
      final nextRad = (angle + 1) * pi / 180;

      final path = Path();
      path.moveTo(
        center.dx + innerRadius * cos(rad),
        center.dy + innerRadius * sin(rad),
      );
      path.lineTo(
        center.dx + outerRadius * cos(rad),
        center.dy + outerRadius * sin(rad),
      );
      path.lineTo(
        center.dx + outerRadius * cos(nextRad),
        center.dy + outerRadius * sin(nextRad),
      );
      path.lineTo(
        center.dx + innerRadius * cos(nextRad),
        center.dy + innerRadius * sin(nextRad),
      );
      path.close();

      final color = HSLColor.fromAHSL(1, angle.toDouble(), 1, 0.5).toColor();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Draw saturation/brightness overlay
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: brightness),
          Colors.transparent,
        ],
        center: Alignment.center,
        radius: 1,
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawCircle(center, outerRadius, gradientPaint);

    final darkPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.5),
        ],
        center: Alignment.center,
        radius: 1,
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawCircle(center, outerRadius, darkPaint);

    // Draw selector handle
    final handleAngle = hue * pi / 180;
    final handleDistance = saturation * outerRadius;
    final handlePos = Offset(
      center.dx + handleDistance * cos(handleAngle),
      center.dy + handleDistance * sin(handleAngle),
    );

    final handleColor = HSLColor.fromAHSL(1, hue, saturation, brightness).toColor();
    final luminance = handleColor.computeLuminance();
    final borderColor = luminance > 0.5 ? Colors.black38 : Colors.white70;

    canvas.drawCircle(
      handlePos,
      8,
      Paint()
        ..color = handleColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      handlePos,
      8,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.saturation != saturation ||
        oldDelegate.brightness != brightness;
  }
}

class _GradientSlider extends StatefulWidget {
  final double value;
  final List<Color> colors;
  final ValueChanged<double> onChanged;

  const _GradientSlider({
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  @override
  State<_GradientSlider> createState() => _GradientSliderState();
}

class _GradientSliderState extends State<_GradientSlider> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanDown: (d) => _update(d.localPosition.dx, constraints.maxWidth),
          onPanUpdate: (d) => _update(d.localPosition.dx, constraints.maxWidth),
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: widget.colors),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: widget.value * (constraints.maxWidth - 24),
                  top: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade600, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _update(double dx, double totalWidth) {
    final newValue = (dx / totalWidth).clamp(0.0, 1.0);
    widget.onChanged(newValue);
  }
}
