#!/usr/bin/env bash
# PR 올리기 전 로컬 검사 (CI 와 동일한 순서)
#   ./scripts/check.sh            전체
#   ./scripts/check.sh camera     특정 팀 폴더의 패키지 + 그에 의존하는 패키지만 (+ 그 팀 펌웨어)
set -euo pipefail
cd "$(dirname "$0")/.."

team=${1:-}
if [ -n "$team" ] && ! python3 scripts/teams.py list | grep -qx "$team"; then
  echo "알 수 없는 팀: $team"; python3 scripts/teams.py list; exit 1
fi

echo "▶ 1/4 코드 스타일 (pre-commit)"
pre-commit run --all-files

# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"

select_args=()
test_args=()
run_ros=true
if [ -n "$team" ]; then
  pkgs=()
  [ -d "src/$team" ] && mapfile -t pkgs < <(colcon list --names-only --base-paths "src/$team")
  if [ ${#pkgs[@]} -eq 0 ]; then
    echo "src/$team 에 ROS 패키지가 없어 빌드/테스트를 건너뜁니다."
    run_ros=false
  else
    select_args=(--packages-above-and-dependencies "${pkgs[@]}")
    test_args=(--packages-above "${pkgs[@]}")
  fi
fi

if [ "$run_ros" = true ]; then
  echo "▶ 2/4 빌드 (colcon build)"
  colcon build --symlink-install "${select_args[@]}"

  echo "▶ 3/4 테스트 (colcon test)"
  colcon test "${test_args[@]}" --event-handlers console_direct+
  colcon test-result --verbose
fi

# 아두이노 펌웨어: 전체 검사이거나, 펌웨어를 담당하는 팀(teams.yml 의 paths 에 firmware/ 포함)일 때
if [ -z "$team" ] || python3 - "$team" <<'PY'; then
import sys
import yaml

cfg = yaml.safe_load(open("config/teams.yml", encoding="utf-8"))
team = next(t for t in cfg["teams"] if t["id"] == sys.argv[1])
sys.exit(0 if any(p.rstrip("/") == "firmware" for p in team.get("paths", [])) else 1)
PY
  echo "▶ 4/4 아두이노 컴파일"
  for dir in firmware/arduino/*/; do
    [ -f "${dir}sketch.yaml" ] && arduino-cli compile "$dir"
  done
fi

echo "✅ 모든 검사 통과 - PR 을 올려도 됩니다."
