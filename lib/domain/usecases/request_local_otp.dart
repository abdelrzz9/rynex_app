import '../entities/otp_challenge.dart';
import '../repositories/otp_repository.dart';

class RequestLocalOtp {
  const RequestLocalOtp(this._repository);

  final OtpRepository _repository;

  OtpChallenge call(String email) {
    return _repository.requestOtp(email);
  }
}
