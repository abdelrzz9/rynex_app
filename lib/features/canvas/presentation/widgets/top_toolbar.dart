import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';
import '../../../projects/presentation/providers/project_list_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../providers/canvas_provider.dart';
import 'canvas_name_editor.dart';

class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasProvider);
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final fgColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    final iconSize = isMobile ? 18.0 : 22.0;
    final buttonSize = isMobile ? 40.0 : 44.0;
    final toolbarHeight = isMobile ? 52.0 : 60.0;
    final spacing = isMobile ? 2.0 : 6.0;
    final horizontalPadding = isMobile ? 4.0 : 12.0;

    return Container(
      height: toolbarHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          // UX FIX 1 — touch targets: minimum 48dp tap area
          // Back: pop from nested /editor route to parent /
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back to Home',
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          if (screenWidth > 360) ...[
            const SizedBox(width: 4),
            const CanvasNameEditor(),
          ],
          const Spacer(),
          SingleChildScrollView(
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
                  fgColor: fgColor,
                ),
                _IconButton(
                  icon: Icons.redo,
                  tooltip: 'Redo (Ctrl+Y)',
                  enabled: canRedo,
                  onTap: () => ref.read(historyProvider.notifier).redo(),
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                  fgColor: fgColor,
                ),
                SizedBox(width: spacing),
                Container(height: 24, width: 1, color: borderColor),
                SizedBox(width: spacing),
                Text(
                  '${(canvasState.transform.zoom * 100).round()}%',
                  style: TextStyle(fontSize: isMobile ? 12 : 13, color: fgColor),
                ),
                _IconButton(
                  icon: Icons.zoom_out,
                  tooltip: 'Zoom Out',
                  enabled: true,
                  onTap: () => ref.read(canvasProvider.notifier).zoomOut(Offset.zero),
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                  fgColor: fgColor,
                ),
                _IconButton(
                  icon: Icons.zoom_in,
                  tooltip: 'Zoom In',
                  enabled: true,
                  onTap: () => ref.read(canvasProvider.notifier).zoomIn(Offset.zero),
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                  fgColor: fgColor,
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
                  fgColor: fgColor,
                ),
                SizedBox(width: spacing),
                Container(height: 24, width: 1, color: borderColor),
                SizedBox(width: spacing),
                _IconButton(
                  icon: canvasState.showGrid ? Icons.grid_on : Icons.grid_off,
                  tooltip: 'Toggle Grid',
                  enabled: true,
                  onTap: () => ref.read(canvasProvider.notifier).toggleGrid(),
                  iconSize: iconSize,
                  buttonSize: buttonSize,
                  fgColor: fgColor,
                ),
                SizedBox(width: spacing),
                // UX FIX 1,4 — 48dp tap target + popup position from button RenderBox
                Builder(
                  builder: (buttonCtx) => IconButton(
                    icon: Icon(Icons.more_vert, color: fgColor, size: 20),
                    tooltip: 'More',
                    onPressed: () => _showMoreMenu(buttonCtx, ref),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCanvasSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Canvas Size'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final preset in PresetCanvasSize.presets)
                ListTile(
                  title: Text('${preset.label} (${preset.width}\u00D7${preset.height})'),
                  leading: const Icon(Icons.crop_square),
                  onTap: () {
                    ref.read(canvasProvider.notifier).setCanvasSize(preset.width, preset.height, preset.label);
                    ref.read(settingsProvider.notifier).setCanvasSize(preset.width, preset.height, preset.label);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  // UX FIX 3 — reusable destructive confirmation dialog
  static Future<bool> _confirmDestructiveAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // UX FIX 4 — popup position from button's RenderBox
  void _showMoreMenu(BuildContext buttonContext, WidgetRef ref) {
    final renderBox = buttonContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final overlay = Overlay.of(buttonContext);
    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null) return;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlayRenderBox),
      ),
      Offset.zero & overlayRenderBox.size,
    );

    showMenu(
      context: buttonContext,
      position: position,
      items: [
        const PopupMenuItem(value: 'save', child: Text('Save Project')),
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Project')),
        const PopupMenuItem(value: 'canvas_size', child: Text('Canvas Size')),
        const PopupMenuItem(value: 'clear', child: Text('Clear Canvas')),
        const PopupMenuItem(value: 'export_png', child: Text('Export as PNG')),
        const PopupMenuItem(value: 'export_jpg', child: Text('Export as JPG')),
        const PopupMenuItem(value: 'export_pdf', child: Text('Export as PDF')),
      ],
    ).then((value) async {
      if (value == 'canvas_size') {
        _showCanvasSizeDialog(buttonContext, ref);
      } else if (value == 'save') {
        await ref.read(activeProjectProvider.notifier).saveNow();
        if (buttonContext.mounted) {
          ScaffoldMessenger.of(buttonContext).showSnackBar(
            const SnackBar(content: Text('Project saved'), duration: Duration(seconds: 1)),
          );
        }
      } else if (value == 'duplicate') {
        final project = ref.read(activeProjectProvider);
        if (project == null) return;
        final id = UuidGenerator.generate();
        final dup = Project(
          id: id,
          name: '${project.name} (Copy)',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          shapes: project.shapes,
        );
        await ref.read(projectStorageServiceProvider).saveProject(dup);
        await ref.read(projectListProvider.notifier).loadProjects();
        if (buttonContext.mounted) {
          ScaffoldMessenger.of(buttonContext).showSnackBar(
            const SnackBar(content: Text('Project duplicated'), duration: Duration(seconds: 1)),
          );
        }
      } else if (value == 'clear') {
        final confirmed = await _confirmDestructiveAction(
          buttonContext,
          title: 'Clear Canvas',
          message: 'This will remove all shapes and cannot be undone.',
          confirmLabel: 'Clear',
        );
        if (!confirmed) return;
        ref.read(shapeListProvider.notifier).clearAll();
        ref.read(historyProvider.notifier).clear();
      } else if (value == 'export_png') {
        final repaintKey = ref.read(canvasRepaintKeyProvider);
        if (repaintKey == null) return;
        final shapes = ref.read(shapeListProvider);
        if (shapes.isEmpty) return;
        final cs = ref.read(canvasProvider);
        await ExportService().exportPng(
          shapes, ExportService.calculateContentBounds(shapes), repaintKey,
          canvasWidth: cs.canvasWidth, canvasHeight: cs.canvasHeight, transform: cs.transform,
        );
      } else if (value == 'export_jpg') {
        final repaintKey = ref.read(canvasRepaintKeyProvider);
        if (repaintKey == null) return;
        final shapes = ref.read(shapeListProvider);
        if (shapes.isEmpty) return;
        final cs = ref.read(canvasProvider);
        await ExportService().exportJpg(
          shapes, ExportService.calculateContentBounds(shapes), repaintKey,
          canvasWidth: cs.canvasWidth, canvasHeight: cs.canvasHeight, transform: cs.transform,
        );
      } else if (value == 'export_pdf') {
        final repaintKey = ref.read(canvasRepaintKeyProvider);
        if (repaintKey == null) return;
        final shapes = ref.read(shapeListProvider);
        if (shapes.isEmpty) return;
        final cs = ref.read(canvasProvider);
        await ExportService().exportPdf(
          shapes, ExportService.calculateContentBounds(shapes), repaintKey,
          canvasWidth: cs.canvasWidth, canvasHeight: cs.canvasHeight, transform: cs.transform,
        );
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
  final Color fgColor;

  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
    this.iconSize = 20,
    this.buttonSize = 40,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    // UX FIX 1 — touch targets: minimum 48dp tap area
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: iconSize, color: enabled ? fgColor : fgColor.withValues(alpha: 0.3)),
        onPressed: enabled ? onTap : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }
}
