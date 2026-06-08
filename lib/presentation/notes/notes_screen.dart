import 'package:flutter/material.dart';

import 'note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Note> _notes = [
    Note(
      id: 'welcome',
      title: 'Welcome to Notes',
      body: 'Capture quick ideas beside your drawing canvas.',
      updatedAt: DateTime.now(),
    ),
  ];

  Future<void> _editNote([Note? note]) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.body ?? '');

    final saved = await showModalBottomSheet<Note>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                note == null ? 'New note' : 'Edit note',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final now = DateTime.now();
                  Navigator.of(context).pop(
                    Note(
                      id: note?.id ?? now.microsecondsSinceEpoch.toString(),
                      title: titleController.text.trim().isEmpty
                          ? 'Untitled note'
                          : titleController.text.trim(),
                      body: bodyController.text.trim(),
                      updatedAt: now,
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save note'),
              ),
            ],
          ),
        );
      },
    );

    titleController.dispose();
    bodyController.dispose();
    if (saved == null) return;

    setState(() {
      final index = _notes.indexWhere((item) => item.id == saved.id);
      if (index == -1) {
        _notes.insert(0, saved);
      } else {
        _notes[index] = saved;
      }
    });
  }

  void _deleteNote(Note note) {
    setState(() => _notes.removeWhere((item) => item.id == note.id));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _notes.isEmpty
            ? const Center(child: Text('No notes yet. Tap + to add one.'))
            : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.note_alt)),
                    title: Text(note.title),
                    subtitle: Text(
                      note.body.isEmpty ? 'No details' : note.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _editNote(note),
                    trailing: IconButton(
                      tooltip: 'Delete note',
                      onPressed: () => _deleteNote(note),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _editNote(),
            icon: const Icon(Icons.add),
            label: const Text('Note'),
          ),
        ),
      ],
    );
  }
}
