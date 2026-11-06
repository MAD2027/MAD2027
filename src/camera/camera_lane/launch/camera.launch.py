"""카메라 팀 런치 (통합 런치 TEAM_LAUNCHES 에서 포함)."""

from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription([Node(package="camera_lane", executable="lane_node", output="screen")])
