#!/usr/bin/env bash
# 작업 마무리: 검사 → GitHub 에 올리기 → PR 생성 링크. (공용 컨테이너 안, 작업 브랜치에서 실행)
#   ./scripts/finish_task.sh
#
# 1) 커밋하지 않은 변경이 있으면 멈춘다
# 2) ./scripts/check.sh <팀> (shared/docs/chore/hotfix 는 전체 검사)
# 3) 이 브랜치를 처음 올리면 git push -u origin HEAD, 이미 올렸으면 git push
# 4) 제목([팀] ...)과 "Closes #이슈" 가 채워진 PR 생성 링크를 출력한다 (이미 PR 이 있으면 push 만으로 반영됨)
#    docs/·chore/ 브랜치(작은 변경, 묶음 이슈)는 짧은 템플릿과 "Refs #이슈" 를 쓴다 (이슈 #70)
set -euo pipefail
cd "$(dirname "$0")/.."

branch=$(git branch --show-current)
if [ -z "$branch" ] || [ "$branch" = main ]; then
  echo "❌ 작업 브랜치에서 실행하세요 (지금: ${branch:-분리된 HEAD})."
  echo "   ./scripts/start_task.sh <팀> <이슈번호> <설명>  으로 브랜치를 먼저 만듭니다."
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ 커밋하지 않은 변경이 있습니다. 먼저 커밋하세요:"
  git status --short
  echo '   git add -p && git commit -m "<팀>: <무엇을 했는지> (#이슈번호)"'
  exit 1
fi

prefix=${branch%%/*}
issue=$(sed -n 's#^[^/]*/\([0-9][0-9]*\)-.*#\1#p' <<< "$branch")
if [ -z "$(git log --oneline origin/main..HEAD 2>/dev/null)" ]; then
  echo "❌ main 에 없는 커밋이 없습니다. 올릴 내용이 없습니다."; exit 1
fi

echo "▶ 검사 (./scripts/check.sh)"
if python3 scripts/teams.py list | grep -qx "$prefix"; then ./scripts/check.sh "$prefix"; else ./scripts/check.sh; fi

echo "▶ GitHub 에 올리기"
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
if [ "$upstream" = "origin/$branch" ]; then
  git push
else
  git push -u origin HEAD   # 이 브랜치를 처음 올림 (이후에는 git push 만)
fi

# PR 생성 링크: 제목과 본문(템플릿에 Closes/Refs #이슈 를 채운 것)을 미리 채운다
template=pull_request_template.md; link=Closes; template_path=.github/pull_request_template.md
case "$prefix" in
  docs|chore) template=small.md; link=Refs; template_path=.github/PULL_REQUEST_TEMPLATE/small.md ;;
esac
repo=$(git remote get-url origin | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')
subject=$(git log -1 --format=%s origin/main..HEAD)
summary=$(sed -E 's/^[a-z0-9-]+: //; s/ \(#[0-9]+\)$//' <<< "$subject")
title="[$prefix] $summary"
body=$(sed -E "s/^${link} #\$/${link} #${issue}/" "$template_path")
url=$(python3 - "$repo" "$branch" "$title" "$body" "$template" <<'PY'
import sys
from urllib.parse import quote

repo, branch, title, body, template = sys.argv[1:]
base = f"https://github.com/{repo}/compare/main...{quote(branch, safe='/')}?quick_pull=1"
url = f"{base}&title={quote(title)}&body={quote(body)}"
print(url if len(url) < 7000 else f"{base}&title={quote(title)}&template={template}")
PY
)

echo
echo "✅ 올렸습니다: $branch"
echo "   PR 이 아직 없으면 아래 링크를 열어 PR 을 만드세요 (이미 있으면 그 PR 에 반영됨):"
echo "   $url"
if [ "$link" = Refs ]; then
  echo "   - 제목·Refs #${issue:-?} (묶음 이슈) 는 채워져 있습니다. 변경 내용, AI 도구 사용을 채웁니다."
else
  echo "   - 제목·Closes #${issue:-?} 는 채워져 있습니다. 변경 내용, 테스트 방법, 다른 팀 영향, AI 도구 사용을 채웁니다."
fi
echo "   - 아직 작업 중이면 초록 버튼 옆 ▼ → Create draft pull request, 끝났으면 Ready for review."
echo "   - CI 를 기다리지 않으려면 PR 화면에서 Enable auto-merge → Squash: CI 통과 후 자동으로 병합됩니다."
