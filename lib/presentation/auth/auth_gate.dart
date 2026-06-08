import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';
import '../home/home_screen.dart';
import 'local_auth_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.authStore,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  final AuthRepository authStore;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late String? _signedInEmail;

  @override
  void initState() {
    super.initState();
    _signedInEmail = widget.authStore.currentUserEmail;
  }

  void _onAuthenticated() {
    setState(() => _signedInEmail = widget.authStore.currentUserEmail);
  }

  Future<void> _logout() async {
    await widget.authStore.logout();
    setState(() => _signedInEmail = null);
  }

  @override
  Widget build(BuildContext context) {
    final signedInEmail = _signedInEmail;
    final currentUser = widget.authStore.currentUser;
    if (signedInEmail == null || currentUser == null) {
      return LocalAuthScreen(
        authStore: widget.authStore,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onAuthenticated: _onAuthenticated,
      );
    }

    return HomeScreen(
      currentUser: currentUser,
      isDarkMode: widget.isDarkMode,
      onDarkModeChanged: widget.onDarkModeChanged,
      onLogout: _logout,
    );
  }
}
