# 오늘도 던전 영업합니다

> **English title:** Dungeon as Usual  
> **Engine:** Godot 4.x  
> **Language:** GDScript  
> **Platform:** PC  
> **Current scope:** Sprint 1 playable prototype only

## 1. 프로젝트 목적

최종적으로 Steam 출시를 목표로 하는 싱글플레이 던전 경영 게임이다.

Sprint 1에서는 완성된 게임이나 Steam 연동 기능을 만들지 않는다. 다음 핵심 질문을 검증할 수 있는 5~10분 분량의 최소 프로토타입 제작이 목표다.

> 플레이어가 직접 설계한 미지의 던전을 용사가 자동으로 탐험하는 모습을 관찰하는 것이 재미있는가?

그래픽 완성도보다 핵심 관전 루프의 재미와 정보 전달의 명확성을 우선한다.

## 2. 핵심 콘셉트

- 플레이어는 던전의 주인이다.
- 인간 모험가는 던전의 보물을 노리고 침입한다.
- 플레이어는 방 안에 보물, 함정, 몬스터를 배치해 용사를 방해한다.
- 용사는 던전 구조를 미리 알지 못하며 직접 탐험한다.
- 용사가 죽으면 플레이어는 Energy를 얻고 새로운 용사가 입장한다.
- 어느 용사가 마지막 Treasure에 도달하면 현재 Dungeon Run이 종료된다.
- 장기적으로 Energy를 사용한 성장 요소를 고려할 수 있지만 Sprint 1에는 포함하지 않는다.

핵심 플레이 흐름은 다음과 같다.

```text
던전 설계
→ 던전 오픈
→ 용사 자동 탐험 관찰
→ 함정 및 몬스터 조우
→ 사망 시 Energy 획득 및 새 용사 입장
→ Treasure 획득
→ 결과 확인
→ 기존 던전 수정
```

## 3. 화면 및 표현 방식

- 완전한 2D 평면 화면으로 제작한다.
- 3D, 쿼터뷰, 3D 카메라는 사용하지 않는다.
- 던전은 위에서 내려다보는 보드게임판 또는 Node Graph 형태로 표현한다.
- Room은 단순한 사각형이나 원으로 표현할 수 있다.
- Connection은 Room 사이의 선으로 표현한다.
- Hero는 원이나 간단한 아이콘으로 표현할 수 있다.
- 완성된 픽셀아트와 캐릭터 그래픽은 필요하지 않다.

예시:

```text
                 [SLIME]
                    |
[ENTRANCE] -- [EMPTY] -- [SPIKE]
                    |
                 [EMPTY]
                    |
                 [강한 몬스터]
                    |
               [TREASURE]
```

## 4. 게임 상태

게임에는 두 가지 주요 상태만 존재한다.

### 4.1 EDIT MODE

플레이어가 던전을 설계하는 상태다. 게임 시작 시 EDIT MODE로 진입한다.

### 4.2 RUN MODE

던전을 개장하고 Hero의 자동 탐험을 관찰하는 상태다. RUN MODE에서는 던전 구조를 수정할 수 없다.

## 5. 던전 구조

던전은 TileMap이 아닌 Node Graph 방식으로 구현한다.

각 Room은 하나의 Node이며 다른 Room과 Connection을 가진다.

```text
Room
- id
- type
- position
- connections[]
```

### 5.1 Room과 내부 요소

- Room은 일반 방, 입구방, 보물방 역할로 구분되는 사각형이다.
- 입구방과 보물방은 기존 Room에 역할로 설정한다.
- 일반 Room 내부 요소: 가시, 독물, 불구덩이, 약한 몬스터, 중간 몬스터, 강한 몬스터
- 강한 몬스터는 별도 Boss 타입이 아니라 높은 에너지 비용과 능력치를 가진 몬스터다.

### 5.2 유효한 던전 조건

- 입구방은 정확히 1개 존재해야 한다.
- 보물방은 정확히 1개 존재해야 한다.
- 입구방에서 보물방까지 실제로 도달 가능한 경로가 존재해야 한다.
- 조건을 충족하지 못하면 Dungeon을 Open할 수 없다.

## 6. EDIT MODE 요구사항

플레이어가 화면에서 다음 작업을 수행할 수 있어야 한다.

- Room 추가
- Room 삭제
- Room 이동
- Room끼리 연결
- Connection 삭제

최소 UI 기능:

