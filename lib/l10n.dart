import 'language_manager.dart';

class L10n {
  static final _ko = <String, String>{
    'game_title': 'SpinGo',
    'start': '시작하기',
    'confirm': '확인',
    'register': '등록',
    'retry': '다시 도전',
    'exit': '나가기',
    'leaderboard_title': '기록판 (Top 7)',
    'enter_name_hint': '이름을 입력하세요 (한글 ≤5자, 영문/숫자 ≤12자)',
    'congrats': '축하해! 기록을 세웠어 🎉',
    'ai_tip_invalid_name': '형식이 맞지 않아요.',
    'lang': 'Language',
    'skip': '건너뛰기',

    'mode_beginner': '기초 모드',
    'mode_beginner_desc': '접시돌리기를 천천히 익혀요',

    'mode_challenge': '도전 모드',
    'mode_challenge_desc': '바람과 방해꾼을 버티며 엔딩에 도전',

    'mode_brain': '뇌자극 모드',
    'mode_brain_desc': '접시돌리기와 구구단을 함께',

    // 인트로 슬라이드
    'intro1': '재미없는 일상에 지친 노총각 박봉식(41세) 과장은',
    'intro2': '첫사랑을 닮은 그녀를 보며 문득 깨달았다.',
    'intro3': '아직 해보지 못한 일이 많다는 것을...',
    'intro4_man': '\'서커스를 배우고 싶습니다.\'',
    'intro4_master': '\'쉽지 않을 텐데...\'',
    'intro5': '\'뭐야, 저 녀석은?\'',

    // 레벨 메시지
    'lv1_msg': '나무를 비비면 접시가 돌아간다네.',
    'lv1v_msg': '쟁반은 크지만 가벼워.',
    'lv2_msg': '아슬아슬 할수록 관객들이 좋아 하지.',
    'lv2t_msg': '여유를 가지면 시야가 넓어 진다네.',
    'lv2v_msg': '사발은 작고 무거워!',
    'lv2b_msg': '잘 돌지만 속도가 줄면 급격히 흔들리지.',
    'lv3_msg': '조금만 능숙해지면 무대에 설 수도 있겠어.',
    'lv3v_msg': '재능이 있구만. 거의 다 왔으니 힘 내라구.',
    'lv4_msg': '이젠 실전이야. 무대에선 별일이 다 일어나지.',
    'lv4v_msg': '좋았어. 이제부터는 기록 싸움이야.',

    'q_lv1': '기록에 도전해 보자!',
    'q_lv2': '큰 접시는 마찰력이 크다는 걸 기억해.',
    'q_lv3': '이제 두 개의 큰 접시를 동시에 버텨야 한다.',
    'q_lv4': '사발까지 등장했어. 집중해!',
    'q_lv5': '마지막 무대야. 버티는 만큼 기록이 된다.',

    's_lv1': '접시를 돌리며 구구단 정답을 말해 보세요.',
    's_lv2': '접시도, 문제도 놓치지 마세요.',
    's_lv3': '손과 머리를 함께 쓰면 뇌가 자극 됩니다.',

    'stage2_1': '새 무대다. 원숭이가 막대를 흔들어도 버텨라!',
    'stage2_2': '큰 접시가 섞였다. 원숭이 움직임을 조심해.',
    'stage2_3': '이제 두 개의 큰 접시까지 버텨야 한다.',
    'stage2_4': '사발까지 등장했다. 막대를 놓치지 마!',
    'stage2_5': '마지막 확장 무대다. 끝까지 버텨라!',

    // 실패 메시지
    'tip_fly_1': '너무 빨리 돌리면 날아간다고!',
    'tip_fly_2': '욕심부리지 마!',
    'tip_fly_3': '진정해, 한꺼번에 너무 많이 돌리지 마.',
    'tip_fly_4': '접시는 헬리곱터가 아니야!',

    'tip_fall_1': '한눈 팔지 말라구!',
    'tip_fall_2': '대체 어디다 정신을 두고 있는 거야?',
    'tip_fall_3': '생각보다 안 떨어진다고 방심하지 마!',
    'tip_fall_4': '접시에 파리가 앉겠다!',

    'wind_warning': '바람이 불면 조심해야 해!',
    'wind_guide': '바람이 불면 회전속도가 줄어들어.\n더 빠르게 돌려야 해!',
    'monkey_guide': '방해꾼이 흔드는 건\n홀드로 막아야 해.',
    'elephant_guide': '방해꾼이 나오면\n연속 탭으로 물리쳐!',

    // 원숭이 실패 메시지
    'tip_monkey_1': '원숭이가 맘대로 날뛰게 하지 마.',
    'tip_monkey_2': '막대를 꽉 잡고 있어야 해.',
    'tip_monkey_3': '막대를 잡아서 속도를 늦춰야 해.',
    'tip_monkey_4': '원숭이한테 당하고만 있을 수는 없어.',

    // ... 기존 내용 뒤에 추가 ...
    'event1_girl':               '정식 단원이 되신 걸 축하해요.',
    'event2_man': '기념으로 술 한 잔...',
    'event2_monkey': '저런 녀석한테 그녀를 뺏길 수 없지!',
    'finale_man': '아이는 1남 1녀 정도로...',
    'finale_girl':               '그건 좀...',
  };

