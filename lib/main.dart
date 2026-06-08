import 'package:flutter/material.dart';

import 'data/repositories/local_auth_repository.dart';
import 'domain/entities/local_user.dart';
import 'domain/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authStore = LocalAuthRepository();
  await authStore.load();
  runApp(DrawingApp(authStore: authStore));
}

class DrawingApp extends StatefulWidget {
  const DrawingApp({required this.authStore, super.key});

  final AuthRepository authStore;

  @override
  State<DrawingApp> createState() => _DrawingAppState();
}

class _DrawingAppState extends State<DrawingApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.authStore.isDarkMode;
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await widget.authStore.setDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rynex Drawing',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AuthGate(
        authStore: widget.authStore,
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.authStore,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  final AuthRepository authStore;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late String? _signedInEmail;

  @override
  void initState() {
    super.initState();
    _signedInEmail = widget.authStore.currentUserEmail;
  }

  Future<void> _onAuthenticated(String email) async {
    await widget.authStore.setCurrentUser(email);
    setState(() => _signedInEmail = email);
  }

  Future<void> _logout() async {
    await widget.authStore.logout();
    setState(() => _signedInEmail = null);
  }

  @override
  Widget build(BuildContext context) {
    final signedInEmail = _signedInEmail;
    if (signedInEmail == null) {
      return AuthScreen(
        authStore: widget.authStore,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onAuthenticated: _onAuthenticated,
      );
    }

    final currentUser = widget.authStore.currentUser;
    if (currentUser == null) {
      return AuthScreen(
        authStore: widget.authStore,
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        onAuthenticated: _onAuthenticated,
      );
    }

    return DrawingCanvas(
      currentUser: currentUser,
      users: widget.authStore.users,
      isDarkMode: widget.isDarkMode,
      onDarkModeChanged: widget.onDarkModeChanged,
      onSwitchAccount: _onAuthenticated,
      onLogout: _logout,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.authStore,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onAuthenticated,
    super.key,
  });

  final AuthRepository authStore;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isPasswordHidden = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      if (_isSignUp) {
        await widget.authStore.signUp(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        );
      } else {
        await widget.authStore.login(
          email: email,
          password: _passwordController.text,
        );
      }
      widget.onAuthenticated(email);
    } on LocalAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rynex'),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Use light mode' : 'Use dark mode',
            onPressed: () => widget.onDarkModeChanged(!widget.isDarkMode),
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.draw_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSignUp ? 'Create your local account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account is saved on this device only.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter your name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _isPasswordHidden
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _isPasswordHidden = !_isPasswordHidden,
                            ),
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: _isSubmitting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isSignUp ? 'Sign up' : 'Log in'),
                        ),
                      ),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Log in'
                              : 'Need an account? Sign up',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({required this.user, this.radius = 20, super.key});

  final LocalUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = user.avatarMaterialColor;
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        user.initials,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(backgroundColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    required this.currentUser,
    required this.users,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onSwitchAccount,
    required this.onLogout,
    super.key,
  });

  final LocalUser currentUser;
  final List<LocalUser> users;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onSwitchAccount;
  final VoidCallback onLogout;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser.email != widget.currentUser.email) {
      _strokes = [];
      _currentStroke = [];
    }
  }

  Future<void> _showAccountSwitcher() async {
    final selectedEmail = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'Switch account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final user in widget.users)
                ListTile(
                  leading: AccountAvatar(user: user),
                  title: Text(user.name.isEmpty ? user.email : user.name),
                  subtitle: Text(user.email),
                  trailing: user.email == widget.currentUser.email
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => Navigator.of(context).pop(user.email),
                ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt)),
                title: const Text('Use another account'),
                subtitle: const Text('Log out, then sign up or log in.'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onLogout();
                },
              ),
            ],
          ),
        );
      },
    );

    if (selectedEmail == null || selectedEmail == widget.currentUser.email) {
      return;
    }
    widget.onSwitchAccount(selectedEmail);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canvasColor = widget.isDarkMode
        ? const Color(0xFF101318)
        : Colors.white;
    final strokeColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        title: Text('Drawing • ${widget.currentUser.email}'),
        actions: [
          IconButton(
            tooltip: 'Switch account',
            onPressed: _showAccountSwitcher,
            icon: AccountAvatar(user: widget.currentUser, radius: 16),
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Use light mode' : 'Use dark mode',
            onPressed: () => widget.onDarkModeChanged(!widget.isDarkMode),
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Clear canvas',
            onPressed: () => setState(() {
              _strokes = [];
              _currentStroke = [];
            }),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke = [..._currentStroke, details.localPosition];
              });
            },
            onPanEnd: (_) {
              setState(() {
                if (_currentStroke.length > 1) {
                  _strokes.add(List.from(_currentStroke));
                }
                _currentStroke = [];
              });
            },
            child: CustomPaint(
              painter: CanvasPainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
                strokeColor: strokeColor,
              ),
              size: Size.infinite,
            ),
          ),
          if (_strokes.isEmpty && _currentStroke.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Draw anywhere to start',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CanvasPainter extends CustomPainter {
  const CanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeColor,
  });

  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    _drawStroke(canvas, currentStroke, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.strokeColor != strokeColor;
  }
}