- DEPTH1 메뉴: `방`, `장애물`, `몬스터`, `통로`, `보기`
- 방 DEPTH2: 기본 단일 그리기, 그리기 모드, 입구방 설정, 보물방 설정, 삭제, 삭제 모드
- 장애물·몬스터 DEPTH2: 종류를 선택한 뒤 방을 클릭해 배치
- 통로 DEPTH2: 그리기, 그리기 모드, 삭제, 삭제 모드
- 하단 상태 표시: `입구방 0/1`, `보물방 0/1`, `던전 오픈`
- 기본 상태는 `보기`이며, DEPTH2 내용과 실제 기능은 보기 선택으로 초기화한다.
- 보기에서 빈 맵은 드래그로 이동하고, 통로가 없는 방은 드래그로 이동·크기 조절한다.
- 통로가 연결된 방은 보기에서 이동·크기 조절할 수 없다.
- 통로 첫 번째 마진 칸은 아무 방에서 선택하고, 두 번째는 다른 방의 마주 보는 마진 칸을 선택한다.
- 대각선 마진과 이미 연결된 두 방 사이의 중복 통로는 허용하지 않는다.

입구방과 보물방은 플레이어가 기존 Room에 역할로 설정한다.

보기 상태에서 통로가 연결되지 않은 Room은 드래그로 이동·크기 조절할 수 있다.

## 7. 던전 오픈

플레이어가 `던전 오픈`을 누르면 다음 조건을 검사한다.

1. 입구방이 정확히 1개 설정되어 있는가?
2. 보물방이 정확히 1개 설정되어 있는가?
3. 입구방에서 보물방까지 도달 가능한 경로가 있는가?

모든 조건을 만족하면:

- RUN MODE로 전환한다.
- Dungeon 편집 기능을 비활성화한다.
- 입구방에서 Hero를 생성한다.

## 8. Hero

Sprint 1에서는 Hero 종류를 하나만 구현한다.

| 속성 | 값 |
|---|---:|
| HP | 20 |
| Attack | 4 |

Hero는 던전 전체 구조를 알지 못한다. 각 Hero는 독립적인 탐험 기록을 가진다.

```text
visited_rooms
known_connections
previous_room
current_room
```

Hero가 실제 Dungeon Graph 전체를 사용해 Treasure까지의 최단 경로를 계산해서는 안 된다. 자신이 직접 탐험하며 발견한 정보만 사용해야 한다.

## 9. Hero 탐험 규칙

Hero가 Room에 도착하면 다음 순서로 행동한다.

1. 현재 Room의 효과를 처리한다.
2. 살아 있다면 연결된 Room을 확인한다.
3. 아직 방문하지 않은 Room이 있으면 그중 하나를 무작위로 선택한다.
4. 모든 연결 Room을 방문했다면 이전 경로를 이용해 Backtracking한다.
5. 선택한 Room으로 이동한다.
6. Treasure에 도달할 때까지 반복한다.

Hero의 현재 위치와 이동 방향을 화면에서 명확히 확인할 수 있어야 한다.

## 10. Hero 판단 상태 표시

Hero가 현재 무엇을 하는지 화면에 표시한다.

필요한 상태 예시:

- `EXPLORING`
- `CHOOSING PATH`
- `MOVING`
- `BACKTRACKING`
- `ENTERING SPIKE`
- `FIGHTING SLIME`
- `FIGHTING STRONG MONSTER`
- `FOUND TREASURE`
- `DEAD`

Sprint 1의 Hero AI는 명시적인 규칙과 무작위 선택으로 동작하는 일반 NPC 로직이다. 머신러닝, LLM, 외부 AI API를 사용하지 않는다.

## 11. Room 효과

### 11.1 Empty

효과가 없다.

### 11.2 Spike

- Hero가 Room에 입장하면 HP가 5 감소한다.
- `SPIKE HIT -5`와 같은 결과를 화면에 잠시 표시한다.
- 단순한 구현을 위해 재입장할 때마다 발동해도 된다.

### 11.3 Slime

| 속성 | 값 |
|---|---:|
| HP | 8 |
| Attack | 2 |

Hero가 Slime Room에 들어가면 짧은 간격의 자동 턴 전투를 진행한다.

```text
Hero attacks Slime
→ Slime attacks Hero
→ Hero attacks Slime
→ 한쪽이 죽을 때까지 반복
```

Slime이 죽으면 현재 Dungeon Run이 끝날 때까지 죽은 상태를 유지한다.

### 11.4 중간·강한 몬스터

| 속성 | 값 |
|---|---:|
| 구분 | HP | Attack |
| 중간 몬스터 | 14 | 3 |
| 강한 몬스터 | 20 | 4 |

약한 몬스터와 동일한 방식으로 자동 턴 전투를 진행한다. 강한 몬스터는 높은 에너지 비용으로 배치하는 보스 대용 몬스터이며, 별도 Boss 타입으로 취급하지 않는다.

### 11.5 Treasure

