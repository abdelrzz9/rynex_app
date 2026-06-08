import '../entities/otp_challenge.dart';
import '../repositories/otp_repository.dart';

class ResendLocalOtp {
  const ResendLocalOtp(this._repository);

  final OtpRepository _repository;

  Future<OtpChallenge> call() {
    return _repository.resendOtp();
  }
}
