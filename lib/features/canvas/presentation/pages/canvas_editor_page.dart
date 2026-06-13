import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/infinite_canvas.dart';
import '../widgets/top_toolbar.dart';
import '../widgets/canvas_gesture_handler.dart';
import '../../../shapes/presentation/widgets/drawing_toolbar.dart';
import '../../../shapes/presentation/widgets/properties_panel.dart';
import '../../../shapes/presentation/providers/active_tool_provider.dart';
import '../../../layers/presentation/widgets/layer_panel.dart';
import '../../../../core/constants/tool_constants.dart';

class CanvasEditorPage extends ConsumerWidget {
  const CanvasEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: isMobile
                ? _buildMobileLayout(context, ref)
                : _buildDesktopLayout(context, ref),
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

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const DrawingToolbar(),
        Expanded(
          child: Stack(
            children: [
              const CanvasGestureHandler(
                child: InfiniteCanvas(),
              ),
            ],
          ),
        ),
        const PropertiesPanel(),
        const LayerPanel(),
      ],
    );
  }

  Widget _buildMiniToolbar(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
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
        spacing: 2,
        runSpacing: 2,
        children: DrawingTool.values.map((tool) {
          return InkWell(
            onTap: () => ref.read(activeToolProvider.notifier).state = tool,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: activeTool == tool
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _toolIcon(tool),
                size: 20,
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
