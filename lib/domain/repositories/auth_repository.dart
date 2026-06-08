import '../entities/local_user.dart';

/// Authentication and profile storage boundary for local accounts.
abstract class AuthRepository {
  bool get isDarkMode;
  String? get currentUserEmail;
  LocalUser? get currentUser;
  List<LocalUser> get users;

  Future<void> load();

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> login({required String email, required String password});
  Future<void> setCurrentUser(String email);
  Future<void> logout();
  Future<void> setDarkMode(bool value);
}

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);

  final String message;
}
