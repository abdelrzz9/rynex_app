import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;
    final crossAxisCount = isTablet ? (screenWidth ~/ 280).clamp(2, 4) : 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, screenWidth > 360 ? 48 : 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Projects',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create, edit, and manage your drawings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _ActionButton(
                          icon: Icons.add,
                          label: 'New Project',
                          onTap: _createNewProject,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.folder_open,
                          label: 'Import',
                          onTap: () {},
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _ActionButton(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {},
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            if (projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.draw_outlined,
                        size: 64,
                        color: isDark ? AppColors.textDisabled : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No projects yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "New Project" to create your first drawing',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textDisabled : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recent Projects',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ProjectCard(
                      project: projects[index],
                      isDark: isDark,
                      onTap: () => _openProject(projects[index].id),
                    ),
                    childCount: projects.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createNewProject() async {
    final id = UuidGenerator.generate();
    final now = DateTime.now();
    final project = Project(id: id, name: 'Untitled Drawing', createdAt: now, updatedAt: now);

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
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectSummary project;
  final bool isDark;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: isDark ? AppColors.textDisabled : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.shapeCount} shapes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _formatDate(project.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textDisabled : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
