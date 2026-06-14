import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'plate.dart';

class BowlPlate extends Plate {
  late Sprite _plainBowl;
  double _dotRotation = 0.0;
  double _wobbleTime = 0.0;

  BowlPlate({required Vector2 center})
      : super(
    center: center,
    imagePath: 'components/plain_bowl.png',
    friction: 2.0,
    // 마찰력 0.8
    maxTilt: 0.8,
    // 기울기 임계값 0.8
    omegaMax: 35,
    // 35 이상 비행
    initialOmega: 20,
    plateSize: Vector2(100, 100),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _plainBowl = await game.loadSprite('components/plain_bowl.png');
  }

  @override
  void boost(double input) {
    // 🔥 접시보다 스와이프에 20% 느리게 반응 (0.8배)
    super.boost(input * 0.8);
  }

  @override
  void update(double dt) {
    // 1. 비행 상태라면 부모 로직 수행 후 종료
    if (flyingAway) {
      super.update(dt);
      return;
    }

    // 2. 사발 전용 회전 및 흔들림 업데이트
    if (!falling) {
      _dotRotation += dt * (omega * 1.5);
      _dotRotation %= 2 * pi;

      // 흔들림 진폭 (3~15 구간)
      targetAmp = (1 - (omega - 3.0) / (15.0 - 3.0)).clamp(0, 1) * maxTilt;

      final freq = 0.5 + (omega * 0.3);
      phase += freq * dt;
      tilt = sin(phase) * targetAmp;

      // 🔥 [수정] 과열 시각화 구간 조정 (30이 아니라 28부터 붉어지게)
      final targetHeat = ((omega - 28.0) / (35.0 - 28.0)).clamp(0.0, 1.0);
      heat = ui.lerpDouble(heat, targetHeat, dt * 3.0)!;
    }

    // 3. 🔥 [중요] 비행 및 물리 로직을 위해 부모 update 호출
    // 이때 plate.dart에서 수정한 완화된 비행 조건이 적용됩니다.
    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(tilt);

    _plainBowl.render(canvas, size: size, anchor: Anchor.center);

    _renderRotatingDots(canvas);

    canvas.restore();
  }

  void _renderRotatingDots(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF2C4A8D).withOpacity(0.7)
      ..style = ui.PaintingStyle.fill;

    const int dotCount = 8;
    final double radiusX = size.x * 0.36;
    final double yCenter = size.y * 0.02;

    for (int i = 0; i < dotCount; i++) {
      double currentAngle = (i * (2 * pi / dotCount)) + _dotRotation;

      double x = cos(currentAngle) * radiusX;
      double z = sin(currentAngle);

      if (z > 0) {
        double dotSize = 1.5 + (z * 1.5);

        // ✅ 곡선 보정 핵심:
        // 중앙(x=0)에서 y값이 가장 크고(아래), 양 끝(x=radiusX)으로 갈수록 y값이 작아지도록(위) 설정
        // (1 - x제곱 비율)을 사용하여 아래로 볼록한 곡선을 만듭니다.
        double curveDepth = 8.0; // 곡선의 깊이 (숫자가 클수록 더 많이 휘어짐)
        double curvedY = yCenter + (1 - pow(x / radiusX, 2)) * curveDepth;

        canvas.drawCircle(ui.Offset(x, curvedY), dotSize, paint);
      }
    }
  }
}