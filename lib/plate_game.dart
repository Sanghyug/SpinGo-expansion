// lib/plate_game.dart
import 'dart:async' as async;
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'components/pole.dart';
import 'components/plate.dart';
import 'components/bowl.dart';
import 'components/big_plate.dart';
import 'components/monkey.dart';
import 'components/elephant.dart';
import 'levels.dart';
import 'sound_manager.dart';
import 'score_manager.dart';
import 'language_manager.dart';
import 'l10n.dart';
import 'package:flame/text.dart';
import 'dart:ui' as ui;

enum BubbleTailDirection {
  left,
  right,
}

late final TextPaint koreanText;

Future<void> initFonts() async {
  try {
    final fontData = await rootBundle.load(
        'assets/fonts/NotoSansKR-Regular.ttf');
    final loader = FontLoader('NotoSansKR')
      ..addFont(Future.value(fontData));
    await loader.load();
    koreanText = TextPaint(
      style: const TextStyle(
          fontFamily: 'NotoSansKR', color: ui.Color(0xFFFFFFFF), fontSize: 28),
    );
  } catch (e) {
    debugPrint('[SpinGo] ⚠️ Font load failed: $e');
  }
}

typedef TrayPlate = BigPlate;

class MathOverlay extends StatelessWidget {
  static const id = 'MathOverlay';
  final PlateSpinGame game;

