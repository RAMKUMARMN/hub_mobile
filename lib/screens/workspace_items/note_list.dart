// lib/screens/workspace_items/note_list.dart
import 'package:flutter/material.dart';
import '../../../models/workspace_items/note.dart';
import 'note_card.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onNoteTap;
  final Function(Note) onNoteDelete;

  const NoteList({
    super.key,
    required this.notes,
    required this.onNoteTap,
    required this.onNoteDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a note',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onTap: () => onNoteTap(note),
          onDelete: () => onNoteDelete(note),
        );
      },
    );
  }
}