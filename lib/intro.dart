import 'dart:async';
import 'package:flutter/material.dart';
import 'sound_manager.dart';
import 'language_manager.dart';
import 'l10n.dart';
import '../widgets/age_rating_banner.dart';

enum BubbleTailDirection {
  left,
  right,
}


class IntroPage extends StatefulWidget {
  // ⭐ 모드 번호를 전달할 수 있도록 콜백 함수 수정 (0: 일반, 1: 신나는, 2: 어르신)
  final Function(int) onStartGame;

  const IntroPage({super.key, required this.onStartGame});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  int _index = 0;
  String _typedText = "";
  Timer? _typingTimer;
  bool _showModeSelection = false; // ⭐ 모드 선택창 표시 여부
  bool _intro4SecondLine = false;

  List<Map<String, String>> get _slides =>
      [
        {"image": "assets/images/intro1.png", "text": L10n.tr('intro1')},
        {"image": "assets/images/intro2.png", "text": L10n.tr('intro2')},
        {"image": "assets/images/intro3.png", "text": L10n.tr('intro3')},
        {
          "image": "assets/images/intro4.png",
          "text": L10n.tr(_intro4SecondLine ? 'intro4_master' : 'intro4_man')
        },
        {"image": "assets/images/intro5.png", "text": L10n.tr('intro5')},
      ];

  @override
  void initState() {
    super.initState();
    SoundManager.requestWelcomeLoop();
    _startTyping();
  }

  void _startTyping() {
    _typingTimer?.cancel();
    setState(() => _typedText = "");
    final fullText = _slides[_index]["text"]!;
    int charIndex = 0;
    _typingTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
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

  void _nextSlide() {
    if (_index == 3 && !_intro4SecondLine) {
      setState(() {
        _intro4SecondLine = true;
      });
      _startTyping();
      return;
    }

    if (_index < _slides.length - 1) {
      setState(() {
        _index++;
        _intro4SecondLine = false;
      });
      _startTyping();
    } else {
      setState(() => _showModeSelection = true);
    }
  }

  bool get _isDialogueSlide {
    return _index == 3 || _index == 4; // intro4, intro5
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // 배경 이미지
          Positioned.fill(
              child: Image.asset(slide["image"]!, fit: BoxFit.cover)),

          // 텍스트 영역 (모드 선택창이 아닐 때만 표시)
          if (!_showModeSelection)
            _isDialogueSlide
                ? _buildDialogueBubble(context)
                : Positioned(
              left: MediaQuery
                  .of(context)
                  .size
                  .width * 0.25,
              bottom: 120,
              right: 30,
              child: Text(
                _typedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // 다음 화살표 (모드 선택창이 아닐 때만 표시)
          if (!_showModeSelection)
            Positioned(
              right: 70,
              top: MediaQuery
                  .of(context)
                  .size
                  .height / 2 - 40,
              child: GestureDetector(
                onTap: _nextSlide,
                child: const Text('>',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                              offset: Offset(2, 2),
                              blurRadius: 5.0,
                              color: Colors.black54),
                        ])),
              ),
            ),

          // ⭐ 모드 선택 오버레이
          if (_showModeSelection)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      context,
                      title: L10n.tr('mode_beginner'),
                      desc: L10n.tr('mode_beginner_desc'),
                      mode: 0,
                    ),
                    const SizedBox(height: 24),
                    _buildModeButton(
                      context,
                      title: L10n.tr('mode_challenge'),
                      desc: L10n.tr('mode_challenge_desc'),
                      mode: 1,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 24),
                    _buildModeButton(
                      context,
                      title: L10n.tr('mode_brain'),
                      desc: L10n.tr('mode_brain_desc'),
                      mode: 2,
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ),
            ),

          // 하단 건너뛰기 버튼 (슬라이드 중에만 표시)
          if (!_showModeSelection)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  onPressed: () => setState(() => _showModeSelection = true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14)),
                  child: Text(L10n.tr('skip'),
                      style:
                      const TextStyle(fontSize: 22, color: Colors.white)),
                ),
              ),
            ),
          Positioned(
            top: 24,
            right: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                final next = LanguageManager.current.value == AppLang.ko
                    ? AppLang.en
                    : AppLang.ko;

                await LanguageManager.set(next);

                if (!mounted) return;
                setState(() {
                  _typedText = "";
                });
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
      ),
    );
  }

  Widget _buildDialogueBubble(BuildContext context) {
    final screen = MediaQuery
        .of(context)
        .size;

    // intro4: 봉식 + 단장 대화
    if (_index == 3) {
      if (!_intro4SecondLine) {
        // 박봉식
        return Positioned(
          left: screen.width * 0.20,
          bottom: screen.height * 0.25,
          child: _speechBubble(
            text: _typedText,
            tailDirection: BubbleTailDirection.left,
            maxWidth: screen.width * 0.32,
          ),
        );
      }

      // 서커스 단장
      return Positioned(
        right: screen.width * 0.12,
        bottom: screen.height * 0.28,
        child: _speechBubble(
          text: _typedText,
          tailDirection: BubbleTailDirection.right,
          maxWidth: screen.width * 0.32,
        ),
      );
    }

    // intro5: 원숭이 대사
    if (_index == 4) {
      return Stack(
        children: [
          Positioned(
            left: screen.width * 0.18,
            bottom: screen.height * 0.28,
            child: _speechBubble(
              text: _typedText,
              maxWidth: screen.width * 0.42,
              tailDirection: BubbleTailDirection.left,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _speechBubble({
    required String text,
    required double maxWidth,
    BubbleTailDirection tailDirection = BubbleTailDirection.left,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
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
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ),

        Positioned(
          bottom: -10,
          left: tailDirection == BubbleTailDirection.left ? 36 : null,
          right: tailDirection == BubbleTailDirection.right ? 36 : null,
          child: Transform.rotate(
            angle: 0.8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
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

  // 모드 선택 버튼 위젯
  Widget _buildModeButton(BuildContext context,
      {required String title,
        required String desc,
        required int mode,
        Color color = Colors.amberAccent}) {
    return InkWell(
      onTap: () => widget.onStartGame(mode),
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(15),
          color: Colors.black87,
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 26, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc,
                style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}