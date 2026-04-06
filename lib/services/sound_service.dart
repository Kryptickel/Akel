import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

// Check if sound is enabled in settings
  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound_alerts_enabled') ?? true;
  }

// Play panic siren sound (simulated with console log on web)
  Future<void> playPanicSiren() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    _logSound('🚨 PANIC SIREN: Loud alert sound playing');

// In production with real audio files:
// await _audioPlayer.play(AssetSource('sounds/siren.mp3'));
  }

// Play alarm sound (for emergency panic alerts)
  Future<void> playAlarm() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    _logSound('🚨 ALARM: Emergency alarm sound playing');

// In production with real audio files:
// await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
  }

// Play success sound
  Future<void> playSuccess() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    _logSound('✅ SUCCESS: Confirmation beep');

// In production:
// await _audioPlayer.play(AssetSource('sounds/success.wav'));
  }

// Play error sound
  Future<void> playError() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    _logSound('❌ ERROR: Alert sound');

// In production:
// await _audioPlayer.play(AssetSource('sounds/error.mp3'));
  }

// Play warning sound
  Future<void> playWarning() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    _logSound('⚠️ WARNING: Caution sound');

// In production:
// await _audioPlayer.play(AssetSource('sounds/warning.wav'));
  }

// Play button click sound
  Future<void> playClick() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    _logSound('🔘 CLICK: Button tap sound');

// In production:
// await _audioPlayer.play(AssetSource('sounds/click.mp3'));
  }

// Log sound events (for debugging and web demo)
  void _logSound(String message) {
    if (kIsWeb) {
// ignore: avoid_print
      print('🔊 SOUND: $message');
    }
  }

// Stop any currently playing sound
  Future<void> stop() async {
// In production:
// await _audioPlayer.stop();
  }

// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
// In production:
// await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

// Dispose
  void dispose() {
// In production:
// _audioPlayer.dispose();
  }
}