import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../plate_game.dart';
import '../sound_manager.dart';

enum ElephantState {
  backRoaming,
  charging,
  frontStomping,
  returning,
}

class Elephant extends SpriteComponent with HasGameReference<PlateSpinGame> {
  final Random _rnd = Random();

  late Sprite _back;
  late Sprite _left;
  late Sprite _right;
  late Sprite _front;
  late Sprite _hurt;

  ElephantState state = ElephantState.backRoaming;

  double _timer = 0;
  double _nextChargeTime = 3;
  double _stompTimer = 0;
  int tapCount = 0;

  late Vector2 backHomePosition;
  late Vector2 frontCenterPosition;

  Elephant() : super(anchor: Anchor.center, priority: -1);

  @override
  Future<void> onLoad() async {
    _back = await game.loadSprite('components/elephant_back.png');
    _left = await game.loadSprite('components/elephant_left.png');
    _right = await game.loadSprite('components/elephant_right.png');
    _front = await game.loadSprite('components/elephant.png');
    _hurt = await game.loadSprite('components/elephantTap.png');

    backHomePosition = Vector2(game.size.x * 0.78, game.size.y * 0.28);
    frontCenterPosition = Vector2(game.size.x * 0.50, game.size.y * 0.62);

    sprite = _back;
    size = Vector2(90, 90);
    scale = Vector2.all(1.0);
    position = backHomePosition;
    priority = -1;

    _nextChargeTime = 3 + _rnd.nextDouble() * 3;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (state == ElephantState.backRoaming) {
      _backRoam(dt);

      if (_timer >= _nextChargeTime) {
        _startCharge();
      }
      return;
    }

    if (state == ElephantState.frontStomping) {
      _frontRoam(dt);

      _stompTimer += dt;
      if (_stompTimer >= 0.7) {
        _stompTimer = 0;
        game.shakeScreen();
        game.slowDownPlatesByElephant();
        SoundManager.playSfxSafe("elephantSound.mp3", volume: 0.8);
      }
      return;
    }
  }

  void _backRoam(double dt) {
    final wave = sin(_timer * 1.6);

    position.x += wave * dt * 22;

    if (position.x < game.size.x * 0.15) {
      position.x = game.size.x * 0.15;
    }
    if (position.x > game.size.x * 0.85) {
      position.x = game.size.x * 0.85;
    }

    sprite = wave >= 0 ? _right : _left;
    priority = -1;
  }

  void _frontRoam(double dt) {
    final wave = sin(_timer * 2.1);

    position.x += wave * dt * 36;

    if (position.x < game.size.x * 0.25) {
      position.x = game.size.x * 0.25;
    }
    if (position.x > game.size.x * 0.75) {
      position.x = game.size.x * 0.75;
    }

    if (tapCount == 0) {
      sprite = _front;
    }
  }

  void _startCharge() {
    state = ElephantState.charging;
    _timer = 0;
    tapCount = 0;

    priority = 1200;
    sprite = _front;

    SoundManager.playSfxSafe("elephantSound.mp3");
    game.shakeScreen();

    add(
      MoveEffect.to(
        frontCenterPosition,
        EffectController(duration: 1.2),
      ),
    );

    add(
      ScaleEffect.to(
        Vector2.all(2.4),
        EffectController(duration: 1.2),
        onComplete: () {
          state = ElephantState.frontStomping;
          _timer = 0;
          _stompTimer = 0;
          sprite = _front;
        },
      ),
    );
  }

  void onTappedByPlayer() {
    if (state != ElephantState.frontStomping &&
        state != ElephantState.charging) {
      return;
    }

    tapCount++;
    sprite = _hurt;

    if (tapCount >= 3) {
      _returnHome();
    }
  }

  void _returnHome() {
    state = ElephantState.returning;
    tapCount = 0;

    sprite = _back;
    priority = -1;

    add(
      MoveEffect.to(
        backHomePosition,
        EffectController(duration: 1.3),
      ),
    );

    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 1.3),
        onComplete: () {
          state = ElephantState.backRoaming;
          _timer = 0;
          _stompTimer = 0;
          _nextChargeTime = 4 + _rnd.nextDouble() * 4;
          sprite = _back;
          priority = -1;
        },
      ),
    );
  }
}