  static final _en = <String, String>{
    'game_title': 'SpinGo',
    'start': 'Start',
    'confirm': 'OK',
    'register': 'Submit',
    'retry': 'Retry',
    'exit': 'Exit',
    'leaderboard_title': 'Leaderboard (Top 7)',
    'enter_name_hint': 'Enter your name (Korean ≤5 chars, Eng/Num ≤12)',
    'congrats': 'Congrats! New record 🎉',
    'ai_tip_invalid_name': 'Invalid format.',
    'lang': 'Language',
    'skip': 'Skip',

    'mode_beginner': 'Beginner',
    'mode_beginner_desc': 'Learn plate spinning step by step',

    'mode_challenge': 'Challenge',
    'mode_challenge_desc': 'Survive wind and troublemakers to reach the ending',

    'mode_brain': 'Brain Boost',
    'mode_brain_desc': 'Spin plates while solving multiplication',

    // Intro slides
    'intro1': 'Bong-sik Park was tired of his boring life...',
    'intro2': 'Then he met someone like his first love.',
    'intro3': 'And realized he still had dreams to chase...',
    'intro4_man': '\'I want to learn circus.\'',
    'intro4_master': '\'It won’t be easy...\'',
    'intro5': '"Who is that guy?"',

    // Level messages
    'lv1_msg': 'Rub the stick, and the plate will spin.',
    'lv1v_msg': 'Trays are large but light.',
    'lv2_msg': 'The riskier it gets, the louder the cheers.',
    'lv2t_msg': 'Take your time — you’ll see the bigger picture.',
    'lv2v_msg': 'Bowls are small and heavy!',
    'lv2b_msg': 'They spin well but shake hard when slowing down.',
    'lv3_msg': 'A little more skill and you’ll stand on stage.',
    'lv3v_msg': 'You’ve got talent — almost there!',
    'lv4_msg': 'Now it’s real — anything can happen on stage.',
    'lv4v_msg': 'Good! From here, it’s all about records.',

    'q_lv1': 'Let’s go for a new record!',
    'q_lv2': 'Remember: large plates have stronger friction.',
    'q_lv3': 'Now you must keep two large plates spinning at once.',
    'q_lv4': 'Bowls have joined the show. Stay focused!',
    'q_lv5': 'Final stage. Your record depends on how long you survive.',

    's_lv1': 'Spin the plates and say the correct multiplication answer.',
    's_lv2': 'Do not lose track of either the plates or the questions.',
    's_lv3': 'Using your hands and mind together stimulates your brain.',

    'stage2_1': 'A new stage begins. Hold steady even when the monkey shakes the poles!',
    'stage2_2': 'Large plates are mixed in. Watch the monkey carefully.',
    'stage2_3': 'Now you must survive with two large plates.',
    'stage2_4': 'Bowls have joined the stage. Do not lose your grip!',
    'stage2_5': 'Final expansion stage. Survive to the end!',

    // Failure messages
    'tip_fly_1': 'Spin too fast and it’ll fly away!',
    'tip_fly_2': 'Don’t get greedy!',
    'tip_fly_3': 'Easy—don’t swipe too much at once.',
    'tip_fly_4': 'A plate is not a helicopter!',

    'tip_fall_1': 'Eyes on the plate!',
    'tip_fall_2': 'Where’s your focus?',
    'tip_fall_3': 'Don’t relax—plates fall when you least expect.',
    'tip_fall_4': 'Move it, before a fly lands on it!',

    'wind_warning': 'Careful! The wind is coming!',
    'wind_guide': 'Wind slows the plates.\nSpin faster to keep them alive!',
    'monkey_guide': 'Hold the pole to stop\nthe troublemaker!',
    'elephant_guide': 'Tap repeatedly to drive\nthe troublemaker away!',

    // 원숭이 실패 메시지 (English)
    'tip_monkey_1': 'Don\'t let the monkey run wild!',
    'tip_monkey_2': 'Hold on tight to the pole!',
    'tip_monkey_3': 'Grab the pole to slow it down!',
    'tip_monkey_4': 'Don\'t let the monkey beat you!',

    'event1_girl':           'Congratulations on becoming a regular member!',
    'event2_man': 'How about a drink to celebrate...',
    'event2_monkey': 'I can’t let a guy like that take her away!',
    'finale_man': 'Maybe one son and one daughter...',
    'finale_girl':             'That\'s a bit much...',
  };

  static String tr(String key) {
    final lang = LanguageManager.current.value;
    final map = lang == AppLang.en ? _en : _ko;
    return map[key] ?? _ko[key] ?? key;
  }
}
