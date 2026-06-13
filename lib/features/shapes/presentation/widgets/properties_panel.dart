import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shape.dart';
import '../../domain/entities/shape_entity.dart';
import '../../domain/entities/shape_type.dart';
import '../providers/active_tool_provider.dart';
import '../providers/shape_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../domain/value_objects/stroke_style.dart';
import '../../domain/value_objects/fill_style.dart';
import '../../domain/value_objects/roughness.dart';

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final allShapes = ref.watch(shapeListProvider);
    final selectedShapes = allShapes.where((s) => selection.isSelected(s.id)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: selectedShapes.isEmpty
          ? _buildDefaultProperties(ref)
          : selectedShapes.length == 1
              ? _buildShapeProperties(ref, selectedShapes.first)
              : _buildMultiSelectProperties(ref, selectedShapes.length),
    );
  }

  Widget _buildDefaultProperties(WidgetRef ref) {
    final style = ref.watch(activeStyleProvider);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _ColorField(
          label: 'Stroke',
          color: style.strokeColor,
          onChanged: (c) => ref.read(activeStyleProvider.notifier).setStrokeColor(c),
        ),
        const SizedBox(height: 8),
        _ColorField(
          label: 'Fill',
          color: style.fillColor,
          onChanged: (c) => ref.read(activeStyleProvider.notifier).setFillColor(c),
        ),
        const SizedBox(height: 8),
        _buildSlider('Width', style.strokeWidth, 0.5, 20,
            (v) => ref.read(activeStyleProvider.notifier).setStrokeWidth(v)),
        const SizedBox(height: 8),
        _buildEnumDropdown('Stroke Style', style.strokeStyle, StrokeStyle.values,
            (v) => ref.read(activeStyleProvider.notifier).setStrokeStyle(v)),
        const SizedBox(height: 8),
        _buildEnumDropdown('Fill Style', style.fillStyle, FillStyle.values,
            (v) => ref.read(activeStyleProvider.notifier).setFillStyle(v)),
        const SizedBox(height: 8),
        _buildEnumDropdown('Roughness', style.roughness, Roughness.values,
            (v) => ref.read(activeStyleProvider.notifier).setRoughness(v)),
        const SizedBox(height: 8),
        _buildSlider('Opacity', style.opacity, 0.0, 1.0,
            (v) => ref.read(activeStyleProvider.notifier).setOpacity(v)),
      ],
    );
  }

  Widget _buildShapeProperties(WidgetRef ref, ShapeEntity shp) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(shp.type.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Position: (${shp.boundingBox.left.toStringAsFixed(0)}, ${shp.boundingBox.top.toStringAsFixed(0)})',
            style: const TextStyle(fontSize: 12)),
        Text('Size: ${shp.boundingBox.width.toStringAsFixed(0)} x ${shp.boundingBox.height.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12)),
        Text('Rotation: ${(shp.rotation * 180 / 3.14159).round()}°',
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 12),
        _ColorField(
          label: 'Stroke',
          color: shp.style.strokeColor,
          onChanged: (c) => _updateStyle(ref, shp, shp.style.copyWith(strokeColor: c)),
        ),
        const SizedBox(height: 8),
        _ColorField(
          label: 'Fill',
          color: shp.style.fillColor,
          onChanged: (c) => _updateStyle(ref, shp, shp.style.copyWith(fillColor: c)),
        ),
        const SizedBox(height: 8),
        _buildSlider('Width', shp.style.strokeWidth, 0.5, 20,
            (v) => _updateStyle(ref, shp, shp.style.copyWith(strokeWidth: v))),
        const SizedBox(height: 8),
        _buildEnumDropdown('Stroke', shp.style.strokeStyle, StrokeStyle.values,
            (v) => _updateStyle(ref, shp, shp.style.copyWith(strokeStyle: v))),
        _buildEnumDropdown('Fill', shp.style.fillStyle, FillStyle.values,
            (v) => _updateStyle(ref, shp, shp.style.copyWith(fillStyle: v))),
        _buildEnumDropdown('Roughness', shp.style.roughness, Roughness.values,
            (v) => _updateStyle(ref, shp, shp.style.copyWith(roughness: v))),
        _buildSlider('Opacity', shp.style.opacity, 0.0, 1.0,
            (v) => _updateStyle(ref, shp, shp.style.copyWith(opacity: v))),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_upward, size: 16),
                label: const Text('Up', style: TextStyle(fontSize: 12)),
                onPressed: () => ref.read(shapeListProvider.notifier).moveUp(shp.id),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_downward, size: 16),
                label: const Text('Down', style: TextStyle(fontSize: 12)),
                onPressed: () => ref.read(shapeListProvider.notifier).moveDown(shp.id),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete'),
          onPressed: () => ref.read(historyProvider.notifier).executeDelete([shp]),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildMultiSelectProperties(WidgetRef ref, int count) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('$count shapes selected',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete All'),
          onPressed: () {
            final allShapes = ref.read(shapeListProvider);
            final sel = ref.read(selectionProvider);
            final toDelete = allShapes.where((s) => sel.isSelected(s.id)).toList();
            ref.read(historyProvider.notifier).executeDelete(toDelete);
          },
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  void _updateStyle(WidgetRef ref, ShapeEntity shp, ShapeStyle newStyle) {
    final updated = shp.copyWith(style: newStyle);
    ref.read(historyProvider.notifier).executeModify(shp.id, shp, updated);
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildEnumDropdown<T>(String label, T value, List<T> items, ValueChanged<T> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(
                    item.toString().split('.').last,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorField({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: GestureDetector(
            onTap: () => _showColorDialog(context),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showColorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            Colors.black,
            Colors.white,
            Colors.red,
            Colors.pink,
            Colors.purple,
            Colors.deepPurple,
            Colors.indigo,
            Colors.blue,
            Colors.lightBlue,
            Colors.cyan,
            Colors.teal,
            Colors.green,
            Colors.lightGreen,
            Colors.lime,
            Colors.yellow,
            Colors.amber,
            Colors.orange,
            Colors.deepOrange,
            Colors.brown,
            Colors.grey,
            Colors.blueGrey,
          ].map((c) {
            return GestureDetector(
              onTap: () {
                onChanged(c);
                Navigator.of(ctx).pop();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
