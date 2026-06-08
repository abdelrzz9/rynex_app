import 'package:flutter/material.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/otp_repository.dart';
import '../../domain/usecases/request_local_otp.dart';
import 'otp_verification_screen.dart';

class EmailVerificationRequestScreen extends StatefulWidget {
  const EmailVerificationRequestScreen({
    required this.authStore,
    required this.otpRepository,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onVerified,
    super.key,
  });

  final AuthRepository authStore;
  final OtpRepository otpRepository;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onVerified;

  @override
  State<EmailVerificationRequestScreen> createState() =>
      _EmailVerificationRequestScreenState();
}

class _EmailVerificationRequestScreenState
    extends State<EmailVerificationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final RequestLocalOtp _requestLocalOtp;
  bool _isRegistering = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _requestLocalOtp = RequestLocalOtp(widget.otpRepository);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final username = _usernameController.text.trim().toLowerCase();
      if (_isRegistering) {
        await widget.authStore.signUp(
          username: username,
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await widget.authStore.verifyLoginCredentials(
          username: username,
          password: _passwordController.text,
        );
      }

      final challenge = await _requestLocalOtp(username);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(
            initialChallenge: challenge,
            otpRepository: widget.otpRepository,
            onVerified: widget.onVerified,
          ),
        ),
      );
    } on LocalAuthException catch (error) {
      _showError(error.message);
    } on OtpException catch (error) {
      _showError(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateUsername(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    if (username.isEmpty) return 'Enter your username.';
    if (!RegExp(r'^[a-z0-9_.-]{3,32}$').hasMatch(username)) {
      return 'Use 3-32 letters, numbers, dots, underscores, or hyphens.';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isRegistering) return null;
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your display name.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (!_isRegistering) return null;
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Enter the account email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password.';
    if (_isRegistering && password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  void _toggleMode(bool registering) {
    if (_isSubmitting || _isRegistering == registering) return;
    setState(() => _isRegistering = registering);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rynex Verification'),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Use light mode' : 'Use dark mode',
            onPressed: () => widget.onDarkModeChanged(!widget.isDarkMode),
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _isRegistering ? 'Create account' : 'Sign in',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter your username. If an OTP is needed, Rynex sends it only to the email stored for that username.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Login')),
                            ButtonSegment(value: true, label: Text('Register')),
                          ],
                          selected: {_isRegistering},
                          onSelectionChanged: (values) => _toggleMode(values.single),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateUsername,
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Account email',
                              prefixIcon: Icon(Icons.mail_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateEmail,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _requestOtp(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _requestOtp,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.lock_open),
                          label: Text(
                            _isSubmitting ? 'Sending...' : 'Send OTP',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
