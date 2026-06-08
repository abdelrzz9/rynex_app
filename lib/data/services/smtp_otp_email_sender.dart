import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/services/otp_email_sender.dart';

class SmtpOtpEmailSender implements OtpEmailSender {
  const SmtpOtpEmailSender({Map<String, String>? environment})
      : _environment = environment;

  final Map<String, String>? _environment;

  Map<String, String> get _env => _environment ?? Platform.environment;

  @override
  Future<void> sendOtp({
    required String recipientEmail,
    required String username,
    required String code,
  }) async {
    final config = _SmtpConfig.fromEnvironment(_env);
    _SmtpConnection connection;
    try {
      connection = await _SmtpConnection.connect(config);
    } on Object {
      throw const OtpEmailException('Unable to connect to the SMTP server.');
    }

    try {
      await connection.sendMessage(
        senderEmail: config.senderEmail,
        recipientEmail: recipientEmail,
        senderName: config.senderName,
        subject: 'Rynex verification code',
        body: 'Your Rynex verification code for $username is $code.\n\n'
            'If you did not request this code, ignore this email.',
      );
    } on OtpEmailException {
      rethrow;
    } on Object {
      throw const OtpEmailException('Unable to send the verification email.');
    } finally {
      connection.close();
    }
  }
}

class _SmtpConnection {
  _SmtpConnection(this._socket, Stream<String> lines)
      : _iterator = StreamIterator(lines);

  Socket _socket;
  StreamIterator<String> _iterator;

  static Future<_SmtpConnection> connect(_SmtpConfig config) async {
    final socket = config.useSsl
        ? await SecureSocket.connect(config.host, config.port)
        : await Socket.connect(config.host, config.port);
    final connection = _SmtpConnection(
      socket,
      socket.transform(utf8.decoder).transform(const LineSplitter()),
    );
    await connection._expect(220);
    await connection._ehlo();

    if (config.useStartTls) {
      await connection._command('STARTTLS', 220);
      await connection._iterator.cancel();
      final secureSocket = await SecureSocket.secure(socket, host: config.host);
      connection._socket = secureSocket;
      connection._iterator = StreamIterator(
        secureSocket.transform(utf8.decoder).transform(const LineSplitter()),
      );
      await connection._ehlo();
    }

    await connection._command('AUTH LOGIN', 334);
    await connection._command(base64Encode(utf8.encode(config.username)), 334);
    await connection._command(base64Encode(utf8.encode(config.password)), 235);
    return connection;
  }

  Future<void> sendMessage({
    required String senderEmail,
    required String recipientEmail,
    required String senderName,
    required String subject,
    required String body,
  }) async {
    await _command('MAIL FROM:<$senderEmail>', 250);
    await _command('RCPT TO:<$recipientEmail>', 250);
    await _command('DATA', 354);
    _socket.write(_buildMessage(
      senderEmail: senderEmail,
      recipientEmail: recipientEmail,
      senderName: senderName,
      subject: subject,
      body: body,
    ));
    await _expect(250);
    await _command('QUIT', 221);
  }

  void close() {
    _iterator.cancel();
    _socket.destroy();
  }

  Future<void> _ehlo() async {
    await _command('EHLO rynex.local', 250);
  }

  Future<void> _command(String command, int expectedCode) async {
    _socket.write('$command\r\n');
    await _expect(expectedCode);
  }

  Future<void> _expect(int expectedCode) async {
    final hasLine = await _iterator.moveNext().timeout(const Duration(seconds: 20));
    if (!hasLine) {
      throw const OtpEmailException('SMTP server closed the connection.');
    }
    var line = _iterator.current;
    while (line.length >= 4 && line[3] == '-') {
      final hasNextLine = await _iterator.moveNext().timeout(
        const Duration(seconds: 20),
      );
      if (!hasNextLine) {
        throw const OtpEmailException('SMTP server closed the connection.');
      }
      line = _iterator.current;
    }
    final code = int.tryParse(line.length >= 3 ? line.substring(0, 3) : '');
    if (code != expectedCode) {
      throw const OtpEmailException('SMTP server returned an unexpected response.');
    }
  }

  String _buildMessage({
    required String senderEmail,
    required String recipientEmail,
    required String senderName,
    required String subject,
    required String body,
  }) {
    final safeSenderName = senderName.replaceAll(RegExp(r'[\r\n]'), '');
    final safeSubject = subject.replaceAll(RegExp(r'[\r\n]'), '');
    final escapedBody = body.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
    return 'From: $safeSenderName <$senderEmail>\r\n'
        'To: <$recipientEmail>\r\n'
        'Subject: $safeSubject\r\n'
        'Content-Type: text/plain; charset=utf-8\r\n'
        '\r\n'
        '$escapedBody\r\n'
        '.\r\n';
  }
}

class _SmtpConfig {
  const _SmtpConfig({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.senderEmail,
    required this.senderName,
    required this.useSsl,
    required this.useStartTls,
  });

  final String host;
  final int port;
  final String username;
  final String password;
  final String senderEmail;
  final String senderName;
  final bool useSsl;
  final bool useStartTls;

  factory _SmtpConfig.fromEnvironment(Map<String, String> env) {
    final host = _required(env, 'SMTP_HOST');
    final username = _required(env, 'SMTP_USERNAME');
    final password = _required(env, 'SMTP_PASSWORD');
    final senderEmail = _required(env, 'SMTP_SENDER_EMAIL');
    final port = int.tryParse(env['SMTP_PORT'] ?? '') ?? 587;
    final senderName = env['SMTP_SENDER_NAME']?.trim().isEmpty == false
        ? env['SMTP_SENDER_NAME']!.trim()
        : 'Rynex';
    final useSsl = (env['SMTP_USE_SSL'] ?? 'false').toLowerCase() == 'true';
    final useStartTls = (env['SMTP_USE_STARTTLS'] ?? 'true').toLowerCase() ==
        'true';

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(senderEmail)) {
      throw const OtpEmailException('SMTP sender email is invalid.');
    }

    return _SmtpConfig(
      host: host,
      port: port,
      username: username,
      password: password,
      senderEmail: senderEmail,
      senderName: senderName,
      useSsl: useSsl,
      useStartTls: useStartTls && !useSsl,
    );
  }

  static String _required(Map<String, String> env, String key) {
    final value = env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw OtpEmailException('$key is not configured.');
    }
    return value;
  }
}
