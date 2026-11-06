#!/usr/bin/env bash
# 이슈 작업 시작: 최신 main 에서 규칙에 맞는 브랜치를 만든다.
#   ./scripts/start_task.sh <팀id> <이슈번호> <짧은-설명>
#   예) ./scripts/start_task.sh camera 12 lane-offset
#       ./scripts/start_task.sh shared 15 lane-info-msg     (공용 영역: 인터페이스/통합 런치 등)
#   팀 id 외 접두사: shared, docs, chore, hotfix (.github/workflows/pr-automation.yml 의 브랜치 규칙과 같음)
set -euo pipefail
cd "$(dirname "$0")/.."

team=${1:?"팀 id"}; issue=${2:?"이슈 번호"}; desc=${3:?"짧은 설명(영문, 하이픈)"}
prefixes=$(python3 scripts/teams.py list; printf '%s\n' shared docs chore hotfix)
if ! grep -qx "$team" <<< "$prefixes"; then
  echo "알 수 없는 팀/접두사: $team"; echo "$prefixes"; exit 1
fi
if ! [[ "$issue" =~ ^[0-9]+$ && "$desc" =~ ^[a-z0-9._-]+$ ]]; then
  echo "이슈 번호는 숫자, 설명은 영문 소문자/숫자/하이픈만: $issue $desc"; exit 1
fi
branch="$team/$issue-$desc"

if [ -n "$(git status --porcelain)" ]; then
  echo "커밋하지 않은 변경이 있습니다. 먼저 커밋하거나 git stash 하세요."; exit 1
fi
git fetch origin main
git switch -c "$branch" origin/main
echo "✅ $branch 브랜치에서 작업을 시작하세요. 첫 push 후 Draft PR 을 열면 진행 상황이 보드에 보입니다."
