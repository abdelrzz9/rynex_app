import '../repositories/otp_repository.dart';

class VerifyLocalOtp {
  const VerifyLocalOtp(this._repository);

  final OtpRepository _repository;

  bool call(String code) {
    return _repository.verifyOtp(code);
  }
}
