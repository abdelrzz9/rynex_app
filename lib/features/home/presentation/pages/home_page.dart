import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../canvas/presentation/providers/canvas_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/project_summary.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';
import '../../../projects/presentation/providers/project_list_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectListProvider.notifier).loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.draw, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Rynex Draw', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Offline-first infinite canvas', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                  _buildNewProjectButton(theme),
                  const SizedBox(height: 32),
                  if (projects.isEmpty)
                    Expanded(child: _buildEmptyState(theme))
                  else
                    Expanded(child: _buildProjectList(projects, theme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewProjectButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _createNewProject,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text('No projects yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor)),
          const SizedBox(height: 8),
          Text('Create your first drawing!', style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<ProjectSummary> projects, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Projects', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectTile(project, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectTile(ProjectSummary project, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image_outlined, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${project.shapeCount} shapes · ${_formatDate(project.updatedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openProject(project.id),
      ),
    );
  }

  Future<void> _createNewProject() async {
    final id = UuidGenerator.generate();
    final now = DateTime.now();
    final project = Project(id: id, name: 'Untitled', createdAt: now, updatedAt: now);

    ref.read(shapeListProvider.notifier).clearAll();
    ref.read(historyProvider.notifier).clear();
    ref.read(selectionProvider.notifier).deselectAll();
    ref.read(canvasProvider.notifier).resetViewport();
    await ref.read(activeProjectProvider.notifier).open(project);
    if (!mounted) return;
    context.goNamed('editor');
  }

  Future<void> _openProject(String id) async {
    ref.read(shapeListProvider.notifier).clearAll();
    ref.read(historyProvider.notifier).clear();
    ref.read(selectionProvider.notifier).deselectAll();
    await ref.read(activeProjectProvider.notifier).load(id);
    final project = ref.read(activeProjectProvider);
    if (project != null) {
      await ref.read(projectStorageServiceProvider).saveProject(project);
      if (!mounted) return;
      context.goNamed('editor');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
