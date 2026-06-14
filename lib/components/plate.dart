import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../sound_manager.dart';
import 'pole.dart';
import '../plate_game.dart';

class Plate extends SpriteComponent with HasGameReference<PlateSpinGame> {
  double omega;
  double angleRad = 0;
  double tilt = 0;
  double phase = 0;
  double currentAmp = 0,
      targetAmp = 0;

  // 🔥 오류 해결 1: final 변수는 선언 시 혹은 이니셜라이저에서 초기화해야 합니다.
  final double phaseOffset = Random().nextDouble() * 2 * pi;

  double flatTimer = 0.0;
  bool gameOver = false;
  bool flyingAway = false;
  bool falling = false;
  double heat = 0.0;

  // 물성치
  double friction;
  double omegaMax;
  double maxTilt;
  double fallSpeed;

  // 🔥 오류 해결 2 & 3: 기본값을 직접 할당하여 초기화 누락 방지
  double omegaMin = 0.5;
  double flySpeedY = -300;
  double flySpeedX = 150;

  final String imagePath;

  Plate({
    required Vector2 center,
    required this.imagePath,
    double initialOmega = 15,
    this.friction = 1.0,
    this.omegaMax = 30,
    this.maxTilt = 0.8,
    this.fallSpeed = 600,
    Vector2? plateSize,
  })
      : omega = initialOmega,
        super(
        size: plateSize ?? Vector2(160, 160),
        anchor: Anchor.center,
        position: center,
        priority: 10,
      );


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite(imagePath);
  }

  @override
  void onMount() {
    super.onMount();
    phase = phaseOffset;
  }

  void boost(double input) {
    if (gameOver || flyingAway || falling) return;
    // 부스트 시에도 omegaMax를 넘으면 즉시 비행 준비
    omega += input * 0.02;
    // 너무 무한정 올라가는 것만 방지 (예: 최대 50)
    if (omega > 50) omega = 50;
  }


  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver) return;

    // 1. [원숭이 방어] 원숭이 공격 감지 및 과회전 유도
    // (내 위치와 X좌표가 거의 일치하는 막대기를 찾음)
    try {
      final myPole = game.children
          .whereType<Pole>()
          .firstWhere((p) => (p.position.x - position.x).abs() < 1.0);

      if (myPole.isShakenByMonkey) {
        // 원숭이가 흔들면 회전 속도를 빠르게 증가시킴 (과열 유도)
        omega += 8.0 * dt;
      }
    } catch (e) {
      // 혹시 막대기를 못 찾더라도 게임이 멈추지 않게 예외 처리
    }

    // 2. [물리 로직] 마찰력에 의한 회전력 감쇠
    omega -= friction * dt;

    // ---------------------------------------------------------
    // 3. [상태 연출 1] 이미 날아가고 있는 중이라면?
    // ---------------------------------------------------------
    if (flyingAway) {
      position.y += flySpeedY * dt;
      position.x += flySpeedX * dt;
      angle += dt * 10;

      // 화면 위로 완전히 사라지면 게임오버 처리 (메모리 정리용)
      if (position.y + size.y < 0) gameOver = true;
      return; // 비행 중에는 아래 로직(떨어짐 판정 등) 무시
    }

    // ---------------------------------------------------------
    // 4. [상태 감지 1] 추락 판정 (속도가 너무 느릴 때)
    // ---------------------------------------------------------
    if (!falling && !flyingAway && omega <= 3.0) {
      falling = true;
      SoundManager.playSfxSafe("crash.wav");

      // [중요] 게임 본체에 "떨어졌다"고 알림 (Tip: 떨어짐 멘트 출력)
      game.failAndRespawnOrGameOver(fromFly: false);
    }

    // ---------------------------------------------------------
    // 5. [상태 연출 2] 이미 떨어지고 있는 중이라면?
    // ---------------------------------------------------------
    if (falling) {
      position.y += (fallSpeed + 900) * dt;
      // 떨어질 때 90도로 꺾이는 연출
      angle = ui.lerpDouble(angle, (tilt >= 0 ? 1.57 : -1.57), dt * 25)!;

      // 화면 아래로 완전히 사라지면 게임오버 처리
      if (position.y > game.size.y + 100) gameOver = true;
      return; // 추락 중에는 아래 로직 무시
    }

    // ---------------------------------------------------------
    // 6. [시각적 연출] 회전, 흔들림, 기울기 계산
    // ---------------------------------------------------------
    angleRad = (angleRad + omega * dt) % (pi * 2);

    // 속도에 따른 흔들림 진폭 계산 (3~12 구간)
    targetAmp = (1 - (omega - 3.0) / (12.0 - 3.0)).clamp(0, 1) * maxTilt;
    currentAmp = ui.lerpDouble(currentAmp, targetAmp, dt * 2.0)!;

    // 흔들림 주기
    phase += (0.5 + (omega * 0.3)) * dt;
    tilt = sin(phase) * currentAmp;
    angle = tilt; // 실제 컴포넌트 회전 적용

    // ---------------------------------------------------------
    // 7. [상태 감지 2] 비행(Fly) 판정 (속도가 너무 빠르고 수평일 때)
    // ---------------------------------------------------------
    if (omega >= (omegaMax - 0.5)) {
      // 기울기가 거의 수평(0.1 미만)일 때만 카운트
      if (tilt.abs() < 0.1) {
        flatTimer += dt;

        // 1초 이상 유지 시 발사!
        if (flatTimer >= 1.0) {
          flyingAway = true;
          SoundManager.playSfxSafe("fly.wav");

          // ▼▼▼ [핵심 수정] ▼▼▼
          // "이건 날아가는 겁니다!" 하고 게임 본체에 알림 (Tip: 날아감 멘트 출력)
          bool byMonkey = false;

          try {
            final myPole = game.children
                .whereType<Pole>()
                .firstWhere((p) => (p.position.x - position.x).abs() < 1.0);

            byMonkey = myPole.isShakenByMonkey;
          } catch (_) {}

          game.failAndRespawnOrGameOver(fromFly: true, byMonkey: byMonkey);
          // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲
        }
      } else {
        flatTimer = 0; // 기울어지면 타이머 리셋
      }
    } else {
      flatTimer = 0; // 속도가 줄면 타이머 리셋
    }

    // 8. 과열 시각화 (빨개지는 효과)
    final targetHeat = ((omega - 25.0) / (omegaMax - 25.0)).clamp(0.0, 1.0);
    heat = ui.lerpDouble(heat, targetHeat, dt * 3.0)!;
  }

  @override
  void render(ui. Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    // 휘청거리는 기울기 적용
    canvas.rotate(tilt);

    // ✅ 일반 접시의 기본 납작도 (0.35)
    // BowlPlate는 bowl.dart에서 0.6으로 직접 덮어쓰도록 유도합니다.
    canvas.scale(1.0, 0.35);

    // 수평 회전
    canvas.rotate(angleRad);

    sprite?.render(canvas, size: size, anchor: Anchor.center);

    // 과열 효과
    if (heat > 0.05) {
      final overlay = Paint()
        ..color = Colors.red.withValues(alpha: heat * 0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * heat);
      canvas.drawCircle(Offset.zero, size.x / 2, overlay);
    }
    canvas.restore();
  }
}