- Hero가 보물 요소가 있는 Room에 도달하면 Treasure를 획득한다.
- Treasure 획득 즉시 현재 Dungeon Run을 종료한다.

## 12. Hero 사망 및 재입장

Hero HP가 0 이하가 되면 사망한다.

사망 시:

- Energy가 10 증가한다.
- Heroes Killed가 1 증가한다.
- 약 1초 후 새 Hero가 Entrance에서 생성된다.
- 새 Hero는 이전 Hero의 탐험 정보를 공유하지 않는다.
- 이미 죽은 몬스터의 상태는 현재 Dungeon Run 동안 유지된다.

RUN MODE에서는 Hero가 죽어도 Dungeon Run이 종료되지 않는다. 새 Hero가 계속 도전하며, 어느 Hero가 Treasure를 획득해야 Run이 종료된다.

## 13. RUN MODE UI

최소한 다음 정보를 표시한다.

```text
Energy: 40
Entered: 6
Killed: 4
Hero HP: 12 / 20
State: EXPLORING
```

필수 항목:

- Energy
- Heroes Entered
- Heroes Killed
- Current Hero HP
- Current Hero State

## 14. 게임 속도

관전 재미를 검증하기 위해 RUN MODE에 다음 배속 버튼을 제공한다.

- `x1`
- `x2`
- `x4`

Hero 이동, 전투, 이벤트 진행 속도는 선택한 배속에 맞춰 변경되어야 한다.

## 15. Hero가 알고 있는 Dungeon 정보

- 플레이어는 Dungeon Owner이므로 전체 Dungeon 구조를 항상 볼 수 있다.
- Hero는 자신의 탐험 기록을 통해 알게 된 정보만 사용한다.
- 가능하면 Hero가 방문한 Room은 정상 표시하고 아직 방문하지 않은 Room은 조금 어둡게 표시한다.
- 미방문 Room을 완전히 숨겨 플레이어가 전체 구조를 파악하기 어렵게 만들지는 않는다.

목적은 플레이어가 Hero의 탐험 범위를 쉽게 이해하게 하는 것이다.

## 16. Treasure 획득 및 결과 화면

Hero가 Treasure를 획득하면 `DUNGEON CLEARED`를 표시하고 결과 화면을 보여준다.

최소 통계:

- Heroes Entered
- Heroes Killed
- Energy Earned
- Rooms Visited
- Trap Hits

예시:

```text
DUNGEON CLEARED

Heroes Entered: 12
Heroes Killed: 11
Energy Earned: 110
Rooms Visited: 73
Trap Hits: 18

[RETURN TO EDIT]
```

`RETURN TO EDIT` 버튼을 누르면 기존 Dungeon 구조를 유지한 채 EDIT MODE로 돌아간다. Sprint 1에서는 획득한 Energy를 소비하는 기능을 구현하지 않는다.

## 17. 코드 구조

프로토타입에 필요한 최소한의 책임 분리를 적용한다.

구조 예시:

- GameManager
- DungeonManager
- DungeonRoom
- Hero
- Monster
- RunManager
- UIManager

정확히 위 구조를 강제하지는 않는다. 현재 기능에 더 단순하고 명확한 구조가 있다면 사용할 수 있다.

- 모든 로직을 하나의 거대한 Script에 넣지 않는다.
- 미래 기능을 예상한 과도한 추상화나 디자인 패턴을 만들지 않는다.

## 18. 게임 데이터

수치를 여러 Script에 반복해서 하드코딩하지 않고 한 곳에서 쉽게 수정할 수 있게 구성한다.

| 대상 | 항목 | 값 |
|---|---|---:|
| Hero | HP | 20 |
| Hero | Attack | 4 |
| Spike | Damage | 5 |
| Slime | HP | 8 |
| Slime | Attack | 2 |
| 중간 몬스터 | HP | 14 |
| 중간 몬스터 | Attack | 3 |
| 강한 몬스터 | HP | 20 |
| 강한 몬스터 | Attack | 4 |
| Hero Death | Energy Reward | 10 |

## 19. Sprint 1 제외 범위

다음 기능은 구현하지 않는다.

- Steamworks, Steam API, Steam Achievement, Steam Cloud
- 멀티플레이 및 온라인 기능
- 서버 및 데이터베이스
- 생성형 AI, 머신러닝, LLM, 외부 AI API
- 복잡한 Pathfinding AI
- 용사 직업, 파티, 성격, 스킬, 장비
- 인간 문명 진화 및 용사 진화
- 던전 진화, 던전 업그레이드, 업그레이드 트리
- 메타 성장
- 보물 등급
- 평판 시스템
- 저장 및 불러오기
- 스토리
- 퀘스트
- 튜토리얼
- 설정 화면
- 완성된 사운드 및 그래픽
- 픽셀아트 제작
- 복잡한 애니메이션

