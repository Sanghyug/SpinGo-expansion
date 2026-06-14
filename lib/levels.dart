enum PlateType { normal, tray, bowl }

class PlateSet {
  final PlateType type;

  PlateSet(this.type);
}

// ❌ 에러 해결: TransformSet 클래스가 없어서 발생한 에러를 위해 추가
class TransformSet {
  final PlateType to;

  TransformSet(this.to);
}

class Level {
  final int index;
  final Duration duration;
  final String background;
  final String messageKey;
  final List<PlateSet> sets;

  // ❌ 에러 해결: 정의되지 않았던 매개변수들을 추가
  final bool isVariation;
  final List<TransformSet> transforms;
  final bool showEventScene; // [추가] 이벤트 씬 출력 여부

  Level({
    required this.index,
    required this.duration,
    required this.background,
    required this.messageKey,
    required this.sets,
    this.isVariation = false, // 기본값 설정
    this.transforms = const [], // 기본값 설정
    this.showEventScene = false, // [추가] 기본값은 false로 설정
  });
}

final List<Level> beginnerLevels = [
  Level(
    index: 1,
    duration: const Duration(seconds: 30),
    background: "backimage1.png",
    messageKey: "lv1_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal)
    ],
  ),
  Level(
    index: 1,
    duration: const Duration(seconds: 30),
    background: "backimage1.png",
    messageKey: "lv1v_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.normal),
    ],
    isVariation: true,
    transforms: [TransformSet(PlateType.tray)],
  ),
  Level(
    index: 2,
    duration: const Duration(seconds: 40),
    background: "backimage2.png",
    messageKey: "lv2_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.tray),
    ],
  ),
  Level(
    index: 2,
    duration: const Duration(seconds:40),
    background: "backimage2.png",
    messageKey: "lv2t_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.tray),
    ],
  ),
  Level(
    index: 2,
    duration: const Duration(seconds: 50),
    background: "backimage2.png",
    messageKey: "lv2v_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.bowl),
    ],
    isVariation: true,
    transforms: [TransformSet(PlateType.bowl)],
  ),
  Level(
    index: 2,
    duration: const Duration(seconds: 60),
    background: "backimage2.png",
    messageKey: "lv2b_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.bowl),
    ],
  ),
  Level(
    index: 3,
    duration: const Duration(seconds: 60),
    background: "backimage3.png",
    messageKey: "lv3_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.bowl),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.tray),
    ],
  ),
  Level(
    index: 3,
    duration: const Duration(seconds: 60),
    background: "backimage3.png",
    messageKey: "lv3v_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.normal),
      PlateSet(PlateType.bowl),
      PlateSet(PlateType.bowl),
      PlateSet(PlateType.tray),
    ],
    isVariation: true,
    transforms: [TransformSet(PlateType.tray)],
  ),
  Level(
    index: 4,
    duration: const Duration(days: 60),
    background: "backimage4.png",
    messageKey: "lv4_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.bowl),
      PlateSet(PlateType.bowl),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.tray),
    ],
  ),
  Level(
    index: 4,
    duration: const Duration(days: 90),
    background: "backimage4.png",
    messageKey: "lv4v_msg",
    sets: [
      PlateSet(PlateType.normal),
      PlateSet(PlateType.bowl),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.tray),
      PlateSet(PlateType.tray),
    ],

  ),
];

// ──────────────────────────────────────────────────────────────
// 2단계: 무한 변형 모드 (5개 세트 고정, 1분 30초 간격)
// ──────────────────────────────────────────────────────────────
final List<Level> expertLevels = [
  Level(index: 1,
      duration: const Duration(seconds: 20),
      background: "backimage2.png",
      messageKey: "q_lv1",
      sets: List.generate(5, (_) => PlateSet(PlateType.normal))),
  Level(index: 2,
      duration: const Duration(seconds: 20),
      background: "backimage2.png",
      messageKey: "q_lv2",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray)
      ]),
  Level(index: 3,
      duration: const Duration(seconds: 20),
      background: "backimage3.png",
      messageKey: "q_lv3",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.tray)
      ]),
  Level(index: 4,
      duration: const Duration(seconds: 20),
      background: "backimage3.png",
      messageKey: "q_lv4",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.bowl)
      ]),
  Level(index: 5,
      duration: const Duration(seconds: 20),
      background: "backimage4.png",
      messageKey: "q_lv5",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.bowl),
        PlateSet(PlateType.bowl)
      ],
  // 레벨 종료 후 이벤트 씬 활성화 플래그 추가
  showEventScene: true,
  ),
];

// lib/levels.dart에 Stage 2용 데이터 추가
final List<Level> stage2Levels = [
  // 1분: All 접시 (5개)
  Level(index: 101,
      duration: const Duration(minutes: 1),
      background: "backimage4.png",
      messageKey: "stage2_1",
      sets: List.generate(5, (_) => PlateSet(PlateType.normal))),
  // 1분: 접시4 + 큰 접시1
  Level(index: 102,
      duration: const Duration(minutes: 1),
      background: "backimage4.png",
      messageKey: "stage2_2",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray)
      ]),
  // 1분: 접시3 + 큰 접시2
  Level(index: 103,
      duration: const Duration(minutes: 1),
      background: "backimage4.png",
      messageKey: "stage2_3",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.tray)
      ]),
  // 1분: 접시2 + 큰 접시2 + 사발1
  Level(index: 104,
      duration: const Duration(minutes: 1),
      background: "backimage4.png",
      messageKey: "stage2_4",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.bowl)
      ]),
  // 최종: 접시1 + 큰 접시2 + 사발2 (실장님 기획 최종안)
  Level(index: 105,
      duration: const Duration(minutes: 5),
      background: "backimage4.png",
      messageKey: "stage2_5",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.bowl),
        PlateSet(PlateType.bowl)
      ]),
];

// ──────────────────────────────────────────────────────────────
// 3단계: 구구단 실버 모드 (4개 세트 고정)
// ──────────────────────────────────────────────────────────────
final List<Level> brainBoosterLevels = [
  Level(index: 1,
      duration: const Duration(seconds: 60),
      background: "backimage1.png",
      messageKey: "s_lv1",
      sets: List.generate(4, (_) => PlateSet(PlateType.normal))),
  Level(index: 2,
      duration: const Duration(seconds: 90),
      background: "backimage2.png",
      messageKey: "s_lv2",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray)
      ]),
  Level(index: 3,
      duration: const Duration(days: 99),
      background: "backimage4.png",
      messageKey: "s_lv3",
      sets: [
        PlateSet(PlateType.normal),
        PlateSet(PlateType.normal),
        PlateSet(PlateType.tray),
        PlateSet(PlateType.bowl)
      ]),
];
