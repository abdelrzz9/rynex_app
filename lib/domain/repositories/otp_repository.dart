import '../entities/otp_challenge.dart';

/// Boundary for username-based email OTP generation and verification.
abstract class OtpRepository {
  OtpChallenge? get currentChallenge;

  Future<OtpChallenge> requestOtp(String username);
  Future<OtpChallenge> resendOtp();
  bool verifyOtp(String code);
  void clear();
}

class OtpException implements Exception {
  const OtpException(this.message);

  final String message;
}
