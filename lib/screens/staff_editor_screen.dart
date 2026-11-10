import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/measure.dart';
import '../widgets/staff_widget.dart';
import '../services/trumpet_service.dart';
import '../services/sound_service.dart';

class StaffEditorScreen extends StatefulWidget {
  const StaffEditorScreen({super.key});

  @override
  State<StaffEditorScreen> createState() => _StaffEditorScreenState();
}

class _StaffEditorScreenState extends State<StaffEditorScreen> {
  final List<MusicalNote> _notes = [];
  NoteDuration _selectedDuration = NoteDuration.quarter;
  Accidental _selectedAccidental = Accidental.none;
  bool _useSolfege = true;
  TimeSignature _timeSignature = TimeSignature.common;
  bool _soundEnabled = true;

  void _addNote(NoteName name, {int octave = 4}) {
    final note = MusicalNote(
      name: name,
      accidental: _selectedAccidental,
      octave: octave,
      duration: _selectedDuration,
    );
    setState(() {
      _notes.add(note);
    });
    if (_soundEnabled) {
      SoundService.playNote(note);
    }
  }

  void _addRest() {
    setState(() {
      _notes.add(MusicalNote(
        name: NoteName.c,
        duration: _selectedDuration,
        isRest: true,
      ));
    });
  }

  void _removeLast() {
    if (_notes.isNotEmpty) {
      setState(() => _notes.removeLast());
    }
  }

  void _clear() {
    setState(() => _notes.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de partitura'),
        actions: [
          IconButton(
            icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: _soundEnabled ? 'Silenciar' : 'Activar sonido',
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
                SoundService.enabled = _soundEnabled;
              });
            },
          ),
          IconButton(
            icon: Icon(_useSolfege ? Icons.abc : Icons.music_note),
            tooltip: _useSolfege ? 'Cambiar a letras' : 'Cambiar a solfeo',
            onPressed: () => setState(() => _useSolfege = !_useSolfege),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pentagrama
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            child: StaffWidget(
              notes: _notes,
              height: 160,
              timeSignature: _timeSignature,
              useSolfege: _useSolfege,
            ),
          ),

          // Info de la última nota
          if (_notes.isNotEmpty && !_notes.last.isRest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                TrumpetService.description(_notes.last, useSolfege: _useSolfege),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),

          const Divider(),

          // Selector de duración
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Duración: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: NoteDuration.values.map((d) {
                        final selected = _selectedDuration == d;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(d.nameEs),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedDuration = d),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alteraciones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Text('Alteración: ', style: TextStyle(fontWeight: FontWeight.bold)),
                ...Accidental.values.map((a) {
                  final selected = _selectedAccidental == a;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(a == Accidental.none ? '♮' : a.symbol),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedAccidental = a),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Teclado de notas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Octava 4 (media)
                  _NoteRow(
                    labels: ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'],
                    names: [
                      NoteName.c, NoteName.d, NoteName.e, NoteName.f,
                      NoteName.g, NoteName.a, NoteName.b
                    ],
                    octave: 4,
                    onTap: _addNote,
                  ),
                  const SizedBox(height: 8),
                  // Octava 5
                  _NoteRow(
                    labels: ['Do5', 'Re5', 'Mi5', 'Fa5', 'Sol5', 'La5', 'Si5'],
                    names: [
                      NoteName.c, NoteName.d, NoteName.e, NoteName.f,
                      NoteName.g, NoteName.a, NoteName.b
                    ],
                    octave: 5,
                    onTap: _addNote,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addRest,
                          icon: const Icon(Icons.music_off),
                          label: const Text('Silencio'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _removeLast,
                          icon: const Icon(Icons.undo),
                          label: const Text('Borrar última'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _clear,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Limpiar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final List<String> labels;
  final List<NoteName> names;
  final int octave;
  final void Function(NoteName name, {int octave}) onTap;

  const _NoteRow({
    required this.labels,
    required this.names,
    required this.octave,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ElevatedButton(
              onPressed: () => onTap(names[i], octave: octave),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                labels[i],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      }),
    );
  }
}
