import 'package:flutter/material.dart';

import '../../domain/entities/local_user.dart';
import '../drawing/drawing_canvas.dart';
import '../notes/notes_screen.dart';
import '../shared/account_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _drawingKey = GlobalKey<DrawingCanvasState>();
  int _selectedIndex = 0;

  Future<void> _showAccountSwitcher() async {
    final selectedUsername = await showModalBottomSheet<String>(
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
                  title: Text(user.displayName),
                  subtitle: Text(user.username),
                  trailing: user.username == widget.currentUser.username
                      ? const Icon(Icons.check_circle)
                      : null,
                  onTap: () => Navigator.of(context).pop(user.username),
                ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.logout)),
                title: const Text('Log out'),
                subtitle: const Text('Return to account verification.'),
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

    if (selectedUsername == null ||
        selectedUsername == widget.currentUser.username) {
      return;
    }
    widget.onSwitchAccount(selectedUsername);
  }

  @override
  Widget build(BuildContext context) {
    final isDrawing = _selectedIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDrawing ? 'Drawing • ${widget.currentUser.displayName}' : 'Notes',
        ),
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
          if (isDrawing)
            IconButton(
              tooltip: 'Clear canvas',
              onPressed: () => _drawingKey.currentState?.clear(),
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DrawingCanvas(
            key: _drawingKey,
            isDarkMode: widget.isDarkMode,
          ),
          const NotesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.brush_outlined),
            selectedIcon: Icon(Icons.brush),
            label: 'Draw',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}
