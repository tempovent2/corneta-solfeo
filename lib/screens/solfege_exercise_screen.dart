import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/measure.dart';
import '../widgets/staff_widget.dart';
import '../services/trumpet_service.dart';
import '../services/sound_service.dart';

class SolfegeExerciseScreen extends StatefulWidget {
  const SolfegeExerciseScreen({super.key});

  @override
  State<SolfegeExerciseScreen> createState() => _SolfegeExerciseScreenState();
}

class _SolfegeExerciseScreenState extends State<SolfegeExerciseScreen> {
  List<MusicalNote> _currentNotes = [];
  int _currentIndex = 0;
  int _correct = 0;
  int _total = 0;
  bool _useSolfege = true;
  bool _showAnswer = false;
  int _difficulty = 1; // 1 = fácil, 2 = medio, 3 = difícil
  Timer? _timer;
  int _seconds = 0;
  bool _running = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _generateExercise();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateExercise() {
    final count = 4 + _difficulty * 2;
    final notes = <MusicalNote>[];
    for (int i = 0; i < count; i++) {
      notes.add(TrumpetService.randomNoteInRange(
        minMidi: _difficulty == 1 ? 60 : 55,
        maxMidi: _difficulty == 3 ? 79 : 72,
        duration: NoteDuration.quarter,
      ));
    }
    setState(() {
      _currentNotes = notes;
      _currentIndex = 0;
      _showAnswer = false;
    });
  }

  void _startTimer() {
    _seconds = 0;
    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _running = false;
  }

  void _nextNote({required bool correct}) {
    setState(() {
      _total++;
      if (correct) _correct++;
      _showAnswer = false;
      if (_currentIndex < _currentNotes.length - 1) {
        _currentIndex++;
        // Reproducir la siguiente nota
        if (_soundEnabled && _currentIndex < _currentNotes.length) {
          SoundService.playNote(_currentNotes[_currentIndex]);
        }
      } else {
        _stopTimer();
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    final accuracy = _total == 0 ? 0 : (_correct / _total * 100).round();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Ejercicio terminado!'),
        content: Text(
          'Aciertos: $_correct / $_total\n'
          'Precisión: $accuracy%\n'
          'Tiempo: $_seconds s',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _correct = 0;
                _total = 0;
              });
              _generateExercise();
            },
            child: const Text('Nuevo ejercicio'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentNotes.isNotEmpty ? _currentNotes[_currentIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solfeo · Lectura rápida'),
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
            onPressed: () => setState(() => _useSolfege = !_useSolfege),
          ),
        ],
      ),
      body: Column(
        children: [
          // Controles de dificultad
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Dificultad:'),
                const SizedBox(width: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Fácil')),
                    ButtonSegment(value: 2, label: Text('Medio')),
                    ButtonSegment(value: 3, label: Text('Difícil')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (s) {
                    setState(() => _difficulty = s.first);
                    _generateExercise();
                  },
                ),
                const Spacer(),
                Text('$_correct/$_total'),
              ],
            ),
          ),

          // Pentagrama con la secuencia
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: StaffWidget(
              notes: _currentNotes,
              height: 150,
              highlightIndex: _currentIndex,
              useSolfege: _useSolfege,
              showTimeSignature: false,
            ),
          ),

          const SizedBox(height: 16),

          // Nota actual grande
          if (current != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Nota ${_currentIndex + 1} de ${_currentNotes.length}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showAnswer
                          ? current.displayName(useSolfege: _useSolfege)
                          : '¿Qué nota es?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _showAnswer ? Colors.green.shade800 : Colors.black87,
                      ),
                    ),
                    if (_showAnswer) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Digitación: ${TrumpetService.fingeringText(current)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const Spacer(),

          // Botones de respuesta
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_running)
                  FilledButton.icon(
                    onPressed: () {
                      _startTimer();
                      setState(() {});
                      // Reproducir la primera nota
                      if (_soundEnabled && _currentNotes.isNotEmpty) {
                        SoundService.playNote(_currentNotes[0]);
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Empezar ejercicio'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _showAnswer = true);
                            if (_soundEnabled &&
                                _currentIndex < _currentNotes.length) {
                              SoundService.playNote(
                                  _currentNotes[_currentIndex]);
                            }
                          },
                          child: const Text('Ver respuesta'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _nextNote(correct: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('✓ Correcto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _nextNote(correct: false),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          child: const Text('✗ Fallé'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tiempo: $_seconds s',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _stopTimer();
                    setState(() {
                      _correct = 0;
                      _total = 0;
                    });
                    _generateExercise();
                  },
                  child: const Text('Nuevo ejercicio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
