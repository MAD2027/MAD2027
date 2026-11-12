import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description() -> LaunchDescription:
    config = os.path.join(get_package_share_directory("mad_fusion"), "config", "fusion.yaml")
    # rosbag 재생(ros2 bag play --clock) 시 use_sim_time:=true 로 bag 의 /clock 시각을 사용한다.
    use_sim_time = LaunchConfiguration("use_sim_time")
    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "use_sim_time",
                default_value="false",
                description="true 면 /clock (rosbag 재생 시각)을 사용",
            ),
            Node(
                package="mad_fusion",
                executable="fusion_node",
                parameters=[config, {"use_sim_time": ParameterValue(use_sim_time, value_type=bool)}],
                output="screen",
            ),
        ]
    )
