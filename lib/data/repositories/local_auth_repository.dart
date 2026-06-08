import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/local_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Device-local implementation of [AuthRepository].
class LocalAuthRepository implements AuthRepository {
  static const _fileName = 'rynex_local_auth.json';

  final Map<String, LocalUser> _users = {};
  bool _isDarkMode = false;
  String? _currentUsername;
  File? _file;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  String? get currentUsername => _currentUsername;

  @override
  LocalUser? get currentUser {
    final username = _currentUsername;
    if (username == null) return null;
    return _users[username];
  }

  @override
  List<LocalUser> get users {
    final values = _users.values.toList(growable: false);
    values.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      ),
    );
    return values;
  }

  @override
  Future<void> load() async {
    final directory = await getApplicationDocumentsDirectory();
    _file = File(path.join(directory.path, _fileName));

    final file = _file!;
    if (!await file.exists()) {
      await _save();
      return;
    }

    final rawData = await file.readAsString();
    if (rawData.trim().isEmpty) return;

    final data = jsonDecode(rawData) as Map<String, dynamic>;
    _isDarkMode = data['isDarkMode'] as bool? ?? false;
    _currentUsername = (data['currentUsername'] as String?)?.trim().toLowerCase();

    final legacyCurrentEmail = data['currentUserEmail'] as String?;
    final usersData = data['users'] as Map<String, dynamic>? ?? {};
    _users.clear();

    for (final entry in usersData.entries) {
      final user = LocalUser.fromJson(entry.value as Map<String, dynamic>);
      final username = user.username.trim().toLowerCase();
      if (username.isNotEmpty) {
        _users[username] = user;
      }
    }

    if (_currentUsername == null && legacyCurrentEmail != null) {
      _currentUsername = _usernameForLegacyEmail(legacyCurrentEmail);
    }

    if (_currentUsername != null && !_users.containsKey(_currentUsername)) {
      _currentUsername = null;
    }

    await _save();
  }

  @override
  Future<void> signUp({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    final normalizedEmail = email.trim().toLowerCase();
    _validateUsername(normalizedUsername);
    _validateEmail(normalizedEmail);
    _validatePassword(password);

    if (_users.containsKey(normalizedUsername)) {
      throw const LocalAuthException('An account already exists for this username.');
    }

    final salt = _createSalt();
    _users[normalizedUsername] = LocalUser(
      username: normalizedUsername,
      name: name.trim(),
      email: normalizedEmail,
      passwordSalt: salt,
      passwordHash: _hashPassword(password, salt),
      avatarColor: LocalUser.avatarColorFor(normalizedUsername),
    );
    await _save();
  }

  @override
  Future<void> verifyLoginCredentials({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    final user = _users[normalizedUsername];
    if (user == null ||
        user.passwordHash != _hashPassword(password, user.passwordSalt)) {
      throw const LocalAuthException('Username or password is incorrect.');
    }
  }

  @override
  Future<void> completeVerifiedSignIn(String username) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_users.containsKey(normalizedUsername)) {
      throw const LocalAuthException('Username does not exist.');
    }

    _currentUsername = normalizedUsername;
    await _save();
  }

  @override
  Future<String> emailForUsername(String username) async {
    final normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername.isEmpty) {
      throw const LocalAuthException('Enter your username.');
    }

    final email = _users[normalizedUsername]?.email.trim().toLowerCase();
    if (email == null) {
      throw const LocalAuthException('Username does not exist.');
    }
    if (email.isEmpty) {
      throw const LocalAuthException('No email is configured for this username.');
    }
    _validateEmail(email);
    return email;
  }

  @override
  Future<void> setCurrentUser(String username) async {
    final normalizedUsername = _normalizeUsername(username);
    if (!_users.containsKey(normalizedUsername)) {
      throw const LocalAuthException('Username does not exist.');
    }
    _currentUsername = normalizedUsername;
    await _save();
  }

  @override
  Future<void> logout() async {
    _currentUsername = null;
    await _save();
  }

  @override
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    await _save();
  }

  String _createSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(_toJson()));
  }

  Map<String, dynamic> _toJson() {
    return {
      'isDarkMode': _isDarkMode,
      'currentUsername': _currentUsername,
      'users': _users.map((username, user) => MapEntry(username, user.toJson())),
    };
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _usernameForLegacyEmail(String email) {
    final localPart = email.split('@').first.trim().toLowerCase();
    final sanitized = localPart.replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    return sanitized.isEmpty ? 'user' : sanitized;
  }

  void _validateUsername(String username) {
    if (username.isEmpty) {
      throw const LocalAuthException('Enter your username.');
    }
    if (!RegExp(r'^[a-z0-9_.-]{3,32}$').hasMatch(username)) {
      throw const LocalAuthException(
        'Usernames must be 3-32 characters using letters, numbers, dots, underscores, or hyphens.',
      );
    }
  }

  void _validateEmail(String email) {
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      throw const LocalAuthException('A valid email is required for this username.');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const LocalAuthException('Password must be at least 8 characters.');
    }
  }
}
