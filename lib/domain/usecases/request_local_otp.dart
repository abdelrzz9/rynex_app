import '../entities/otp_challenge.dart';
import '../repositories/otp_repository.dart';

class RequestLocalOtp {
  const RequestLocalOtp(this._repository);

  final OtpRepository _repository;

  Future<OtpChallenge> call(String username) {
    return _repository.requestOtp(username);
  }
}
