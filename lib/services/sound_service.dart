import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../models/note.dart';

/// Genera y reproduce tonos simples (ondas seno) para las notas.
/// No necesita archivos de audio externos.
class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static final AudioPlayer _metroPlayer = AudioPlayer();
  static bool _enabled = true;

  static bool get enabled => _enabled;
  static set enabled(bool value) => _enabled = value;

  /// Frecuencia de una nota MIDI (A4 = 440 Hz)
  static double frequencyFromMidi(int midi) {
    return 440.0 * pow(2, (midi - 69) / 12.0);
  }

  /// Reproduce una nota musical
  static Future<void> playNote(MusicalNote note, {double volume = 0.6}) async {
    if (!_enabled || note.isRest) return;

    final freq = frequencyFromMidi(note.midiNumber);
    final durationMs = (note.duration.beats * 400).clamp(150, 1200).toInt();

    await _playTone(freq, durationMs, volume: volume);
  }

  /// Reproduce un tono por frecuencia
  static Future<void> playFrequency(double freq, {int durationMs = 400, double volume = 0.6}) async {
    if (!_enabled) return;
    await _playTone(freq, durationMs, volume: volume);
  }

  /// Click del metrónomo
  static Future<void> playClick({bool accent = false}) async {
    if (!_enabled) return;
    final freq = accent ? 1200.0 : 800.0;
    await _playTone(freq, 40, volume: accent ? 0.7 : 0.45, player: _metroPlayer);
  }

  static Future<void> _playTone(
    double frequency,
    int durationMs, {
    double volume = 0.6,
    AudioPlayer? player,
  }) async {
    final p = player ?? _player;
    try {
      final bytes = _generateSineWaveWav(
        frequency: frequency,
        durationMs: durationMs,
        volume: volume,
      );
      await p.stop();
      await p.play(BytesSource(bytes));
    } catch (e) {
      // Silenciar errores de audio en dispositivos sin salida
    }
  }

  /// Genera un WAV en memoria (PCM 16-bit mono 22050 Hz)
  static Uint8List _generateSineWaveWav({
    required double frequency,
    required int durationMs,
    double volume = 0.6,
  }) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2; // 16-bit
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    var offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt chunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); //  
    buffer.setUint32(offset, 16, Endian.little); // chunk size
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little); // PCM
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little); // mono
    offset += 2;
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, sampleRate * 2, Endian.little); // byte rate
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little); // block align
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little); // bits per sample
    offset += 2;

    // data chunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Samples (con envelope simple para evitar clicks)
    final amplitude = (volume * 30000).clamp(0, 32767);
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Envelope ADSR muy simple
      double env = 1.0;
      final attack = 0.01;
      final release = 0.08;
      final totalSec = durationMs / 1000.0;
      if (t < attack) {
        env = t / attack;
      } else if (t > totalSec - release) {
        env = (totalSec - t) / release;
        if (env < 0) env = 0;
      }
      final sample = (sin(2 * pi * frequency * t) * amplitude * env).round();
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  static Future<void> stop() async {
    await _player.stop();
    await _metroPlayer.stop();
  }

  static Future<void> dispose() async {
    await _player.dispose();
    await _metroPlayer.dispose();
  }
}
