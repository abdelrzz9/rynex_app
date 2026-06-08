import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/otp_repository.dart';
import '../../domain/usecases/request_local_otp.dart';
import '../../domain/usecases/resend_local_otp.dart';
import '../../domain/usecases/verify_local_otp.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({
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
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  late final RequestLocalOtp _requestLocalOtp;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _requestLocalOtp = RequestLocalOtp(widget.otpRepository);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final challenge = _requestLocalOtp(_phoneController.text);
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
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Icon(
                              Icons.phone_iphone_outlined,
                              size: 44,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Verify your phone number',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter your mobile number to receive a local testing OTP. No network, database, or backend is used.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+()\-\s]'),
                            ),
                          ],
                          onFieldSubmitted: (_) => _requestOtp(),
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            hintText: '+1 555 123 4567',
                            prefixIcon: Icon(Icons.call_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validatePhoneNumber,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _requestOtp,
                          icon: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sms_outlined),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Request OTP'),
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

  String? _validatePhoneNumber(String? value) {
    final phone = value?.trim() ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Enter a valid phone number with at least 10 digits.';
    }
    return null;
  }
}

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
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  late OtpChallenge _challenge;
  late final ResendLocalOtp _resendLocalOtp;
  late final VerifyLocalOtp _verifyLocalOtp;
  final _controllers = List<TextEditingController>.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List<FocusNode>.generate(_otpLength, (_) => FocusNode());
  Timer? _timer;
  int _remainingSeconds = _resendSeconds;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _challenge = widget.initialChallenge;
    _resendLocalOtp = ResendLocalOtp(widget.otpRepository);
    _verifyLocalOtp = VerifyLocalOtp(widget.otpRepository);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remainingSeconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _remainingSeconds = 0);
        return;
      }
      if (mounted) setState(() => _remainingSeconds--);
    });
  }

  void _resendOtp() {
    if (_remainingSeconds > 0) return;
    final challenge = _resendLocalOtp();
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {
      _challenge = challenge;
      _isVerified = false;
    });
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new OTP has been generated.')),
    );
  }

  void _verify() {
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all 6 digits.')),
      );
      return;
    }

    if (_verifyLocalOtp(code)) {
      widget.otpRepository.clear();
      _timer?.cancel();
      setState(() => _isVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number verified successfully.')),
      );
      widget.onVerified(_challenge.phoneNumber);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incorrect OTP. Please try again.')),
    );
  }

  void _handleOtpChanged(String value, int index) {
    if (value.length > 1) {
      _pasteOtp(value);
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final code = _controllers.map((controller) => controller.text).join();
    if (code.length == _otpLength) {
      _verify();
    }
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _pasteOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _otpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final focusIndex = digits.length >= _otpLength ? _otpLength - 1 : digits.length;
    final clampedFocusIndex = focusIndex.clamp(0, _otpLength - 1) as int;
    _focusNodes[clampedFocusIndex].requestFocus();
    if (digits.length >= _otpLength) _verify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isCompact = MediaQuery.sizeOf(context).width < 420;
    final fieldSize = isCompact ? 44.0 : 54.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 20 : 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        _isVerified
                            ? Icons.verified_user_outlined
                            : Icons.mark_email_read_outlined,
                        size: 56,
                        color: _isVerified
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isVerified ? 'Verification complete' : 'Check your OTP',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We generated a local 6-digit code for ${_challenge.phoneNumber}.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 18),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              'Debug OTP: ${_challenge.code}',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_otpLength, (index) {
                          return SizedBox(
                            width: fieldSize,
                            height: fieldSize + 8,
                            child: Focus(
                              onKeyEvent: (_, event) =>
                                  _handleKeyEvent(event, index),
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                enabled: !_isVerified,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                textInputAction: index == _otpLength - 1
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                maxLength: 1,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _handleOtpChanged(value, index),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isVerified ? null : _verify,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Verify OTP'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _remainingSeconds == 0 && !_isVerified
                            ? _resendOtp
                            : null,
                        icon: const Icon(Icons.refresh_outlined),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _remainingSeconds == 0
                                ? 'Resend OTP'
                                : 'Resend in ${_remainingSeconds}s',
                          ),
                        ),
                      ),
                      if (_isVerified) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Success! You can now continue with the verified phone session.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class OtpSuccessScreen extends StatelessWidget {
  const OtpSuccessScreen({
    required this.phoneNumber,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onStartOver,
    super.key,
  });

  final String phoneNumber;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified'),
        actions: [
          IconButton(
            tooltip: isDarkMode ? 'Use light mode' : 'Use dark mode',
            onPressed: () => onDarkModeChanged(!isDarkMode),
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 72,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Phone verified successfully',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        phoneNumber,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: onStartOver,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Verify another number'),
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
    );
  }
}
