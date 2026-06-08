import 'package:flutter/material.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/otp_repository.dart';
import 'presentation/auth/auth_gate.dart';

class RynexApp extends StatefulWidget {
  const RynexApp({
    required this.authStore,
    required this.otpRepository,
    super.key,
  });

  final AuthRepository authStore;
  final OtpRepository otpRepository;

  @override
  State<RynexApp> createState() => _RynexAppState();
}

class _RynexAppState extends State<RynexApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.authStore.isDarkMode;
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await widget.authStore.setDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rynex Drawing & Notes',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AuthGate(
        authStore: widget.authStore,
        otpRepository: widget.otpRepository,
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}
