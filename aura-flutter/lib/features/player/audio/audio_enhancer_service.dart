import 'dart:async';

enum AudioEnhancementMode {
  off,
  dialogueBoost,
  nightMode,
  surroundPassthrough,
  audioNormalizer;

  String get label {
    switch (this) {
      case AudioEnhancementMode.off:
        return 'Standard Audio';
      case AudioEnhancementMode.dialogueBoost:
        return 'Dialogue Boost (+5dB)';
      case AudioEnhancementMode.nightMode:
        return 'Night Mode (DRC Limiter)';
      case AudioEnhancementMode.surroundPassthrough:
        return 'Surround Sound Passthrough (Bitstream)';
      case AudioEnhancementMode.audioNormalizer:
        return 'Dynamic Normalizer (EBU R128)';
    }
  }

  String get description {
    switch (this) {
      case AudioEnhancementMode.off:
        return 'Original uncompressed stream audio mix.';
      case AudioEnhancementMode.dialogueBoost:
        return 'Boosts human vocal frequencies (1.0 kHz - 3.2 kHz) for clear speech.';
      case AudioEnhancementMode.nightMode:
        return 'Dynamic range compression to reduce sudden loud audio peaks.';
      case AudioEnhancementMode.surroundPassthrough:
        return 'Direct bitstream passthrough (Dolby Digital / DTS / AC3) to external AV receivers.';
      case AudioEnhancementMode.audioNormalizer:
        return 'Maintains consistent volume across explosions, dialogue, and quiet scenes.';
    }
  }

  /// MediaKit / FFmpeg audio filter string representation
  String? get mediaKitFilter {
    switch (this) {
      case AudioEnhancementMode.off:
        return null;
      case AudioEnhancementMode.dialogueBoost:
        // Equalizer parametric boost on vocal frequencies
        return 'equalizer=f=2000:width_type=h:width=1500:g=5';
      case AudioEnhancementMode.nightMode:
        // Dynamic Range Compressor (DRC) peak clamping
        return 'acompressor=threshold=-20dB:ratio=4:attack=5:release=50';
      case AudioEnhancementMode.surroundPassthrough:
        // Direct channel mapping for multichannel surround
        return 'surround';
      case AudioEnhancementMode.audioNormalizer:
        // EBU R128 standard two-pass loudnorm/dynaudnorm
        return 'dynaudnorm=f=150:g=15';
    }
  }
}

class AudioEnhancerService {
  AudioEnhancementMode _currentMode = AudioEnhancementMode.off;
  final _modeStreamController =
      StreamController<AudioEnhancementMode>.broadcast();

  AudioEnhancementMode get currentMode => _currentMode;
  Stream<AudioEnhancementMode> get modeStream => _modeStreamController.stream;

  void setEnhancementMode(AudioEnhancementMode mode) {
    _currentMode = mode;
    _modeStreamController.add(_currentMode);
  }

  void dispose() {
    _modeStreamController.close();
  }
}
