import 'package:flutter/material.dart';

import '../../core/config/app_identity.dart';
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
  late String? _signedInEmail;
  String? _verifiedEmail;

  @override
  void initState() {
    super.initState();
    _signedInEmail = widget.authStore.currentUserEmail;
  }

  Future<void> _onEmailVerified(String email) async {
    await widget.authStore.ensureVerifiedUser(
      name: AppIdentity.ownerName,
      email: email,
    );
    if (!mounted) return;
    setState(() {
      _verifiedEmail = email;
      _signedInEmail = widget.authStore.currentUserEmail;
    });
  }

  Future<void> _onSwitchAccount(String email) async {
    await widget.authStore.setCurrentUser(email);
    setState(() => _signedInEmail = email);
  }

  Future<void> _logout() async {
    await widget.authStore.logout();
    setState(() {
      _signedInEmail = null;
      _verifiedEmail = null;
    });
  }

  void _restartOtpFlow() {
    widget.otpRepository.clear();
    setState(() => _verifiedEmail = null);
  }

  @override
  Widget build(BuildContext context) {
    final signedInEmail = _signedInEmail;
    if (signedInEmail == null) {
      final verifiedEmail = _verifiedEmail;
      if (verifiedEmail != null) {
        return EmailVerificationSuccessScreen(
          email: verifiedEmail,
          isDarkMode: widget.isDarkMode,
          onDarkModeChanged: widget.onDarkModeChanged,
          onStartOver: _restartOtpFlow,
        );
      }

      return EmailVerificationRequestScreen(
        otpRepository: widget.otpRepository,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onVerified: _onEmailVerified,
      );
    }

    final currentUser = widget.authStore.currentUser;
    if (currentUser == null) {
      return EmailVerificationRequestScreen(
        otpRepository: widget.otpRepository,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onVerified: _onEmailVerified,
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
