import 'package:flutter/material.dart';

import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/otp_repository.dart';
import '../../domain/usecases/resend_local_otp.dart';
import '../../domain/usecases/verify_local_otp.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.initialChallenge,
    required this.otpRepository,
    required this.onVerified,
    super.key,
  });

  final OtpChallenge initialChallenge;
  final OtpRepository otpRepository;
  final ValueChanged<String> onVerified;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late OtpChallenge _challenge;
  late final ResendLocalOtp _resendLocalOtp;
  late final VerifyLocalOtp _verifyLocalOtp;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _challenge = widget.initialChallenge;
    _resendLocalOtp = ResendLocalOtp(widget.otpRepository);
    _verifyLocalOtp = VerifyLocalOtp(widget.otpRepository);
  }

  Future<void> _verifyEmail() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (_verifyLocalOtp(_challenge.code)) {
      final email = _challenge.email;
      widget.otpRepository.clear();
      widget.onVerified(email);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    setState(() => _isVerifying = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification expired. Send a new email.')),
    );
  }

  void _resendEmail() {
    setState(() => _challenge = _resendLocalOtp());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new local email check is ready.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Check your email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Email ready for ${_challenge.email}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'For this local demo, no verification digits are printed '
                        'or typed on screen. Tap the verification action to '
                        'continue as the owner account.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _isVerifying ? null : _verifyEmail,
                        icon: _isVerifying
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.verified_user_outlined),
                        label: Text(
                          _isVerifying ? 'Verifying...' : 'Verify email',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _isVerifying ? null : _resendEmail,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Send again'),
                      ),
                    ],
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
