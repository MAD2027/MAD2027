"""전체 시스템 통합 런치.

각 팀은 자기 패키지에 `<패키지>/launch/<이름>.launch.py` 를 만들고,
통합할 준비가 되면 아래 TEAM_LAUNCHES 에 한 줄 추가하는 PR 을 올린다.
설치되지 않은 패키지는 건너뛰므로 일부 팀만 있어도 실행된다.

  ros2 launch mad_bringup system.launch.py                     # 실제 센서
  ros2 launch mad_bringup system.launch.py use_sim_time:=true  # rosbag 재생 (ros2 bag play ... --clock)

use_sim_time 은 이 런치의 노드와 포함하는 모든 팀 런치에 전달된다.
"""

import os

from ament_index_python.packages import PackageNotFoundError, get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, LogInfo
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

from mad_bringup.static_tf import load_static_transforms

# (패키지 이름, launch 파일 이름)
TEAM_LAUNCHES = [
    ("mad_fusion", "fusion.launch.py"),  # 센서 융합 (팀 리더 공동)
    # ("camera_lane", "camera.launch.py"),
    # ("gps_localization", "gps.launch.py"),
    # ("lidar_obstacle", "lidar.launch.py"),
    # ("control_driver", "control.launch.py"),
]


def generate_launch_description() -> LaunchDescription:
    share = get_package_share_directory("mad_bringup")
    config = os.path.join(share, "config", "system.yaml")
    use_sim_time = LaunchConfiguration("use_sim_time")
    sim_time = {"use_sim_time": use_sim_time}

    actions = [
        DeclareLaunchArgument("use_sim_time", default_value="false", description="rosbag 재생 시 true (--clock 필요)"),
        Node(package="mad_bringup", executable="system_monitor", parameters=[config, sim_time], output="screen"),
    ]

    # 센서 장착 위치 (config/static_tf.yaml): base_link → camera_link 등
    for tf in load_static_transforms(os.path.join(share, "config", "static_tf.yaml")):
        actions.append(
            Node(
                package="tf2_ros",
                executable="static_transform_publisher",
                name=f"static_tf_{tf.child}",
                arguments=tf.args(),
                parameters=[sim_time],
            )
        )

    for package, launch_file in TEAM_LAUNCHES:
        try:
            team_share = get_package_share_directory(package)
        except PackageNotFoundError:
            actions.append(LogInfo(msg=f"[bringup] {package} 미설치 - 건너뜀"))
            continue
        path = os.path.join(team_share, "launch", launch_file)
        actions.append(
            IncludeLaunchDescription(
                PythonLaunchDescriptionSource(path),
                launch_arguments={"use_sim_time": use_sim_time}.items(),
            )
        )
    return LaunchDescription(actions)
