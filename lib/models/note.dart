enum NoteName {
  c, d, e, f, g, a, b;

  String get solfege {
    switch (this) {
      case NoteName.c: return 'Do';
      case NoteName.d: return 'Re';
      case NoteName.e: return 'Mi';
      case NoteName.f: return 'Fa';
      case NoteName.g: return 'Sol';
      case NoteName.a: return 'La';
      case NoteName.b: return 'Si';
    }
  }

  String get letter => name.toUpperCase();
}

enum Accidental {
  none,
  sharp,   // ♯
  flat,    // ♭
  natural; // ♮

  String get symbol {
    switch (this) {
      case Accidental.none: return '';
      case Accidental.sharp: return '♯';
      case Accidental.flat: return '♭';
      case Accidental.natural: return '♮';
    }
  }
}

enum NoteDuration {
  whole,      // redonda  (4)
  half,       // blanca   (2)
  quarter,    // negra    (1)
  eighth,     // corchea  (0.5)
  sixteenth;  // semicorchea (0.25)

  double get beats {
    switch (this) {
      case NoteDuration.whole: return 4.0;
      case NoteDuration.half: return 2.0;
      case NoteDuration.quarter: return 1.0;
      case NoteDuration.eighth: return 0.5;
      case NoteDuration.sixteenth: return 0.25;
    }
  }

  String get nameEs {
    switch (this) {
      case NoteDuration.whole: return 'Redonda';
      case NoteDuration.half: return 'Blanca';
      case NoteDuration.quarter: return 'Negra';
      case NoteDuration.eighth: return 'Corchea';
      case NoteDuration.sixteenth: return 'Semicorchea';
    }
  }
}

class MusicalNote {
  final NoteName name;
  final Accidental accidental;
  final int octave; // 4 = middle C region
  final NoteDuration duration;
  final bool isRest;

  const MusicalNote({
    required this.name,
    this.accidental = Accidental.none,
    this.octave = 4,
    this.duration = NoteDuration.quarter,
    this.isRest = false,
  });

  /// Posición en el pentagrama (0 = línea inferior, sube hacia arriba)
  /// Para clave de Sol: Do4 está en el primer espacio inferior (ledger)
  int get staffPosition {
    // Base: Do4 = posición -2 (ledger line abajo)
    // Cada grado de escala sube 1 posición
    final basePositions = {
      NoteName.c: 0,
      NoteName.d: 1,
      NoteName.e: 2,
      NoteName.f: 3,
      NoteName.g: 4,
      NoteName.a: 5,
      NoteName.b: 6,
    };
    int pos = basePositions[name]! + (octave - 4) * 7;
    return pos - 2; // Ajuste para clave de Sol (Mi4 en línea inferior)
  }

  /// Nombre completo con alteración y octava
  String displayName({bool useSolfege = true}) {
    if (isRest) return 'Silencio';
    final base = useSolfege ? name.solfege : name.letter;
    return '$base${accidental.symbol}$octave';
  }

  /// Pitch MIDI aproximado (C4 = 60)
  int get midiNumber {
    final base = {
      NoteName.c: 0,
      NoteName.d: 2,
      NoteName.e: 4,
      NoteName.f: 5,
      NoteName.g: 7,
      NoteName.a: 9,
      NoteName.b: 11,
    }[name]!;
    int midi = 12 + (octave + 1) * 12 + base; // C0 = 12
    if (accidental == Accidental.sharp) midi += 1;
    if (accidental == Accidental.flat) midi -= 1;
    return midi;
  }

  MusicalNote copyWith({
    NoteName? name,
    Accidental? accidental,
    int? octave,
    NoteDuration? duration,
    bool? isRest,
  }) {
    return MusicalNote(
      name: name ?? this.name,
      accidental: accidental ?? this.accidental,
      octave: octave ?? this.octave,
      duration: duration ?? this.duration,
      isRest: isRest ?? this.isRest,
    );
  }
}
