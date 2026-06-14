// lib/components/basketball.dart
import 'dart:math';
import 'dart:ui' as ui; // Gradient
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 구의 윗부분을 잘라내고(아랫부분 40%만 남김),
/// 절단면(타원) + 벽 두께(오렌지 링) + 내부 흰색 + 회전 점선(두께 위)을 표시.
/// 검은 홈선/무늬 없음.
class Basketball extends PositionComponent {
  double radius;
  double omega;     // 점선 회전 속도
  double friction;  // 감속
  double angle = 0; // 회전 위상

  final Color base = const Color(0xFFEB7A2D);   // 오렌지(외피/벽두께)
  final Color shadow = const Color(0xFFB4541E); // 아래쪽 그늘(볼륨)
  final Color inner = Colors.white;             // 내부 색

  Basketball({
    required Vector2 position,
    this.radius = 60,
    this.omega = 8.0,
    this.friction = 0.6,
  }) : super(position: position, size: Vector2.all(1), anchor: Anchor.center, priority: 1000);

  @override
  void update(double dt) {
    super.update(dt);
    omega = max(0, omega - friction * dt);
    angle = (angle + omega * dt) % (pi * 2);
  }

  @override
  void render(Canvas canvas) {
    final r = radius;
    final c = Offset.zero;

    // ---- 절단 높이: 아래 40%만 남기기 → 평면 y = +0.2r
    final double yCut = r * 0.20;

    // 절단 원 반지름
    final double rPlane = sqrt(max(0, r * r - yCut * yCut));

    // 살짝 위에서 내려다보는 시점 → 타원
    const double perspective = 0.56; // 0.50~0.65 조절
    final double cutW = rPlane * 2;
    final double cutH = max(1, rPlane * 2 * perspective);

    // 벽 두께(px)
    final double wall = max(2.0, r * 0.08);

    // ---- 1) 하단 반구(40%) 그리기
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-r * 3, yCut, r * 3, r * 3));
    canvas.drawCircle(c, r, Paint()..color = base);

    final radialPaint = Paint()
      ..shader = ui.Gradient.radial(
        c.translate(0, r * 0.35),
        r * 1.1,
        [Colors.transparent, shadow.withOpacity(0.85)],
        [0.35, 1.0],
      );
    canvas.drawCircle(c, r, radialPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.35, -r * 0.45),
        width: r * 0.8,
        height: r * 0.5,
      ),
      Paint()..color = Colors.white.withOpacity(0.18),
    );
    canvas.restore();

    // ---- 2) 절단 타원 + 내부
    final Rect outerCutRect = Rect.fromCenter(center: Offset(0, yCut), width: cutW, height: cutH);
    final Rect innerCutRect = outerCutRect.deflate(wall);

    // 바깥 절단 타원(오렌지) = 벽 두께 바탕
    canvas.drawOval(outerCutRect, Paint()..color = base);

    // 내부 흰색 + 살짝 그늘
    if (innerCutRect.width > 0 && innerCutRect.height > 0) {
      canvas.drawOval(innerCutRect, Paint()..color = inner);
      final innerShade = Paint()..color = Colors.black.withOpacity(0.06);
      final Rect shadeRect = innerCutRect.translate(0, innerCutRect.height * 0.12);
      canvas.drawOval(shadeRect, innerShade);
    }

    // 얇은 외곽선(옵션)
    canvas.drawOval(
      outerCutRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF3A1E0E).withOpacity(0.20),
    );
    if (innerCutRect.width > 0 && innerCutRect.height > 0) {
      canvas.drawOval(
        innerCutRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.black.withOpacity(0.10),
      );
    }

    // ---- 3) 벽 두께 링에 "회전 점선" (앞/뒤 전부)
    if (innerCutRect.width > 0 && innerCutRect.height > 0) {
      _drawDottedWallRim(
          canvas: canvas,
          outerRect: outerCutRect,
          innerRect: innerCutRect,
          phase: angle,        // 회전 위상
          dotCount: 40,        // 48~64 권장
          onlyFrontHalf: false // ✅ 뒤쪽까지 이어지게
      );
    }

    // 전체 외곽선 아주 옅게(옵션)
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF0D0D0D).withOpacity(0.10),
    );
  }

  /// 벽 두께 링 중앙선을 따라 회전하는 점선
  /// - onlyFrontHalf=false이면 뒤쪽(윗반원)도 그리되, 뒤쪽은 옅게
  void _drawDottedWallRim({
    required Canvas canvas,
    required Rect outerRect,
    required Rect innerRect,
    required double phase,
    int dotCount = 56,
    bool onlyFrontHalf = true,
  }) {
    final cx = (outerRect.left + outerRect.right) / 2;
    final cy = (outerRect.top + outerRect.bottom) / 2;

    final rx = ((outerRect.width / 2) + (innerRect.width / 2)) / 2;
    final ry = ((outerRect.height / 2) + (innerRect.height / 2)) / 2;

    final wall = (outerRect.width - innerRect.width) / 2;
    final double rDot = wall * 0.45; // 0.30~0.45

    // 뒤쪽(윗반원) 먼저 옅게 그리기 → 앞쪽 점이 덮여 자연스러운 겹침
    if (!onlyFrontHalf) {
      final Paint backP = Paint()..color = const Color(0xFF311B0B).withOpacity(0.30);
      for (int i = 0; i < dotCount; i++) {
        final theta = phase + (2 * pi / dotCount) * i;
        final dx = cx + rx * cos(theta);
        final dy = cy + ry * sin(theta);
        // 화면 좌표계에서 뒤쪽은 dy <= cy (타원 윗쪽)
        if (dy <= cy) {
          canvas.drawCircle(Offset(dx, dy), rDot, backP);
        }
      }
    }

    // 앞쪽(아랫반원) 선명하게
    final Paint frontP = Paint()..color = const Color(0xFF311B0B).withOpacity(0.85);
    for (int i = 0; i < dotCount; i++) {
      final theta = phase + (2 * pi / dotCount) * i;
      final dx = cx + rx * cos(theta);
      final dy = cy + ry * sin(theta);
      if (onlyFrontHalf) {
        if (dy > cy) {
          canvas.drawCircle(Offset(dx, dy), rDot, frontP);
        }
      } else {
        // 전체를 그리되 앞쪽은 진하게
        if (dy > cy) {
          canvas.drawCircle(Offset(dx, dy), rDot, frontP);
        } else {
          // 뒤쪽은 위에서 이미 옅게 그려졌음
          // 필요 시 여기서도 한 번 더 옅게 그릴 수 있음.
        }
      }
    }
  }
}
