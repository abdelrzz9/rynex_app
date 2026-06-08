import 'dart:math';

import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/otp_repository.dart';
import '../../domain/services/otp_email_sender.dart';

/// Stores OTP challenges only in this process' memory and delivers codes by SMTP.
class InMemoryOtpRepository implements OtpRepository {
  InMemoryOtpRepository({
    required AuthRepository authRepository,
    required OtpEmailSender emailSender,
  })  : _authRepository = authRepository,
        _emailSender = emailSender;

  final AuthRepository _authRepository;
  final OtpEmailSender _emailSender;
  static const _otpLifetime = Duration(minutes: 10);

  final Random _random = Random.secure();
  OtpChallenge? _currentChallenge;

  @override
  OtpChallenge? get currentChallenge => _currentChallenge;

  @override
  Future<OtpChallenge> requestOtp(String username) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.isEmpty) {
      throw const OtpException('Enter your username.');
    }

    final recipientEmail = await _lookupEmail(normalizedUsername);
    final challenge = OtpChallenge(
      username: normalizedUsername,
      code: _generateCode(),
      createdAt: DateTime.now(),
    );

    await _sendOtp(
      recipientEmail: recipientEmail,
      username: normalizedUsername,
      code: challenge.code,
    );
    _currentChallenge = challenge;
    return challenge;
  }

  @override
  Future<OtpChallenge> resendOtp() async {
    final challenge = _currentChallenge;
    if (challenge == null) {
      throw const OtpException('Request an OTP before resending.');
    }

    return requestOtp(challenge.username);
  }

  @override
  bool verifyOtp(String code) {
    final challenge = _currentChallenge;
    if (challenge == null) return false;
    final isExpired =
        DateTime.now().difference(challenge.createdAt) > _otpLifetime;
    if (isExpired) {
      clear();
      return false;
    }
    final submittedCode = code.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(submittedCode)) return false;
    return submittedCode == challenge.code;
  }

  @override
  void clear() {
    _currentChallenge = null;
  }

  Future<String> _lookupEmail(String username) async {
    try {
      return await _authRepository.emailForUsername(username);
    } on LocalAuthException catch (error) {
      throw OtpException(error.message);
    }
  }

  Future<void> _sendOtp({
    required String recipientEmail,
    required String username,
    required String code,
  }) async {
    try {
      await _emailSender.sendOtp(
        recipientEmail: recipientEmail,
        username: username,
        code: code,
      );
    } on OtpEmailException catch (error) {
      throw OtpException(error.message);
    }
  }

  String _generateCode() {
    final value = 100000 + _random.nextInt(900000);
    return value.toString();
  }
}
