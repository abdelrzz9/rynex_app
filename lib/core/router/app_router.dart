import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/canvas/presentation/pages/canvas_editor_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'editor',
      builder: (context, state) => const CanvasEditorPage(),
    ),
  ],
);
