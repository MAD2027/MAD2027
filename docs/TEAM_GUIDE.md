# 팀 간 협업 규칙

## 팀 체계

4개 팀(카메라·GPS·라이다·제어)이 나란히 있고, 팀마다 1~2명입니다. **팀장이나 상하 관계는 없습니다** (이슈 #62). 승인이 필수가 아니므로(이슈 #51) 누가 누구를 승인하는 구조가 필요 없기 때문입니다.

| 팀 | 담당 폴더 | 하는 일 | GitHub 팀 |
|---|---|---|---|
| 카메라 | `src/camera/` | 카메라 기반 인지 (차선/객체/신호 인식) | `team-camera` |
| GPS | `src/gps/` | GPS/IMU 기반 측위 및 경로 | `team-gps` |
| 라이다 | `src/lidar/` | 라이다 기반 인지 (장애물/거리) | `team-lidar` |
| 제어 | `src/control/`, `firmware/` | 판단/제어 및 아두이노 펌웨어 | `team-control` |
| 융합 (4팀 공동) | `src/fusion/` | 센서 출력을 합쳐 자율주행 상황 판단 | 전용 팀 없음 |

- **리뷰**: 승인은 필수가 아니고 `CI 통과` 면 작성자가 병합할 수 있습니다. 같은 팀 사람에게 한 번 봐 달라고 부탁하는 것을 권장하고, 같은 팀에 다른 사람이 없으면 아무 팀에나 부탁합니다 ([CONTRIBUTING 6장](CONTRIBUTING.md#누구에게-리뷰를-부탁하나-권장)).
- **팀 일은 팀이 함께 정합니다**: 팀 이슈 나누기, 팀 `AGENTS.md` 규칙, 팀 출력 토픽을 융합에 알리기.
- **여러 팀에 걸친 일**(융합, 인터페이스, 통합 런치, static TF, 릴리스, 차량 실행 일정)은 이슈를 열고 관련 팀이 함께 정합니다. 맡을 사람은 이슈의 Assignees 로 표시합니다.
- **저장소 관리자**(GitHub 팀 `maintainers`): Organization 초대·팀 배치·보호 규칙 같은 관리 업무를 하고, 공용 파일(`docs/`, `scripts/`, `.github/`, `config/`, `src/bringup/`) 리뷰 요청을 받습니다. 팀장이 아니라 관리 담당입니다.
- 리뷰가 자동으로 요청되는 곳은 `config/teams.yml` 의 `code_owners` → `.github/CODEOWNERS` 로 정해집니다. 팀 폴더는 그 팀, 융합·인터페이스는 4팀 모두에게 요청이 갑니다.

## 저장소 구조와 담당

```
src/
├── camera/        카메라 팀 ROS2 패키지
├── gps/           GPS 팀
├── lidar/         라이다 팀
├── control/       제어 팀
├── fusion/        🔀 센서 융합·판단 (mad_fusion) - 4팀 공동 → docs/INTEGRATION.md
├── interfaces/    🔌 팀 간 공용 메시지 (mad_interfaces) - 영향 받는 팀 동의 필요
└── bringup/       🚗 전체 통합 런치 + 노드 상태 감시 (mad_bringup)
firmware/arduino/  아두이노 스케치 (제어 팀)
config/teams.yml   팀 구성 (단일 진실 공급원)
scripts/           개발 도우미 스크립트
docs/              문서
```

- 담당자는 `.github/CODEOWNERS` 로 정해집니다. 이 파일은 `config/teams.yml` 에서 자동 생성되고, 그 폴더가 바뀐 PR 에 담당 팀 리뷰를 자동으로 요청합니다.
- **다른 팀 폴더를 고쳐야 하면** 그 팀에 이슈를 남기거나, 직접 PR 을 올리고 그 팀 사람이 확인한 뒤 병합합니다. 승인이 필수는 아니어서 GitHub 이 막아 주지 않으므로, **다른 팀 폴더를 바꾼 PR 은 그 팀의 확인(댓글이나 Approve) 없이 병합하지 않습니다.**

## 팀 간 인터페이스 (가장 중요)

팀끼리는 **토픽 이름과 메시지 타입**으로만 연결됩니다. 이 약속이 지켜지면 각 팀은 따로 개발해도 마지막에 문제없이 붙습니다.

### 규칙
1. 팀 간에 주고받는 커스텀 메시지는 **반드시** `src/interfaces/mad_interfaces/msg/` 에 정의합니다. 팀 패키지 안에 따로 만들지 않습니다.
2. 표준 메시지(`sensor_msgs`, `geometry_msgs`, `nav_msgs`)로 충분하면 표준 메시지를 씁니다.
3. 토픽 이름, 타입, 발행/구독 팀을 `src/interfaces/mad_interfaces/README.md` 의 표에 기록합니다.
4. **하위 호환을 유지합니다.** 필드는 추가만 하고, 삭제·이름 변경·타입 변경은 하지 않습니다. 꼭 필요하면 새 메시지를 만들고 옛 메시지는 나중에 지웁니다.

### 변경 절차
1. `🔌 인터페이스 변경 요청` 이슈를 생성합니다. 자동으로 `area:shared` 라벨이 붙습니다.
2. **영향 받는 팀(발행·구독하는 팀)마다 한 명 이상**이 이슈에 👍 를 남깁니다. 반대가 있거나 의견이 갈리면 관련 팀이 모여 정하고, 결론을 이슈에 댓글로 남깁니다.
3. `shared/<이슈번호>-<설명>` 브랜치에서 메시지만 바꾸는 **작은 PR** 을 올립니다. 모든 팀이 자동으로 멘션됩니다.
4. 이슈에서 영향 받는 팀 모두의 동의를 확인한 뒤 병합합니다. GitHub 이 승인을 강제하지 않으므로 **동의 확인은 병합하는 사람의 책임**입니다. PR 본문에 동의한 이슈 번호를 적습니다(`Closes #이슈`). 그다음 각 팀이 자기 코드를 맞추는 PR 을 따로 올립니다.

### 각 노드가 지켜야 할 공통 규칙
- 1초에 한 번 이상 `/system/status` (`mad_interfaces/NodeStatus`) 를 발행합니다. `team` 에는 팀 id 를 넣습니다. `system_monitor` 가 노드가 끊기면 경고합니다.
- 파라미터는 코드에 하드코딩하지 말고 `config/*.yaml` 과 `declare_parameter` 로 받습니다.
- 각 팀 패키지에는 `launch/<팀>.launch.py` 를 둡니다. 통합할 준비가 되면 `src/bringup/mad_bringup/launch/system.launch.py` 의 `TEAM_LAUNCHES` 에 한 줄을 추가하는 PR 을 올립니다.
  - `./scripts/new_package.sh` 가 `launch/<팀>.launch.py`(use_sim_time 전달 포함)와 `config/<패키지>.yaml` 을 만들고 설치 등록(`setup.py` / `CMakeLists.txt`)까지 해 둡니다. 노드를 만들면 실행 파일로 등록하고 런치의 `node("...")` 줄만 추가하면 됩니다.
  - 빌드하면 `install/<패키지>/share/<패키지>/launch/`, `.../config/` 로 설치되고, `ros2 launch` 는 이 설치 위치에서 파일을 찾습니다.

## 버전 관리 (모두가 같은 버전을 쓰는 법)

| 무엇 | 어떻게 고정하나 |
|---|---|
| OS / ROS2 | Ubuntu 22.04 + ROS2 Humble. 모든 PC 가 GHCR 의 같은 공용 이미지를 사용 ([TARGET_ENV.md](TARGET_ENV.md)) |
| pip 패키지 | `requirements.txt` 에 `이름==버전` 으로 고정 → 공용 이미지에 포함 |
| ROS 패키지 의존성 | 각 패키지 `package.xml` 에 적음 → 공용 이미지에 포함. 수동 `apt install` 금지 |
| 개발 도구 | `requirements-dev.txt`, `.pre-commit-config.yaml` 에 버전 고정 |
| 아두이노 | `arduino-cli` 버전은 Dockerfile 과 CI 에, 보드·코어·라이브러리 버전은 `sketch.yaml` 의 profile 에 고정 |
| 코드 기준점 | 통합 테스트를 통과한 시점에 **Release 태그**(`v0.3.0`)를 만듭니다. 차량 테스트, 시연, 대회 때는 태그 버전을 사용 |

### 릴리스 만들기 (주 1회 권장, 관리자)
**Actions → 버전 릴리스 → Run workflow** 를 실행합니다. main 의 CI 가 통과 상태일 때만 태그가 만들어지고, 팀별로 분류된 릴리스 노트가 자동으로 작성됩니다.

```bash
# 특정 버전으로 차량 실행
git fetch --tags && git switch --detach v0.3.0
colcon build && ros2 launch mad_bringup system.launch.py
```

## ROS_DOMAIN_ID 배정

같은 와이파이에 있으면 다른 사람의 토픽이 섞입니다. 사람마다 다른 번호를 씁니다.

| 범위 | 사용 |
|---|---|
| `0` | 실제 차량 (통합 테스트) |
| `10~19` | 카메라 팀 개인 |
| `20~29` | GPS 팀 개인 |
| `30~39` | 라이다 팀 개인 |
| `40~49` | 제어 팀 개인 |
| `50~59` | 융합·통합 개발 (융합 작업을 하는 사람) |

```bash
echo 'export ROS_DOMAIN_ID=12' >> ~/.bashrc   # 본인 번호
```
- 평소에는 자기 팀 범위의 번호를 쓰고, 융합 작업 때만 `50~59` 를 씁니다. 같은 팀 안에서 번호가 겹치지 않게 팀끼리 정합니다.
- 여러 사람이 **함께** 통합 테스트할 때는 모두 같은 번호(실제 차량이면 `0`)로 맞춥니다.

## 충돌 해결

충돌은 **자주 main 을 받아오면 작게** 끝납니다. (`./scripts/sync_main.sh`)

```bash
./scripts/sync_main.sh
# CONFLICT (content): Merge conflict in src/camera/.../node.py
# 1) 파일을 열어 <<<<<<< ======= >>>>>>> 부분을 정리 (VS Code: "Accept Both/Current/Incoming")
# 2) 정리 후
git add <파일>
git commit                 # 병합 커밋 완료
./scripts/check.sh         # 빌드/테스트 확인
git push
```

- 남의 팀 코드와 충돌했으면 **혼자 결정하지 말고** 그 코드 작성자에게 물어봅니다. `git log -p <파일>` 로 작성자를 찾을 수 있습니다.
- 꼬였으면 병합을 취소합니다: `git merge --abort`
- 공용 브랜치(main 등)에서 `git push --force` 는 금지입니다. 자기 작업 브랜치에서만, 그것도 꼭 필요할 때만 `--force-with-lease` 를 씁니다.

## 팀 구성 변경하기

팀 이름이나 역할은 언제든 바뀔 수 있습니다. **`config/teams.yml` 한 곳만** 고치면 됩니다.

### 예: "라이다" 팀을 "인지(perception)" 팀으로 바꾸기
1. GitHub Organization → Teams 에서 `team-perception` 을 만들거나 기존 팀 이름을 변경하고, 팀원과 저장소 권한을 확인합니다.
2. `config/teams.yml` 을 수정합니다.
   ```yaml
   - id: perception
     name: 인지
     description: 라이다/카메라 융합 인지
     github_team: team-perception
     color: "5319e7"
     paths:
       - src/perception/
   ```
3. 폴더를 옮기고 생성 파일을 갱신합니다.
   ```bash
   git mv src/lidar src/perception
   python3 scripts/teams.py sync
   ./scripts/check.sh
   ```
4. **PR 을 병합하기 전에** GitHub **Issues → Labels** 에서 예전 라벨 `team:lidar` 의 이름을 `team:perception` 으로 바꿉니다. 이렇게 하면 기존 이슈와 PR 에도 새 이름이 그대로 반영됩니다.
5. `chore/<이슈>-rename-team` 브랜치로 PR 을 올리고 병합합니다. 병합하면 라벨 색상과 설명이 자동으로 갱신됩니다.

### 사람이 팀을 옮기거나 새로 들어올 때
GitHub Organization → Teams 에서 그 사람을 해당 `team-*` 에 넣거나 뺍니다. 저장소 파일은 고칠 필요가 없습니다. 리뷰 요청은 팀 단위(`code_owners`: `team` / `all_teams` / `maintainers`)로 가므로 사람 이름이 설정에 들어가지 않습니다.

`scripts/teams.py sync` 가 다시 만드는 파일:
`.github/CODEOWNERS`, `.github/labeler.yml`, `.github/labels.json`, `.github/teams.json`, `.github/release.yml`, 이슈 양식의 팀 선택지

동기화를 잊으면 CI(`팀 설정 동기화 검사`)가 실패하므로 놓칠 일은 없습니다.

## 데이터 (rosbag 등)

- rosbag, 대용량 모델, 데이터셋은 **저장소에 올리지 않습니다** (`.gitignore` 처리됨). 공유 드라이브에 두고 이슈나 PR 에 링크를 남깁니다.
- 1MB 를 넘는 파일은 pre-commit 이 커밋을 막습니다.
