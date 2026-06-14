import 'package:flame/components.dart';
import 'plate.dart';
import 'dart:math';
import 'dart:ui' as ui;

// big_plate.dart 수정본
class BigPlate extends Plate {
  BigPlate({required Vector2 center, required String imagePath})
      : super(
    center: center,
    imagePath: imagePath,
    friction: 2.8,
    // 마찰력 2.8
    maxTilt: 0.7,
    // 기울기 임계값 1.2
    omegaMax: 28,
    // 28 이상 비행
    initialOmega: 18,
    plateSize: Vector2(180, 180),
  );

  @override
  void boost(double input) {
    // 🔥 접시보다 스와이프에 20% 빨리 반응 (1.2배)
    super.boost(input * 1.2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 🔥 과열 시작점 재정의 (24 이상)
    final targetHeat = ((omega - 24.0) / (28.0 - 24.0)).clamp(0.0, 1.0);
    heat = ui.lerpDouble(heat, targetHeat, dt * 3.0)!;
  }
}