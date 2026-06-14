import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../layers/presentation/widgets/layer_panel.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBg
          : AppColors.lightBg,
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(isTablet, showSidePanels),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              const CanvasGestureHandler(
                child: InfiniteCanvas(),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _buildQuickActions(),
              ),
            ],
          ),
        ),
        const DrawingToolbar(),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isTablet, bool showSidePanels) {
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

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quickButton(Icons.undo, () => ref.read(historyProvider.notifier).undo()),
          _quickButton(Icons.redo, () => ref.read(historyProvider.notifier).redo()),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 20),
      ),
    );
  }
}
