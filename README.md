# Corneta Solfeo · App de lectura para Corneta / Trompeta en Sib

Aplicación Flutter orientada a músicos de banda que tocan **corneta o trompeta en Sib♭**.

## Características (v1.2)

- **Sonido de las notas** (tonos generados, sin necesidad de archivos de audio)
- **Importar partituras MusicXML** (después de escanear un PDF con Opuscan/ClefSnap)
- **Editor de partitura** con reproducción al escribir
- **Pentagrama visual** con clave de Sol
- **Digitaciones de pistones** en tiempo real (Sib)
- **Ejercicios de solfeo / lectura a primera vista** con sonido
- **Tabla completa de digitaciones**
- Nomenclatura: **Do-Re-Mi** o **C-D-E**
- Botón de silencio en todas las pantallas

---

## Cómo compilar el APK con GitHub (recomendado)

1. Crea un repositorio nuevo en GitHub.
2. Sube **toda la carpeta** `corneta_solfeo`.
3. Ve a la pestaña **Actions** → workflow **"Build APK"**.
4. Cuando termine, descarga el artifact `corneta-solfeo-apk`.
5. Dentro está el `app-release.apk`.

También se puede lanzar manualmente con el botón **Run workflow**.

---

## Compilar en tu ordenador

```bash
cd corneta_solfeo
flutter pub get
flutter run
flutter build apk --release
```

---

## Flujo para importar marchas (PDF)

1. Abre el PDF en **Opuscan**, **ClefSnap** o **PlayScore 2**.
2. Exporta como **MusicXML**.
3. En la app → **Importar partitura** → selecciona el archivo.

---

## Notas sobre el sonido

- Los tonos se generan en tiempo real (onda seno).
- No necesitan conexión a internet ni archivos de audio.
- El sonido es básico (no es el timbre real de una corneta), pero sirve perfectamente para reconocer alturas y practicar.
- Puedes silenciarlo con el icono del altavoz en la barra superior.

---

Hecho para músicos de banda.
