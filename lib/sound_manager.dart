// lib/sound_manager.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart';

/// 게임 전역 사운드 매니저 (audioplayers ^6.x)
class SoundManager {
  static final AudioPlayer _bgm = AudioPlayer();
  static String? _currentBgm; // 현재 세팅된 BGM 파일명
  static bool _muted = false;

  static bool get isMuted => _muted;

  static Future<void> _initOnce() async {
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setVolume(_muted ? 0.0 : 1.0);
  }

  /// 내부 공통: 주어진 파일을 루프로 "확실히" 재생
  static Future<void> _startLoop(String file, {bool force = false}) async {
    await _initOnce();

    // 1. 현재 재생 중인 BGM과 같고, 실제로 재생 중이라면 건너뜀 (끊김 방지)
    if (!force && _currentBgm == file && _bgm.state == PlayerState.playing) {
      return;
    }

    // 2. 다른 곡이거나 멈춰있다면 정지 후 재설정
    await _bgm.stop();
    _currentBgm = file;

    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setVolume(_muted ? 0.0 : 1.0);

    // ▼▼▼ [핵심 수정] resume() 대신 play() 사용! ▼▼▼
    // play()는 소스 설정과 재생을 동시에 처리하며, 멈춘 상태에서도 확실하게 시작합니다.
    await _bgm.play(AssetSource('audio/$file'));
  }

  static Future<void> requestWelcomeLoop() => _startLoop('welcome.mp3');

  static Future<void> requestMainLoop() => _startLoop('main.mp3');

  static Future<void> forceMainLoop() => _startLoop('main.mp3', force: true);

  static Future<void> stopBgm() async {
    await _bgm.stop();
  }

  static Future<void> toggleMute() async {
    _muted = !_muted;
    await _bgm.setVolume(_muted ? 0.0 : 1.0);
  }


  static final List<AudioPlayer> _sfxPlayers = [];
  static AudioPlayer? _monkeyPlayer;

  static Future<void> playSfxSafe(String file, {double volume = 1.0}) async {
    if (_muted) return;

    try {
      final p = AudioPlayer();
      _sfxPlayers.add(p);

      await p.setReleaseMode(ReleaseMode.release);
      await p.setVolume(volume.clamp(0.0, 1.0));

      p.onPlayerComplete.listen((_) async {
        await p.dispose();
        _sfxPlayers.remove(p);
      });

      await p.play(AssetSource('audio/$file'));
    } catch (e) {
      debugPrint('[SoundManager] SFX play failed: $file / $e');
    }
  }

  // ▲▲▲ [추가 끝] ▲▲▲

  // ───────────────────────────────────────────────────────────
  //             🔒 안전한 효과음 재생 유틸
  // ───────────────────────────────────────────────────────────

  /// 에셋 존재 여부 확인 (assets/ 접두어 자동 부착)
  static Future<bool> _assetExists(String relPathFromAssets) async {
    try {
      await rootBundle.load('assets/$relPathFromAssets');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> playMonkeySfx() async {
    if (_muted) return;

    try {
      await stopMonkeySfx(restartBgm: false);

      _monkeyPlayer = AudioPlayer();
      await _monkeyPlayer!.setReleaseMode(ReleaseMode.stop);
      await _monkeyPlayer!.setVolume(0.8);

      _monkeyPlayer!.onPlayerComplete.listen((_) async {
        await stopMonkeySfx();
      });

      await _monkeyPlayer!.play(AssetSource('audio/monkey_sound.mp3'));

      Future.delayed(const Duration(milliseconds: 300), () {
        forceMainLoop();
      });
    } catch (e) {
      debugPrint('[SoundManager] Monkey SFX play failed: $e');
      forceMainLoop();
    }
  }

  static Future<void> stopMonkeySfx({bool restartBgm = true}) async {
    try {
      if (_monkeyPlayer != null) {
        await _monkeyPlayer!.stop();
        await _monkeyPlayer!.dispose();
        _monkeyPlayer = null;
      }
    } catch (e) {
      debugPrint('[SoundManager] Monkey SFX stop failed: $e');
    }

    if (restartBgm && !_muted) {
      forceMainLoop();
    }
  }

  /// 효과음 1회 재생(폴백): primary 없으면 fallback 시도, 그것도 없으면 무음
  static Future<void> playSfxWithFallback(String primary, {
    String? fallback,
    double volume = 1.0,
  }) async {
    final relPrimary = 'audio/$primary';
    if (await _assetExists(relPrimary)) {
      return playSfxSafe(primary, volume: volume);
    }
    if (fallback != null) {
      final relFallback = 'audio/$fallback';
      if (await _assetExists(relFallback)) {
        return playSfxSafe(fallback, volume: volume);
      }
    }
    debugPrint('[SoundManager] SFX not found: $primary'
        '${fallback != null ? ' (and fallback: $fallback)' : ''}. Silenced.');
  }

  static Future<void> playSfx(String file, {double volume = 1.0}) async {
    final p = AudioPlayer();
    await p.setReleaseMode(ReleaseMode.stop);
    await p.setVolume(_muted ? 0.0 : volume.clamp(0.0, 1.0));
    await p.play(AssetSource('audio/$file'));
  }
}

class SoundLifecycleObserver with WidgetsBindingObserver {
  SoundLifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SoundManager.stopBgm(); // 앱 백그라운드 시 즉시 정지
    } else if (state == AppLifecycleState.resumed) {
      // 복귀 시 재개하지 않음 (심사 요구사항)
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}