import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../canvas/presentation/providers/canvas_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/project_summary.dart';
import '../../../projects/presentation/providers/active_project_provider.dart';
import '../../../projects/presentation/providers/project_list_provider.dart';
import '../../../selection/presentation/providers/selection_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../shapes/presentation/providers/shape_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isProjectListLoading = true;
  String? _projectListError;
  bool _isCreatingProject = false;
  String? _openingProjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProjects());
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isProjectListLoading = true;
      _projectListError = null;
    });
    try {
      await ref.read(projectListProvider.notifier).loadProjects();
    } on Exception catch (_) {
      if (mounted) setState(() => _projectListError = 'Failed to load projects.');
    } finally {
      if (mounted) setState(() => _isProjectListLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryPurpleDark : AppColors.primaryPurple;
    const primaryLight = AppColors.primaryPurpleLight;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsButton(primary: primary, border: border, onTap: () => _showSettingsDialog(context)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          _LogoSection(primary: primary),
                          const SizedBox(height: 32),
                          // UX FIX 2 — loading indicator while creating
                          _NewProjectButton(
                            primary: primary,
                            onTap: _createNewProject,
                            isLoading: _isCreatingProject,
                          ),
                          const SizedBox(height: 32),
                          // UX FIX 2 — loading/empty/error states
                          _RecentProjectsSection(
                            projects: projects,
                            isLoading: _isProjectListLoading,
                            errorMessage: _projectListError,
                            onRetry: _loadProjects,
                            openingProjectId: _openingProjectId,
                            primary: primary,
                            primaryLight: primaryLight,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            border: border,
                            surface: surface,
                            onOpen: _openProject,
                          ),
                          const Spacer(flex: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // FEATURE 3 DONE — Removed useless _BottomNav banner
          ],
        ),
      ),
    );
  }

  Future<void> _createNewProject() async {
    if (_isCreatingProject) return;
    setState(() => _isCreatingProject = true);
    try {
      final id = UuidGenerator.generate();
      final now = DateTime.now();
      final project = Project(id: id, name: 'Untitled Drawing', createdAt: now, updatedAt: now);

      ref.read(shapeListProvider.notifier).clearAll();
      ref.read(historyProvider.notifier).clear();
      ref.read(selectionProvider.notifier).deselectAll();
      ref.read(canvasProvider.notifier).resetViewport();
      await ref.read(activeProjectProvider.notifier).open(project);
      if (mounted) context.go('/editor');
    } on Object catch (e) {
      debugPrint('Create project error: $e');
    } finally {
      if (mounted) setState(() => _isCreatingProject = false);
    }
  }

  Future<void> _openProject(String id) async {
    if (_openingProjectId != null) return;
    setState(() => _openingProjectId = id);
    try {
      ref.read(shapeListProvider.notifier).clearAll();
      ref.read(historyProvider.notifier).clear();
      ref.read(selectionProvider.notifier).deselectAll();
      await ref.read(activeProjectProvider.notifier).load(id);
      final project = ref.read(activeProjectProvider);
      if (project != null && mounted) {
        context.go('/editor');
      }
    } on Object catch (e) {
      debugPrint('Open project error: $e');
    } finally {
      if (mounted) setState(() => _openingProjectId = null);
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final settings = ref.read(settingsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (v) {
                if (v == null) return;
                ref.read(settingsProvider.notifier).setThemeMode(v);
                Navigator.pop(ctx);
              },
              child: Column(
                children: ThemeMode.values.map((mode) {
                  final label = switch (mode) {
                    ThemeMode.system => 'Follow System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  };
                  return RadioListTile<ThemeMode>(
                    title: Text(label),
                    value: mode,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Canvas Size: ${settings.canvasSizeLabel} (${settings.canvasWidth}\u00D7${settings.canvasHeight})',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final Color primary;
  final Color border;
  final VoidCallback onTap;

  const _SettingsButton({required this.primary, required this.border, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            // UX FIX 1 — touch targets: minimum 48dp tap area
            child: IconButton(
              icon: Icon(Icons.settings, color: primary, size: 22),
              onPressed: onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final Color primary;

  const _LogoSection({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, size: 80, color: primary),
          const SizedBox(height: 16),
          Text(
            'Rynex Draw',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Offline-first infinite canvas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProjectButton extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;
  final bool isLoading;

  const _NewProjectButton({
    required this.primary,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text(
                  '+ New Project',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

class _RecentProjectsSection extends StatelessWidget {
  final List<ProjectSummary> projects;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String? openingProjectId;
  final Color primary;
  final Color primaryLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color surface;
  final void Function(String id) onOpen;

  const _RecentProjectsSection({
    required this.projects,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.openingProjectId,
    required this.primary,
    required this.primaryLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.surface,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            if (onRetry != null)
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
          ],
        ),
      );
    }
    if (projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: textSecondary),
            const SizedBox(height: 12),
            Text('No recent projects', style: TextStyle(color: textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Projects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...projects.take(5).map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProjectCard(
                project: p,
                isOpening: openingProjectId == p.id,
                primaryLight: primaryLight,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                border: border,
                surface: surface,
                onTap: () => onOpen(p.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectSummary project;
  final bool isOpening;
  final Color primaryLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color surface;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    this.isOpening = false,
    required this.primaryLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isOpening ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isOpening
                    ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.image_outlined, size: 28, color: Color(0xFF6C4DD3)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${project.shapeCount} shapes \u2022 ${_formatDate(project.updatedAt)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isOpening
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.chevron_right, size: 22, color: textSecondary),
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


