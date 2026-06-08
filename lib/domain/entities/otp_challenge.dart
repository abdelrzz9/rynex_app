/// In-memory OTP challenge data used by the local verification flow.
class OtpChallenge {
  const OtpChallenge({
    required this.phoneNumber,
    required this.code,
    required this.createdAt,
  });

  final String phoneNumber;
  final String code;
  final DateTime createdAt;
}
