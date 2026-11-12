# 개발 흐름 (모든 팀원 필독)

> 핵심 규칙 3가지
> 1. **모든 작업은 이슈에서 시작한다.** 이슈가 없으면 아무도 내가 뭘 하는지 모른다.
> 2. **main 에 직접 push 하지 않는다.** 브랜치 → PR → 리뷰 → 병합.
> 3. **작게, 자주 병합한다.** 브랜치는 2~3일 안에 병합. 오래 들고 있을수록 합칠 때 아프다.
>
> **AI 도구(Claude Code, Codex, Grok 등)를 써도 규칙은 같다.** AI 가 만든 코드의 책임은 PR 을 올린 사람에게 있고, 리뷰와 병합은 사람이 한다. AI 는 공용 컨테이너 안에서 실행한다. → [AI_TOOLS.md](AI_TOOLS.md)

```
 이슈 생성 ──▶ 브랜치 생성 ──▶ 개발/커밋 ──▶ Draft PR ──▶ 리뷰 요청 ──▶ CI 통과 + 승인 ──▶ Squash 병합
 (보드: Todo)  (In Progress)                (보드에 보임)  (In Review)                      (Done, 이슈 자동 닫힘)
```

## 0. 한눈에 보기

### 처음 한 번 (PC 마다)
| # | 할 일 | 어디서 | 자세히 |
|---|---|---|---|
| 1 | GitHub 가입 → **MAD2027 Organization 초대 수락** → 관리자가 내 팀에 추가 (= push 권한) | 웹 | [GUIDE.md 2장](GUIDE.md#2-새-팀원--새-노트북에-적용하기-약-3060분) |
| 2 | Docker, VS Code 설치 (윈도우는 WSL2 안) | 호스트 | [DEV_ENV.md](DEV_ENV.md) |
| 3 | 이름/이메일 설정, **SSH 키 등록**, `ssh -T git@github.com` 확인 (= 이 PC 를 내 GitHub 계정과 연결) | 호스트 | [DEV_ENV.md - GitHub 로그인](DEV_ENV.md#github-로그인-ssh-키-pc-마다-처음-한-번) |
| 4 | `git clone git@github.com:MAD2027/MAD2027.git ~/mad2027` (저장소 받기) | 호스트 | 〃 |
| 5 | `code .` → **Reopen in Container** (또는 `./scripts/dev.sh`) | 호스트 | [DEV_ENV.md](DEV_ENV.md) |
| 6 | `./scripts/check.sh` 가 통과하면 준비 끝 | 컨테이너 | [GUIDE.md 2장](GUIDE.md#2-새-팀원--새-노트북에-적용하기-약-3060분) |

### 작업할 때마다
| # | 할 일 | 명령 / 화면 | 자세히 |
|---|---|---|---|
| 1 | 이슈 만들고 Assignees 에 나 | GitHub **Issues → New issue** | [1장](#1-이슈-만들기) |
| 2 | 작업 브랜치 만들기 | `./scripts/start_task.sh <팀> <이슈번호> <설명>` | [2장](#2-브랜치-만들기) |
| 3 | 코드 수정 → 커밋 (여러 번 해도 됨) | `git add -p` → `git commit -m "<팀>: ... (#이슈)"` | [3장](#3-개발하고-커밋하기) |
| 4 | 매일 최신 main 받기 | `./scripts/sync_main.sh` | [3장](#3-개발하고-커밋하기) |
| 5 | 올리기 전 검사 | `./scripts/check.sh <팀>` | [4장](#4-pr-올리기) |
| 6 | GitHub 에 올리기 | `git push -u origin HEAD` (다음부터 `git push`) | [4장](#4-pr-올리기) |
| 7 | 승인 요청서(PR) 만들기 → 완성되면 **Ready for review** | 터미널에 나온 링크 → **Create draft pull request** | [4-1](#4-1-웹에서-pr-만들기-화면-따라하기) |
| 8 | CI 실패·수정 요청 반영 | 같은 브랜치에서 고쳐 `git push` (같은 PR 에 자동 반영) | [5장](#5-리뷰와-ci-결과에-대응하기-pr-을-올린-사람) |
| 9 | 담당 팀 승인 + `CI 통과` → **Squash and merge** | PR 화면 | [7장](#7-병합) |
| 10 | 내 PC 정리 후 다음 이슈로 | `git switch main && git pull --ff-only` | [7장](#7-병합) |

> 명령은 모두 **컨테이너 터미널**에서 실행합니다 (`# [호스트]` 표시가 있는 것 제외). 터미널 구분은 [BEGINNER.md 1장](BEGINNER.md#1-터미널이-세-종류-있다).

## 1. 이슈 만들기

GitHub → **Issues → New issue** → 양식 선택

| 양식 | 언제 |
|---|---|
| ✨ 기능 개발 | 새 기능, 개선, 일반 작업 |
| 🐞 버그 | 오동작 |
| 🔌 인터페이스 변경 요청 | 팀 간 메시지(`src/interfaces/`) 추가/변경 |

- **담당 팀**을 고르면 `team:xxx` 라벨이 자동으로 붙고 보드에 등록됩니다.
- 작업을 시작할 때 오른쪽 **Assignees** 에 자기 자신을 지정하세요. 이렇게 해야 "누가 하는지"가 보입니다. (`status:in-progress` 라벨이 자동으로 붙습니다)
- 3일 넘게 걸릴 작업은 여러 이슈로 나눕니다.
- 다른 팀 작업을 기다리고 있으면 `status:blocked` 라벨을 붙이고, 무엇을 기다리는지 댓글로 남깁니다.

## 2. 브랜치 만들기

이름 규칙: `<팀>/<이슈번호>-<짧은-설명>` (영문 소문자, 하이픈)

```bash
./scripts/start_task.sh camera 12 lane-offset
# = git fetch origin main && git switch -c camera/12-lane-offset origin/main
```

`커밋하지 않은 변경이 있습니다. 먼저 커밋하거나 git stash 하세요.` 로 멈추면 (`git status` 로 무엇이 바뀌었는지 먼저 확인):

| 상황 | 해결 |
|---|---|
| 이전 작업 브랜치에서 하던 일 | 그 브랜치에서 `git add` → `git commit` (필요하면 `git push`) 후 다시 `start_task.sh` |
| 브랜치를 만들기 전에 **main 에서 이미 코드를 고쳐 버림** | 변경을 잠시 치워 두고 새 브랜치로 옮깁니다: `git stash` → `./scripts/start_task.sh ...` → `git stash pop` |
| 필요 없는 변경 (실험, 실수) | 파일 하나: `git restore <파일>`, 전부: `git restore .` (**되돌릴 수 없으니** `git diff` 로 확인 후) |

> `git stash pop` 에서 충돌이 나면 [TEAM_GUIDE.md - 충돌 해결](TEAM_GUIDE.md#충돌-해결) 과 같은 방법으로 정리합니다. stash 한 내용은 `git stash list` 로 볼 수 있습니다.

| 접두사 | 용도 |
|---|---|
| `camera/`, `gps/`, `lidar/`, `control/` | 각 팀 작업 (`config/teams.yml` 의 팀 id) |
| `shared/` | 인터페이스, 통합 런치 등 공용 작업 |
| `hotfix/`, `docs/`, `chore/` | 긴급 수정, 문서, 빌드/환경 |

## 3. 개발하고 커밋하기

```bash
git add -p                      # 바꾼 부분을 확인하며 담기
git commit -m "camera: 차선 중심 오프셋 계산 추가 (#12)"
```

- 커밋 메시지는 `<팀>: <무엇을 했는지> (#이슈번호)` 형식으로 씁니다.
- 커밋할 때 pre-commit 이 코드 스타일을 자동으로 검사하고 고칩니다. 고쳐진 파일이 있으면 `git add` 후 다시 커밋하세요.
- git 훅이 규칙을 바로 검사합니다 (사람이든 AI 든 같음):

  | 언제 | 검사 | 막히면 |
  |---|---|---|
  | 커밋할 때 | 메시지가 `<팀>: <내용> (#이슈번호)` 인지 (Merge·Revert 는 통과) | 메시지만 고쳐 같은 명령으로 다시 커밋 |
  | push 할 때 | main 에 직접 push 하는지, 브랜치 이름이 `<팀>/<이슈번호>-<설명>` 인지 | `git branch -m <새 이름>` 후 다시 push |

  훅은 `./scripts/dev.sh`, `./scripts/check.sh` 가 자동으로 설치합니다 (예전에 만든 컨테이너면 `pre-commit install` 한 번).
- **하루에 한 번 이상** main 의 최신 변경을 받아옵니다. 충돌을 작을 때 해결하기 위해서입니다.
  ```bash
  ./scripts/sync_main.sh
  ```

## 4. PR 올리기

```bash
# [컨테이너] 한 번에: 검사 → push(처음이면 -u 자동) → 제목·Closes #이슈 가 채워진 PR 생성 링크 출력
./scripts/finish_task.sh
```
```bash
# [컨테이너] 직접 할 때 (위 스크립트가 하는 일과 같음)
./scripts/check.sh camera        # 로컬 검사 (스타일 + 빌드 + 테스트). 전체는 인자 없이
git push -u origin HEAD          # 이 브랜치를 처음 push 할 때. 그 다음부터는 git push 만
```

push 하면 터미널에 PR 생성 링크가 나옵니다. `finish_task.sh` 의 링크는 제목(`[팀] 마지막 커밋 내용`)과 본문의 `Closes #이슈번호` 가 미리 채워져 있습니다. PR 이 이미 있으면 push 만으로 그 PR 에 반영됩니다.

- **작업 초반에 Draft PR 을 열어 두세요.** 다른 사람이 진행 상황을 볼 수 있습니다.
- 제목은 `[camera] 차선 중심 오프셋 발행` 형식으로 쓰고, 본문에는 `Closes #12` 를 넣습니다. 그래야 병합할 때 이슈가 자동으로 닫힙니다.
- 완성되면 **Ready for review** 를 누릅니다. 바꾼 폴더의 승인권자(팀 폴더는 **그 팀 팀장**과 `leads`)에게 리뷰가 자동으로 요청됩니다. 같은 팀원에게도 Reviewers 에서 직접 리뷰를 요청해 두면 좋습니다.

### 4-1. 웹에서 PR 만들기 (화면 따라하기)

1. push 후 터미널에 나온 `https://github.com/MAD2027/MAD2027/pull/new/camera/12-lane-offset` 링크를 엽니다.
   (또는 GitHub 저장소 첫 화면 위쪽의 노란 띠 → **Compare & pull request**. 안 보이면 **Pull requests** 탭 → **New pull request** → compare 에서 내 브랜치 선택)
2. 맨 위 줄이 **`base: main` ← `compare: camera/12-lane-offset`** 인지 확인합니다. base 는 항상 `main` 입니다.
3. **제목**: `[camera] 차선 중심 오프셋 발행` 처럼 `[팀] 무엇을 했는지`.
4. **본문**: 양식(템플릿)이 자동으로 채워져 있습니다. 지우지 말고 칸만 채웁니다.
   - `Closes #` 뒤에 이슈 번호 (`Closes #12`). 숫자 앞에 띄어쓰기 없이 `#12`.
   - `- [ ]` 를 `- [x]` 로 바꾸면 체크됩니다 (`x` 는 영어 소문자, 괄호 안 공백 없이). 미리보기(**Preview** 탭)에서 확인할 수 있습니다.
   - 테스트 방법: 리뷰어가 그대로 따라 칠 수 있는 명령을 적습니다. 실행하지 못한 테스트가 있으면 못 했다고 씁니다.
   - `<!-- ... -->` 는 화면에 보이지 않는 안내문이므로 그대로 둬도 됩니다.
5. 아래쪽 초록 버튼 옆 **▼** 를 눌러 **Create draft pull request** 를 고릅니다 (아직 작업 중일 때). 다 끝났으면 **Create pull request**.
6. 만든 뒤에도 제목은 제목 옆 **Edit**, 본문은 본문 오른쪽 위 **···** → **Edit** 으로 언제든 고칠 수 있습니다.

> 같은 브랜치로 PR 을 두 번 만들 수 없습니다. 이미 PR 이 있으면 **더 push 하는 것만으로 그 PR 에 반영**됩니다. 새 PR 을 만들지 않습니다.

### 4-2. PR 화면 둘러보기

| 탭 | 여기서 보는 것 |
|---|---|
| **Conversation** | 본문, 리뷰 댓글, 봇 안내 댓글, 맨 아래 검사(CI) 결과와 병합 버튼 |
| **Commits** | 이 PR 에 들어간 커밋 목록 |
| **Checks** | CI 각 단계의 성공/실패와 로그 |
| **Files changed** | **실제로 바뀐 줄** (초록 = 추가, 빨강 = 삭제). Ready for review 를 누르기 전에 여기서 내 변경을 한 번 훑어보고, 디버그용 코드나 관계없는 파일이 섞이지 않았는지 확인합니다 |

### 4-3. "📋 PR 규칙 확인" 댓글이 달렸을 때

PR 을 만들거나 고칠 때마다 봇이 규칙을 검사하고, 어긋난 것이 있으면 `⚠️` 댓글을 답니다. 고치면 **같은 댓글이 자동으로 갱신**되어 `✅ 모든 규칙을 지켰습니다` 로 바뀝니다.

| 안내 | 해결 |
|---|---|
| 브랜치 이름이 규칙과 다름 | 브랜치 이름은 PR 을 만든 뒤 바꾸기 어렵습니다. 작은 PR 이면 그대로 두고 리뷰어에게 알리며, 다음부터 `./scripts/start_task.sh` 로 브랜치를 만듭니다 |
| `Closes #이슈번호` 가 없음 | 본문을 Edit 해서 `Closes #12` 를 넣습니다. 이슈가 없으면 먼저 이슈를 만듭니다 |
| AI 도구 확인 항목 미체크 | AI 를 썼다면 코드를 직접 읽고 이해한 뒤 템플릿의 "AI 가 만든 코드를 직접 읽고..." 를 `[x]` 로 체크합니다 |
| 변경량이 400줄 초과 | 기능 단위로 PR 을 나눕니다 (예: 메시지 정의 / 노드 / launch). 나누기 어려우면 리뷰어와 상의합니다 |

## 5. 리뷰와 CI 결과에 대응하기 (PR 을 올린 사람)

### CI 가 실패했을 때 (❌)
1. PR **Conversation** 맨 아래 검사 목록에서 ❌ 항목 오른쪽 **Details** 를 누릅니다.
2. 왼쪽에서 빨간 단계를 펼쳐 **처음 나오는 에러 메시지**를 찾습니다 (맨 마지막 줄이 아니라 위쪽에 원인이 있는 경우가 많습니다).

   | 실패한 검사 | 주된 원인 | 고치는 법 |
   |---|---|---|
   | 코드 스타일 / 팀 설정 동기화 | 스타일 검사(pre-commit) 없이 커밋됨 | `pre-commit run --all-files` → 고쳐진 파일 `git add` → 커밋 |
   | ROS2 빌드 / 테스트 | 빌드 에러, 테스트 실패, `package.xml` 의존성 누락 | `./scripts/check.sh <팀>` 으로 내 PC 에서 같은 에러를 재현해 고침 |
   | 아두이노 컴파일 | 스케치 문법 오류, 라이브러리 미등록 | `arduino-cli compile firmware/arduino/<스케치>` |
3. 같은 브랜치에서 고치고 커밋한 뒤 `git push` 하면 CI 가 자동으로 다시 돕니다.
4. 내 변경과 관계없어 보이는 실패(main 이 이미 깨졌거나 네트워크 오류)라면 PR 에 댓글로 남기고 팀 리더에게 알립니다. **테스트를 지우거나 건너뛰게 만들어서 통과시키지 않습니다.**

### 리뷰에서 수정 요청을 받았을 때
리뷰 결과는 **Approved**(승인), **Changes requested**(수정 요청), **Commented**(의견만) 중 하나입니다.
1. **Files changed** 또는 **Conversation** 에서 리뷰 댓글을 하나씩 읽습니다. 이해가 안 되면 그 댓글에 **Reply** 로 질문합니다.
2. 코드를 고칩니다. **같은 브랜치에서** 커밋하고 push 하면 같은 PR 에 반영됩니다.
   ```bash
   # [컨테이너]
   git switch camera/12-lane-offset          # 다른 브랜치에 있었다면 PR 브랜치로
   # ... 수정 ...
   git add -p && git commit -m "camera: 리뷰 반영 - 타임아웃 파라미터화 (#12)"
   git push
   ```
3. 반영한 댓글에는 "반영했습니다" 처럼 짧게 답하고 **Resolve conversation** 을 누릅니다. 반영하지 않기로 한 것은 이유를 답글로 남깁니다 (Resolve 는 리뷰어가 해도 됩니다).
4. 오른쪽 **Reviewers** 의 리뷰어 이름 옆 🔄 (Re-request review) 를 눌러 다시 봐 달라고 요청합니다.

> 리뷰 중 main 이 많이 바뀌었으면 `./scripts/sync_main.sh` 후 `git push`. PR 화면의 **Update branch** 버튼을 눌렀다면 내 PC 에서 `git pull` 로 받아온 뒤 작업합니다.

### "Merging is blocked" 가 뜰 때
PR 맨 아래에 `Merging is blocked - Waiting on code owner review from MAD2027/...` 이 보이면 에러가 아니라 **"이 코드의 담당 팀 승인이 아직 없다"** 는 뜻입니다. main 보호 규칙의 **Require review from Code Owners** 때문입니다.

- 누가 승인해야 하는지는 `.github/CODEOWNERS` 에 있습니다: 팀 폴더(`src/camera/` 등)는 **그 팀 팀장**(팀장 본인 PR·부재 시 다른 리더, `leads`), `src/fusion/`·`src/interfaces/` 는 `leads`(팀 리더), 그 밖의 공용 파일(`docs/`, `scripts/`, `.github/` 등)은 `maintainers`. 여러 영역을 바꿨으면 **영역마다** 담당 팀의 승인이 필요합니다.
- **PR 을 올린 본인은 자기 PR 을 승인할 수 없습니다.** 리더가 올린 PR 이라도 다른 리더나 관리자가 승인해야 합니다.

| 메시지 | 해결 |
|---|---|
| `Waiting on code owner review from ...` | 오른쪽 **Reviewers** 에 그 팀이 요청돼 있는지 확인하고(없으면 톱니바퀴로 추가), 담당자에게 PR 링크를 보내 리뷰를 부탁합니다 |
| `Review required` / `At least 1 approving review is required` | 승인(Approve)이 하나도 없습니다. 위와 같이 리뷰를 요청합니다 |
| `Changes requested` | 리뷰어가 수정을 요청했습니다. 위 "리뷰에서 수정 요청을 받았을 때" 대로 고친 뒤 다시 리뷰를 요청합니다 |
| `Some checks were not successful` / `CI 통과` 대기 | CI 가 실패했거나 아직 도는 중입니다. 위 "CI 가 실패했을 때" 를 봅니다 |
| `All conversations must be resolved` | 리뷰 댓글 중 **Resolve conversation** 이 안 된 것이 있습니다. 반영하거나 답한 뒤 Resolve 합니다 |
| `This branch has conflicts` | main 과 충돌입니다. `./scripts/sync_main.sh` 로 해결 ([TEAM_GUIDE.md - 충돌 해결](TEAM_GUIDE.md#충돌-해결)) |

> 승인해 줄 수 있는 사람이 없다면(다른 리더가 GitHub 팀에 아직 없는 경우) 관리자에게 **Organization → Teams → leads / maintainers** 에 팀원 추가를 요청합니다. 규칙을 우회(Bypass)하지 않습니다.

PR 을 올리면 자동으로 일어나는 일:

| 자동화 | 내용 |
|---|---|
| 팀 라벨 | 브랜치 이름과 변경 경로로 `team:xxx` 라벨 부여 |
| 규칙 안내 | 브랜치 이름, 이슈 연결, PR 크기(400줄)를 확인해 댓글로 안내 |
| CI | 바뀐 팀의 패키지와 그 패키지에 의존하는 패키지만 빌드·테스트. 아두이노가 바뀌면 컴파일 검사 (토픽으로만 연결된 융합은 다시 검사하지 않음 → [INTEGRATION.md](INTEGRATION.md)) |
| 진행 중 표시 | 이슈에 담당자가 지정되거나, PR 본문 `Closes #N` 으로 연결되면 이슈에 `status:in-progress` 자동 부여 (리포트 "🚧 진행 중" 집계) |
| 공용 영역 알림 | `src/interfaces/`, `src/bringup/` 이 바뀌면 모든 팀을 멘션 |
| 상태 점검 (매일) | 3일 넘게 열린 PR → `status:stale`, main 보다 20커밋 이상 뒤처짐 → `status:behind-main` |

- AI 도구를 썼다면 PR 템플릿의 **AI 도구 사용** 에 체크합니다. `ai:*` 라벨이 붙고 리포트에 집계됩니다.

## 6. 리뷰하기 (리뷰를 요청받은 사람)

- 리뷰 요청을 받으면 **하루 안에** 응답합니다. 리뷰 대기가 가장 큰 병목입니다.
- 볼 것: 동작하는가 / 테스트가 있는가 / 토픽 이름·메시지 타입이 인터페이스 문서와 맞는가 / 타임아웃·예외 처리
- 승인(Approve) 1개와 `CI 통과` 가 모두 있어야 병합할 수 있습니다.

### 누가 승인하나 (팀장 승인 원칙)
승인권자는 `config/teams.yml` 의 `lead`(팀장 GitHub 아이디), `code_owners` 로 정하고 `.github/CODEOWNERS` 에 자동 반영됩니다.

| 바꾼 폴더 | 승인 | 비고 |
|---|---|---|
| 팀 폴더 (`src/camera/` 등, 제어 팀은 `firmware/` 포함) | **그 팀 팀장** | 팀원은 먼저 리뷰(Comment)로 의견을 남기고, 팀장이 최종 승인 |
| 팀장 본인이 올린 PR, 팀장이 자리를 비울 때 | **다른 팀 리더**(`leads`) | 자기 PR 은 승인할 수 없으므로. PR 댓글에 이유를 남깁니다 |
| 리더가 모두 자리를 비운 급한 경우 | **전체 팀장**(`maintainers`) | 예비 승인. PR 댓글에 이유를 남기고, 팀장이 돌아오면 확인받습니다 |
| `src/fusion/`, `src/interfaces/` | 리더 중 누구나 (`leads`) | 팀 리더 공동 담당 |
| 그 밖의 공용 파일 (`docs/`, `scripts/`, `.github/` 등) | `maintainers` | |

> GitHub 은 "`leads` 중 누구나" 까지만 강제할 수 있습니다. **팀 폴더는 원칙적으로 자기 팀장이 승인**하고, 다른 리더와 전체 팀장은 위 표의 예외일 때만 승인합니다. (팀 폴더 PR 에는 `maintainers` 에게도 리뷰 요청이 가지만, 예외가 아니면 지나쳐도 됩니다.)
> 승인 뒤 새로 push 하면 승인이 사라지므로(Dismiss stale approvals) 다시 승인을 받아야 합니다.

## 7. 병합

- **Squash and merge** 버튼으로 병합합니다. 병합 후 브랜치는 자동으로 삭제됩니다.
- 로컬 정리:
  ```bash
  git switch main && git pull --ff-only
  git branch -d camera/12-lane-offset
  ```

## 진행 상황 확인하는 곳

| 알고 싶은 것 | 볼 곳 |
|---|---|
| 지금 누가 무엇을 하나 | Projects 보드 → `담당자별` 뷰 |
| 팀별 진행 상황 | Projects 보드 → `팀별` 뷰, 또는 Issues 에서 `label:team:camera` |
| 이번 주 / 이번 달 무엇이 끝났나 | 매주 월요일, 매월 1일 자동 생성되는 `📊 주간 리포트`, `📅 월간 리포트` 이슈와 노션 `작업 기록` 데이터베이스 |
| 내 코드가 본체에서도 도나 | Actions → `본체 노트북 실기 테스트` 실행 ([TARGET_ENV.md](TARGET_ENV.md)) |
| 특정 파일을 누가 언제 바꿨나 | GitHub 파일 화면 → **History** / **Blame**, 또는 `git log -p <파일>` |
| 어느 버전이 안정 버전인가 | **Releases** (태그) |
| main 이 깨졌나 | README 의 CI 배지, `ci:nightly-failure` 이슈 |

## 막혔을 때

- 충돌 해결: [TEAM_GUIDE.md - 충돌 해결](TEAM_GUIDE.md#충돌-해결)
- 개발 환경 문제: [DEV_ENV.md](DEV_ENV.md)
