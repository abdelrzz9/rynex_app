import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/tool_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/active_tool_provider.dart';

class DrawingToolbar extends ConsumerWidget {
  const DrawingToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final selectedColor = isDark ? AppColors.darkSelected : AppColors.lightSelected;
    final iconColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isMobile = screenWidth < 600;
    final isShort = screenHeight < 600;

    final iconSize = isShort ? 18.0 : (isMobile ? 20.0 : 22.0);
    final buttonSize = isShort ? 38.0 : (isMobile ? 44.0 : 48.0);

    final tools = _toolGroups;

    if (isMobile) {
      final mobileChildren = <Widget>[];
      for (final group in tools) {
        for (final tool in group) {
          mobileChildren.add(_ToolButton(
            tool: tool,
            icon: _toolIcon(tool),
            isActive: activeTool == tool,
            selectedColor: selectedColor,
            iconColor: iconColor,
            iconSize: iconSize,
            buttonSize: buttonSize,
            onTap: () => ref.read(activeToolProvider.notifier).state = tool,
          ));
        }
        if (group != tools.last) {
          mobileChildren.add(Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Container(width: 1, height: 24, color: borderColor),
          ));
        }
      }
      return Container(
        height: buttonSize + 8,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          physics: const BouncingScrollPhysics(),
          children: mobileChildren,
        ),
      );
    }

    final desktopChildren = <Widget>[];
    for (final group in tools) {
      for (final tool in group) {
        desktopChildren.add(_ToolButton(
          tool: tool,
          icon: _toolIcon(tool),
          isActive: activeTool == tool,
          selectedColor: selectedColor,
          iconColor: iconColor,
          iconSize: iconSize,
          buttonSize: buttonSize,
          onTap: () => ref.read(activeToolProvider.notifier).state = tool,
        ));
      }
      if (group != tools.last) {
        desktopChildren.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Divider(height: 1, color: borderColor),
        ));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: SizedBox(
        width: buttonSize + 8,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: desktopChildren,
          ),
        ),
      ),
    );
  }

  static const List<List<DrawingTool>> _toolGroups = [
    [DrawingTool.select],
    [DrawingTool.pencil, DrawingTool.pen, DrawingTool.marker, DrawingTool.brush],
    [DrawingTool.eraser],
    [DrawingTool.rectangle, DrawingTool.roundedRect, DrawingTool.ellipse, DrawingTool.diamond, DrawingTool.triangle, DrawingTool.polygon],
    [DrawingTool.line, DrawingTool.arrow],
    [DrawingTool.freehand],
    [DrawingTool.text, DrawingTool.image],
  ];

  IconData _toolIcon(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.select:
        return Icons.pan_tool_outlined;
      case DrawingTool.pencil:
        return Icons.edit;
      case DrawingTool.pen:
        return Icons.draw;
      case DrawingTool.marker:
        return Icons.highlight;
      case DrawingTool.brush:
        return Icons.brush;
      case DrawingTool.eraser:
        return Icons.auto_fix_high;
      case DrawingTool.rectangle:
        return Icons.rectangle_outlined;
      case DrawingTool.roundedRect:
        return Icons.rounded_corner;
      case DrawingTool.ellipse:
        return Icons.circle_outlined;
      case DrawingTool.diamond:
        return Icons.diamond_outlined;
      case DrawingTool.triangle:
        return Icons.change_history;
      case DrawingTool.polygon:
        return Icons.pentagon_outlined;
      case DrawingTool.line:
        return Icons.show_chart;
      case DrawingTool.arrow:
        return Icons.arrow_forward;
      case DrawingTool.freehand:
        return Icons.gesture;
      case DrawingTool.text:
        return Icons.text_fields;
      case DrawingTool.image:
        return Icons.image_outlined;
    }
  }
}

class _ToolButton extends StatelessWidget {
  final DrawingTool tool;
  final IconData icon;
  final bool isActive;
  final Color selectedColor;
  final Color iconColor;
  final double iconSize;
  final double buttonSize;
  final VoidCallback onTap;

  const _ToolButton({
    required this.tool,
    required this.icon,
    required this.isActive,
    required this.selectedColor,
    required this.iconColor,
    required this.iconSize,
    required this.buttonSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${tool.label} (${tool.shortcutLabel})',
      preferBelow: false,
      child: Material(
        color: isActive ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: iconSize,
              color: isActive ? AppColors.accent : iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
