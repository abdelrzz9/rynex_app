import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../history/domain/commands/align_shapes_command.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';
import '../../../projects/presentation/providers/project_list_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../providers/canvas_provider.dart';
import 'canvas_name_editor.dart';

class TopToolbar extends ConsumerWidget implements PreferredSizeWidget {
  const TopToolbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasState = ref.watch(canvasProvider);
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);

    return AppBar(
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        tooltip: 'Back to Home',
        onPressed: () => context.go('/'),
        padding: EdgeInsets.zero,
      ),
      title: const CanvasNameEditor(),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          tooltip: 'Undo (Ctrl+Z)',
          onPressed: canUndo ? () => ref.read(historyProvider.notifier).undo() : null,
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          tooltip: 'Redo (Ctrl+Y)',
          onPressed: canRedo ? () => ref.read(historyProvider.notifier).redo() : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '${(canvasState.transform.zoom * 100).round()}%',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, ref, value),
          itemBuilder: (ctx) => _buildMenuItems(ctx, ref),
        ),
      ],
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context, WidgetRef ref) {
    final selection = ref.read(selectionProvider);
    final multiSelected = selection.selectedIds.length >= 2;
    final shapes = ref.read(shapeListProvider);
    final hasShapes = shapes.isNotEmpty;

    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'canvas_size', child: Text('Canvas Size')),
      const PopupMenuItem(value: 'zoom_to_fit', child: Text('Zoom to Fit')),
      const PopupMenuItem(value: 'grid', child: Text('Toggle Grid')),
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'save', child: Text('Save Project')),
      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Project')),
      if (hasShapes) const PopupMenuItem(value: 'clear', child: Text('Clear Canvas')),
    ];

    if (multiSelected) {
      items.add(const PopupMenuDivider());
      items.add(const PopupMenuItem(value: 'align_left', child: Text('Align Left')));
      items.add(const PopupMenuItem(value: 'align_center_h', child: Text('Align Center H')));
      items.add(const PopupMenuItem(value: 'align_right', child: Text('Align Right')));
      items.add(const PopupMenuItem(value: 'align_top', child: Text('Align Top')));
      items.add(const PopupMenuItem(value: 'align_center_v', child: Text('Align Center V')));
      items.add(const PopupMenuItem(value: 'align_bottom', child: Text('Align Bottom')));
      items.add(const PopupMenuItem(value: 'distribute_h', child: Text('Distribute H')));
      items.add(const PopupMenuItem(value: 'distribute_v', child: Text('Distribute V')));
    }

    items.addAll([
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'export_png', child: Text('Export as PNG')),
      const PopupMenuItem(value: 'export_jpg', child: Text('Export as JPG')),
      const PopupMenuItem(value: 'export_pdf', child: Text('Export as PDF')),
    ]);

    return items;
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'canvas_size':
        _showCanvasSizeDialog(context, ref);
      case 'zoom_to_fit':
        _zoomToFit(ref);
      case 'grid':
        ref.read(canvasProvider.notifier).toggleGrid();
      case 'save':
        _saveProject(context, ref);
      case 'duplicate':
        _duplicateProject(context, ref);
      case 'clear':
        _clearCanvas(context, ref);
      case 'export_png':
      case 'export_jpg':
      case 'export_pdf':
        _export(context, ref, value);
      default:
        _handleAlignment(context, ref, value);
    }
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

  void _zoomToFit(WidgetRef ref) {
    final shapes = ref.read(shapeListProvider);
    if (shapes.isEmpty) {
      ref.read(canvasProvider.notifier).resetViewport();
      return;
    }
    final bounds = shapes.map((s) => s.rotatedBoundingBox).reduce(
      (a, b) => a.expandToInclude(b),
    );
    ref.read(canvasProvider.notifier).zoomToFit(
      WidgetsBinding.instance.platformDispatcher.views.first.physicalSize / WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio,
      bounds,
    );
  }

  Future<void> _saveProject(BuildContext context, WidgetRef ref) async {
    await ref.read(activeProjectProvider.notifier).saveNow();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project saved'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _duplicateProject(BuildContext context, WidgetRef ref) async {
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project duplicated'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _clearCanvas(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDestructiveAction(
      context,
      title: 'Clear Canvas',
      message: 'This will remove all shapes and cannot be undone.',
      confirmLabel: 'Clear',
    );
    if (!confirmed) return;
    ref.read(shapeListProvider.notifier).clearAll();
    ref.read(historyProvider.notifier).clear();
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String format) async {
    final repaintKey = ref.read(canvasRepaintKeyProvider);
    if (repaintKey == null) return;
    final shapes = ref.read(shapeListProvider);
    if (shapes.isEmpty) return;
    final cs = ref.read(canvasProvider);
    final bounds = ExportService.calculateContentBounds(shapes);
    switch (format) {
      case 'export_png':
        await ExportService().exportPng(shapes, bounds, repaintKey,
          canvasWidth: cs.canvasWidth, canvasHeight: cs.canvasHeight, transform: cs.transform,
        );
      case 'export_jpg':
        await ExportService().exportJpg(shapes, bounds, repaintKey,
          canvasWidth: cs.canvasWidth, canvasHeight: cs.canvasHeight, transform: cs.transform,
        );
      case 'export_pdf':
        await ExportService().exportPdf(shapes, bounds, repaintKey,
          canvasWidth: cs.canvasWidth, canvasHeight: cs.canvasHeight, transform: cs.transform,
        );
    }
  }

  void _handleAlignment(BuildContext context, WidgetRef ref, String value) {
    if (!value.startsWith('align_') && !value.startsWith('distribute_')) return;
    final shapes = ref.read(shapeListProvider);
    final selectedIds = ref.read(selectionProvider).selectedIds;
    final selected = shapes.where((s) => selectedIds.contains(s.id)).toList();
    if (selected.length < 2) return;

    final alignment = switch (value) {
      'align_left' => AlignmentType.left,
      'align_center_h' => AlignmentType.centerH,
      'align_right' => AlignmentType.right,
      'align_top' => AlignmentType.top,
      'align_center_v' => AlignmentType.centerV,
      'align_bottom' => AlignmentType.bottom,
      'distribute_h' => AlignmentType.distributeH,
      'distribute_v' => AlignmentType.distributeV,
      _ => null,
    };
    if (alignment == null) return;

    final command = AlignShapesCommand(
      shapes: selected,
      alignment: alignment,
      onUpdate: (id, s) => ref.read(shapeListProvider.notifier).updateShape(id, s),
    );
    ref.read(historyProvider.notifier).execute(command);
  }

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
}
