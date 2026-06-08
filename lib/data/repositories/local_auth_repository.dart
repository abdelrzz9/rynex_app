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
  static const _pbkdf2Algorithm = 'pbkdf2-sha256';
  static const _pbkdf2Iterations = 120000;
  static const _derivedKeyLength = 32;

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
    // Always require an explicit local unlock after an app restart.
    _currentUserEmail = null;

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

    await _save();
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
        'A local account already exists for this email.',
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
    if (user == null || !_verifyPassword(password, user)) {
      throw const LocalAuthException('Email or local password is incorrect.');
    }

    _currentUserEmail = normalizedEmail;
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
    final derivedKey = _pbkdf2(
      passwordBytes: utf8.encode(password),
      saltBytes: base64Url.decode(salt),
      iterations: _pbkdf2Iterations,
      length: _derivedKeyLength,
    );
    return [
      _pbkdf2Algorithm,
      _pbkdf2Iterations.toString(),
      base64UrlEncode(derivedKey),
    ].join(r'$');
  }

  bool _verifyPassword(String password, LocalUser user) {
    if (user.passwordHash.startsWith('$_pbkdf2Algorithm\$')) {
      return _constantTimeEquals(
        user.passwordHash,
        _hashPassword(password, user.passwordSalt),
      );
    }

    final legacyHash = sha256
        .convert(utf8.encode('${user.passwordSalt}:$password'))
        .toString();
    return _constantTimeEquals(user.passwordHash, legacyHash);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var difference = 0;
    for (var index = 0; index < a.length; index += 1) {
      difference |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }

    return difference == 0;
  }

  List<int> _pbkdf2({
    required List<int> passwordBytes,
    required List<int> saltBytes,
    required int iterations,
    required int length,
  }) {
    final hmac = Hmac(sha256, passwordBytes);
    final blocks = <int>[];
    final blockCount = (length / hmac.convert(<int>[]).bytes.length).ceil();

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex += 1) {
      var block = hmac.convert([
        ...saltBytes,
        (blockIndex >> 24) & 0xff,
        (blockIndex >> 16) & 0xff,
        (blockIndex >> 8) & 0xff,
        blockIndex & 0xff,
      ]).bytes;
      final output = List<int>.from(block);

      for (var iteration = 1; iteration < iterations; iteration += 1) {
        block = hmac.convert(block).bytes;
        for (var index = 0; index < output.length; index += 1) {
          output[index] ^= block[index];
        }
      }

      blocks.addAll(output);
    }

    return blocks.take(length).toList(growable: false);
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
