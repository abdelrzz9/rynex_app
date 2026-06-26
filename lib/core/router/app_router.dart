import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/canvas/presentation/pages/canvas_editor_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

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
          builder: (context, state) => const CanvasEditorPage(),
        ),
      ],
    ),
  ],
);
