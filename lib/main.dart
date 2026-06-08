import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/local_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = LocalAuthRepository();
  await authStore.load();
  runApp(RynexApp(authStore: authStore));
}
