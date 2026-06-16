// lib/components/monkey.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'dart:math';
import '../plate_game.dart';
import 'pole.dart';
import '../sound_manager.dart';

class Monkey extends SpriteAnimationComponent
    with HasGameReference<PlateSpinGame> {
  bool isAttacking = false;
  double _timer = 0;
  double _nextInterval = 12;
  final Random _rnd = Random();
  Pole? _targetPole;
  bool _hasPlayedSound = false;

  // [추가] 애니메이션 딜레이(버벅거림)를 없애기 위해 미리 담아둘 변수들
  late SpriteAnimation _roamingAnimation;
  late SpriteAnimation _shakeAnimation;
  late SpriteAnimation _exitAnimation;

  @override
  Future<void> onLoad() async {
    // 1. 배회 애니메이션 미리 로드 (roaming1~3)
    final roamingSprites = await Future.wait([
      game.loadSprite('components/roaming1.png'),
      game.loadSprite('components/roaming2.png'),
      game.loadSprite('components/roaming3.png'),
    ]);
    _roamingAnimation = SpriteAnimation.spriteList(
      roamingSprites,
      stepTime: 0.15,
    );

    // 2. 공격(흔들기) 애니메이션 미리 로드 (shake1, 2)
    final shakeSprites = await Future.wait([
      game.loadSprite('components/shake1.png'),
      game.loadSprite('components/shake2.png'),
    ]);
    _shakeAnimation = SpriteAnimation.spriteList(
      shakeSprites,
      stepTime: 0.1,
    );

    // 3. 퇴장 애니메이션 미리 로드 (exit1, 2)
    final exitSprites = await Future.wait([
      game.loadSprite('components/exit1.png'),
      game.loadSprite('components/exit2.png'),
    ]);
    _exitAnimation = SpriteAnimation.spriteList(
      exitSprites,
      stepTime: 0.2,
    );

    // 4. 초기 상태를 배회(roaming) 애니메이션으로 설정
    animation = _roamingAnimation;

    // 5. 원숭이 크기를 2배로 (기존 100 -> 200)
    size = Vector2(200, 200);
    anchor = Anchor.bottomCenter;

    // 6. 레이어 위치: 배경(-1) 보다는 크고, 막대기(0) 보다는 작게 (막대기 뒤로!)
    priority = -1;
    _nextInterval = _nextAttackInterval();
  }

  double _nextAttackInterval() {
    final level = game.currentLevelIndexForGimmick;

    switch (level) {
      case 101:
        return 12 + _rnd.nextInt(4).toDouble(); // 12~15초
      case 102:
        return 10 + _rnd.nextInt(4).toDouble(); // 10~13초
      case 103:
        return 8 + _rnd.nextInt(4).toDouble(); // 8~11초
      case 104:
        return 7 + _rnd.nextInt(3).toDouble(); // 7~9초
      case 105:
        return 5 + _rnd.nextInt(3).toDouble(); // 5~7초
      default:
        return 12 + _rnd.nextInt(4).toDouble();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isAttacking) return;
    if (!game.canStartGimmick) return;

    _timer += dt;

    if (_timer > _nextInterval) {
      _timer = 0;
      _chooseTargetAndAttack();
    }
  }

  void _chooseTargetAndAttack() {
    if (!game.canStartGimmick) return;

    final targetPoles = game.children.whereType<Pole>().toList();
    if (targetPoles.isEmpty) return;

    isAttacking = true;
    _hasPlayedSound = false; // [추가] 새로운 공격 시작 시 사운드 플래그 확실히 초기화
    _targetPole = targetPoles[_rnd.nextInt(targetPoles.length)];

    // 대상 막대기 뒤로 이동
    add(MoveEffect.to(
      Vector2(_targetPole!.position.x, game.size.y),
      EffectController(duration: 1.5),
      onComplete: () => _startShaking(),
    ));
  }

  // [수정] 애니메이션을 미리 불러왔으므로 async, await 제거 (즉시 실행)
  void _startShaking() {
    if (_targetPole == null) return;

    // 1. 공격 애니메이션으로 즉각 교체 (딜레이 없음)
    animation = _shakeAnimation;

    // 2. 흔들기 시작할 때 딱 한 번만 소리 재생
    if (!_hasPlayedSound) {
      SoundManager.playMonkeySfx();
      _hasPlayedSound = true; // 재생했다고 표시
    }

    _targetPole!.isShakenByMonkey = true;
  }

  // 유저가 홀드에 성공했을 때 PlateSpinGame에서 호출해줄 함수
  // [수정] async 제거 및 막대기 상태 복구 로직 추가
  void onDefeated() {
    _hasPlayedSound = false;

    if (_targetPole != null) {
      _targetPole!.isShakenByMonkey = false;
    }

    // [중요 추가] 원숭이 퇴치 시 사운드 강제 종료!
    // SoundManager에 효과음을 정지하는 함수가 있다면 호출해 주세요.
    SoundManager.stopMonkeySfx(); // <-- (주의: 이 함수 이름은 SoundManager 구현에 맞춰야 합니다)

    animation = _exitAnimation;

    add(MoveEffect.to(
        Vector2(game.size.x + 250, game.size.y),
        EffectController(duration: 1.5),
        onComplete: () {
          isAttacking = false;
          _resetToRoaming();
        }
    ));
  }

  // [수정] async 제거 (미리 로드된 기본 애니메이션으로 즉시 복구)
  void _resetToRoaming() {
    animation = _roamingAnimation;
    _timer = 0;
    _nextInterval = _nextAttackInterval();
  }
}