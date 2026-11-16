<!-- 자동 생성 (scripts/teams.py sync). 규칙은 같은 폴더의 AGENTS.md 에 쓴다 - 모든 AI 도구 공용 -->
@AGENTS.md

<!-- CLAUDE NOTES: 이 줄 아래는 scripts/teams.py sync 가 지우지 않는다 -->

# 공용 개발 시스템 정비 (Claude 인계용)

> **할 일 목록은 GitHub 고정 이슈 #71 "📌 공용 개발 시스템 정비 트래커" 에 있습니다** (이슈 #70 으로 이 파일에서 옮김, D7).
> 작업 전에 #71 본문을 읽고, 항목을 끝내거나 병합 후 확인한 사실이 생기면 **#71 본문을 고칩니다** (GitHub 도구로 이슈 편집). 기록만 바꾸려고 PR 을 만들지 않습니다.
> 이 구역에는 오래 쓸 참고 사항만 둡니다 (`scripts/teams.py sync` 가 지우지 않음).

## 진행 규칙
- #71 의 항목은 **사용자(저장소 관리자)에게 확인받은 뒤** 진행합니다. 결정(D) 이 필요한 항목은 결정 전에 시작하지 않습니다.
- 코드·문서 변경은 이슈 → 브랜치 → Draft PR (CONTRIBUTING.md, AGENTS.md "작업 절차"). 작은 변경은 그 달의 묶음 이슈 `🧹 자잘한 수정 YYYY-MM` 을 `Refs` 로 쓰고, 열린 PR 이 있으면 거기에 묶습니다.
- AI 는 PR 을 병합하지 않고 auto-merge 도 켜지 않습니다.

## 참고 (작업하며 알게 된 것)
- `.gitignore` 의 `install/` 이 colcon 출력뿐 아니라 모든 `install/` 폴더를 무시함 → 설치 스크립트는 `scripts/installer/` 에 둠
- `.pre-commit-config.yaml` 의 `name:` 값에 `: ` 가 들어가면 따옴표로 감싸야 함 (안 그러면 `pre-commit install` 이 조용히 일부 훅만 설치)
- 루트·팀 폴더의 `CLAUDE.md` 는 `teams.py sync` 가 만드는 파일. 루트 `CLAUDE.md` 의 `CLAUDE NOTES` 표시줄 아래(이 구역)만 sync 가 보존한다. 팀 규칙은 `AGENTS.md` 에 쓴다 (다른 AI 도구도 읽도록)
- GitHub 에서 Draft 를 해제하면서 팀 리뷰어를 같이 요청하면 "Validation Failed" 가 날 때가 있음 → 리뷰어만 다시 요청하면 됨
- 노션 기록은 진행 리포트와 백업이 `.github/scripts/report.js` 의 `notion`·`text`·`block` 을 함께 씀. 노션 DB 열 이름을 바꾸면 `backup.js` 도 고쳐야 함
- 클라우드 AI 세션은 Docker/ROS 가 없어 `colcon build`·`check.sh` 를 못 함 → PR "테스트 방법" 에 실행하지 못했다고 적고, CI 결과와 사람의 컨테이너 확인으로 보완
- 묶음 이슈 제목 접두사 `🧹 자잘한 수정 ` 은 `chore-bundle.yml` 과 `pr-automation.yml` 의 `BUNDLE` 이 같아야 함 (봇이 `Refs` 를 이슈 연결로 인정하는 기준)
