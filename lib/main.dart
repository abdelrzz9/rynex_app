import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/in_memory_otp_repository.dart';
import 'data/repositories/local_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = LocalAuthRepository();
  await authStore.load();
  final otpRepository = InMemoryOtpRepository();
  runApp(RynexApp(authStore: authStore, otpRepository: otpRepository));
}