  const MathOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: game.problemNotifier,
      builder: (context, problem, _) {
        if (problem.isEmpty) return const SizedBox.shrink();
        return Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    // ✅ Deprecated 해결
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amberAccent, width: 2),
                  ),
                  child: Text(problem, style: const TextStyle(fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
                ),
                const SizedBox(height: 5),
                ValueListenableBuilder<double>(
                  valueListenable: game.timerNotifier,
                  builder: (context, timerVal, _) {
                    return SizedBox(width: 200,
                        child: LinearProgressIndicator(
                            value: timerVal, minHeight: 5));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 리더보드
// ──────────────────────────────────────────────────────────────
class LeaderboardOverlay extends StatelessWidget {
  static const id = 'LeaderboardOverlay';
  final PlateSpinGame game;

  const LeaderboardOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScoreEntry>>(
      future: ScoreManager.load(),
      builder: (context, snap) {
        final entries = (snap.data ?? const <ScoreEntry>[]);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(L10n.tr('leaderboard_title'),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (!snap.hasData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(),
                      )
                    else
                      ...List.generate(entries.length, (i) {
                        final e = entries[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 32, child: Text('${i + 1}.')),
                              Expanded(
                                  child: Text(e.name,
                                      overflow: TextOverflow.ellipsis)),
                              Text('${e.score}'),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          game.overlays.remove(LeaderboardOverlay.id);
                          game.overlays.add(GameOverOverlay.id);
                          game.pauseEngine();
                        },
                        child: Text(L10n.tr('confirm')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 이름 입력
// ──────────────────────────────────────────────────────────────
class NameEntryOverlay extends StatefulWidget {
  static const id = 'NameEntryOverlay';
  final PlateSpinGame game;

  const NameEntryOverlay({super.key, required this.game});

  @override
  State<NameEntryOverlay> createState() => _NameEntryOverlayState();
}

class _NameEntryOverlayState extends State<NameEntryOverlay> {
  final _controller = TextEditingController(text: 'me');
  String? _error;
  final _focusNode = FocusNode();

  bool _valid(String s) {
    final runes = s.runes.toList();
    final isKorean = runes.any((cp) => (cp >= 0xAC00 && cp <= 0xD7A3));
    if (isKorean) return runes.length <= 5;
    final ascii = RegExp(r'^[A-Za-z0-9 ]{1,12}$');
    return ascii.hasMatch(s);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L10n.tr('congrats'),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(L10n.tr('enter_name_hint'))),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  maxLength: 12,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.black54,
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  onTap: () {
                    _focusNode.requestFocus();
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = _controller.text.trim();
                      if (name.isEmpty || !_valid(name)) {
                        setState(() =>
                        _error = L10n.tr('ai_tip_invalid_name'));
                        return;
                      }
                      await ScoreManager.addIfTop7(
                          ScoreEntry(name, game.currentScore));
                      game.overlays.remove(NameEntryOverlay.id);
                      game.overlays.add(LeaderboardOverlay.id);
                    },
                    child: Text(L10n.tr('register')),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// HUD (음소거, 언어)
// ──────────────────────────────────────────────────────────────
class HudOverlay extends StatefulWidget {
  static const id = 'HudOverlay';
  final PlateSpinGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  bool _muted = SoundManager.isMuted;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 50, right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black54,
                    minimumSize: const Size(48, 40)),
                onPressed: () async {
                  await SoundManager.toggleMute();
                  setState(() => _muted = SoundManager.isMuted);
                },
                child: Text(
                    _muted ? '🔇' : '🔊', style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black54,
                    minimumSize: const Size(48, 36)),
                onPressed: () async {
                  final selected = await showDialog<AppLang>(
                    context: context,
                    builder: (ctx) =>
                        AlertDialog(
                          backgroundColor: Colors.black87,
                          title: Text(L10n.tr('lang')),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<AppLang>(
                                value: AppLang.ko,
                                groupValue: LanguageManager.current.value,
                                onChanged: (v) => Navigator.pop(ctx, v),
                                title: const Text('한국어'),
                              ),
                              RadioListTile<AppLang>(
                                value: AppLang.en,
                                groupValue: LanguageManager.current.value,
                                onChanged: (v) => Navigator.pop(ctx, v),
                                title: const Text('English'),
                              ),
                            ],
                          ),
                        ),
                  );
                  if (selected != null) {
                    await LanguageManager.set(selected);
                    if (mounted) setState(() {});
                  }
                },
                child: Text(L10n.tr('lang')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// GameOverOverlay
// ──────────────────────────────────────────────────────────────
class GameOverOverlay extends StatelessWidget {
  static const id = 'GameOverOverlay';
  final PlateSpinGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha:0.35)))),
        Positioned.fill(
          child: Center(
            child: Image.asset('assets/images/game_over.png',
                fit: BoxFit.fitHeight, alignment: Alignment.center),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 180,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      game.overlays.remove(GameOverOverlay.id);
                      game.onExit?.call();
                    },
                    child: Text(L10n.tr('retry')),
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      game.overlays.remove(GameOverOverlay.id);
                      SystemNavigator.pop();
                    },
                    child: Text(L10n.tr('exit')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// ⚙️ PlateSpinGame 본체 (최종 완성본)
// ──────────────────────────────────────────────────────────────
class PlateSpinGame extends FlameGame with PanDetector, TapCallbacks {
  final int startMode;
  final VoidCallback? onExit;
  final problemNotifier = ValueNotifier<String>("");
  final timerNotifier = ValueNotifier<double>(0);
  final SpeechToText _speech = SpeechToText();

  PlateSpinGame({this.onExit, this.startMode = 0});

  late List<Level> currentLevelList;

  async.Timer? _levelTimer;
  int _levelIndex = 0;
  int remainingSeconds = 0;
  SpriteComponent? _bg;
  final List<Component> _decor = [];
  final List<Plate> _plates = [];
  final List<Pole> _poles = [];
  int _attemptsLeft = 3;
  SpriteComponent? _lifeIcon;
  TextComponent? _lifeText;
  bool _isGameOver = false;
  bool _isRespawning = false;
  bool _inCutscene = false;
  double _cutsceneLeft = 0.0;
  double _respawnCooldown = 0.0;
  TextComponent? _levelMsg;
  int _score = 0;

  int get currentScore => _score;

  int get currentLevelIndexForGimmick {
    if (currentLevelList.isEmpty) return 0;
    return currentLevelList[_levelIndex].index;
  }
  double _levelTime = 0.0;
  double _tickAccum = 0.0;
  TextComponent? _scoreText;
  double _swipeAccum = 0.0;
  final double _swipeUnit = 120.0;
  bool _lastFailWasFly = false;
  bool _lastFailByMonkey = false; // [추가] 원숭이 때문에 실패했는지 판별하는 변수
  TextComponent? _tipText;
  Monkey? _stageMonkey;

  bool _bossStarted = false;
  double _windCooldown = 9999.0;
  double _windEffectLeft = 0.0;
  bool _windActive = false;
  bool _windWarned = false;
  TextComponent? _windWarningText;
  bool _windGuideShown = false;
  bool _monkeyGuideShown = false;

  bool get isGameOverForEffects => _isGameOver;

  Pole? _holdingMonkeyPole;
  double _monkeyHoldTime = 0.0;
  Plate? _holdingMonkeyPlate;

  bool _isSilverMode = false;
  int? _currentAnswer;
  double _missionTimer = 0;
  final double _baseLimit = 7.0;
  int _consecutiveCorrect = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // [추가] 시작 시 모드에 맞는 레벨 리스트를 할당합니다.
    if (startMode == 1)
      currentLevelList = expertLevels;
    else if (startMode == 2)
      currentLevelList = brainBoosterLevels;
    else
      currentLevelList = beginnerLevels;

    await images.loadAll([
      'backimage1.png',
      'backimage2.png',
      'backimage3.png',
      'backimage4.png',
      'game_over.png',
      'guide.png',
      'plate.png',
      'components/plate_blue.png',
      'components/plate_red.png',
      'components/plate_yellow.png',
      'components/plate_green.png',
      'components/plate_orange.png',
      'components/bowl.png',
      'components/bigPlate1.png',
      'components/bigPlate2.png',
      'components/pole.png',
      'components/help.png',
      'components/elephant.png',
      'components/elephantTap.png',
      'components/elephant_back.png',
      'components/elephant_left.png',
      'components/elephant_right.png',
      'components/leaf1.png',
      'components/leaf2.png',
      'components/leaf3.png',
    ]);
    await SoundManager.requestMainLoop();
    await initFonts();

    if (startMode == 1 || startMode == 2) {
      _levelIndex = 0;
      if (startMode == 2) {
        _isSilverMode = true;
        overlays.add(MathOverlay.id);
        async.Timer(const Duration(seconds: 2), _generateMathProblem);
      }
    }
    _applyLevel(currentLevelList[_levelIndex]);
    _initLivesUI();
    _initScoreUI();
    overlays.add(HudOverlay.id);
  }

  void _startListening() async {
    try {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
          onResult: (result) {
            String voice = result.recognizedWords;
            if (_currentAnswer != null &&
                voice.contains(_currentAnswer.toString())) {
              _onMathSuccess();
            }
          },
          // ✅ 'options' 매개변수 대신 직접 listenMode를 지원하는 버전이거나,
          // 지원하지 않는 구버전일 수 있으므로 가장 안전한 기본 호출 방식으로 변경합니다.
          listenFor: const Duration(seconds: 5),
          localeId: "ko_KR",
        );
      }
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  void _generateMathProblem() {
    if (!_isSilverMode || _isGameOver) return;
    final random = Random();
    int a = random.nextInt(8) + 2;
    int b = random.nextInt(9) + 1;
    _currentAnswer = a * b;
    problemNotifier.value = "$a × $b = ?";
    _missionTimer = _baseLimit - (_consecutiveCorrect * 0.2).clamp(0, 4.0);
    _startListening();
  }

  void _onMathSuccess() {
    _score += 200;
    _scoreText?.text = "Score: $_score";
    problemNotifier.value = "O";
    _currentAnswer = null;
    async.Timer(const Duration(seconds: 1), _generateMathProblem);
  }

  void _onMathFail() {
    problemNotifier.value = "X";
    _currentAnswer = null;
    async.Timer(const Duration(seconds: 1), _generateMathProblem);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    if (_isSilverMode && _currentAnswer != null) {
      _missionTimer -= dt;
      timerNotifier.value = (_missionTimer / _baseLimit).clamp(0, 1);
      if (_missionTimer <= 0) _onMathFail();
    }

    if (_inCutscene) {
      _cutsceneLeft -= dt;
      if (_cutsceneLeft <= 0) {
        _inCutscene = false;
        _isRespawning = false; // [안전장치] 컷신 종료 시 리스폰 플래그도 확실히 해제!
        _levelMsg?.removeFromParent();
        _levelMsg = null;
        _setupPlates(currentLevelList[_levelIndex]);
        _respawnCooldown = 0.2;
      }
      return;
    }

    if (_respawnCooldown > 0) {
      _respawnCooldown -= dt;
      return;
    }

    if (_holdingMonkeyPole != null && _holdingMonkeyPole!.isShakenByMonkey) {
      _monkeyHoldTime += dt;

      if (_holdingMonkeyPlate != null) {
        _holdingMonkeyPlate!.omega -= 5.0 * dt;
        if (_holdingMonkeyPlate!.omega < 10) {
          _holdingMonkeyPlate!.omega = 10;
        }
      }

      if (_monkeyHoldTime >= 0.7) {
        _defeatMonkeyByHold();
      }
    }

    if (_plates.isEmpty) {
      failAndRespawnOrGameOver();
      return;
    }

    _levelTime += dt;
    _updateWind(dt);

    _tickAccum += dt;
    while (_tickAccum >= 0.1) {
      _addScore(1);
      _tickAccum -= 0.1;
    }

    // [핵심] 배열 길이 차이로 인한 에러를 막는 안전한 반복문
    for (int i = 0; i < _plates.length; i++) {
      final p = _plates[i];
      if (p.gameOver) {
        bool wasShaken = false;
        if (i < _poles.length) {
          wasShaken = _poles[i].isShakenByMonkey;
        }

        // [핵심 추가] 찰나의 차이로 막대기 상태가 false가 되었더라도,
        // 현재 화면에 공격 중인 원숭이가 있다면 원숭이 때문인 것으로 너그럽게 인정!
        final monkey = children
            .whereType<Monkey>()
            .firstOrNull;
        if (monkey != null && monkey.isAttacking) {
          wasShaken = true;
        }

        failAndRespawnOrGameOver(fromFly: p.flyingAway, byMonkey: wasShaken);
        return;
      }
      _updateBackgroundHeat();
    }
  }

  void _defeatMonkeyByHold() {
    final pole = _holdingMonkeyPole;
    if (pole == null) return;

    pole.isShakenByMonkey = false;
    pole.resistanceAmount = 0;

    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;

    final monkey = children
        .whereType<Monkey>()
        .firstOrNull;
    monkey?.onDefeated();
  }

  void _nextLevel() {
    _cancelTimer();

    if (currentLevelList == expertLevels &&
        currentLevelList[_levelIndex].showEventScene) {
      pauseEngine();
      overlays.add('Event1');
      return;
    }

    _levelIndex++;
    if (_levelIndex >= currentLevelList.length) {
      // 모든 스테이지 종료 시 Finale 호출
      overlays.add('Finale');

    } else {
      _applyLevel(currentLevelList[_levelIndex]);
    }
  }

// [추가] 컷신이 모두 끝난 후 실행될 함수
  void startStage2() {
    _levelIndex = 0;
    currentLevelList = stage2Levels;

    _bossStarted = false;


    // 1. 혹시 모를 기존 원숭이 제거
    children.whereType<Monkey>().forEach((m) => m.removeFromParent());

    // 2. 레벨 적용 (수정된 _applyLevel에서 알아서 원숭이를 1마리 소환해 줍니다!)
    _applyLevel(currentLevelList[_levelIndex]);

    resumeEngine();

    // 3. [음악 버그 해결] 스테이지 2 시작 시 확실하게 메인 BGM 큐!
    SoundManager.requestMainLoop();
  }

  // ▼▼▼ 함수 괄호 안에 byMonkey 파라미터가 선언되어 있어야 합니다! ▼▼▼
  void failAndRespawnOrGameOver({bool fromFly = false, bool byMonkey = false}) {
    _lastFailWasFly = fromFly;
    _lastFailByMonkey = byMonkey;

    // [핵심 추가] 리스폰(화면 초기화) 전에 무조건 원숭이 소리부터 강제로 끕니다!
    // 이렇게 해야 오디오 채널이 꼬이지 않고 BGM이 살아납니다.
    SoundManager.stopMonkeySfx(restartBgm: false);

    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;

    for (final pole in _poles) {
      pole.isShakenByMonkey = false;
      pole.resistanceAmount = 0;
    }

    children.whereType<Monkey>().forEach((m) {
      m.removeFromParent();
    });
    _stageMonkey = null;

    if (_isGameOver || _isRespawning) return;
    _isRespawning = true;
    _attemptsLeft--;
    _updateLifeUI();

    if (fromFly) {
      SoundManager.playSfxSafe("fly.wav");
    } else {
      SoundManager.playSfxSafe("crash.wav");
    }

    async.Timer(const Duration(milliseconds: 500), () {
      if (!_isGameOver) {
        SoundManager.playSfxSafe("crowd.wav");
      }
    });

    async.Timer(const Duration(milliseconds: 2000), () {
      if (!_isGameOver) {
        SoundManager.forceMainLoop();
      }
    });

    if (_attemptsLeft > 0) {
      _showTipFor(const Duration(seconds: 3));
      _respawnCooldown = 3.0;
      async.Timer(const Duration(seconds: 3), () {
        _tipText?.removeFromParent();
        _tipText = null;
        _applyLevel(currentLevelList[_levelIndex]);
        _respawnCooldown = 0.35;
        _isRespawning = false;

        SoundManager.forceMainLoop();
      });
    } else {
      _showTipFor(const Duration(seconds: 3));
      _respawnCooldown = 3.0;
      async.Timer(const Duration(seconds: 3), () {
        _tipText?.removeFromParent();
        _tipText = null;
        gameOver();
      });
    }
  }

  void _startBossPhase() {
    children.whereType<Monkey>().forEach((m) {
      m.removeFromParent();
    });

    _stageMonkey = null;

    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;

    _callElephant();
  }

  void gameOver() {
    if (_isGameOver) return;

    _windActive = false;
    _windEffectLeft = 0.0;
    _windCooldown = 9999.0;
    _windWarningText?.removeFromParent();
    _windWarningText = null;
    SoundManager.forceMainLoop();

    _isGameOver = true;
    _cancelTimer();
    SoundManager.requestWelcomeLoop();
    pauseEngine();
    ScoreManager.qualifies(_score).then((ok) =>
        overlays.add(ok ? NameEntryOverlay.id : LeaderboardOverlay.id));
  }

  void _addScore(int amount) {
    _score += amount;
    _scoreText?.text = "Score: $_score";
  }

  void _updateLifeUI() {
    _lifeText?.text = "×${(_attemptsLeft - 1).clamp(0, 99)}";
  }

  void _cancelTimer() {
    _levelTimer?.cancel();
    _levelTimer = null;
  }

  void _clearDecor() {
    for (final c in _decor)
      c.removeFromParent();
    _decor.clear();
  }

  void _clearPlates() {
    for (final p in _plates)
      p.removeFromParent();
    _plates.clear();
  }

  void _applyLevel(Level level) {
    _cancelTimer();
    _clearDecor();
    _clearPlates();
    _poles.clear();
    _levelTime = 0.0;
    _windActive = false;
    _windEffectLeft = 0.0;
    _windWarned = false;

// Expert 전반부에서만, 레벨 시작 후 10초 뒤부터 바람 가능
    if (_shouldUseWind) {
      _windCooldown = 3.0 + Random().nextDouble() * 3.0;
    } else {
      _windCooldown = 9999.0;
    }

    // 기존 원숭이 일단 싹 제거 (초기화)
    if (currentLevelList != stage2Levels) {
      children.whereType<Monkey>().forEach((m) => m.removeFromParent());
      _stageMonkey = null;
    }

    _bg?.removeFromParent();
    _bg = SpriteComponent(sprite: Sprite(images.fromCache(level.background)),
        size: size,
        priority: -2);
    add(_bg!);

    if (startMode == 0) {
      _inCutscene = true;
      _cutsceneLeft = 2.0;
      _levelMsg?.removeFromParent();
      _levelMsg = TextComponent(text: L10n.tr(level.messageKey),
          anchor: Anchor.center,
          position: Vector2(size.x / 2, size.y / 4),
          textRenderer: koreanText);
      add(_levelMsg!);
    } else {
      _inCutscene = false;
      _setupPlates(level);
    }

    remainingSeconds = level.duration.inSeconds;
    _showChallengeGuideIfNeeded(level);


    // ▼▼▼ [핵심 수정] 레벨 업 시 원숭이 소환 로직 복구 ▼▼▼
    // 스테이지 2 모음집(stage2Levels)을 플레이 중이라면 원숭이가 있어야 합니다.
    if (currentLevelList == stage2Levels) {
      final existingMonkey = children
          .whereType<Monkey>()
          .firstOrNull;

      if (existingMonkey == null) {
        _stageMonkey = Monkey();
        add(_stageMonkey!);
      } else {
        _stageMonkey = existingMonkey;
      }
    }
    // ▲▲▲ [핵심 수정 끝] ▲▲▲

    if (remainingSeconds < 1000000) {
      _levelTimer = async.Timer.periodic(const Duration(seconds: 1), (t) {
        remainingSeconds--;
        if (remainingSeconds <= 0) {
          t.cancel();
          _levelTimer = null;
          _nextLevel();
        }
      });
    }
  }

  void _setupPlates(Level level) {
    _clearDecor();
    _clearPlates();
    _poles.clear();

    final count = level.sets.length;

    // ✅ [수정] 막대기 위치 후보들을 미리 만듭니다.
    final List<double> xPositions = [];
    final spacing = size.x / (count + 1);
    for (int i = 0; i < count; i++) {
      xPositions.add(spacing * (i + 1));
    }

    // ✅ [핵심 1] 막대기 위치를 랜덤으로 섞습니다.
    xPositions.shuffle();

    final plateImages = [
      'components/plate_blue.png',
      'components/plate_yellow.png',
      'components/plate_red.png',
      'components/plate_green.png',
      'components/plate_orange.png'
    ];

    for (int i = 0; i < count; i++) {
      final x = xPositions[i]; // 섞인 위치 사용
      final pivotY = size.y / 2.2;

      final pole = Pole(
          position: Vector2(x, size.y), targetHeight: (size.y - pivotY).abs())
        ..priority = 0;
      add(pole);
      _decor.add(pole);
      _poles.add(pole);

      final type = level.sets[i].type;
      Plate plate;

      if (type == PlateType.tray) {
        // ✅ [핵심 2] 큰 접시 이미지도 1, 2 중 랜덤 선택
        final trayImg = (Random().nextBool())
            ? 'bigPlate1.png'
            : 'bigPlate2.png';
        plate = BigPlate(
            center: Vector2(x, pivotY), imagePath: 'components/$trayImg');
      } else if (type == PlateType.bowl) {
        plate = BowlPlate(center: Vector2(x, pivotY))
          ..omega = 30;
      } else {
        // ✅ [핵심 3] 일반 접시 색상(이미지)을 랜덤하게 선택
        final randomImg = plateImages[Random().nextInt(plateImages.length)];
        plate = Plate(center: Vector2(x, pivotY), imagePath: randomImg);
      }

      plate.priority = 1;
      add(plate);
      _plates.add(plate);
    }
    _respawnCooldown = 0.35;
    _isRespawning = false;
  }

  void _initLivesUI() {
    _lifeIcon?.removeFromParent();
    _lifeText?.removeFromParent();
    _lifeIcon = SpriteComponent(sprite: Sprite(images.fromCache('plate.png')),
        size: Vector2(40, 40),
        position: Vector2(20, size.y - 60),
        anchor: Anchor.topLeft,
        priority: 3000);
    add(_lifeIcon!);
    _lifeText = TextComponent(text: "×${(_attemptsLeft - 1).clamp(0, 99)}",
        anchor: Anchor.topLeft,
        position: Vector2(70, size.y - 55),
        textRenderer: koreanText,
        priority: 3001);
    add(_lifeText!);
  }

  void _initScoreUI() {
    _scoreText?.removeFromParent();
    _scoreText = TextComponent(text: "Score: 0",
        anchor: Anchor.topRight,
        position: Vector2(size.x - 100, 20),
        textRenderer: koreanText,
        priority: 3002);
    add(_scoreText!);
  }

  void _showTipFor(Duration dur) {
    List<String> tipList;

    // 1순위: 원숭이가 막대를 흔들어서 접시가 날아간 경우
    if (_lastFailByMonkey) {
      tipList = [
        L10n.tr('tip_monkey_1'),
        L10n.tr('tip_monkey_2'),
        L10n.tr('tip_monkey_3'),
        L10n.tr('tip_monkey_4')
      ];
    }
    // 2순위: 유저가 너무 세게 돌려서 날아간 경우
    else if (_lastFailWasFly) {
      tipList = [
        L10n.tr('tip_fly_1'),
        L10n.tr('tip_fly_2'),
        L10n.tr('tip_fly_3'),
        L10n.tr('tip_fly_4')
      ];
      // 번역 키가 그대로 나오면 임시 대체
      if (tipList[0] == 'tip_fly_1')
        tipList = ['너무 빨리 돌리면 날아가요!', '속도를 조절하세요!'];
    }
    // 3순위: 바닥으로 떨어진 경우
    else {
      tipList = [
        L10n.tr('tip_fall_1'),
        L10n.tr('tip_fall_2'),
        L10n.tr('tip_fall_3'),
        L10n.tr('tip_fall_4')
      ];
    }

    final tip = (tipList..shuffle()).first;

    _tipText?.removeFromParent();
    _tipText = TextComponent(
        text: tip,
        anchor: Anchor.center,
        position: Vector2(size.x / 2, size.y * 0.25),
        textRenderer: koreanText,
        // 폰트가 로드되었는지 확인 필요
        priority: 4000);

    add(_tipText!);
  }

  void _showCenterMessage(String text, {int seconds = 3}) {
    _tipText?.removeFromParent();

    _tipText = TextComponent(
      text: text,
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 4),
      textRenderer: koreanText,
      priority: 5000,
    );

    add(_tipText!);

    async.Timer(Duration(seconds: seconds), () {
      _tipText?.removeFromParent();
      _tipText = null;
    });
  }

  void _showChallengeGuideIfNeeded(Level level) {
    if (currentLevelList == expertLevels &&
        level.index == 3 &&
        !_windGuideShown) {
      _windGuideShown = true;
      _showCenterMessage(
        L10n.tr('wind_guide'),
      );
    }

    if (currentLevelList == stage2Levels &&
        level.index == 101 &&
        !_monkeyGuideShown) {
      _monkeyGuideShown = true;
      _showCenterMessage(
        L10n.tr('monkey_guide'),
      );
    }
  }

  bool get _shouldUseWind {
    final level = currentLevelList[_levelIndex].index;

    if (currentLevelList == expertLevels) {
      return level >= 3 && level <= 5;
    }

    if (currentLevelList == stage2Levels) {
      return level >= 103 && level <= 105;
    }

    return false;
  }

  void _updateWind(double dt) {
    if (!_shouldUseWind) return;
    if (_isGameOver || _isRespawning || _inCutscene) return;
    if (_plates.isEmpty) return;

    if (_levelTime < 3.0) return;

    if (_windActive) {
      _windEffectLeft -= dt;

      if (_windEffectLeft <= 0) {
        _windActive = false;
        _windCooldown = 12.0 + Random().nextDouble() * 10.0;

        // windSound가 끝난 뒤 BGM 복구
        SoundManager.forceMainLoop();
      }
      return;
    }

    _windCooldown -= dt;

  //  if (_windCooldown <= 2.0 && !_windWarned) {
  //    _windWarned = true;
  //    _showWindWarning();
  //  }

    if (_windCooldown <= 0) {
      _startWindEvent();
    }
  }

  void _showWindWarning() {
    _windWarningText?.removeFromParent();

    _windWarningText = TextComponent(
      text: L10n.tr('wind_warning'),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.22),
      textRenderer: koreanText,
      priority: 4200,
    );

    add(_windWarningText!);

    async.Timer(const Duration(seconds: 2), () {
      _windWarningText?.removeFromParent();
      _windWarningText = null;
    });
  }

  void _startWindEvent() {
    if (_isGameOver || _isRespawning || _inCutscene) return;
    if (!_shouldUseWind) return;

    _windActive = true;
    _windEffectLeft = 4.0;
    _windWarned = false;

    _windWarningText?.removeFromParent();
    _windWarningText = null;

    SoundManager.playSfxSafe("windSound.mp3", volume: 0.7);

    // 바람 효과는 시작 순간에 1회만 적용
    for (final plate in _plates) {
      if (!plate.gameOver && !plate.falling && !plate.flyingAway) {
        plate.omega *= 0.9; // 10%만 감속
        if (plate.omega < 8.0) {
          plate.omega = 8.0;
        }
      }
    }

    add(WindLeafEffect());
  }

  void _callElephant() {
    SoundManager.playMonkeySfx();

    final help = SpriteComponent(
      sprite: Sprite(images.fromCache('components/help.png')),
      size: Vector2(180, 120),
      anchor: Anchor.center,
      position: Vector2(size.x * 0.55, size.y * 0.25),
      priority: 5000,
    );

    add(help);

    Future.delayed(const Duration(seconds: 2), () {
      help.removeFromParent();

      SoundManager.playSfxSafe("elephantSound.mp3");

      spawnElephant();
    });
  }

  void spawnElephant() {
    if (children
        .whereType<Elephant>()
        .isNotEmpty) return;
    add(Elephant());
  }

  void shakeScreen() {
    camera.viewfinder.add(
      MoveEffect.by(
        Vector2(10, 0),
        EffectController(
          duration: 0.05,
          reverseDuration: 0.05,
          repeatCount: 4,
        ),
      ),
    );
  }

  void slowDownPlatesByElephant() {
    for (final plate in _plates) {
      if (!plate.gameOver && !plate.falling && !plate.flyingAway) {
        plate.omega -= 1.8;
        if (plate.omega < 4.0) plate.omega = 4.0;
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // 여기서 플래그가 하나라도 true면 스와이프를 무시합니다. (먹통의 주범!)
    if (_isGameOver || _inCutscene || _isRespawning) return;

    final pos = info.eventPosition.global;
    Plate? nearestPlate;
    Pole? nearestPole;
    double minDist = double.infinity;

    for (int i = 0; i < _plates.length; i++) {
      final p = _plates[i];
      final d = p.position.distanceTo(pos);
      if (d < minDist) {
        minDist = d;
        nearestPlate = p;
        if (i < _poles.length) {
          nearestPole = _poles[i];
        }
      }
    }

    if (nearestPlate != null && nearestPole != null) {

      if (nearestPole.isShakenByMonkey) {
        return;
      }

      // [정상 스와이프 로직]
      final input = info.delta.global.length.clamp(0, 60).toDouble();
      if (input <= 0) return;

      nearestPlate.boost(input);

      if (nearestPole.children
          .whereType<RotateEffect>()
          .isEmpty) {
        nearestPole.add(
            RotateEffect.by(0.005, SineEffectController(period: 0.1)));
      }
      nearestPole.add(
          RotateEffect.by(0.01, SineEffectController(period: 0.08)));

      _swipeAccum += input;
      if (_swipeAccum >= _swipeUnit) {
        _addScore(10 * (_swipeAccum ~/ _swipeUnit));
        _swipeAccum %= _swipeUnit;
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final pos = event.canvasPosition;

    for (int i = 0; i < _poles.length; i++) {
      final pole = _poles[i];

      if (!pole.isShakenByMonkey) continue;

      final dx = (pole.position.x - pos.x).abs();
      final isNearPole = dx < 80 && pos.y > size.y * 0.45;

      if (isNearPole) {
        _holdingMonkeyPole = pole;
        _holdingMonkeyPlate = i < _plates.length ? _plates[i] : null;
        _monkeyHoldTime = 0.0;
        return;
      }
    }

    final elephant = children
        .whereType<Elephant>()
        .firstOrNull;
    elephant?.onTappedByPlayer();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;
  }

  @override
  void onPanCancel() {
    _holdingMonkeyPole = null;
    _holdingMonkeyPlate = null;
    _monkeyHoldTime = 0.0;
  }

  void _updateBackgroundHeat() {
    // 기존 heat 로직 필요 시 추가
  }
}

class StoryOverlay extends StatefulWidget {
  final String imagePath;
  final List<String> textKeys;
  final List<String>? speakers;
  final VoidCallback onTap;

  const StoryOverlay({
    super.key,
    required this.imagePath,
    required this.textKeys,
    this.speakers,
    required this.onTap,
  });

  @override
  State<StoryOverlay> createState() => _StoryOverlayState();
}

class _StoryOverlayState extends State<StoryOverlay> {
  String _typedText = "";
  int _currentTextIndex = 0;
  async.Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer?.cancel();
    _typedText = "";

    final fullText = L10n.tr(widget.textKeys[_currentTextIndex]);
    int charIndex = 0;

    _timer = async.Timer.periodic(const Duration(milliseconds: 45), (t) {
      if (charIndex < fullText.length) {
        setState(() {
          _typedText += fullText[charIndex];
        });
        charIndex++;
      } else {
        t.cancel();
      }
    });
  }

  void _nextText() {
    if (_currentTextIndex < widget.textKeys.length - 1) {
      setState(() {
        _currentTextIndex++;
      });
      _startTyping();
    } else {
      widget.onTap();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.textKeys[_currentTextIndex];

    final speaker = widget.speakers != null &&
        _currentTextIndex < widget.speakers!.length
        ? widget.speakers![_currentTextIndex]
        : key;

    Alignment bubbleAlign = Alignment.bottomLeft;
    EdgeInsets bubbleMargin = const EdgeInsets.only(left: 70, bottom: 95);

    BubbleTailDirection tailDirection = BubbleTailDirection.left;

    if (speaker == 'girl') {
      bubbleAlign = Alignment.bottomRight;
      bubbleMargin = const EdgeInsets.only(right: 120, bottom: 95);
      tailDirection = BubbleTailDirection.right;
    } else if (speaker == 'man') {
      bubbleAlign = Alignment.bottomLeft;
      bubbleMargin = const EdgeInsets.only(left: 90, bottom: 95);
      tailDirection = BubbleTailDirection.left;
    } else if (speaker == 'monkey') {
      bubbleAlign = Alignment.bottomRight;
      bubbleMargin = const EdgeInsets.only(right: 110, bottom: 95);
      tailDirection = BubbleTailDirection.right;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/${widget.imagePath}',
            fit: BoxFit.cover,
          ),
        ),

        // 말풍선
        Align(
          alignment: bubbleAlign,
          child: Container(
            margin: bubbleMargin,
            child: _speechBubble(
              text: _typedText,
              maxWidth: 560,
              tailDirection: tailDirection,
            ),
          ),
        ),

        // 오른쪽 다음 화살표
        Positioned(
          right: 70,
          top: MediaQuery
              .of(context)
              .size
              .height / 2 - 40,
          child: GestureDetector(
            onTap: _nextText,
            child: const Text(
              '>',
              style: TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 5.0,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 중앙 하단 건너뛰기: 즉시 다음 화면/게임으로
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              child: Text(
                L10n.tr('skip'),
                style: const TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
          ),
        ),

        // 언어 전환
        Positioned(
          top: 24,
          right: 24,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final next = LanguageManager.current.value == AppLang.ko
                  ? AppLang.en
                  : AppLang.ko;

              await LanguageManager.set(next);

              if (!mounted) return;
              _startTyping();
            },
            child: Text(
              LanguageManager.current.value == AppLang.ko ? 'EN' : 'KR',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _speechBubble({
    required String text,
    required double maxWidth,
    required BubbleTailDirection tailDirection,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.black87, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(3, 5),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ),

        Positioned(
          bottom: -10,
          left: tailDirection == BubbleTailDirection.left ? 38 : null,
          right: tailDirection == BubbleTailDirection.right ? 38 : null,
          child: Transform.rotate(
            angle: 0.8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                border: const Border(
                  right: BorderSide(color: Colors.black87, width: 3),
                  bottom: BorderSide(color: Colors.black87, width: 3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WindLeafEffect extends Component
    with HasGameReference<PlateSpinGame> {

  final Random _rnd = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    for (int i = 0; i < 10; i++) {
      final spriteName =
          'components/leaf${1 + _rnd.nextInt(3)}.png';

      final leaf = SpriteComponent(
        sprite: Sprite(game.images.fromCache(spriteName)),
        size: Vector2.all(40 + _rnd.nextDouble() * 25),
        position: Vector2(
          -50 - _rnd.nextDouble() * 200,
          game.size.y * (0.15 + _rnd.nextDouble() * 0.55),
        ),
        priority: 2500,
      );

      game.add(leaf);

      leaf.add(
        MoveEffect.to(
          Vector2(
            game.size.x + 200,
            leaf.position.y +
                (_rnd.nextDouble() - 0.5) * 150,
          ),
          EffectController(
            duration: 4.0,
          ),
          onComplete: () {
            leaf.removeFromParent();
          },
        ),
      );

      leaf.add(
        RotateEffect.by(
          pi * (4 + _rnd.nextDouble() * 6),
          EffectController(
            duration: 4.0,
          ),
        ),
      );
    }

    removeFromParent();
  }
}