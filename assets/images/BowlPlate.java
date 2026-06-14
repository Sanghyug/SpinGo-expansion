import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'plate.dart';

class BowlPlate extends Plate {
  late Sprite _plainBowl;
  double _dotRotation = 0.0; // 점들의 회전 각도 (0 ~ 2*pi)
  double _wobbleTime = 0.0;

  BowlPlate({required Vector2 center}) : super(
    center: center,
    imagePath: 'components/plain_bowl.png',
    friction: 0.5,
    maxTilt: 0.8,
    // 사발의 크기를 적절하게 설정 (사용자 피드백 반영)
    plateSize: Vector2(100, 100), 
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _plainBowl = await game.loadSprite('components/plain_bowl.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle = 0; // 사발 본체 이미지는 회전시키지 않음

    if (!falling && !flyingAway) {
      // 1. 회전 속도(omega)에 따라 점들의 회전 각도를 업데이트
      _dotRotation += dt * (omega * 0.1); 
      _dotRotation %= 2 * pi;

      // 2. 사발/접시 공통 흔들림 로직 (속도가 줄면 휘청거림)
      if (omega < 40) {
        _wobbleTime += dt * (50 - omega);
        double wobbleIntensity = (40 - omega) * 0.02;
        tilt = sin(_wobbleTime) * wobbleIntensity;

        // 임계점(-50도 ≒ 0.87rad) 도달 시 추락
        if (tilt.abs() > 0.87) {
          falling = true;
        }
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(tilt); // 사발 전체 흔들림 적용

    // 1. 배경이 될 민무늬 사발 렌더링
    _plainBowl.render(canvas, size: size, anchor: Anchor.center);

    // 2. 사발 겉면에 입체적으로 회전하는 점들을 그림
    _renderRotatingDots(canvas);

    canvas.restore();
  }

  void _renderRotatingDots(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF2C4A8D).withOpacity(0.9) // 세련된 청색 점
      ..style = ui.PaintingStyle.fill;

    const int totalDots = 6; // 사발 둘레에 배치할 점의 총 개수
    final double radiusX = size.x * 0.43; // 사발 옆면까지의 가로 반지름
    final double yOffset = size.y * 0.12; // 사발 배 부분의 세로 위치

    for (int i = 0; i < totalDots; i++) {
      // 각 점의 고유 각도 + 현재 회전량
      double currentAngle = (i * (2 * pi / totalDots)) + _dotRotation;
      
      // 삼각함수를 이용한 입체 위치 계산
      // x: 좌우 위치, z(sin): 앞뒤 위치 판단용
      double x = cos(currentAngle) * radiusX;
      double z = sin(currentAngle); 

      // 점이 사발의 앞면(z > 0)에 있을 때만 그림 (뒤로 넘어간 점은 숨김)
      if (z > 0) {
        // 원근감을 위해 앞쪽으로 올수록 점이 커지고, 옆으로 갈수록 작아짐
        double dotSize = 2.0 + (z * 2.5);
        
        // 사발의 둥근 하단 곡선을 따라가도록 y위치를 미세하게 보정
        double curvedY = yOffset + (pow(x / radiusX, 2) * 5);

        canvas.drawCircle(ui.Offset(x, curvedY), dotSize, paint);
      }
    }
  }
}