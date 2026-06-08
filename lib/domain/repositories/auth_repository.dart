import '../entities/local_user.dart';

/// Authentication and profile storage boundary for offline local accounts.
abstract class AuthRepository {
  bool get isDarkMode;
  String? get currentUserEmail;
  LocalUser? get currentUser;

  Future<void> load();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> login({required String email, required String password});
  Future<void> logout();
  Future<void> setDarkMode(bool value);
}

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);

  final String message;
}
