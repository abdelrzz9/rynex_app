import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/export_service.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../providers/canvas_provider.dart';

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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    final iconSize = isMobile ? 18.0 : isTablet ? 20.0 : 22.0;
    final buttonSize = isMobile ? 48.0 : isTablet ? 44.0 : 40.0;
    final toolbarHeight = isMobile ? 56.0 : isTablet ? 64.0 : 72.0;
    final spacing = isMobile ? 2.0 : isTablet ? 4.0 : 6.0;
    final horizontalPadding = isMobile ? 4.0 : isTablet ? 8.0 : 12.0;

    return Container(
      height: toolbarHeight,
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
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back to Home',
            onPressed: () => context.goNamed('home'),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: buttonSize, minHeight: buttonSize),
          ),
          if (screenWidth > 360) ...[
            SizedBox(width: isMobile ? 2 : 4),
            Text(
              'Rynex Draw',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
            ),
          ],
          SizedBox(width: spacing),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _IconButton(
                    icon: Icons.undo,
                    tooltip: 'Undo (Ctrl+Z)',
                    enabled: canUndo,
                    onTap: () => ref.read(historyProvider.notifier).undo(),
                    iconSize: iconSize,
                    buttonSize: buttonSize,
                  ),
                  _IconButton(
                    icon: Icons.redo,
                    tooltip: 'Redo (Ctrl+Y)',
                    enabled: canRedo,
                    onTap: () => ref.read(historyProvider.notifier).redo(),
                    iconSize: iconSize,
                    buttonSize: buttonSize,
                  ),
                  SizedBox(width: spacing + (isMobile ? 2 : 4)),
                  Container(height: 24, width: 1, color: Colors.grey.shade400),
                  SizedBox(width: spacing + (isMobile ? 2 : 4)),
                  _IconButton(
                    icon: Icons.zoom_out,
                    tooltip: 'Zoom Out',
                    enabled: true,
                    onTap: () => ref.read(canvasProvider.notifier).zoomOut(Offset.zero),
                    iconSize: iconSize,
                    buttonSize: buttonSize,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing),
                    child: Text(
                      '${(canvasState.transform.zoom * 100).round()}%',
                      style: TextStyle(fontSize: isMobile ? 12 : 13, color: fgColor),
                    ),
                  ),
                  _IconButton(
                    icon: Icons.zoom_in,
                    tooltip: 'Zoom In',
                    enabled: true,
                    onTap: () => ref.read(canvasProvider.notifier).zoomIn(Offset.zero),
                    iconSize: iconSize,
                    buttonSize: buttonSize,
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
                    iconSize: iconSize,
                    buttonSize: buttonSize,
                  ),
                  SizedBox(width: spacing + (isMobile ? 2 : 4)),
                  Container(height: 24, width: 1, color: Colors.grey.shade400),
                  SizedBox(width: spacing + (isMobile ? 2 : 4)),
                  _IconButton(
                    icon: canvasState.showGrid ? Icons.grid_on : Icons.grid_off,
                    tooltip: 'Toggle Grid (Ctrl+Shift+G)',
                    enabled: true,
                    onTap: () => ref.read(canvasProvider.notifier).toggleGrid(),
                    iconSize: iconSize,
                    buttonSize: buttonSize,
                  ),
                  SizedBox(width: spacing),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: fgColor, size: 20),
                    tooltip: 'More',
                    onPressed: () => _showMoreMenu(context, ref),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: buttonSize, minHeight: buttonSize),
                  ),
                ],
              ),
            ),
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
        const PopupMenuItem(value: 'export_json', child: Text('Export as JSON')),
      ],
    ).then((value) async {
      if (value == 'clear') {
        ref.read(shapeListProvider.notifier).clearAll();
        ref.read(historyProvider.notifier).clear();
      } else if (value == 'export_png') {
        final repaintKey = ref.read(canvasRepaintKeyProvider);
        if (repaintKey == null) return;
        final shapes = ref.read(shapeListProvider);
        if (shapes.isEmpty) return;
        await ExportService().exportPng(shapes, ExportService.calculateContentBounds(shapes), repaintKey);
      } else if (value == 'export_json') {
        final shapes = ref.read(shapeListProvider);
        if (shapes.isEmpty) return;
        await ExportService().exportJson(shapes);
      }
    });
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;
  final double iconSize;
  final double buttonSize;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.iconSize = 20,
    this.buttonSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: iconSize),
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: buttonSize, minHeight: buttonSize),
      ),
    );
  }
}
