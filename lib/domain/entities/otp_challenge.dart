/// In-memory OTP challenge data used by the local email verification flow.
class OtpChallenge {
  const OtpChallenge({
    required this.email,
    required this.code,
    required this.createdAt,
  });

  final String email;
  final String code;
  final DateTime createdAt;
}
