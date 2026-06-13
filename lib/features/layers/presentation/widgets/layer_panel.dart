import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/layer.dart';
import '../providers/layer_provider.dart';

class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(layerListProvider);
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
              onReorder: (old, next) => ref.read(layerListProvider.notifier).reorder(old, next),
              itemBuilder: (context, index) {
                final layer = layers[index];
                return _LayerTile(key: ValueKey(layer.id), layer: layer);
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

  const _LayerTile({super.key, required this.layer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLast = layer.order == ref.watch(layerListProvider).map((l) => l.order).reduce(
      (a, b) => a > b ? a : b,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isLast ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: ListTile(
          dense: true,
          leading: Icon(
            layer.isVisible ? Icons.visibility : Icons.visibility_off,
            size: 18,
            color: layer.isVisible ? theme.colorScheme.onSurface : theme.disabledColor,
          ),
          title: Text(
            layer.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
              color: layer.isVisible ? null : theme.disabledColor,
            ),
          ),
          trailing: Icon(
            layer.isLocked ? Icons.lock : Icons.lock_open,
            size: 16,
            color: theme.disabledColor,
          ),
          onTap: () => ref.read(layerListProvider.notifier).toggleVisibility(layer.id),
          onLongPress: () => ref.read(layerListProvider.notifier).toggleLock(layer.id),
        ),
      ),
    );
  }
}
