import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/measure.dart';
import '../widgets/staff_widget.dart';
import '../services/trumpet_service.dart';
import '../services/sound_service.dart';

class ScoreViewerScreen extends StatefulWidget {
  final Score score;

  const ScoreViewerScreen({super.key, required this.score});

  @override
  State<ScoreViewerScreen> createState() => _ScoreViewerScreenState();
}

class _ScoreViewerScreenState extends State<ScoreViewerScreen> {
  int _currentMeasure = 0;
  int _currentNoteInMeasure = 0;
  bool _useSolfege = true;
  bool _showFingerings = true;
  bool _soundEnabled = true;

  List<MusicalNote> get _allNotes {
    final list = <MusicalNote>[];
    for (final m in widget.score.measures) {
      list.addAll(m.notes);
    }
    return list;
  }

  MusicalNote? get _currentNote {
    final notes = _allNotes;
    if (notes.isEmpty) return null;
    int idx = 0;
    for (int m = 0; m < widget.score.measures.length; m++) {
      final measureNotes = widget.score.measures[m].notes;
      if (m == _currentMeasure) {
        if (_currentNoteInMeasure < measureNotes.length) {
          return measureNotes[_currentNoteInMeasure];
        }
      }
      idx += measureNotes.length;
    }
    return null;
  }

  void _nextNote() {
    final measures = widget.score.measures;
    if (measures.isEmpty) return;

    setState(() {
      final current = measures[_currentMeasure];
      if (_currentNoteInMeasure < current.notes.length - 1) {
        _currentNoteInMeasure++;
      } else if (_currentMeasure < measures.length - 1) {
        _currentMeasure++;
        _currentNoteInMeasure = 0;
      }
    });
    _playCurrent();
  }

  void _prevNote() {
    setState(() {
      if (_currentNoteInMeasure > 0) {
        _currentNoteInMeasure--;
      } else if (_currentMeasure > 0) {
        _currentMeasure--;
        _currentNoteInMeasure =
            widget.score.measures[_currentMeasure].notes.length - 1;
        if (_currentNoteInMeasure < 0) _currentNoteInMeasure = 0;
      }
    });
    _playCurrent();
  }

  void _playCurrent() {
    if (!_soundEnabled) return;
    final note = _currentNote;
    if (note != null) {
      SoundService.playNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measure = widget.score.measures.isNotEmpty
        ? widget.score.measures[_currentMeasure]
        : Measure();
    final current = _currentNote;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.score.title),
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
            tooltip: 'Cambiar nomenclatura',
            onPressed: () => setState(() => _useSolfege = !_useSolfege),
          ),
          IconButton(
            icon: Icon(
                _showFingerings ? Icons.visibility : Icons.visibility_off),
            tooltip: 'Mostrar digitaciones',
            onPressed: () => setState(() => _showFingerings = !_showFingerings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info del compás
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Compás ${_currentMeasure + 1} / ${widget.score.measures.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  measure.timeSignature.toString(),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Pentagrama del compás actual
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: StaffWidget(
              notes: measure.notes,
              height: 160,
              timeSignature: measure.timeSignature,
              highlightIndex: _currentNoteInMeasure,
              useSolfege: _useSolfege,
            ),
          ),

          const SizedBox(height: 16),

          // Nota actual + digitación
          if (current != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      current.isRest
                          ? 'Silencio'
                          : current.displayName(useSolfege: _useSolfege),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_showFingerings && !current.isRest) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Pistones: ${TrumpetService.fingeringText(current)}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      current.duration.nameEs,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Controles de navegación
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevNote,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _nextNote,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Siguiente'),
                  ),
                ),
              ],
            ),
          ),

          // Lista rápida de todos los compases
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.score.measures.length,
              itemBuilder: (context, index) {
                final selected = index == _currentMeasure;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('C${index + 1}'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _currentMeasure = index;
                        _currentNoteInMeasure = 0;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
