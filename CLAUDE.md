<!-- 자동 생성 (scripts/teams.py sync). 규칙은 같은 폴더의 AGENTS.md 에 쓴다 - 모든 AI 도구 공용 -->
@AGENTS.md

<!-- CLAUDE NOTES: 이 줄 아래는 scripts/teams.py sync 가 지우지 않는다 -->

# 공용 개발 시스템 정비 - 할 일 목록 (Claude 인계용)

> 공동 개발 시스템 정비가 끝날 때까지 Claude 로 작업하므로 여기에 둡니다. 다음 세션은 **작업 전에 이 목록을 읽고, 항목을 끝내면 같은 PR 에서 이 구역을 갱신**합니다. 정비가 끝나면 이 구역을 지웁니다.
> 이 구역은 `scripts/teams.py sync` 가 지우지 않습니다 (위 표시줄 아래).
> 마지막 갱신: 2026-11-16 (이슈 #64 주간·월간 자동 백업 추가, D5·D6 결정). 진행 상황의 기준은 GitHub 이슈·PR 이고, 이 파일은 요약입니다.

## 진행 규칙
- 이 목록의 항목은 **사용자(전체 팀장)에게 확인받은 뒤** 진행합니다. 결정(D) 이 필요한 항목은 결정 전에 시작하지 않습니다.
- 항목마다 이슈 → `shared/<이슈>-<설명>` 브랜치 → PR (CONTRIBUTING.md, AGENTS.md "작업 절차").
- 끝난 항목은 아래 "완료" 로 옮기고 PR 번호를 적습니다.

## 현재 상태 (2026-11-16)
- **조직(D3 결정: 8~9명)**: 전체 팀장 1 + 팀장 4 + 팀원 3~4. **제어팀 = 자율주행팀이 센서 3팀 상위, 자율주행팀 팀장 = 제어 팀장** (이슈 #59, 문서에서만 상위 표현, GitHub 팀 중첩 안 함, 융합 주 담당 = 제어 팀장, 센서 PR 리뷰 요청에 `team-control` 추가 안 함). **팀당 팀장 1 + 팀원 0~1** → 팀원 없이 팀장 혼자인 팀이 생길 수 있음. README·TEAM_GUIDE·ORG_SETUP 인원 숫자는 C1(#47)에서 반영.
- **GitHub 팀 구성(실제)**: `leads`·`maintainers` = Anjabom, S1Ron1124 / `team-camera`·`team-gps`·`team-lidar`·`team-control` = Anjabom 만. 다른 팀장·팀원은 아직 미배치 (H1).
- **승인 체계 (D4 결정 A, 이슈 #51)**: PR 승인은 **필수 아님**. 병합 조건 = PR + `CI 통과` + 대화 Resolve, Squash. 작성자가 병합 가능
  - `.github/CODEOWNERS` 는 유지하되 **리뷰 자동 요청용**만 (팀 폴더 = `team-*`·`leads`·`maintainers`, `src/fusion/`·`src/interfaces/` = `leads`, 그 밖 = `maintainers`)
  - 리뷰 권장: 같은 팀끼리(팀원 PR=팀장, 팀장 PR=팀원). 다른 팀 폴더를 바꾼 PR 은 그 팀 확인 후 병합
  - `src/interfaces/` 는 승인 대신 **인터페이스 변경 요청 이슈에서 전원 동의** 확인 후 병합 (확인 책임 = 병합하는 사람)
  - GitHub Ruleset `main 보호` 도 같은 설정으로 변경 완료 (H2, 2026-11-16). 이슈 #53 PR 이 승인 없이 병합되면 동작 확인 끝
- **열린 PR**: 이슈 #64 PR(자동 백업). 이슈 #55 PR(C3 완료 기록). #60(#59)·#54(#53)·#52·#48·#46 병합됨, #56(C3 기록 첫 시도)은 #60 과 충돌·조직도 미반영이라 닫음. #54 가 리뷰 0건으로 병합되어 승인 필수 없음(H2) 동작 확인 끝. 11-12 기준으로 열려 있던 #43·#44·#40·#27·Dependabot #2~#5 도 모두 병합됨
  - #40(`setup-host.sh`)은 H4 실제 실행 검증 **전에** 병합됨 → H4 는 여전히 필요, 문제가 나오면 후속 PR 로 수정
- 센서 팀 폴더(`src/camera|gps|lidar|control/`)는 아직 문서만 있고 패키지 없음. `fusion_inputs.yaml`·`static_tf.yaml` 은 빈 목록 (팀 개발 시작 후 채움, 이 목록 범위 밖)
- `config/target_env.yml`(본체 노트북 기준 사양)이 비어 있음 (H3)

## A. 결정 필요 (사용자)
| # | 결정 | 선택지 | 막힌 작업 |
|---|---|---|---|
| D1 | ~~팀장이 쓴 코드의 승인 방식~~ **결정: B** (2026-11-12) | 팀 폴더는 같은 팀 사람끼리 서로 승인(팀원 PR=팀장, 팀장 PR=팀원), 다른 팀장(`leads`)·전체 팀장(`maintainers`)은 대리. 팀원이 없는 팀의 팀장 PR 은 대리 승인 | C1 |
| D2 | 팀장 4명의 GitHub 아이디 (자율주행팀 팀장 = 제어 팀장으로 확정, 이슈 #59) | - | C2, H1 |
| D3 | ~~조직 인원~~ **결정: 8~9명** (2026-11-12) | 팀원 수가 정해지면 TEAM_GUIDE 역할 표에 반영 | C1, C3 |
| D4 | ~~PR 필수 승인 유지 여부~~ **결정: A** (2026-11-16) | 필수 승인만 제거, PR·`CI 통과` 필수와 CODEOWNERS(리뷰 요청용) 유지. 인터페이스는 이슈 전원 동의 | 이슈 #51 |
| D5 | ~~백업 대상~~ **결정: (a)+(b)** (2026-11-16) | 저장소 전체 `git bundle` + GitHub 기록(이슈·PR·댓글 등 JSON). rosbag 은 범위 밖 | 이슈 #64 |
| D6 | ~~백업 보관 위치~~ **결정: A** (2026-11-16) | 이 저장소 프리릴리스 `backup-*`, 주간 5개·월간 12개 보존, 노션 `작업 기록` DB 에 행 추가. 외부 보관(별도 저장소·클라우드)은 필요할 때 후속 | 이슈 #64 |

## B. 사람(관리자)이 할 일
| # | 할 일 | 비고 |
|---|---|---|
| H1 | 팀장·팀원 Organization 초대, GitHub 팀 배치 (팀장 → `leads`·`maintainers`·자기 `team-*`, 팀원 → 자기 `team-*`). 각 `team-*` 의 저장소 권한이 **Write** 인지 확인 (push·리뷰 요청에 필요) | Org 관리자만 가능. AI 는 팀 구성원을 바꿀 수 없음 |
| ~~H2~~ | ~~Ruleset `main 보호` 승인 0, Code Owners·Dismiss stale 끄기~~ **완료** (2026-11-16). 승인 없이 병합되는지는 이슈 #53 PR 로 확인 | ORG_SETUP 5장 |
| H3 | 본체 노트북에서 `python3 scripts/env_check.py --capture` → PR | `.wslconfig`·설치 스크립트의 사양 기준 |
| H4 | `scripts/installer/setup-host.sh`(#40, 이미 병합) 실제 실행 검증: WSL(이미 수동 설치한 PC 에서 "건너뜀" 동작), 가능하면 새 Ubuntu 22.04 | 결과(멈춘 화면)를 AI 에 전달 → 수정 |
| H5 | PR 리뷰·병합. 남은 것: 이슈 #55 PR (C3 완료 기록). 병합된 #27 은 컨테이너에서 `ros2 launch mad_bringup system.launch.py use_sim_time:=true` 확인 권장 | 승인은 필수 아님 (#52). `CI 통과` 후 작성자가 병합 가능 |
| H6 | 병합된 #6(actions/labeler 5→7) 이 다음 팀 PR 에서 `team:xxx` 라벨을 붙이는지 확인 | 안 붙으면 #6 되돌리기, `teams.py gen_labeler` 확인 |
| H7 | 팀원별 ROS_DOMAIN_ID 배정·공유 | 팀당 10개 범위 (TEAM_GUIDE) |
| H8 | 이슈 #64 PR 병합 후 **Actions → 자동 백업 → Run workflow** (weekly) 로 한 번 실행: Releases 에 `backup-weekly-...` 프리릴리스, 노션 `작업 기록` 에 `주간 백업` 행이 생기는지 확인. 다음 `버전 릴리스` 의 릴리스 노트가 백업 태그가 아닌 이전 `v*` 기준인지도 확인 | docs/BACKUP.md |

## C. AI(Claude 등) 가 할 일
| # | 할 일 | 산출물 | 선행 |
|---|---|---|---|
| C2 | (선택) 4팀과 융합(`fusion`)의 `lead:` 에 팀장 아이디 → `python3 scripts/teams.py sync` → CODEOWNERS 갱신. 승인 필수가 아니라 팀장 개인에게 리뷰 요청이 가게 하는 용도 | 작은 PR | D2, H1 |
| C5 | 윈도우 설치 파일: `scripts/installer/windows/MAD-설치.cmd` + `setup-windows.ps1`(가상화 검사, WSL·Ubuntu-22.04, winget 으로 VS Code·Git·확장, `.wslconfig`, 재부팅 후 이어하기, WSL 에서 함께 든 `setup-host.sh` 실행) + **서명 없는** `MAD-Setup.exe`(Inno Setup, 릴리스 워크플로가 windows 러너에서 만들어 Releases 첨부). 문서에 SmartScreen "추가 정보 → 실행" 안내 | PR 1개 | H4 |
| C6 | (선택) Copilot·Gemini 용 연결 파일을 `teams.py sync` 가 생성(`AGENTS.md` 를 따르라는 짧은 파일), AI 규칙 숙지 점검 시나리오 문서 | PR 1개 | 다른 AI 도구 사용자가 생기면 |

## 권장 순서
1. ~~D1, D3 결정~~ (완료). D2(팀장 아이디)는 대기
2. ~~#46 병합 → C1 → #52 병합 → H2~~ (완료), H1
3. H3, H7
4. ~~C3~~ (완료). C2 는 선택
5. H4 → C5
6. H6 (다음 팀 PR 에서), H8 (#64 병합 후)
7. C6 (필요할 때)

## 참고 (작업하며 알게 된 것)
- `.gitignore` 의 `install/` 이 colcon 출력뿐 아니라 모든 `install/` 폴더를 무시함 → 설치 스크립트는 `scripts/installer/` 에 둠
- `.pre-commit-config.yaml` 의 `name:` 값에 `: ` 가 들어가면 따옴표로 감싸야 함 (안 그러면 `pre-commit install` 이 조용히 일부 훅만 설치)
- 루트·팀 폴더의 `CLAUDE.md` 는 `teams.py sync` 가 만드는 파일. 루트 `CLAUDE.md` 의 `CLAUDE NOTES` 표시줄 아래(이 구역)만 sync 가 보존한다. 팀 규칙은 `AGENTS.md` 에 쓴다 (다른 AI 도구도 읽도록)
- GitHub 에서 Draft 를 해제하면서 팀 리뷰어를 같이 요청하면 "Validation Failed" 가 날 때가 있음 → 리뷰어만 다시 요청하면 됨
- 노션 기록은 진행 리포트와 백업이 `.github/scripts/report.js` 의 `notion`·`text`·`block` 을 함께 씀. 노션 DB 열 이름을 바꾸면 `backup.js` 도 고쳐야 함
- 클라우드 AI 세션은 Docker/ROS 가 없어 `colcon build`·`check.sh` 를 못 함 → PR "테스트 방법" 에 실행하지 못했다고 적고, CI 결과와 사람의 컨테이너 확인으로 보완

## 완료
| 항목 | PR |
|---|---|
| fusion.launch.py `use_sim_time` 인자, BEGINNER.md, GitHub SSH 로그인, dev.sh git 연동 | #29 |
| PR·승인 흐름 문서 (Merging is blocked, 권한 오류, https 전환, 한눈에 보기) | #33 |
| 팀 폴더 승인 = 팀장(`leads`) + 전체 팀장(`maintainers`) 예비, `teams.yml` `lead`/`code_owners` | #36 |
| 조직과 역할 표, ROS_DOMAIN_ID 50~59, 인터페이스 변경 전원 동의 | #38 |
| actions/labeler 5→7 | #6 (H6 확인 필요) |
| 런치 use_sim_time·센서 static TF·새 패키지 런치 템플릿 | #27 |
| 개발 환경 자동 설치 스크립트 `setup-host.sh` | #40 (H4 검증 필요) |
| git 훅(커밋 메시지·브랜치·main push 검사), `finish_task.sh` | #43 |
| AGENTS.md 작업 절차 체크리스트, AI 작업 요청 양식 | #44 |
| Dependabot: checkout 5→7, cache 4→6, docker/login-action 3→4, setup-python 6→7 | #2 #3 #4 #5 |
| ~~C4: #27 용 이슈 연결~~ → #27 이 병합되어 불필요 | - |
| 할 일 목록을 루트 CLAUDE.md 메모 구역에 기록 (이슈 #45) | #46 |
| C1: 같은 팀끼리 서로 승인(D1=B) - `code_owners` 에 `team`, 4팀 `[team, leads, maintainers]`, CONTRIBUTING·TEAM_GUIDE·ORG_SETUP·README 8~9명 기준 (이슈 #47) | #48 |
| 할 일 목록 갱신, H2 승인 없이 병합 확인 (이슈 #53) | #54 |
| 필수 승인 제거(D4=A): CI 통과만으로 병합, CODEOWNERS 는 리뷰 요청용, 인터페이스는 이슈 전원 동의 (이슈 #51). Ruleset 변경(H2) 완료 | #52 |
| 조직 개편: 제어팀(자율주행팀)을 센서 3팀 상위로, 자율주행팀 팀장 = 제어 팀장, 문서에서만 상위 표현 (이슈 #59) | #60 |
| C3: 교육 자료 갱신 - "MAD 개발 교본"(https://claude.ai/artifact/UyaDFHe2VnQzd9SEUjRjZi) 초보자 기준 재작성(컴퓨터 기초, 저장소 구조, 이슈→병합 따라하기, 용어 사전), "MAD 팀 구조 점검"(https://claude.ai/artifact/U3URe3BEjjpQeaWvmCaGky) 승인 없는 병합 체계로, 두 페이지 모두 제어팀 상위 조직도(#59) 반영 (이슈 #55). 페이지는 저장소 밖(소유자 계정)이라 다음 갱신도 같은 주소로 | 이슈 #55 PR |
| 주간·월간 자동 백업: `backup.yml`(bundle + GitHub 기록 JSON → 프리릴리스, 보존 5/12, 실패 시 `ci:backup-failure` 이슈), 노션 `작업 기록` DB 에 백업 행, `docs/BACKUP.md` 복원 방법 (이슈 #64, D5·D6) | 이슈 #64 PR (H8 확인 필요) |
