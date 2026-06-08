import 'package:flutter/material.dart';

import '../../domain/entities/local_user.dart';
import '../drawing/drawing_canvas.dart';
import '../notes/notes_screen.dart';
import '../shared/account_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.currentUser,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
    super.key,
  });

  final LocalUser currentUser;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _drawingKey = GlobalKey<DrawingCanvasState>();
  int _selectedIndex = 0;

  Future<void> _showAccountSwitcher() async {
    await showModalBottomSheet<void>(
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
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: AccountAvatar(user: widget.currentUser),
                title: Text(
                  widget.currentUser.name.isEmpty
                      ? widget.currentUser.email
                      : widget.currentUser.name,
                ),
                subtitle: Text(widget.currentUser.email),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.logout)),
                title: const Text('Log out'),
                subtitle: const Text('Return to local account unlock.'),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDrawing = _selectedIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDrawing ? 'Drawing • ${widget.currentUser.email}' : 'Notes',
        ),
        actions: [
          IconButton(
            tooltip: 'Account',
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
