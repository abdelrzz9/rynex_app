import '../entities/otp_challenge.dart';

/// Boundary for local, device-only OTP generation and email verification.
abstract class OtpRepository {
  OtpChallenge? get currentChallenge;

  OtpChallenge requestOtp(String email);
  OtpChallenge resendOtp();
  bool verifyOtp(String code);
  void clear();
}

class OtpException implements Exception {
  const OtpException(this.message);

  final String message;
}
