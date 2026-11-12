<!-- 자동 생성 (scripts/teams.py sync). 규칙은 같은 폴더의 AGENTS.md 에 쓴다 - 모든 AI 도구 공용 -->
@AGENTS.md

<!-- CLAUDE NOTES: 이 줄 아래는 scripts/teams.py sync 가 지우지 않는다 -->

# 공용 개발 시스템 정비 - 할 일 목록 (Claude 인계용)

> 공동 개발 시스템 정비가 끝날 때까지 Claude 로 작업하므로 여기에 둡니다. 다음 세션은 **작업 전에 이 목록을 읽고, 항목을 끝내면 같은 PR 에서 이 구역을 갱신**합니다. 정비가 끝나면 이 구역을 지웁니다.
> 이 구역은 `scripts/teams.py sync` 가 지우지 않습니다 (위 표시줄 아래).
> 마지막 갱신: 2026-11-12 (이슈 #45, 루트 CLAUDE.md). 진행 상황의 기준은 GitHub 이슈·PR 이고, 이 파일은 요약입니다.

## 진행 규칙
- 이 목록의 항목은 **사용자(전체 팀장)에게 확인받은 뒤** 진행합니다. 결정(D) 이 필요한 항목은 결정 전에 시작하지 않습니다.
- 항목마다 이슈 → `shared/<이슈>-<설명>` 브랜치 → PR (CONTRIBUTING.md, AGENTS.md "작업 절차").
- 끝난 항목은 아래 "완료" 로 옮기고 PR 번호를 적습니다.

## 현재 상태 (2026-11-12)
- **조직(D3 결정: 8~9명)**: 전체 팀장 1 + 팀장 4(그중 1명 자율주행팀 팀장 겸임) + 팀원 3~4. **팀당 팀장 1 + 팀원 0~1** → 팀원 없이 팀장 혼자인 팀이 생길 수 있음. 문서 일부(README "팀당 약 4명", ORG_SETUP "16명", TEAM_GUIDE 역할 표 "약 17명")는 팀당 4명 기준 → C1 에서 수정.
- **GitHub 팀 구성(실제)**: `leads`·`maintainers` = Anjabom, S1Ron1124 / `team-camera`·`team-gps`·`team-lidar`·`team-control` = Anjabom 만. 다른 팀장·팀원은 아직 미배치 (H1).
- **승인 체계(main)**: `.github/CODEOWNERS` 기준
  - 팀 폴더(`src/camera|gps|lidar|control/`, `firmware/`) = `leads` 또는 `maintainers`
  - `src/fusion/`, `src/interfaces/` = `leads`
  - 그 밖의 공용 파일 = `maintainers`
  - 팀원(`team-*`)은 승인 권한 없음. 누구도 자기 PR 은 승인 불가 → **팀장이 쓴 코드는 다른 팀장 또는 전체 팀장이 승인** (D1=B 로 바꾸는 중 → C1)
  - `config/teams.yml` 의 팀별 `lead:`(팀장 아이디)는 비어 있음 (C2)
  - 보호 규칙(ORG_SETUP 5장): 승인 1, Code Owners 필수, 새 push 시 승인 무효, 대화 Resolve 필수, `CI 통과` 필수, Squash. 실제 설정은 미확인 (H2)
- **열린 PR (권장 병합 순서)**: #43 git 훅·`finish_task.sh` → #44 AGENTS.md 작업 절차(#43 필요) → Dependabot #2~#5 (하나씩) → #27 런치 use_sim_time·static TF·패키지 템플릿 → #40 설치 스크립트(H4 검증 후)
- `config/target_env.yml`(본체 노트북 기준 사양)이 비어 있음 (H3)

## A. 결정 필요 (사용자)
| # | 결정 | 선택지 | 막힌 작업 |
|---|---|---|---|
| D1 | ~~팀장이 쓴 코드의 승인 방식~~ **결정: B** (2026-11-12) | 팀 폴더는 같은 팀 사람끼리 서로 승인(팀원 PR=팀장, 팀장 PR=팀원), 다른 팀장(`leads`)·전체 팀장(`maintainers`)은 대리. 팀원이 없는 팀의 팀장 PR 은 대리 승인 | C1 |
| D2 | 팀장 4명의 GitHub 아이디, 자율주행팀 팀장이 누구인지 | - | C2, H1 |
| D3 | ~~조직 인원~~ **결정: 8~9명** (2026-11-12) | 팀원 수가 정해지면 TEAM_GUIDE 역할 표에 반영 | C1, C3 |

## B. 사람(관리자)이 할 일
| # | 할 일 | 비고 |
|---|---|---|
| H1 | 팀장·팀원 Organization 초대, GitHub 팀 배치 (팀장 → `leads`·`maintainers`·자기 `team-*`, 팀원 → 자기 `team-*`) | Org 관리자만 가능. AI 는 팀 구성원을 바꿀 수 없음 |
| H2 | 저장소 Settings → Rules 의 실제 보호 규칙이 ORG_SETUP 5장과 같은지 확인 | |
| H3 | 본체 노트북에서 `python3 scripts/env_check.py --capture` → PR | `.wslconfig`·설치 스크립트의 사양 기준 |
| H4 | PR #40 `scripts/installer/setup-host.sh` 실제 실행 검증: WSL(이미 수동 설치한 PC 에서 "건너뜀" 동작), 가능하면 새 Ubuntu 22.04 | 결과(멈춘 화면)를 AI 에 전달 → 수정 |
| H5 | PR 리뷰·병합 (위 권장 순서). #27 은 컨테이너에서 `ros2 launch mad_bringup system.launch.py use_sim_time:=true` 확인 | 작성자 본인은 승인 불가 |
| H6 | 병합된 #6(actions/labeler 5→7) 이 다음 팀 PR 에서 `team:xxx` 라벨을 붙이는지 확인 | 안 붙으면 #6 되돌리기, `teams.py gen_labeler` 확인 |
| H7 | 팀원별 ROS_DOMAIN_ID 배정·공유 | 팀당 10개 범위 (TEAM_GUIDE) |

## C. AI(Claude 등) 가 할 일
| # | 할 일 | 산출물 | 선행 |
|---|---|---|---|
| C1 | **2명 이하 팀 기준 승인·역할 정리 (D1=B)**: `scripts/teams.py` 의 `code_owners` 에 `team`(= 그 팀 `github_team`) 을 쓸 수 있게 하고 4팀을 `code_owners: [team, leads, maintainers]` 로 → sync → CODEOWNERS 예: `/src/camera/ @MAD2027/team-camera @MAD2027/leads @MAD2027/maintainers`. 문서: CONTRIBUTING 6장 "누가 승인하나"(팀원 PR=팀장, 팀장 PR=팀원, 팀원 없는 팀·부재 시 다른 팀장/전체 팀장), TEAM_GUIDE 역할 표 8~9명·"1차 리뷰" 규칙 수정, 융합 주 담당=자율주행팀 팀장, ORG_SETUP 팀 표·Ruleset 설명, README·ORG_SETUP 인원 숫자 | PR 1개 | (결정 완료) |
| C2 | 4팀과 융합(`fusion`)의 `lead:` 에 팀장 아이디 → `python3 scripts/teams.py sync` → CODEOWNERS 갱신 | 작은 PR | D2, H1 |
| C3 | 교육 자료 웹 페이지 갱신: "MAD 개발 교본"(https://claude.ai/artifact/UyaDFHe2VnQzd9SEUjRjZi), "MAD 팀 구조 점검"(https://claude.ai/artifact/U3URe3BEjjpQeaWvmCaGky) 을 9명 기준·확정 승인 체계로, 병합된 PR 의 "리뷰 중" 표시 정리 | 페이지 갱신 (같은 주소, 소유자 계정에서) | C1 병합 |
| C4 | PR #27 용 이슈를 만들어 본문에 `Closes #` 연결 (규칙 봇 경고 해소) | 이슈 1개 | 없음 |
| C5 | 윈도우 설치 파일: `scripts/installer/windows/MAD-설치.cmd` + `setup-windows.ps1`(가상화 검사, WSL·Ubuntu-22.04, winget 으로 VS Code·Git·확장, `.wslconfig`, 재부팅 후 이어하기, WSL 에서 함께 든 `setup-host.sh` 실행) + **서명 없는** `MAD-Setup.exe`(Inno Setup, 릴리스 워크플로가 windows 러너에서 만들어 Releases 첨부). 문서에 SmartScreen "추가 정보 → 실행" 안내 | PR 1개 | H4, #40 병합 |
| C6 | (선택) Copilot·Gemini 용 연결 파일을 `teams.py sync` 가 생성(`AGENTS.md` 를 따르라는 짧은 파일), AI 규칙 숙지 점검 시나리오 문서 | PR 1개 | 다른 AI 도구 사용자가 생기면 |

## 권장 순서
1. ~~D1, D3 결정~~ (완료). D2(팀장 아이디)는 대기
2. C4 → C1 (동시에 H1)
3. H5: #43 → #44 병합, H3, H7
4. C2 → C3
5. H4 → #40 병합 → C5
6. H6, Dependabot·#27 병합
7. C6 (필요할 때)

## 참고 (작업하며 알게 된 것)
- `.gitignore` 의 `install/` 이 colcon 출력뿐 아니라 모든 `install/` 폴더를 무시함 → 설치 스크립트는 `scripts/installer/` 에 둠
- `.pre-commit-config.yaml` 의 `name:` 값에 `: ` 가 들어가면 따옴표로 감싸야 함 (안 그러면 `pre-commit install` 이 조용히 일부 훅만 설치)
- 루트·팀 폴더의 `CLAUDE.md` 는 `teams.py sync` 가 만드는 파일. 루트 `CLAUDE.md` 의 `CLAUDE NOTES` 표시줄 아래(이 구역)만 sync 가 보존한다. 팀 규칙은 `AGENTS.md` 에 쓴다 (다른 AI 도구도 읽도록)
- GitHub 에서 Draft 를 해제하면서 팀 리뷰어를 같이 요청하면 "Validation Failed" 가 날 때가 있음 → 리뷰어만 다시 요청하면 됨
- 클라우드 AI 세션은 Docker/ROS 가 없어 `colcon build`·`check.sh` 를 못 함 → PR "테스트 방법" 에 실행하지 못했다고 적고, CI 결과와 사람의 컨테이너 확인으로 보완

## 완료
| 항목 | PR |
|---|---|
| fusion.launch.py `use_sim_time` 인자, BEGINNER.md, GitHub SSH 로그인, dev.sh git 연동 | #29 |
| PR·승인 흐름 문서 (Merging is blocked, 권한 오류, https 전환, 한눈에 보기) | #33 |
| 팀 폴더 승인 = 팀장(`leads`) + 전체 팀장(`maintainers`) 예비, `teams.yml` `lead`/`code_owners` | #36 |
| 조직과 역할 표, ROS_DOMAIN_ID 50~59, 인터페이스 변경 전원 동의 | #38 |
| actions/labeler 5→7 | #6 (H6 확인 필요) |
