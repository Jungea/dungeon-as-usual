# 오늘도 던전 영업합니다

**Dungeon as Usual**

플레이어가 직접 던전을 설계하고, 던전 구조를 모르는 용사들이 자동으로 탐험하는 모습을 관찰하는 2D 던전 경영 게임 프로토타입입니다.

> 함정 점검 완료. 몬스터 배치 완료. 오늘도 정상 영업합니다.

## 프로젝트 정보

- 엔진: Godot 4.7.2
- 언어: GDScript
- 플랫폼: PC
- 현재 버전: Sprint 1 프로토타입
- 저장소: `https://github.com/Jungea/dungeon-as-usual`

## 게임 플레이

플레이어는 던전 주인이 되어 방과 연결을 배치합니다. 던전을 개장하면 용사가 입구에서 출발해 자신이 발견한 정보만 이용하며 탐험합니다.

```text
던전 설계
→ 던전 영업 시작
→ 용사 자동 탐험
→ 함정 및 몬스터 조우
→ 용사 사망 시 에너지 획득 및 새 용사 입장
→ 보물 획득
→ 결과 확인
→ 던전 수정
```

## 실행 방법

1. [Godot 4.7.2](https://godotengine.org/download/windows/)를 설치합니다.
2. Godot 프로젝트 관리자에서 `project.godot`를 가져옵니다.
3. 프로젝트 폴더를 다음 위치로 지정합니다.

   ```text
   D:\practice\Dungeon\project.godot
   ```

4. 프로젝트를 열고 `F5` 또는 실행 버튼을 누릅니다.

## 플레이 방법

### 던전 편집

1. `빈 방 추가`, `가시 함정 추가`, `슬라임 추가`, `보스 추가`, `보물 추가` 버튼을 누릅니다.
2. 게임판 안쪽을 클릭해 Room을 배치합니다.
3. `방 연결`을 누르고 연결할 두 Room을 차례로 클릭합니다.
4. 입구에서 보물까지 연결된 경로를 만듭니다.
5. `던전 영업 시작`을 누릅니다.

### 편집 기능

- `방 삭제`: 선택한 Room을 삭제합니다.
- `연결 삭제`: 두 Room을 차례로 클릭해 연결을 삭제합니다.
- `던전 수정하기`: Run 종료 후 편집 모드로 돌아갑니다.

### 관전 기능

- `x1`, `x2`, `x4`: 용사 이동과 전투 속도를 조절합니다.
- 밝은 Room: 용사가 방문한 Room
- 어두운 Room: 용사가 아직 방문하지 않은 Room
- 주황색 원: 현재 용사의 위치

## Sprint 1 구현 범위

- 2D Node Graph 방식 던전 편집
- Entrance, Empty, Spike, Slime, Boss, Treasure Room
- Room 추가·삭제
- Connection 생성·삭제
- Entrance → Treasure 경로 유효성 검사
- 용사의 독립 탐험 기록
- 미탐험 경로 무작위 선택
- Backtracking
- Spike 피해 처리
- Slime 및 Boss 자동 턴 전투
- Hero 사망, Energy 획득, 새 Hero 재입장
- Treasure 획득 및 Run 종료
- 결과 통계 화면
- x1/x2/x4 속도 조절

## 프로젝트 구조

```text
.
├─ project.godot
├─ main.tscn
├─ scripts/
│  ├─ main.gd
│  ├─ dungeon_manager.gd
│  ├─ dungeon_room.gd
│  ├─ hero.gd
│  └─ game_data.gd
├─ GAME_REQUIREMENTS.md
├─ logs/
│  └─ SPRINT_1.md
└─ README.md
```

- `main.gd`: 게임 화면, UI, 편집 모드와 영업 모드 제어
- `dungeon_manager.gd`: Dungeon Graph와 경로 유효성 검사
- `dungeon_room.gd`: Room 데이터
- `hero.gd`: 용사 탐험 기록과 이동 규칙
- `game_data.gd`: HP, 공격력, 피해량 등 공통 수치

## 알려진 한계

- Room은 드래그 이동이 아닌 클릭 배치 방식입니다.
- 그래픽, 사운드, 애니메이션은 프로토타입 수준입니다.
- 저장 및 불러오기를 지원하지 않습니다.
- Steam 기능은 아직 구현하지 않았습니다.
- Sprint 2 이후 기능은 포함하지 않습니다.

자세한 요구사항과 작업 기록은 [GAME_REQUIREMENTS.md](GAME_REQUIREMENTS.md)와 [logs/SPRINT_1.md](logs/SPRINT_1.md)에서 확인할 수 있습니다.

