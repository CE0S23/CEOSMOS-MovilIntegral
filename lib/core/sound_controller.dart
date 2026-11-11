import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// One global player. Audio errors are surfaced without interrupting the timer.
class SoundController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  String? _asset;
  String? error;
  bool playing = false;
  bool busy = false;
  bool _disposed = false;
  double volume = .45;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> toggle(String asset) async {
    if (busy) return;
    busy = true;
    error = null;
    _changed();
    try {
      if (playing && _asset == asset) {
        await _player.pause();
        playing = false;
      } else {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(volume);
        await _player.play(AssetSource(asset));
        _asset = asset;
        playing = true;
      }
    } catch (_) {
      playing = false;
      error =
          'No se pudo reproducir el audio. Puedes reintentarlo o continuar en silencio.';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> stop() async {
    while (busy && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_disposed) return;
    try {
      await _player.stop();
    } catch (_) {
      /* Player may not have started yet. */
    }
    playing = false;
    _asset = null;
    _changed();
  }

  Future<void> setVolume(double value) async {
    volume = value;
    try {
      await _player.setVolume(value);
    } catch (_) {
      error = 'No se pudo cambiar el volumen.';
    }
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    _player.dispose();
    super.dispose();
  }
}
