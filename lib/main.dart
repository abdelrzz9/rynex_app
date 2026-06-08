import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/in_memory_otp_repository.dart';
import 'data/repositories/local_auth_repository.dart';
import 'data/services/smtp_otp_email_sender.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = LocalAuthRepository();
  await authStore.load();
  final otpRepository = InMemoryOtpRepository(
    authRepository: authStore,
    emailSender: const SmtpOtpEmailSender(),
  );
  runApp(RynexApp(authStore: authStore, otpRepository: otpRepository));
}
