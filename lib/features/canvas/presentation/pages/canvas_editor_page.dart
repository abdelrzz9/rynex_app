import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../layers/presentation/widgets/layer_panel.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';
import '../../../shapes/presentation/widgets/drawing_toolbar.dart';
import '../../../shapes/presentation/widgets/properties_panel.dart';
import '../widgets/canvas_gesture_handler.dart';
import '../widgets/infinite_canvas.dart';
import '../widgets/top_toolbar.dart';

class CanvasEditorPage extends ConsumerStatefulWidget {
  const CanvasEditorPage({super.key});

  @override
  ConsumerState<CanvasEditorPage> createState() => _CanvasEditorPageState();
}

class _CanvasEditorPageState extends ConsumerState<CanvasEditorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = ref.read(activeProjectProvider);
      if (project != null && project.shapes.isNotEmpty) {
        ref.read(shapeListProvider.notifier).shapes = project.shapes;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final showSidePanels = screenWidth >= 1200;

    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          const SizedBox(height: 8),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(context, ref)
                : _buildDesktopLayout(context, ref, isTablet, showSidePanels),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const CanvasGestureHandler(
          child: InfiniteCanvas(),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: _buildMiniToolbar(context, ref),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, WidgetRef ref, bool isTablet, bool showSidePanels) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DrawingToolbar(),
        const Expanded(
          child: Stack(
            children: [
              CanvasGestureHandler(
                child: InfiniteCanvas(),
              ),
            ],
          ),
        ),
        if (showSidePanels) ...[
          const PropertiesPanel(),
          const LayerPanel(),
        ],
      ],
    );
  }

  Widget _buildMiniToolbar(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final iconSize = screenWidth < 360 ? 18.0 : 20.0;
    const buttonSize = 48.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        children: DrawingTool.values.map((tool) {
          return InkWell(
            onTap: () => ref.read(activeToolProvider.notifier).state = tool,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: activeTool == tool
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _toolIcon(tool),
                size: iconSize,
                color: activeTool == tool
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _toolIcon(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.select:
        return Icons.pan_tool_outlined;
      case DrawingTool.rectangle:
        return Icons.rectangle_outlined;
      case DrawingTool.ellipse:
        return Icons.circle_outlined;
      case DrawingTool.diamond:
        return Icons.diamond_outlined;
      case DrawingTool.triangle:
        return Icons.change_history;
      case DrawingTool.line:
        return Icons.show_chart;
      case DrawingTool.arrow:
        return Icons.arrow_forward;
      case DrawingTool.freehand:
        return Icons.brush;
      case DrawingTool.text:
        return Icons.text_fields;
      case DrawingTool.image:
        return Icons.image_outlined;
    }
  }
}
