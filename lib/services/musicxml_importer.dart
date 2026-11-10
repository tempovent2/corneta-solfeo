import 'package:xml/xml.dart';
import '../models/note.dart';
import '../models/measure.dart';

/// Importador básico de MusicXML (parte de una sola voz / un pentagrama).
/// Soporta: notas, silencios, alteraciones, duraciones, compases y armadura.
class MusicXmlImporter {
  /// Parsea un string MusicXML y devuelve una Score.
  static Score parse(String xmlContent, {String title = 'Partitura importada'}) {
    final document = XmlDocument.parse(xmlContent);
    final part = document.findAllElements('part').firstOrNull;
    if (part == null) {
      throw Exception('No se encontró ninguna parte (<part>) en el MusicXML');
    }

    final measures = <Measure>[];
    TimeSignature currentTs = TimeSignature.common;
    int divisions = 1; // divisiones por negra (MusicXML)

    for (final measureElem in part.findElements('measure')) {
      final notes = <MusicalNote>[];

      // Atributos del compás (time, divisions, key...)
      for (final attr in measureElem.findElements('attributes')) {
        final divElem = attr.findElements('divisions').firstOrNull;
        if (divElem != null) {
          divisions = int.tryParse(divElem.innerText) ?? 1;
        }

        final timeElem = attr.findElements('time').firstOrNull;
        if (timeElem != null) {
          final beats = int.tryParse(
                  timeElem.findElements('beats').firstOrNull?.innerText ?? '4') ??
              4;
          final beatType = int.tryParse(
                  timeElem.findElements('beat-type').firstOrNull?.innerText ??
                      '4') ??
              4;
          currentTs = TimeSignature(beats, beatType);
        }
      }

      // Notas y silencios
      for (final noteElem in measureElem.findElements('note')) {
        final isRest = noteElem.findElements('rest').isNotEmpty;
        final isChord = noteElem.findElements('chord').isNotEmpty;
        if (isChord) continue; // ignoramos acordes por simplicidad (una voz)

        final durationDiv = int.tryParse(
                noteElem.findElements('duration').firstOrNull?.innerText ??
                    '$divisions') ??
            divisions;

        final duration = _durationFromDivisions(durationDiv, divisions);

        if (isRest) {
          notes.add(MusicalNote(
            name: NoteName.c,
            duration: duration,
            isRest: true,
          ));
          continue;
        }

        final pitchElem = noteElem.findElements('pitch').firstOrNull;
        if (pitchElem == null) continue;

        final step = pitchElem.findElements('step').firstOrNull?.innerText ?? 'C';
        final octave =
            int.tryParse(pitchElem.findElements('octave').firstOrNull?.innerText ?? '4') ??
                4;
        final alter =
            int.tryParse(pitchElem.findElements('alter').firstOrNull?.innerText ?? '0') ??
                0;

        final name = _stepToNoteName(step);
        Accidental accidental = Accidental.none;
        if (alter == 1) accidental = Accidental.sharp;
        if (alter == -1) accidental = Accidental.flat;
        if (alter == 2) accidental = Accidental.sharp; // dobles se simplifican
        if (alter == -2) accidental = Accidental.flat;

        // También miramos <accidental> explícito
        final accElem = noteElem.findElements('accidental').firstOrNull?.innerText;
        if (accElem == 'sharp') accidental = Accidental.sharp;
        if (accElem == 'flat') accidental = Accidental.flat;
        if (accElem == 'natural') accidental = Accidental.natural;

        notes.add(MusicalNote(
          name: name,
          accidental: accidental,
          octave: octave,
          duration: duration,
        ));
      }

      if (notes.isNotEmpty) {
        measures.add(Measure(notes: notes, timeSignature: currentTs));
      }
    }

    if (measures.isEmpty) {
      measures.add(Measure(timeSignature: currentTs));
    }

    return Score(
      title: title,
      measures: measures,
      isBbTransposing: true,
    );
  }

  static NoteName _stepToNoteName(String step) {
    switch (step.toUpperCase()) {
      case 'C':
        return NoteName.c;
      case 'D':
        return NoteName.d;
      case 'E':
        return NoteName.e;
      case 'F':
        return NoteName.f;
      case 'G':
        return NoteName.g;
      case 'A':
        return NoteName.a;
      case 'B':
        return NoteName.b;
      default:
        return NoteName.c;
    }
  }

  static NoteDuration _durationFromDivisions(int durationDiv, int divisions) {
    // durationDiv / divisions = beats de negra
    final beats = durationDiv / divisions;
    if (beats >= 3.5) return NoteDuration.whole;
    if (beats >= 1.5) return NoteDuration.half;
    if (beats >= 0.75) return NoteDuration.quarter;
    if (beats >= 0.4) return NoteDuration.eighth;
    return NoteDuration.sixteenth;
  }
}
