import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/measure.dart';
import '../services/musicxml_importer.dart';
import 'score_viewer_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _loading = false;
  String? _error;
  String? _lastFileName;

  Future<void> _pickMusicXml() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xml', 'musicxml', 'mxl'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      _lastFileName = file.name;

      String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw Exception('No se pudo leer el archivo');
      }

      // Algunos .mxl son ZIP, por simplicidad solo soportamos .xml / .musicxml planos
      if (file.extension?.toLowerCase() == 'mxl') {
        throw Exception(
            'Los archivos .mxl (comprimidos) aún no están soportados.\n'
            'Abre el archivo en MuseScore y expórtalo como MusicXML (.musicxml o .xml).');
      }

      final score = MusicXmlImporter.parse(content, title: file.name);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScoreViewerScreen(score: score),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickPdfInfo() async {
    // Solo informativo: no hacemos OMR real aquí
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar PDF (Reconocimiento óptico)'),
        content: const SingleChildScrollView(
          child: Text(
            'El reconocimiento óptico de partituras (OMR) completo es muy complejo '
            'y requiere modelos de inteligencia artificial pesados.\n\n'
            'Recomendación práctica (la que usan la mayoría de músicos):\n\n'
            '1. Usa una app especializada de OMR:\n'
            '   • Opuscan (Android/iOS)\n'
            '   • ClefSnap\n'
            '   • PlayScore 2\n'
            '   • Audiveris (escritorio, gratuito)\n\n'
            '2. Escanea o importa tu PDF de la marcha.\n'
            '3. Exporta el resultado como MusicXML (.musicxml o .xml).\n'
            '4. Vuelve a esta app y usa el botón "Importar MusicXML".\n\n'
            'Así obtienes la mejor precisión y luego puedes practicar '
            'solfeo y digitaciones aquí con la partitura ya convertida.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar partitura'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Importa una marcha o ejercicio',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Formato recomendado: MusicXML\n'
              '(exportado desde MuseScore, Opuscan, Sibelius, etc.)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _loading ? null : _pickMusicXml,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.music_note),
              label: Text(_loading ? 'Procesando...' : 'Importar MusicXML / .xml'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickPdfInfo,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('¿Tienes un PDF? (cómo convertirlo)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],

            if (_lastFileName != null && _error == null) ...[
              const SizedBox(height: 16),
              Text(
                'Último archivo: $_lastFileName',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],

            const Spacer(),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consejo para marchas de banda',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Abre el PDF en Opuscan o ClefSnap.\n'
                      '2. Corrige los errores de reconocimiento si los hay.\n'
                      '3. Exporta como MusicXML.\n'
                      '4. Importa aquí y practica con digitaciones Sib y solfeo.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
