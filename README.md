# 오늘도 던전 영업합니다

**Dungeon as Usual**

플레이어가 직접 던전을 설계하고, 던전 구조를 모르는 용사들이 자동으로 탐험하는 모습을 관찰하는 2D 던전 경영 게임 프로토타입입니다.

> 함정 점검 완료. 몬스터 배치 완료. 오늘도 정상 영업합니다.

## 프로젝트 정보

- 엔진: Godot 4.7.2
- 언어: GDScript
- 플랫폼: PC
- 현재 버전: Sprint 3 프로토타입
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

1. 기본 상태는 `보기`입니다. 빈 맵을 드래그하면 맵이 이동하고, 방을 드래그하면 방이 이동합니다.
2. `방` 메뉴를 선택하면 기본 단일 그리기 상태가 됩니다. 맵을 클릭해 격자에 맞는 3×3칸 Room을 만듭니다.
3. `방`의 DEPTH2에서 `그리기 모드`를 선택하면 Room을 연속으로 만들 수 있습니다.
4. `입구방 설정` 또는 `보물방 설정`을 선택한 뒤 대상 Room을 클릭합니다.
5. `장애물`·`몬스터` 메뉴에서 종류를 선택한 뒤 대상 Room을 클릭합니다.
6. Room을 맞닿게 배치한 뒤 `통로` 메뉴에서 두 마진 칸을 차례로 클릭합니다. 첫 번째는 아무 방에서, 두 번째는 다른 방의 마주 보는 마진에서 선택합니다.
7. 입구방에서 정확히 1개의 보물방까지 연결된 경로를 만듭니다.
8. 하단의 `입구방 0/1`, `보물방 0/1`을 확인하고 `던전 오픈`을 누릅니다.

### 편집 기능

- `방`의 `삭제`: Room 하나를 삭제하고, `삭제 모드`: 연속으로 삭제합니다.
- `통로`의 `삭제`: 통로 하나를 삭제하고, `삭제 모드`: 연속으로 삭제합니다.
- 통로가 연결된 Room은 보기 상태에서 이동·크기 조절할 수 없습니다.
- `보기`: DEPTH2 내용과 실제 작업을 해제하고 기본 보기 상태로 돌아갑니다.
- `던전 수정`: Run 종료 후 편집 모드로 돌아갑니다.

### 관전 기능

- `x1`, `x2`, `x4`: 용사 이동과 전투 속도를 조절합니다.
- 밝은 Room: 용사가 방문한 Room
- 어두운 Room: 용사가 아직 방문하지 않은 Room
- 주황색 원: 현재 용사의 위치

## Sprint 1 구현 범위

- 2D Node Graph 방식 던전 편집
- 일반 Room과 내부 요소(보물, 가시, 약한·중간·강한 몬스터)
- Room 추가·삭제
- 맞닿은 Room 사이의 문 생성·삭제
- 입구방 → 보물방 경로 유효성 검사
- 용사의 독립 탐험 기록
- 미탐험 경로 무작위 선택
- Backtracking
- Spike 피해 처리
- 약한·중간·강한 몬스터 자동 턴 전투
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

- Sprint 2에서 Room 자유 그리기·이동·크기 조절을 지원합니다.
- 그래픽, 사운드, 애니메이션은 프로토타입 수준입니다.
- 저장 및 불러오기를 지원하지 않습니다.
- Steam 기능은 아직 구현하지 않았습니다.
- Sprint 3에서는 방 이름, 방 번호, 진행 분석, 종료 통계, 미니맵을 추가했습니다. 확장 기능은 [SPRINT_4_REQUIREMENTS.md](SPRINT_4_REQUIREMENTS.md)로 미룹니다.

자세한 요구사항과 작업 기록은 [GAME_REQUIREMENTS.md](GAME_REQUIREMENTS.md), [SPRINT_2_REQUIREMENTS.md](SPRINT_2_REQUIREMENTS.md), [SPRINT_3_REQUIREMENTS.md](SPRINT_3_REQUIREMENTS.md), [SPRINT_4_REQUIREMENTS.md](SPRINT_4_REQUIREMENTS.md), [logs/SPRINT_2.md](logs/SPRINT_2.md)에서 확인할 수 있습니다.

