import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ 화면 방향 제어를 위해 반드시 필요
import 'package:flame/game.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'plate_game.dart';
import 'intro.dart';
import 'sound_manager.dart';
import 'language_manager.dart';
import 'l10n.dart';

void main() async {
  // ✅ 플러터 엔진이 초기화될 때까지 대기
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 가로 방향(Landscape)으로 고정 설정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // ✅ 상태바 및 하단 네비게이션 바 숨기기 (몰입형 게임 모드)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SoundLifecycleObserver();
  await LanguageManager.init();

  runApp(const SpinGoApp());
}

class SoundLifecycleObserver extends WidgetsBindingObserver {
  SoundLifecycleObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ⭐ 피선생님의 SoundManager에 stopBgm/requestMainLoop 등이 있으므로 그에 맞춤
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      SoundManager.stopBgm();
    } else if (state == AppLifecycleState.resumed) {
      SoundManager.requestMainLoop();
    }
  }
}

class SpinGoApp extends StatelessWidget {
  const SpinGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: LanguageManager.current,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'SpinGo: The Immortal Circus',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            // ✅ 한글 폰트 적용 (에셋에 폰트 파일이 있는지 확인 필수!)
            fontFamily: lang == AppLang.ko ? 'NotoSansKR' : null,
          ),
          // ✅ 가로 화면 비율을 유지하기 위한 Wrapper
          home: const LandscapeWrapper(
            child: GameMainWrapper(),
          ),
        );
      },
    );
  }
}

class LandscapeWrapper extends StatelessWidget {
  final Widget child;

  const LandscapeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          if (w >= h) {
            return child;
          }

          return Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: SizedBox(
                width: h,
                height: w,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class GameMainWrapper extends StatefulWidget {

  const GameMainWrapper({super.key});

  @override
  State<GameMainWrapper> createState() => _GameMainWrapperState();
}

class _GameMainWrapperState extends State<GameMainWrapper> {
  late ConfettiController _confettiController;

  bool _isStartScreen = true;
  bool _isIntro = false;
  int _selectedMode = 0;

  Timer? _titleTimer;

  // 애니메이션을 위한 변수들
  String _displayTitle = "";
  final String _fullTitle = "SpinGo";
  bool _showButton = false;

  void _onPressStart() {
    setState(() {
      _isStartScreen = false;
      _isIntro = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // 2. 조종기 초기화 (2초 동안 발사하도록 설정)
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _startTyping();
  }

  @override
  void dispose() {
    // 3. 화면이 꺼질 때 조종기도 종료 (메모리 관리)
    _confettiController.dispose();
    _titleTimer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _displayTitle = "";
    _showButton = false;
    int index = 0;
    _titleTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (index < _fullTitle.length) {
        setState(() {
          _displayTitle += _fullTitle[index];
          index++;
        });
      } else {
        timer.cancel();
        setState(() => _showButton = true);
        // 4. ✅ 글자가 다 나오면 폭죽 팡!
        _confettiController.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isStartScreen) {
      SoundManager.requestWelcomeLoop();

      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 배경 이미지: 옆이 잘리더라도 위아래를 꽉 맞춥니다.
            Positioned.fill(
              child: Image.asset(
                'assets/images/welcome.png',
                fit: BoxFit.fitHeight,
              ),
            ),

            // 2. 최신 코드 반영 (withValues 사용)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3)
                  ],
                ),
              ),
            ),

            // 5. ✅ 폭죽을 화면 중앙에 배치
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                // 사방으로 발사
                shouldLoop: false,
                colors: const [
                  Colors.red,
                  Colors.blue,
                  Colors.yellow,
                  Colors.green,
                  Colors.orange
                ],
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),

            // 3. 타이틀 및 버튼
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 'The Immortal Circus' 텍스트는 상혁 님 요청대로 제거했습니다.

                  // 타자기 효과로 나타나는 SpinGo
                  Text(
                    _displayTitle,
                    style: TextStyle(
                      fontSize: 90,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                            blurRadius: 20,
                            color: Colors.red.withValues(alpha: 0.8)
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // 버튼과의 간격

                  // 글자가 다 나오면 나타나는 시작하기 버튼
                  if (_showButton)
                    ElevatedButton(
                      onPressed: _onPressStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Text(
                          L10n.tr('start'),
                          style: TextStyle(fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isIntro) return IntroPage(onStartGame: (mode) =>
        setState(() {
          _selectedMode = mode;
          _isIntro = false;
        }));

    // 3. 모드 선택 후 실제 게임 화면
    return Scaffold(
      body: GameWidget<PlateSpinGame>(
        game: PlateSpinGame(
          startMode: _selectedMode,
          onExit: () => setState(() => _isStartScreen = true), // 종료 시 시작 화면으로
        ),
        overlayBuilderMap: {
          HudOverlay.id: (context, game) => HudOverlay(game: game),
          MathOverlay.id: (context, game) => MathOverlay(game: game),
          NameEntryOverlay.id: (context, game) => NameEntryOverlay(game: game),
          LeaderboardOverlay.id: (context, game) =>
              LeaderboardOverlay(game: game),
          GameOverOverlay.id: (context, game) => GameOverOverlay(game: game),
          'Event1': (context, game) =>
              StoryOverlay(
                imagePath: 'eventScene1.png',
                textKeys: ['event1_girl'],
                speakers: ['girl'],
                onTap: () {
                  SoundManager.forceMainLoop();
                  game.overlays.remove('Event1');
                  game.overlays.add('Event2');
                },
              ),
          'Event2': (context, game) =>
              StoryOverlay(
                imagePath: 'eventScene2.png',
                textKeys: ['event2_man', 'event2_monkey'],
                speakers: ['man', 'monkey'],
                onTap: () {
                  SoundManager.forceMainLoop();
                  game.overlays.remove('Event2');
                  (game as PlateSpinGame).startStage2();
                },
              ),
          'Finale': (context, game) =>
              StoryOverlay(
                imagePath: 'finale.png',
                textKeys: ['finale_man', 'finale_girl'],
                speakers: ['man', 'girl'],
                onTap: () {
                  game.overlays.remove('Finale');
                  (game as PlateSpinGame).onExit?.call();
                },
              ),
        },
        initialActiveOverlays: const [HudOverlay.id],
      ),
    );
  }
}