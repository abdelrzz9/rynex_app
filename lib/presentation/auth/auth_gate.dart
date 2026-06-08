import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/otp_repository.dart';
import '../home/home_screen.dart';
import '../otp/otp_flow.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.authStore,
    required this.otpRepository,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  final AuthRepository authStore;
  final OtpRepository otpRepository;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late String? _signedInUsername;
  String? _verifiedUsername;

  @override
  void initState() {
    super.initState();
    _signedInUsername = widget.authStore.currentUsername;
  }

  Future<void> _onUsernameVerified(String username) async {
    await widget.authStore.completeVerifiedSignIn(username);
    if (!mounted) return;
    setState(() {
      _verifiedUsername = username;
      _signedInUsername = widget.authStore.currentUsername;
    });
  }

  Future<void> _onSwitchAccount(String username) async {
    await widget.authStore.setCurrentUser(username);
    setState(() => _signedInUsername = username);
  }

  Future<void> _logout() async {
    await widget.authStore.logout();
    setState(() {
      _signedInUsername = null;
      _verifiedUsername = null;
    });
  }

  void _restartOtpFlow() {
    widget.otpRepository.clear();
    setState(() => _verifiedUsername = null);
  }

  @override
  Widget build(BuildContext context) {
    final signedInUsername = _signedInUsername;
    if (signedInUsername == null) {
      final verifiedUsername = _verifiedUsername;
      if (verifiedUsername != null) {
        return EmailVerificationSuccessScreen(
          username: verifiedUsername,
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          onStartOver: _restartOtpFlow,
        );
      }

      return EmailVerificationRequestScreen(
        authStore: widget.authStore,
        otpRepository: widget.otpRepository,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onVerified: _onUsernameVerified,
      );
    }

    final currentUser = widget.authStore.currentUser;
    if (currentUser == null) {
      return EmailVerificationRequestScreen(
        authStore: widget.authStore,
        otpRepository: widget.otpRepository,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onVerified: _onUsernameVerified,
      );
    }

    return HomeScreen(
      currentUser: currentUser,
      users: widget.authStore.users,
      isDarkMode: widget.isDarkMode,
      onDarkModeChanged: widget.onDarkModeChanged,
      onSwitchAccount: _onSwitchAccount,
      onLogout: _logout,
    );
  }
}
