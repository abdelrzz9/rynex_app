/// In-memory OTP challenge metadata for a username-based email verification flow.
class OtpChallenge {
  const OtpChallenge({
    required this.username,
    required this.code,
    required this.createdAt,
  });

  final String username;
  final String code;
  final DateTime createdAt;
}
