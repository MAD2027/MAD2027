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

# 팀 런치·설정 템플릿 (docs/TEAM_GUIDE.md: 각 팀 패키지에 launch/<팀>.launch.py)
# → 설치 위치 install/<패키지>/share/<패키지>/{launch,config}/ 에 들어가도록 setup.py / CMakeLists.txt 에 등록한다.
mkdir -p "$pkg/launch" "$pkg/config"
cat > "$pkg/launch/$team.launch.py" <<EOF
"""$team 팀 런치 ($name) - 통합 런치 mad_bringup/system.launch.py 의 TEAM_LAUNCHES 에서 포함된다."""

# ros2 launch $name $team.launch.py                     # 실제 센서
# ros2 launch $name $team.launch.py use_sim_time:=true  # rosbag 재생 시

import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    config = os.path.join(get_package_share_directory("$name"), "config", "$name.yaml")
    use_sim_time = LaunchConfiguration("use_sim_time")

    def node(executable: str) -> Node:
        return Node(
            package="$name",
            executable=executable,
            parameters=[config, {"use_sim_time": use_sim_time}],
            output="screen",
        )

    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="false", description="rosbag 재생 시 true"),
            # 노드를 만들면 실행 파일로 등록하고(python: setup.py entry_points, cpp: add_executable + install)
            # 아래에 추가한다. 예: node("lane_node"),
        ]
    )
EOF
cat > "$pkg/config/$name.yaml" <<EOF
# $name 노드 파라미터 (코드에 하드코딩하지 말고 declare_parameter + 여기). 수정 후 colcon build --symlink-install 이면 재빌드 불필요.
# '/**' 는 이 파일을 받는 모든 노드에 적용. 특정 노드만: '<노드 이름>:' 아래에 쓴다.
/**:
  ros__parameters:
    use_sim_time: false   # 런치 인자 use_sim_time 이 이 값을 덮어쓴다
EOF
python3 - "$pkg" "$lang" <<'PY'
import re
import sys
from pathlib import Path

pkg, lang = Path(sys.argv[1]), sys.argv[2]
xml = pkg / "package.xml"
text = xml.read_text(encoding="utf-8")
deps = "  <exec_depend>launch</exec_depend>\n  <exec_depend>launch_ros</exec_depend>\n"
anchor = "  <test_depend>" if "  <test_depend>" in text else "  <export>"
xml.write_text(text.replace(anchor, deps + anchor, 1), encoding="utf-8")

if lang == "python":
    setup = pkg / "setup.py"
    text = setup.read_text(encoding="utf-8")
    m = re.search(r"\((['\"])share/\1 \+ package_name, \[\1package\.xml\1\]\),\n", text)
    if not m:
        sys.exit(f"⚠️  {setup} 에서 data_files 의 package.xml 줄을 찾지 못했습니다. launch/config 등록을 직접 추가하세요.")
    q, indent = m.group(1), " " * 8
    lines = "".join(
        f"{indent}({q}share/{q} + package_name + {q}/{d}{q}, glob({q}{d}/*{ext}{q})),\n"
        for d, ext in (("launch", ".launch.py"), ("config", ".yaml"))
    )
    text = text[: m.end()] + lines + text[m.end() :]
    if "from glob import glob" not in text:
        text = "from glob import glob\n\n" + text
    setup.write_text(text, encoding="utf-8")
else:
    cmake = pkg / "CMakeLists.txt"
    text = cmake.read_text(encoding="utf-8")
    if "ament_package()" not in text:
        sys.exit(f"⚠️  {cmake} 에서 ament_package() 를 찾지 못했습니다. launch/config install 을 직접 추가하세요.")
    install = "install(DIRECTORY launch config DESTINATION share/${PROJECT_NAME})\n\n"
    cmake.write_text(text.replace("ament_package()", install + "ament_package()", 1), encoding="utf-8")
PY

# 생성된 파일을 저장소 스타일로 맞춘다 (첫 커밋에서 pre-commit 이 실패하지 않도록)
if command -v pre-commit >/dev/null; then
  mapfile -t files < <(find "$pkg" -type f)
  pre-commit run --files "${files[@]}" >/dev/null 2>&1 || true
fi
echo "✅ $pkg 생성 완료"
