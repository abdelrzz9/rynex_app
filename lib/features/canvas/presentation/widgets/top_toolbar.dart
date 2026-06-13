import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/canvas_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';

class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasProvider);
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final fgColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Text('Rynex Draw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 16),
          const Spacer(),
          _IconButton(
            icon: Icons.undo,
            tooltip: 'Undo (Ctrl+Z)',
            enabled: canUndo,
            onTap: () => ref.read(historyProvider.notifier).undo(),
          ),
          _IconButton(
            icon: Icons.redo,
            tooltip: 'Redo (Ctrl+Y)',
            enabled: canRedo,
            onTap: () => ref.read(historyProvider.notifier).redo(),
          ),
          const SizedBox(width: 8),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          _IconButton(
            icon: Icons.zoom_out,
            tooltip: 'Zoom Out',
            enabled: true,
            onTap: () => ref.read(canvasProvider.notifier).zoomOut(Offset.zero),
          ),
          Text(
            '${(canvasState.transform.zoom * 100).round()}%',
            style: TextStyle(fontSize: 13, color: fgColor),
          ),
          _IconButton(
            icon: Icons.zoom_in,
            tooltip: 'Zoom In',
            enabled: true,
            onTap: () => ref.read(canvasProvider.notifier).zoomIn(Offset.zero),
          ),
          _IconButton(
            icon: Icons.fit_screen,
            tooltip: 'Zoom to Fit',
            enabled: true,
            onTap: () {
              final shapes = ref.read(shapeListProvider);
              if (shapes.isEmpty) {
                ref.read(canvasProvider.notifier).resetViewport();
                return;
              }
              final bounds = shapes.map((s) => s.rotatedBoundingBox).reduce(
                (a, b) => a.expandToInclude(b),
              );
              ref.read(canvasProvider.notifier).zoomToFit(
                MediaQuery.of(context).size,
                bounds,
              );
            },
          ),
          Container(height: 24, width: 1, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          _IconButton(
            icon: canvasState.showGrid ? Icons.grid_on : Icons.grid_off,
            tooltip: 'Toggle Grid (Ctrl+Shift+G)',
            enabled: true,
            onTap: () => ref.read(canvasProvider.notifier).toggleGrid(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.more_vert, color: fgColor, size: 20),
            tooltip: 'More',
            onPressed: () => _showMoreMenu(context, ref),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 50, 0, 0),
      items: [
        const PopupMenuItem(value: 'clear', child: Text('Clear Canvas')),
        const PopupMenuItem(value: 'export_png', child: Text('Export as PNG')),
        const PopupMenuItem(value: 'export_svg', child: Text('Export as SVG')),
        const PopupMenuItem(value: 'export_json', child: Text('Export as JSON')),
      ],
    ).then((value) {
      if (value == 'clear') {
        ref.read(shapeListProvider.notifier).clearAll();
        ref.read(historyProvider.notifier).clear();
      }
    });
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
