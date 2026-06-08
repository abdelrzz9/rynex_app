import 'dart:math';

import '../../domain/entities/otp_challenge.dart';
import '../../domain/repositories/otp_repository.dart';

/// Stores local email OTP challenges only in this process' memory.
class InMemoryOtpRepository implements OtpRepository {
  final Random _random = Random.secure();
  OtpChallenge? _currentChallenge;

  @override
  OtpChallenge? get currentChallenge => _currentChallenge;

  @override
  OtpChallenge requestOtp(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const OtpException('Enter a valid email address.');
    }

    return _currentChallenge = OtpChallenge(
      email: normalizedEmail,
      code: _generateCode(),
      createdAt: DateTime.now(),
    );
  }

  @override
  OtpChallenge resendOtp() {
    final challenge = _currentChallenge;
    if (challenge == null) {
      throw const OtpException('Request an OTP before resending.');
    }

    return requestOtp(challenge.email);
  }

  @override
  bool verifyOtp(String code) {
    final challenge = _currentChallenge;
    if (challenge == null) return false;
    return code.trim() == challenge.code;
  }

  @override
  void clear() {
    _currentChallenge = null;
  }

  String _generateCode() {
    final value = 100000 + _random.nextInt(900000);
    return value.toString();
  }
}
