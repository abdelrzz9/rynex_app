import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';

// FEATURE 1 DONE — Inline editable canvas name
class CanvasNameEditor extends ConsumerStatefulWidget {
  const CanvasNameEditor({super.key});

  @override
  ConsumerState<CanvasNameEditor> createState() => _CanvasNameEditorState();
}

class _CanvasNameEditorState extends ConsumerState<CanvasNameEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing(String currentName) {
    _controller.text = currentName;
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _commit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      ref.read(activeProjectProvider.notifier).updateName(name);
    }
    if (mounted) setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final name = project?.name ?? 'Untitled Drawing';

    if (_isEditing) {
      return SizedBox(
        width: 200,
        height: 36,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: (_) => _commit(),
          onTapOutside: (_) => _commit(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: fgColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: fgColor.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: fgColor),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _startEditing(name),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: fgColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.edit, size: 16, color: fgColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
