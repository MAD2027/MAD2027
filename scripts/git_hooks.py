#!/usr/bin/env python3
"""git 훅 검사 (pre-commit 이 호출). 어떤 AI 도구나 사람이 작업해도 규칙 위반을 커밋·push 단계에서 막는다.

  commit-msg <파일>   커밋 메시지 첫 줄이 `<팀>: <내용> (#이슈번호)` 인지
  pre-push            main 직접 push 금지, 브랜치 이름이 `<팀>/<이슈번호>-<설명>` 인지

규칙의 기준: AGENTS.md "Git / PR 규칙", .github/workflows/pr-automation.yml 의 브랜치 검사.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
EXTRA_PREFIXES = ["shared", "hotfix", "docs", "chore"]  # 팀 id 외에 허용하는 접두사 (pr-automation.yml 과 같음)
AI_BRANCH = re.compile(r"^(claude|codex|grok)/")  # 이름을 바꿀 수 없는 클라우드 AI 에이전트 브랜치 (PR 봇도 허용)
# git 이 만드는 메시지는 형식 검사에서 제외
AUTO_MESSAGE = re.compile(r"^(Merge |Revert \"|fixup! |squash! |amend! )")
ZERO = "0" * 40


def prefixes() -> list[str]:
    cfg = yaml.safe_load((ROOT / "config" / "teams.yml").read_text(encoding="utf-8"))
    return [t["id"] for t in cfg["teams"]] + EXTRA_PREFIXES


def commit_msg(path: str) -> int:
    lines = [ln for ln in Path(path).read_text(encoding="utf-8").splitlines() if not ln.startswith("#")]
    subject = next((ln.strip() for ln in lines if ln.strip()), "")
    if not subject or AUTO_MESSAGE.match(subject):
        return 0
    ids = prefixes()
    if re.match(rf"^({'|'.join(map(re.escape, ids))}): .+ \(#\d+\)$", subject):
        return 0
    print("❌ 커밋 메시지 형식이 규칙과 다릅니다.")
    print(f"   지금:  {subject}")
    print("   규칙:  <팀>: <무엇을 했는지> (#이슈번호)")
    print("   예:    camera: 차선 중심 오프셋 계산 (#12)")
    print(f"   팀:    {', '.join(ids)}")
    print('   고치기: 같은 명령으로 메시지만 바꿔 다시 커밋 (git commit -m "...")')
    return 1


def pre_push() -> int:
    local = os.environ.get("PRE_COMMIT_LOCAL_BRANCH", "").removeprefix("refs/heads/")
    if local in ("", "HEAD"):
        local = subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True).stdout.strip()
    remote = os.environ.get("PRE_COMMIT_REMOTE_BRANCH", "")
    to_ref = os.environ.get("PRE_COMMIT_TO_REF", "")
    if not remote.startswith("refs/heads/") or to_ref == ZERO:  # 태그 push, 원격 브랜치 삭제는 검사 안 함
        return 0
    branch = remote.removeprefix("refs/heads/")
    if branch == "main":
        print("❌ main 에 직접 push 할 수 없습니다. 작업 브랜치에서 PR 로 올립니다.")
        print("   ./scripts/start_task.sh <팀> <이슈번호> <설명>  →  커밋  →  ./scripts/finish_task.sh")
        return 1
    if AI_BRANCH.match(branch):
        return 0
    ids = prefixes()
    if not re.match(rf"^({'|'.join(map(re.escape, ids))})/\d+-[a-z0-9._-]+$", branch):
        print(f"❌ 브랜치 이름 '{branch}' 이 규칙 <팀>/<이슈번호>-<설명> 과 다릅니다.")
        print(f"   팀/접두사: {', '.join(ids)}  (설명은 영문 소문자·숫자·하이픈)")
        if local:
            print(f"   고치기: git branch -m {local} <팀>/<이슈번호>-<설명>  후 다시 push")
        return 1
    return 0


def main() -> int:
    if len(sys.argv) >= 3 and sys.argv[1] == "commit-msg":
        return commit_msg(sys.argv[2])
    if len(sys.argv) >= 2 and sys.argv[1] == "pre-push":
        return pre_push()
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
