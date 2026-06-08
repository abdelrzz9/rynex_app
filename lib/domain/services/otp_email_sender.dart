abstract class OtpEmailSender {
  Future<void> sendOtp({
    required String recipientEmail,
    required String username,
    required String code,
  });
}

class OtpEmailException implements Exception {
  const OtpEmailException(this.message);

  final String message;
}
