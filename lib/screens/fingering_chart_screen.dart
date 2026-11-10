import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/trumpet_service.dart';

class FingeringChartScreen extends StatelessWidget {
  const FingeringChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Notas típicas de corneta desde G3 hasta C6
    final notes = <MusicalNote>[];
    for (int midi = 55; midi <= 84; midi++) {
      notes.add(TrumpetService.randomNoteInRange(minMidi: midi, maxMidi: midi));
    }
    // Mejor: generar de forma ordenada
    final ordered = <MusicalNote>[];
    for (int midi = 55; midi <= 84; midi++) {
      ordered.add(_noteFromMidi(midi));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digitaciones · Corneta Sib'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ordered.length,
        itemBuilder: (context, index) {
          final note = ordered[index];
          final dig = TrumpetService.fingeringText(note);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Text(
                  note.name.solfege.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                note.displayName(useSolfege: true),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              subtitle: Text('Escrito: ${note.displayName(useSolfege: false)}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dig == 'Abierto (0)'
                      ? Colors.blue.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dig,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  MusicalNote _noteFromMidi(int midi) {
    int octave = (midi ~/ 12) - 1;
    int pc = midi % 12;
    NoteName name;
    Accidental acc = Accidental.none;

    switch (pc) {
      case 0: name = NoteName.c; break;
      case 1: name = NoteName.c; acc = Accidental.sharp; break;
      case 2: name = NoteName.d; break;
      case 3: name = NoteName.e; acc = Accidental.flat; break;
      case 4: name = NoteName.e; break;
      case 5: name = NoteName.f; break;
      case 6: name = NoteName.f; acc = Accidental.sharp; break;
      case 7: name = NoteName.g; break;
      case 8: name = NoteName.a; acc = Accidental.flat; break;
      case 9: name = NoteName.a; break;
      case 10: name = NoteName.b; acc = Accidental.flat; break;
      case 11: name = NoteName.b; break;
      default: name = NoteName.c;
    }
    return MusicalNote(
      name: name,
      accidental: acc,
      octave: octave,
      duration: NoteDuration.quarter,
    );
  }
}
