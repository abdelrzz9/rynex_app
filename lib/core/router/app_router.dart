import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/canvas/presentation/pages/canvas_editor_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/projects/presentation/providers/active_project_provider.dart';
import '../../features/projects/presentation/providers/project_list_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'editor',
          name: 'editor',
          onExit: (context, state) async {
            try {
              final container = ProviderScope.containerOf(context);
              await container.read(activeProjectProvider.notifier)
                  .saveNow()
                  .timeout(const Duration(seconds: 3));
              container.invalidate(projectListProvider);
            } on Object catch (e) {
              debugPrint('Save on exit failed or timed out: $e');
            }
            return true;
          },
          builder: (context, state) => const CanvasEditorPage(),
        ),
      ],
    ),
  ],
);
