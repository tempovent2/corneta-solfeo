import '../models/note.dart';

/// Servicio específico para corneta / trompeta en Sib
class TrumpetService {
  /// Combinaciones de pistones para trompeta/corneta en Sib
  /// Clave: MIDI number escrito (C4 = 60)
  /// Valor: lista de pistones (1, 2, 3)
  static final Map<int, List<int>> _fingerings = {
    // Octava baja
    54: [1, 2, 3], // F#3 / Gb3
    55: [1, 3],    // G3
    56: [2, 3],    // G#3 / Ab3
    57: [1, 2],    // A3
    58: [1],       // A#3 / Bb3
    59: [2],       // B3
    60: [],        // C4 (Do escrito)
    61: [1, 2, 3], // C#4
    62: [1, 3],    // D4
    63: [2, 3],    // D#4 / Eb4
    64: [1, 2],    // E4
    65: [1],       // F4
    66: [2],       // F#4
    67: [],        // G4
    68: [2, 3],    // G#4
    69: [1, 2],    // A4
    70: [1],       // A#4 / Bb4
    71: [2],       // B4
    72: [],        // C5
    73: [1, 2],    // C#5
    74: [1],       // D5
    75: [2],       // D#5
    76: [],        // E5
    77: [1],       // F5
    78: [2],       // F#5
    79: [],        // G5
    80: [2, 3],    // G#5
    81: [1, 2],    // A5
    82: [1],       // Bb5
    83: [2],       // B5
    84: [],        // C6
  };

  /// Devuelve los pistones a pulsar para una nota escrita
  static List<int> getFingerings(MusicalNote note) {
    if (note.isRest) return [];
    final midi = note.midiNumber;
    return _fingerings[midi] ?? [];
  }

  /// Texto legible de digitación
  static String fingeringText(MusicalNote note) {
    final f = getFingerings(note);
    if (f.isEmpty) return 'Abierto (0)';
    return f.join('-');
  }

  /// Descripción completa
  static String description(MusicalNote note, {bool useSolfege = true}) {
    if (note.isRest) return 'Silencio';
    final name = note.displayName(useSolfege: useSolfege);
    final dig = fingeringText(note);
    return '$name  →  $dig';
  }

  /// Genera una nota aleatoria dentro del rango típico de corneta
  static MusicalNote randomNoteInRange({
    int minMidi = 55, // G3
    int maxMidi = 79, // G5
    NoteDuration duration = NoteDuration.quarter,
  }) {
    final midi = minMidi + (DateTime.now().millisecondsSinceEpoch % (maxMidi - minMidi + 1));
    return _fromMidi(midi, duration);
  }

  static MusicalNote _fromMidi(int midi, NoteDuration duration) {
    int octave = (midi ~/ 12) - 1;
    int pc = midi % 12;
    NoteName name;
    Accidental acc = Accidental.none;

    switch (pc) {
      case 0: name = NoteName.c; break;
      case 1: name = NoteName.c; acc = Accidental.sharp; break;
      case 2: name = NoteName.d; break;
      case 3: name = NoteName.e; acc = Accidental.flat; break; // preferimos bemoles
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
      duration: duration,
    );
  }
}
