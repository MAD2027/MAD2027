"""가짜 차선 중심 오프셋 발행 노드 ([SIM] 검증용)."""

import math

import rclpy
from rclpy.node import Node
from std_msgs.msg import Float32

from camera_lane.lane_math import lane_center_offset
from mad_interfaces.msg import NodeStatus


class LaneNode(Node):
    def __init__(self) -> None:
        super().__init__("lane_node")
        self.lane_width_m = self.declare_parameter("lane_width_m", 3.5).value
        rate_hz = self.declare_parameter("rate_hz", 10.0).value
        self.offset_pub = self.create_publisher(Float32, "/camera/lane_offset", 10)
        self.status_pub = self.create_publisher(NodeStatus, "/system/status", 10)
        self.t = 0.0
        self.create_timer(1.0 / rate_hz, self._on_timer)
        self.create_timer(1.0, self._publish_status)

    def _on_timer(self) -> None:
        self.t += 0.1
        drift = 0.3 * math.sin(self.t)  # 가짜 측정값
        half = self.lane_width_m / 2.0
        self.offset_pub.publish(Float32(data=lane_center_offset(half + drift, -half + drift)))

    def _publish_status(self) -> None:
        msg = NodeStatus()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.team = "camera"
        msg.node_name = self.get_name()
        msg.level, msg.message = NodeStatus.OK, "가짜 차선 발행 중"
        self.status_pub.publish(msg)


def main() -> None:
    rclpy.init()
    node = LaneNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()


if __name__ == "__main__":
    main()
