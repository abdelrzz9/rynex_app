import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: RynexApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