## 20. 구현 원칙

- 나중에 필요할 것 같다는 이유로 시스템을 미리 만들지 않는다.
- 미래 확장성을 위한 불필요한 Architecture를 만들지 않는다.
- 필요하지 않다면 ECS를 도입하지 않는다.
- 필요하지 않다면 외부 Plugin을 추가하지 않는다.
- Steam SDK를 설치하지 않는다.
- 실제 AI를 사용하지 않는다.
- 완성된 Asset을 찾거나 제작하는 데 시간을 사용하지 않는다.
- Sprint 1 완료 조건을 달성하면 추가 기능을 구현하지 않고 종료한다.

## 21. 권장 개발 순서

개발 전 현재 Repository와 프로젝트 구조를 확인한다. Godot 프로젝트가 없다면 Godot 4.x 프로젝트를 생성한다.

1. Godot 프로젝트 실행
2. 2D Room 표시
3. Room 생성
4. Connection 생성
5. Dungeon 유효성 검사
6. Hero 생성
7. Hero Room 이동
8. 미탐험 경로 선택
9. Backtracking
10. Spike
11. Slime 전투
12. 중간·강한 몬스터 전투
13. Hero 사망 및 재생성
14. Treasure
15. Run 종료
16. 결과 화면
17. 속도 조절
18. 전체 플레이 테스트

각 단계에서 프로젝트가 계속 실행 가능한 상태를 유지한다. 가능한 경우 구현 후 실제로 실행해 오류를 확인하며, 컴파일 또는 파싱 오류를 남긴 채 다음 단계로 넘어가지 않는다.

## 22. UX 원칙

이 프로토타입의 핵심은 관전이다. 화려한 연출보다 다음 정보가 명확히 전달되는 것을 우선한다.

- Hero가 현재 어디에 있는가?
- Hero가 어디로 이동하는가?
- Hero가 왜 되돌아가는가?
- 어떤 함정을 밟았는가?
- 어떤 몬스터와 싸우고 있는가?
- Hero HP가 얼마나 남았는가?
- Hero가 죽었는가?
- 새 Hero가 들어왔는가?
- Treasure에 얼마나 가까워졌는가?

## 23. Sprint 1 완료 조건

- [ ] Godot 프로젝트가 정상 실행된다.
- [ ] 2D 평면 Dungeon Editor가 나타난다.
- [ ] Entrance가 존재한다.
- [ ] 플레이어가 여러 Room을 배치할 수 있다.
- [ ] Room끼리 Connection을 만들 수 있다.
- [ ] Spike를 배치할 수 있다.
- [ ] Slime을 배치할 수 있다.
- [ ] 약한·중간·강한 몬스터를 배치할 수 있다.
- [ ] Treasure를 배치할 수 있다.
- [ ] Entrance에서 Treasure까지 유효한 경로를 만들 수 있다.
- [ ] `던전 오픈`을 누를 수 있다.
- [ ] 유효성 검사 후 EDIT MODE에서 RUN MODE로 전환된다.
- [ ] Hero가 Entrance에서 생성된다.
- [ ] Hero가 전체 Dungeon 구조를 모르는 상태에서 탐험한다.
- [ ] 갈림길에서 미탐험 경로를 선택한다.
- [ ] 필요한 경우 Backtracking한다.
- [ ] Spike에 입장하면 피해를 입는다.
- [ ] Slime을 만나면 자동 전투한다.
- [ ] 몬스터를 만나면 자동 전투한다.
- [ ] Hero 사망 시 Energy가 10 증가한다.
- [ ] Hero 사망 후 새로운 Hero가 Entrance에서 생성된다.
- [ ] 새 Hero는 이전 Hero의 탐험 정보를 모른다.
- [ ] Hero들이 Treasure를 찾을 때까지 계속 도전한다.
- [ ] Hero가 Treasure에 도달하면 Dungeon Run이 종료된다.
- [ ] 결과 화면이 표시된다.
- [ ] `RETURN TO EDIT`으로 기존 Dungeon을 다시 수정할 수 있다.
- [ ] `x1`, `x2`, `x4` 속도 조절이 정상 작동한다.

위 항목이 모두 정상적으로 플레이 가능하면 Sprint 1은 완료다. 추가 기능은 구현하지 않는다.

## 24. 작업 완료 보고 형식

작업 완료 후에는 길게 설명하지 않고 다음 내용만 보고한다.

1. 생성하거나 수정한 주요 파일
2. 게임 실행 방법
3. 현재 구현된 기능
4. 알려진 버그 또는 한계
5. Sprint 1 완료 조건 중 미완료 항목 여부

