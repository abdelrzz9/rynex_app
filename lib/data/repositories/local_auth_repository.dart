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
  String? _currentUserEmail;
  File? _file;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  String? get currentUserEmail => _currentUserEmail;

  @override
  LocalUser? get currentUser {
    final email = _currentUserEmail;
    if (email == null) return null;
    return _users[email];
  }

  @override
  List<LocalUser> get users {
    final values = _users.values.toList(growable: false);
    values.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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
    _currentUserEmail = data['currentUserEmail'] as String?;

    final usersData = data['users'] as Map<String, dynamic>? ?? {};
    _users
      ..clear()
      ..addAll(
        usersData.map(
          (email, userData) => MapEntry(
            email,
            LocalUser.fromJson(userData as Map<String, dynamic>),
          ),
        ),
      );

    if (_currentUserEmail != null && !_users.containsKey(_currentUserEmail)) {
      _currentUserEmail = null;
      await _save();
    }
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_users.containsKey(normalizedEmail)) {
      throw const LocalAuthException(
        'An account already exists for this email.',
      );
    }

    final salt = _createSalt();
    _users[normalizedEmail] = LocalUser(
      name: name.trim(),
      email: normalizedEmail,
      passwordSalt: salt,
      passwordHash: _hashPassword(password, salt),
      avatarColor: LocalUser.avatarColorFor(normalizedEmail),
    );
    _currentUserEmail = normalizedEmail;
    await _save();
  }

  @override
  Future<void> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _users[normalizedEmail];
    if (user == null ||
        user.passwordHash != _hashPassword(password, user.passwordSalt)) {
      throw const LocalAuthException('Email or password is incorrect.');
    }

    _currentUserEmail = normalizedEmail;
    await _save();
  }

  @override
  Future<void> setCurrentUser(String email) async {
    _currentUserEmail = email.trim().toLowerCase();
    await _save();
  }

  @override
  Future<void> logout() async {
    _currentUserEmail = null;
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

    final data = {
      'isDarkMode': _isDarkMode,
      'currentUserEmail': _currentUserEmail,
      'users': _users.map((email, user) => MapEntry(email, user.toJson())),
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}
