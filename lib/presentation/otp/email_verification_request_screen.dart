import 'package:flutter/material.dart';

import '../../core/config/app_identity.dart';
import '../../domain/repositories/otp_repository.dart';
import '../../domain/usecases/request_local_otp.dart';
import 'otp_verification_screen.dart';

class EmailVerificationRequestScreen extends StatefulWidget {
  const EmailVerificationRequestScreen({
    required this.otpRepository,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onVerified,
    super.key,
  });

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
  final _emailController = TextEditingController(text: AppIdentity.ownerEmail);
  late final RequestLocalOtp _requestLocalOtp;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _requestLocalOtp = RequestLocalOtp(widget.otpRepository);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final challenge = _requestLocalOtp(_emailController.text);
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
    } on OtpException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (email != AppIdentity.ownerEmail) {
      return 'Use ${AppIdentity.ownerEmail} to continue.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rynex Email Verification'),
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
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Icon(
                              Icons.alternate_email,
                              size: 44,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Verify your email',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The phone form was replaced with an email check for '
                          '${AppIdentity.ownerEmail}. Verification is prepared '
                          'locally without showing a code on screen.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => _requestOtp(),
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _requestOtp,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open),
                          label: Text(
                            _isSubmitting ? 'Preparing...' : 'Continue',
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
