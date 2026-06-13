import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../providers/active_tool_provider.dart';

class DrawingToolbar extends ConsumerWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : Colors.white;
    final selectedColor = isDark ? Colors.blue.shade700 : Colors.blue.shade100;
    final iconColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolButton(
            tool: DrawingTool.select,
            icon: Icons.pan_tool_outlined,
            shortcut: 'V',
            isActive: activeTool == DrawingTool.select,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.select,
          ),
          const Divider(height: 1),
          _ToolButton(
            tool: DrawingTool.rectangle,
            icon: Icons.rectangle_outlined,
            shortcut: 'R',
            isActive: activeTool == DrawingTool.rectangle,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.rectangle,
          ),
          _ToolButton(
            tool: DrawingTool.ellipse,
            icon: Icons.circle_outlined,
            shortcut: 'O',
            isActive: activeTool == DrawingTool.ellipse,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.ellipse,
          ),
          _ToolButton(
            tool: DrawingTool.diamond,
            icon: Icons.diamond_outlined,
            shortcut: 'D',
            isActive: activeTool == DrawingTool.diamond,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.diamond,
          ),
          _ToolButton(
            tool: DrawingTool.triangle,
            icon: Icons.change_history,
            shortcut: 'T',
            isActive: activeTool == DrawingTool.triangle,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.triangle,
          ),
          const Divider(height: 1),
          _ToolButton(
            tool: DrawingTool.line,
            icon: Icons.show_chart,
            shortcut: 'L',
            isActive: activeTool == DrawingTool.line,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.line,
          ),
          _ToolButton(
            tool: DrawingTool.arrow,
            icon: Icons.arrow_forward,
            shortcut: 'A',
            isActive: activeTool == DrawingTool.arrow,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.arrow,
          ),
          _ToolButton(
            tool: DrawingTool.freehand,
            icon: Icons.brush,
            shortcut: 'P',
            isActive: activeTool == DrawingTool.freehand,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.freehand,
          ),
          const Divider(height: 1),
          _ToolButton(
            tool: DrawingTool.text,
            icon: Icons.text_fields,
            shortcut: 'X',
            isActive: activeTool == DrawingTool.text,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.text,
          ),
          _ToolButton(
            tool: DrawingTool.image,
            icon: Icons.image_outlined,
            shortcut: 'I',
            isActive: activeTool == DrawingTool.image,
            selectedColor: selectedColor,
            iconColor: iconColor,
            onTap: () => ref.read(activeToolProvider.notifier).state = DrawingTool.image,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final DrawingTool tool;
  final IconData icon;
  final String shortcut;
  final bool isActive;
  final Color selectedColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.shortcut,
    required this.isActive,
    required this.selectedColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${tool.label} ($shortcut)',
      preferBelow: false,
      child: Material(
        color: isActive ? selectedColor : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 44,
            child: Icon(icon, size: 22, color: isActive ? Colors.blue : iconColor),
          ),
        ),
      ),
    );
  }
}
