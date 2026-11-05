#!/usr/bin/env bash
# 팀 폴더에 ROS2 패키지 생성
#   ./scripts/new_package.sh <팀id> <패키지이름> [python|cpp]
set -euo pipefail
cd "$(dirname "$0")/.."

team=${1:?"팀 id 필요 (python3 scripts/teams.py list)"}
name=${2:?"패키지 이름 필요 (예: ${1}_lane_detector)"}
lang=${3:-python}

if ! python3 scripts/teams.py list | grep -qx "$team"; then
  echo "알 수 없는 팀: $team"; python3 scripts/teams.py list; exit 1
fi

case "$lang" in
  python) build_type=ament_python; deps=(rclpy mad_interfaces) ;;
  cpp)    build_type=ament_cmake;  deps=(rclcpp mad_interfaces) ;;
  *) echo "언어는 python 또는 cpp"; exit 1 ;;
esac

# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"
mkdir -p "src/$team"
(cd "src/$team" && ros2 pkg create "$name" --build-type "$build_type" --license Apache-2.0 \
  --dependencies "${deps[@]}")
pkg="src/$team/$name"

# 코드 스타일은 pre-commit(ruff / clang-format)이 저장소 전체에 같은 규칙으로 검사한다.
# ros2 pkg create 가 넣는 ament 스타일 린터는 그 규칙과 충돌하므로(따옴표, 줄 길이 99, import 순서,
# 중괄호 위치 등) 충돌하는 것만 뺀다. 충돌하지 않는 린터(pep257, xmllint, cppcheck, lint_cmake)는 남긴다.
if [ "$lang" = python ]; then
  rm -f "$pkg/test/test_flake8.py"
  sed -i '/<test_depend>ament_flake8<\/test_depend>/d' "$pkg/package.xml"
else
  marker='ament_lint_auto_find_test_dependencies()'
  if grep -q "$marker" "$pkg/CMakeLists.txt"; then
    sed -i "s|^\([[:space:]]*\)$marker|\1# 스타일은 clang-format / ruff (pre-commit) 가 검사 → 충돌하는 ament 린터 제외\n\1set(ament_cmake_uncrustify_FOUND TRUE)\n\1set(ament_cmake_flake8_FOUND TRUE)\n&|" \
      "$pkg/CMakeLists.txt"
  else
    echo "⚠️  $pkg/CMakeLists.txt 에서 ament_lint_auto 설정을 찾지 못했습니다. 린터 설정을 직접 확인하세요."
  fi
fi

# 생성된 파일을 저장소 스타일로 맞춘다 (첫 커밋에서 pre-commit 이 실패하지 않도록)
if command -v pre-commit >/dev/null; then
  mapfile -t files < <(find "$pkg" -type f)
  pre-commit run --files "${files[@]}" >/dev/null 2>&1 || true
fi
echo "✅ $pkg 생성 완료"
