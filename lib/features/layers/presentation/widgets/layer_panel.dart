import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/layer.dart';
import '../providers/layer_provider.dart';

class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(layerListProvider);
    final activeId = ref.watch(activeLayerIdProvider);
    final theme = Theme.of(context);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Layers', style: theme.textTheme.titleSmall),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => ref.read(layerListProvider.notifier).addLayer('Layer ${layers.length + 1}'),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add Layer',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: layers.length,
              onReorderItem: (old, next) => ref.read(layerListProvider.notifier).reorder(old, next),
              itemBuilder: (context, index) {
                final layer = layers[index];
                final isActive = layer.id == activeId;
                return _LayerTile(key: ValueKey(layer.id), layer: layer, isActive: isActive);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerTile extends ConsumerWidget {
  final LayerEntity layer;
  final bool isActive;

  const _LayerTile({super.key, required this.layer, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: ListTile(
          dense: true,
          leading: GestureDetector(
            onTap: () => ref.read(layerListProvider.notifier).toggleVisibility(layer.id),
            child: Icon(
              layer.isVisible ? Icons.visibility : Icons.visibility_off,
              size: 18,
              color: layer.isVisible ? theme.colorScheme.onSurface : theme.disabledColor,
            ),
          ),
          title: GestureDetector(
            onDoubleTap: () => _renameDialog(context, ref),
            child: Text(
              layer.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: layer.isVisible ? null : theme.disabledColor,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => ref.read(layerListProvider.notifier).toggleLock(layer.id),
                child: Icon(
                  layer.isLocked ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(width: 4),
              if (!isActive && ref.watch(layerListProvider).length > 1)
                GestureDetector(
                  onTap: () => ref.read(layerListProvider.notifier).removeLayer(layer.id),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          onTap: () => ref.read(activeLayerIdProvider.notifier).state = layer.id,
          onLongPress: () => ref.read(layerListProvider.notifier).toggleLock(layer.id),
        ),
      ),
    );
  }

  void _renameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: layer.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Layer name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(layerListProvider.notifier).rename(layer.id, controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
