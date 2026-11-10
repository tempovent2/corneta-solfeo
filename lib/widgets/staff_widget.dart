import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/measure.dart';

class StaffWidget extends StatelessWidget {
  final List<MusicalNote> notes;
  final double height;
  final bool showClef;
  final bool showTimeSignature;
  final TimeSignature timeSignature;
  final int? highlightIndex;
  final bool useSolfege;

  const StaffWidget({
    super.key,
    required this.notes,
    this.height = 180,
    this.showClef = true,
    this.showTimeSignature = true,
    this.timeSignature = TimeSignature.common,
    this.highlightIndex,
    this.useSolfege = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.white,
      child: CustomPaint(
        painter: _StaffPainter(
          notes: notes,
          showClef: showClef,
          showTimeSignature: showTimeSignature,
          timeSignature: timeSignature,
          highlightIndex: highlightIndex,
          useSolfege: useSolfege,
        ),
      ),
    );
  }
}

class _StaffPainter extends CustomPainter {
  final List<MusicalNote> notes;
  final bool showClef;
  final bool showTimeSignature;
  final TimeSignature timeSignature;
  final int? highlightIndex;
  final bool useSolfege;

  _StaffPainter({
    required this.notes,
    required this.showClef,
    required this.showTimeSignature,
    required this.timeSignature,
    this.highlightIndex,
    required this.useSolfege,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final lineSpacing = size.height / 8;
    final topLineY = lineSpacing * 1.5;

    // 5 líneas del pentagrama
    for (int i = 0; i < 5; i++) {
      final y = topLineY + i * lineSpacing;
      canvas.drawLine(Offset(20, y), Offset(size.width - 10, y), paint);
    }

    double x = 30;

    // Clave de Sol (simplificada)
    if (showClef) {
      final clefPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '𝄞',
          style: TextStyle(fontSize: 48, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, topLineY - 10));
      x += 45;
    }

    // Compás
    if (showTimeSignature) {
      final tsPainter = TextPainter(
        text: TextSpan(
          text: '${timeSignature.beats}\n${timeSignature.beatUnit}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 0.9,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tsPainter.layout();
      tsPainter.paint(canvas, Offset(x, topLineY + lineSpacing * 0.8));
      x += 35;
    }

    // Notas
    final noteSpacing = 38.0;
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final isHighlight = highlightIndex == i;

      if (note.isRest) {
        _drawRest(canvas, x, topLineY, lineSpacing, note.duration, isHighlight);
      } else {
        _drawNote(canvas, x, topLineY, lineSpacing, note, isHighlight);
      }

      // Nombre debajo
      final namePainter = TextPainter(
        text: TextSpan(
          text: note.displayName(useSolfege: useSolfege),
          style: TextStyle(
            fontSize: 11,
            color: isHighlight ? Colors.red : Colors.black87,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(
        canvas,
        Offset(x - namePainter.width / 2 + 6, topLineY + lineSpacing * 5.2),
      );

      x += noteSpacing;
      if (x > size.width - 40) break;
    }
  }

  void _drawNote(Canvas canvas, double x, double topY, double spacing,
      MusicalNote note, bool highlight) {
    final pos = note.staffPosition;
    // pos 0 = línea inferior (Mi4 en clave de Sol)
    final y = topY + (4 - pos) * (spacing / 2);

    final paint = Paint()
      ..color = highlight ? Colors.red : Colors.black
      ..style = PaintingStyle.fill;

    // Cabeza de nota (elipse)
    final headRect = Rect.fromCenter(
      center: Offset(x + 6, y),
      width: 14,
      height: 10,
    );
    canvas.drawOval(headRect, paint);

    // Plica (stem)
    if (note.duration != NoteDuration.whole) {
      final stemPaint = Paint()
        ..color = highlight ? Colors.red : Colors.black
        ..strokeWidth = 1.5;
      final stemUp = pos < 4; // arriba si está en la mitad inferior
      if (stemUp) {
        canvas.drawLine(
          Offset(x + 13, y),
          Offset(x + 13, y - spacing * 2.5),
          stemPaint,
        );
      } else {
        canvas.drawLine(
          Offset(x - 1, y),
          Offset(x - 1, y + spacing * 2.5),
          stemPaint,
        );
      }
    }

    // Alteración
    if (note.accidental != Accidental.none) {
      final accPainter = TextPainter(
        text: TextSpan(
          text: note.accidental.symbol,
          style: TextStyle(
            fontSize: 18,
            color: highlight ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      accPainter.layout();
      accPainter.paint(canvas, Offset(x - 16, y - 12));
    }

    // Líneas adicionales (ledger lines)
    if (pos < 0 || pos > 8) {
      final ledgerPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.2;
      // Simplificado: solo una ledger si es necesario
      if (pos < 0) {
        canvas.drawLine(
          Offset(x - 4, topY + 4 * spacing),
          Offset(x + 16, topY + 4 * spacing),
          ledgerPaint,
        );
      }
    }
  }

  void _drawRest(Canvas canvas, double x, double topY, double spacing,
      NoteDuration duration, bool highlight) {
    final paint = Paint()
      ..color = highlight ? Colors.red : Colors.black
      ..style = PaintingStyle.fill;

    // Silencio de negra simplificado
    final y = topY + spacing * 1.5;
    canvas.drawRect(
      Rect.fromLTWH(x, y, 10, spacing * 1.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StaffPainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.useSolfege != useSolfege;
  }
}
