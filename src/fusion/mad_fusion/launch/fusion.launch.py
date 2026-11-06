"""융합 런치 (통합 런치 mad_bringup/system.launch.py 의 TEAM_LAUNCHES 에서 포함된다).

ros2 launch mad_fusion fusion.launch.py use_sim_time:=true   # rosbag 재생 시
"""

import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    config = os.path.join(get_package_share_directory("mad_fusion"), "config", "fusion.yaml")
    use_sim_time = LaunchConfiguration("use_sim_time")
    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="false", description="rosbag 재생 시 true"),
            Node(
                package="mad_fusion",
                executable="fusion_node",
                parameters=[config, {"use_sim_time": use_sim_time}],
                output="screen",
            ),
        ]
    )
