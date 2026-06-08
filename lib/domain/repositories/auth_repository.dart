import '../entities/local_user.dart';

abstract class AuthRepository {
  bool get isDarkMode;
  String? get currentUsername;
  LocalUser? get currentUser;
  List<LocalUser> get users;

  Future<void> load();
  Future<void> signUp({
    required String username,
    required String name,
    required String email,
    required String password,
  });
  Future<void> verifyLoginCredentials({
    required String username,
    required String password,
  });
  Future<void> completeVerifiedSignIn(String username);
  Future<String> emailForUsername(String username);
  Future<void> setCurrentUser(String username);
  Future<void> logout();
  Future<void> setDarkMode(bool value);
}

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);

  final String message;
}
