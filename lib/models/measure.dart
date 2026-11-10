import 'note.dart';

class TimeSignature {
  final int beats;   // numerador
  final int beatUnit; // denominador (4 = negra, 8 = corchea...)

  const TimeSignature(this.beats, this.beatUnit);

  static const common = TimeSignature(4, 4);
  static const threeFour = TimeSignature(3, 4);
  static const twoFour = TimeSignature(2, 4);
  static const sixEight = TimeSignature(6, 8);

  @override
  String toString() => '$beats/$beatUnit';
}

class Measure {
  final List<MusicalNote> notes;
  final TimeSignature timeSignature;

  Measure({
    List<MusicalNote>? notes,
    this.timeSignature = TimeSignature.common,
  }) : notes = notes ?? [];

  double get totalBeats {
    return notes.fold(0.0, (sum, n) => sum + n.duration.beats);
  }

  bool get isComplete {
    return totalBeats >= timeSignature.beats;
  }

  Measure copyWith({
    List<MusicalNote>? notes,
    TimeSignature? timeSignature,
  }) {
    return Measure(
      notes: notes ?? List.from(this.notes),
      timeSignature: timeSignature ?? this.timeSignature,
    );
  }
}

class Score {
  final String title;
  final List<Measure> measures;
  final int keySignature; // número de sostenidos (+) o bemoles (-)
  final bool isBbTransposing; // true = instrumento en Sib

  Score({
    this.title = 'Nueva partitura',
    List<Measure>? measures,
    this.keySignature = 0,
    this.isBbTransposing = true,
  }) : measures = measures ?? [Measure()];

  /// Transpone una nota escrita a sonido real (para Sib: baja 1 tono)
  MusicalNote toConcertPitch(MusicalNote written) {
    if (!isBbTransposing) return written;
    // Sib suena 1 tono más grave que escrito
    // Do escrito → Sib sonido
    int midi = written.midiNumber - 2;
    return _midiToNote(midi, written.duration, written.isRest);
  }

  /// Transpone de sonido real a escrito (para el instrumentista)
  MusicalNote toWrittenPitch(MusicalNote concert) {
    if (!isBbTransposing) return concert;
    int midi = concert.midiNumber + 2;
    return _midiToNote(midi, concert.duration, concert.isRest);
  }

  MusicalNote _midiToNote(int midi, NoteDuration duration, bool isRest) {
    if (isRest) {
      return MusicalNote(
        name: NoteName.c,
        duration: duration,
        isRest: true,
      );
    }
    int octave = (midi ~/ 12) - 1;
    int pc = midi % 12;
    NoteName name;
    Accidental acc = Accidental.none;

    switch (pc) {
      case 0: name = NoteName.c; break;
      case 1: name = NoteName.c; acc = Accidental.sharp; break;
      case 2: name = NoteName.d; break;
      case 3: name = NoteName.d; acc = Accidental.sharp; break;
      case 4: name = NoteName.e; break;
      case 5: name = NoteName.f; break;
      case 6: name = NoteName.f; acc = Accidental.sharp; break;
      case 7: name = NoteName.g; break;
      case 8: name = NoteName.g; acc = Accidental.sharp; break;
      case 9: name = NoteName.a; break;
      case 10: name = NoteName.a; acc = Accidental.sharp; break;
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
