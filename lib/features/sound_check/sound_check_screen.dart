import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

/// Shared listening volume (0–100), set on the sound check, adjustable in the
/// Listening header.
final listeningVolume = ValueNotifier<double>(80);

/// Headphone check before Listening: plays a test chime, volume slider.
class SoundCheckScreen extends ConsumerStatefulWidget {
  const SoundCheckScreen({super.key});

  @override
  ConsumerState<SoundCheckScreen> createState() => _SoundCheckScreenState();
}

class _SoundCheckScreenState extends ConsumerState<SoundCheckScreen> {
  Player? _player;
  bool _playing = false;
  String? _error;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    try {
      final player = _player ??= Player();
      final file = File(p.join(ref.read(appPathsProvider).root.path, 'sound_check.wav'));
      if (!await file.exists()) await file.writeAsBytes(chimeWav());
      await player.setVolume(listeningVolume.value);
      await player.open(Media(file.uri.toString()));
      setState(() {
        _playing = true;
        _error = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      if (mounted) setState(() => _playing = false);
    } catch (e) {
      setState(() => _error = 'Audio could not be played: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    return Scaffold(
      body: CenterCard(
        maxWidth: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.headphones, size: 32),
              SizedBox(width: 12),
              Text('Sound check', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            const Text(
              'Put on your headphones. When the Listening section starts, the recording plays automatically '
              'and cannot be paused or replayed.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.panel,
              child: Column(children: [
                Row(children: [
                  FilledButton.icon(
                    key: const Key('play-tone'),
                    onPressed: _playing ? null : _play,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_playing ? 'PLAYING…' : 'PLAY SOUND'),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Press the button and check that you can hear the sound clearly.')),
                ]),
                const SizedBox(height: 16),
                ValueListenableBuilder<double>(
                  valueListenable: listeningVolume,
                  builder: (context, v, _) => Row(children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: v,
                        min: 0,
                        max: 100,
                        onChanged: (x) {
                          listeningVolume.value = x;
                          _player?.setVolume(x);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                    SizedBox(width: 44, child: Text('${v.round()}%')),
                  ]),
                ),
              ]),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            const Text(
              'If you cannot hear the sound, raise your hand now.',
              style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('sound-ok'),
                onPressed: exam.confirmSoundCheck,
                child: const Text('SOUND IS OK – START LISTENING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 4-note chime (F4 A4 C5 F5) as a 16-bit mono WAV, like the web sound check.
Uint8List chimeWav() {
  const rate = 22050;
  const total = 2.0;
  final n = (rate * total).round();
  final samples = Float64List(n);
  const notes = [(349.23, 0.0, 0.45), (440.0, 0.22, 0.45), (523.25, 0.44, 0.5), (698.46, 0.66, 1.2)];
  for (final (freq, start, dur) in notes) {
    final s0 = (start * rate).round();
    final len = (dur * rate).round();
    for (var i = 0; i < len && s0 + i < n; i++) {
      final t = i / rate;
      final env = math.min(1.0, t / 0.03) * math.exp(-4 * t / dur);
      samples[s0 + i] += 0.35 * env * math.sin(2 * math.pi * freq * t) +
          0.1 * env * math.sin(4 * math.pi * freq * t);
    }
  }
  final data = ByteData(44 + n * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}
