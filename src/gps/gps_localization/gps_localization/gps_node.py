"""[SIM] 가짜 gps 출력 발행 노드 (검증용)."""

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import NavSatFix

from mad_interfaces.msg import NodeStatus


class FakeNode(Node):
    def __init__(self) -> None:
        super().__init__("gps_node")
        rate_hz = self.declare_parameter("rate_hz", 10.0).value
        self.frame_id = self.declare_parameter("frame_id", "gps_link").value
        self.pub = self.create_publisher(NavSatFix, "/gps/fix", 10)
        self.status_pub = self.create_publisher(NodeStatus, "/system/status", 10)
        self.create_timer(1.0 / rate_hz, self._on_timer)
        self.create_timer(1.0, self._publish_status)

    def _on_timer(self) -> None:
        msg = NavSatFix()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = self.frame_id
        msg.latitude, msg.longitude, msg.altitude = 37.5665, 126.9780, 30.0
        self.pub.publish(msg)

    def _publish_status(self) -> None:
        msg = NodeStatus()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.team = "gps"
        msg.node_name = self.get_name()
        msg.level, msg.message = NodeStatus.OK, "가짜 데이터 발행 중"
        self.status_pub.publish(msg)


def main() -> None:
    rclpy.init()
    node = FakeNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.try_shutdown()
