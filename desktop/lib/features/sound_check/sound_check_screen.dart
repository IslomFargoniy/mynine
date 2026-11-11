import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/web_tokens.dart';

/// Player volume (0–100). The web has no in-app volume control, so this stays
/// at 100 and the candidate uses the Windows volume keys.
final listeningVolume = ValueNotifier<double>(100);

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

  Future<void> _stop() async {
    await _player?.stop();
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final title = exam.currentModule?.title ?? 'Listening';
    // sound-check-modal.tsx: overlay bg-black/70 on top of the module page.
    return Scaffold(
      backgroundColor: WebTokens.pageBackground,
      body: Container(
        color: WebTokens.soundOverlay,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Container(
          width: WebTokens.modalMaxWidth,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TW.gray200),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header: bg-gradient-to-r from-blue-600 to-indigo-600 p-6 text-center
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [WebTokens.gradientFrom, WebTokens.gradientTo]),
              ),
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.headphones, size: 32, color: Colors.white),
                ),
                Text('Sound Check', style: inter(20, weight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('$title — Computer-Delivered IELTS Simulation', style: inter(12, color: TW.blue100)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  'When the Listening section starts, the audio will play automatically and cannot be paused. '
                  'Please check your headphones and play the test sound.',
                  textAlign: TextAlign.center,
                  style: inter(14, color: TW.gray600, height: 1.625),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TW.gray50,
                    border: Border.all(color: TW.gray200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _playing ? TW.blue100 : TW.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_playing ? LucideIcons.volume2 : LucideIcons.volumeX,
                          size: 20, color: _playing ? TW.blue600 : TW.gray500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Audio Sample Test', style: inter(12, weight: FontWeight.w600, color: TW.gray800)),
                        Text(_playing ? 'Playing sample...' : 'Click to test sound',
                            style: inter(11, color: TW.gray500)),
                      ]),
                    ),
                    InkWell(
                      key: const Key('play-tone'),
                      onTap: _playing ? _stop : _play,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: TW.blue600),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_playing ? LucideIcons.square : LucideIcons.play, size: 14, color: TW.blue600),
                          const SizedBox(width: 6),
                          Text(_playing ? 'Stop' : 'Play Tone',
                              style: inter(12, weight: FontWeight.w700, color: TW.blue600)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TW.amber50,
                    border: Border.all(color: const Color(0xCCFEE685)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('⚠️', style: inter(14, weight: FontWeight.w700, height: 1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once the test starts, the audio plays only once. Please set your volume to a comfortable 70-80% level.',
                        style: inter(11, color: TW.amber700),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                // Audio preload status: "Offline Ready" only once the recording is
                // on this computer (it downloads in the background after login).
                ListenableBuilder(
                  listenable: exam,
                  builder: (context, _) => _AudioStatus(ready: exam.audioReady),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: inter(12, color: TW.red600)),
                ],
                const SizedBox(height: 20),
                // Ink paints on the nearest Material: without this one it lands on the
                // Scaffold, underneath the white card, and the button is invisible.
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                  key: const Key('sound-ok'),
                  onTap: () {
                    _player?.stop();
                    exam.confirmSoundCheck();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [WebTokens.gradientFrom, WebTokens.gradientTo]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x402B7FFF), blurRadius: 15, offset: Offset(0, 10))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.circleCheck, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Sound is good, Start Test',
                            overflow: TextOverflow.ellipsis, style: inter(14, weight: FontWeight.w700, color: Colors.white)),
                      ),
                    ]),
                  ),
                ),
                ),
              ]),
            ),
          ]),
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

/// Whether the Listening recording is already stored on this computer.
class _AudioStatus extends StatelessWidget {
  const _AudioStatus({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key(ready ? 'audio-ready' : 'audio-preparing'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready ? TW.emerald50 : TW.gray50,
        border: Border.all(color: ready ? TW.emerald200 : TW.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(ready ? LucideIcons.shieldCheck : LucideIcons.download,
            size: 16, color: ready ? TW.emerald600 : TW.gray500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
              ready
                  ? 'Listening audio is stored on this computer (100% offline ready)'
                  : 'Listening audio is being downloaded to this computer',
              style: inter(11, weight: FontWeight.w600, color: ready ? TW.emerald800 : TW.gray700)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ready ? const Color(0x99A4F4CF) : TW.gray200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(ready ? 'Offline Ready' : 'Preparing audio…',
              style: inter(10, weight: FontWeight.w700, color: ready ? TW.emerald800 : TW.gray700)),
        ),
      ]),
    );
  }
}
